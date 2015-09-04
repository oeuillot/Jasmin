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

        property int pageSize: 32;
        property var pageSizeLoaded: ([]);
        property var loadingPages: ([]);
        property bool loading: false;
        property var objectID;

        function loadPage(pageIndex) {

            if (loading) {
                console.error("Already loading !!!!");
                return;
            }

            loading=true;
            console.log("LOAD PAGE "+pageIndex);

            var def=FolderScript.loadModel(page.upnpServer, objectID, pageIndex*pageSize, pageSize);
            def.then(function onSuccess(result) {
                console.log("Response List["+pageIndex+"]="+result.list.length+" position="+result.position+"/"+pageIndex*pageSize);
                loading=false;

                var list=result.list;
                var model=listView.model;
                var p=result.position;
                for(var i=0;i<list.length;i++) {
                    model[p+i]=list[i];
                }

                listView.updateLayout();

                console.log("Loading pages="+loadingPages);

                if (loadingPages.length) {
                    loadPage(loadingPages.shift());
                }
            }, function onFailed(reason) {
                console.error("Can not load model "+reason);
            });
        }

        Component.onCompleted: {
            var infos=FolderScript.fillModel(page.upnpServer, page.meta);

            objectID=infos.objectID;

            listView.model=[];
            listView.modelSize=infos.childCount;

            //            console.log("ModelSize="+infos.childCount);


            pageSizeLoaded[0]=true;
            loadPage(0);

            listView.onPageCellIndexChanged.connect(function() {
                var cur=listView.pageCellIndex;

                if (loadingPages.length) {
                    for(var i=0;i<loadingPages.lenght;i++) {
                        var idx=loadingPages.shift();

                        pageSizeLoaded[idx]=false;
                    }
                }


                for(var i=0;i<listView.viewRows;i++) {
                    var ix=cur+i*listView.viewColumns;
                    var pi=Math.floor(ix/pageSize);

//                    console.log("Test #"+pi+" "+ix+" => "+pageSizeLoaded[pi]);

                    if (pageSizeLoaded[pi]) {
                        ix=cur+(i+1)*listView.viewColumns-1;
                        pi=Math.floor(ix/pageSize);

//                        console.log("Test 2#"+pi+" "+ix+" => "+pageSizeLoaded[pi]);

                        if (pageSizeLoaded[pi]) {
                            continue;
                        }
                    }

                    pageSizeLoaded[pi]=true;

                    if (loading) {
                        loadingPages.unshift(pi);
                        console.log("MARK page #"+pi+" and wait ... lp="+loadingPages);
                        continue;
                    }

                    console.log("MARK page #"+pi);
                    loadPage(pi);
                    break;
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
