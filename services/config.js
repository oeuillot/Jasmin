.pragma library

function getServiceHost(path) {
    var url=Qt.resolvedUrl(path);

//    if (/^file\:/.exec(url)) {
//        url="http://192.168.3.34:5000"+path;
//        url="http://192.168.4.14:5000"+path;
//    url="http://192.168.0.58:5000"+path;
//    url="http://192.168.3.193:5000"+path;
//    }

    return url;
}

function fillHeader(headers) {
    headers=headers || {};

    var application=Qt.application;
    headers["X-User-Agent"]=application.name+"/"+application.version+" (QML client; "+application.organization+")"

    return headers;
}
