.import "../../jasmin/upnpServer.js" as UpnpServer

var XMLNS={
    dc: UpnpServer.PURL_ELEMENT_XMLS,
    "": UpnpServer.DIDL_LITE_XMLNS
}


function getText(xml, path, xmlns) {
    if (!xml) {
        return;
    }

    var text=xml.byPath(path, xmlns || XMLNS).text();

    return text;
}

function addLine(grid, labelTitle, valueTitle, title, xml, path, formatter) {
    if (!xml) {
        return;
    }

    var reg=/^([^@]*)(@.*)?$/i.exec(path);
    //console.log("reg=",reg);
    var value=xml;
    if (reg[1]) {
        value=xml.byPath(reg[1], XMLNS).first();
    }
    if (!reg[2]) {
        value=value.text();
    } else {
        value=value.attr(reg[2].slice(1));
    }

    if (!value) {
        return;
    }

    if (formatter) {
        value=formatter(value);
    }

    if (!value) {
        return;
    }

    labelTitle.createObject(grid, {
                                text: title
                            });

    valueTitle.createObject(grid, {
                                text: value
                            });

}

function dateYearFormatter(stringDate) {
    var date=new Date(stringDate);

    if (date.getUTCMonth()===0 && date.getUTCDate()===1 && date.getUTCHours()===0 && date.getUTCMinutes()===0 && date.getUTCSeconds()===0) {
        return String(date.getUTCFullYear());
    }

    return null;
}

function dateFormatter(stringDate) {
    var date=new Date(stringDate);

    if (date.getUTCMonth()===0 && date.getUTCDate()===1 && date.getUTCHours()===0 && date.getUTCMinutes()===0 && date.getUTCSeconds()===0) {
        return null;
    }

    return  Qt.formatDateTime(date, "dddd dd MMMM yyyy hh:mm:ss")
}
function sizeFormatter(stringSize) {
    var size=parseFloat(stringSize);

    return humanFileSize(size, 1024);
}

function humanFileSize(bytes, thresh) {
    if (Math.abs(bytes) < thresh) {
        return bytes + ' octets';
    }
    var units = ['ko','mo','go', 'to']
    var u = -1;
    do {
        bytes /= thresh;
        ++u;
    } while(Math.abs(bytes) >= thresh && u < units.length - 1);
    return bytes.toFixed(1)+' '+units[u];
}
