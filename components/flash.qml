import QtQuick 2.0

Text {
    id: widget;
    visible: false;

    color: "red";

    property int animSize: 60;

    opacity: 0.8*(1-anim/animSize)

    z: 99999

    property Text target;

    font.bold: target.font.bold;
    font.family: target.font.family;
    font.pixelSize: target.font.pixelSize+anim;

    property int targetX;
    property int targetY;

    x: targetX-contentWidth/2;
    y: targetY-contentHeight/2;
    width: contentWidth
    height: contentHeight

    property real anim: 0;

    NumberAnimation {
        id: animation;
        duration: 300;

        target: widget
        property: "anim"

        onRunningChanged:{
            if (!animation.running) {
               widget.visible=false;
            }
        }
    }


    function flash() {
        visible=true;
        targetX=target.x+target.width/2;
        targetY=target.y+target.height/2;

        for(var p=target.parent;p!==widget.parent;p=p.parent) {
            targetX+=p.x;
            targetY+=p.y;
        }

        text=target.text;

        animation.from= 0;
        animation.to= animSize;

       animation.start();
    }
}

