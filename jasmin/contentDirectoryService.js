.pragma library

.import fbx.async 1.0 as Async
.import fbx.web 1.0 as Web

.import "util.js" as Util
.import "xml.js" as Xml
.import "xmlParser.js" as XmlParser
.import "upnpServer.js" as UpnpServer
.import "soapTransport.js" as Soap

var LOG_DIDL=false;

var UPNP_CONTENT_DIRECTORY_1="urn:schemas-upnp-org:service:ContentDirectory:1";

var DIDL_LITE_XMLNS="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/";
var PURL_ELEMENT_XMLS="http://purl.org/dc/elements/1.1/";

var JASMIN_MUSICMETADATA="urn:schemas-jasmin-upnp.net:musicmetadata/";
var JASMIN_FILEMEDATA="urn:schemas-jasmin-upnp.net:filemetadata/";
var JASMIN_MOVIEMETADATA="urn:schemas-jasmin-upnp.net:moviemetadata/";

var SEC_DLNA_XMLNS="http://www.sec.co.kr/dlna";


var MICROSOFT_WMPNSS="urn:schemas-microsoft-com:WMPNSS-1-0/";

var CONTENT_DIRECTORY_XMLNS_SET={
    "": UpnpServer.UPNP_SERVICE_XMLNS,
    "dlna": UpnpServer.DLNA_DEVICE_XMLNS,
    "u": UPNP_CONTENT_DIRECTORY_1,
    "s": UpnpServer.SOAP_ENVELOPE_XMLNS
}

var DIDL_XMLNS_SET = {
    "": DIDL_LITE_XMLNS,
    "upnp": UpnpServer.UPNP_METADATA_XMLNS,
    "sec": SEC_DLNA_XMLNS,
    "dc": PURL_ELEMENT_XMLS,
    "mm": JASMIN_MUSICMETADATA,
    "mo": JASMIN_MOVIEMETADATA,
    "fm": JASMIN_FILEMEDATA
}

var RESPONSE_SOAP_XMLNS={
    "": UpnpServer.UPNP_SERVICE_XMLNS,
    "upnp": UpnpServer.UPNP_METADATA_XMLNS,
    "sec": SEC_DLNA_XMLNS,
    "dc": PURL_ELEMENT_XMLS,
    "mm": JASMIN_MUSICMETADATA,
    "mo": JASMIN_MOVIEMETADATA,
    "fm": JASMIN_FILEMEDATA,
    "microsoft": MICROSOFT_WMPNSS
}

function ContentDirectoryService(upnpServer) {
    this.upnpServer=upnpServer;
}

ContentDirectoryService.prototype.constructor = ContentDirectoryService;


ContentDirectoryService.prototype.connect=function() {

    var self=this;

    var upnpServer=this.upnpServer;

    var deferred0 = upnpServer.connect().then(function onSuccess() {

        var contentDirectoryService=self.getService();
        //console.log("Return contentDirectoryService="+contentDirectoryService);
        if (!contentDirectoryService){
            return Async.Deferred.rejected("No content directory service !");
        }

        var controlURL=upnpServer.relativeURL(contentDirectoryService.controlURL);

        console.log("controlURL=", controlURL);

        var soapTransport=new Soap.SoapTransport(controlURL, upnpServer.xmlParserWorker, RESPONSE_SOAP_XMLNS);
        self.soapTransport=soapTransport;

        var deferred = self.getSortCapabilities().then(function onSuccess(sortCaps) {
            self.sortCaps=sortCaps;
            //console.log("SortCaps="+Util.inspect(sortCaps));

            var deferred2=self.getSearchCapabilities().then(function onSuccess(searchCaps) {
                self.searchCaps=searchCaps;
                // console.log("SearchCaps="+Util.inspect(searchCaps));

                var deferred3=self.getSystemUpdateID().then(function onSuccess(systemUpdateID) {
                    self.systemUpdateID=systemUpdateID;
                    //console.log("SystemUpdateID="+systemUpdateID);

                    var deferred4=self.browseMetadata(0).then(function(meta) {
                        //console.log("Meta="+Util.inspect(meta, false, {}));

                        return {
                            contentDirectoryService: self,
                            sortCaps: sortCaps,
                            searchCaps: searchCaps,
                            systemUpdateID: systemUpdateID,
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
    });

    return deferred0;
}

ContentDirectoryService.prototype.getService=function() {
    this.upnpServer._validServer();

    var service = this.upnpServer.services[UPNP_CONTENT_DIRECTORY_1];
    if (service) {
        return service;
    }

    console.error("Can not find service="+UPNP_CONTENT_DIRECTORY_1+" in list "+Util.inspect(this.upnpServer.services));
    return null;
}


ContentDirectoryService.prototype.getSortCapabilities=function() {
    var deferred=this.soapTransport.sendAction(UPNP_CONTENT_DIRECTORY_1+"#GetSortCapabilities", {
                                                   _name: "u:GetSortCapabilities",
                                                   _attrs: {
                                                       "xmlns:u" : UPNP_CONTENT_DIRECTORY_1
                                                   }
                                               });

    //console.log("Get SortCapabilities ...");

    deferred.then(function onSuccess(response) {
        var sc=response.soapBody.byPath("u:GetSortCapabilitiesResponse/SortCaps", CONTENT_DIRECTORY_XMLNS_SET);
        if (!sc.length) {
            return undefined;
        }

        var ret={};
        var sorts=sc.text().split(',');
        var xmlns=sc.xmlNode().namespaceURIs;

        var sp={};
        sorts.forEach(function(sort) {
            XmlParser.splitName(sort, sp);

            //            console.log("X="+sp.xmlns+" => "+xmlns[sp.xmlns || '']);

            var x=xmlns[sp.xmlns || ""];
            if (!x){
                console.error("Can not find uri associated to prefix '"+sp.xmlns+"'");
                return;
            }

            var key=sp.name+"##"+x;

            ret[key]={xmlns:x, name: sp.name };
        });

        return ret;
    }, function onError(reason) {
        console.error("getSortCapabilities error : "+reason);
    });

    return deferred;
}

ContentDirectoryService.prototype.hasSortCapabilities=function(xmlns, name) {
    if (!this.sortCaps) {
        return null;
    }

    var f=this.sortCaps(name+"##"+xmlns);
    return !!f;
}

ContentDirectoryService.prototype.getSearchCapabilities=function() {
    var deferred=this.soapTransport.sendAction(UPNP_CONTENT_DIRECTORY_1+"#GetSearchCapabilities", {
                                                   _name: "u:GetSearchCapabilities",
                                                   _attrs: {
                                                       "xmlns:u" : UPNP_CONTENT_DIRECTORY_1
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

ContentDirectoryService.prototype.getSystemUpdateID=function() {

    var deferred=this.soapTransport.sendAction(UPNP_CONTENT_DIRECTORY_1+"#GetSystemUpdateID", {
                                                   _name: "u:GetSystemUpdateID",
                                                   _attrs: {
                                                       "xmlns:u" :UPNP_CONTENT_DIRECTORY_1
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


ContentDirectoryService.prototype.browseDirectChildren=function(objectId, options) {
    return this.browse(objectId, "BrowseDirectChildren", options);
}

ContentDirectoryService.prototype.browseMetadata=function(objectId, options) {
    return this.browse(objectId, "BrowseMetadata", options);
}


ContentDirectoryService.prototype.browse=function(objectId, browseFlag, options) {
    // filters, startingIndex, requestedCount, sortCriteria

    options=options || {};

    var xmlns={
    };
    xmlns[PURL_ELEMENT_XMLS]="dc";
    xmlns[UPNP_CONTENT_DIRECTORY_1]="u";
    xmlns[UpnpServer.UPNP_METADATA_XMLNS]="upnp";
    xmlns[MICROSOFT_WMPNSS]="microsoft";
    //    xmlns[DIDL_LITE_XMLNS]="didl"

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
    if (options.filters) {
        options.filters.forEach(function(filter) {
            var name=filter.name;
            var prefix=getPrefix(filter.namespaceURI);

            filterParams.push((prefix?(prefix+":"):"")+name);
        });
    }

    var sortParams=[];
    if (options.sortCriteria) {
        options.sortCriteria.forEach(function(criteria) {
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

    var startingIndex=(typeof(options.startingIndex)==="number")?options.startingIndex:0;
    var requestCount=(typeof(options.requestCount)==="number")?options.requestCount:0;

    var params=[
                { ObjectID: objectId },
                { BrowseFlag: browseFlag },
                { Filter: (filterParams.length?filterParams.join():"*") },
                { StartingIndex: startingIndex },
                { RequestedCount: requestCount },
                { SortCriteria: (sortParams.length?sortParams.join():"") }
            ];

    var self=this;

    var deferred=this.soapTransport.sendAction(UPNP_CONTENT_DIRECTORY_1+"#Browse", {
                                                   _name: "u:Browse",
                                                   _attrs: attrs,
                                                   _content: params
                                               });

    function onSuccess(response) {
        var soapBody=response.soapBody;

        var ret={
            numberReturned: parseInt(soapBody.byPath("u:BrowseResponse/NumberReturned", CONTENT_DIRECTORY_XMLNS_SET).text(), 10),
            totalMatches: parseInt(soapBody.byPath("u:BrowseResponse/TotalMatches", CONTENT_DIRECTORY_XMLNS_SET).text(), 10),
            updateID: parseInt(soapBody.byPath("u:BrowseResponse/UpdateID", CONTENT_DIRECTORY_XMLNS_SET).text(), 10)
        };

        var result=soapBody.byPath("u:BrowseResponse/Result", CONTENT_DIRECTORY_XMLNS_SET);
        if (!result.length) {
            console.error("No result ? ", Util.inspect(soapBody, false, {}));
        } else {
            var didl=result.text();

            if (LOG_DIDL) {
                console.log("DIDL="+didl);

            }

            var xmlDeferred;

            if (self.xmlParserWorker) {
                xmlDeferred=self.xmlParserWorker.parseXML(didl);

            } else {
                xmlDeferred=Xml.parseXML(didl);
            }

            xmlDeferred=xmlDeferred.then(function onSuccess(xml) {
                ret.result = xml;

                return ret;
            }, null, function onProgress(data) {
                //console.log("PDD="+data);
                deferred.progress(data);
            });

            return xmlDeferred;
        }

        // console.log("Parsed response="+Util.inspect(ret, false, {}));

        return Async.Deferred.resolved(ret);
    }

    if (options.deferredXMLParsing) {
        options.deferredXMLParsing=onSuccess;
        return deferred;
    }

    deferred.then(onSuccess);

    return deferred;
}
