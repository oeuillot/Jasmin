import QtQuick 2.2
import QtGraphicalEffects 1.0
import QtMultimedia 5.0

import fbx.async 1.0

import "../../jasmin" 1.0
import ".." 1.0

import "object.js" as UpnpObject
import "object_item_videoItem.js" as ObjectItemVideoItem;

FocusInfo {
    id: videoItem

    heightRef: imageColumn;

    property AudioPlayer audioPlayer;
    property var contentDirectoryService;
    property var xml
    property var infoClass;
    property var objectID;


    Item {
        id: infosColumn

        x: 30
        y: 20
        width: parent.width-((imagesList && imagesList.length)?(256+20):0)-60
        height: childrenRect.height+20


        property var trailers: ([]);

        property var movies: ([]);

        Component {
            id: labelComponent

            Text {
                font.bold: false
                font.pixelSize: 14
                width: 120
                color: "#666666"

                horizontalAlignment: Text.AlignLeft
            }
        }

        Component {
            id: valueComponent

            Text {
                font.bold: true
                font.pixelSize: 14

                elide: Text.ElideRight
            }
        }

        Component {
            id: synopsysComponent

            Text {
                font.bold: true
                font.pixelSize: 14
                textFormat: Text.StyledText

                wrapMode: Text.WordWrap
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

                onXChanged: {
                    updateFocusPosition();
                }

                Text {
                    id: trailerButton
                    text: Fontawesome.Icon.film;
                    font.bold: true
                    font.pixelSize: 20
                    font.family: Fontawesome.Name
                    visible: false;

                    focus: true
                    color: "black"

                    Keys.onPressed: {

                        switch(event.key) {
                        case Qt.Key_Left:
                        case Qt.Key_Right:
                            event.accepted=true;
                            if (playButton.visible) {
                                playButton.forceActiveFocus();
                            }
                            return;

                        case Qt.Key_Zoom:
                            if (trailer.playbackState!==MediaPlayer.StoppedState) {
                                event.accepted=true;

                                if (trailer) {

                                }
                            }
                            return;

                        case Qt.Key_Period:
                        case Qt.Key_MediaTogglePlayPause:
                            if (trailer.playbackState===MediaPlayer.PlayingState) {
                                event.accepted=true;
                                trailer.$pause();
                                return;
                            }
                            if (trailer.playbackState===MediaPlayer.PausedState) {
                                event.accepted=true;
                                trailer.$play();
                                return;
                            }
                            return;

                        case Qt.Key_Escape:
                        case Qt.Key_Back:
                            if (trailer.playbackState===MediaPlayer.StoppedState) {
                                return;
                            }
                            event.accepted=true;

                            trailer.hide();
                            return;


                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            event.accepted = true;

                            if(!infosColumn.trailers || !infosColumn.trailers.length) {
                                return;
                            }

                            timerVideo.stop();

                            if (trailer.playbackState!==MediaPlayer.StoppedState) {
                                trailer.fullscreen();
                                return;
                            }

                            trailer.show();

                            return;
                        }
                    }

                    onActiveFocusChanged: {
                        videoItem.showFocus(trailerButton, activeFocus);
                    }

                    Component.onCompleted: {
                        var ls=ObjectItemVideoItem.listResources(contentDirectoryService, xml);

                        var list=[];

                        ls.forEach(function(l) {
                            if (!/^video\/(.*)/.exec(l.type)) {
                                return;
                            }

                            if (l.additionalInfos.type!=="trailer") {
                                return;
                            }

                            list.push(l);
                        });

                        infosColumn.trailers=list;

                        if (list.length) {
                            trailerButton.visible=true;
                            trailerButton.forceActiveFocus();

                            timerVideo.start();
                        }
                    }

                    Timer {
                        id: timerVideo
                        interval: 5000
                        repeat: false

                        onTriggered: {
                            if (running) {
                                return;
                            }

                            trailer.show();
                        }
                    }
                }

                Text {
                    id: playButton
                    text: Fontawesome.Icon.play
                    font.bold: true
                    font.pixelSize: 20
                    font.family: Fontawesome.Name
                    visible: false;

                    focus: true
                    color: "black"

                    Keys.onPressed: {

                        switch(event.key) {

                        case Qt.Key_Left:
                        case Qt.Key_Right:
                            event.accepted=true;
                            if (trailerButton.visible) {
                                trailerButton.forceActiveFocus();
                            }
                            return;

                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            event.accepted = true;

                            var ls=ObjectItemVideoItem.listResources(contentDirectoryService, xml);

                            var res;

                            ls.forEach(function(l) {
                                if (res) {
                                    return;
                                }

                                if (!/^video\/(.*)/.exec(l.type)) {
                                    return;
                                }

                                if (l.additionalInfos.type==="trailer") {
                                    return;
                                }

                                res=l;
                            });

                            if(!res) {
                                return;
                            }

                            console.log("Res="+res.source);

                            var upnpServer=new UpnpServer.UpnpServer("http://192.168.3.63:54243/device.xml");

                            var avTransport=new AvTransportService.AvTransportService(upnpServer);

                            avTransport.connect().then(function onSuccess() {

                                avTransport.sendSetAvTransportURI(res.source, xml);

                            }, function onFailed(reason) {
                                console.error("Cant not connect server: ",reason);
                            });
                            return;
                        }
                    }

                    onActiveFocusChanged: {
                        videoItem.showFocus(playButton, activeFocus);
                    }

                    Component.onCompleted: {
                        var ls=ObjectItemVideoItem.listResources(contentDirectoryService, xml);

                        var list=[];

                        ls.forEach(function(l) {

                            if (!/^video\/(.*)/.exec(l.type)) {
                                return;
                            }

                            if (l.additionalInfos.type==="trailer") {
                                return;
                            }

                            list.push(l);
                        });

                        infosColumn.movies=list;

                        if (list.length) {
                            playButton.visible=true;

                            if (!trailerButton.visible) {
                                playButton.forceActiveFocus();
                            }
                        }
                    }

                }
            }
        }

        Item {
            id: grid
            x: 0
            y: titleInfo.y+titleInfo.height;
            width: parent.width

            Component.onCompleted: {

                var y=0;

                function addLine(label, value, lc, vc) {
                    var lab=(lc || labelComponent).createObject(grid, {
                                                                    text: label,
                                                                    x: 0,
                                                                    y: y,
                                                                    width: 80
                                                                });
                    var val=(vc || valueComponent).createObject(grid, {
                                                                    text: value,
                                                                    x: 100,
                                                                    y: y,
                                                                    width: grid.width-100-8
                                                                });

                    y+=val.height+8;
                }

                var year=UpnpObject.getText(xml, "dc:data");
                if (year) {
                    addLine("Année de sortie", (new Date(year).getFullYear()));
                }

                //console.log("Xml="+Util.inspect(xml, false, {}));
                var director=UpnpObject.getText(xml, "upnp:director");
                if (director) {
                    addLine("Réalisé par", director);
                }

                var actors=UpnpObject.getText(xml, "upnp:actor");
                if (actors) {
                    addLine("Avec", actors);
                }

                var genres=UpnpObject.getText(xml, "upnp:genre");
                if (genres) {
                    addLine("Genre", genres);
                }

                var synopsys=UpnpObject.getText(xml, "upnp:longDescription") || UpnpObject.getText(xml, "dc:description");
                if (synopsys) {
                    addLine("Synopsys", synopsys, null, synopsysComponent);
                }

                grid.height=y+8;
            }
        }

        Component {
            id: videoComponent

            VideoOutput {

                // ContentRect

                /*
                x: infosColumn.x+grid.x
                y: infosColumn.y+grid.y
                width: grid.width-x
                height: parent.height-y
                */
                x: imageColumn.x
                y: imageColumn.y
                width: imageColumn.width
                height: imageColumn.width

                source: trailer

                fillMode: VideoOutput.PreserveAspectFit
            }
        }


        DeferredVideo {
            id: trailer

            autoLoad: true

            property VideoOutput videoView;

            function show(source) {
                if (!source) {
                    source=infosColumn.trailers[0].source;
                }

                return audioPlayer.pause().then(function() {
                    return trailer.$stop().then(function() {
                        imageColumn.visible=false;

                        if (videoView) {
                            videoView.destroy();
                        }

                        videoView = videoComponent.createObject(videoItem, {
                                                                    source: trailer
                                                                });

                        trailer.source=source;

                        return trailer.$play();
                    });
                });
            }

            function hide() {
                return trailer.$stop().then(function() {
                    videoView.visible=false;
                    videoView.destroy();

                    imageColumn.visible=true;

                    //console.log("x="+trailer.x+" y="+trailer.y+" w="+trailer.width+" h="+trailer.height);

                    return Deferred.resolved();
                });
            }

            function fullscreen() {
                console.log("Show fullscreen");

                var x=0;
                var y=0;
                var w=videoItem.width;
                var h=videoItem.height;

                var p=videoView.parent;
                for(;p;p=p.parent) {
                    //console.log("P="+p);
                    if (p.objectName==="fbx.ui.page.Stack") {
                        break;
                    }

                    x-=p.x;
                    y-=p.y;
                    w=p.width;
                    h=p.height;
                }
                //console.log("X="+x+" y="+y+" w="+w+" h="+h);

                videoView.z=99999;
                videoView.x=x;
                videoView.y=y;
                videoView.width=w
                videoView.height=h
            }


            onStatusChanged: {
                //if (status===MediaPlayer.Buffered) {
                //console.log("Status="+status+" "+metaData.size+" "+metaData.resolution);
                //}
            }
        }
    }

    ImageColumn {
        id: imageColumn
        imagesList: videoItem.imagesList
        infosColumn: infosColumn
        showReversedImage: true
    }

}
