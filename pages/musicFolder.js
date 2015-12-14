.pragma library

.import fbx.async 1.0 as Async

.import "../jasmin/upnpServer.js" as UpnpServer
.import "../jasmin/util.js" as Util
.import "../jasmin/contentDirectoryService.js" as ContentDirectoryService

var XMLNS={
    dc: ContentDirectoryService.PURL_ELEMENT_XMLS,
    "": ContentDirectoryService.DIDL_LITE_XMLNS,
    "upnp": UpnpServer.UPNP_METADATA_XMLNS
}


function normalizeName(str) {
    var r = [];
    if (!str || !str.length) {
      return r;
    }
    str.split(',').forEach(
        function(tok) {
          tok = tok.replace(/\w\S*/g, function(txt) {
            return txt.charAt(0).toUpperCase() +
                txt.substr(1).toLowerCase();
          });

          r.push(tok.trim());
        });
  return r;
}

function browseTrack(contentDirectoryService, xml) {

    if (xml.byPath("res", ContentDirectoryService.DIDL_XMLNS_SET).count()) {
       return Async.Deferred.resolved(xml);
    }

    var objectID=xml.attr("id");

    return contentDirectoryService.browseMetadata(objectID).then(function(meta) {

        var nodeXml=meta.result.byPath("DIDL-Lite", ContentDirectoryService.DIDL_XMLNS_SET).children();

        console.log("Browse:"+nodeXml.xtoString());
       return nodeXml;
    });
}


function browseTracks(contentDirectoryService, xml, metas) {

  var objectID=xml.attr("id");

  var trackSorters=[
              {
                  ascending: true,
                  name: "originalTrackNumber",
                  namespaceURI: UpnpServer.UPNP_METADATA_XMLNS
              },
              {
                  ascending: true,
                  name: "date",
                  namespaceURI: ContentDirectoryService.PURL_ELEMENT_XMLS
              }


          ];

  // console.log("Request "+objectID);

  var deferred=contentDirectoryService.browseDirectChildren(objectID, {
      sorters: trackSorters,
      requestCount: 256

  }).then(function onSuccess(xml) {

      // console.log(Util.inspect(xml, false, {}));

      var listByDisk={};
      var list=[];

      xml.result.byPath("DIDL-Lite", ContentDirectoryService.DIDL_XMLNS_SET).children().forEach(function(item) {

          // console.log("item=",Util.inspect(item, false, {}));

          var upnpClass=item.byPath("upnp:class", ContentDirectoryService.DIDL_XMLNS_SET).text();
          // console.log("item=",Util.inspect(item, false, {})+" =>
                      // "+upnpClass);
          if (!upnpClass){
              return;
          }

          if (upnpClass.indexOf("object.item.audioItem")!==0) {
              return;
          }

          var infos={ xml: item};

          var title=item.byPath("dc:title", ContentDirectoryService.DIDL_XMLNS_SET).text();
          if (!title) {
              title="Inconnu";
          }
          infos.title=title;

          var trackNumber=item.byPath("upnp:originalTrackNumber", ContentDirectoryService.DIDL_XMLNS_SET).text();
          if (trackNumber) {
              infos.trackNumber = parseInt(trackNumber, 10);

          } else {
              infos.trackNumber = 0;
          }

          var date=item.byPath("dc:date", ContentDirectoryService.DIDL_XMLNS_SET).text();
          if (date) {
              var d=new Date(date);
              infos.date=d.getTime();

              if (metas && !metas.year) {
                  metas.year=d.getFullYear();
              }
          }

          var res=item.byPath("res", ContentDirectoryService.DIDL_XMLNS_SET).first();
          if (!res) {
              return;
          }

          var duration=res.attr("duration");
          if (duration) {
              var r=/([0-9]{1,2}:)([0-9]{1,2}:)([0-9]{1,2})(\.[0-9]{1,3})?/.exec(duration);

              // console.log("r="+Util.inspect(r, false, {}));
              if (r) {
                  var d=0;
                  if (r[1]) {
                      d+=parseInt(r[1],10)*60*60;
                  }
                  if (r[2]) {
                      d+=parseInt(r[2],10)*60;
                  }
                  if (r[3]) {
                      d+=parseInt(r[3], 10);
                  }

                  infos.duration=d;
              }
          }

          var disk=item.byPath("upnp:originalDiscNumber", ContentDirectoryService.DIDL_XMLNS_SET).text();
          if (disk) {
              infos.disk=parseInt(disk, 10);
          } else {
              infos.disk=0;
          }

          if (metas) {
              item.byPath("upnp:artist", ContentDirectoryService.DIDL_XMLNS_SET).forEach(function(ax) {
                 var txt=normalizeName(ax.text());
                  if (!txt) {
                      return;
                  }

                  txt.forEach(function(t) {
                      if (metas.artists.indexOf(t)<0) {
                          metas.artists.push(t);
                      }
                  });
              });


              item.byPath("upnp:genre", ContentDirectoryService.DIDL_XMLNS_SET).forEach(function(ax) {
                 var txt=normalizeName(ax.text());
                  if (!txt.length) {
                      return;
                  }

                  txt.forEach(function(t) {
                      if (metas.genres.indexOf(t)<0) {
                          metas.genres.push(t);
                      }
                  });
              });
          }

          var ds=listByDisk[infos.disk];
          if (!ds){
              ds=[];
              listByDisk[infos.disk]=ds;
              list.push(ds);
          }

          ds.push(infos);
      });

     //console.log("list=",Util.inspect(list));

      list.sort(function(i1, i2) {
          var d1=i1[0].disk || 999999;
          var d2=i2[0].disk || 999999;

          return d1-d2;
      });

      list.forEach(function(ds) {
          //console.log("Disk #"+ds[0].disk+" index="+diskIndex);

          ds.sort(function(i1, i2) {
              var t1=i1.trackNumber || 9999999;
              var t2=i2.trackNumber || 9999999;

              var d=t1-t2;
              if (d!==0) {
                  return d;
              }
              return i1.date-i2.date;
          });
      });

      return list;
  });

  return deferred;
}
