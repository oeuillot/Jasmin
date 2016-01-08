import QtQuick 2.0

import "fontawesome.js" as Fontawesome;

FocusScope {
    id: widget
    height: container.height
    width: container.width

    Item {
        id: container
        x: parent.x
        y: parent.y
        width: 300
        height: 62

        Canvas {
            id: canvas
            x: 0
            y: 0
            width: parent.width
            height: parent.height

            onPaint: {
                var ctx = canvas.getContext('2d');

                console.log("Width="+width+" height="+height);

                ctx.save();

                ctx.beginPath();
                ctx.fillStyle = "#EECCCCFF";
                ctx.moveTo(4, 0);
                ctx.lineTo(14, height-4);
                ctx.lineTo(width-10-8, height-4);
                ctx.lineTo(width-4, 0);
                ctx.closePath();
                ctx.fill();


                ctx.beginPath();
                ctx.strokeStyle = "#2D77C9";
                ctx.lineWidth = 3;
                ctx.moveTo(4, 0);
                ctx.lineTo(14, height-4);
                ctx.lineTo(width-10-8, height-4);
                ctx.lineTo(width-4, 0);
                ctx.stroke();

                ctx.restore();
            }
        }


        /*
        Rectangle {
            color: "#EECCCCFF"
            x: 0
            y: 0
            width: parent.width
            height: parent.height
        }
        */

        Rectangle {
            border.color: "#2D77C9"
            border.width: 2
            radius: 10
            x: textInput.x-6
            y: textInput.y-2
            width: textInput.width+12
            height: textInput.height+4
        }

        Text {
            id: shadowInput
            x: textInput.x
            y: textInput.y
            width: textInput.width
            height: textInput.height
            font.pixelSize: 20

            color: "#CCCCCC"
        }

        Text {
            id: textInput
            x: 32
            y: 8
            width: widget.width-x-8-logo.width-32
            font.pixelSize: 20
            property int proposalIndex: -1;
            property var proposalsArray: ([]);

            text: ""

            focus: true

            Keys.onPressed: {
                switch(event.key) {
                case Qt.Key_0:
                case Qt.Key_1:
                case Qt.Key_2:
                case Qt.Key_3:
                case Qt.Key_4:
                case Qt.Key_5:
                case Qt.Key_6:
                case Qt.Key_7:
                case Qt.Key_8:
                case Qt.Key_9:
                    event.accepted=true;
                    text+=String.fromCharCode(event.key-Qt.Key_0+48);

                    searchProposals(text);
                    break;

                case Qt.Key_Back:
                case Qt.Key_Backspace:
                case Qt.Key_Left:
                    event.accepted=true;
                    if (text.length) {
                        text=text.slice(0, -1);
                        searchProposals(text);
                    }
                    break;


                case Qt.Key_Return:
                case Qt.Key_Enter:
                    event.accepted=true;
                    onValidCB(textInput.text);
                    close();
                    break;

                case Qt.Key_Escape:
                case Qt.Key_Back:
                    event.accepted=true;
                    onCancelCB();
                    close();
                    break;

                case Qt.Key_Down:
                case Qt.Key_Up:
                    event.accepted=true;
                    if (!proposalsArray || !proposalsArray.length) {
                        break;
                    }

                    if (event.key === Qt.Key_Down) {
                        if (proposalIndex<0) {
                            proposalIndex=0;
                        } else {
                            proposalIndex=(proposalIndex+1) % proposalsArray.length;
                        }
                    } else {
                        if (proposalIndex<0) {
                            proposalIndex=proposalsArray.length-1;
                        } else {
                            proposalIndex=(proposalIndex+proposalsArray.length-1) % proposalsArray.length;
                        }
                    }

                    shadowInput.visible=false;
                    textInput.text=proposalsArray[proposalIndex].text;
                    break;
                }
            }

            function searchProposals(text) {
                proposalIndex=-1;

                var proposals=onKeyChangedCB(text);
                if (!proposals || !proposals.length) {
                    proposalsArray=null;
                    proposalIndex=-1;
                    shadowInput.visible=false;
                    proposalsList.visible=false;
                    return;
                }

                var p0=proposals[0].text;

                textInput.text=p0.substring(0, text.length);
                shadowInput.text=p0;
                shadowInput.visible=true;

                proposalsArray=proposals;
                proposalIndex=-1;

                if (proposals.length>1) {
                    var ps=proposals.map(function(p) { return p.text; });

                    var js=ps.join(', ')+".";
                    proposalsList.text=js;
                    proposalsList.visible=true;
                } else {
                    proposalsList.visible=false;
                }
            }
        }
        Rectangle {
            x: textInput.x+textInput.paintedWidth
            y: textInput.y
            width: 1
            height: textInput.height

            color: "#000000"

            SequentialAnimation on opacity {
                loops: Animation.Infinite

                PropertyAnimation {
                    easing.type: Easing.InOutQuart
                    to: 1;
                    duration: 300
                }
                PropertyAnimation {
                    easing.type: Easing.InOutQuart
                    to: 0;
                    duration: 300
                }
            }

        }

        Text {
            id: proposalsList
            x: 12
            visible: false
            y: textInput.y+textInput.height+8
            width: widget.width-x-8-logo.width-16
            font.pixelSize: 14
            elide: Text.ElideRight
        }

        Item {
            id: logo
            x: textInput.x+textInput.width+16
            y: 4
            width: 30
            height: width

            Rectangle {
                x: 0
                y: 0
                width: parent.width
                height: parent.height

                color: "#2D77C9"

                border.color: "#BB1E4392"
                border.width: 1
                radius: 1
                smooth: true
            }

            Text {
                x: (parent.width-width)/2
                y: (parent.height-height)/2
                color: "#333333"

                font.family: Fontawesome.Name
                font.pixelSize: 20
                text: Fontawesome.Icon.search
                smooth: true
            }
        }
    }


    NumberAnimation {
        id: showSearchBox
        duration: 800
        property: "y"
        from: -searchBox.height
        to: 0
    }

    property var onKeyChangedCB;
    property var onValidCB;
    property var onCancelCB;

    function close() {
        onKeyChangedCB=null;
        onValidCB=null;
        onCancelCB=null;
        widget.visible=false;
    }

    function show(onKeyChangedCB, onValidCB, onCancelCB) {

        widget.onKeyChangedCB=onKeyChangedCB;
        widget.onValidCB=onValidCB;
        widget.onCancelCB=onCancelCB;

        console.log("Container.height="+searchBox.height);
        //searchBox.y=-searchBox.height;
        proposalsList.visible=false;
        shadowInput.visible=false;
        widget.visible=true;

        //showSearchBox.start();

        textInput.text="";
        textInput.forceActiveFocus();

        textInput.searchProposals("");
    }
}
