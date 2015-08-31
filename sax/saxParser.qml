import QtQuick 2.0
import fbx.async 1.0

import "sax.js" as Sax;
import "../jasmin/util.js" as Util
import "../jasmin/xml.js" as Xml

Timer {
    id: timer

    interval: 10

    repeat: true

    triggeredOnStart: true

    property bool xmlStrict: true

    property var xmlOptions: ({ xmlns: true, position: false})

    property int chunckSize: 1024*4;

    property double progress: 0;

    property int delayBetweenMessages: 250;

    property int workersCount: 0;

    function parseXML(buffer, callbacks) {
        var startMs=Date.now();

        progress=0;
        var performance=0;
        timer.workersCount++;
        var bufferSize=buffer.length;
        var bufferPosition = 0;

        console.log("Parse "+bufferSize+" bytes");

        if (timer.workersCount>1) {
            console.log("WORKERS COUNT "+timer.workersCount);
        }

        var parser=Sax.parser(xmlStrict, xmlOptions);

        var dictionnary={};
        var document={
            nodeType: 9,
            tagName: "Document",

            namespaceURIs: dictionnary
        };

        var stack=[document];

        var deferred=new Deferred.Deferred();

        var tagCount=0;

        var _splitNameRegExp = /(xmlns)(:[a-z0-9_-]+)?/i;

        parser.onopentag=function(tag) {
            //console.log("ON START TAG "+Util.inspect(tag, false, {}));

            tagCount++;

            var child={
                tagName: tag.name,
                nodeType: 1,
                namespaceURI: tag.uri
            };

            var parent=stack[stack.length-1];

            if (stack.length===1) {
                parent.documentElement=child;

            } else {
                if (!parent.childNodes) {
                    parent.childNodes=[];
                }
                parent.childNodes.push(child);
            }

            stack.push(child);

            var xmlns;
            if (tag.uri && parent.namespaceURIs[tag.prefix]!==tag.uri) {
                xmlns = {};
                for ( var k in parent.namespaceURIs) {
                    xmlns[k] = parent.namespaceURIs[k];
                }
                xmlns[tag.prefix]=tag.uri;
            }

            var attributes=tag.attributes;
            if (attributes) {
                for ( var name in attributes) {
                    var value = attributes[name];

                    var r = _splitNameRegExp.exec(name);

                    //console.log("Try attr "+name+"/"+value, r);

                    if (!r) {
                        if (!child.attributes) {
                            child.attributes=[];
                        }
                        child.attributes.push({name: name, value: value.value});

                        continue;
                    }
                    if (!xmlns) {
                        xmlns = {};
                        for ( var k in parent.namespaceURIs) {
                            xmlns[k] = parent.namespaceURIs[k];
                        }
                    }

                    var xname=(r[2] && r[2].slice(1)) || "";
                    xmlns[xname] = value.value;
                    dictionnary[xname]=value.value;
                }
            }

            child.namespaceURIs = xmlns || parent.namespaceURIs;

            if (callbacks && callbacks.openTag) {
                callbacks.openTag(child, progress);
            }

            //console.log("OPEN TAG "+Util.inspect(child, false, {}));
        }

        var lastMessageDate=Date.now();

        parser.onclosetag=function() {
            //console.log("ON CLOSE TAG ");
            var closed=stack[stack.length-1];
            stack.pop();
            if (!stack.length) {
                // Document !

                if (callbacks && callbacks.closeDocument) {
                    callbacks.closeDocument(closed);
                }
                return;
            }

            if (callbacks && callbacks.closeTag) {
                callbacks.closeTag(closed, progress);
            }

            var now=Date.now();
            if (lastMessageDate+delayBetweenMessages>now) {
                return;
            }
            lastMessageDate=now;

            progress=bufferPosition/bufferSize;

            deferred.progress({count: tagCount, progress: progress});
        }

        parser.ontext=function(text){
            text=text.trim();
            if (!text) {
                return;
            }
            var tag=stack[stack.length-1];
            if (!tag.childNodes) {
                tag.childNodes=[];
            }
            tag.childNodes.push({ nodeType: 3, nodeValue: text });
        }


        //console.log("TIMER START");

        var triggerCount=0;

        function trigger() {
            triggerCount++;
            console.log("TRIGGER ! "+bufferPosition+"/"+bufferSize);
            if (bufferPosition>=bufferSize) {
                parser.end();
                return;
            }

            var now=Date.now();

            var size=Math.min(bufferSize-bufferPosition, chunckSize);

            var buf=buffer.substring(bufferPosition, bufferPosition+size);
            bufferPosition+=size;

            try {
                parser.write(buf);

            } catch (x) {
                console.error(x);
                bufferSize=-1;
                return;
            }

            var perf=Date.now()-now;
 //           console.log("Perf "+perf)
            performance+=Date.now()-now;

            if (bufferPosition>=bufferSize) {
                parser.end();
            }
        }
        timer.onTriggered.connect(trigger);

        parser.onend=function() {
            //console.log("ON END "+Util.inspect(document, false, {}));
            timer.onTriggered.disconnect(trigger);
            timer.progress=1;

            timer.workersCount--;
            if (timer.workersCount===0) {
                timer.stop();
            }

            var perf=Date.now()-startMs;

            console.log("PERFORMANCE = "+performance+"ms/ "+bufferSize+"bytes/ trigger="+triggerCount+"/ total="+perf+"ms");
            deferred.resolve(Xml.$XML(document), tagCount);
        };

        if (!timer.running) {
            timer.start();
        }
        return deferred;
    }
}


