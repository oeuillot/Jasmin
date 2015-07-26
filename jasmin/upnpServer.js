.pragma library

.import fbx.async 1.0 as Async
.import fbx.web 1.0 as Web

.import "util.js" as Util
.import "xml.js" as Xml
.import "soapTransport.js" as Soap


var UPNP_SERVICE_XMLNS="urn:schemas-upnp-org:service-1-0";
var UPNP_DEVICE_XMLNS="urn:schemas-upnp-org:device-1-0";
var DLNA_DEVICE_XMLNS="urn:schemas-dlna-org:device-1-0";
var UPNP_CONTENT_DIRECTORY_1_XMLNS="urn:schemas-upnp-org:service:ContentDirectory:1";
var SOAP_ENVELOPE_XMLNS="http://schemas.xmlsoap.org/soap/envelope/";
var DIDL_LITE_XMLNS="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/";
var UPNP_METADATA_XMLNS="urn:schemas-upnp-org:metadata-1-0/upnp/";
var PURL_ELEMENT_XMLS="http://purl.org/dc/elements/1.1/";

var CONTENT_DIRECTORY_TYPE=UPNP_CONTENT_DIRECTORY_1_XMLNS;

var CONTENT_DIRECTORY_XMLNS_SET={
    "": UPNP_SERVICE_XMLNS,
    "dlna": DLNA_DEVICE_XMLNS,
    "u": UPNP_CONTENT_DIRECTORY_1_XMLNS,
    "s": SOAP_ENVELOPE_XMLNS
}

var DEVICE_XMLNS_SET={
    "": UPNP_DEVICE_XMLNS,
    "dlna": DLNA_DEVICE_XMLNS,
    "s": SOAP_ENVELOPE_XMLNS
}

var DIDL_XMLNS_SET = {
    "": DIDL_LITE_XMLNS,
    "upnp": UPNP_METADATA_XMLNS,
    "dc": PURL_ELEMENT_XMLS
}


function UpnpServer(url) {
    this.url=url;
    this.errored=undefined;

    this.deviceDescription=null;
    this.urlBase=null;
}

UpnpServer.prototype.constructor = UpnpServer;

UpnpServer.prototype.tryConnection=function(){

    if (this.errored!==undefined) {
        return Async.Deferred.rejected(this.errored);
    }

    var transaction=Web.Http.Transaction.factory({
                                                     method: "get",
                                                     url: this.url
                                                 });

    var deferred = transaction.send();

    var self=this;

    deferred=deferred.then(function onSuccess(response) {
        //console.log("Deferred succes: ", Util.inspect(response), response.status, response.statusText);

        if (response.isError() || !response.status) {
            self.errored="Server error "+response.statusText;

            console.error(self.errored);

            return Async.Deferred.rejected(self.errored);
        }

        var deferred = Xml.parseXml(response.body);

        deferred=deferred.then(function(xmlResponse) {
            try {
                return self._fillDeviceDescription(xmlResponse);

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

    }, function onProgress(message){
        console.log("Deferred progress: ",message);
    });

    return deferred;
}

UpnpServer.prototype._fillDeviceDescription=function(xmlDocument) {

    var jsDocument=xmlDocument.toObject();
    this.deviceDescription=jsDocument;
    //console.log("DeviceDescription=",Util.inspect(jsDocument, false, {} ));
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

    var contentDirectoryService=this.services[CONTENT_DIRECTORY_TYPE];
    if (!contentDirectoryService){
        throw new Error("No content directory service !");
    }

    var controlURL=this.relativeURL(contentDirectoryService.controlURL);

    console.log("controlURL=", controlURL);

    var soapTransport=new Soap.SoapTransport(controlURL.toString());
    this.soapTransport=soapTransport;

    var self=this;

    var deferred = this.getSortCapabilities().then(function onSuccess(sortCaps) {
        self.sortCaps=sortCaps;
        console.log("SortCaps="+Util.inspect(sortCaps));

        var deferred2=self.getSearchCapabilities().then(function onSuccess(searchCaps) {
            self.searchCaps=searchCaps;
            console.log("SearchCaps="+Util.inspect(searchCaps));

            var deferred3=self.getSystemUpdateID().then(function onSuccess(systemUpdateID) {
                self.systemUpdateID=systemUpdateID;
                console.log("SystemUpdateID="+systemUpdateID);

                var deferred4=self.browseMetadata(0).then(function(meta) {
                    //console.log("Meta="+Util.inspect(meta, false, {}));

                    return {
                        upnpServer: self,
                        rootMeta: meta
                    };
                });

                return deferred4;
            });

            return deferred3;
        });

        return deferred2;
    });

    return deferred;
}

UpnpServer.prototype._validServer=function() {
    if (this.errored!==false) {
        throw new Error("Server is not ready ("+this.errored+")");
    }
}

UpnpServer.prototype.getContentDirectoryService=function() {
    this._validServer();

    return this.services[CONTENT_DIRECTORY_TYPE];
}


UpnpServer.prototype.getSortCapabilities=function() {
    var deferred=this.soapTransport.sendAction("urn:schemas-upnp-org:service:ContentDirectory:1#GetSortCapabilities", {
                                                   _name: "u:GetSortCapabilitiesRequest",
                                                   _attrs: {
                                                       "xmlns:u" :"urn:schemas-upnp-org:service:ContentDirectory:1"
                                                   }
                                               });

    deferred.then(function onSuccess(response) {
        var sc=response.soapBody.byPath("u:GetSortCapabilitiesResponse/SortCaps", CONTENT_DIRECTORY_XMLNS_SET);
        if (!sc.length) {
            return undefined;
        }

        var ret={};
        var sorts=sc.text().split(',');
        var xmlns=response.xmlns;

        var sp={};
        sorts.forEach(function(sort) {
            Xml.splitName(sort, sp);

            var x=xmlns[sp.xmlns || ""];
            var key=sp.name+"##"+x;

            ret[key]={xmlns:x, name: sp.name };
        });

        return ret;
    });

    return deferred;
}

UpnpServer.prototype.getSearchCapabilities=function() {
    var deferred=this.soapTransport.sendAction("urn:schemas-upnp-org:service:ContentDirectory:1#GetSearchCapabilities", {
                                                   _name: "u:GetSearchCapabilitiesRequest",
                                                   _attrs: {
                                                       "xmlns:u" :"urn:schemas-upnp-org:service:ContentDirectory:1"
                                                   }
                                               });

    deferred.then(function onSuccess(response) {
        var sc=response.soapBody.byPath("u:GetSearchCapabilitiesResponse/SearchCaps", CONTENT_DIRECTORY_XMLNS_SET);
        if (sc.length) {
            return sc.text().split(',');
        }

        return undefined;
    });

    return deferred;
}

UpnpServer.prototype.getSystemUpdateID=function() {

    var deferred=this.soapTransport.sendAction("urn:schemas-upnp-org:service:ContentDirectory:1#GetSystemUpdateID", {
                                                   _name: "u:GetSystemUpdateIDRequest",
                                                   _attrs: {
                                                       "xmlns:u" :"urn:schemas-upnp-org:service:ContentDirectory:1"
                                                   }
                                               });

    deferred.then(function onSuccess(response) {

        var id=response.soapBody.byPath("u:SystemUpdateID/Id", CONTENT_DIRECTORY_XMLNS_SET);
        if (!id.length) {
            return undefined;
        }

        return id.text();
    });

    return deferred;
}


UpnpServer.prototype.browseDirectChildren=function(objectId, filter, startingIndex, requestedCount, sortCriteria ) {

    return this.browse(objectId, "BrowseDirectChildren", filter, startingIndex, requestedCount, sortCriteria);
}

UpnpServer.prototype.browseMetadata=function(objectId) {
    return this.browse(objectId, "BrowseMetadata", null, 0, 0, null);
}

UpnpServer.prototype.relativeURL = function(url) {
    return Web.Http.URL.prototype.relative.call(this.urlBase, url);
}

UpnpServer.prototype.browse=function(objectId, browseFlag, filters, startingIndex, requestedCount, sortCriteria) {

    var xmlns={
    };
    xmlns[PURL_ELEMENT_XMLS]="dc";
    xmlns[UPNP_SERVICE_XMLNS]="u";
    xmlns[UPNP_METADATA_XMLNS]="upnp"
    xmlns[DIDL_LITE_XMLNS]="didl"

    var xmlnsAno=0;

    function getPrefix(namespaceURI) {

        var prefix=xmlns[namespaceURI];
        if (prefix!==undefined) {
            return prefix;
        }

        prefix="jasmin"+(++xmlnsAno);
        xmlns[namespaceURI]=prefix;

        return prefix;
    }


    var filterParams=[];
    if (filters) {
        filters.forEach(function(filter) {
            var name=filter.name;
            var prefix=getPrefix(filter.namespaceURI);

            filterParams.push((prefix?(prefix+":"):"")+name);
        });
    }

    var sortParams=[];
    if (sortCriteria) {
        sortCriteria.forEach(function(criteria) {
            var name=criteria.name;
            var prefix=getPrefix(criteria.namespaceURI);

            sortParams.push((criteria.ascending?'+':'-')+(prefix?(prefix+":"):"")+name);
        });
      }

    var attrs={};
    for(var x in xmlns) {
        var prefix=xmlns[x];
        attrs["xmlns"+(prefix?(':'+prefix):'')]=x;
    }

    var params={
        ObjectID: objectId,
        BrowseFlag: browseFlag,
        Filter: (filterParams.length?filterParams.join():"*"),
                          StartingIndex: (typeof(startingIndex)==="number")?startingIndex:0,
                                                                             RequestedCount: (typeof(requestCount)==="number")?requestCount:0,
                                                                                                                              SortCriteria: (sortParams.length?sortParams.join():"*"),
    };

    var deferred=this.soapTransport.sendAction("urn:schemas-upnp-org:service:ContentDirectory:1#Browse", {
                                                   _name: "u:Browse",
                                                   _attrs: attrs,
                                                   _content: params
                                               });

    deferred.then(function onSuccess(response) {
        var soapBody=response.soapBody;

        var ret={
            numberReturned: parseInt(soapBody.byPath("u:BrowseResponse/NumberReturned", CONTENT_DIRECTORY_XMLNS_SET).text(), 10),
            totalMatches: parseInt(soapBody.byPath("u:BrowseResponse/TotalMatches", CONTENT_DIRECTORY_XMLNS_SET).text(), 10),
            updateID: parseInt(soapBody.byPath("u:BrowseResponse/UpdateID", CONTENT_DIRECTORY_XMLNS_SET).text(), 10)
        };

        var result=soapBody.byPath("u:BrowseResponse/Result", CONTENT_DIRECTORY_XMLNS_SET);
        if (result.length) {
            var didl=result.text();

            //console.log("DIDL="+didl);

            var deferred = Xml.parseXml(didl);

            deferred=deferred.then(function(xml) {
                ret.result = xml;

                return ret;
            });

            return deferred;
        }

        // console.log("Parsed response="+Util.inspect(ret, false, {}));

        return Async.Deferred.resolved(ret);
    });

    return deferred;
}
