.import QtQuick 2.0 as QtQuick
.import Qt 2.0 as Qt

.import "../jasmin/util.js" as Util
.import "../jasmin/upnpServer.js" as UpnpServer
.import "../jasmin/xml.js" as Xml
.import "fontawesome.js" as Fontawesome

function computeType(upnpClass) {
    if (!upnpClass) {
        return Fontawesome.Icon.question;
    }

    if (upnpClass.indexOf("object.container.album")===0 || upnpClass.indexOf("object.item.audioItem")===0) {
        return Fontawesome.Icon.music;
    }

    if (upnpClass.indexOf("object.item.videoItem")===0) {
        return Fontawesome.Icon.film;
    }

    if (upnpClass.indexOf("object.item.imageItem")===0) {
        return Fontawesome.Icon.file_picture_o;
    }

    if (!upnpClass.indexOf("object.container")) {
        return Fontawesome.Icon.folder_open_o;
    }

    return Fontawesome.Icon.question;
}

function computeImage(xml, upnpClass) {
    if (!upnpClass) {
        return;
    }

    if (upnpClass.indexOf("object.container.album")===0 || upnpClass.indexOf("object.item.audioItem")===0) {
        var res=xml.byTagName("albumArtURI", UpnpServer.UPNP_METADATA_XMLNS).first().text();
        if (!res) {
            return;
        }

        var imageSource=upnpServer.relativeURL(res).toString();
        return imageSource;
    }

    if (upnpClass.indexOf("object.item.videoItem")===0) {
        return;
    }

    var ret=xml.byTagName("res", UpnpServer.DIDL_LITE_XMLNS).forEach(function(res) {

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
            console.error("Unknown protocol : "+protocolInfo);
            return null;
        }

        var ts=/^image\/(.*)/.exec(contentFormat);
        if (!ts) {
            console.log("Invalid content format '"+contentFormat+"'");
            return null;
        }

        var imageType=ts[1];

        if ([ "png", "jpeg", "gif", "bmp", "svg+xml" ].indexOf(imageType)<0) {
            console.log("Invalid image Type '"+imageType+"'");
            return null;
        }

        var url=res.text();

        var imageSource=upnpServer.relativeURL(url).toString();

        //console.log("Return "+imageSource);

        return imageSource;
    });

    return ret;
}

function computeLabel(xml) {
    return xml.byTagName("title", UpnpServer.PURL_ELEMENT_XMLS).text();
}

function computeInfo(xml, upnpClass) {
    //console.log(Util.inspect(xml, false, {}));

    if (upnpClass.indexOf("object.container")>=0) {
        var childCount=xml.attr("childCount");
        if (childCount) {
            var c=parseInt(childCount, 10);
            if (c===0) {
                return "Dossier vide";
            }

            if (c===1) {
                return "Un fichier";
            }

            return c+" fichiers";
        }
    }

    var date=xml.byPath("dc:date", UpnpServer.DIDL_XMLNS_SET).first().text();
    if (date) {
        var jdate=new Date(date);


        if (jdate.getUTCMonth()===0 && jdate.getUTCDate()===1 && jdate.getUTCHours()===0 && jdate.getUTCMinutes()===0 && jdate.getUTCSeconds()===0) {
            return String(jdate.getUTCFullYear());
        }


        return Qt.formatDateTime(jdate, "dd/MM/yyyy hh:mm");
    }

    var artists=xml.byPath("upnp:artist", UpnpServer.DIDL_XMLNS_SET);
    if (artists.count) {
        var ar=artists.first().text();
        if (artists.count()>1) {
            ar+=" (+"+(artists.count()-1)+")";
        }
        return ar;
    }

    console.log("unknown="+Util.inspect(xml, false, {}));
    return null;
}
