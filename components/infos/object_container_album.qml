import QtQuick 2.2
import QtGraphicalEffects 1.0
import QtMultimedia 5.0
import "../../jasmin" 1.0
import ".." 1.0

import "object.js" as UpnpObject
import "object_container_album.js" as ObjectContainerAlbum;

FocusScope {
    id: focusScope
    x: row.x
    y: row.y
    height: row.height
    width: parent.width

    property AudioPlayer audioPlayer;
    property var upnpServer;
    property var xml;
    property string resImageSource;
    property string objectID;

    property var metas: null;

    function playTracks(diskIndex, trackIndex, shuffle, append) {

        var disks=focusScope.metas.tracks;
        if (!disks) {
            return 0;
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

        audioPlayer.setPlayList(upnpServer, ls, resImageSource, 0, shuffle, append);
        audioPlayer.play();

        return ls.length;
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

        var children=separator.parent.children;
        for(var i=0;i<children.length;i++) {
            var child=children[i];
            //            console.log("Child "+child+" "+child.type+" "+child.diskIndex+" "+child.trackIndex);
            if (child.type!=="track") {
                continue;
            }
            if (child.diskIndex!==diskIndex || child.trackIndex!==trackIndex) {
                continue;
            }

            child.forceActiveFocus();

            return true;
        }

        // console.log("Not FOUND !");

        return false;
    }


    Item {
        id: row
        height: imageColumn.height+30;
        width: parent.width

        property var currentFocus;

        Rectangle {
            id: focusRectangle
            color: "red"
            opacity: 0.4
            width: 0
            height: 0
            radius: 2
        }

        ParallelAnimation {

            id: focusAnimation

            NumberAnimation {
                id: animationX
                target: focusRectangle
                properties: "x"
                duration: 100
                from: 0
                to: 0
            }

            NumberAnimation {
                id: animationY
                target: focusRectangle
                properties: "y"
                duration: 100
                from: 0
                to: 0
            }

            NumberAnimation {
                id: animationWidth
                target: focusRectangle
                properties: "width"
                duration: 100
                from: 0
                to: 0
            }

            NumberAnimation {
                id: animationHeight
                target: focusRectangle
                properties: "height"
                duration: 100
                from: 0
                to: 0
            }
        }

        function showFocus(comp, activeFocus) {
//            console.log("Comp="+comp+" activeFocus="+activeFocus);
            if (!comp || (!activeFocus && comp===currentFocus)) {
                focusRectangle.visible=false;
                return;
            }
            if (!activeFocus) {
                return;
            }

            var x=comp.x-2;
            var y=comp.y-2;

            for(var p=comp.parent;p!==row;p=p.parent) {
                x+=p.x;
                y+=p.y;
            }

            if (!currentFocus) {
                focusRectangle.x=x;
                focusRectangle.y=y;
                focusRectangle.width=comp.width+4;
                focusRectangle.height=comp.height+4;
                focusRectangle.visible=true;
                currentFocus=comp;
                return;
            }

            focusAnimation.stop();
            animationX.from=animationX.to;
            animationX.to=x;
            animationY.from=animationY.to;
            animationY.to=y;
            animationWidth.from=animationWidth.to;
            animationWidth.to=comp.width+4;;
            animationHeight.from=animationHeight.to;
            animationHeight.to=comp.height+4;;
            focusRectangle.visible=true;
            focusAnimation.start();

            currentFocus=comp;
        }


        Component {
            id: trackComponent

            FocusScope {
                id: trackItem
                width: 400
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

                property bool playingObjectID: (focusScope.audioPlayer!=null && focusScope.audioPlayer.playingObjectID===objectID);

                onActiveFocusChanged: {
                    row.showFocus(trackItem, activeFocus);
                }

                Item {
                    width: 400
                    height: 24

                    Text {
                        id: title
                        font.bold: false
                        font.pixelSize: 12
                        x: 0
                        y: 2
                        opacity: 0.7

                        color: "black" //  color: trackItem.activeFocus?"red": "black"

                        horizontalAlignment: (playingObjectID)?Text.AlignLeft:Text.AlignRight

                        font.family: (playingObjectID)?"fontawesome":value.font.family
                        text: (playingObjectID)?((focusScope.audioPlayer.playbackState===Audio.PlayingState)?Fontawesome.Icon.volume_up:Fontawesome.Icon.volume_off):point

                        width: 16
                    }

                    Text {
                        id: value
                        font.bold: true
                        font.pixelSize: 14

                        color: "black" // color: trackItem.activeFocus?"red": "black"

                        x: 20
                        y: 0
                        width: 370-((duration.visible)?(duration.width+10):0)
                        height: 24
                        elide: Text.ElideRight
                    }


                    Text {
                        id: duration
                        x: 320
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
                        //var res=xml.byPath("res", UpnpServer.DIDL_XMLNS_SET).first();

                        playTracks(diskIndex, trackIndex);
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


        Item {
            id: infosColumn

            x: 30
            y: 20
            width: parent.width-((resImageSource)?(256+20):0)-60
            height: infosColumn.childrenRect.height+20

            Row {
                x: 0
                y: 0
                height: 32
                width: parent.width
                spacing: 16

                Text {
                    text: UpnpObject.getText(xml, "dc:title");
                    font.bold: true
                    font.pixelSize: 20
                    elide: Text.ElideRight
                }

                Row {
                    spacing: 8
                    height: 32

                    Text {
                        id: playButton
                        text: Fontawesome.Icon.play
                        font.bold: true
                        font.pixelSize: 20
                        font.family: "fontawesome"

                        focus: true
                        color: "black" // playButton.activeFocus?"red":"black";

                        KeyNavigation.right: randomButton
                        KeyNavigation.left: menuButton

                        Keys.onPressed: {
                            switch(event.key) {

                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                event.accepted = true;

                                playTracks(-1, 0);
                            }
                        }

                        onActiveFocusChanged: {
                            row.showFocus(playButton, activeFocus);
                        }

                    }
                    Text {
                        id: randomButton
                        text: Fontawesome.Icon.random
                        font.bold: true
                        font.pixelSize: 20
                        font.family: "fontawesome"

                        focus: true
                        color: "black" // color: randomButton.activeFocus?"red":"black";

                        KeyNavigation.left: playButton
                        KeyNavigation.right: menuButton

                        Keys.onPressed: {
                            switch(event.key) {

                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                event.accepted = true;

                                playTracks(-1, 0, true);
                                return;
                            }
                        }

                        onActiveFocusChanged: {
                            row.showFocus(randomButton, activeFocus);
                        }
                    }
                    Text {
                        id: menuButton
                        text: Fontawesome.Icon.ellipsis_h
                        font.bold: true
                        font.pixelSize: 20
                        font.family: "fontawesome"

                        color: "black" // color: menuButton.activeFocus?"red":"black";
                        focus: true

                        KeyNavigation.left: randomButton
                        KeyNavigation.right: playButton

                        onActiveFocusChanged: {
                            row.showFocus(menuButton, activeFocus);
                        }
                    }


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

            Text {
                id: metaInfos
                x: 0
                y: 26
                font.bold: false
                font.pixelSize: 16
                width: parent.width
                elide: Text.ElideMiddle
                height: 20

            }

            Rectangle {
                id: separator
                x: 0
                y: 50
                width: parent.width
                height: 1
                opacity: 0.3
                color: "black"
            }

            Component.onCompleted: {

                var components = {
                    track: trackComponent,
                    disc: discComponent
                }

                var d=ObjectContainerAlbum.fillTracks(infosColumn, components, 60, upnpServer, xml);

                d.then(function onSuccess(metas) {
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

                    metaInfos.text=ms;

                    //                    infosColumn.height=infosColumn.childrenRect.height;
                });
            }
        }


        Item {
            id: imageColumn
            visible: !!resImageSource
            clip: true

            x: parent.width-256-30
            y: 30
            width: 256;
            height: Math.max(infosColumn.height+20, 30+256+30)-30;

            Image {
                id: image2
                width: 256
                height: 256
                x: 0
                y: 0

                sourceSize.width: 256
                sourceSize.height: 256

                antialiasing: true
                fillMode: Image.PreserveAspectFit

                source: resImageSource;
                asynchronous: true
            }

            Image {
                x: 0
                y: image2.paintedHeight+Math.floor((256-image2.paintedHeight)/2);
                width: 256
                height: 256

                opacity: 0.25

                smooth: true
                antialiasing: true
                asynchronous: true

                transform: Rotation {
                    origin.x: 128;
                    origin.y: image2.paintedHeight/2;
                    axis { x: 1; y: 0; z: 0 }
                    angle: 180 }

                sourceSize.width: 256
                sourceSize.height: 256

                fillMode: Image.PreserveAspectFit
                source: resImageSource
            }
        }

        Component.onCompleted: {
            focusScope.forceActiveFocus();
        }
    }
}
