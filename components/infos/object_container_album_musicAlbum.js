.import "../../jasmin/upnpServer.js" as UpnpServer
.import "../../jasmin/util.js" as Util
.import "../../jasmin/contentDirectoryService.js" as ContentDirectoryService
.import "../../pages/musicFolder.js" as MusicFolder


function fillTracks(parent, components, y, contentDirectoryService, xml) {


    var metas = {
        artists: [],
        genres: [],
        year: 0,
    };

    var deferred = MusicFolder.browseTracks(contentDirectoryService, xml, metas).then(function(list) {
        if (!list.length) {
            return;
        }

        metas.tracks=list;

        var comps={};
        metas.comps=comps;

        var rowIndex=0;

        var diskIndex=0;
        list.forEach(function(ds) {
            //console.log("Disk #"+ds[0].disk+" index="+diskIndex);

            if (list.length>1) {
                var cdisc=components.disc.createObject(parent, {
                                                           text: (ds[0].disk)?("Disque "+ds[0].disk):"Autre disque",
                                                       });
                cdisc.y=y;
                y+=cdisc.height;
            }


            function addInfos(infos, index) {
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
                    diskIndex: diskIndex,
                    trackIndex: index,
                    point: (trackNumber?String(trackNumber):"\u25CF"),
                    text: infos.title,
                    duration: duration,
                    xml: infos.xml,
                    objectID: infos.xml.attr("id")
                };

                // console.log(Util.inspect(params, false, {}));

                var row=components.track.createObject(parent, params);

                comps[diskIndex+"/"+index]=row;

                return row;
            }

            var k=Math.floor(ds.length/2+0.5);
            for(var i=0;i<k;i++) {
                var c1=addInfos(ds[i], i);
                c1.x=0;
                c1.y=y;
                var c2=addInfos(ds[i+k], i+k);
                if (c2){
                    c2.x=c1.width+4;
                    c2.y=y;
                }
                y+=24;
            };

            diskIndex++;
        });

        return metas;

    }, function onFailed(reason) {
        console.error("Failed ! ",reason);
    });

    return deferred;
}
