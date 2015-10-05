import QtQuick 2.2
import QtGraphicalEffects 1.0
import QtMultimedia 5.0

import "../../jasmin" 1.0
import ".." 1.0

import "object.js" as UpnpObject

FocusInfo {
    id: focusScope

    heightRef: imageColumn;

    property AudioPlayer audioPlayer;

    Item {
        id: infosColumn

        x: 30
        y: 20
        width: parent.width-((imagesList && imagesList.length)?(256+20):0)-60
        height: childrenRect.height+30


        TitleInfo {
            id: titleInfo
            x: 0
            y: 0
            width: parent.width;
            title: UpnpObject.getText(xml, "dc:title");

            Rating {
                id: rating
                xml: focusScope.xml

                font.pixelSize: 20;
                font.bold: false;
            }


            Row {
                id: commands
                spacing: 8
                height: 32
                x: (rating.visible)?(rating.x+rating.width+32):0;

                function processKeyEvent(event, shuffle) {
                    switch(event.key) {

                    case Qt.Key_PageDown:
                        // Ajoute les pistes du disque juste après celui qui est en écoute, sans forcement lancer le PLAY
                        event.accepted = true;

                        return audioPlayer.setPlayList(contentDirectoryService, [xml], resImageSource, true, audioPlayer.playListIndex+1);

                    case Qt.Key_PageUp:
                        // Ajoute les pistes du disque après les morceaux
                        event.accepted = true;

                        audioPlayer.setPlayList(contentDirectoryService, [xml], resImageSource, true);
                        return;

                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        // Joue le disque immediatement
                        event.accepted = true;

                        audioPlayer.clear().then(function() {
                            return audioPlayer.setPlayList(contentDirectoryService, [xml], resImageSource);

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

                    KeyNavigation.right: randomButton
                    KeyNavigation.left: randomButton

                    Keys.onPressed: {
                        commands.processKeyEvent(event, false);
                    }

                    onActiveFocusChanged: {
                        focusScope.showFocus(playButton, activeFocus);
                    }

                    Component.onCompleted: {
                        playButton.forceActiveFocus();
                    }
                }
                Text {
                    id: randomButton
                    text: Fontawesome.Icon.random
                    font.bold: true
                    font.pixelSize: 20
                    font.family: Fontawesome.Name

                    focus: true

                    KeyNavigation.left: playButton
                    KeyNavigation.right: playButton

                    Keys.onPressed: {
                        commands.processKeyEvent(event, true);
                    }

                    onActiveFocusChanged: {
                        focusScope.showFocus(randomButton, activeFocus);
                    }
                }
            }
        }
    }

    ImageColumn {
        id: imageColumn
        imagesList: focusScope.imagesList
        infosColumn: infosColumn
        showReversedImage: true
    }
}
