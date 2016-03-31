import QtQuick 2.0

import "card.js" as CardScript
import "../jasmin" 1.0
import "../resources/genres" 1.0

import "fontawesome.js" as Fontawesome;


FocusScope {
    id: card

    x: rectangle.x;
    y: rectangle.y
    width: rectangle.width;
    height: rectangle.height

    property var model;

    property alias resImageSource: imageItem.source;

    property var imagesList: undefined;

    property var contentDirectoryService;

    property alias title: label.text;

    property bool selected: false;

    property alias transparentImage: bgImage.visible;

    property real selectedScale: 10;

    property string upnpClass;

    property bool hideInfo: false;

    property string infoType: "";

    property Item certificateItem;

    onSelectedChanged: {
        //console.log("Selected changed "+selected);
        if (selectedAnimation.running) {
            selectedAnimation.stop();
        }

        selectedAnimation.to=(selected?2:10);
        selectedAnimation.start();
    }

    PropertyAnimation {
        id: selectedAnimation;
        target: card;
        property: "selectedScale";
        duration: 150
    }

    onModelChanged: {
        //console.log("Model changed="+Util.inspect(model, false, {}));

        selectedScale=10;
        resImageSource="";
        transparentImage=false;
        imagesList=null;
        if (certificateItem) {
            certificateItem.visible=false;
        }

        if (!model) {
            upnpClass="";
            label.text="";
            card.infoType="";
            itemType.text=CardScript.computeType(null);
            itemType.visible=true;
            return;
        }

        upnpClass=model.byPath("upnp:class", ContentDirectoryService.DIDL_XMLNS_SET).text() || "object.item";

        // console.log("upnpclass="+upnpClass);
        itemType.text= CardScript.computeType(upnpClass);
        itemType.visible=true;

        label.font.pixelSize=16;
        info.font.pixelSize=14;
        title=CardScript.computeLabel(model, upnpClass) || "";

        var ratingV=CardScript.getRating(model);
        rating.rating=ratingV;
        //console.log("Rating="+ratingV);

        if (ratingV < 0) {
            info.text=CardScript.computeInfo(model, upnpClass) || "";
            card.infoType="description";

        } else {
            card.infoType="rating";
        }
    }

    function delayedUpdateModel() {
        var imagesList=getImagesList();

        if (imagesList && imagesList.length) {
            var ps=CardScript.filterByType(imagesList, "poster");
            if (ps.length) {
                imagesList=ps;
            }

            ps=CardScript.filterByWidth(imagesList, 160);
            if (ps.length) {
                imagesList=ps;
            }

            resImageSource=imagesList[0].url;
            transparentImage=imagesList[0].transparent || false;

            if (transparentImage) {
                bgImage.source="card/transparent.png";
            }
        }

        var certificate=CardScript.computeCertificate(model);
        if (certificate) {
            if (!certificateItem) {
                certificateItem=certificateComponent.createObject(card);
            }

            certificateItem.xml=model;
        }
    }

    function getImagesList() {
        if (card.imagesList!==null) {
            return card.imagesList;
        }

        if (!upnpClass) {
            card.imagesList=false;
            return false;
        }

        var imagesList;

        if (!upnpClass.indexOf("object.container.genre.musicGenre")) {
            var imageURL=GenreImageRepository.getGenreImageURL(title);
            if (imageURL) {
                imagesList=[{ url: imageURL }];
            }
        }


        if (!imagesList) {
            imagesList=CardScript.computeImage(model, contentDirectoryService);
            //console.log("ImagesList="+imagesList);
        }

        card.imagesList=imagesList || false;

        return card.imagesList;
    }


    Item {
        id: rectangle
        width: 154
        height: 190

        focus: true

        Rectangle {
            id: rectImage
            x: selectedScale
            y: selectedScale
            width: parent.width-selectedScale*2
            height: parent.width-selectedScale*2
            border.color: "#D3D3D3"
            border.width: 1
            color: "#E9E9E9"

            Text {
                id: itemType
                x: 1
                y: 1
                width: parent.width-2
                height: parent.height-2

                opacity: 0.4
                font.pixelSize: 92+(4-Math.floor((selectedScale-2)/2));
                font.family: Fontawesome.Name
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Image {
                id: bgImage
                x: 1
                y: 1
                width: parent.width-2
                height: parent.height-2

                visible: transparentImage
                smooth: true
                antialiasing: true
                asynchronous: true
                fillMode: Image.PreserveAspectFit

                sourceSize.width: 256
                sourceSize.height: 256

                source: ""
            }

            Image {
                id: imageItem
                x: 1
                y: 1
                width: parent.width-2
                height: parent.height-2

                visible: (source!="")

                smooth: true
                antialiasing: true
                asynchronous: true
                fillMode: Image.PreserveAspectFit

                sourceSize.width: 256
                sourceSize.height: 256

                onStatusChanged: {
                    if (status===Image.Ready) {
                        itemType.visible=false;
                    }
                }
            }
        }

        Text {
            id: label
            y: rectImage.y+rectImage.height
            x: selectedScale
            width: parent.width-x;
            color: "#404040"
            elide: Text.ElideMiddle
            font.bold: true
            font.pixelSize: 16

            onContentWidthChanged: {
                if (label.contentWidth>parent.width-x && font.pixelSize>12) {
                    font.pixelSize--;
                }
            }
        }
    }

    Text {
        id: info
        visible: (infoType==="description") && !hideInfo
        y: label.y+label.height
        x: selectedScale
        width: parent.width-x;
        color: "#8A8A92"
        elide: Text.ElideMiddle
        font.bold: true
        font.pixelSize: 14

        onContentWidthChanged: {
            if (info.contentWidth>parent.width-x && font.pixelSize>12) {
                font.pixelSize--;
            }
        }
    }

    Rating {
        id: rating
        visible:  (infoType==="rating") && !hideInfo;
        y: label.y+label.height
        x: selectedScale
    }
    Component {
        id: certificateComponent

        Certificate {
            id: certificate
            x: parent.width-certificate.width-4-8-selectedScale;
            y: selectedScale+4;
            bgOpacity: 0.8
            xml: card.xml
        }
    }
}
