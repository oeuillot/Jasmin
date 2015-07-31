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

    property Info info

    Timer {
        id: timer
        interval: 200
        repeat: true
        triggeredOnStart: true
    }


    Component {
        id: infoComponent

        Info {

            property bool destroying: false

            onHeightChanged: parent.updateHeight();

            onDestroyingChanged: parent.updateHeight();
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: 10
        focus: true

        property int focusColumnIndex;
        property var currentCard;

        function open(card, row, auto) {
           // console.log("card="+card.xml+" row="+row);

            if (info) {
                info.destroying=true;
                info.destroy();
                info=null;
            }

            var xml=Xml.$XML(card.xml.nodes);

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
                                      audioPlayer: audioPlayer
                                  });


                    }, function onFailure(reason) {
                        console.log("Failure: "+reason);
                    });
                    return;
                }
            }

            // console.log("CreateObject info="+infoComponent+" col="+row.parent+" "+card.resImageSource);

            info = infoComponent.createObject(row.parent.infoContainer, {
                                                  xml: xml,
                                                  markerPosition: card.x+card.width/2,
                                                  resImageSource: card.resImageSource,
                                                  upnpClass: upnpClass,
                                                  upnpServer: upnpServer,
                                                  audioPlayer: page.audioPlayer
                                              });

            row.parent.infoContainer.visible=true;
        }

        model: ListModel {
            id: listModel

            Component.onCompleted: {
                fillModelDeferred=FolderScript.fillModel(this, page.upnpServer, page.meta, timer);
            }
        }
        delegate:
            Column {
            focus: true

            property Item infoContainer: infoContainer;

            Keys.onPressed: {
                //console.log("Event="+event.key);
                switch(event.key) {
                case Qt.Key_Return:
                    event.accepted = true;

                    listView.open(listView.currentCard, row, false);

                    break;
                }
            }

            onActiveFocusChanged: {
                //console.log("Active focus row "+activeFocus+" / "+listView.focusColumnIndex);
                if (activeFocus) {
                    var card=[card1, card2, card3, card4, card5, card6, card7][listView.focusColumnIndex];

                    card.forceActiveFocus ();
                }
            }


            function registerFocus(card, row, columnIndex) {
                if (card.activeFocus){
                    listView.focusColumnIndex=columnIndex;
                    listView.currentCard=card;

                    // console.log("Set focus to "+columnIndex);

                    if (page.info) {
                        listView.open(card, row, true);
                    }
                }
            }

            Row {
                id: row
                focus: true

                Card {
                    id: card1
                    xml: item1
                    upnpServer: page.upnpServer
                    KeyNavigation.right: card2
                    onActiveFocusChanged: registerFocus(this, row, 0);
                }
                Card {
                    id: card2
                    xml: item2
                    upnpServer: page.upnpServer
                    KeyNavigation.right: card3
                    onActiveFocusChanged: registerFocus(this, row, 1);
                }
                Card {
                    id: card3
                    xml: item3
                    upnpServer: page.upnpServer
                    KeyNavigation.right: card4
                    onActiveFocusChanged: registerFocus(this, row, 2);
                }
                Card {
                    id: card4
                    xml: item4
                    upnpServer: page.upnpServer
                    KeyNavigation.right: card5
                    onActiveFocusChanged: registerFocus(this, row, 3);
                }
                Card {
                    id: card5
                    xml: item5
                    upnpServer: page.upnpServer
                    KeyNavigation.right: card6
                    onActiveFocusChanged: registerFocus(this, row, 4);
                }
                Card {
                    id: card6
                    xml: item6
                    upnpServer: page.upnpServer
                    KeyNavigation.right: card7
                    onActiveFocusChanged: registerFocus(this, row, 5);
                }
                Card {
                    id: card7
                    xml: item7
                    upnpServer: page.upnpServer
                    KeyNavigation.right: card1
                    onActiveFocusChanged: registerFocus(this, row, 6);
                }
            }
            Item {
                id: infoContainer
                visible: false
                width: parent.width
                height: 10

                function updateHeight() {

                    var children=infoContainer.children;
                    var h=0;
                    for(var i=0;i<children.length;i++) {
                        var c=children[i];
                        if (c.destroying) {
                            continue;
                        }

                        // console.log("hc="+c.height);
                        h=Math.max(c.height, h);
                    }

                    //console.log("Children rect changed ! h="+h);

                    height=h;

                    if (!h) {
                        infoContainer.visible=false;
                    }
                }
            }
        }
    }

    onStackChanged: {
        if (stack) {
            stack.breadcrumb.opacity=0.7;
        }
    }
}
