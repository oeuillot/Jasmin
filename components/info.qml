import QtQuick 2.2
import QtGraphicalEffects 1.0

Item {
    height: rowInfo.height
    width: parent.width

    property var xml
    property int markerPosition: 20;

    property string borderColor: "#D3D3D3"
    property string backgroundColor: "#E9E9E9"
    property bool backgroundReady: false;

    property var resImageSource;

    Canvas {
        id: canvas
        y: -12
        x: 0
        width: parent.width
        height: rowInfo.height+12
        onPaint: {
            var ctx = getContext('2d');

            var bg=backgroundColor;
            if (backgroundReady) {
                bg=ctx.createPattern(background, "no-repeat");
            }

            ctx.beginPath();
            ctx.fillStyle = bg;
            ctx.strokeStyle = borderColor;
            ctx.moveTo(0, 12);
            ctx.lineTo(markerPosition-12, 12);
            ctx.lineTo(markerPosition, 0);
            ctx.lineTo(markerPosition+12, 12);
            ctx.lineTo(width, 12);
            ctx.lineTo(width, height-1);
            ctx.lineTo(0, height-1);
            ctx.lineTo(0, 12);
            ctx.fill();
            ctx.stroke();
        }
    }

    onBackgroundReadyChanged: {
        canvas.requestPaint();
        background.visible=false;
    }

    Item {
        id: rowInfo
        width: parent.width
        height: 160;

        Rectangle {
            anchors.topMargin: 40
            width: 20
            height: 20
            color: "blue"
            visible: false
        }

        Image {
            id: background
            anchors.centerIn: parent
            source: (resImageSource?resImageSource:'')
            asynchronous: true
            sourceSize: Qt.size(16, 16)
            width: parent.width;
            height: parent.height
            visible: false
        }

        FastBlur {
            visible: !!resImageSource
            anchors.fill: background
            source: background
            radius: 128
        }
    }
}
