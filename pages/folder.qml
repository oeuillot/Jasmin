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

    property var fillModelDeferred;

    Timer {
        id: timer
        interval: 200
        repeat: true
        triggeredOnStart: true
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: 10
        focus: true

        property int focusColumnIndex;
        property var currentCard;

        function open(card, row){
            console.log("card="+card+" row="+row);

            var xml=Xml.$XML(card.xml);

            var upnpClass=xml.byTagName("class", UpnpServer.UPNP_METADATA_XMLNS).text() || "object.item";
            var objectID=xml.attr("id");

            if (upnpClass==="object.container") {
                upnpServer.browseMetadata(objectID).then(function onSuccess(meta) {

                    page.push("folder.qml", {
                                  upnpServer: page.upnpServer,
                                  meta: meta,
                                  title: card.title
                              });


                }, function onFailure(reason) {
                    console.log("Failure: "+reason);
                });
            }
        }

        model: ListModel {
            id: listModel

            Component.onCompleted: {
                fillModelDeferred=FolderScript.fillModel(this, page.upnpServer, page.meta, timer);
            }
        }
        delegate:
            Row {
            id: row
            focus: true

            function registerFocus(card, columnIndex) {
                if (card.activeFocus){
                    listView.focusColumnIndex=columnIndex;
                    listView.currentCard=card;

                    console.log("Set focus to "+columnIndex);
                }
            }

            Keys.onPressed: {
                console.log("Event="+event.key);
                switch(event.key) {
                case Qt.Key_Return:
                    event.accepted = true;

                    listView.open(listView.currentCard, this);

                    break;
                }
            }

            Card {
                id: card1
                xml: item1
                KeyNavigation.right: card2
                onActiveFocusChanged: registerFocus(this, 0);
            }
            Card {
                id: card2
                xml: item2
                KeyNavigation.right: card3
                onActiveFocusChanged: registerFocus(this, 1);
            }
            Card {
                id: card3
                xml: item3
                KeyNavigation.right: card4
                onActiveFocusChanged: registerFocus(this, 2);
            }
            Card {
                id: card4
                xml: item4
                KeyNavigation.right: card5
                onActiveFocusChanged: registerFocus(this, 3);
            }
            Card {
                id: card5
                xml: item5
                KeyNavigation.right: card6
                onActiveFocusChanged: registerFocus(this, 4);
            }
            Card {
                id: card6
                xml: item6
                KeyNavigation.right: card7
                onActiveFocusChanged: registerFocus(this, 5);
            }
            Card {
                id: card7
                xml: item7
                KeyNavigation.right: card1
                onActiveFocusChanged: registerFocus(this, 6);
            }

            onActiveFocusChanged: {
                console.log("Active focus row "+activeFocus+" / "+listView.focusColumnIndex);
                if (activeFocus) {
                    var card=[card1, card2, card3, card4, card5, card6, card7][listView.focusColumnIndex];

                    card.forceActiveFocus ();
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
