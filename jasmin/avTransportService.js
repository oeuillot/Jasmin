.pragma library

.import "xml.js" as Xml
.import "xmlParser.js" as XmlParser
.import "soapTransport.js" as Soap
.import "jstoxml.js" as JsToXML

function AvTransportService(upnpServer) {
    this.serverURL=serverURL;

    var soapTransport=new Soap.SoapTransport(serverURL, xmlParserWorker);
    this.soapTransport=soapTransport;
}

AvTransportService.prototype.constructor = AvTransportService;

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
            "xmlns:dc": "http://purl.org/dc/elements/1.1/",
            "xmlns:sec": "http://www.sec.co.kr/"
        },

        _content: xml
    }

    var didlXml = JsToXML.toXML(jxml, { header: true, filter: JsToXML.xmlFilters});

    var req=this.soapTransport.sendAction("urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI", {
                                      _name: "u:SetAVTransportURI ",
                                      _attrs: {
                                          "xmlns:u" :"urn:schemas-upnp-org:service:AVTransport:1"
                                      },
                                      _content: {
                                        InstanceID: 0,
                                          CurrentURI: contentURI,
                                          CurrentURIMetaData: didlXml
                                      }
                                    });
    return req;
}


