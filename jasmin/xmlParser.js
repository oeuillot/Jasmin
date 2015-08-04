
function parseXML(text, callbacks) {
    var stack = [];
    var poped;
    var node;
    callbacks=callbacks || {};

    var sp={};

    var dictionnary={};
    var defaultNamespaceURI="";

    var start=Date.now();
    var d3=0;

    var attrSplitRegExp=/[	 ]+/g;
    var selfClosingRegExp=/\/$/;
    var attrValueRegExp=/([a-z-_]+)(:[a-z-_]+)?(="[^"]*"|='[^']*')?/i;

    var iter = text.split(/(<[^>]+>)/);

    var document={
        nodeType: 9,
        nodeName: "Document",
        namespaceURIs: dictionnary,
    };

    if (callbacks.openDocument) {
        callbacks.openDocument(document);
    }

    for (var i = 0; i < iter.length; ++i) {
        var progress=i/iter.length;
        var item = iter[i];

        if (item.charAt(0) === "<") {
            item = item.slice(1, -1);

            switch (item.charAt(0)) {
            case "/":
                var nodeName = item.slice(1).trim();

                if (!node || node.tagName !== nodeName) {
                    throw new Error("Malformed document");
                }

                if (callbacks.closeTag) {
                    callbacks.closeTag(node, progress);
                }

                poped = stack.pop();
                node = stack[stack.length - 1];
                break;


            case "?":
                break;

            case "!":
                break;

            default:
                var self_closing = selfClosingRegExp.test(item);
                if (self_closing) {
                    item = item.slice(0, -1).trim();
                }

                var n = {
                    nodeType: 1,
                };

                attrSplitRegExp.lastIndex=0;
                var attrs = item.split(attrSplitRegExp);
                var atts = [];

                for (var j = 1; j < attrs.length; ++j) {
                    var attr=attrs[j];
                    if (!attr){
                        continue;
                    }

                    var kv = attrValueRegExp.exec(attr);

                    if (kv[1]==="xmlns") {
                        if (!kv[3]) {
                            continue;
                        }
                        if (!kv[2]) {
                            defaultNamespaceURI=kv[3].slice(2, -1);
                            continue;
                        }

                        //console.log("Fill dic "+kv[2].slice(1)+" = "+kv[3].slice(2, -1));

                        dictionnary[kv[2].slice(1)]=kv[3].slice(2, -1);
                        continue;
                    }

                    var att={
                    };
                    atts.push(att);

                    if (kv[2]) {
                        att.name=kv[1]+kv[2];
                        //                        att.namespaceURI=dictionnary[kv[1]];
                    } else {
                        att.name=kv[1];
                        //                        att.namespaceURI=defaultNamespaceURI;
                    }

                    if (!kv[3]) {
                        continue;
                    }
                    att.value = kv[3].slice(2, -1);
                }

                if (atts.length) {
                    n.attributes=atts;
                }

                sp=splitName(item, sp);

                if (sp.xmlns) {
                    n.tagName=sp.xmlns+":"+sp.name;
                    //                    n.prefix=nms[1];
                    n.namespaceURI=dictionnary[sp.xmlns];
                    //console.log("Search dic '"+nms[1]+"' => "+dictionnary[nms[1]]);

                } else {
                    n.tagName=sp.name;
                    n.namespaceURI=defaultNamespaceURI;
                }

                if (node) {
                    if (!node.childNodes){
                        node.childNodes=[];
                    }

                    node.childNodes.push(n);
                }

                if (!self_closing) {
                    stack.push(n);
                    node = n;
                }

                if (callbacks.openTag) {
                    callbacks.openTag(node, progress);
                }

                if (self_closing && callbacks.closeTag) {
                    callbacks.closeTag(n, progress);
                }

                break;
            }
            continue;
        }

        item = item.trim();

        if (!item.length) {
            continue;
        }

        if (!node) {
            throw new Error("Malformed document");
        }

        var d2=Date.now();
        var txt = _unescape(item);

        d3+=Date.now()-d2;

        if (!node.childNodes){
            node.childNodes=[];
        }

        var textNode={ nodeType: 3, nodeValue: txt };

        node.childNodes.push(textNode);

        if (callbacks && callbacks.textNode) {
            callbacks.textNode(n, progress);
        }
    }

    dictionnary[""]=defaultNamespaceURI;

    start=Date.now()-start;
    console.log("Parsing: "+start+"ms size="+text.length+" escape="+d3+"ms");

    document.documentElement=poped;

    if (callbacks.closeDocument) {
        callbacks.closeDocument(document);
    }

    return document;
}


var lookup = {
    lt: "<",
    gt: ">",
    quot: '"',
    apos: "'",
    amp: "&"
};

function _unescape(t) {
    if (!t) {
        return t;
    }

    for(var i=0;i<1000000;i++) {
    }

    var ret;
    var idx=0;

    for(;;) {
        var i2=t.indexOf('&', idx);
        if (i2<0) {
            break;
        }

        if (!ret) {
            ret=[];
        }

        if (i2>idx) {
            ret.push(t.substring(idx, i2));
        }

        var i3=t.indexOf(';', i2);
        idx=i3+1;

        ret.push(lookup[t.substring(i2+1, i3)]);
    }

    if (!ret) {
        return t;
    }

    ret.push(t.substring(idx));

    return ret.join('');
};

var _splitNameRegExp=/([a-z0-9_-]+:)?([a-z0-9_-]+)/i;
function splitName(name, ret) {
    ret=ret || {};

    var kv = _splitNameRegExp.exec(name);

    if (kv[1]) {
        ret.xmlns=kv[1].slice(0, -1);
    } else {
        ret.xmlns=undefined;
    }

    ret.name=kv[2];

    return ret;
}



if (typeof(WorkerScript)!=="undefined") {
    WorkerScript.onMessage = function(message) {
        try {
            parseXML(message.data, {
                         closeTag: function(tag, progress) {
                             WorkerScript.sendMessage({
                                                          identifier: message.identifier,
                                                          reason: "closeTag",
                                                          detail: tag,
                                                          progress: progress
                                                      });
                         },

                         closeDocument: function(document) {
                             WorkerScript.sendMessage({
                                                          identifier: message.identifier,
                                                          reason: "closeDocument",
                                                          detail: document
                                                      });
                         }
                     });
        } catch (x) {
            WorkerScript.sendMessage({
                                         identifier: message.identifier,
                                         reason: "exception",
                                         detail: x
                                     });
        }
        WorkerScript.sendMessage({
                                     identifier: message.identifier,
                                     reason: "done"
                                 });
    }
}
