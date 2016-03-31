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

    property var creationDate: Date.now();

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

                onContentWidthChanged: {
                    if (contentWidth>80) {
                        font.pixelSize--;
                    }
                }
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

            Certificate {
                id: certiticate
                x: rating.x+16+((rating.visible)?(rating.width):0);
                xml: videoItem.xml
            }


            Row {
                spacing: 8
                height: 32
                x: certiticate.x+32+((certiticate.visible)?(certiticate.width):0);

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
                            if (audioPlayer.playbackState!==MediaPlayer.StoppedState) {
                                event.accepted=true;

                                if (trailer) {

                                }
                            }
                            return;

                        case Qt.Key_Period:
                        case Qt.Key_MediaTogglePlayPause:
                            if (audioPlayer.playbackState===MediaPlayer.PlayingState) {
                                event.accepted=true;
                                audioPlayer.pause();
                                return;
                            }
                            if (audioPlayer.playbackState===MediaPlayer.PausedState) {
                                event.accepted=true;
                                audioPlayer.play();
                                return;
                            }
                            return;

                        case Qt.Key_Escape:
                        case Qt.Key_Back:
                            if (audioPlayer.playbackState===MediaPlayer.StoppedState) {
                                return;
                            }
                            event.accepted=true;

                            infosColumn.hideVideo();
                            return;


                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            event.accepted = true;

                            if(!infosColumn.trailers || !infosColumn.trailers.length) {
                                return;
                            }

                            if (Date.now()-creationDate<1000) {
                                // Evite un plantage quand la vidéo demarre trop vide !
                                return;
                            }

                            timerVideo.stop();

                            if (audioPlayer.videoMode && audioPlayer.playbackState!==MediaPlayer.StoppedState) {
                                infosColumn.fullscreenVideo();
                                return;
                            }

                            infosColumn.showVideo();

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
                            // console.log("l.type="+l.type+" "+l.additionalInfos.type+" "+l.additionalInfo);

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

                            infosColumn.showVideo();
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
                        if (Date.now()-creationDate<1000) {
                            // Parfois, ça va trop vite !
                            return;
                        }

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

                            //Qt.openUrlExternally(res.source);
                            App.urlOpen(res.source, res.type);

                            /*
                            var upnpServer=new UpnpServer.UpnpServer("http://192.168.3.63:54243/device.xml");

                            var avTransport=new AvTransportService.AvTransportService(upnpServer);

                            avTransport.connect().then(function onSuccess() {

                                avTransport.sendSetAvTransportURI(res.source, xml);

                            }, function onFailed(reason) {
                                console.error("Cant not connect server: ",reason);
                            });
                            */
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
                var lines=0;

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
                    lines+=Math.ceil(value/80);

                    return {
                        label: lab,
                        value: val
                    };
                }

                var originalTitle=UpnpObject.getText(xml, "mo:originalTitle");
                var title=UpnpObject.getText(xml, "dc:title");
                var alsoKnownAs=UpnpObject.getText(xml, "mo:alsoKnownAs");
                if (originalTitle && originalTitle!==title) {
                    addLine("Titre original", originalTitle);
                }
                if (alsoKnownAs && alsoKnownAs!==title) {
                    addLine("Autre titre", alsoKnownAs);
                }

                var episode=UpnpObject.getText(xml, "mo:episode");
                var season=UpnpObject.getText(xml, "mo:season");
                if (episode) {
                    var e=""+parseInt(episode, 10);
                    if (season) {
                        e+="  (saison "+parseInt(season, 10)+")";
                    }

                    addLine("Episode", e);
                }

                var hasDate=false;

                var airDate=UpnpObject.getText(xml, "mo:airDate");
                if (airDate) {
                    var reg=/^(\d{4})-(\d{1,2})-(\d{1,2})/.exec(airDate);
                    if (reg) {
                        addLine("Diffusion", reg[3]+"/"+reg[2]+"/"+reg[1]);
                        hasDate=true;
                    }
                }

                if (!hasDate) {
                    var year=UpnpObject.getText(xml, "mo:year");
                    if (year) {
                        addLine("Année de sortie", year);
                        hasDate=true;
                    }
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

                var genres=UpnpObject.getTextList(xml, "upnp:genre");
                if (genres) {
                    addLine("Genre"+((genres.length>1)?"s":""), genres.join(', '));
                }

                var synopsys=UpnpObject.getText(xml, "upnp:longDescription") || UpnpObject.getText(xml, "dc:description");
                if (synopsys) {
                    addLine("Synopsys", synopsys, null, synopsysComponent);
                }

                if (lines<4) {
                   UpnpObject.addDatesLine(xml, addLine);
                }


                //var ress=UpnpObject.getText(xml, "upnp:res");
                //if (ress) {
                //    addLine("Genre", genres);
                //}

                grid.height=y+8;
            }
        }

        Component {
            id: videoComponent

            VideoOutput {
                x: imageColumn.x
                y: imageColumn.y
                width: imageColumn.width
                height: imageColumn.width

                source: audioPlayer

                fillMode: VideoOutput.PreserveAspectFit

            }
        }

        property VideoOutput videoView;

        function showVideo(source) {
            if (!source) {
                source=infosColumn.trailers[0].source;
            }

//            console.log("Audio player has stopped !");
            imageColumn.visible=false;

            audioPlayer.setVideoPosition(imageColumn.parent, imageColumn.x, imageColumn.y, imageColumn.width, imageColumn.width);

            audioPlayer.onPlaybackStateChanged.connect(playbackChanged);

            return audioPlayer.playVideo(source);
        }

        function playbackChanged() {
//            console.log("Playback changed ! "+audioPlayer.playbackState);
            if (audioPlayer.playbackState===Audio.StoppedState) {
                hideVideo();
            }
        }

        function hideVideo() {
            audioPlayer.onPlaybackStateChanged.disconnect(playbackChanged);

            return audioPlayer.stop().then(function() {

                audioPlayer.hideVideo();

                imageColumn.visible=true;

                //console.log("x="+trailer.x+" y="+trailer.y+" w="+trailer.width+" h="+trailer.height);

                return Deferred.resolved();
            });
        }

        function fullscreenVideo() {
 //           console.log("Show fullscreen");

            audioPlayer.setVideoPosition(imageColumn, "fbx.ui.page.Stack");
        }

    }

    ImageColumn {
        id: imageColumn
        imagesList: videoItem.imagesList
        infosColumn: infosColumn
        showReversedImage: false
    }

}
