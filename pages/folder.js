.import "../jasmin/upnpServer.js" as UpnpServer

.import "../jasmin/util.js" as Util

function fillModel(list, upnpServer, meta, timer) {

    //console.profile();
    //console.log(Util.inspect(meta.result, false, {}));

    var container=meta.result.byPath("DIDL-Lite/container", UpnpServer.DIDL_XMLNS_SET);
    //console.log("Container=",Util.inspect(container));

    var objectID=container.attr("id");
    //console.log("ID="+objectID);

    var filters=[{
                     name: "title",
                     namespaceURI: UpnpServer.PURL_ELEMENT_XMLS
                 }, {
                     name: "date",
                     namespaceURI: UpnpServer.PURL_ELEMENT_XMLS
                 }, {
                     name: "res",
                     namespaceURI: UpnpServer.DIDL_LITE_XMLNS
                 }, {
                     name: "albumArtURI",
                     namespaceURI: UpnpServer.UPNP_METADATA_XMLNS
                 }, {
                     name: "artist",
                     namespaceURI: UpnpServer.UPNP_METADATA_XMLNS
                 }

            ];

    var sorters=[
                {
                    ascending: true,
                    name: "title",
                    namespaceURI: UpnpServer.PURL_ELEMENT_XMLS
                }

            ];

    upnpServer.browseDirectChildren(objectID, filters, 0, 99, sorters).then(function onSuccess(xml){

        //console.log(Util.inspect(xml, false, {}));
        //console.profileEnd();

        function newSlot() {
            return {
                item1: null,
                item2: null,
                item3: null,
                item4: null,
                item5: null,
                item6: null,
                item7: null
            }
        }

        var slot=newSlot();
        var slotIdx=1;

        var slots=[];

        var children=xml.result.byPath("DIDL-Lite", UpnpServer.DIDL_XMLNS_SET).children();
       //console.log(Util.inspect(children, false, {}));

        children.forEach(function(item) {

            //console.log("New item #"+slotIdx);

            slot["item"+slotIdx]=item;

            // console.log("Item #"+slotIdx+" ",item.byPath);

            slotIdx++;
            if (slotIdx<=7) {
                return;
            }
            slots.push(slot);
            slot=newSlot();
            slotIdx=1;
        });

        //console.log("End of items "+slotIdx);

        if (slotIdx) {
            slots.push(slot);
        }

        timer.triggered.connect(function() {
            var s=slots.shift();

            list.append(s);

            if (!slots.length) {
                timer.stop();
            }
        });
        timer.start();

    }, function onFailure(reason) {
        console.error("Failure", reason);
    });
}

