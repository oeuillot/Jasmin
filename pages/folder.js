.pragma library

.import "../jasmin/upnpServer.js" as UpnpServer
.import "../jasmin/contentDirectoryService.js" as ContentDirectoryService
.import "../jasmin/xml.js" as Xml
.import fbx.async 1.0 as Async

.import "../jasmin/util.js" as Util
.import "musicFolder.js" as MusicFolder

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

    if (options.recentlyAdded) {
        //if (contentDirectoryService.hasSortCapabilities("modificationDate", ContentDirectoryService.SEC_DLNA_XMLNS)) {
        options.filters.push({
                                 name: "modificationDate",
                                 namespaceURI: ContentDirectoryService.SEC_DLNA_XMLNS
                             });
        //}

    }


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
                 },/* {
                     name: "date",
                     namespaceURI: ContentDirectoryService.PURL_ELEMENT_XMLS
                 },*/ {
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

function prepareRecentlyAdded(contentDirectoryService, listView, result, recentDate, recentlyComponent, allComponent) {
    var recentList=[];

    var hasJMD=true; //contentDirectoryService.hasSortCapabilities("modifiedTime", ContentDirectoryService.JASMIN_FILEMEDATA);
    var hasSEC=true; //contentDirectoryService.hasSortCapabilities("modificationDate", ContentDirectoryService.SEC_DLNA_XMLNS);

    for(var i=0;i<result.length;i++) {
        var xml=result[i];

        var date=xml.byPath("sec:modificationDate", ContentDirectoryService.DIDL_XMLNS_SET).text();

        //        console.log("Date="+date);

        if (!date) {
            continue;
        }

        var ds=new Date(date);
        if (ds.getTime()<recentDate.getTime()) {
            continue;
        }

        recentList.push(i);
    }

    //console.log("RecentsList="+recentList.length+" rowIndex="+Math.ceil(recentList.length/listView.viewColumns));

    if (!recentList.length || recentList.length===result.length) {
        listView.redirectedModel=null;
        return;
    }

    listView.headers=[
                { rowIndex: 0,
                    component: listView.createComponentHeader(recentlyComponent, { count: recentList.length} )
                },
                { rowIndex: Math.ceil(recentList.length/listView.viewColumns),
                    component: listView.createComponentHeader(allComponent)
                }
            ];

    listView.redirectedModel=createRedirectedModel(recentList, listView.viewColumns, listView.model);
}

function createRedirectedModel(recentList, viewColumns, model) {
    var emptyCells=recentList.length % viewColumns;
    if (emptyCells>0) {
        emptyCells=viewColumns-emptyCells;
    }

    //console.log("EMPTY CELLS="+emptyCells);
    return {
        get: function(idx) {
            //console.log("Request idx="+idx);
            if (idx<recentList.length) {
                //console.log("Return recentList["+idx+"]=>"+recentList[idx]);
                return recentList[idx];
            }
            idx-=recentList.length;
            if (idx<emptyCells) {
                //console.log("Return emptyCells["+idx+"]=>-1");
                return -1;
            }
            idx-=emptyCells;

            if (idx<model.length) {
                return idx;
            }

            //console.log("Return main index "+idx);

            return -1;
        },
        length: recentList.length+emptyCells+model.length
    };
}

function processSearch(listView, text, searchHeaderComponent) {
    var model=listView.model;

    var result=[];
    var proposals=[];

    var t9=["[1]", "[2ABC]", "[3DEF]", "[4GHU]", "[5JKL]", "[6MNO]", "[7PQRS]", "[8TUV]", "[9WXYZ]", "[0]"]

    if (text) {
        var chars=[];
        for(var i=0;i<text.length;i++) {
            var c=text.charAt(i).toUpperCase();
            for(var j=0;j<t9.length;j++) {
                if (t9[j].indexOf(c)<0) {
                    continue;
                }
                chars.push(t9[j]);
                break;
            }
        }

        var reg=new RegExp("\\b("+chars.join('')+"\\w*)\\b", "i");

        //console.log("Search reg="+reg);

        var dic={};

        for(i=0;i<model.length;i++) {
            var xml=model[i];

            if (xml.$title===undefined) {
                xml.$title=xml.byPath("dc:title", ContentDirectoryService.DIDL_XMLNS_SET).first().text();
            }

            var r=reg.exec(xml.$title);

            //console.log("Search "+xml.$title+" => ",r);

            if (!r) {
                continue;
            }

            result.push(i);

            var t=r[1].toUpperCase();
            if (dic[t]) {
                continue;
            }
            dic[t]=true;

            proposals.push({text: t, index: i});
        }
    }

    proposals.sort(function(m1, m2) {
        var ret=m1.text.length-m2.text.length;
        if (ret) {
            return ret;
        }

        return m1.text-m2.text;
    });


    listView.redirectedModel=createRedirectedModel(result, listView.viewColumns, []);

    return proposals;
}
