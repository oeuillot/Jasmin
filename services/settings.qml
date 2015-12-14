/**
 * Copyright Olivier Oeuillot
 */

import QtQuick 2.0
import fbx.async 1.0
import fbx.web 1.0

import "config.js" as Config

Item {

    property var settings: ({});

    property bool settingsLoaded: false;

    property var _deltas: false;

    function get(name) {
        return settings[name];
    }


    function unset(name) {
        set(name, undefined);
    }

    function set(name, value) {
        if (settings[name]===value) {
            return;
        }

        if (_deltas===false) {
            _deltas={};
        }

        if (value===undefined) {
            delete settings[name];

            _deltas[name]="";

        } else {
            settings[name]=value;

            _deltas[name]=value;
        }

        timer.restart();
    }

    function sync() {
        // retourne une promise
        if (!_deltas) {
            return Deferred.resolved();
        }

        return saveSettings();
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

            saveSettings();
        }
    }

    function saveSettings() {
        var clientsURL=Config.getServiceHost("/services/saveSettings");

        var headers= Config.fillHeader();

        headers['Content-Type']='application/json';

        var deltas=_deltas;
        _deltas=false;

        var transaction=Http.Transaction.factory({
                                                     method: "POST",
                                                     url: clientsURL,
                                                     headers: headers,
                                                     body: JSON.stringify(deltas),
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
            _deltas=false;

            return settings;

        }, function onFailed(reason) {
            console.error("Request failed="+reason);
            settingsLoaded=true;

            return null;
        });

        return deferred;
    }
}
