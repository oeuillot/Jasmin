import QtQuick 2.2

import "object.js" as UpnpObject

FocusScope {
    id: focusScope
    x: titleRow.x
    y: titleRow.y
    height: 70
    width: parent.width

    focus: false

    property alias title: titleText.text;

    property alias textInfo: metaInfos.text;

    default property alias contents: titleRow.children

    Row {
        id: titleRow
        x: 0
        y: 0
        height: 32
        width: parent.width
        spacing: 16

        Text {
            id: titleText
            text: UpnpObject.getText(xml, "dc:title");
            font.bold: true
            font.pixelSize: 20
            elide: Text.ElideRight
        }
    }

    Text {
        id: metaInfos
        x: 0
        y: 26
        font.bold: false
        font.pixelSize: 16
        width: parent.width
        elide: Text.ElideMiddle
        height: 20
    }

    Rectangle {
        id: separator
        x: 0
        y: 50
        width: parent.width
        height: 1
        opacity: 0.3
        color: "black"
    }
}
