import QtQuick 2.2
import QtGraphicalEffects 1.0

import "../jasmin" 1.0
import "../components/infos" 1.0

Item {
    height: rowInfo.height
    width: parent.width

    property var xml
    property string resImageSource;
    property string upnpClass;

    property int markerPosition: 80;

    property string borderColor: "#D3D3D3"
    property string backgroundColor: "#E9E9E9"


    Component {
        id: object

        Object {

        }
    }

    Component {
        id: object_container_album

        ObjectContainerAlbum {

        }
    }

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

    Item {
        id: rowInfo
        width: parent.width
        height: childrenRect.height

        Image {
            id: background
            source: (resImageSource?resImageSource:'')
            asynchronous: true
            sourceSize.height: 8
            sourceSize.width: 8
            x: 0
            y: 0
            width: parent.width
            height: parent.height
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

        Component.onCompleted: {
            if (!rowInfo) {
                return;
            }


            var upnpClasses = {
                "object.container.album": object_container_album,
                "object": object
            }


            var infoClass;

            var clz=upnpClass;

            for(;clz;) {
              //console.log("Try "+clz);

                infoClass=upnpClasses[clz];
                if (infoClass) {
                    break;
                }

                clz=/(.*)(\.[a-z]+)$/i.exec(clz)[1];
            }

            if (!infoClass) {
                infoClass=object;
            }


            var obj=infoClass.createObject(rowInfo, {
                                               xml: xml,
                                               resImageSource: resImageSource
                                           })

            obj.anchors.left=rowInfo.left;
            obj.anchors.right=rowInfo.right;
            obj.anchors.top=rowInfo.top;
        }
    }
}
