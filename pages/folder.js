.import "../jasmin/upnpServer.js" as UpnpServer
.import "../jasmin/contentDirectoryService.js" as ContentDirectoryService
.import fbx.async 1.0 as Async

.import "../jasmin/util.js" as Util

function getModelInfo(contentDirectoryService, meta) {

    // console.profile();
    //console.log(Util.inspect(meta.result, false, {}));

    var container=meta.result.byPath("DIDL-Lite/container", ContentDirectoryService.DIDL_XMLNS_SET);
    //    console.log("Container=",Util.inspect(container));

    var objectID=container.attr("id");
    //    console.log("ID="+objectID);

    var childCount= -1;
    var cc=container.attr("childCount");
    if (cc) {
        childCount=parseInt(cc, 10);
    }
    //    console.log("ChildCount="+childCount);

    return { objectID: objectID, childCount: childCount };
}

function listModel(contentDirectoryService, objectID, options) {
    var deferred = new Async.Deferred.Deferred();

    options= options || {};

    options.filters=[{
                         name: "title",
                         namespaceURI: ContentDirectoryService.PURL_ELEMENT_XMLS
                     }];

    options.sorters=[
                {
                    ascending: true,
                    name: "title",
                    namespaceURI: ContentDirectoryService.PURL_ELEMENT_XMLS
                }

            ];


    //console.log("listModel: Request position "+position+" pageSize="+pageSize);

    var d=contentDirectoryService.browseDirectChildren(objectID, options);

    d.then(function onSuccess(xml){

        //console.log("Return=",Util.inspect(xml.result));

        var children=xml.result.byPath("DIDL-Lite", ContentDirectoryService.DIDL_XMLNS_SET).children();
        //console.log("Children=",Util.inspect(children));

        //console.log("*** RESOLVE "+children.length);
        deferred.resolve(children.toArray());

    }, function onFailure(reason) {

        deferred.reject(reason);
    });

    return deferred;
}

function loadModel(contentDirectoryService, objectID, position, pageSize, loadArtists) {
    var deferred = new Async.Deferred.Deferred();

    var filters=[{
                     name: "title",
                     namespaceURI: ContentDirectoryService.PURL_ELEMENT_XMLS
                 }, {
                     name: "class",
                     namespaceURI: UpnpServer.UPNP_METADATA_XMLNS
                 }, {
                     name: "date",
                     namespaceURI: ContentDirectoryService.PURL_ELEMENT_XMLS
                 }, {
                     name: "res",
                     namespaceURI: ContentDirectoryService.DIDL_LITE_XMLNS
                 }, {
                     name: "albumArtURI",
                     namespaceURI: UpnpServer.UPNP_METADATA_XMLNS
                 }, {
                     name: "rating",
                     namespaceURI: UpnpServer.UPNP_METADATA_XMLNS

                 }, {
                     name: "userRatingInStars",
                     namespaceURI: ContentDirectoryService.MICROSOFT_WMPNSS

                 }, {
                     name: "certificate",
                     namespaceURI: ContentDirectoryService.JASMIN_MOVIEMETADATA

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
                    namespaceURI: ContentDirectoryService.PURL_ELEMENT_XMLS
                }

            ];


    //console.log("loadModel: Request position "+position+" pageSize="+pageSize);

    var d=contentDirectoryService.browseDirectChildren(objectID, {
                                                           filters: filters,
                                                           startingIndex: position,
                                                           requestCount: Math.max(pageSize, 32),
                                                           sortCriteria: sorters
                                                       });

    d.then(function onSuccess(xml){

        //console.log("Return=",Util.inspect(xml.result));

        var children=xml.result.byPath("DIDL-Lite", ContentDirectoryService.DIDL_XMLNS_SET).children();
        //console.log("Children=",Util.inspect(children));

        //console.log("*** RESOLVE "+children.length);
        deferred.resolve({
                             list: children.toArray(),
                             position: position,
                             pageSize: pageSize,
                             totalMatches: xml.totalMatches
                         });

    }, function onFailure(reason) {

        deferred.reject(reason);
    });

    return deferred;
}
