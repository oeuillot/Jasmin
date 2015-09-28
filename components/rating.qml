import QtQuick 2.0

import "fontawesome.js" as Fontawesome;
import "../jasmin" 1.0

Text {
    id: widget

    property var xml: null;

    onXmlChanged: {
        if (!xml) {
            rating=-1;
            return;
        }

        var r=xml.byPath("upnp:rating", ContentDirectoryService.DIDL_XMLNS_SET).first().text();
        if (!r) {
            rating=-1;
            return;
        }

        rating=parseFloat(r);
    }

    property real rating: 0;

    onRatingChanged: {
        if (rating<0) {
            widget.text="";
            widget.visible=false;
            return;
        }

        var r=rating;
        var txt="";

        for(var i=0;i<5;i++) {
            if (r>=1) {
                txt+=Fontawesome.Icon.star;
                r--;
                continue;
            }
            if (r>=0.5) {
                txt+=Fontawesome.Icon.star_half_full;
                r=0;
                continue;
            }
            txt+=Fontawesome.Icon.star_o;
        }

        //console.log("Rating string="+txt);

        widget.text=txt;
         widget.visible=true;
    }

    color: "#FFCB00"
    font.bold: true
    font.pixelSize: 14
    font.family: Fontawesome.Name
}
