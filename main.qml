import QtQuick 2.4
import "components" 1.0
import fbx.application 1.0
import fbx.ui.page 1.0
import fbx.ui.layout 1.0

Application {
    id: app

    JBackground {
        background: "jasmin"
    }

    Stack {
        id: pageStack

        property var breadcrumb;

        anchors {
            top: breadcrumb.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        focus: true

        initialPage: "server.qml"
        baseUrl: Qt.resolvedUrl("pages/")

        KeyNavigation.up: breadcrumb
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
}
