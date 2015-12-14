import QtQuick 2.4
import QtMultimedia 5.0

import fbx.async 1.0

MediaPlayer {
    id: mediaPlayer

    property var playDeferred: ([]);
    property var stopDeferred: ([]);
    property var pauseDeferred: ([]);

    onPlaybackStateChanged: {
        var d;

        switch(playbackState) {
        case MediaPlayer.PlayingState:
            d=playDeferred;
            playDeferred=[];
            console.log("PlaybackChanged: "+playbackState+" PLAYING "+d);
            break;

        case MediaPlayer.StoppedState:
            d=stopDeferred;
            stopDeferred=[];
            console.log("PlaybackChanged: "+playbackState+" STOPPED "+d);
            break;

        case MediaPlayer.PausedState:
            d=pauseDeferred;
            pauseDeferred=[];
            console.log("PlaybackChanged: "+playbackState+" PAUSED "+d);
            break;

        default:
            console.error("PlaybackChanged: "+playbackState+" UNKNOWN STATE");
            break;
        }


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

        //console.log("Play video !");

        mediaPlayer.play();

        return deferred;
    }

    function $stop() {
        console.log("$Stop current playbackState="+playbackState);

        if (playbackState===MediaPlayer.StoppedState) {
            return Deferred.resolved(playbackState);
        }

        var deferred=new Deferred.Deferred();

        stopDeferred.push(deferred);

        //console.log("Stop video !");

        console.log("$Stop: defer stop !");

        mediaPlayer.stop();

        return deferred;

    }

    function $pause() {
        if (playbackState===MediaPlayer.PausedState) {
            return Deferred.resolved(playbackState);
        }

        var deferred=new Deferred.Deferred();

        pauseDeferred.push(deferred);

        //console.log("Pause video !");

        mediaPlayer.pause();

        return deferred;
    }
}

