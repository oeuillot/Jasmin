import QtQuick 2.0


Item {
    id: imageColumn

    property string resImageSource;
    property Item infosColumn;

    visible: !!resImageSource
    clip: true

    width: 256;
    height: Math.max(infosColumn.height+20, 30+256+30)-30;

    Image {
        id: image2
        width: 256
        height: 256
        x: 0
        y: 0

        sourceSize.width: 256
        sourceSize.height: 256

        antialiasing: true
        fillMode: Image.PreserveAspectFit

        source: resImageSource;
        asynchronous: true
    }

    Image {
        x: 0
        y: image2.paintedHeight+Math.floor((256-image2.paintedHeight)/2);
        width: 256
        height: 256

        opacity: 0.25

        smooth: true
        antialiasing: true
        asynchronous: true

        transform: Rotation {
            origin.x: 128;
            origin.y: image2.paintedHeight/2;
            axis { x: 1; y: 0; z: 0 }
            angle: 180 }

        sourceSize.width: 256
        sourceSize.height: 256

        fillMode: Image.PreserveAspectFit
        source: resImageSource
    }
}
