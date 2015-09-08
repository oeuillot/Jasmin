.import "../jasmin/upnpServer.js" as UpnpServer
.import fbx.async 1.0 as Async

.import "../jasmin/util.js" as Util

function fillModel(upnpServer, meta) {

    // console.profile();
    console.log(Util.inspect(meta.result, false, {}));

    var container=meta.result.byPath("DIDL-Lite/container", UpnpServer.DIDL_XMLNS_SET);
    // console.log("Container=",Util.inspect(container));

    var objectID=container.attr("id");
    // console.log("ID="+objectID);

    var childCount=container.attr("childCount");
    console.log("ChildCount="+childCount);


    return { objectID: objectID, childCount: childCount };
}

function loadModel(upnpServer, objectID, position, pageSize, loadArtists) {
    var deferred = new Async.Deferred.Deferred();

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
                     name: "rating",
                     namespaceURI: UpnpServer.UPNP_METADATA_XMLNS

                 }];

    if (loadArtists) {
        filters.push({
                         name: "artist",
                         namespaceURI: UpnpServer.UPNP_METADATA_XMLNS
                     });
    }

    var sorters=[
                {
                    ascending: true,
                    name: "title",
                    namespaceURI: UpnpServer.PURL_ELEMENT_XMLS
                }

            ];


    //    console.log("Request position "+position+" pageSize="+pageSize);

    var d=upnpServer.browseDirectChildren(objectID, {
                                              filters: filters,
                                              startingIndex: position,
                                              requestCount: Math.max(pageSize, 32),
                                              sortCriteria: sorters
                                          });

    d.then(function onSuccess(xml){

        //console.log("Return=",Util.inspect(xml.result));

        var children=xml.result.byPath("DIDL-Lite", UpnpServer.DIDL_XMLNS_SET).children();
        //console.log("Children=",Util.inspect(children));

        //console.log("*** RESOLVE "+children.length);
        deferred.resolve({
                             list: children.toArray(),
                             position: position,
                             pageSize: pageSize
                         });

    }, function onFailure(reason) {

        deferred.reject(reason);
    });

    return deferred;
}
