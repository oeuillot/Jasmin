.import "../jasmin/util.js" as Util
.import "../jasmin/upnpServer.js" as Jasmin
.import "../jasmin/xml.js" as Xml

.import QtQuick 2.0 as QtQuick
.import Qt 2.0 as Qt

function computeImage(xml, upnpClass, image, resImage) {
    if (!upnpClass) {
        return "card/unknown.png";
    }

    if (upnpClass.indexOf("object.container.album")>=0 || upnpClass.indexOf("object.item.audioItem")>=0) {
        return "card/music.png";
    }

    if (upnpClass.indexOf("object.item.videoItem")>=0) {
        return "card/video.png";
    }

    if (upnpClass.indexOf("object.item.imageItem")>=0) {
        //console.log("image=",Util.inspect(xml, false,{}));

        var parent=image.parent;

        var res=xml.byTagName("res", Jasmin.DIDL_LITE_XMLNS).text();

        if (res) {
            var params = {
                 source: res,
            };

            var img=resImage.createObject(parent, params);
//            console.log("image="+img+" "+parent.width);

            img.width=Qt.binding(function() { return parent.width - 2 });
            img.height=Qt.binding(function() { return parent.height - 2 });

            image.width=Qt.binding(function() { return parent.width - 2 });
            image.height=Qt.binding(function() { return parent.height - 2 });

            return "card/transparent.png";
        }

        return "card/image.png";
    }

    if (!upnpClass.indexOf("object.container")) {
        return "card/folder.png";
    }

    return "card/unknown.png";
}

function computeLabel(xml) {
    return xml.byTagName("title", Jasmin.PURL_ELEMENT_XMLS).text();
}

function computeInfo(xml, upnpClass) {
    console.log(Util.inspect(xml, false, {}));

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

    var date=xml.byTagName("date", Jasmin.PURL_ELEMENT_XMLS).text();
    if (date) {
        var jdate=new Date(date);

        return Qt.formatDateTime(jdate, "dd/MM/yyyy hh:mm");
    }

    return "";
}
