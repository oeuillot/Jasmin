import QtQuick 2.4
import fbx.ui.page 1.0
import fbx.ui.control 1.0
import fbx.media 1.0

Item {
    height: parent.height
    width: 80

    Rectangle: {
        height: parent.height;
        width: parent.width;

        opacity: 0.3
        color: "white"
    }


    AudioPlayer {
        id: audioPlayer
        width: parent.width
        height: parent.height
    }

    Component.onCompleted: {
        audioPlayer.source="http://127.0.0.1:10293/content/730";
        audioPlayer.play(0);
    }
}

