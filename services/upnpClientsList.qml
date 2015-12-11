import QtQuick 2.4
import fbx.async 1.0
import fbx.web 1.0

import "../jasmin/xml.js" as Xml
import "../jasmin/upnpServer.js" as UpnpServer

import "config.js" as Config

Item {
    id: upnpClientsList

    signal newServer(variant server);
    signal removeServer(variant server);
    signal updateServer(variant server);

    property string error: "";

    property bool errored: false;

    function start() {
        timer.start();
        console.log("START TIMER");
    }

    function stop() {
        timer.stop();
        console.log("STOP TIMER");
    }

    Timer {
        id: timer
        interval: 5000
        repeat: true
        triggeredOnStart: true

        property var currentList: ([]);

        property string etag;

        onTriggered: {
            var clientsURL=Config.getServiceHost("/services/upnpClientsList");

            //console.log("ClientsURL="+clientsURL+" etag="+etag);

            var headers= Config.fillHeader();

            if (etag) {
                headers["If-None-Match"]=etag;
            }

            var transaction=Http.Transaction.factory({
                                                         url: clientsURL,
                                                         headers: headers
                                                     });

            var deferred = transaction.send();

            var self=this;

            deferred.then(function onSuccess(response) {
                //console.log("Deferred success: ", response, response.status, response.statusText);

                if (response.isError() || !response.status) {
                    console.error("Request error="+response.status);

                    error="Response error: "+response;
                    return;
                }
                error="";
                if (response.status===304) {
                    return;
                }

                etag=response.headers['etag'];
                //                console.log("ETAG="+etag);

                var newList=response.jsonParse().data;

                var olds={};
                currentList.forEach(function(s) {
                    olds[s.USN]=s;
                });

                newList.forEach(function(s) {
                    var old=olds[s.USN];
                    if (!old) {
                        currentList.push(s);

                        console.log("New server "+s.USN+" "+s.LOCATION);

                        loadProperties(s).then(function(result) {
                            if (!result) {
                                return;
                            }

                            newServer(s);
                        });
                        return;
                    }

                    delete olds[s.USN];
                    if (s.LOCATION===old.LOCATION && s.EXT===old.EXT) {
                        return;
                    }
                    old.LOCATION=s.LOCATION;
                    old.EXT=s.EXT;
                    old.DATE=s.DATE;

                    console.log("Update server "+s.USN+" "+s.LOCATION);

                    loadProperties(old).then(function(result) {
                        if (!result) {
                            return;
                        }

                        updateServer(old);
                    });
                });

                for(var k in olds) {
                    var old=olds[k];

                    currentList.splice(currentList.indexOf(old.USN), 1);

                    console.log("Remove server "+old.USN+" "+old.LOCATION);

                    removeServer(old);
                }

            }, function onFailed(reason) {
                console.error("Can not get list: "+reason);
                error="Fail: "+reason;
            });
        }

        function loadProperties(server) {

            // console.log("Loading properties of '"+server.LOCATION+"'");

            var application=Qt.application;
            var headers= {
                "X-User-Agent": application.name+"/"+application.version+" (QML client; "+application.organization+")"
            };

            var transaction=Http.Transaction.factory({
                                                         url: server.LOCATION,
                                                         headers: headers,
                                                         debug: false
                                                     });
            transaction.url=server.LOCATION; // Microsoft PROBLEM !

            var deferred = transaction.send();

            deferred.then(function onSuccess(response) {
                console.log("Deferred success: ", response, response.status, response.statusText);

                if (response.isError() || !response.status) {
                    console.error("Request error="+response.status+" url="+server.LOCATION);
                    return;
                }

                var xmlNS={'': "urn:schemas-upnp-org:device-1-0"};

                return Xml.parseXML(response.body, {}).then(function(xml) {

                    //console.log("Document="+xml);

                    var name=xml.byPath("root/device/friendlyName", xmlNS).text();
                    if (name) {
                        server.name=name;
                    }

                    var icon256;

                    function test(old, size, node) {
                        var width=parseInt(node.byPath('width', xmlNS).text() || '0', 10);
                        var height=parseInt(node.byPath('height', xmlNS).text() || '0', 10);
                        var depth=parseInt(node.byPath('depth', xmlNS).text() || '0', 10);
                        var type=node.byPath('type', xmlNS).text();

                        if (/(image\/je?pg|image\/png)/.exec(type)) {
                            return;
                        }

                        if (old) {
                            var diff=Math.abs(old.width-128)-Math.abs(width-128);
                            if (diff<0) {
                                return old;
                            }
                            if (!diff) {
                                if (old.depth>depth) {
                                    return old;
                                }

                                if (/image\/jpe?g/.exec(type)) {
                                    return old;
                                }
                            }
                        }

                        var url=node.byPath('url', xmlNS).text();
                        return {
                            width: width,
                            height: height,
                            type: type,
                            depth: depth,
                            url: url
                        };
                    }

                    xml.byPath("root/device/iconList/icon", xmlNS).forEach(function(icon) {
                        icon256=test(icon256, 256, icon);
                    });

                    if (icon256) {
                        var u=UpnpServer.relativeURL(server.LOCATION, icon256.url);
                        server.imageURL=u;
                        server.imageWidth=icon256.width;
                        server.imageHeight=icon256.height;
                    }

                    return server;
                });
            });

            return deferred;
        }
    }
}

