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

    property var upnpServer;

    property Item imageItem;

    property alias title: label.text;

    property bool selected: false;

    property bool transparentImage: false;

    property bool infoDisplayed: false;

    property real selectedScale: 10;

    onSelectedChanged: PropertyAnimation { target: card; property: "selectedScale"; to: (selected?2:10); duration: 150 }

    onModelChanged: {
        //console.log("Xml="+Util.inspect(model, false, {}));

        if (imageItem) {
            imageItem.visible=false;
            if (!model) {
                imageItem.destroy();
                imageItem=null;
            }
        }

        if (!model) {
            resImageSource="";
            transparentImage=false;
            label.text="";
            info.infoVisible=false;
            rating.visible=false;
            itemType.text=CardScript.computeType(null);
            itemType.visible=true;
            return;
        }


        var upnpClass=model.byPath("upnp:class", UpnpServer.DIDL_XMLNS_SET).text() || "object.item";

        // console.log("upnpclass="+upnpClass);

        var img=CardScript.computeImage(model, upnpClass);
        if (img) {
            resImageSource=img.source;
            transparentImage=img.transparent;

        } else {
            resImageSource="";
            transparentImage=false;
        }

        itemType.text= CardScript.computeType(upnpClass);
        itemType.visible=true;

        label.text=CardScript.computeLabel(model, upnpClass) || "";
        itemType.text= CardScript.computeType(upnpClass);


        var ratingV=CardScript.getRating(model)
        if (ratingV<0) {
            rating.visible=false;
            info.text=CardScript.computeInfo(model, upnpClass) || "";
            info.infoVisible=true;
        } else {
            info.infoVisible=false;
            rating.text=CardScript.computeRatingText(ratingV)
            rating.visible=true;
        }
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

                        visible: transparentImage
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

                        onStatusChanged: {
//                            console.log("status="+status);
                            if (status===Image.Ready) {
                                itemType.visible=false;
                            }
                        }
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

        Text {
            id: info
            property bool infoVisible: false
            visible: infoVisible && !infoDisplayed
            y: label.y+label.height
            x: selectedScale
            width: parent.width-x;
            color: "#8A8A92"
            elide: Text.ElideMiddle
            font.bold: true
            font.pixelSize: (text && text.length>14)?12:14
        }

        Text {
            id: rating
            visible: false //card.rating>=0 && !card.selected
            y: label.y+label.height
            x: selectedScale
            color: "#FFCB00"
            font.bold: true
            font.pixelSize: 14
            font.family: "fontawesome"
        }
    }
}
