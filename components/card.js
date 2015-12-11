.import QtQuick 2.0 as QtQuick
.import Qt 2.0 as Qt

.import "../jasmin/util.js" as Util
.import "../jasmin/upnpServer.js" as UpnpServer
.import "../jasmin/contentDirectoryService.js" as ContentDirectoryService
.import "../jasmin/xml.js" as Xml
.import "../jasmin/xmlParser.js" as XmlParser
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

function computeImage(xml, contentDirectoryService) {

    var l=[];
    var urls={};

    xml.byPath("upnp:albumArtURI", ContentDirectoryService.DIDL_XMLNS_SET).forEach(function(res) {
        var url=contentDirectoryService.upnpServer.relativeURL(res.text());

        if (urls[url]) {
            return;
        }

        urls[url]=true;
        var u={url: url };

        var dlna=res.attr("dlna:profileID");
        if (dlna) {
           if (/^JPEG_/.exec(dlna)) {
                u.transparent=false;

            } else if (/^PNG_/.exec(dlna)) {
                u.transparent=true;
            }
        }

        l.push(u);
    });

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

        var imageSource=contentDirectoryService.upnpServer.relativeURL(url);

        if (urls[imageSource]) {
            return;
        }

        urls[imageSource]=true;

        l.push({
            url: imageSource,
            transparent: transparent
        });
    });

    return l;
}

function computeLabel(xml) {
    if (!xml) {
        return null;
    }

    return xml.byPath("dc:title", ContentDirectoryService.DIDL_XMLNS_SET).first().text();
}

function getRating(xml) {
    if (!xml) {
        return -1;
    }

    var rating=xml.byPath("upnp:rating", ContentDirectoryService.DIDL_XMLNS_SET).first().text();
    if (rating) {
        var r= parseFloat(rating);

        return r;
    }
    rating=undefined;

    xml.byPath("desc", ContentDirectoryService.DIDL_XMLNS_SET).forEach(function(desc) {
        if (rating!==undefined) {
            return;
        }

        if (desc.attr("id")!=="UserRating") {
            return;
        }

        var descContent=XmlParser.parseXML(desc.text(), desc.xmlNode().namespaceURIs);
        if (!descContent) {
            return;
        }

        var $m=Xml.$XML(descContent);
        var r=$m.byPath("microsoft:userRatingInStars", ContentDirectoryService.RESPONSE_SOAP_XMLNS).first().text();
        if (!r) {
            return;
        }

        rating=parseInt(r);
    });

    if (rating===undefined) {
        return -1;
    }

    return rating;
}


function computeInfo(xml, upnpClass, component) {
    //console.log(Util.inspect(xml, false, {}));

    if (!xml) {
        return null;
    }

    if (upnpClass.indexOf("object.item.videoItem")!==0) {
        // Not for movie

        var artists=xml.byPath("upnp:artist", ContentDirectoryService.DIDL_XMLNS_SET);
        if (artists.count) {
            var ar=artists.first().text();
            if (artists.count()>1) {
                ar+=" (+"+(artists.count()-1)+")";
            }
            return ar;
        }
    }

    var date=xml.byPath("dc:date", ContentDirectoryService.DIDL_XMLNS_SET).first().text();
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

function computeCertificate(xml) {
    if (!xml) {
        return null;
    }

    var certificate = xml.byPath("mo:certificate", ContentDirectoryService.DIDL_XMLNS_SET).first().text();
    //console.log("Certificate="+certificate);

    return certificate;
}
