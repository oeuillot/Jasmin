import QtQuick 2.2
import "../jasmin" 1.0

import "fontawesome.js" as Fontawesome;

Item {
    id: widget
    width: certificateText.contentWidth+6;
    height: certificateText.height+6;

    property alias bgOpacity: certificateBackground.opacity;

    property var xml;

    onXmlChanged: {
        if (!xml) {
            widget.visible=false;
            return;
        }

        var certificate = xml.byPath("mo:certificate", ContentDirectoryService.DIDL_XMLNS_SET).first().text();

        //console.log("Certificate="+certificate);
        if (!certificate) {
            widget.visible=false;
            return;
        }

        if (certificate==="!") {
            certificateBackground.color="#FF9C32";
            certificateText.font.family=Fontawesome.Name;
            certificate=Fontawesome.Icon.warning;

        } else if (/\+$/.exec(certificate)) {
            certificateBackground.color="#22BB22";

        } else {
            certificateBackground.color="#FF0000";
        }

        certificateText.text=certificate;

        widget.visible=true;
    }

    Rectangle {
        id: certificateBackground
        width: parent.width
        height: parent.height
        opacity: 0.80
        radius: 10;
    }

    Text {
        id: certificateText
        color: "white"
        x: 3
        y: 3
        font.pixelSize: 14;
        font.bold: true
    }
}
