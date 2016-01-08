/**
  * @author Olivier Oeuillot
  */

import QtQuick 2.2
import fbx.ui.page 1.0
import fbx.ui.control 1.0
import fbx.async 1.0
import QtMultimedia 5.0

import "folder.js" as FolderScript
import "musicFolder.js" as MusicFolder
import "../components" 1.0
import "../jasmin" 1.0
import "../services" 1.0

Page {
    id: page
    title: ""

    property var meta;
    property var contentDirectoryService;
    property AudioPlayer audioPlayer;
    property JSettings settings;
    property SearchBox searchBox;

    property var fillModelDeferred;

    property Card focusCard;

    property Info info;

    property bool loadArtists: true;

    property int pageSize: 32;

    property bool pageShown: false;

    property bool autoPop: false;

    property var deferredXMLParsing;

    property var listOptions: ({modelHasIndex: true, recentlyAdded: true});

    onDidAppear: {
        pageShown=true;

        listView.preparePages();
    }

    onDidDisappear: {
        //console.log("ON DID DISAPPEAR *********");
        listView.onBack();
        listView.model=null;
        listView.headers=null;
        listView.redirectedModel=null;
    }

    onWillAppear: {
        //console.log("ON WILL APPEAR ********* model="+listView.model);

        //listView.model=[]
        if (listView.model && listView.model.length) {
            //console.log("ON WILL APPEAR back");
            listView.onFront();
            listView.updateLayout();
            return;
        }

        if (listView.modelInfos.childCount<=pageSize*2 && !page.listOptions.modelHasIndex) {
            // Petites pages, on charge directe
            listView.pageSizeLoaded[0]=true;
            listView.loadPage(0).then(function() {

                // console.log(Date.now()+" little ModelSize="+listView.modelSize);
                if (listView.modelSize===0) {
                    messageFolder.text="Le dossier est vide";
                    messageFolder.visible=true;
                    backFolderTimer.start();
                    return;
                }

                listView.preparePages();
            });

        } else {
            // Grosse liste, on ne charge que le titre/class
            FolderScript.listModel(contentDirectoryService, listView.objectID, page.listOptions).then(function(result) {
                listView.redirectedModel=null;
                listView.headers=null;
                listView.model=result;

                //                console.log(Date.now()+" big ModelSize="+result.length+" "+listOptions.recentyAdded);

                if (listOptions.recentlyAdded) {
                    var d=new Date();
                    d.setDate(d.getDate()-14);

                    FolderScript.prepareRecentlyAdded(contentDirectoryService, listView, result, d, recentlyAdded, allAlbums);
                }

                listView.updateLayout();
                listView.preparePages();
            });
        }
    }
    Component {
        id: recentlyAdded

        GridSectionSeparator {

            property int count: 0

            title: (count>1)?"Ajoutés récemment":"Ajouté récemment"
        }
    }

    Component {
        id: allAlbums

        GridSectionSeparator {
            title: "Toute la liste"
            height: 50
        }
    }

    Component {
        id: searchHeaderComponent

        GridSectionSeparator {

            property int count: 0

            title: "Résultat de la recherche"
        }
    }

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

                            MusicFolder.browseTrack(contentDirectoryService, model).then(function onSuccess(xml) {
                                return audioPlayer.setPlayList(contentDirectoryService, [xml], resImageSource, true, audioPlayer.playListIndex+1);

                            }, function onFailed(reason) {
                                console.error("Can not browse track "+model);
                            });
                            return;

                        case Qt.Key_PageUp:
                            // Ajoute les pistes du disque après les morceaux
                            event.accepted = true;

                            MusicFolder.browseTrack(contentDirectoryService, model).then(function onSuccess(xml) {
                                return audioPlayer.setPlayList(contentDirectoryService, [xml], resImageSource, true);

                            }, function onFailed(reason) {
                                console.error("Can not browse track "+model);
                            });
                            return;
                        }

                    } else if (!upnpClass.indexOf("object.container.album.musicAlbum")) {
                        switch(event.key) {
                        case Qt.Key_PageDown:
                            // Ajoute les pistes du disque juste après celui qui est en écoute, sans forcement lancer le PLAY
                            event.accepted = true;

                            MusicFolder.browseTracks(contentDirectoryService, model).then(function(disks) {
                                var list=[];
                                disks.forEach(function(disk) {
                                    disk.forEach(function(track) {
                                        list.push(track.xml);
                                    });
                                });

                                audioPlayer.setPlayList(contentDirectoryService, list, resImageSource, true, audioPlayer.playListIndex+1);
                            });
                            return;

                        case Qt.Key_PageUp:
                            // Ajoute les pistes du disque après les morceaux
                            event.accepted = true;

                            MusicFolder.browseTracks(contentDirectoryService, model).then(function(disks) {
                                var list=[];
                                disks.forEach(function(disk) {
                                    disk.forEach(function(track) {
                                        list.push(track.xml);
                                    });
                                });

                                audioPlayer.setPlayList(contentDirectoryService, list, resImageSource, true);
                            });
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
                        // console.log("Active focus changed for card "+this.cellIndex);
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
        width: parent.width-5
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
                                      settings: settings,
                                      searchBox: searchBox
                                  });


                    }, function onFailure(reason) {
                        console.error("Failure: "+reason);
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
        property var modelInfos;


        function preparePages() {

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

            var cellCount=listView.viewRows*listView.viewColumns;

            for(var i1=0;i1<cellCount;i1++) {
                var ix=cur+i1;
                var modelIdx=listView.getModelIndex(ix);
                //console.log("ModelIndex of "+ix+"=>"+modelIdx);
                if (modelIdx<0) {
                    continue;
                }

                var pi=Math.floor(modelIdx/pageSize);

                // console.log("Test "+cur+" ix="+ix+" pi="+pi);

                if (pageSizeLoaded[pi]) {
                    continue;
                }

                //                console.log("Need page "+pi);

                pageSizeLoaded[pi]=true;
                if (loading) {
                    loadingPages.unshift(pi);
                    continue;
                }

                loadPage(pi);
            }
        }

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

                if (!listView.model) {
                    listView.model=[];
                }

                var list=result.list;
                var model=listView.model;
                var p=result.position;
                for(var i=0;i<list.length;i++) {
                    model[p+i]=list[i];
                }

                listView.updateLayout();
                listView.updateFocusRect();

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
            modelInfos=FolderScript.getModelInfo(contentDirectoryService, page.meta);

            objectID=modelInfos.objectID;

            if (!listView.model) {
                listView.model=[];
            }
            if (modelInfos.childCount>0) {
                listView.modelSize=modelInfos.childCount;
            }

            // console.log("ModelSize="+modelInfos.childCount);

            listView.onUserScrollingChanged.connect(function onScroll() {
                //console.log(Date.now()+" UserScrolling="+listView.userScrolling);
                listView.preparePages();
            });

            //console.log(Date.now()+" Loading page");
        }

        delegate: card
    }

    Text {
        id: messageFolder
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
            if (autoPop) {
                return;
            }

            autoPop=true;
            page.pop();
        }
    }

    Item {
        id: flashMessage
        x: 0
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

    property var beforeSearch: ({});

    Keys.onPressed: {
        Util.logKeyName(event);

        switch(event.key) {
        case Qt.Key_Period:
        case Qt.Key_MediaTogglePlayPause:
            audioPlayer.togglePlayPause(true);
            event.accepted = true;
            break;

        case Qt.Key_MediaNext:
        case Qt.Key_AudioForward:
            audioPlayer.forward(true);
            event.accepted = true;
            break;

        case Qt.Key_NumLock:
            audioPlayer.stop();
            event.accepted = true;
            break;

        case Qt.Key_Minus:
            audioPlayer.playAudio();
            event.accepted = true;
            break;

        case Qt.Key_MediaPrevious: // Clavier
        case Qt.Key_AudioRewind: // Freebox
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
            if (autoPop) {
                // Deja en cours de fermeture !
                event.accepted=true;
                return;
            }
            autoPop=true;

            break;

        case Qt.Key_0:
        case Qt.Key_1:
        case Qt.Key_2:
        case Qt.Key_3:
        case Qt.Key_4:
        case Qt.Key_5:
        case Qt.Key_6:
        case Qt.Key_7:
        case Qt.Key_8:
        case Qt.Key_9:
            break;

        case Qt.Key_Blue:
        case Qt.Key_F1:
        case Qt.Key_Search:
            if (!listView.getModelSize()) {
                break;
            }

            if (!beforeSearch) {
                beforeSearch={
                    redirectedModel: listView.redirectedModel,
                    headers: listView.headers || []
                };


                listView.hideHeaders();
                listView.headers=[
                            { rowIndex: 0,
                                component: listView.createComponentHeader(searchHeaderComponent )
                            }
                        ];
            }

            searchBox.show(function onKeyChanged(text) {
                console.log("KEY CHANGED "+text);

                var ret=FolderScript.processSearch(listView, text, searchHeaderComponent);
                listView.updateLayout();

                if (ret && ret.length) {
                    messageFolder.visible=false;
                    return ret;
                }

                if (!text) {
                    messageFolder.text="Recherche par saisie prédictive de 9 touches";
                    messageFolder.visible=true;
                    return ret;
                }

                messageFolder.text="Aucun resultat n'a été trouvé !";
                messageFolder.visible=true;
                return ret;


            }, function onValidation(text) {
                console.log("ON VALIDATION "+text);

                // TODO  on laisse le filtrage

                messageFolder.visible=false;
                listView.forceActiveFocus();

            }, function onCancel() {
                messageFolder.visible=false;

                listView.hideHeaders();
                listView.headers=beforeSearch.headers;
                listView.redirectedModel=beforeSearch.redirectedModel;
                beforeSearch=null;

                listView.updateLayout();
                listView.forceActiveFocus();
            });
            break;
        }
    }
}
