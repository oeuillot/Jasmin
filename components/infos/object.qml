import QtQuick 2.2
import QtGraphicalEffects 1.0
import "../../jasmin" 1.0
import ".." 1.0

import "object.js" as UpnpObject

FocusInfo {
    id: row   
    heightRef: imageColumn;

    Item {
        id: infosColumn

        x: 30
        y: 20
        width: parent.width-((row.imagesList && row.imagesList.length)?(256+20):0)-60
        height: childrenRect.height+20


        Component {
            id: labelComponent

            Text {
                id: title
                font.bold: false
                font.pixelSize: 14
                color: "#666666"

                horizontalAlignment: Text.AlignLeft
            }
        }

        Component {
            id: valueComponent

            Text {
                id: value
                font.bold: true
                font.pixelSize: 14
            }
        }

        TitleInfo {
            id: titleInfo
            x: 0
            y: 0
            width: parent.width;
            title: UpnpObject.getText(xml, "dc:title");
        }

        Item {
            id: grid
            x: 0
            y: titleInfo.y+titleInfo.height;
            width: parent.width

            Component.onCompleted: {
                //console.log("Xml="+Util.inspect(xml, false, {}));


                var y=0;
                var lines=0;

                function addLine(label, value, lc, vc) {
                    var lab=(lc || labelComponent).createObject(grid, {
                                                                    text: label,
                                                                    x: 0,
                                                                    y: y,
                                                                    width: 120
                                                                });
                    var val=(vc || valueComponent).createObject(grid, {
                                                                    text: value,
                                                                    x: 140,
                                                                    y: y,
                                                                    width: grid.width-140-8
                                                                });

                    y+=val.height+8;
                    lines++;
                }

                UpnpObject.addDatesLine(xml, addLine);

                var childCount=UpnpObject.getText(xml, "@childCount");
                if (childCount) {
                    addLine("Nombre de fichiers", childCount);
                }

                grid.height=y+8;
            }
        }
    }

    ImageColumn {
        id: imageColumn
        imagesList: row.imagesList
        infosColumn: infosColumn
        showReversedImage: false
    }

}
