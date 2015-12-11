.import "../../jasmin/upnpServer.js" as UpnpServer
.import "../../jasmin/contentDirectoryService.js" as ContentDirectoryService

var XMLNS=ContentDirectoryService.DIDL_XMLNS_SET;

function getText(xml, path, xmlns, separator, role) {
    var ls=getTextList(xml, path, xmlns, role);
    if (!ls || !ls.length) {
        return null;
    }

    return ls.join(separator || ", ");
}


function getTextList(xml, path, xmlns, role) {
    if (!xml) {
        return;
    }

    var reg=/^([^@]*)(@.*)?$/i.exec(path);
    //console.log("reg=",reg);
    var value=xml;
    if (reg[1]) {
        value=xml.byPath(reg[1], xmlns || XMLNS);

        if (!value) {
            return;
        }
    }
    if (reg[2]) {
        var vs=[];
        var attName=reg[2].slice(1);
        value.forEach(function(x) {
           var av=x.attr(attName);
            if (role && role!==av) {
                return;
            }
            vs.push(x);
        });
        value=vs;
    }

    var ls=[];
    value.forEach(function(x) {
        var txt=x.text();
        if (!txt) {
            return;
        }

        ls.push(txt);
    });

    if (!ls.length) {
        return null;
    }

    return ls;
}

function addLine2(grid, labelComponent, valueComponent, labelText, valueText) {

    labelComponent.createObject(grid, {
                                    text: labelText
                                });

    valueComponent.createObject(grid, {
                                    text: valueText
                                });
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

    addLine2(grid, labelTitle, valueTitle, title, value);

    return true;
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
    var size=Math.floor(parseFloat(stringSize));

    if (size<2) {
        return size+" octet";
    }

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
