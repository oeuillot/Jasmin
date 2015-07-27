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
            ctx.stroke();
            ctx.clip();

            ctx.fillRect(0, 0, width, height);

            //ctx.drawImage(background, 0, 0, 128, 128);
        }
        /*
        Component.onCompleted: {
            console.log("Loadimge="+resImageSource);
            loadImage(resImageSource);
        }
        onImageLoaded: {
            var ctx = getContext('2d');
            ctx.drawImage(resImageSource, 0, 0, 16, 16);

            var data=ctx.getImageData(0, 0, 16, 16);

            console.log("data="+data, data.width, data.height, data.data);

            var bitmap=data.data;
            for(var i=0;i<bitmap.length;i++) {
                console.log("bit="+bitmap[i]);
            }

            unloadImage(resImageSource);
        }
        */
    }

    onBackgroundReadyChanged: {
        canvas.requestPaint();
        background.visible=false;
    }

    Item {
        id: rowInfo
        width: parent.width
        height: row.height;

        Rectangle {
            anchors.topMargin: 40
            width: 20
            height: 20
            color: "blue"
            visible: false
        }


        Image {
            id: background
            source: (resImageSource?resImageSource:'')
            asynchronous: true
            sourceSize.height: 8
            sourceSize.width: 8
            width: parent.width;
            height: parent.height;
            visible: false

            onStatusChanged: {
                if (status!==Image.Ready || !resImageSource) {
                    return;
                }

                fastBlur.visible=true;
            }
        }
        FastBlur {
            id: fastBlur
            visible: false
            anchors.fill: background
            source: background
            radius: 128
        }

        Item {
            id: row
            anchors.left: parent.left;
            anchors.right: parent.right;
            anchors.top: parent.top;
            height: childrenRect.height;

            Rectangle {
                id: infosColumn

                anchors.left: parent.left;
                anchors.top: parent.top;
                anchors.right: imageColumn.right;

                Row {
                    Text {

                    }
                }

                color: "blue"
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
    }
}
