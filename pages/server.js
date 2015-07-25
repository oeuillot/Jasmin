.import "../jasmin/upnpServer.js" as Jasmin

function tryURL(url) {

    console.log("Try "+url+" ("+Jasmin+")");

    var server=new Jasmin.UpnpServer(url);

    var deferred = server.tryConnection();

    return deferred;
}

