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

                horizontalAlignment: Text.AlignRight
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

        Grid {
            id: grid
            x: 0
            y: titleInfo.y+titleInfo.height;
            columns: 2
            spacing: 6

            Component.onCompleted: {
                //console.log("Xml="+Util.inspect(xml, false, {}));

                var hasDate;

                hasDate=!!UpnpObject.addLine(grid, labelComponent, valueComponent, "Date de création :", xml, "fm:birthTime", UpnpObject.dateFormatter);

                var md=UpnpObject.addLine(grid, labelComponent, valueComponent, "Date de modification :", xml, "fm:modifiedTime", UpnpObject.dateFormatter);
                if (md) {
                    hasDate=true;
                } else {
                    var sd=UpnpObject.addLine(grid, labelComponent, valueComponent, "Date de modification :", xml, "sec:modificationDate", UpnpObject.dateFormatter);
                    if (sd) {
                        hasDate=true;
                    }
                }

                //UpnpObject.addLine(grid, labelComponent, valueComponent, "Date d'accés :", xml, "fm:accessTime", UpnpObject.dateFormatter);
                // UpnpObject.addLine(grid, labelComponent, valueComponent, "Date de changement:", xml, "fm:changeTime", UpnpObject.dateFormatter);

                if (!hasDate){
                    UpnpObject.addLine(grid, labelComponent, valueComponent, "Date :", xml, "dc:date", UpnpObject.dateFormatter);
                }
                UpnpObject.addLine(grid, labelComponent, valueComponent, "Année :", xml, "dc:date", UpnpObject.dateYearFormatter);
                UpnpObject.addLine(grid, labelComponent, valueComponent, "Taille :", xml, "res@size", UpnpObject.sizeFormatter);
                UpnpObject.addLine(grid, labelComponent, valueComponent, "Nombre de fichiers :", xml, "@childCount");
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
