import QtQuick 2.0

import fbx.async 1.0


WorkerScript {

    property var deferreds: ({})
    property int deferredId: 0;

    function parseXML(xml) {
        var deferred=new Deferred.Deferred();

        var did=deferredId++;

        sendMessage({ deferredId: did,
                      xml: xml
                     });
    }

    onMessage: {
        var message=messageObject;

        var deferred = deferreds[message.deferredId];
        delete deferreds[message.deferredId];

        deferred.resolve(message.parsedXML);
    }

}
