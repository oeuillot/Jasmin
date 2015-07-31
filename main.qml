import QtQuick 2.4
import "components" 1.0
import fbx.application 1.0
import fbx.ui.page 1.0
import fbx.ui.layout 1.0

import "./pages" 1.0

Application {
    id: app

    FontLoader {
        id: fontawesome
        source: "components/fonts/fontawesome-webfont__ttf.png"
    }

    JBackground {
        background: "jasmin"
    }

    Stack {
        id: pageStack

        property var breadcrumb;
        property Menu menu : menu;

        anchors {
            top: breadcrumb.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        focus: true

        baseUrl: Qt.resolvedUrl("pages/")

        KeyNavigation.up: breadcrumb

        Component.onCompleted: {
            pageStack.push("server.qml", {
                audioPlayer: menu.audioPlayer,
                menu: menu
            });
        }
    }

    Breadcrumb {
        id: breadcrumb

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        stack: pageStack

        KeyNavigation.down: pageStack

        Component.onCompleted: {
            pageStack.breadcrumb=this;
        }
    }

    Menu {
        id: menu
        visible: false
        x: parent.width-menu.width
        y: breadcrumb.height
    }
}
