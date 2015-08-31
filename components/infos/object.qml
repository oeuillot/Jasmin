import QtQuick 2.2
import QtGraphicalEffects 1.0
import "../../jasmin" 1.0
import ".." 1.0

import "object.js" as UpnpObject

Item {
    id: row
    height: childrenRect.height;

    property var upnpServer;
    property var xml
    property var infoClass;
    property var resImageSource;
    property var objectID;

    property alias metadatasGrid: grid;

    Component {
        id: labelComponent

        Text {
            id: title
            font.bold: false
            font.pixelSize: 14

            horizontalAlignment: Text.AlignRight
        }
    }

    Component {
        id: valueComponent

        Text {
            id: value
            font.bold: true
            font.pixelSize: 14
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
                width: parent.width;
                elide: Text.ElideRight
                text: UpnpObject.getText(xml, "dc:title");
                font.bold: true
                font.pixelSize: (text.length<60)?20:((text.length<100)?16:14)
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
                    //console.log("Xml="+Util.inspect(xml, false, {}));

                    var hasDate;

                    hasDate=!!UpnpObject.addLine(grid, labelComponent, valueComponent, "Date de création :", xml, "fm:birthTime", UpnpObject.dateFormatter);
                    hasDate=!!UpnpObject.addLine(grid, labelComponent, valueComponent, "Date de modification :", xml, "fm:modifiedTime", UpnpObject.dateFormatter) || !hasDate;
                    //UpnpObject.addLine(grid, labelComponent, valueComponent, "Date d'accés :", xml, "fm:accessTime", UpnpObject.dateFormatter);
                    // UpnpObject.addLine(grid, labelComponent, valueComponent, "Date de changement:", xml, "fm:changeTime", UpnpObject.dateFormatter);

                    if (!hasDate){
                        UpnpObject.addLine(grid, labelComponent, valueComponent, "Date :", xml, "dc:date", UpnpObject.dateFormatter);
                    }
                    UpnpObject.addLine(grid, labelComponent, valueComponent, "Année :", xml, "dc:date", UpnpObject.dateYearFormatter);
                    UpnpObject.addLine(grid, labelComponent, valueComponent, "Taille :", xml, "res@size", UpnpObject.sizeFormatter);
                    UpnpObject.addLine(grid, labelComponent, valueComponent, "Nombre de fichiers :", xml, "@childCount");
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
            cache: false

            source: (resImageSource?resImageSource:'')
            asynchronous: true

        }
    }
}
