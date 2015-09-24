import QtQuick 2.2
import QtGraphicalEffects 1.0
import "../../jasmin" 1.0
import ".." 1.0

import "object.js" as UpnpObject
import "object_item_videoItem.js" as ObjectItemVideoItem;

FocusInfo {
    id: videoItem
    height: childrenRect.height;

    property var contentDirectoryService;
    property var xml
    property var infoClass;
    property var resImageSource;
    property var objectID;


    Item {
        id: infosColumn

        x: 30
        y: 20
        width: parent.width-((resImageSource)?(256+20):0)-60
        height: childrenRect.height+20


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

        TitleInfo {
            id: titleInfo
            x: 0
            y: 0
            width: parent.width;
            title: UpnpObject.getText(xml, "dc:title");

            Rating {
                id: rating
                xml: videoItem.xml

                font.pixelSize: 20;
                font.bold: false;
            }


            Row {
                spacing: 8
                height: 32
                x: (rating.visible)?(rating.x+rating.width+32):0;

                Text {
                    id: playButton
                    text: Fontawesome.Icon.play
                    font.bold: true
                    font.pixelSize: 20
                    font.family: Fontawesome.Name

                    focus: true
                    color: "black"

                    Keys.onPressed: {

                        var ls=ObjectItemVideoItem.listResources(contentDirectoryService, xml);

                        var res=ls[0];
                        if(!res) {
                            return;
                        }
                        console.log("Res="+res.source);

                        var avTransport=new AvTransport.AvTransport("http://192.168.3.193:54243/service/AVTransport/control");

                        avTransport.sendSetAvTransportURI(res.source, xml);
                    }

                    onActiveFocusChanged: {
                        videoItem.showFocus(playButton, activeFocus);
                    }

                    Component.onCompleted: {
                        playButton.forceActiveFocus();
                    }
                }
            }
        }

        Text {
            id: summary
            x: 0
            y: titleInfo.y+titleInfo.height;

            Component.onCompleted: {
                console.log("Xml="+Util.inspect(xml, false, {}));

            }
        }
    }

    ImageColumn {
        id: imageColumn
        resImageSource: videoItem.resImageSource
        infosColumn: infosColumn
        showReversedImage: false
    }

}
