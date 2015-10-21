import QtQuick 2.2
import "../jasmin" 1.0

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

        certificateText.text=certificate;

        if (/\+$/.exec(certificate)) {
            certificateBackground.color="#22BB22";
        }

        widget.visible=true;
    }

    Rectangle {
        id: certificateBackground
        width: parent.width
        height: parent.height
        color: "#FF0000"
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
