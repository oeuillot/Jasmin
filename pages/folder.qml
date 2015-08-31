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

    property Info info;

    Component {
        id: card

        Card {
            upnpServer: page.upnpServer

            property int cellIndex;

            Keys.onPressed: {
                switch(event.key) {
                case Qt.Key_Escape:
                case Qt.Key_Back:
                    if (info) {
                        info.destroy();
                        info=null;
                    }
                    return;

                case Qt.Key_Return:
                case Qt.Key_Enter:

                    if (!info || info.card!==this) {
                        listView.open(this, false);
                    }

                    event.accepted=true;
                    return;
                }
            }

            onActiveFocusChanged: {
                if (activeFocus) {

                    page.focusCard=this;

                    if (info && info.card===this) {
                        return;
                    }

                    this.selected=true;

                    if (info) {
                        info.destroy();
                        info=null;
                    }

                    if (info) {
                        listView.open(this, true);

                    } else {
                        //                        console.log("Active focus changed for card "+this.cellIndex);
                        listView.show(this);
                    }

                    return;
                }

                if (!info || info.card!==this) {
                    this.selected=false;
                }

                if (page.focusCard===this) {
                    page.focusCard=null;
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
                              audioPlayer: page.audioPlayer,
                              card: card
                          });

            //row.parent.infoContainer.visible=true;

            info.Component.onDestruction.connect((function() {
                card.selected=false;
            }).bind(card));
        }

        Component.onCompleted: {
            var infos=FolderScript.fillModel(page.upnpServer, page.meta);

            listView.model=[];
            listView.modelSize=infos.childCount;

            //            console.log("ModelSize="+infos.childCount);

            var pageSize=64;
            var pageSizeLoaded=[];
            var loadingPages=[];
            var loading=false;

            function loadPage(position) {
                loading=true;
                console.log("LOAD PAGE "+Math.floor(position/pageSize));
                pageSizeLoaded[Math.floor(position/pageSize)]=true;

                var def=FolderScript.loadModel(page.upnpServer, infos.objectID, position, pageSize);
                def.then(function onSuccess(result) {
                    //                    console.log("Response List="+result.list.length);
                    loading=false;

                    var params=[result.position, result.list.length];
                    params = params.concat(result.list);

                    listView.model.splice.apply(listView.model, params);
                    listView.updateLayout();

                    if (loadingPages.length) {
                        loadPage(loadingPages.shift());
                    }
                });
            }

            loadPage(0);

            listView.onFocusIndexChanged.connect(function() {
                var cur=listView.focusIndex;

                var pi=Math.floor(cur/pageSize);
                if (!pageSizeLoaded[pi]) {
                    if (loading) {
                        loadingPages.unshift(pi*pageSize);
                    } else{
                        loadPage(pi*pageSize);
                    }
                }

                var pi2=Math.floor((cur+cellShownCount)/pageSize);
                if (!pageSizeLoaded[pi2]) {
                    if (loading) {
                        loadingPages.unshift(pi2*pageSize);
                    } else{
                        loadPage(pi2*pageSize);
                    }
                }

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
