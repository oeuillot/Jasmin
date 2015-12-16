import QtQuick 2.0

Item {
    width: parent.width
    height: 32

    property alias title: titleComponent.text;

    Text {
        id: titleComponent
        font.pixelSize: 16
        x: 10
        y: parent.height-30
        width: parent.width
        height: 20
        color: "#666666"
    }

    Rectangle {
        x: 10
        y: parent.height-8
        width: parent.width-x*2
        height: 1
        color: "#AAAAAA"
    }
}
