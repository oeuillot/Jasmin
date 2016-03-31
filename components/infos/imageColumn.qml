import QtQuick 2.0

import "../card.js" as CardScript

Item {
    id: imageColumn
    x: parent.width-256-30
    y: 30

    property var imagesList;
    property var filtredImagesList: CardScript.filterByWidth(imagesList, 256);
    property string resImageSource: (filtredImagesList && filtredImagesList.length)?filtredImagesList[0].url:'';
    property Item infosColumn;

    property int cycleIndex: 0;

    property real imagesOpacity: 1;

    property bool showReversedImage: true;

    visible: !!resImageSource
    clip: true

    width: 256;
    height: Math.max(infosColumn.height+20, 30+256+30)-30;

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
        opacity: imagesOpacity

        source: resImageSource;
        asynchronous: true
    }

    Image {
        x: 0
        y: image2.paintedHeight+Math.floor((256-image2.paintedHeight)/2);
        width: 256
        height: 256

        visible: showReversedImage

        opacity: imagesOpacity*0.25

        smooth: true
        antialiasing: true
        asynchronous: true

        transform: Rotation {
            origin.x: 128;
            origin.y: image2.paintedHeight/2;
            axis { x: 1; y: 0; z: 0 }
            angle: 180 }

        sourceSize.width: 256
        sourceSize.height: 256

        fillMode: Image.PreserveAspectFit
        source: resImageSource
    }

    onFiltredImagesListChanged: {
        if (!filtredImagesList || filtredImagesList.length<2) {
            timer.stop();
            return;
        }

        timer.restart();
    }

    Timer {
        id: timer
        interval: 4000;
        repeat: true

        onTriggered: {
            if (!running) {
                return;
            }

            cycleIndex++;

            animations.start();
        }
    }

    SequentialAnimation {
        id: animations
        NumberAnimation {
            target: imageColumn
            property: "imagesOpacity"
            duration: 400
            from: 1;
            to: 0;
        }
        ScriptAction {
            script: resImageSource=filtredImagesList[cycleIndex % filtredImagesList.length].url
        }
        ParallelAnimation {
            NumberAnimation {
                target: imageColumn
                property: "imagesOpacity"
                duration: 400
                from: 0;
                to: 1;
            }
            /*
            NumberAnimation {
                target: imageIndexItem
                property: "opacity"
                duration: 400
                from: 0;
                to: 0.7;
            }
            */
        }
        /*
        NumberAnimation {
            target: imageIndexItem
            property: "opacity"
            duration: 2500
            from: 0.7;
            to: 0;
        }
        */
    }

    Item {
        id: imageIndexItem
        width: idxText.contentWidth+8;
        height: idxText.contentHeight+4;
        x: image2.width-width
        y: image2.height-height

        opacity: 0

        visible: (filtredImagesList && filtredImagesList.length>1) || false;

        Rectangle {
            width: parent.width;
            height: parent.height;

            opacity: 0.7
            color: "white";

            border.color: "black";
            border.width: 1
        }

        Text {
            id: idxText
            x: 4

            property int imagesCount: (filtredImagesList && filtredImagesList.length) || 1;

           text: "Image "+((cycleIndex % imagesCount)+1)+"/"+imagesCount;
        }
    }
}
