import QtQuick 2.2
import fbx.ui.page 1.0
import fbx.ui.control 1.0
import fbx.async 1.0
import QtMultimedia 5.0

import "folder.js" as FolderScript
import "../components" 1.0
import "../jasmin" 1.0

Page {
    id: page
    title: ""

    property var meta;
    property var contentDirectoryService;
    property AudioPlayer audioPlayer;

    property JSettings settings;

    property var fillModelDeferred;

    property Card focusCard;

    property Info info;

    property bool loadArtists: true;

    property int pageSize: 32;

    Component {
        id: card

        Card {

            property int cellIndex;

            Keys.onPressed: {
                switch(event.key) {

                case Qt.Key_Return:
                case Qt.Key_Enter:

                    if (!info || info.card!==this) {
                        listView.open(this, false);
                    }

                    event.accepted=true;
                    return;                                        
                 }

                if (upnpClass) {
                    if (!upnpClass.indexOf("object.item.audioItem")) {
                        switch(event.key) {
                        case Qt.Key_PageDown:
                            // Ajoute les pistes du disque juste après celui qui est en écoute, sans forcement lancer le PLAY
                            event.accepted = true;

                            return audioPlayer.setPlayList(contentDirectoryService, [model], resImageSource, true, audioPlayer.playListIndex+1);

                        case Qt.Key_PageUp:
                            // Ajoute les pistes du disque après les morceaux
                            event.accepted = true;

                            audioPlayer.setPlayList(contentDirectoryService, [model], resImageSource, true);
                            return;
                        }

                    } else if (!upnpClass.indexOf("object.container.album.musicAlbum")) {
                        switch(event.key) {
                        case Qt.Key_PageDown:
                            // Ajoute les pistes du disque juste après celui qui est en écoute, sans forcement lancer le PLAY
                            event.accepted = true;

                            var list=getMusicTrackList(model);

                            return audioPlayer.setPlayList(contentDirectoryService, list, resImageSource, true, audioPlayer.playListIndex+1);

                        case Qt.Key_PageUp:
                            // Ajoute les pistes du disque après les morceaux
                            event.accepted = true;

                            var list=getMusicTrackList(model);

                            audioPlayer.setPlayList(contentDirectoryService, list, resImageSource, true);
                            return;
                        }
                    }
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
                        info.card.hideInfo=false;

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

            Component.onCompleted: {
                this.contentDirectoryService=page.contentDirectoryService;
            }
        }
    }
    Component {
        id: infoComponent

        Info {

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
            //console.log("Open card="+card.model);

            if (info) {
                info.destroy();
                info=null;
            }

            var xml=card.model;

            var upnpClass=xml.byTagName("class", UpnpServer.UPNP_METADATA_XMLNS).text() || "object.item";
            var objectID=xml.attr("id");

            // console.log("upnpClass="+upnpClass);

            if (upnpClass.indexOf("object.container")===0 && upnpClass.indexOf("object.container.album")<0) {
                if (!auto) {
                    contentDirectoryService.browseMetadata(objectID).then(function onSuccess(meta) {

                        page.push("folder.qml", {
                                      contentDirectoryService: page.contentDirectoryService,
                                      meta: meta,
                                      title: card.title,
                                      audioPlayer: page.audioPlayer,
                                      loadArtists: true,
                                      settings: settings
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
                              upnpClass: upnpClass,
                              contentDirectoryService: contentDirectoryService,
                              audioPlayer: page.audioPlayer,
                              card: card
                          });

            card.hideInfo=true;

            //row.parent.infoContainer.visible=true;
        }

        property var pageSizeLoaded: ([]);
        property var loadingPages: ([]);
        property bool loading: false;
        property var objectID;

        function loadPage(pageIndex) {
            if (loading) {
                console.error("Already loading !!!!");
                return Deferred.rejected();
            }

            loading=true;
            // console.log("LOAD PAGE "+pageIndex);

            var def=FolderScript.loadModel(contentDirectoryService, objectID, pageIndex*pageSize, pageSize, loadArtists);
            def.then(function onSuccess(result) {
                //                console.log("Response List["+pageIndex+"]="+result.list.length+" position="+result.position+"/"+pageIndex*pageSize);
                loading=false;

                if (!listView.modelSize  && result.totalMatches) {
                    listView.modelSize=result.totalMatches;

                    //console.log("SET TOTAL MATCHES to "+result.totalMatches);
                }


                var list=result.list;
                var model=listView.model;
                var p=result.position;
                for(var i=0;i<list.length;i++) {
                    model[p+i]=list[i];
                }

                listView.updateLayout();

                //console.log("Loading pages="+loadingPages);

                if (loadingPages.length) {
                    //console.log("Next page !");
                    loadPage(loadingPages.shift());
                }
            }, function onFailed(reason) {
                console.error("Can not load model "+reason);
            });

            return def;
        }

        Component.onCompleted: {
            var infos=FolderScript.fillModel(contentDirectoryService, page.meta);

            objectID=infos.objectID;

            listView.model=[];
            if (infos.childCount>0) {
                listView.modelSize=infos.childCount;
            }

            //            console.log("ModelSize="+infos.childCount);


            listView.onUserScrollingChanged.connect(function() {
                //console.log("UserScrolling="+listView.userScrolling);

                var cur=listView.pageCellIndex;

                if (loadingPages.length) {
                    for(var i=0;i<loadingPages.lenght;i++) {
                        var idx=loadingPages.shift();

                        pageSizeLoaded[idx]=false;
                    }                   
                }

                if (listView.userScrolling) {
                    return;
                }

                for(var i=0;i<listView.viewRows;i++) {
                    var ix=cur+i*listView.viewColumns;
                    var pi=Math.floor(ix/pageSize);

                    // console.log("Test "+cur+" ix="+ix+" pi="+pi);

                    if (!pageSizeLoaded[pi]) {
                        pageSizeLoaded[pi]=true;
                        if (loading) {
                            loadingPages.unshift(pi);
                            continue;
                        } else {
                            loadPage(pi);
                        }
                    }

                    ix=ix+listView.viewColumns-1;
                    pi=Math.floor(ix/pageSize);

                    if (!pageSizeLoaded[pi]) {
                        pageSizeLoaded[pi]=true;
                        if (loading) {
                            loadingPages.unshift(pi);
                            continue;
                        } else {
                            loadPage(pi);
                        }
                    }
                }

            });

            if (infos.childCount<=pageSize*2) {
                pageSizeLoaded[0]=true;
                loadPage(0).then(function() {

                    //console.log("ModelSize="+listView.modelSize);
                    if (listView.modelSize===0) {
                        emptyFolder.visible=true;
                        backFolderTimer.start();
                    }
                });

            } else {
                FolderScript.listModel(contentDirectoryService, objectID).then(function(result) {
                    listView.model=result;
                    listView.updateLayout();

                    pageSizeLoaded[0]=true;
                    loadPage(0);
                });
            }
        }

        delegate: card
    }

    Text {
        id: emptyFolder
        visible: false
        text: "Le dossier est vide"

        x: (page.width-contentWidth)/2
        y: (page.height-contentHeight)/2

        color: "#404040"
        font.bold: true
        font.pixelSize: 20
    }

    Timer {
        id: backFolderTimer
        interval: 1000;
        repeat: false
        onTriggered: {
            page.pop();
        }
    }

    Item {
        id: flashMessage
        x:0
        y: 0
        width: parent.width
        height: childrenRect.height
        clip: true
        visible: true
        opacity: 0.75

        Rectangle {
            id: flashRectangle
            x:0;
            y: -height;
            width: parent.width
            height: childrenRect.height;
            color: "red"

            Text {
                x: (parent.width-contentWidth)/2;
                y: 4

                color: "white"
                text: "Le dossier est vide !"
            }
        }


        NumberAnimation {
            id: showAnim;
            property: "y"
            duration: 300;
            target: flashRectangle

            onRunningChanged:{
                if (!showAnim.running) {
                    hideAnim.from=1
                    hideAnim.to=0;
                    hideAnim.start();
                }
            }
        }

        NumberAnimation {
            id: hideAnim;
            property: "opacity"
            duration: 2000;
            target: flashRectangle

            onRunningChanged:{
                if (!hideAnim.running) {
                    flashMessage.visible=false;
                }
            }
        }

        function flash() {
            showAnim.from=-flashRectangle.height;
            showAnim.to=0;

            showAnim.start();
            flashRectangle.opacity=1
            flashMessage.visible=true;
        }

    }

    onStackChanged: {
        if (stack) {
            stack.breadcrumb.opacity=0.7;
        }
    }

    Keys.onPressed: {
        Util.logKeyName(event);

        switch(event.key) {
        case Qt.Key_Period:
        case Qt.Key_MediaTogglePlayPause:
            audioPlayer.togglePlayPause(true);
            event.accepted = true;
            break;

        case Qt.Key_Asterisk:
        case Qt.Key_AudioForward:
            audioPlayer.forward(true);
            event.accepted = true;
            break;

        case Qt.Key_Slash:
        case Qt.Key_AudioRewind:
            audioPlayer.back(true);
            event.accepted = true;
            break;

        case Qt.Key_Escape:
        case Qt.Key_Back:
            if (info!=null) {
                var card=info.card;

                info.card.hideInfo=false;
                info.destroy();
                info=null;

                if (card) {
                    card.forceActiveFocus();
                }

                event.accepted = true;
                return;
            }

            break;
        }
    }
}
