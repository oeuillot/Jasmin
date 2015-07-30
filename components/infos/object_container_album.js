.import "../../jasmin/upnpServer.js" as UpnpServer
.import "../../jasmin/util.js" as Util

var XMLNS={
    dc: UpnpServer.PURL_ELEMENT_XMLS,
    "": UpnpServer.DIDL_LITE_XMLNS,
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


function fillTracks(parent, components, y, upnpServer, xml) {

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
                    namespaceURI: UpnpServer.PURL_ELEMENT_XMLS
                },


            ];

    console.log("Request "+objectID);

    var deferred=upnpServer.browseDirectChildren(objectID, null, 0, 256, trackSorters).then(function onSuccess(xml) {

        console.log(Util.inspect(xml, false, {}));

        var listByDisk={};
        var list=[];

        var metas = {
            artists: [],
            genres: [],
            year: 0
        };

        xml.result.byPath("DIDL-Lite", UpnpServer.DIDL_XMLNS_SET).children().forEach(function(item) {

            console.log("item=",Util.inspect(item, false, {}));

            var upnpClass=item.byPath("upnp:class", UpnpServer.DIDL_XMLNS_SET).text();
            //console.log("item=",Util.inspect(item, false, {})+" => "+upnpClass);
            if (!upnpClass){
                return;
            }

            if (upnpClass.indexOf("object.item.audioItem")!==0) {
                return;
            }

            var infos={ xml: item};

            var title=item.byPath("dc:title", UpnpServer.DIDL_XMLNS_SET).text();
            if (!title) {
                title="Inconnu";
            }
            infos.title=title;

            var trackNumber=item.byPath("upnp:originalTrackNumber", UpnpServer.DIDL_XMLNS_SET).text();
            if (trackNumber) {
                infos.trackNumber = parseInt(trackNumber, 10);

            } else {
                infos.trackNumber = 0;
            }

            var date=item.byPath("dc:date", UpnpServer.DIDL_XMLNS_SET).text();
            if (date) {
                var d=new Date(date);
                infos.date=d.getTime();

                if (!metas.year) {
                    metas.year=d.getFullYear();
                }
            }

            var res=item.byPath("res", UpnpServer.DIDL_XMLNS_SET).first();
            if (!res) {
                return;
            }

            var duration=res.attr("duration");
            if (duration) {
                var r=/([0-9]{1,2}:)([0-9]{1,2}:)([0-9]{1,2})(\.[0-9]{1,3})?/.exec(duration);

                //                    console.log("r="+Util.inspect(r, false, {}));
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

            var disk=item.byPath("mm:diskNo", UpnpServer.DIDL_XMLNS_SET).text();
            if (disk) {
                infos.disk=parseInt(disk, 10);
            } else {
                infos.disk=0;
            }

            item.byPath("upnp:artist", UpnpServer.DIDL_XMLNS_SET).forEach(function(ax) {
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

            item.byPath("upnp:genre", UpnpServer.DIDL_XMLNS_SET).forEach(function(ax) {
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

            var ds=listByDisk[infos.disk];
            if (!ds){
                ds=[];
                listByDisk[infos.disk]=ds;
                list.push(ds);
            }

            ds.push(infos);
        });

        //console.log("list=",Util.inspect(list, false, {}));

        if (!list.length) {
            return;
        }

        list.sort(function(i1, i2) {
            var d1=i1.disk || 9999999;
            var d2=i2.disk || 9999999;

            return d1.disk-d2.disk;
        });


        var rowIndex=0;

        list.forEach(function(ds) {
            ds.sort(function(i1, i2) {
                var t1=i1.trackNumber || 9999999;
                var t2=i2.trackNumber || 9999999;

                var d=t1-t2;
                if (d!==0) {
                    return d;
                }
                return i1.date-i2.date;
            });

            if (list.length>1) {
                var cdisc=components.disc.createObject(parent, {
                                                           text: (ds[0].disk)?("Disque "+ds[0].disk):"Autre disque",

                                                       });
                cdisc.y=y;
                y+=cdisc.height;
            }

            var grid=components.grid.createObject(parent, {
                                                      visible: true
                                                  });
            grid.y=y;

            function addInfos(infos) {
                if (!infos) {
                    return;
                }

                var trackNumber=infos.trackNumber;

                var duration="";
                var d=infos.duration;
                if (d) {
                    var h=Math.floor(d/3600);
                    var m=Math.floor(d/60) % 60;
                    var s=d % 60;

                    duration=((m<10)?'0':'')+m+':'+((s<10)?'0':'')+s;
                    if (h) {
                        duration=((h<10)?'0':'')+h+':'+duration;
                    }
                }

                var params={
                    type: "row",
                    point: (trackNumber?String(trackNumber):"\u25CF"),
                    text: infos.title,
                    duration: duration,
                    xml: infos.xml
                };

                console.log(Util.inspect(params, false, {}));

                var row=components.track.createObject(grid, params);

                return row;
            }

            var yh=0;
            var k=Math.floor(ds.length/2+0.5);
            for(var i=0;i<k;i++) {
                var c1=addInfos(ds[i]);
                c1.x=0;
                c1.y=yh;
                var c2=addInfos(ds[i+k]);
                if (c2){
                    c2.x=400;
                    c2.y=yh;
                }

                yh+=24;
            };

            grid.height=yh;
            y+=yh;
        });

        return metas;

    }, function onFailed(reason) {
        console.error("Failed ! ",reason);
    });

    return deferred;
}
