import QtQuick 2.4
import QtMultimedia 5.5
import "components" 1.0
import fbx.application 1.0
import fbx.ui.page 1.0
import fbx.ui.layout 1.0

import "./pages" 1.0
import "./jasmin" 1.0
import "./services" 1.0

Application {
    id: app

    color: "#FEFFFFFF" // Super technique pour contourner une limitation Freebox :-p  (merci mid pour l'astuce)

    property Menu menu;

    property bool starting: false;

    JSettings {
        id: settings

        onSettingsLoadedChanged: {
            startup();
        }
    }

    function startup() {
        if (fontawesome.status!==FontLoader.Ready) {
            return;
        }

        if (!settings.settingsLoaded) {
            return;
        }

        if (!starting) {
            return;
        }
        starting=false;

        menu=menuComponent.createObject(app, {
                                            settings: settings,
                                            videoOutput: videoOutput
                                        });

        pageStack.push("server2.qml", {
                           audioPlayer: menu.audioPlayer,
                           menu: menu,
                           settings: settings
                       });

    }

    FontLoader {
        id: fontawesome
        source: "components/fonts/fontawesome-webfont__ttf.png"

        onStatusChanged: {
            if (status===FontLoader.Ready) {
                startup();
            }
        }
    }

    JBackground {
        background: "jasmin"
    }

    Stack {
        id: pageStack

        property var breadcrumb;

        x: 0
        y: breadcrumb.height
        width: parent.width-((menu && menu.visible)?menu.width:0)
        height: parent.height-breadcrumb.height
        focus: true

        baseUrl: Qt.resolvedUrl("pages/")

        KeyNavigation.up: breadcrumb
    }

    Breadcrumb {
        id: breadcrumb
        x:0
        y:0
        width: parent.width

        stack: pageStack

        KeyNavigation.down: pageStack

        Component.onCompleted: {
            pageStack.breadcrumb=this;
        }
    }

    Component {
        id: menuComponent

        // On passe en component pour un probleme de temps de chargement de la fonte !

        Menu {
            id: menu
            x: parent.width-menu.width
            y: breadcrumb.y+breadcrumb.height
        }
    }

    Component.onCompleted: {
        starting=true;
        startup();
    }

    VideoOutput {
        id: videoOutput
        visible: false
        z: 65536
        fillMode: VideoOutput.PreserveAspectFit
    }

    /*
    Video {
        id: videoView

        x: 0 //imageColumn.x
        y: 0 //imageColumn.y
        width: 256 //imageColumn.width
        height: 256 //imageColumn.width

        source: "http://192.168.3.193:10293/cds/content/23552?contentHandler=af_metas&resKey=trailer_221413"
        autoPlay: true
        autoLoad: true
    }
    */
}
