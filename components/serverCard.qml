import QtQuick 2.0

import "card.js" as CardScript
import "../jasmin" 1.0

import "fontawesome.js" as Fontawesome;

FocusScope {
    id: card

    x: rectangle.x;
    y: rectangle.y
    width: rectangle.width;
    height: rectangle.height

    property var model;

    property string resImageSource;

    property var contentDirectoryService;

    property Item imageItem;

    property alias title: label.text;

    property bool selected: false;

    property real selectedScale: 10;

    onSelectedChanged: {
        if (selectedAnimation.running) {
            selectedAnimation.stop();
        }

        selectedAnimation.to=(selected?2:10);
        selectedAnimation.start();
    }

    PropertyAnimation {
        id: selectedAnimation;
        target: card;
        property: "selectedScale";
        duration: 150
    }

    onModelChanged: {
        //console.log("Xml="+Util.inspect(model, false, {}));

        selectedScale=10;

        resImageSource=model.imageURL || "";

        label.text=model.label;
    }


    Item {
        id: rectangle
        width: 154
        height: 190

        focus: true

        Rectangle {
            id: rectImage
            x: selectedScale
            y: selectedScale
            width: parent.width-selectedScale*2
            height: parent.width-selectedScale*2
            border.color: "#D3D3D3"
            border.width: 1
            color: "#E9E9E9"

            Text {
                id: itemType
                x: 1
                y: 1
                width: parent.width-2
                height: parent.height-2

                opacity: 0.4
                font.pixelSize: 92+(4-Math.floor((selectedScale-2)/2));
                font.family: Fontawesome.Name
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: model.icon || Fontawesome.Icon.hdd_o
            }

            Image {
                x: 0
                y: 0
                width: parent.width
                height: parent.height

                smooth: true
                antialiasing: true
                asynchronous: true
                fillMode: Image.PreserveAspectFit

                sourceSize.width: 256
                sourceSize.height: 256

                source: resImageSource

                onStatusChanged: {
                    //                            console.log("status="+status);
                    if (status===Image.Ready) {
                        itemType.visible=false;
                    } else {
                        itemType.visible=true;
                    }
                }
            }
        }
        Text {
            id: label
            y: rectImage.y+rectImage.height
            x: selectedScale
            width: parent.width-x;
            color: "#404040"
            elide: Text.ElideMiddle
            font.bold: true
            font.pixelSize: (text && text.length>14)?14:16
        }
    }
}
