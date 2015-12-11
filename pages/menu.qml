/**
  * @author Olivier Oeuillot
  */

import QtQuick 2.4
import QtMultimedia 5.0
import fbx.ui.page 1.0
import fbx.ui.control 1.0
import "../components" 1.0
import "../services" 1.0

Item {
    id: menu
    height: parent.height
    width: 120    

    property AudioPlayer audioPlayer: audioPlayer

    property JSettings settings;

    Rectangle {
        height: parent.height;
        width: parent.width;

        opacity: 0.3
        color: "#FFFFFF"
    }

    AudioPlayer {
        id: audioPlayer

        width: parent.width
        height: parent.height
        settings: menu.settings
    }
}

