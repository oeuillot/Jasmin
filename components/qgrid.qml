/**
 * Copyright Olivier Oeuillot
 */
 
import QtQuick 2.0

import "../jasmin" 1.0

FocusScope {
    id: widget

    objectName: "net.jasmin.Grid"

    property int cellWidth: 154;

    property int cellHeight: 190;

    property int horizontalSpacing: 0;

    property int verticalSpacing: 0;

    property var model;

    property int modelSize: 0;

    property var delegate;

    property int lastFocusIndex: -1;
    property int focusIndex: -1;

    property int pageCellIndex: 0;

    property int cellShownCount: 32;

    property int viewColumns: 7;

    property int viewRows: 4

    property int viewCells: 0;

    property bool userScrolling: false;

    onActiveFocusChanged: {
       console.log("Grid: Active focus "+activeFocus+" "+focusIndex);

        if (activeFocus) {
            if (focusIndex<0 && lastFocusIndex>=0) {
                focusIndex=lastFocusIndex;
            }

            if (focusIndex>=0 && focus(focusIndex)) {
                return;
            }

            var rowY=grid.contentY;
            if (grid.info && grid.info.y<rowY) {
                rowY-=grid.info.height;
            }

            var firstCellIndex=Math.floor(rowY/(cellHeight+verticalSpacing))*widget.viewColumns;
            focus(firstCellIndex);
        }
    }

    Component.onCompleted: {
        widget.onModelChanged.connect(function() {
            updateLayout("onModelChanged");
        });

        widget.onModelSizeChanged.connect(function() {
            updateLayout("onModelSizeChanged");
        });
    }

    function scrollIntoView(child) {
        var x=0;
        var y=0;
        for(var p=child;p!==grid.contentItem;p=p.parent){
            x+=p.x;
            y+=p.y;
        }

        y=Math.max(y-4, 0);

        if (y<grid.contentY) {
            grid.contentY=y;
        }
        if (y+child.height+8>grid.contentY+grid.height) {
            grid.contentY=y+child.height+8-grid.height;
        }
    }

    function onBack() {
        var cellDelegates=grid.cellDelegates;
        grid.cellDelegates=[];

        for(var i=0;i<cellDelegates.length;i++) {
            var child=cellDelegates[i];

            child.destroy();
        }
    }

    function onFront() {

    }


    function setParams(params) {
        return params;
    }

    function updateLayout(reason) {
        grid.updateLayout(reason || "widget");
    }

    function show(component, info) {
        var cy=component.y;
        var y=cy-grid.contentY;
        var ch=component.height;
        if (info) {
            ch+=info.height;
        }

        var modelSize=Math.max(widget.model.length, widget.modelSize);

        var totY=(Math.ceil(modelSize/viewColumns)*(cellHeight+verticalSpacing)-verticalSpacing)+(info?info.height:0);
        // console.log("DIFF "+totY+"/"+grid.contentHeight);
        if (grid.contentHeight!==totY) {
            grid.contentHeight=totY;
        }

        // console.log("SHOW height="+ch+" info.height="+(info?info.height:0));

       // console.log("SHOW Index="+component.cellIndex+" y="+y+" cellHeight="+cellHeight+" component.y="+component.y+" total.height="+ch+" grid.contentY="+grid.contentY+" grid.height="+grid.height+" info.h="+(info && info.height));

        if (ch>grid.height) {
            grid.contentY=info.y;
           // console.log("0===>"+grid.contentY);
            return;
        }

        var preloadShowUp=0; //cellHeight;
        if (y<preloadShowUp) {
            if (component.y-grid.contentY+ch+preloadShowUp+verticalSpacing<grid.height) {
                var sy=component.y+ch+preloadShowUp+verticalSpacing-grid.height;
                grid.contentY=Math.max(component.y-preloadShowUp, 0); //Math.max(0, sy);

             //   console.log("1===>"+sy+"="+component.y+"+"+ch+"+"+preloadShowUp+"+"+verticalSpacing+"-"+grid.height);
                return;
            }

            // console.log("2===>"+cy);
            grid.contentY=Math.min(cy, grid.contentHeight-grid.height);
            return;
        }

        var preloadShowDown=0; //cellHeight;
        if (y+ch+preloadShowDown>grid.height) {
            var sy=component.y+ch+preloadShowDown-grid.height;

            // console.log("SY="+sy+" grid.contentHeight="+grid.contentHeight+" component.height="+component.height);

            grid.contentY=Math.min(sy, grid.contentHeight-grid.height);
            //console.log("3===>"+grid.contentY);
            return;
        }

        // console.log("0===>");
    }

    function showInfo(item, infoComponent, params) {
        //        console.log("Show info of "+item.cellIndex);

        var rowIndex=item.cellIndex/widget.viewColumns;

        params=params || {};
        params.width=grid.width;
        params.cellIndex=item.cellIndex;

        if (grid.info) {
            grid.infoRowIndex=-1;
            grid.info.destroy();
            grid.info=null;
        }

        var info=infoComponent.createObject(grid.contentItem, params);

        grid.info=info;
        grid.infoRowIndex=rowIndex;

        info.onHeightChanged.connect(function() {
            //            console.log("HEIGHT CHANGED New height="+h);

            show(item, info);
            grid.updateLayout("onHeightChanged");
        });

        //listView.updateLayout("showInfo");

        info.Component.onDestruction.connect(destructingEvent(info));

        //        grid.updateLayout();
        return info;
    }

    function destructingEvent(info) {
        return function() {
            //            console.log("Catch a destruction ! "+info.cellIndex+" "+grid.info);
            if (grid.info!==info) {
                return;
            }

            var card=info.card;
            if (card) {
                card.selected=false;
            }

            grid.info=null;
            grid.infoRowIndex=-1;
            grid.updateLayout("infoDestructing");
        }
    }

    function focusLeft(cellIndex) {
        /*
        var x=(cellIndex % widget.viewColumns);

        if (!x) {
            return focus(cellIndex-1);
        }*/

        return focus(cellIndex-1);
    }

    function focusRight(cellIndex) {
        /* var x=(cellIndex % widget.viewColumns);

        if (x+1===widget.viewColumns) {
            return focus(cellIndex-widget.viewColumns+1);
        } */

        return focus(cellIndex+1);
    }

    function focusTop(cellIndex) {
        //console.log("FOCUS TOP "+cellIndex);
        return focus(cellIndex-widget.viewColumns);
    }

    function focusBottom(cellIndex) {
        var modelSize=Math.max(widget.model.length, widget.modelSize);

        if (cellIndex+widget.viewColumns>=modelSize) {
            if (Math.floor(cellIndex/widget.viewColumns)===Math.floor((modelSize-1)/widget.viewColumns)) {
                return false;
            }

            cellIndex=modelSize-1;
        } else {
            cellIndex+=widget.viewColumns;
        }

        return focus(cellIndex);
    }


    function focus(cellIndex) {
        var model=widget.model;
        if (!model) {
            return false;
        }

        var modelSize=Math.max(model.length, widget.modelSize);

        //console.log("Focus "+cellIndex+" modelSize="+modelSize);
        if (cellIndex<0 || cellIndex>=modelSize) {
            return false;
        }

        var delegateIndex=grid.cellIndexToCellDelegate(cellIndex);
        var cellDelegate=grid.cellDelegates[delegateIndex];

        //console.log("=>["+cellIndex+","+delegateIndex+"]="+cellDelegate);

        if (cellDelegate && cellDelegate.cellIndex===cellIndex) {
            cellDelegate.forceActiveFocus();
            return true;
        }

        console.log("Invalid cellIndex="+cellDelegate.cellIndex+" modelSize="+modelSize+" model.length="+model.length+" delegateIndex="+delegateIndex);
    }

    Flickable {
        id: grid
        x: 0
        y: 0
        width: widget.width
        height: widget.height

        interactive: true

        contentWidth: width
        contentHeight: height

        property var cellDelegates: ([])

        property int pageIndex;

        property Info info;

        property int infoRowIndex: -1;

        property var cellUpdate: ([]);

        property int viewShadows: 0;

        Rectangle {
            id: focusRectangle
            color: "red"
            opacity: 0.4
            width: cellWidth
            height: cellHeight
            radius: 4
            visible: Math.max(widget.model.length, widget.modelSize);

            Component.onCompleted: {
                widget.onFocusIndexChanged.connect(function() {
                    if (focusIndex<0){
                        focusRectangle.visible=false;
                        return;
                    }

                    focusRectangle.visible=true;

                    focusAnimation.stop();
                    animationX.from=focusRectangle.x;
                    animationX.to=(focusIndex % viewColumns)*(cellWidth+horizontalSpacing);
                    animationY.from=focusRectangle.y;
                    animationY.to=(Math.floor(focusIndex / viewColumns))*(cellHeight+verticalSpacing);
                    focusAnimation.start();
                });
            }
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

        onHeightChanged: {
            //console.log("Width="+width+" height="+height);

            widget.viewColumns=Math.floor((width+horizontalSpacing)/(cellWidth+horizontalSpacing));

            widget.viewRows=Math.ceil((height+verticalSpacing)/(cellHeight+verticalSpacing));

            widget.viewCells=widget.viewColumns*(widget.viewRows+1); // Pour le scroll

            grid.viewShadows = widget.viewRows +1 + 1; //(((widget.viewRows*(cellHeight+verticalSpacing))>height)?0:1);

            //console.log("width="+width+" height="+height+" viewColumns="+viewColumns+" viewRows="+viewRows+" viewCells="+widget.viewCells);

            cellShownCount=widget.viewCells;

            updateLayout("onHeightChanged");
        }

        onContentYChanged: {
            updateContentYChanged("contentYChanged");
        }


        function updateContentYChanged(reason) {
            if (!model) {
                return;
            }

            var now=Date.now();

            var rowY=contentY;
            if (info && info.y<rowY) {
                rowY-=info.height;
            }

            var rowIndex=Math.floor(rowY/(cellHeight+verticalSpacing));
            pageIndex=rowIndex;
            widget.pageCellIndex=pageIndex*widget.viewColumns;
            if (rowIndex>0){
                rowIndex--;
            }

            var y=rowIndex*(widget.cellHeight+widget.verticalSpacing);
            if (info && infoRowIndex<rowIndex) {
                y+=info.height;
            }

            var modelSize=Math.max(widget.model.length, widget.modelSize);

            //console.log("contentY="+contentY+" rowY="+rowY+" rowIndex="+rowIndex+" y="+y);

            var created=0;
            var associated=0;
            var endRows=grid.viewShadows;
            var startRows=0;

            var cellDelegates=grid.cellDelegates;

            for(var j=startRows;j<endRows;j++, rowIndex++) {
                var idx=rowIndex*widget.viewColumns;
                var delegateIndex=cellIndexToCellDelegate(idx);

                for(var i=0;i<widget.viewColumns;i++,idx++,delegateIndex++) {
                    var cellModel=model[idx];
                    var cellDelegate=cellDelegates[delegateIndex];

                   // console.log("cellModel #"+idx+" "+cellModel);

                    try {
                        if (cellDelegate) {
                            //var now2=Date.now();

                            if (cellDelegate.cellIndex===idx) {
                                if (cellDelegate.y!==y) {
                                    cellDelegate.y=y;
    //                                console.log("Update Y");
                                }
                                if (cellDelegate.model!==cellModel) {
                                    //console.log("Update cellModel "+idx+" "+cellModel);
                                    cellDelegate.model=cellModel;

                                    if (cellDelegate.delayedUpdateModel) {
                                        registerAsync(idx, cellDelegate);
                                    }
                                }
                                if (!cellDelegate.visible) {
                                    cellDelegate.visible=true;
    //                                console.log("Update visible");
                                }
                                //now2=Date.now()-now2;
                                // console.log("Time "+now2);
                                continue;
                            }
     //                       console.log("Not same index "+idx+"/"+cellDelegate.cellIndex);

                            if (idx>=modelSize) {
                                cellDelegate.visible=false;
                                continue;
                            }

                            cellDelegate.y=y;
                            cellDelegate.cellIndex=idx;
                            cellDelegate.visible=true;

                            if (rowIndex<pageIndex || rowIndex>=pageIndex+widget.viewRows) {
    //                          //  console.log("Ignore rowIndex="+rowIndex);
                                continue;
                            }

                            // console.log("Set cellModel "+idx+" "+cellModel);
                            cellDelegate.model=cellModel;

                            if (cellDelegate.delayedUpdateModel) {
                                registerAsync(idx, cellDelegate);
                            }

                            associated++;
                            continue;
                        }

                        if (idx>=modelSize) {
                            continue;
                        }

                        var params=setParams({
                                                 x: i*(widget.cellWidth+widget.horizontalSpacing),
                                                 y: y,
                                                 width: cellWidth,
                                                 height: cellHeight,
                                                 model: cellModel,
                                                 cellIndex: idx
                                             });

                        // console.log("Instanciate cellModel "+idx+" "+cellModel);

                        cellDelegate=widget.delegate.createObject(grid.contentItem, params);

                        cellDelegate.onActiveFocusChanged.connect(delegateActiveFocus(cellDelegate));

                        cellDelegates[delegateIndex] = cellDelegate;
                        created++;

                        if (cellDelegate.delayedUpdateModel) {
                            registerAsync(idx, cellDelegate);
                        }
                    } finally {
                    }
                }

                y+=widget.cellHeight+widget.verticalSpacing;
                if (grid.info && grid.infoRowIndex===rowIndex) {
                    grid.info.y=y;
                    y+=grid.info.height;
                }
            }

            now=Date.now()-now;
//            if (associated || created) {
//                console.log("updateContentYChanged: reason="+reason+" associated="+associated+" created="+created+" delay="+now+"ms");
//            }
        }

        function delegateActiveFocus(cellDelegate) {
            return function() {
                if (cellDelegate.activeFocus) {
                    focusIndex=cellDelegate.cellIndex;
                    return;
                }
                if (focusIndex===cellDelegate.cellIndex) {
                    lastFocusIndex=focusIndex;
                    focusIndex=-1;
                }
            };
        }

        function registerAsync(index, delegate) {
            cellUpdate.unshift({index: index, delegate: delegate});

            if (!timer.running) {
                timer.start();
            }
        }

        function cellIndexToCellDelegate(cellIndex) {
            var rowIndex=Math.floor(cellIndex/widget.viewColumns);

            var delegateIndex = ((rowIndex % (grid.viewShadows))*widget.viewColumns)+(cellIndex % widget.viewColumns);

            //console.log("toDelegateIndex("+cellIndex+")="+delegateIndex+"  rowIndex="+rowIndex+" viewRows.viewRows="+viewRows.viewRows);

            return delegateIndex;
        }

        function updateLayout(reason) {
            if (!width || !widget.model) {
                return;
            }

            var now=Date.now();

          //  console.log("Model="+widget.model+" "+(widget.model && widget.model.length)+" reason="+reason);

            var modelSize=Math.max(widget.model.length, widget.modelSize);

            var ch=Math.floor((modelSize+widget.viewColumns-1)/widget.viewColumns)

            var h=ch*(cellHeight+verticalSpacing)-verticalSpacing;
            if (info) {
                h+=info.height;
            }

            h=Math.max(height, h);

            if (h!==contentHeight) {
                contentHeight=h;

                //console.log("Change content height to "+h);
            }

            updateContentYChanged(reason+".updateLayout");

            now=Date.now()-now;
            //            console.log("Construct delay="+now+"ms");
        }
    }


    Keys.onPressed: {
        function markRepeat() {
            //console.log(Date.now()+" MARK REPEAT");

            userScrolling=true;
            timerRepeat.restart();
        }

        switch(event.key) {
        case Qt.Key_Left:
            markRepeat();
            if (focusLeft(focusIndex)) {
                event.accepted=true;
            }
            return;

        case Qt.Key_Right:
            markRepeat();
            if (focusRight(focusIndex)) {
                event.accepted=true;
            }
            return;

        case Qt.Key_Up:
            markRepeat();
            if (focusTop(focusIndex)) {
                event.accepted=true;
            }
            return;
        case Qt.Key_Down:
            markRepeat();
            if (focusBottom(focusIndex)) {
                event.accepted=true;
            }
            return;
        }
    }


    Timer {
        id: timerRepeat
        interval: 400;
        running: false;
        repeat: false;

        onTriggered: {
            //console.log(Date.now()+" Timer trigger: "+running);
            if (!running) {
                userScrolling=false;
            }
        }
    }

    Timer {
        id: timer
        interval: 50;
        running: false
        repeat: true

        onTriggered: {
            if (timerRepeat.running) {
                return;
            }

            for(;;) {
                if (!grid.cellUpdate.length) {
                    timer.stop();
                    return;
                }

                var update=grid.cellUpdate.shift();
                if (!grid.cellUpdate.length) {
                    timer.stop();
                }

                if (update.delegate.cellIndex!==update.index) {
                    // Item was lost by scrolling
                    // console.log("**** IGNORE Process "+update.delegate);
                    continue;
                }

                if (update.delegate.delayedUpdateModel()===false) {
                    // Nothing to do, call next immediatly
                    continue;
                }

                break;
            }
        }
    }
}
