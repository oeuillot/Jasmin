import QtQuick 2.0


Rectangle {
    id: focusRectangle
    color: "red"
    opacity: 0.4
    radius: 4

    function setPosition(toX, toY) {
        focusAnimation.stop();
        animationX.from=x;
        animationX.to=toX
        animationY.from=y;
        animationY.to=toY
        focusAnimation.start();
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
    }
}
