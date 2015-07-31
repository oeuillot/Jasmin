import QtQuick 2.4
import QtMultimedia 5.0
import fbx.ui.page 1.0
import fbx.ui.control 1.0

import "../jasmin" 1.0
import "." 1.0

Item {
    id: audioPlayer
    height: childrenRect.height

    property var playList: []

    property alias playbackState: audio.playbackState;

    property string playingObjectID: "";

    function addMusic(upnpServer, xml, albumImageURL, url) {

        console.log("Add music "+Util.inspect(xml, false, {}), url);

        if (url) {
            playList.push({
                              xml: xml,
                              url: url,
                              imageURL: albumImageURL
                          });

            return;
        }

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
        });
    }

    function playMusic(upnpServer, xml, albumImageURL) {
        console.log("PlayMusic "+xml);
        playList=[];
        audio.stop();

        addMusic(upnpServer, xml, albumImageURL);

        popPlayList();
    }

    function pause() {
        audio.pause();
    }

    function play() {
        audio.play();
    }

    function popPlayList() {
        audio.stop();
        if (!playList.length) {
            return;
        }
        var music=playList.shift();

        console.log("Set source="+music.url);

        audio.source=music.url;
        audio.currentImageURL=music.imageURL;

        title.text=music.title || "Inconnu";
        artist.text=music.artist || "Inconnu";

        playingObjectID=music.objectID;

        audio.play();
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

    Audio {
        id: audio
        autoLoad: true

        property var currentXML;
        property var currentImageURL;

        property int progress: 0;

        onPlaybackStateChanged: {
            console.log("Playback state "+playbackState);
        }

        onCurrentImageURLChanged: {
            image.source=currentImageURL;
        }

        onPositionChanged: {
            //console.log("Position="+position+"/"+duration);
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

    Image {
        id: image1
        x: (parent.width-width)/2
        y: (parent.width-height)/2
        width: 64
        height: 64
        antialiasing: true
        source: "card/music.png"
        opacity: 0.4
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
        visible: (audio.playbackState==Audio.PlayingState)
    }
    Item {
        x: 0
        y: bgProgress.y+bgProgress.height
        height: 24
        width: parent.width

        Text {
            x: 1
            y: 1
            font.pixelSize: (audio.position>=60*60*1000)?9:12
            text: formatTime(audio.position);
        }
        Text {
            x: 0
            y: 1
            width: parent.width-1
            font.pixelSize: ((audio.duration-audio.position)>=60*60*1000)?9:12
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


