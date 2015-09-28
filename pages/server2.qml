import QtQuick 2.2
import fbx.application 1.0
import fbx.ui.page 1.0
import fbx.ui.control 1.0
import "../components" 1.0
import "../jasmin" 1.0
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
        width: parent.width-140-5
        height: parent.height-5
        focus: true

        delegate: card
    }

    Component.onCompleted: {
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
                        label: "Serveur Delabarre",
                        imageURL: "http://192.168.3.193:10293/icons/icon_128.png",
                        url: "http://192.168.3.193:10293/description.xml"
                    },

                    {
                        icon: Fontawesome.Icon.plus_circle,
                        label: "Nouveau serveur"
                    }

                ];

        var lastURL=settings["lastServerURL"];
        console.log("Last url="+lastURL);

        for(var i=0;i<listView.left;i++) {
            if (listView.model[i].url===lastURL) {
                listView.focus(i);
                break;
            }
        }
    }

    function connect(model) {
        console.log("Connect to "+Util.inspect(model));

        if (deferredRequest) {
            deferredRequest.cancel();
            deferredRequest=null;
        }

        //settings["lastServerURL"]=model.url;

        var upnpServer = new UpnpServer.UpnpServer(model.url);

        var contentDirectoryService=new ContentDirectoryService.ContentDirectoryService(upnpServer);

        contentDirectoryService.connect().then(function onSuccess(cresult) {
            page.menu.visible=true;

            page.title="Serveurs";

            page.push("folder.qml", {
                          contentDirectoryService: contentDirectoryService,
                          meta: cresult.rootMeta,
                          title: upnpServer.name,
                          audioPlayer: page.audioPlayer,
                          settings: settings
                      });

        }, function onError(reason) {
            console.log("FAIL "+reason);

            // text.text="La tentative de connexion a échoué : "+reason;

            // enterIP.state="error";
            // urlEntry.forceActiveFocus();
            // connectButton.enabled=true;

        }, function onProgress(message) {
            text.text="Tentative en cours : "+message;
        });
    }
}
