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

    property var currentTrack: null;

    property string playingObjectID: (currentTrack?currentTrack.objectID:"");

    property int playbackState: Audio.StoppedState;

    function setPlayList(upnpServer, xmlArray, albumImageURL, playListIndex, shuffle, append) {
        //console.log("setPlay: xml="+xmlArray+" playListIndex="+playListIndex+" shuffle="+shuffle+" append="+append);

        if (!append) {
            return clear().then(function() {
                playListIndex=0;
                _setPlayList(upnpServer, xmlArray, albumImageURL, playListIndex, shuffle);
            });
        }

        // append


        _setPlayList(upnpServer, xmlArray, albumImageURL, playListIndex, shuffle);
        return Deferred.resolved();
    }

    function _fillInfo(upnpServer, xml, albumImageURL, playList ) {
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

            playList.push({
                              objectID: objectID,
                              xml: xml,
                              url: url,
                              imageURL: imageURL,
                              title: title,
                              artist: artist
                          });

            return false; // Break the loop if forEach support it :-)
       });

        return found;
    }

    function _setPlayList(upnpServer, xmlArray, albumImageURL, playListIndex, shuffleP) {

        if (shuffleP!==undefined) {
            shuffle=shuffleP;
        }

        // console.log("xmlArray="+xmlArray);

        if (!(xmlArray instanceof Array)) {
            xmlArray=[xmlArray];
        }

        xmlArray.forEach(function(xml) {
            _fillInfo(upnpServer, xml, albumImageURL, playList);
        });
    }

    function clear() {
        return stop().then(function() {
            // remove all ...
            playingObjectID="";


            playList=[];
            playListIndex=0;

            return true;
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
            return true;
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

            return playIndex(playListIndex+1);
        });
    }

    function playIndex(index) {
        //console.log("PLAY index #"+index);

        playListIndex=index;
        if (playListIndex>=playList.length) {
            return Deferred.resolved(false);
        }

        return audio.$stop().then(function() {

            currentTrack=playList[playListIndex];;

            return audio.$play().then(function() {
                playbackState=Audio.PlayingState;

                return playbackState;
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

        source: (currentTrack && currentTrack.url) || ""

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
        source: (currentTrack && currentTrack.imageURL) || "";
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

        text: (currentTrack?(currentTrack.title || "Inconnu"):"")
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

        text: (currentTrack?(currentTrack.artist || "Inconnu"):"")
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


