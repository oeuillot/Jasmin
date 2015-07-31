import QtQuick 2.2
import fbx.application 1.0
import fbx.ui.page 1.0
import fbx.ui.control 1.0
import "../components" 1.0
import "../jasmin" 1.0
import "." 1.0

import "server.js" as ServerScript;

Page {
    id: page
    title: "Choix du serveur"

    property Menu menu;
    property AudioPlayer audioPlayer;

    Column {
        id: enterIP

        property var deferredRequest;

        Text {
            text: "Saisissez l'adresse et le port du serveur UPNP :"
            color: "black"
            font.bold: true
        }
        Row {
            Text {
                text: "http://"
                color: "black"
                font.bold: true

                anchors.verticalCenter: parent.verticalCenter
            }

            TextInput {
                id: urlEntry
                font.bold: true
                color: "black"
                width: 700
                text: "192.168.0.58:10293/DeviceDescription.xml"
                displayText: "URL du server"

                property string text1: "192.168.3.32:10293/DeviceDescription.xml"
                property string text2: "192.168.3.193:10293/DeviceDescription.xml"
                property string text3: "localhost:10293/DeviceDescription.xml"

                anchors.verticalCenter: parent.verticalCenter

                KeyNavigation.down: connectButton

                Component.onCompleted: {
                    //console.log("AppWIndow=", Util.inspect(Qt.application));
                }
            }
        }

        Row {
            Text {
                id: text
                text: "Par exemple: http://192.168.3.193:10293/DeviceDescription.xml"
                color: "black"
                font.bold: true
                font.pixelSize: 12
                height: 24
            }
            JLoading {
                id: loading
                width: 24
                height: 24
                visible: !!enterIP.deferredRequest
            }
        }
        Button {
            id: connectButton

            KeyNavigation.up: urlEntry
            focus: true

            text: "Se connecter au serveur"
            onClicked: {
                console.log("Change ! "+urlEntry.text);

                connectButton.enabled=false;

                if (enterIP.deferredRequest) {
                    enterIP.deferredRequest.cancel();
                }

                enterIP.deferredRequest=ServerScript.tryURL("http://"+urlEntry.text);

                text.text="Tentative de connexion ...";

                //console.log("deferred="+enterIP.deferredRequest);

                enterIP.deferredRequest.then(function(result) {
                    console.log("SUCCESS !");
                    text.text="Tentative réussie";
                    enterIP.state="hide";
                    enterIP.deferredRequest=null;

                    page.menu.visible=true;

                    var upnpServer=result.upnpServer;
                    var meta=result.rootMeta;

                    page.title="Serveurs";

                    page.push("folder.qml", {
                                  upnpServer: upnpServer,
                                  meta: meta,
                                  title: upnpServer.name,
                                  audioPlayer: page.audioPlayer
                              });

                }, function(reason) {
                    enterIP.deferredRequest=null;

                    text.text="La tentative de connexion a échoué : "+reason;

                    enterIP.state="error";
                    urlEntry.forceActiveFocus();
                    connectButton.enabled=true;

                }, function(message) {
                    text.text="Tentative en cours : "+message;
                });
            }
        }

        x: 0
        opacity: 0
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter

        states: [
            State {
                name: "show"
                PropertyChanges {
                    target: enterIP
                    x: 100
                    opacity: 1
                }
            },
            State {
                name: "error"
                PropertyChanges {
                    target: enterIP
                    x: 100
                    opacity: 1
                }
            },
            State {
                name: "hide"
                PropertyChanges {
                    target: enterIP
                    x: 0
                    opacity: 0
                }
            }
        ]

        transitions: [
            Transition {
                to:"show"
                NumberAnimation { properties: "x"; duration:800; easing.type: Easing.OutCubic}
                NumberAnimation { properties: "opacity"; duration: 800 }
            },
            Transition {
                to:"error"
                SequentialAnimation {
                    loops: 5
                    NumberAnimation { properties: "x"; to: 120; duration: 40; easing.type: Easing.InOutQuad }
                    NumberAnimation { properties: "x"; to: 80; duration: 80; easing.type: Easing.InOutQuad }
                    NumberAnimation { properties: "x"; to: 100; duration: 40; easing.type: Easing.InOutQuad }
                }
                NumberAnimation { properties: "opacity"; duration: 0 }
                onRunningChanged: {
                    if (!running) {
                        enterIP.state="show";
                    }
                }
            },
            Transition {
                to:"hide"
                NumberAnimation { properties: "x"; duration:800; easing.type: Easing.OutCubic}
                NumberAnimation { properties: "opacity"; duration: 800 }
            }
        ]
    }

    Component.onCompleted: {
        enterIP.state="show"
    }
}
