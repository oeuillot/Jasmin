import QtQuick 2.2
import QtGraphicalEffects 1.0

import "../jasmin" 1.0
import "../components/infos" 1.0


Item {
    id: widget
    height: rowInfo.height
    width: parent.width

    property Card card;

    property AudioPlayer audioPlayer;
    property var upnpServer;
    property var xml
    property string resImageSource;
    property string upnpClass;
    property int cellIndex;

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
 
 
    Component {
        id: object_item_audioItem_musicTrack

        ObjectItemAudioItemMusicTrack {

        }
    }
    
    

    Canvas {
        id: canvas
        y: -12
        x: 0
        width: parent.width
        height: rowInfo.height+12
        visible: false

        property int cnt : 0;
        property bool done : false;

        onPaint: {
            //            console.log("Paint ! "+(cnt), " "+done+" "+height);
            /*
            if (cnt!==1 && (height>256)) {
                cnt++;
                return;
            }
            cnt++;
*/
            return;
            var ctx = getContext('2d');

            ctx.reset(); // If Height changed !

            ctx.beginPath();
            ctx.fillStyle = "#E9E9E9";
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
        }
    }

    Item {
        id: rowInfo
        width: parent.width
        height: childrenRect.height

        onChildrenRectChanged: {
            console.log("h="+childrenRect.height);

            //canvas.visible=true;
        }

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


        Keys.onPressed: {

            switch(event.key) {
            case Qt.Key_Up:
//                console.log("UPPPPP");

                 card.forceActiveFocus();
                 event.accepted=true;
            }
        }

        Component.onCompleted: {

            //console.log("COMPLETED ! "+xml);

            var upnpClasses = {
                "object.container.album": object_container_album,
                "object.item.audioItem.musicTrack": object_item_audioItem_musicTrack,
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

            //console.log("Info class="+infoClass+Util.inspect(xml, false, {}));

            var objectID=xml.attr("id");

            upnpServer.browseMetadata(objectID).then(function onSuccess(meta) {

                var xml=meta.result.byPath("DIDL-Lite", UpnpServer.DIDL_XMLNS_SET).first().children();

                //console.log("xml1="+Util.inspect(xml));

                var obj=infoClass.createObject(rowInfo, {
                                                   x: 0,
                                                   y: 0,
                                                   width: rowInfo.width,
                                                   xml: xml,
                                                   resImageSource: resImageSource,
                                                   upnpServer: widget.upnpServer,
                                                   audioPlayer: widget.audioPlayer,
                                                   objectID: objectID
                                               });
            });
        }
    }
}
