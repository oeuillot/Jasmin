import QtQuick 2.4
import QtMultimedia 5.0

import fbx.async 1.0

Item {
    id: audio

    property bool log: false;

    property var playDeferred: ([]);
    property var stopDeferred: ([]);
    property var pauseDeferred: ([]);
    property var instanciateDeferred: ([]);

    property int playbackState: Audio.StoppedState;

    property int position: 0;

    property int duration: 0;

    property var source: null;

    property bool autoLoad: true;

    property Audio _internalAudio;

    onPlaybackStateChanged: {
        var d;
        if (log) {
            console.log("PlaybackState changed "+playbackState);
        }

        switch(playbackState) {
        case Audio.PlayingState:
            d=playDeferred;
            playDeferred=[];
            break;

        case Audio.StoppedState:
            d=stopDeferred;
            stopDeferred=[];
            break;

        case Audio.PausedState:
            d=pauseDeferred;
            pauseDeferred=[];
            break;
        }

        //console.log("PlaybackChanged: "+playbackState+" "+d);

        if (!d || !d.length) {
            return;
        }

        for(var i=0;i<d.length;i++) {
            d[i].resolve(playbackState);
        }
    }
    onSourceChanged: {
        if (log) {
            console.log("Source changed "+source+" internalAudio="+_internalAudio);
        }
        if (!_internalAudio) {
            return;
        }

        _internalAudio.source=source;
    }

    function $play() {
        if (log) {
            console.log("$play playbackState="+playbackState+" internalAudio="+_internalAudio);
        }
        if (playbackState===Audio.PlayingState) {
            return Deferred.resolved(playbackState);
        }

        var deferred=new Deferred.Deferred();

        playDeferred.push(deferred);

        if (!_internalAudio) {
            if (log) {
                console.log("No internal audio ");
            }
            return _instanciateInternalAudio().then(function onSuccess(createdAudio) {
                if (log) {
                    console.log("Audio instanciate "+createdAudio);
                }

                if (!createdAudio) {
                    return Deferred.resolved(Audio.StoppedState);
                }

                return audio.$play();
            });
        }

        _internalAudio.play();

        return deferred;
    }

    function $stop() {
        if (log) {
            console.log("$stop playbackState="+playbackState+" internalAudio="+_internalAudio);
        }

        if (playbackState===Audio.StoppedState) {
            return Deferred.resolved(playbackState);
        }

        if (!_internalAudio) {
            return Deferred.resolved(Audio.StoppedState);
        }

        var deferred=new Deferred.Deferred();

        stopDeferred.push(deferred);

        _internalAudio.stop();

        deferred.then(function() {
            if (log) {
                console.log("Promise STOP "+_internalAudio);
            }
            if (!_internalAudio) {
                return Audio.StoppedState;
            }

            playbackState=Audio.StoppedState;
            position=0;
            duration=0;

            if (log) {
                console.log("Stopping ...");
            }
            _internalAudio.destroy();
            _internalAudio=null;

            return Audio.StoppedState;
        });

        return deferred;

    }

    function $pause() {
        if (playbackState===Audio.PausedState) {
            return Deferred.resolved(playbackState);
        }

        if (playbackState===Audio.StoppedState || !_internalAudio) {
            return Deferred.resolved(Audio.StoppedState);
        }

        var deferred=new Deferred.Deferred();

        pauseDeferred.push(deferred);

        _internalAudio.pause();

        return deferred;
    }

    Component {
        id: audioComponent

        Audio {
            id: audio2
            autoLoad: audio.autoLoad
            autoPlay: false
            source: audio.source

            onPlaybackStateChanged: {
                audio.playbackState=audio2.playbackState;
            }

            onPositionChanged: {
                audio.position=audio2.position;
            }

            onDurationChanged: {
                audio.duration=audio2.duration;
            }

            Component.onCompleted: {
                if (log) {
                    console.log("Audio2 instanciated "+audio2);
                }
                _internalAudio=audio2;

                var d=instanciateDeferred;
                instanciateDeferred=[];

                for(var i=0;i<d.length;i++) {
                    d[i].resolve(audio2);
                }
            }
        }
    }

    function _instanciateInternalAudio() {
        if (log) {
            console.log("Create AUDIO");
        }

        var deferred=new Deferred.Deferred();

        instanciateDeferred.push(deferred);

        audioComponent.createObject(audio);

        return deferred;
    }
}

