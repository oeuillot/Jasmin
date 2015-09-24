import QtQuick 2.2
import QtGraphicalEffects 1.0
import QtMultimedia 5.0

import "../../jasmin" 1.0
import ".." 1.0

import "object.js" as UpnpObject

FocusScope {
    id: focusScope
    x: row.x
    y: row.y
    height: row.height
    width: parent.width

    property AudioPlayer audioPlayer;
    property var upnpServer;
    property var xml;
    property string resImageSource;
    property string objectID;

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

            Rating {
                id: rating

                xml: metas
            }

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
                    id: commands
                    spacing: 8
                    height: 32


                    function processKeyEvent(event, shuffle) {
                        switch(event.key) {

                        case Qt.Key_PageDown:
                            // Ajoute les pistes du disque juste après celui qui est en écoute, sans forcement lancer le PLAY
                            event.accepted = true;

                            return audioPlayer.setPlayList(upnpServer, [xml], resImageSource, true, audioPlayer.playListIndex+1);

                        case Qt.Key_PageUp:
                            // Ajoute les pistes du disque après les morceaux
                            event.accepted = true;

                            audioPlayer.setPlayList(upnpServer, [xml], resImageSource, true);
                            return;

                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            // Joue le disque immediatement
                            event.accepted = true;

                            audioPlayer.clear().then(function() {
                                 return audioPlayer.setPlayList(upnpServer, [xml], resImageSource);

                            }).then(function() {
                                audioPlayer.shuffle=shuffle;

                                audioPlayer.play();
                            });
                            return;
                        }

                    }

                    Text {
                        id: playButton
                        text: Fontawesome.Icon.play
                        font.bold: true
                        font.pixelSize: 20
                        font.family: Fontawesome.Name

                        focus: true
                        color: playButton.activeFocus?"red":"black";

                        KeyNavigation.right: randomButton
                        KeyNavigation.left: randomButton
                        KeyNavigation.down: separator;

                        Keys.onPressed: {
                            commands.processKeyEvent(event, false);
                        }
                    }
                    Text {
                        id: randomButton
                        text: Fontawesome.Icon.random
                        font.bold: true
                        font.pixelSize: 20
                        font.family: Fontawesome.Name

                        focus: true
                        color: randomButton.activeFocus?"red":"black";

                        KeyNavigation.left: playButton
                        KeyNavigation.right: playButton
                        KeyNavigation.down: separator;

                        Keys.onPressed: {
                           commands.processKeyEvent(event, true);
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
