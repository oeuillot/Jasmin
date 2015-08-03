.import "../jasmin/upnpServer.js" as UpnpServer

.import "../jasmin/util.js" as Util

function fillModel(upnpServer, meta) {

    //console.profile();
    //console.log(Util.inspect(meta.result, false, {}));

    var container=meta.result.byPath("DIDL-Lite/container", UpnpServer.DIDL_XMLNS_SET);
    //console.log("Container=",Util.inspect(container));

    var objectID=container.attr("id");
    //console.log("ID="+objectID);

    var filters=[{
                     name: "title",
                     namespaceURI: UpnpServer.PURL_ELEMENT_XMLS
                 }, {
                     name: "date",
                     namespaceURI: UpnpServer.PURL_ELEMENT_XMLS
                 }, {
                     name: "res",
                     namespaceURI: UpnpServer.DIDL_LITE_XMLNS
                 }, {
                     name: "albumArtURI",
                     namespaceURI: UpnpServer.UPNP_METADATA_XMLNS
                 }, {
                     name: "artist",
                     namespaceURI: UpnpServer.UPNP_METADATA_XMLNS
                 }

            ];

    var sorters=[
                {
                    ascending: true,
                    name: "title",
                    namespaceURI: UpnpServer.PURL_ELEMENT_XMLS
                }

            ];

    var deferred = upnpServer.browseDirectChildren(objectID, filters, 0, 99, sorters).then(function onSuccess(xml){

        var children=xml.result.byPath("DIDL-Lite", UpnpServer.DIDL_XMLNS_SET).children();
       //console.log(Util.inspect(children, false, {}));

        return children.toArray();

    }, function onFailure(reason) {
        console.error("Failure", reason);
    });

    return deferred;
}

