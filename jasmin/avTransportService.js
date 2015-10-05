.pragma library

.import "util.js" as Util
.import "xml.js" as Xml
.import "xmlParser.js" as XmlParser
.import "soapTransport.js" as Soap
.import "jstoxml.js" as JsToXML
.import "contentDirectoryService.js" as ContentDirectoryService
.import "upnpServer.js" as UpnpServer

var UPNP_AV_TRANSPORT_1= "urn:schemas-upnp-org:service:AVTransport:1";

function AvTransportService(upnpServer) {
    this.upnpServer=upnpServer;
}

AvTransportService.prototype.constructor = AvTransportService;


AvTransportService.prototype.getService=function() {
    this.upnpServer._validServer();

    //console.log("services"+Util.inspect(this.upnpServer.services));

    return this.upnpServer.services[UPNP_AV_TRANSPORT_1];
}

AvTransportService.prototype.connect=function() {

    var self=this;

    var upnpServer=this.upnpServer;

    var deferred0 = upnpServer.connect().then(function onSuccess() {

        var avTransportService=self.getService();
        if (!avTransportService){
            return Async.Deferred.rejected("No av transport service !");
        }

        var controlURL=upnpServer.relativeURL(avTransportService.controlURL);

        //console.log("controlURL=", controlURL);

        var soapTransport=new Soap.SoapTransport(controlURL.toString(), upnpServer.xmlParserWorker);
        self.soapTransport=soapTransport;

        return {
            avTransportService: self
        };
    });

    return deferred0;
};


var XMLNS={
    dc: ContentDirectoryService.PURL_ELEMENT_XMLS,
    upnp: UpnpServer.UPNP_METADATA_XMLNS,
    "": ContentDirectoryService.DIDL_LITE_XMLNS
}

AvTransportService.prototype.sendSetAvTransportURI= function(contentURI, xml) {


    /*
    <DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sec="http://www.sec.co.kr/">
    <item id="f-0" parentID="0" restricted="0">
        <dc:title>Video</dc:title>
        <dc:creator>Anonymous</dc:creator>
        <upnp:class>object.item.videoItem</upnp:class>
        <res protocolInfo="http-get:*:video/mp4:DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000">{0}</res>
    </item>
    </DIDL-Lite>
    */

    var jxml= {
        _name: "DIDL-Lite",
        _attrs: {
            xmlns: "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/",
            "xmlns:upnp": "urn:schemas-upnp-org:metadata-1-0/upnp/",
            "xmlns:dc": "http://purl.org/dc/elements/1.1/"
        },

        _content: [
            {
                _name: "item",
                _attrs: {
                    id: xml.attr("id"),
                    parentID: xml.attr("parentID"),
                },
                _content: [
                    {
                        _name: "dc:title",
                        _content: xml.byPath("dc:title", XMLNS).text()
                    }, {
                        _name: "upnp:class",
                        _content: xml.byPath("upnp:class", XMLNS).text()
                    }
                ]
            }]
    };


    var didlXml = JsToXML.toXML(jxml, { header: true, filter: JsToXML.xmlFilters});

    console.log("didlXml="+didlXml);

    //didXml="<DIDL-Lite></DIDL-Lite>"

    var req=this.soapTransport.sendAction(UPNP_AV_TRANSPORT_1+"#SetAVTransportURI", {
                                              _name: "u:SetAVTransportURI ",
                                              _attrs: {
                                                  "xmlns:u" : UPNP_AV_TRANSPORT_1
                                              },
                                              _content: {
                                                  InstanceID: 0,
                                                  CurrentURI: contentURI,
                                                  CurrentURIMetaData: didlXml
                                              }
                                          });
    return req;
}


AvTransportService.prototype.sendPlay= function(instanceId, speed) {

    var req=this.soapTransport.sendAction(UPNP_AV_TRANSPORT_1+"#Play", {
                                              _name: "u:Play",
                                              _attrs: {
                                                  "xmlns:u" : UPNP_AV_TRANSPORT_1
                                              },
                                              _content: {
                                                  InstanceID: (instanceId!==undefined)?instanceId:0,
                                                                                        Speed: (speed!==undefined)?speed:1
                                              }
                                          });
    return req;
}

AvTransportService.prototype.sendStop= function(instanceId) {

    var req=this.soapTransport.sendAction(UPNP_AV_TRANSPORT_1+"#Stop", {
                                              _name: "u:Stop",
                                              _attrs: {
                                                  "xmlns:u" : UPNP_AV_TRANSPORT_1
                                              },
                                              _content: {
                                                  InstanceID: (instanceId!==undefined)?instanceId:0,
                                                                                        Speed: 1
                                              }
                                          });
    return req;
}


