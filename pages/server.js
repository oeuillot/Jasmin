.import "../jasmin/upnpServer.js" as UpnpServer

function tryURL(url) {

    console.log("Try "+url+" ...");

    var server=new UpnpServer.UpnpServer(url);

    var deferred = server.tryConnection();

    return deferred;
}

