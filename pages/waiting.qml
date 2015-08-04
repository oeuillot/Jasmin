import QtQuick 2.4
import "../components" 1.0

import "../jasmin" 1.0

Item {
    id: waiting

    property XmlParserWorker xmlParserWorker;

    width: 300
    height: 40
    opacity: 0

    Rectangle {
        color: "white";
        x: 0
        y: 0
        width: parent.width
        height: parent.height
        opacity: 0.6
        border.color: "#417F00"
        border.width: 3
        radius: 5
    }

    Text {
        color: "#417F00"
        font.bold: true
        text: "Analyse en cours "+Math.floor(xmlParserWorker.progress*100)+" %"
        width: parent.width;
        height: parent.height

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }


    states: [
        State {
            name: ""
            when: !xmlParserWorker.workersCount
            PropertyChanges {
                target: waiting
                x: -40
                opacity: 0
            }
        },
        State {
            name: "show"
            when: xmlParserWorker.workersCount>0
            PropertyChanges {
                target: waiting
                x: 100
                opacity: 1
            }
        }
    ]

    transitions: [
        Transition {
            to:"show"
            reversible: true
            NumberAnimation { properties: "x"; duration:800; easing.type: Easing.OutCubic}
            NumberAnimation { properties: "opacity"; duration: 800 }
        }
    ]
}
