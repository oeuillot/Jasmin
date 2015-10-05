import QtQuick 2.4
import "components" 1.0
import fbx.application 1.0
import fbx.ui.page 1.0
import fbx.ui.layout 1.0

import "./pages" 1.0
import "./jasmin" 1.0

Application {
    id: app

    property Menu menu;

    property bool started: false;

    /*
    Settings {
        id: settings
        App: app
    }
    */

    function startup() {
        if (started) {
            return;
        }
        started=true;

        menu=menuComponent.createObject(app);

        pageStack.push("server2.qml", {
                           audioPlayer: menu.audioPlayer,
                           menu: menu,
                           settings: settings
//                           xmlParserWorker: xmlParserWorker
                       });
    }

    FontLoader {
        id: fontawesome
        source: "components/fonts/fontawesome-webfont__ttf.png"

        onStatusChanged: {
            console.log("Waiting ...");

            if (fontawesome.status===FontLoader.Ready) {
                console.log("GO ...");
                startup();
            }
        }
    }

    JBackground {
        background: "jasmin"
    }

    JSettings {
        id: settings
    }

    Stack {
        id: pageStack

        property var breadcrumb;

        x: 0
        y: breadcrumb.height
        width: parent.width-(menu.visible?menu.width:0)
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

    XmlParserWorker {
        id: xmlParserWorker
    }

    Waiting {
        id: waiting
        x: 0
        y: 64

        xmlParserWorker: xmlParserWorker
    }

    Component {
        id: menuComponent

        // On passe en component pour un probleme de temps de chargement de la fonte !

        Menu {
            id: menu
            x: parent.width-menu.width
            y: breadcrumb.y+breadcrumb.height;
        }
    }

    Component.onCompleted: {

        if (fontawesome.status===FontLoader.Ready) {           
            startup();
        }
    }
}
