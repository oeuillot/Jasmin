/**
 * Copyright Olivier Oeuillot
 */

import QtQuick 2.0
import fbx.async 1.0
import fbx.web 1.0

import "config.js" as Config

Item {

    property var settings: ({});

    property bool settingsModified: false;

    property bool settingsLoaded: false;

    function get(name) {
        return settings[name];
    }

    function set(name, value) {
        if (value===undefined) {
            delete settings[name];
        } else {
            settings[name]=value;
        }
        settingsModified=true;

        timer.restart();
    }

    function sync() {
        // retourne une promise
    }

    Component.onCompleted: {
        loadSettings();
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

            settingsModified=false;

            saveSettings();
        }
    }

    function saveSettings() {
        var clientsURL=Config.getServiceHost("/services/saveSettings");

        var headers= Config.fillHeader();

        headers['Content-Type']='application/json';

        var transaction=Http.Transaction.factory({
                                                     method: "POST",
                                                     url: clientsURL,
                                                     headers: headers,
                                                     body: JSON.stringify(settings),
                                                     debug: true
                                                 });

        var deferred = transaction.send();

        return deferred;
    }

    function loadSettings() {
        var clientsURL=Config.getServiceHost("/services/loadSettings");

        var headers= Config.fillHeader();

        var transaction=Http.Transaction.factory({
                                                     url: clientsURL,
                                                     headers: headers
                                                 });

        var deferred = transaction.send();

        var self=this;

        deferred.then(function onSuccess(response) {
            console.log("Deferred success: ", response, response.status, response.statusText);

            settingsLoaded=true;

            if (response.isError() || !response.status) {
                console.error("Request error="+response.status);

                return null;
            }

            settings=response.jsonParse().data;
            settingsModified=false;

            return settings;

        }, function onFailed(reason) {
            console.error("Request failed="+reason);
            settingsLoaded=true;

            return null;
        });

        return deferred;
    }
}
