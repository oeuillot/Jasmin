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

    property string upnpClass;

    property string resImageSource;

    property var upnpServer;

    property Item imageItem;

    property alias title: label.text;

    property double rating: CardScript.getRating(model)

    property bool selected: false;

    onModelChanged: {
        //console.log("Xml="+Util.inspect(model, false, {}));

        if (imageItem) {
            imageItem.visible=false;
            imageItem.destroy();
            imageItem=null;
        }

        if (!model) {
            upnpClass="";
            resImageSource="";
            return;
        }


        upnpClass=model.byTagName("class", UpnpServer.UPNP_METADATA_XMLNS).text() || "object.item";

        // console.log("upnpclass="+upnpClass);

        resImageSource=CardScript.computeImage(model, upnpClass) || "";
    }

    function delayedUpdateModel() {

        if (imageItem) {
            imageItem.visible=false;
            imageItem.destroy();
            imageItem=null;
        }

        if (!resImageSource) {
            return false;
        }

        imageItem=resImage.createObject(rectImage);
    }

    Item {
        id: rectangle
        width: 154
        height: 190

        focus: true

        Rectangle {
            visible: card.selected
            width: parent.width
            height: parent.height

            color: "transparent"
            opacity: 0.1
            radius: 5
        }

        Rectangle {
            id: rectImage
            x: card.selected?2:10
            y: card.selected?2:10
            width: parent.width-(card.selected?2:10)*2
            height: parent.width-(card.selected?2:10)*2
            border.color: (rectangle.activeFocus)?"#FFB3B3":"#D3D3D3"
            border.width: 1
            color: "#E9E9E9"

            Text {
                id: itemType
                x: 1
                y: 1
                width: parent.width-2
                height: parent.height-2

                opacity: 0.4
                text: CardScript.computeType(upnpClass);
                font.pixelSize: 92+(card.selected?4:0)
                font.family: "fontawesome"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Component {
                id: resImage

                Item {
                    x: 1
                    y: 1
                    width: parent.width-2
                    height: parent.height-2

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

                        source: "card/transparent.png"
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
                    }
                }
            }
        }

        Rectangle {
            x: 2
            y: label.y
            width: parent.width-4
            height: label.height+info.height
            opacity: 0.4
            color: "red"
            visible: rectangle.activeFocus
        }

        Text {
            id: label
            y: rectImage.y+rectImage.height
            x: card.selected?2:10
            width: parent.width-x;
            color: "#404040"
            elide: Text.ElideMiddle
            font.bold: true
            font.pixelSize: (text && text.length>14)?14:16
            text: CardScript.computeLabel(model, upnpClass)
        }

        Text {
            id: info
            visible: card.rating<0 && !card.selected
            y: label.y+label.height
            x: card.selected?2:10
            width: parent.width-x;
            color: "#9A9AA2"
            elide: Text.ElideMiddle
            font.bold: true
            font.pixelSize: (text && text.length>14)?12:14
            text: CardScript.computeInfo(model, upnpClass)
        }

        Text {
            id: rating
            visible: card.rating>=0 && !card.selected
            y: label.y+label.height
            x: card.selected?2:10
            color: "#FFCB00"
            font.bold: true
            font.pixelSize: 14
            font.family: "fontawesome"
            text: CardScript.computeRatingText(card.rating)
        }

    }
}
