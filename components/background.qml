import QtQuick 2.0

Image {
    id: widget

    property string background: ""
    property string logo: ""
    property real logoRatio: 0.8

    asynchronous: true
    anchors.fill: parent
    smooth: true
    source: widget.background ? ("background/" + widget.background) : ""

    Image {
        id: logo
        visible: widget.logo != ""
        anchors.fill: parent
        smooth: true
        asynchronous: true
        source: widget.logo ? "background/" + widget.logo : ""
    }

    NumberAnimation {
        id: logoHide
        target: logo
        property: "opacity"
        duration: 2000
        from: 1;
        to: 0;
    }


    function hideLogo() {
        logoHide.start();
    }
}
