import QtQuick 2.0

import "card.js" as CardScript
import "../jasmin" 1.0

FocusScope {
    id: card

    x: rectangle.x; y: rectangle.y
    width: rectangle.width; height: rectangle.height

    property var xml;

    property alias title: label.text;

    onXmlChanged: {
        if (!xml.nodes) {
            return;
        }

        var $xml=Xml.$XML(xml.nodes);

        var upnpClass=$xml.byTagName("class", UpnpServer.UPNP_METADATA_XMLNS).text() || "object.item";

        // console.log("upnpclass="+upnpClass);

        rectangle.visible=true;
        image.source=CardScript.computeImage($xml, upnpClass, image, resImage);
        card.title= CardScript.computeLabel($xml, upnpClass);
        info.text= CardScript.computeInfo($xml, upnpClass);
    }

    Item {
        id: rectangle
        width: 160
        height: 180

        visible: false

        focus: true

        Rectangle {
            visible: rectangle.activeFocus
            anchors.fill: parent;

            color: "red"
            opacity: 0.1
            radius: 5
        }

        Column {
            anchors.fill: parent
            anchors.leftMargin: rectangle.activeFocus?2:10
            anchors.rightMargin: rectangle.activeFocus?2:10
            anchors.bottomMargin: rectangle.activeFocus?2:10
            anchors.topMargin: rectangle.activeFocus?2:10

            spacing: 4

            Rectangle {

                width: parent.width-parent.anchors.leftMargin-parent.anchors.rightMargin
                height: parent.width-parent.anchors.leftMargin-parent.anchors.rightMargin
                border.color: "#D3D3D3"
                border.width: 1
                color: "#E9E9E9"

                Item {
                    x: 1
                    y: 1
                    width: parent.width-2
                    height: parent.height-2
                    clip: true

                    Image {
                        id: image
                        anchors.centerIn: parent
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit

                        opacity: 0.4
                        width: 64
                        height: 64
                    }

                    Component {
                        id: resImage

                        Image {
                            objectName: 'res'

                            smooth: true
                            anchors.centerIn: parent
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                }
            }

            Text {
                id: label
                width: parent.width;
                color: "#404040"
                elide: Text.ElideMiddle
                font.bold: true
                font.pixelSize: (text && text.length>14)?14:16

            }

            Text {
                id: info
                width: parent.width;
                color: "#9A9AA2"
                elide: Text.ElideMiddle
                font.bold: true
                font.pixelSize: (text && text.length>14)?12:14
                visible: !rectangle.activeFocus
            }

        }
    }
}
