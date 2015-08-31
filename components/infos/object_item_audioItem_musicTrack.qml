import QtQuick 2.2
import QtGraphicalEffects 1.0
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

    property bool layoutDone: false

    Item {
        id: row
        height: childrenRect.height;
        width: parent.width

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
                        KeyNavigation.down: separator;
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
                        KeyNavigation.down: separator;
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
                        KeyNavigation.down: separator;
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
return;
                var components = {
                    grid: gridComponent,
                    disc: discComponent
                }

                var d=ObjectContainerAlbum.fillTracks(infosColumn, components, 60, upnpServer, xml);

                d.then(function onSuccess(metas) {

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
        }
    }
}
