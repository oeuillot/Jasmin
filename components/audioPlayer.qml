import QtQuick 2.4
import QtMultimedia 5.0
import fbx.ui.page 1.0
import fbx.ui.control 1.0

import fbx.async 1.0

import "../jasmin" 1.0
import "../services" 1.0

import "fontawesome.js" as Fontawesome;

Item {
    id: audioPlayer

    property bool log: false;

    property var playList: ([]);

    property int playListIndex: 0;

    property bool shuffle;

    property var currentTrack: null;

    property string playingObjectID: "";

    property int playbackState: Audio.StoppedState;

    property JSettings settings;

    property bool videoMode: false;

    property VideoOutput videoOutput;

    onCurrentTrackChanged: {
        //console.log("Current Track"+currentTrack+" "+currentTrack.objectID);
        playingObjectID=(audioPlayer.currentTrack)?audioPlayer.currentTrack.objectID:"";
    }

    /*
    onPlayingObjectIDChanged: {
        console.log("PlayingObjectId "+playingObjectID);
    }
    */

    function setPlayList(contentDirectoryService, xmlArray, albumImageURL, append, offset) {
        if (log) {
            console.log("setPlay: xml="+xmlArray+" playListIndex="+playListIndex+" shuffle="+shuffle+" append="+append);
        }

        if (!append) {
            return clear().then(function() {
                playListIndex=0;
                _setPlayList(contentDirectoryService, xmlArray, albumImageURL, offset);
            });
        }

        // append

        _setPlayList(contentDirectoryService, xmlArray, albumImageURL, offset);
        return Deferred.resolved();
    }

    function _fillInfo(contentDirectoryService, xml, albumImageURL, playList ) {
        var found=false;

        xml.byPath("res", ContentDirectoryService.DIDL_XMLNS_SET).forEach(function(res) {
            if (found) {
                return;
            }

            var protocolInfo=res.attr("protocolInfo");
            if (!protocolInfo) {
                console.log("No protocolInfo "+res);
                return;
            }

            //console.log("pi="+protocolInfo);
            var ts=protocolInfo.split(':');
            if (ts[0]!=='http-get') {
                console.log("No http-get="+ts[0]);
                return;
            }

            var url=res.text();
            if (!url) {
                console.log("No url");
                return;
            }

            var imageURL=xml.byPath("upnp:albumArtURI", ContentDirectoryService.DIDL_XMLNS_SET).first().text();
            if (imageURL) {
                imageURL=contentDirectoryService.upnpServer.relativeURL(imageURL);
            }

            if (!imageURL) {
                imageURL = albumImageURL;
            }

            var title=xml.byPath("dc:title", ContentDirectoryService.DIDL_XMLNS_SET).first().text();
            var artist=xml.byPath("upnp:artist", ContentDirectoryService.DIDL_XMLNS_SET).first().text();

            var objectID=xml.attr("id");

            url=contentDirectoryService.upnpServer.relativeURL(url);

            found={
                objectID: objectID,
                //                xml: xml,
                url: url,
                imageURL: imageURL,
                title: title,
                artist: artist,
                serverUSN: contentDirectoryService.upnpServer.USN
            };

            return false; // Break the loop if forEach support it :-)
        });

        if (!found) {
            console.error("No res in "+xml.xtoString());
        }

        return found;
    }

    function _setPlayList(contentDirectoryService, xmlArray, albumImageURL, offset) {

        //console.log("xmlArray="+xmlArray);

        if (!(xmlArray instanceof Array)) {
            xmlArray=[xmlArray];
        }

        xmlArray.forEach(function(xml) {
            var info=_fillInfo(contentDirectoryService, xml, albumImageURL, playList);
            if (!info) {
                console.log("FillInfo return null for xml="+xml);
                return;
            }
            if (offset===undefined) {
                playList.push(info);
                return;
            }
            playList.splice(offset, 0, info);
            offset++;
        });

        var sets=[];
        playList.forEach(function(p) {
            sets.push({
                          serverUSN: p.serverUSN,
                          objectID: p.objectID
                      });
        });

        settings.set("audio.playlist", sets);

        trackList.updateList();
    }

    function clear() {
        return stop().then(function() {
            // remove all ...
            playingObjectID="";

            playList=[];
            playListIndex=0;

            trackList.updateList();

            return true;
        });
    }

    function clearNext() {
        if (playList.length && playListIndex<=playList.length) {
            var current=playList[playListIndex];
            playList=[current];
            playListIndex=0;
        }

        trackList.updateList();

        return Deferred.resolved(true);
    }


    function playMusic(contentDirectoryService, xml, albumImageURL) {
        return setPlayList(contentDirectoryService, [xml], albumImageURL, 0, false, false).then(function() {
            return play();
        });
    }

    function stop() {
        playbackState=Audio.StoppedState;
        return mediaPlayer.$stop().then(function() {
            console.log("Set audio player to STOP "+audioPlayer.playbackState);
            mediaPlayer.source="";
            return true;
        });
    }

    function playAudio(flash) {
        //console.log("Play: Current playback="+playbackState+" audioPlayback="+audio.playbackState);
        videoMode=false;
        videoOutput.visible=false;

        if (playbackState===Audio.PlayingState) {
            return Deferred.resolved(playbackState);
        }
        playbackState=Audio.PlayingState;

        if (mediaPlayer.playbackState===Audio.StoppedState) {
            return playIndex(playListIndex);
        }

        if (mediaPlayer.playbackState===Audio.PausedState) {
            return togglePlayPause(flash);
        }

        return Deferred.resolved(playbackState);
    }


    function playVideo(source) {
        if (log) {
            console.log("Play: Current playback="+playbackState+" audioPlayback="+mediaPlayer.playbackState);
        }
        if (videoMode && playbackState===Audio.PlayingState) {
            return Deferred.resolved(playbackState);
        }

        stop().then(function() {
            videoMode=true;
            videoOutput.visible=true;
            videoOutput.source=mediaPlayer;
            mediaPlayer.source=source;

            return mediaPlayer.$play().then(function() {
                playbackState=Audio.PlayingState;

                return playbackState;
            });
        });
    }


    function pause(flash) {
        if (flash) {
            togglePlayPauseFlash.flash();
        }

        // console.log("Pause playbackState="+playbackState+"/"+Audio.PlayingState);
        if (playbackState===Audio.PlayingState) {
            return mediaPlayer.$pause().then(function() {
                playbackState=Audio.StoppedState;
            });
        }

        return Deferred.resolved(false);
    }
    function togglePlayPause(flash) {
        if (flash) {
            togglePlayPauseFlash.flash();
        }

        //console.log("PlayPause playbackState="+playbackState+"/"+Audio.PlayingState);
        if (playbackState===Audio.PlayingState) {
            return mediaPlayer.$pause().then(function() {
                playbackState=Audio.StoppedState;
            });
        }

        if (mediaPlayer.playbackState===Audio.PausedState) {
            return mediaPlayer.$play().then(function() {
                playbackState=Audio.PlayingState;
            });
        }

        if (!videoMode) {
            return playAudio();
        }

        return playVideo();
    }

    function forward(flash) {
        //console.log("AUDIO: Forward");

        if (flash) {
            forwardFlash.flash();
        }

        return stop().then(function() {
            //console.log("AUDIO: stopped "+playListIndex+" len="+playList.length);

            if (playListIndex+1>=playList.length) {
                return false;
            }

            return playIndex(playListIndex+1);
        });
    }

    function back(flash) {
        //console.log("AUDIO: Forward");

        if (flash) {
            backFlash.flash();
        }

        return stop().then(function() {
            //console.log("AUDIO: stopped "+playListIndex+" len="+playList.length);

            if (playListIndex<1) {
                return false;
            }

            return playIndex(playListIndex-1);
        });
    }


    function playIndex(index) {
        //console.log("PLAY index #"+index);

        videoMode=false;
        videoOutput.visible=false;

        playListIndex=index;

        settings.set("audio.playIndex", index);

        trackList.updateList();

        if (playListIndex>=playList.length) {
            return Deferred.resolved(false);
        }

        return mediaPlayer.$stop().then(function() {

            currentTrack=playList[playListIndex];;

            mediaPlayer.source=currentTrack.url;

            return mediaPlayer.$play().then(function() {
                playbackState=Audio.PlayingState;

                return playbackState;
            });
        });
    }

    function formatTime(d) {
        d=Math.floor(d/1000);
        var h=Math.floor(d/3600);
        var m=Math.floor(d/60) % 60;
        var s=d % 60;

        var r=((m<10)?'0':'')+m+':'+((s<10)?'0':'')+s;
        if (h) {
            r=((h<10)?'0':'')+h+':'+r;
        }

        return r;
    }



    function setVideoPosition(component, offsetX, offsetY, width, height) {
        if (log) {
            console.log("VideoOutput="+videoOutput+" component="+component);
        }

        if (!component) {
            return;
        }

        var p=component;
        if (typeof(offsetX)==="string") {
            var found=false;
            for(;p;p=p.parent) {
                //console.log("P="+p);
                if (p.objectName===offsetX) {
                    found=true;
                    break;
                }
            }

            if (!found) {
                console.error("Can not find component '"+offsetX+"'");
                return;
            }
            offsetX=0;
        }

        var x=offsetX || 0;
        var y=offsetY || 0;
        var w=width || p.width;
        var h=height || p.height;

        for(;p;p=p.parent) {
            //console.log("P="+p+" "+p.x+" "+p.y);
            if (p===videoOutput.parent) {
                break;
            }

            x+=p.x;
            y+=p.y;
        }
        if (log) {
            console.log("X="+x+" y="+y+" w="+w+" h="+h);
        }
        videoOutput.x=x;
        videoOutput.y=y;
        videoOutput.width=w
        videoOutput.height=h
        videoOutput.z=99999;
    }

    function hideVideo() {
        videoMode=false;
        videoOutput.visible=false;
        //videoOutput.source=null;
    }

    property MediaPlayer $mediaPlayer: mediaPlayer;

    DeferredMediaPlayer {
        id: mediaPlayer
        autoLoad: true

        source: (currentTrack && currentTrack.url) || ""

        property int progress: 0;

        onPlaybackStateChanged: {
            //console.log("Playback audio.state="+audio.playbackState+" audioPlayer.state="+audioPlayer.playbackState);

            if (mediaPlayer.playbackState===Audio.StoppedState) {
                progress=0;
            }

            if (mediaPlayer.playbackState===Audio.StoppedState && audioPlayer.playbackState===Audio.PlayingState) {
                //console.log("Identify a forward");
                forward();
                return;
            }
        }

        onPositionChanged: {
            // console.log("Position="+position+"/"+duration);
            if (!duration) {
                progress=0;
                return;
            }

            progress=Math.floor(position/duration*100);
        }

        onProgressChanged: {
            // console.log("Progress="+progress);
            cursorProgress.width=Math.floor(progress*bgProgress.width/100);
            cursorProgress2.x=Math.floor(progress*(bgProgress.width-2)/100);
        }
    }

    Component {
        id: trackItem

        Item {
            id: myTrack

            property var model;
            x: (parent.width-width)/2
            height: (selected)?(artist.y+artist.height):(title.y+title.height);

            property bool selected: false
            property bool autoDestroy: false;

            Behavior on y {

                NumberAnimation { id: trackItemYAnimation;
                    duration: 300;

                    onRunningChanged:{
                        if (!trackItemYAnimation.running) {
                            if (autoDestroy) {
                                myTrack.destroy();
                                //console.log("Destroy "+myTrack);
                            }
                        }
                    }
                }
            }
            Behavior on width {
                NumberAnimation { duration: 300 }
            }

            Rectangle {
                x: 0
                y: 0
                width: parent.width
                height: parent.width

                border.color: "#D3D3D3"
                border.width: 1
                color: "#E9E9E9"

                property var model;
            }

            Text {
                x: 1
                y: 1
                width: parent.width-2
                height: parent.width-2

                font.pixelSize: 72
                font.family: Fontawesome.Name
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: 0.4
                text: Fontawesome.Icon.music
            }


            Image {
                x: 0
                y: 0
                width: parent.width
                height: parent.width
                antialiasing: true
                smooth: true
                fillMode: Image.PreserveAspectFit
                source: (model && model.imageURL) || "";
            }

            Text {
                id: title
                x: 0
                y: parent.width
                width: parent.width
                height: (selected)?20:16

                font.bold: true
                font.pixelSize: (selected)?16:14
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight

                text: (model?(model.title || "Inconnu"):"")
            }

            Text {
                id: artist

                visible: selected

                x: 0
                y: title.y+title.height
                width: parent.width
                height: 20

                font.bold: false
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight

                text: (currentTrack?(currentTrack.artist || "Inconnu"):"")
            }
        }
    }


    Item {
        id: commandItems
        x: 0
        height: 24+3
        width: parent.width
        visible: videoMode===false

        Rectangle {
            id: bgProgress
            x: 0
            y: 0
            width: parent.width
            height: 3
            color: "#BCBCBC"
        }
        Rectangle {
            id: cursorProgress
            x: 0
            y: 0
            width: 0
            height: 3
            color: "#707070"
        }
        Rectangle {
            id: cursorProgress2
            x: 0
            y: 0
            width: 2
            height: 5
            color: "black"
            visible: (mediaPlayer.playbackState!==Audio.StopState)
        }


        Text {
            x: 1
            y: 1+3
            font.pixelSize: (mediaPlayer.position>=60*60*1000)?10:12
            text: formatTime(mediaPlayer.position);
        }

        Text {
            x: parent.width-contentWidth
            y: 1+3
            //            width: parent.width-1
            font.pixelSize: ((mediaPlayer.duration-mediaPlayer.position)>=60*60*1000)?10:12
            text: "-"+formatTime(mediaPlayer.duration-mediaPlayer.position);
            visible: mediaPlayer.duration>0
            horizontalAlignment: Text.AlignRight
        }

        Row {
            id: commands
            x: (parent.width-childrenRect.width)/2
            y: 3
            width: childrenRect.width
            height: 24
            spacing: 8

            Text {
                id: backButton
                text: Fontawesome.Icon.backward
                font.bold: true
                font.pixelSize: 16
                font.family: Fontawesome.Name
            }
            Text {
                id: togglePlayPauseButton
                text: (mediaPlayer.playbackState==Audio.PlayingState)?Fontawesome.Icon.pause:Fontawesome.Icon.play
                font.bold: true
                font.pixelSize: 16
                font.family: Fontawesome.Name
            }
            Text {
                id: forwardButton
                text: Fontawesome.Icon.forward
                font.bold: true
                font.pixelSize: 16
                font.family: Fontawesome.Name
            }
        }
        Flash {
            id: backFlash
            target: backButton
        }
        Flash {
            id: togglePlayPauseFlash
            target: togglePlayPauseButton
        }
        Flash {
            id: forwardFlash
            target: forwardButton
        }
    }

    Item {
        id: trackList
        x: 0
        y: 0
        width: parent.width;
        height: parent.height;
        clip: true

        property int cellWidth: width;
        property int cellHeight: cellWidth+16;
        property int cellVerticalSpacing: 4;

        property var itemCache: ([]);

        property Item emptyListItem: trackItem.createObject(trackList, {width: cellWidth, visible: false });

        function updateList() {
            var cnt=Math.ceil((height-commandItems.height)/(cellWidth+cellVerticalSpacing));
            var cntFloor=Math.floor((height-commandItems.height)/(cellWidth+cellVerticalSpacing));
            var children=trackList.children;

            var start=0;
            if (playListIndex>0) {
                start=playListIndex-1;
            }

            var forceFirst=(!playList.length);
            if (forceFirst) {
                emptyListItem.visible=true;
                commandItems.y=emptyListItem.height;
            } else {
                emptyListItem.visible=false;
            }

            var currentItemCache=itemCache;
            itemCache=[];

            var y=0;
            for(var i=0;i<cnt;i++) {
                var track=playList[start+i];
                var item=null;

                if (!track) {
                    break;
                }

                for(var j=0;j<currentItemCache.length;) {
                    var it=currentItemCache[j];
                    if (it.model!==track) {
                        j++;
                        continue;
                    }

                    currentItemCache.splice(j, 1);

                    item=it;
                    break;
                }

                if (!item) {
                    item=trackItem.createObject(trackList, {
                                                    y: (i==0 && playListIndex>0)?(-cellWidth):(height),
                                                                                  width: cellWidth-32,
                                                                                  model: track
                                                } );
                }

                itemCache.push(item);
                item.visible=true;
                item.z=i;

                if (start+i===playListIndex || (!i && forceFirst)) {
                    item.selected=true;
                    item.width=cellWidth;
                    item.y=y;
                    y+=cellWidth+40;

                    commandItems.y=y;
                    y+=commandItems.height;

                } else {
                    item.selected=false;
                    item.width=cellWidth-32;
                    item.y=y;

                    y+=cellWidth-32+16;
                }

                y+=cellVerticalSpacing;
            }

            for(var i=0;i<currentItemCache.length;i++) {
                var item=currentItemCache[i];
                item.autoDestroy=true;

                if (item.y<cellHeight) {
                    item.y=-item.height;
                    continue;
                }

                item.y+=parent.height;
            }
        }

        Component.onCompleted: {
            updateList();
        }
    }
}


