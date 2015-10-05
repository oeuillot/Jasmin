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
                }

                var hasDate;

                var birthTime=UpnpObject.getText(xml, "fm:birthTime");
                if (birthTime) {
                    hasDate=true;
                    addLine("Date de création", UpnpObject.dateFormatter(birthTime));
                }

                var modifiedTime=UpnpObject.getText(xml, "fm:modifiedTime");
                if (!modifiedTime) {
                    modifiedTime=UpnpObject.getText(xml, "sec:modificationDate");
                }
                if (modifiedTime) {
                    hasDate=true;
                    addLine("Date de modification", UpnpObject.dateFormatter(modifiedTime));
                }

                if (!hasDate) {
                    var date=UpnpObject.getText(xml, "dc:date");
                    if (date) {
                        addLine("Date", UpnpObject.dateFormatter(date));
                    }
                } else {
                    var year=UpnpObject.getText(xml, "dc:date");
                    if (year) {
                        var syear=UpnpObject.dateYearFormatter(year);
                        if (syear) {
                            addLine("Année", syear);
                        }
                    }
                }

                var size=UpnpObject.getText(xml, "res@size");
                if (size!==undefined) {
                    addLine("Taille", UpnpObject.sizeFormatter(size));
                }

                var childCount=UpnpObject.getText(xml, "@childCount");
                if (childCount!==undefined) {
                    addLine("Nombre de fichiers", String(childCount));
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
