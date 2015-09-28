.pragma library

.import fbx.async 1.0 as Async
.import fbx.web 1.0 as Web

.import "util.js" as Util
.import "xml.js" as Xml
.import "xmlParser.js" as XmlParser

var UPNP_SERVICE_XMLNS="urn:schemas-upnp-org:service-1-0";
var UPNP_DEVICE_XMLNS="urn:schemas-upnp-org:device-1-0";
var DLNA_DEVICE_XMLNS="urn:schemas-dlna-org:device-1-0";
var SOAP_ENVELOPE_XMLNS="http://schemas.xmlsoap.org/soap/envelope/";
var UPNP_METADATA_XMLNS="urn:schemas-upnp-org:metadata-1-0/upnp/";

var DEVICE_XMLNS_SET={
    "": UPNP_DEVICE_XMLNS,
    "dlna": DLNA_DEVICE_XMLNS,
    "s": SOAP_ENVELOPE_XMLNS
}

function UpnpServer(url, xmlParserWorker) {
    this.url=url;
    this.errored=undefined;
    this.xmlParserWorker=xmlParserWorker;

    this.deviceDescription=null;
    this.urlBase=null;
}

UpnpServer.prototype.constructor = UpnpServer;

UpnpServer.prototype.connect=function(){

    if (this.errored!==undefined) {
        return Async.Deferred.rejected(this.errored);
    }

    if (this.errored===false) {
        return Async.Deferred.resolved(this);
    }

    var application=Qt.application;

    console.log("URL="+this.url);

    var transaction=Web.Http.Transaction.factory({
                                                     method: "GET",
                                                     url: this.url,
                                                     headers: {
                                                         "user-agent": application.name+"/"+application.version+" (QML client; "+application.organization+")"
                                                     }
                                                 });

    var deferred = transaction.send();

    var self=this;

    deferred=deferred.then(function onSuccess(response) {
        console.log("Deferred success: ", Util.inspect(response), response.status, response.statusText);

        if (response.isError() || !response.status) {
            self.errored="Server error "+response.statusText;

            console.error(self.errored);

            return Async.Deferred.rejected(self.errored);
        }

        var deferred;
        if (self.xmlParserWorker) {
            deferred=self.xmlParserWorker.parseXML(response.body);

        } else {
            deferred = Xml.parseXML(response.body);
        }

        deferred=deferred.then(function onSuccess(xmlResponse) {
            try {
                self._fillDeviceDescription(xmlResponse).then(function onSuccess(services) {
                    return {
                        upnpServer: self,
                        services: services,
                        xml: xmlResponse
                    };
                });

            } catch (x){
                self.errored="Can not parse document "+x;
                console.exception("Can not parse document",x,x.message,"At "+x.fileName+":"+x.lineNumber);
                return Async.Deferred.rejected(self.errored);
            }
        });

        deferred = deferred.then(function onSuccess(result) {
            self.errored=false;

            return result;
        });

        return deferred;

    }, function onFailure(failed) {
        console.error("Deferred failed: ",failed);

        self.errored=failed;

        return failed;
    });

    return deferred;
}

UpnpServer.prototype._fillDeviceDescription=function(xmlDocument) {

    var jsDocument=xmlDocument.toObject();
    this.deviceDescription=jsDocument;
    console.log("DeviceDescription=",Util.inspect(jsDocument, false, {} ));
    //console.log("DeviceDescription XML=",Util.inspect(xmlDocument, false, {} ));

    var url=xmlDocument.byPath("root/device/URLBase", DEVICE_XMLNS_SET).text();
    if (!url) {
        url=this.url;
    }
    this.urlBase=new Web.Http.URL(url);

    console.log("urlBase="+this.urlBase);

    this.name=xmlDocument.byPath("root/device/friendlyName", DEVICE_XMLNS_SET).text() || "Server"
    console.log("name="+this.name);

    var services={};
    this.services=services;
    xmlDocument.byPath("root/device/serviceList/service", DEVICE_XMLNS_SET).toObjects().forEach(function(s) {
        services[s.serviceType]=s;
    });

    //console.log("services=", Util.inspect(services));

    return Async.Deferred.resolved(services);
}

UpnpServer.prototype._validServer=function() {
    if (this.errored!==false) {
        throw new Error("Server is not ready ("+this.errored+")");
    }
}

UpnpServer.prototype.relativeURL = function(url) {
    return Web.Http.URL.prototype.relative.call(this.urlBase, url);
}
