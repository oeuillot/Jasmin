/**
  * @author Olivier Oeuillot
  */

import QtQuick 2.2
import fbx.application 1.0
import fbx.ui.page 1.0
import fbx.ui.control 1.0
import "../components" 1.0
import "../jasmin" 1.0
import "../services" 1.0
import "." 1.0

Page {
    id: page
    title: "Choix du serveur"

    property Menu menu;
    property AudioPlayer audioPlayer;

    property JSettings settings;

    property var deferredRequest;

    Component {
        id: card

        ServerCard {
            id: widget

            property int cellIndex;

            Keys.onPressed: {
                switch(event.key) {

                case Qt.Key_Return:
                case Qt.Key_Enter:

                    connect(widget.model);

                    event.accepted=true;
                    return;
                }
            }

            onActiveFocusChanged: {

                if (activeFocus) {
                    this.selected=true;
                    return;
                }

                this.selected=false;
            }
        }
    }


    QGrid {
        id: listView
        x: 5
        y: 5
        width: parent.width-5
        height: parent.height-5
        focus: true

        delegate: card
    }

    Component.onCompleted: {

        if (false) {
            listView.model=[
                        {
                            label: "Freebox Serveur",
                            imageURL: "http://mafreebox.freebox.fr:52424/icons/lrg.jpg",
                            url: "http://mafreebox.freebox.fr:52424/device.xml"
                        },
                        {
                            label: "Serveur Lafond",
                            imageURL: "http://localhost:10293/icons/icon_128.png",
                            url: "http://localhost:10293/description.xml"
                        },
                        {
                            label: "Serveur Lafond 2",
                            imageURL: "http://192.168.3.37:10293/icons/icon_128.png",
                            url: "http://192.168.3.37:10293/description.xml"
                        },
                        {
                            name: "Serveur Delabarre",
                            imageURL: "http://192.168.3.193:10293/icons/icon_128.png",
                            LOCATION: "http://192.168.3.193:10293/description.xml"
                        },
                        {
                            label: "FreeMi Marsilly",
                            imageURL: "http://192.168.0.109:61234/icon.png",
                            url: "http://192.168.0.109:61234/"
                        },

                        {
                            icon: Fontawesome.Icon.plus_circle,
                            label: "Nouveau serveur"
                        }
                    ];
        } else {
            listView.model=[];
        }

        var lastURL=settings.get("lastServerURL");
        console.log("Last url="+lastURL);

        /*
        for(var i=0;i<listView.left;i++) {
            if (listView.model[i].url===lastURL) {
                listView.focus(i);
                break;
            }
        }
        */
    }

    function connect(model) {
        console.log("Connect to "+Util.inspect(model));

        if (deferredRequest) {
            deferredRequest.cancel();
            deferredRequest=null;
        }


        settings.set("lastServer.USN", model.USN);

        var upnpServer = new UpnpServer.UpnpServer(model.LOCATION);

        var contentDirectoryService=new ContentDirectoryService.ContentDirectoryService(upnpServer);

        contentDirectoryService.connect().then(function onSuccess(cresult) {
            deferredRequest=null;

            //page.menu.visible=true;

            page.title="Serveurs";

            page.push("folder.qml", {
                          contentDirectoryService: contentDirectoryService,
                          meta: cresult.rootMeta,
                          title: upnpServer.name,
                          audioPlayer: page.audioPlayer,
                          settings: settings
                      });

        }, function onError(reason) {
            console.error("FAIL "+reason);
            deferredRequest=null;

            // text.text="La tentative de connexion a échoué : "+reason;

            // enterIP.state="error";
            // urlEntry.forceActiveFocus();
            // connectButton.enabled=true;

        }, function onProgress(message) {
            text.text="Tentative en cours : "+message;
        });
    }

    onDidAppear: {
        clientsList.start();
    }

    onDidDisappear: {
        clientsList.stop();
    }

    UpnpClientsList {
        id: clientsList;

        onNewServer: {
            //console.log("New Server="+server.ST);
            if (server.ST !== ContentDirectoryService.UPNP_CONTENT_DIRECTORY_1) {
                return;
            }

            var model=listView.model;
            var count=model.length;

            var lastFocus;
            if (listView.focusIndex>=0 && listView.focusIndex<count) {
                lastFocus=model[listView.focusIndex].USN;
            }

            model.push(server);

            model.sort(function(s1, s2) {
                return s1.name-s2.name;
            });

            listView.updateLayout("newServer");

console.log("Last focus="+lastFocus);
            if (!count) {
                listView.focus(0);

            } else if (lastFocus) {
                var lastServerUSN=settings.get("lastServer.USN");

                var focusIdx=-1;
                for(var i=0;i<model.length;i++) {
                    var m=model[i];

                    if (m.USN===lastFocus) {
                        focusIdx=i;
                        continue;
                    }
                    if (m.USN===lastServerUSN) {
                        focusIdx=i;
                        break;
                    }
                }
                listView.focus(focusIdx);
            }
        }

        onRemoveServer: {
            if (server.ST !== ContentDirectoryService.UPNP_CONTENT_DIRECTORY_1) {
                return;
            }

            var i=listView.model.indexOf(server);
            if (i>=0) {
                listView.model.splice(i, 1);
            }
            listView.updateLayout("removedServer");
        }

        onUpdateServer: {
            if (server.ST !== ContentDirectoryService.UPNP_CONTENT_DIRECTORY_1) {
                return;
            }

            listView.model=newList;
            listView.updateLayout("updateServer");
        }
    }
}
