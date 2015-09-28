import QtQuick 2.4
import QtMultimedia 5.0

import fbx.async 1.0

Video {
    id: video

    property var playDeferred: ([]);
    property var stopDeferred: ([]);
    property var pauseDeferred: ([]);

    onPlaybackStateChanged: {
        var d;

        switch(playbackState) {
        case MediaPlayer.PlayingState:
            d=playDeferred;
            playDeferred=[];
            break;

        case MediaPlayer.StoppedState:
            d=stopDeferred;
            stopDeferred=[];
            break;

        case MediaPlayer.PausedState:
            d=pauseDeferred;
            pauseDeferred=[];
            break;
        }

        console.log("PlaybackChanged: "+playbackState+" "+d);

        if (!d || !d.length) {
            return;
        }

        for(var i=0;i<d.length;i++) {
            d[i].resolve(playbackState);
        }
    }

    function $play() {
        if (playbackState===MediaPlayer.PlayingState) {
            return Deferred.resolved(playbackState);
        }

        var deferred=new Deferred.Deferred();

        playDeferred.push(deferred);

        video.play();

        return deferred;
    }

    function $stop() {
        if (playbackState===MediaPlayer.StoppedState) {
            return Deferred.resolved(playbackState);
        }

        var deferred=new Deferred.Deferred();

        stopDeferred.push(deferred);

        video.stop();

        return deferred;

    }

    function $pause() {
        if (playbackState===MediaPlayer.PausedState) {
            return Deferred.resolved(playbackState);
        }

        var deferred=new Deferred.Deferred();

        pauseDeferred.push(deferred);

        video.pause();

        return deferred;
    }
}

