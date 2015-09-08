import QtQuick 2.4
import QtMultimedia 5.0
import fbx.ui.page 1.0
import fbx.ui.control 1.0

import fbx.async 1.0

import "../jasmin" 1.0

import "fontawesome.js" as Fontawesome;

Item {
    id: audioPlayer
    height: childrenRect.height

    property var playList: ([]);

    property int playListIndex: 0;

    property bool shuffle;

    property string playingObjectID: "";

    property int playbackState: Audio.StoppedState;

    property bool manualStop: false;

    function setPlayList(upnpServer, xmlArray, albumImageURL, playListIndex, shuffle, append) {
        //console.log("setPlay: xml="+xmlArray+" playListIndex="+playListIndex+" shuffle="+shuffle+" append="+append);

        if (!append) {
            return stop().then(function() {
                playListIndex=0;
                _setPlayList(upnpServer, xmlArray, albumImageURL, playListIndex, shuffle);
            });
        }

        _setPlayList(upnpServer, xmlArray, albumImageURL, playListIndex, shuffle, append);
        return Deferred.resolved();
    }

    function _fillInfo(upnpServer, xml, albumImageURL, playList, playListIndex ) {
        var found=false;

        xml.byPath("res", UpnpServer.DIDL_XMLNS_SET).forEach(function(res) {
            if (found) {
                return;
            }

            var protocolInfo=res.attr("protocolInfo");
            if (!protocolInfo) {
                return;
            }

            var ts=protocolInfo.split(':');
            if (ts[0]!=='http-get') {
                return;
            }

            var url=res.text();
            if (!url) {
                return;
            }

            var imageURL=xml.byPath("upnp:albumArtURI", UpnpServer.DIDL_XMLNS_SET).first().text();
            if (imageURL) {
                imageURL=upnpServer.relativeURL(imageURL).toString();
            }

            if (!imageURL) {
                imageURL = albumImageURL;
            }

            var title=xml.byPath("dc:title", UpnpServer.DIDL_XMLNS_SET).first().text();
            var artist=xml.byPath("upnp:artist", UpnpServer.DIDL_XMLNS_SET).first().text();

            var objectID=xml.attr("id");

            url=upnpServer.relativeURL(url).toString();

            found=true;

            playList[playListIndex]={
                              objectID: objectID,
                              xml: xml,
                              url: url,
                              imageURL: imageURL,
                              title: title,
                              artist: artist
                          };

            return false; // Break the loop if forEach support it :-)
       });

        return found;
    }

    function _setPlayList(upnpServer, xmlArray, albumImageURL, playListIndex, shuffleP, append) {

        if (!append) {
            playList=[];
        }

        if (!playListIndex) {
            playListIndex=0;
        }

        if (shuffleP!==undefined) {
            shuffle=shuffleP;
        }

        // console.log("xmlArray="+xmlArray);

        if (!(xmlArray instanceof Array)) {
            xmlArray=[xmlArray];
        }

        var idx=playList.length;
        xmlArray.forEach(function(xml) {
            if (_fillInfo(upnpServer, xml, albumImageURL, playList, idx)!==true) {
                return;
            }

            idx++;
        });
    }

    function clear() {
        return stop().then(function() {
            playList=[];
        });
    }

    function playMusic(upnpServer, xml, albumImageURL) {
        return setPlayList(upnpServer, [xml], albumImageURL, 0, false, false).then(function() {
            return play();
        });
    }

    function stop() {
        audioPlayer.playbackState=Audio.StoppedState;
        return audio.$stop().then(function() {
            //console.log("Set audio player to STOP "+audioPlayer.playbackState);
        });
    }

    function play() {
        //console.log("Play: Current playback="+playbackState+" audioPlayback="+audio.playbackState);

        if (playbackState===Audio.PlayingState) {
            return Deferred.resolved(playbackState);
        }
        playbackState=Audio.PlayingState;

        if (audio.playbackState===Audio.StoppedState) {
            return playIndex(playListIndex);
        }

        if (audio.playbackState===Audio.PausedState) {
            return togglePlayPause();
        }

        return Deferred.resolved(playbackState);
    }

    function togglePlayPause() {
        //console.log("PlayPause playbackState="+playbackState+"/"+Audio.PlayingState);
        if (playbackState===Audio.PlayingState) {
            return audio.$pause().then(function() {
                playbackState=Audio.StoppedState;
            });
        }

        if (audio.playbackState===Audio.PausedState) {
            return audio.$start().then(function() {
                playbackState=Audio.PlayingState;
            });
        }

        return play();
    }

    function forward() {
        //console.log("AUDIO: Forward");

        return stop().then(function() {
            //console.log("AUDIO: stopped "+playListIndex+" len="+playList.length);

            if (playListIndex>=playList.length) {
                return false;
            }
            playListIndex++;

            return playIndex(playListIndex);
        });
    }

    function playIndex(index) {
        //console.log("PLAY index #"+index);

        playListIndex=index;
        if (playListIndex>=playList.length) {
            return Deferred.resolved(false);
        }

        return audio.$stop().then(function() {

            var music=playList[playListIndex];

            //console.log("playIndex.stopped #"+playListIndex+" source="+music.url);

            audio.source=music.url;
            audio.currentMusic=music;

            title.text=music.title || "Inconnu";
            artist.text=music.artist || "Inconnu";

            playingObjectID=music.objectID;

            //console.log("Call play of audio !");

            return audio.$play().then(function() {
                playbackState=Audio.PlayingState;
            });
        });
    }

    function formatTime(d) {
        d=Math.floor(d/1000);
        var h=Math.floor(d/3600);
        var m=Math.floor(d/60) % 60;
        var s=d % 60;

        var r=((m<10)?'0':'')+m+':'+((s<10)?'0':'')+s;
        if (h) {
            r=((h<10)?'0':'')+h+':'+r;
        }

        return r;
    }

    DeferredAudio {
        id: audio
        autoLoad: true

        property var currentMusic;

        property int progress: 0;

        onPlaybackStateChanged: {
            console.log("Playback audio.state="+audio.playbackState+" audioPlayer.state="+audioPlayer.playbackState);

            if (audio.playbackState===Audio.StoppedState) {
                progress=0;
            }

            if (audio.playbackState===Audio.StoppedState && audioPlayer.playbackState===Audio.PlayingState) {
                // console.log("Identify a forward");
                forward();
                return;
            }
        }

        onCurrentMusicChanged: {
            image.source=(currentMusic && currentMusic.imageURL) || "";
        }

        onPositionChanged: {
            //            console.log("Position="+position+"/"+duration);
            if (!duration) {
                progress=0;
                return;
            }

            progress=Math.floor(position/duration*100);
        }

        onProgressChanged: {
            //console.log("Progress="+progress);
            cursorProgress.width=Math.floor(progress*bgProgress.width/100);
            cursorProgress2.x=Math.floor(progress*(bgProgress.width-2)/100);
        }
    }

    Rectangle {
        id: image0
        width: parent.width
        height: parent.width
        x: 0
        y: 0

        border.color: "#D3D3D3"
        border.width: 1
        color: "#E9E9E9"
    }

    Text {
        id: text

        x: 1
        y: 1
        width: parent.width-2
        height: parent.width-2

        font.pixelSize: 72
        font.family: "fontawesome"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        opacity: 0.4
        text: Fontawesome.Icon.music
    }

    Image {
        id: image
        x: 0
        y: 0
        visible: !!image.source
        width: parent.width
        height: parent.width
        antialiasing: true
        fillMode: Image.PreserveAspectFit
    }
    Text {
        id: title

        x: 0
        y: parent.width
        width: parent.width
        height: 20

        font.bold: true
        font.pixelSize: 16
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    Text {
        id: artist

        x: 0
        y: title.y+title.height
        width: parent.width
        height: 20

        font.bold: false
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    Rectangle {
        id: bgProgress
        x: 0
        y: artist.y+artist.height
        width: parent.width
        height: 3
        color: "#BCBCBC"
    }
    Rectangle {
        id: cursorProgress
        x: 0
        y: bgProgress.y
        width: 0
        height: 3
        color: "#707070"
    }
    Rectangle {
        id: cursorProgress2
        x: 0
        y: bgProgress.y-2
        width: 2
        height: 5
        color: "black"
        visible: (audio.playbackState!==Audio.StopState)
    }
    Item {
        x: 0
        y: bgProgress.y+bgProgress.height
        height: 24
        width: parent.width

        Text {
            x: 1
            y: 1
            font.pixelSize: (audio.position>=60*60*1000)?10:12
            text: formatTime(audio.position);
        }
        Text {
            x: 0
            y: 1
            width: parent.width-1
            font.pixelSize: ((audio.duration-audio.position)>=60*60*1000)?10:12
            text: "-"+formatTime(audio.duration-audio.position);
            visible: audio.duration>0
            horizontalAlignment: Text.AlignRight
        }

        Row {
            id: commands
            x: (parent.width-childrenRect.width)/2
            width: childrenRect.width
            height: 24
            spacing: 8

            Text {
                text: Fontawesome.Icon.backward
                font.bold: true
                font.pixelSize: 16
                font.family: "fontawesome"
            }
            Text {
                text: (audio.playbackState==Audio.PlayingState)?Fontawesome.Icon.pause:Fontawesome.Icon.play
                font.bold: true
                font.pixelSize: 16
                font.family: "fontawesome"
            }
            Text {
                text: Fontawesome.Icon.forward
                font.bold: true
                font.pixelSize: 16
                font.family: "fontawesome"
            }
        }
    }
}


