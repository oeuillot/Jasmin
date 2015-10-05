import QtQuick 2.2

FocusScope {
    id: focusScope
    x: row.x
    y: row.y
    height: row.height
    width: parent.width

    property var contentDirectoryService;
    property var xml;
    property var imagesList;
    property string objectID;

    default property alias contents: row.children

    property var currentFocus;

    property Item heightRef;

    Item {
        id: row
        height: (heightRef?(heightRef.y+heightRef.height):childrenRect.height);
        width: parent.width

        Rectangle {
            id: focusRectangle
            color: "red"
            opacity: 0.4
            x: 0
            y: 0
            width: 0
            height: 0
            radius: 4
            visible: false
        }

        ParallelAnimation {

            id: focusAnimation

            NumberAnimation {
                id: animationX
                target: focusRectangle
                properties: "x"
                duration: 100
                from: 0
                to: 0
            }

            NumberAnimation {
                id: animationY
                target: focusRectangle
                properties: "y"
                duration: 100
                from: 0
                to: 0
            }

            NumberAnimation {
                id: animationWidth
                target: focusRectangle
                properties: "width"
                duration: 100
                from: 0
                to: 0
            }

            NumberAnimation {
                id: animationHeight
                target: focusRectangle
                properties: "height"
                duration: 100
                from: 0
                to: 0
            }
        }

        Component.onCompleted: {
            //focusScope.forceActiveFocus();
        }
    }

    function updateFocusPosition() {
        var comp=currentFocus;
        if (!comp) {
            return;
        }

        var x=comp.x-2;
        var y=comp.y-2;

        for(var p=comp.parent;p!==row;p=p.parent) {
            x+=p.x;
            y+=p.y;
        }

        if (x<0) {
            return;
        }

        focusAnimation.stop();
        focusRectangle.x=x;
        focusRectangle.y=y;
        focusRectangle.width=comp.width+4;
        focusRectangle.height=comp.height+4;
        focusRectangle.visible=true;
        animationX.to=focusRectangle.x;
        animationY.to=focusRectangle.y;
        animationWidth.to=focusRectangle.width;
        animationHeight.to=focusRectangle.height;
    }

    function showFocus(comp, activeFocus) {
        //console.log("Comp="+comp+" activeFocus="+activeFocus);
        if (!comp || (!activeFocus && comp===currentFocus)) {
            focusRectangle.visible=false;
            return;
        }

        if (!activeFocus) {
            return;
        }

        for(var p=comp.parent;p;p=p.parent) {
            if (p.objectName!=="net.jasmin.Grid") {
                continue;
            }

            p.scrollIntoView(comp);
            break;
        }

        var x=comp.x-2;
        var y=comp.y-2;

        for(var p=comp.parent;p!==row;p=p.parent) {
            x+=p.x;
            y+=p.y;
        }

        if (!currentFocus) {
            focusRectangle.x=x;
            focusRectangle.y=y;
            focusRectangle.width=comp.width+4;
            focusRectangle.height=comp.height+4;
            focusRectangle.visible=true;
            animationX.to=focusRectangle.x;
            animationY.to=focusRectangle.y;
            animationWidth.to=focusRectangle.width;
            animationHeight.to=focusRectangle.height;
            currentFocus=comp;
            return;
        }

        focusAnimation.stop();
        animationX.from=animationX.to;
        animationX.to=x;
        animationY.from=animationY.to;
        animationY.to=y;
        animationWidth.from=animationWidth.to;
        animationWidth.to=comp.width+4;
        animationHeight.from=animationHeight.to;
        animationHeight.to=comp.height+4;
        focusRectangle.visible=true;
        focusAnimation.start();

        currentFocus=comp;
    }
}
