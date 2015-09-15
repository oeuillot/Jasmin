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

    if (upnpClass.indexOf("object.item.textItem")===0) {
        return Fontawesome.Icon.file_text_o;
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
        var res=xml.byPath("upnp:albumArtURI", UpnpServer.DIDL_XMLNS_SET).first().text();
        if (!res) {
            return;
        }

        // No transparency for albumArtURI
        var imageSource=upnpServer.relativeURL(res).toString();
        return {
            source: imageSource,
            transparent: false
        };
    }

    if (upnpClass.indexOf("object.item.videoItem")===0) {
        // return;
    }

    var ret=xml.byPath("res", UpnpServer.DIDL_XMLNS_SET).forEach(function(res) {

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

        var ts=/^image\/(.*)/.exec(contentFormat);
        if (!ts) {
            //console.log("Invalid content format '"+contentFormat+"'");
            return;
        }

        var imageType=ts[1];

        if ([ "png", "jpeg", "gif", "bmp", "svg+xml" ].indexOf(imageType)<0) {
            console.log("Unkown image Type '"+imageType+"'");
            return;
        }

        var transparent=(['png', 'gif', 'svg+xml'].indexOf(imageType)>=0);

        var url=res.text();

        var imageSource=upnpServer.relativeURL(url).toString();

        return {
            source: imageSource,
            transparent: transparent
        };
    });

    return ret;
}

function computeLabel(xml) {
    if (!xml) {
        return null;
    }

    return xml.byPath("dc:title", UpnpServer.DIDL_XMLNS_SET).first().text();
}

function getRating(xml) {
    if (!xml) {
        return -1;
    }

    var rating=xml.byPath("upnp:rating", UpnpServer.DIDL_XMLNS_SET).first().text();

    if (!rating) {
        // console.log("NO RATING");
        return -1;
    }

    var r= parseFloat(rating);

    //console.log("RATING="+r);

    return r;
}

function computeRatingText(rating) {
    var txt="";
    if (rating<0) {
        return txt;
    }

    for(var i=0;i<5;i++) {
        if (rating>=1) {
            txt+=Fontawesome.Icon.star;
            rating--;
            continue;
        }
        if (rating>=0.5) {
            txt+=Fontawesome.Icon.star_half_full;
            rating=0;
            continue;
        }
        txt+=Fontawesome.Icon.star_o;
    }

    //console.log("Rating string="+txt);

    return txt;
}

function computeInfo(xml, upnpClass, component) {
    //console.log(Util.inspect(xml, false, {}));

    if (!xml) {
        return null;
    }

    if (upnpClass.indexOf("object.item.videoItem")!==0) {
        // Not for movie

        var artists=xml.byPath("upnp:artist", UpnpServer.DIDL_XMLNS_SET);
        if (artists.count) {
            var ar=artists.first().text();
            if (artists.count()>1) {
                ar+=" (+"+(artists.count()-1)+")";
            }
            return ar;
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

    //console.log("No infos for="+Util.inspect(xml, false, {}));
    return null;
}
