import QtQuick 2.2
import QtGraphicalEffects 1.0
import "../../jasmin" 1.0
import ".." 1.0

import "object.js" as UpnpObject

Item {
    id: row
    height: childrenRect.height;
    width: parent.width

    property var xml
    property var infoClass;
    property var resImageSource;

    property alias metadatasGrid: grid;

    Component {
        id: labelTitle

        Text {
            id: title
            font.bold: false
            font.pixelSize: 12

            horizontalAlignment: Text.AlignRight

            width: 80
        }
    }

    Component {
        id: valueTitle

        Text {
            id: value
            font.bold: true
            font.pixelSize: 12
        }
    }


    Item {
        id: infosColumn

        x: 30
        y: 20
        width: parent.width-(resImageSource?(20+imageColumn.width):0)-30-30
        height: childrenRect.height+20
        anchors.margins: 10;

        Column {
            spacing: 8
            width: parent.width-10
            x: 0
            y: 0

            Text {
                text: UpnpObject.getText(xml, "dc:title");
                font.bold: true
                font.pixelSize: 20
            }

            Rectangle {
                height: 1
                opacity: 0.3
                color: "black"
                width: parent.width
            }
            Item {
                height: 10
            }

            Grid {
                id: grid
                columns: 2
                spacing: 6

                Component.onCompleted: {
                    UpnpObject.addLine(grid, labelTitle, valueTitle, "Date :", xml, "dc:date", UpnpObject.dateFormatter);
                    UpnpObject.addLine(grid, labelTitle, valueTitle, "Taille :", xml, "res@size", UpnpObject.sizeFormatter);
                }
            }
        }
    }

    Item {
        id: imageColumn
        anchors.top: parent.top;
        anchors.right: parent.right;
        visible: !!resImageSource

        anchors.margins: 30;

        width: childrenRect.width;
        height: childrenRect.height+30;

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

            source: (resImageSource?resImageSource:'')
            asynchronous: true

        }
    }
}
