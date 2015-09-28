.pragma library

.import fbx.async 1.0 as Async
.import fbx.web 1.0 as Web
.import QtQuick.XmlListModel 2.0 as XmlListModel

.import "xml.js" as Xml
.import "jstoxml.js" as JsToXML
.import "util.js" as Util

var LOG_TRANSPORT = false;

var XMLSOAP_XMLNS={
    "": "http://schemas.xmlsoap.org/soap/envelope/"
}

var RESPONSE_SOAP_XMLNS={
    "": "urn:schemas-upnp-org:service-1-0"
}

function SoapTransport(url, xmlParserWorker) {
    this.url = url;
    this.xmlParserWorker=xmlParserWorker;
}

SoapTransport.prototype.sendAction = function(soapAction, xmlBody) {

    var jxml = {
        _name: "s:Envelope",
        _attrs: {
            "xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
            "s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/"
        },
        _content: {
            "s:Body": xmlBody
        }
    };

    var xml = JsToXML.toXML(jxml, { header: true, filter: JsToXML.xmlFilters });

    if (LOG_TRANSPORT) {
        console.log("SOAP url='"+this.url+"' request="+xml);
    }

    var application=Qt.application;

    var transaction = Web.Http.Transaction.factory({
                                                       method: "POST",
                                                       url: this.url,
                                                       headers: {
                                                           "SOAPACTION": "\""+soapAction+"\"",
                                                           "Content-Type": "text/xml; charset=\"utf-8\"",
                                                           "User-Agent": application.name+"/"+application.version+" (QML client; "+application.organization+")"
                                                       },
                                                       body: xml
                                                   });

    var deferred = transaction.send();

    var self=this;
    deferred = deferred.then(function onSuccess(response) {

        if (response.isError() || !response.status) {
            var message = "Response error (status=" + response.status + ")";
            console.error(message);

            return Async.Deferred.rejected(message);
        }

        if (LOG_TRANSPORT){
            console.log("Raw response="+response.body);
        }

        var deferred;
        try {
            if (self.xmlParserWorker) {
                deferred=self.xmlParserWorker.parseXML(response.body, RESPONSE_SOAP_XMLNS);

            } else {
                deferred = Xml.parseXML(response.body, RESPONSE_SOAP_XMLNS);
            }

        } catch (x) {
            var message = "Can not parse document " + x;
            console.exception("Can not parse document",x,x.message,"At "+x.fileName+":"+x.lineNumber);
            return Async.Deferred.rejected(message);
        }

        deferred = deferred.then(function onSuccess(xmlDocument) {
            //console.log("Response XML=", Util.inspect(xmlResponse, false, {}));

            //            console.log("Response XML=", Util.inspect(xml.toObject(), false, {}));

            var soapBody = xmlDocument.byPath("Envelope/Body", XMLSOAP_XMLNS);

            //       console.log("Soapbody=",Util.inspect(soapBody, false, {}));

            if (!soapBody.length) {
                var message="Soapbody is not found !";
                console.exception(new Error(message));
                return Async.Deferred.rejected(message);
            }

            var ret = {
                document: xmlDocument,
                response: response,
                soapBody: soapBody,
                xmlns: xmlDocument.xmlNode().namespaceURIs
            }

            return ret;
        });

        return deferred;
    });

    return deferred;
}

