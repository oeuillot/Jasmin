/**
 * Copyright Olivier Oeuillot
 */
 
import QtQuick 2.2
import QtGraphicalEffects 1.0

import "../jasmin" 1.0
import "../components/infos" 1.0
import "card.js" as CardScript


FocusScope {
    id: widget
    height: infoComponent.height
    width: infoComponent.width

    property bool winOS: false;

    property Card card;

    property AudioPlayer audioPlayer;
    property var contentDirectoryService;
    property var xml

    property var imagesList: null;

    property string resImageSource: (imagesList && imagesList.length)?imagesList[0].url:'';

    property string upnpClass;
    property int cellIndex;

    property int markerPosition: 80;

    property string borderColor: "#D3D3D3"
    property string backgroundColor: "#E9E9E9"


    Item {
        id: infoComponent
        height: rowInfo.height
        width: parent.width

        Component {
            id: object

            Object {

            }
        }

        Component {
            id: object_container_album

            ObjectContainerAlbumMusic {

            }
        }


        Component {
            id: object_item_audioItem_musicTrack

            ObjectItemAudioItemMusicTrack {

            }
        }

        Component {
            id: object_item_videoItem

            ObjectItemVideoItem {

            }
        }


        Rectangle {
            y: 0
            x: 0
            width: parent.width
            height: rowInfo.height

            border.color: borderColor
            color: "#E9E9E9";
        }

        Canvas {
            id: arrow
            y: -12
            x: markerPosition+y
            width: -y*2
            height: 2-y
            contextType: "2d"

            onPaint: {                
                var ctx=context;
                if (!ctx) {
                    ctx=getContext("2d");
                }

                ctx.beginPath();
                ctx.fillStyle = "#E9E9E9";
                ctx.moveTo(0, -y);
                ctx.lineTo(-y, 0);
                ctx.lineTo(-y*2, -y);
                ctx.lineTo(-y*2, -y+2);
                ctx.lineTo(0, -y+2);
                ctx.fill();

                ctx.beginPath();
                ctx.strokeStyle = borderColor;
                ctx.moveTo(0, -y);
                ctx.lineTo(-y, 0);
                ctx.lineTo(-y*2, -y);
                ctx.stroke();

            }

            onYChanged: {
                //requestPaint();
            }
        }
/*

        NumberAnimation {
                id: arrowAnimation
                target: arrow
                properties: "y"
                from: 0
                to: -12
                duration: 200
           }
*/
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


            Keys.onPressed: {

                switch(event.key) {
                case Qt.Key_Up:
                    widget.destroy();

                    card.forceActiveFocus();                    
                    event.accepted=true;
                }
            }

            Component.onCompleted: {

                //console.log("COMPLETED ! "+xml);

                //console.log("AudioPlayer="+audioPlayer);

                var upnpClasses = {
                     "object.item.videoItem": object_item_videoItem,
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

                contentDirectoryService.browseMetadata(objectID).then(function onSuccess(meta) {

                    var xml=meta.result.byPath("DIDL-Lite", ContentDirectoryService.DIDL_XMLNS_SET).first().children();

                    if (!imagesList || !imagesList.length) {
                        imagesList=CardScript.computeImage(xml, contentDirectoryService);
                    }

                    //console.log("xml1="+Util.inspect(xml));

                    var obj=infoClass.createObject(rowInfo, {
                                                       x: 0,
                                                       y: 0,
                                                       width: rowInfo.width,
                                                       xml: xml,
                                                       imagesList: imagesList,
                                                       contentDirectoryService: contentDirectoryService,
                                                       audioPlayer: audioPlayer,
                                                       objectID: objectID
                                                   });
                });
            }
        }
    }
    Component.onCompleted: {
//        arrowAnimation.start();
    }
}
