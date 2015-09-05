import QtQuick 2.2
import QtGraphicalEffects 1.0
import QtMultimedia 5.0
import "../../jasmin" 1.0
import ".." 1.0

import "object.js" as UpnpObject
import "object_container_album.js" as ObjectContainerAlbum;

FocusScope {
    id: focusScope
    x: row.x
    y: row.y
    height: row.height
    width: parent.width

    property AudioPlayer audioPlayer;
    property var upnpServer;
    property var xml
    property string infoClass;
    property string resImageSource;
    property string objectID;

    property var metas: null;

    property bool layoutDone: false


    function playTracks(trackIndex, callback) {

        var disks=focusScope.metas.tracks;
        if (!disks) {
            return 0;
        }

        var ls=[];

        disks.forEach(function(tracks) {
            tracks.forEach(function(track) {
                ls.push(track.xml);
            });
        });

        if (callback) {
            ls=callback(ls);
        }

        audioPlayer.setPlayList(upnpServer, ls, resImageSource, trackIndex);
        audioPlayer.play();

        return ls.length;
    }


    Item {
        id: row
        height: childrenRect.height;
        width: parent.width


        Component {
            id: trackComponent


            FocusScope {
                width: 400
                height: 24

                property string point;
                property alias text: value.text
                property alias duration: duration.text
                property string type;

                property var xml;
                property string objectID;

                property bool playingObjectID: (focusScope.audioPlayer!=null && focusScope.audioPlayer.playingObjectID===objectID);

                Item {
                    width: 400
                    height: 24

                    Text {
                        id: title
                        font.bold: false
                        font.pixelSize: 12
                        x: 0
                        y: 2
                        opacity: 0.7

                        horizontalAlignment: (playingObjectID)?Text.AlignLeft:Text.AlignRight

                        font.family: (playingObjectID)?"fontawesome":value.font.family
                        text: (playingObjectID)?(focusScope.audioPlayer.playbackState===1?Fontawesome.Icon.volume_up:Fontawesome.Icon.volume_off):point

                        width: 16
                    }

                    function changePosition(source, offset) {
                        var list=source.parent.parent;
                        //                    console.log("Parent2="+list+" "+list.id);

                        var children=list.children;
                        for(var i=0;i<children.length;i++) {
                            if (children[i]!==this.parent) {
                                continue;
                            }

                            var next=children[i+offset];
                            if (next && next.type==="row") {
                                console.log("Next focus="+next+"/"+next.id);
                                next.children[1].forceActiveFocus();

                                return true;
                            }
                            break;
                        }

                        return false;
                    }

                    Text {
                        id: value
                        font.bold: true
                        font.pixelSize: 14
                        focus: true

                        color: activeFocus?"red": "black"

                        x: 20
                        y: 0
                        width: 370
                        height: 24
                        elide: Text.ElideRight
                    }

                    Keys.onPressed: {
                        switch(event.key) {
                        case Qt.Key_Right:
                            if (changePosition(this, 1)) {
                                event.accepted = true;
                            }
                            return;


                        case Qt.Key_Down:
                            if (changePosition(this, 2)) {
                                event.accepted = true;
                            }
                            return;

                        case Qt.Key_Left:
                            if (changePosition(this, -1)) {
                                event.accepted = true;
                            }
                            return;

                        case Qt.Key_Up:
                            if (changePosition(this, -2)) {
                                event.accepted = true;
                            }
                            return;

                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            //var res=xml.byPath("res", UpnpServer.DIDL_XMLNS_SET).first();

                            audioPlayer.playMusic(upnpServer, xml, resImageSource);
                            event.accepted = true;
                            return;
                        }
                    }


                    Text {
                        id: duration
                        x: 320
                        y: 2

                        font.bold: false
                        font.pixelSize: 12
                        opacity: 0.7

                        width: 30
                    }
                }
            }
        }

        Component {
            id: gridComponent

            FocusScope {
                Item {
                    x:0
                    width: 800
                }
            }
        }

        Component {
            id: discComponent

            Item {
                width: parent.width
                height: 28

                property alias text: discTitle.text

                Text {
                    id: discTitle
                    x: 0
                    y: 8
                    width: parent.width
                    font.bold: true
                    font.pixelSize: 12
                }
            }
        }


        Item {
            id: infosColumn

            x: 30
            y: 20
            width: parent.width-((resImageSource)?(256+20):0)-60
            height: childrenRect.height+30

            Row {
                x: 0
                y: 0
                height: 32
                width: parent.width
                spacing: 16

                Text {
                    text: UpnpObject.getText(xml, "dc:title");
                    font.bold: true
                    font.pixelSize: 20
                    elide: Text.ElideRight
                }

                Row {
                    spacing: 8
                    height: 32

                    Text {
                        id: playButton
                        text: Fontawesome.Icon.play
                        font.bold: true
                        font.pixelSize: 20
                        font.family: "fontawesome"

                        focus: true
                        color: playButton.activeFocus?"red":"black";

                        KeyNavigation.right: randomButton
                        KeyNavigation.left: menuButton

                        Keys.onPressed: {
                            switch(event.key) {

                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                event.accepted = true;

                                playTracks(0);
                            }
                        }
                    }
                    Text {
                        id: randomButton
                        text: Fontawesome.Icon.random
                        font.bold: true
                        font.pixelSize: 20
                        font.family: "fontawesome"

                        focus: true
                        color: randomButton.activeFocus?"red":"black";

                        KeyNavigation.left: playButton
                        KeyNavigation.right: menuButton

                        Keys.onPressed: {
                            switch(event.key) {

                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                event.accepted = true;

                                playTracks(0, function(tracks) {
                                    var ts=tracks.slice(0);
                                    for(var i=0;i<ts.length;i++) {
                                        var j=Math.floor(Math.random()*ts.length);
                                        var t=ts[i];
                                        ts[i]=ts[j];
                                        ts[j]=t;
                                    }
                                    return ts;
                                });
                                return;
                            }
                        }
                    }
                    Text {
                        id: menuButton
                        text: Fontawesome.Icon.ellipsis_h
                        font.bold: true
                        font.pixelSize: 20
                        font.family: "fontawesome"

                        color: menuButton.activeFocus?"red":"black";
                        focus: true

                        KeyNavigation.left: randomButton
                        KeyNavigation.right: playButton
                    }


                    Keys.onPressed: {

                        switch(event.key) {
                        case Qt.Key_Down:
                            var next=separator.nextItemInFocusChain();
                            console.log("DOWN "+next);
                            next.forceActiveFocus();
                            event.accepted=true;
                        }
                    }

                }
            }

            Text {
                id: metaInfos
                x: 0
                y: 26
                font.bold: false
                font.pixelSize: 16
                width: parent.width
                elide: Text.ElideMiddle
                height: 20

            }

            Rectangle {
                id: separator
                x: 0
                y: 50
                width: parent.width
                height: 1
                opacity: 0.3
                color: "black"
            }

            Component.onCompleted: {

                var components = {
                    grid: gridComponent,
                    track: trackComponent,
                    disc: discComponent
                }

                var d=ObjectContainerAlbum.fillTracks(infosColumn, components, 60, upnpServer, xml);

                d.then(function onSuccess(metas) {
                    focusScope.metas=metas;

                    var ms="";
                    var artists=metas.artists;
                    if (artists && artists.length) {
                        var l=Math.min(8, artists.length);

                        for(var i=0;i<l;i++) {
                            if (ms) {
                                ms+=", ";
                            }

                            ms+=artists[i];
                        }

                        if (artists.length>l) {
                            ms+=", ...";
                        }
                    }

                    if (metas.year) {
                        if (ms) {
                            ms+=" \u25CF "
                        }

                        ms+=metas.year;
                    }
                    metaInfos.text=ms;

                    infosColumn.height=infosColumn.childrenRect.height;
                });
            }
        }

        Item {
            id: imageColumn
            visible: !!resImageSource

            x: parent.width-256-30
            y: 30
            width: 256;
            height: 30+256+30;

            Image {
                id: image2
                width: 256
                height: 256
                x: 0
                y: 0

                sourceSize.width: 256
                sourceSize.height: 256

                antialiasing: true
                fillMode: Image.PreserveAspectFit
                cache: false

                source: (resImageSource?resImageSource:'')
                asynchronous: true

            }
        }

        Component.onCompleted: {
            focusScope.forceActiveFocus();

            console.log("**** audioPlayer="+audioPlayer);
        }
    }
}
