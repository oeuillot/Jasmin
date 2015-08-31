import QtQuick 2.0
import "xml.js" as Xml
import fbx.async 1.0

import "xmlParser.js" as XmlParser

WorkerScript {
    id: worker

    property var deferreds: ({})
    property int deferredId: 0;

    property int delayBetweenMessages: 250;

    property int minimumDelay: 500;

    property int workersCount: 0
    property real progress: 0;

    function parseXML(text) {
        worker.source=Qt.resolvedUrl("/jasmin/xmlParser.js");

        var deferred=new Deferred.Deferred();

        var did=deferredId++;

        var now=Date.now();

        deferreds[did]={
          deferred: deferred,
            startDate: now,
            messageDate: now,
            tagCount: 0,
            progress: 0
        };

        sendMessage({ identifier: did,
                      data: text
                     });

        updateProgress();

        return deferred;
    }

    onMessage: {
        var message=messageObject;

        var info = deferreds[message.identifier];
        if (!info) {
            console.error("Unknwon deferredId="+message.identifier);
            return;
        }

        var deferred=info.deferred;

//        console.log("Deferred="+deferred+" reason="+message.reason);

        if (message.reason==="done") {
            delete deferreds[message.identifier];
            updateProgress();
            return;
        }

        if (message.reason==="closeTag") {
            info.tagCount++;
            var now=Date.now();
            if (info.messageDate+delayBetweenMessages>now) {
               return;
            }
            info.messageDate=now;
            info.progress=message.progress;
            updateProgress();

            deferred.progress({tag: message.detail, count: info.count, progress: message.progress});
            return;
        }

        if (message.reason==="exception") {
            info.progress=1;
            updateProgress();

            deferred.reject(message.detail);
            return;
        }

        if (message.reason==="closeDocument") {
            info.progress=1;
            updateProgress();

            deferred.resolve(Xml.$XML(message.detail), info.tagCount);            
            return;
        }
    }

    function updateProgress() {
        var count=0;
        var p=0;
        var now=Date.now();

        for(var k in deferreds) {
            var info=deferreds[k];
            if (info.start+minimumDelay>now) {
                continue;
            }

            p+=info.progress;
            count++;
        }

        //console.log("Progress "+count+"/"+p);

        worker.workersCount=count;

        worker.progress=count?(p/count):0;
    }
}
