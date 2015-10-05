import QtQuick 2.4
import QtMultimedia 5.0

import fbx.async 1.0

Audio {
    id: audio

    property var playDeferred: ([]);
    property var stopDeferred: ([]);
    property var pauseDeferred: ([]);

    onPlaybackStateChanged: {
        var d;

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

    function $play() {
        if (playbackState===Audio.PlayingState) {
            return Deferred.resolved(playbackState);
        }

        var deferred=new Deferred.Deferred();

        playDeferred.push(deferred);

        audio.play();

        return deferred;
    }

    function $stop() {
        if (playbackState===Audio.StoppedState) {
            return Deferred.resolved(playbackState);
        }

        var deferred=new Deferred.Deferred();

        stopDeferred.push(deferred);

        audio.stop();

        return deferred;

    }

    function $pause() {
        if (playbackState===Audio.PausedState) {
            return Deferred.resolved(playbackState);
        }

        var deferred=new Deferred.Deferred();

        pauseDeferred.push(deferred);

        audio.pause();

        return deferred;
    }
}

