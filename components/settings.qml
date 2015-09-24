/**
 * Copyright Olivier Oeuillot
 */

import QtQuick 2.0

Item {

    property var properties: ({});

    property bool propertiesModified: false;

    function get(name) {
        return properties[name];
    }

    function set(name, value) {
        if (value===undefined) {
            delete properties[name];
        } else {
            properties[name]=value;
        }
        propertiesModified=true;

        timer.restart();
    }

    Timer {
        id: timer
        running: false
        repeat: false
        interval: 1000

        onTriggered: {
            if (running) {
                return;
            }

            propertiesModified=false;

            saveProperties();
        }
    }

    function saveProperties() {

    }

    function loadProperties() {

    }
}
