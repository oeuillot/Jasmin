import QtQuick 2.2
import QtGraphicalEffects 1.0
import QtMultimedia 5.0
import "../../jasmin" 1.0
import ".." 1.0

import "object.js" as UpnpObject
import "object_container_album_musicAlbum.js" as ObjectContainerAlbum;

FocusInfo {
    id: focusScope

    property AudioPlayer audioPlayer;

    property var metas: null;

    heightRef: imageColumn;

    property string playingObjectID: (audioPlayer!=null && audioPlayer.playingObjectID);
    onPlayingObjectIDChanged: {
        console.log("Item poib="+playingObjectID);
    }

    function playTracks(diskIndex, trackIndex, append) {

        var disks=focusScope.metas.tracks;
        if (!disks) {
            return Deferred.rejected();
        }

        var t=trackIndex;

        var ls=[];

        //        console.log("Add track="+t+" disk="+diskIndex);

        for(var di=0;di<disks.length;di++) {

            if (diskIndex>=0 && diskIndex>di) {
                continue;
            }

            var tracks=disks[di];

            for(var ti=0;ti<tracks.length;ti++) {
                if (t>0) {
                    t--;
                    continue;
                }

                var track=tracks[ti];
                ls.push(track.xml);
            }
        }

        if (!ls.length) {
            return Deferred.rejected();
        }

        return audioPlayer.setPlayList(contentDirectoryService, ls, resImageSource, append);
    }


    function changePosition(diskIndex, trackIndex) {
        //console.log("ChangePosition Parent2="+list+" "+list.parent+" offset="+offset+" source="+source);

        var disks=focusScope.metas.tracks;
        if (!disks) {
            return false;
        }

        //console.log("ChangePosition "+diskIndex+"/"+trackIndex);

        for(;;) {
            if (trackIndex<0) {
                if (diskIndex<1) {
                    return false;
                }

                diskIndex--;
                trackIndex=disks[diskIndex].length+trackIndex;

                if (trackIndex<0 && diskIndex<1) {
                    trackIndex=0;
                    break;
                }

                continue;
            }
            if (trackIndex>=disks[diskIndex].length) {
                trackIndex-=disks[diskIndex].length;

                if (diskIndex+1<disks.length) {
                    diskIndex++;
                    continue;
                }

                trackIndex=disks[diskIndex].length-1;
                break;
            }

            break;
        }
        //console.log("Search "+diskIndex+"/"+trackIndex);

        var comp=metas.comps[diskIndex+"/"+trackIndex];
        if (comp) {
            comp.forceActiveFocus();
            return true;
        }

        // console.log("Not FOUND !");

        return false;
    }


    Item {
        id: infosColumn

        x: 30
        y: 20
        width: parent.width-((imagesList && imagesList.length)?(256+20):0)-60
        height: childrenRect.height+20

        Component {
            id: trackComponent

            FocusScope {
                id: trackItem
                width: 375
                height: 24

                focus: true

                property string point;
                property alias text: value.text
                property alias duration: duration.text
                property string type: "track"

                property int diskIndex: 0
                property int trackIndex: 0

                property var xml;
                property string objectID;


                onActiveFocusChanged: {
                    focusScope.showFocus(trackItem, activeFocus);
                }

                Item {
                    width: 375
                    height: 24

                    Text {
                        id: title
                        font.bold: false
                        font.pixelSize: 12
                        x: 0
                        y: 2
                        opacity: 0.7

                        color: "black" //  color: trackItem.activeFocus?"red": "black"

                        horizontalAlignment: (playingObjectID==objectID)?Text.AlignLeft:Text.AlignRight

                        font.family: (playingObjectID==objectID)?"fontawesome":value.font.family
                        text: (playingObjectID==objectID)?((focusScope.audioPlayer.playbackState===Audio.PlayingState)?Fontawesome.Icon.volume_up:Fontawesome.Icon.volume_off):point

                        width: 16
                    }

                    Text {
                        id: value
                        font.bold: true
                        font.pixelSize: 14

                        color: "black" // color: trackItem.activeFocus?"red": "black"

                        x: 20
                        y: 0
                        width: 350-((duration.visible)?(duration.width+10):0)
                        height: 24
                        elide: Text.ElideRight
                    }


                    Text {
                        id: duration
                        x: 340
                        y: 2

                        color: "black" // color: trackItem.activeFocus?"red": "black"

                        font.bold: false
                        font.pixelSize: 12
                        opacity: 0.7
                        visible: (duration.text.length>0)

                        width: 30
                    }
                }

                Keys.onPressed: {

                    //console.log("ITEM key "+event.key);
                    var disks=focusScope.metas.tracks;
                    var len=disks[diskIndex].length;
                    var mid=Math.ceil(len/2);

                    //console.log("Current="+diskIndex+"/"+trackIndex+" mid="+mid+" len="+len);

                    switch(event.key) {
                    case Qt.Key_Right:
                        if (trackIndex===len-1) {
                            changePosition(diskIndex, trackIndex+1);

                        } else if (trackIndex<mid) {
                            changePosition(diskIndex, trackIndex+mid);

                        } else {
                            changePosition(diskIndex, trackIndex-mid+1);
                        }

                        event.accepted = true;
                        return;


                    case Qt.Key_Down:
                        if (changePosition(diskIndex, trackIndex+1)) {
                            event.accepted = true;
                        } else {

                        }

                        return;

                    case Qt.Key_Left:
                        if (!trackIndex) {
                            changePosition(diskIndex, -1);

                        } else if (trackIndex>=mid) {
                            changePosition(diskIndex, trackIndex-mid);

                        } else {
                            changePosition(diskIndex, trackIndex+mid-1);
                        }

                        event.accepted = true;
                        return;

                    case Qt.Key_Up:
                        if (!changePosition(diskIndex, trackIndex-1)) {
                            playButton.forceActiveFocus();
                        }
                        event.accepted = true;
                        return;

                    case Qt.Key_Return:
                    case Qt.Key_Enter:

                        playTracks(diskIndex, trackIndex, false).then(function() {
                            audioPlayer.play();
                        });

                        event.accepted = true;
                        return;

                    case Qt.Key_PageUp:
                        audioPlayer.setPlayList(contentDirectoryService, [xml], resImageSource, true);

                        event.accepted = true;
                        return;

                    case Qt.Key_PageDown:
                        audioPlayer.setPlayList(contentDirectoryService, [xml], resImageSource, true, audioPlayer.playListIndex+1);

                        event.accepted = true;
                        return;
                    }
                }
            }
        }


        Component {
            id: discComponent

            Item {
                width: parent.width
                height: 28

                property alias text: discTitle.text

                Text {
                    id: discTitle
                    x: 0
                    y: 8
                    width: parent.width
                    font.bold: true
                    font.pixelSize: 12
                }
            }
        }

        function processKeyEvent(event, shuffle) {
            switch(event.key) {

            case Qt.Key_PageDown:
                // Ajoute les pistes du disque juste après celui qui est en écoute, sans forcement lancer le PLAY
                event.accepted = true;

                if (audioPlayer.playbackState===Audio.StoppedState) {
                    audioPlayer.clear().then(function() {
                        return playTracks(-1, 0);
                    });
                    return;
                }

                audioPlayer.clearNext().then(function() {
                    return playTracks(-1, 0, true);

                });
                return;

            case Qt.Key_Return:
            case Qt.Key_Enter:
                // Joue le disque immediatement
                event.accepted = true;

                audioPlayer.clear().then(function() {
                    return playTracks(-1, 0);

                }).then(function() {
                    audioPlayer.shuffle=shuffle;

                    audioPlayer.play();
                });
                return;

            case Qt.Key_PageUp:
                // Ajoute les pistes du disque après les morceaux
                event.accepted = true;

                playTracks(-1, 0, false, true);
                return;
            }

        }

        TitleInfo {
            id: title
            title: UpnpObject.getText(xml, "dc:title")

            Rating {
                id: rating

                xml: focusScope.xml
            }

            Row {
                spacing: 8
                height: 32
                x: (rating.visible)?(rating.x+rating.width+32):0;

                onXChanged: {
                    updateFocusPosition();
                }

                Text {
                    id: playButton
                    text: Fontawesome.Icon.play
                    font.bold: true
                    font.pixelSize: 20
                    font.family: Fontawesome.Name

                    focus: true
                    color: "black" // playButton.activeFocus?"red":"black";

                    KeyNavigation.right: randomButton
                    KeyNavigation.left: randomButton
                    //                    KeyNavigation.left: menuButton

                    Keys.onPressed: {
                        infosColumn.processKeyEvent(event, false);
                    }

                    onActiveFocusChanged: {
                        focusScope.showFocus(playButton, activeFocus);
                    }

                    Component.onCompleted: {
                        playButton.forceActiveFocus();
                    }
                }

                Text {
                    id: randomButton
                    text: Fontawesome.Icon.random
                    font.bold: true
                    font.pixelSize: 20
                    font.family: Fontawesome.Name

                    focus: true
                    color: "black" // color: randomButton.activeFocus?"red":"black";

                    KeyNavigation.left: playButton
                    KeyNavigation.right: playButton
                    //                    KeyNavigation.right: menuButton

                    Keys.onPressed: {
                        infosColumn.processKeyEvent(event, true);
                    }

                    onActiveFocusChanged: {
                        focusScope.showFocus(randomButton, activeFocus);
                    }
                }
                /*
                Text {
                    id: menuButton
                    text: Fontawesome.Icon.ellipsis_h
                    font.bold: true
                    font.pixelSize: 20
                    font.family: Fontawesome.Name

                    color: "black" // color: menuButton.activeFocus?"red":"black";
                    focus: true

                    KeyNavigation.left: randomButton
                    KeyNavigation.right: playButton

                    onActiveFocusChanged: {
                        focusScope.showFocus(menuButton, activeFocus);
                    }
                }
                */


                Keys.onPressed: {

                    switch(event.key) {
                    case Qt.Key_Down:

                        if (changePosition(0, 0)) {
                            event.accepted=true;
                        }
                    }
                }

            }
        }

        Component.onCompleted: {

            var components = {
                track: trackComponent,
                disc: discComponent
            }

            var d=ObjectContainerAlbum.fillTracks(infosColumn, components, 60, contentDirectoryService, xml);

            d.then(function onSuccess(metas) {
                metas=metas || {};
                focusScope.metas=metas;

                var ms="";
                var artist=UpnpObject.getText(xml, "upnp:artist");
                if (artist) {
                    ms+=artist;

                } else {
                    var artists=metas.artists;
                    if (artists && artists.length) {
                        var l=Math.min(8, artists.length);

                        for(var i=0;i<l;i++) {
                            if (ms) {
                                ms+=", ";
                            }

                            ms+=artists[i];
                        }

                        if (artists.length>l) {
                            ms+=", ...";
                        }
                    }
                }

                if (metas.year) {
                    if (ms) {
                        ms+=" \u25CF "
                    }

                    ms+=metas.year;
                }

                title.textInfo=ms;

                //                    infosColumn.height=infosColumn.childrenRect.height;
            });
        }
    }

    ImageColumn {
        id: imageColumn
        imagesList: focusScope.imagesList
        infosColumn: infosColumn
    }

}
