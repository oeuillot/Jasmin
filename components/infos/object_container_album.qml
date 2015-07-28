import QtQuick 2.2
import QtGraphicalEffects 1.0
import "../../jasmin" 1.0
import ".." 1.0

Item {
    id: row
    height: childrenRect.height;


    width: parent.width

    property var xml
    property var infoClass;
    property var resImageSource;

    function getText(xml, path, xmlns) {
        console.log(Util.inspect(xml, false, {}));
        if (!xml) {
            return "";
        }

        var text=xml.byPath(path, xmlns).text();

        return text || "";
    }


    Item {
        id: infosColumn

        anchors.left: parent.left;
        anchors.top: parent.top;
        anchors.right: imageColumn.left;
        height: childrenRect.height
        anchors.margins: 10;

        Row {
            Text {
                text: getText(xml, "dc:title", {dc: UpnpServer.PURL_ELEMENT_XMLS});
                font.bold: true
                font.pixelSize: 20
            }
            Text {
                text: Fontawesome.Icon.play
                font.bold: true
                font.pixelSize: 20
                font.family: "fontawesome"
            }
        }
    }

    Item {
        id: imageColumn
        anchors.top: parent.top;
        anchors.right: parent.right;

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
