.pragma library

.import "../../jasmin/upnpServer.js" as UpnpServer
.import "../../jasmin/util.js" as Util
.import "../../jasmin/contentDirectoryService.js" as ContentDirectoryService

function listResources(contentDirectoryService, xml) {

    var lst=[];

    var resEx=xml.byPath("resEx", ContentDirectoryService.DIDL_XMLNS_SET);

    xml.byPath("res", ContentDirectoryService.DIDL_XMLNS_SET).forEach(function(res) {

        //console.log("Test res "+Util.inspect(xml, false, {}));

        var protocolInfo=res.attr("protocolInfo");
        if (!protocolInfo) {
            console.log("No protocol info: "+Util.inspect(xml, false, {}));
            return;
        }

        var ps=/^([^:]*):([^:]*):([^:]*):(.*)$/.exec(protocolInfo);
        if (!ps) {
            console.log("Invalid format '"+protocolInfo+"'");
            return;
        }

        var protocol=ps[1];
        var network=ps[2];
        var contentFormat=ps[3];
        var additionalInfo=ps[4];

        if (protocol!=="http-get") {
            //console.error("Unknown protocol : "+protocolInfo);
            return;
        }

        var ts=/^video\/(.*)/.exec(contentFormat);
        if (!ts) {
            //console.log("Invalid content format '"+contentFormat+"'");
           //return;
        }

        var url=res.text();

        var imageSource=contentDirectoryService.upnpServer.relativeURL(url).toString();

        var additionalInfos={};
        if (additionalInfo) {
            additionalInfo.split(',').forEach(function(token) {
               var req=/([^=]+)(=.*)/.exec(token);
               if (!req) {
                  return;
               }

               additionalInfos[req[1]]=(req[2] && req[2].slice(1));
            });
        }

        lst.push({
                     type: contentFormat,
                     additionalInfo: additionalInfo,
                     additionalInfos: additionalInfos,
                     source: imageSource
                 });
    });

    return lst;
}
