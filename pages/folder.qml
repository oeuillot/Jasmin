import QtQuick 2.2
import fbx.ui.page 1.0
import fbx.ui.control 1.0

import "folder.js" as FolderScript
import "../components" 1.0
import "../jasmin" 1.0

Page {
    id: page
    title: "Films HD"

    property var meta;
    property var upnpServer;
    property AudioPlayer audioPlayer;

    property var fillModelDeferred;

    property Card focusCard;

    property Info info

    Component {
        id: card

        Card {
            upnpServer: page.upnpServer

            property int cellIndex;

            Keys.onPressed: {
                if (event.key === Qt.Key_Return) {
                    listView.open(this, false);
                    event.accepted=true;
                    return;
                }

                if (event.key === Qt.Key_Left) {
                    if (listView.focusLeft(cellIndex)) {
                        event.accepted=true;
                    }
                    return;
                }

                if (event.key === Qt.Key_Right) {
                    if (listView.focusRight(cellIndex)) {
                        event.accepted=true;
                    }
                    return;
                }

                if (event.key === Qt.Key_Up) {
                    if (listView.focusTop(cellIndex)) {
                        event.accepted=true;
                    }
                    return;
                }

                if (event.key === Qt.Key_Down) {
                    if (listView.focusBottom(cellIndex)) {
                        event.accepted=true;
                    }
                    return;
                }
            }

            onActiveFocusChanged: {
                if (activeFocus) {
                    page.focus=this;

                    if (page.info) {
                        listView.open(this, true);

                    } else {
                        listView.show(this);
                    }

                    return;
                }

                if (page.focus===this) {
                    page.focus=null;
                }
            }
        }
    }
    Component {
        id: infoComponent

        Info {

        }
    }

    Component {
        id: infoContainerComponent

        Item {
            id: infoContainer
            visible: false
            width: parent.width
            height: 10
        }
    }


    QGrid {
        id: listView
        x: 5
        y: 5
        width: parent.width-140-5
        height: parent.height-5
        focus: true

        function open(card, auto) {
            console.log("Open card="+card.model);

            if (info) {
                info.destroy();
                info=null;
            }

            var xml=card.model;

            var upnpClass=xml.byTagName("class", UpnpServer.UPNP_METADATA_XMLNS).text() || "object.item";
            var objectID=xml.attr("id");

            // console.log("upnpClass="+upnpClass);

            if (upnpClass==="object.container") {
                if (!auto) {

                    upnpServer.browseMetadata(objectID).then(function onSuccess(meta) {

                        page.push("folder.qml", {
                                      upnpServer: page.upnpServer,
                                      meta: meta,
                                      title: card.title,
                                      audioPlayer: page.audioPlayer
                                  });


                    }, function onFailure(reason) {
                        console.log("Failure: "+reason);
                    });
                    return;
                }
            }

            // console.log("CreateObject info="+infoComponent+" col="+row.parent+" "+card.resImageSource);

            info=showInfo(card, infoComponent, {
                              xml: xml,
                              markerPosition: card.x+card.width/2,
                              resImageSource: card.resImageSource,
                              upnpClass: upnpClass,
                              upnpServer: upnpServer,
                              audioPlayer: page.audioPlayer
                          });

            //row.parent.infoContainer.visible=true;
        }

        Component.onCompleted: {
            fillModelDeferred=FolderScript.fillModel(page.upnpServer, page.meta);

            fillModelDeferred.then(function(list) {
                console.log("List="+list);
                listView.model=list;
                listView.updateLayout();

                listView.forceActiveFocus();
            });
        }

        delegate: card
    }

    onStackChanged: {
        if (stack) {
            stack.breadcrumb.opacity=0.7;
        }
    }
}
