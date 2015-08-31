import QtQuick 2.0

import "../jasmin" 1.0

FocusScope {
    id: widget

    property int cellWidth: 154;

    property int cellHeight: 190;

    property int horizontalSpacing: 0;

    property int verticalSpacing: 0;

    property var model;

    property int modelSize: 0;

    property var delegate;

    property int focusIndex: 0;

    property int cellShownCount: 32;

    onActiveFocusChanged: {
        console.log("Grid: Active focus "+activeFocus);

        if (activeFocus) {
            if (focusIndex>=0 && focus(focusIndex)) {
                return;
            }

            var rowY=grid.contentY;
            if (grid.info && grid.info.y<rowY) {
                rowY-=grid.info.height;
            }

            var firstCellIndex=Math.floor(rowY/(cellHeight+verticalSpacing))*grid.viewColumns;
            focus(firstCellIndex);
        }
    }

    Component.onCompleted: {
        widget.onModelChanged.connect(function() {
            updateLayout();
        });

        widget.onModelSizeChanged.connect(function() {
           updateLayout();
        });
    }

    function updateLayout() {
        grid.updateLayout();
    }

    function show(component, info) {
        var cy=component.y;
        var y=cy-grid.contentY;
        var ch=component.height;
        if (info) {
            ch+=info.height;
        }

        //      console.log("Index="+component.cellIndex+" y="+y+" cellHeight="+cellHeight+" component.y="+component.y+" total.height="+ch+" grid.contentY="+grid.contentY+" grid.height="+grid.height+" info.h="+(info && info.height));

        if (ch>grid.height) {
            grid.contentY=info.y;
            //            console.log("0===>"+grid.contentY);
            return;
        }

        if (y<cellHeight) {
            if (component.y-grid.contentY+ch+cellHeight+verticalSpacing<grid.height) {
                var sy=component.y+ch+cellHeight+verticalSpacing-grid.height;
                grid.contentY=Math.max(0, sy);

                //                console.log("1===>"+sy+"="+component.y+"+"+ch+"+"+cellHeight+"+"+verticalSpacing+"-"+grid.height);
                return;
            }

            //            console.log("2===>"+cy);
            grid.contentY=Math.min(cy, grid.contentHeight-grid.height);
            return;
        }

        if (y+ch+cellHeight>grid.height) {
            var sy=component.y+ch+cellHeight-grid.height;

            //            console.log("SY="+sy+" grid.contentHeight="+grid.contentHeight+" component.height="+component.height);

            grid.contentY=Math.min(sy, grid.contentHeight-grid.height);
            //            console.log("3===>"+grid.contentY);
            return;
        }

        //        console.log("0===>");
    }

    function showInfo(item, infoComponent, params) {
        //        console.log("Show info of "+item.cellIndex);

        var rowIndex=item.cellIndex/grid.viewColumns;

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
            var h=info.height;
            //            console.log("HEIGHT CHANGED New height="+h);

            grid.updateLayout();
        });

        info.Component.onDestruction.connect(destructingEvent(info));

        grid.updateLayout();
        show(item, info);
        return info;
    }

    function destructingEvent(info) {
        return function() {
//            console.log("Catch a destruction ! "+info.cellIndex+" "+grid.info);
            if (grid.info!==info) {
                return;
            }

            grid.info=null;
            grid.infoRowIndex=-1;
            grid.updateLayout();
        }
    }

    function focusLeft(cellIndex) {
        var x=(cellIndex % grid.viewColumns);

        if (!x) {
            return focus(cellIndex+grid.viewColumns-1);
        }

        return focus(cellIndex-1);
    }

    function focusRight(cellIndex) {
        var x=(cellIndex % grid.viewColumns);

        if (x+1===grid.viewColumns) {
            return focus(cellIndex-grid.viewColumns+1);
        }

        return focus(cellIndex+1);
    }

    function focusTop(cellIndex) {
        return focus(cellIndex-grid.viewColumns);
    }

    function focusBottom(cellIndex) {
        var modelSize=Math.max(widget.model.length, widget.modelSize);

        if (cellIndex+grid.viewColumns>=modelSize) {
            if (Math.floor(cellIndex/grid.viewColumns)===Math.floor((modelSize-1)/grid.viewColumns)) {
                return false;
            }

            cellIndex=modelSize-1;
        } else {
            cellIndex+=grid.viewColumns;
        }

        return focus(cellIndex);
    }


    function focus(cellIndex) {
        var model=widget.model;
        var modelSize=Math.max(widget.model.length, widget.modelSize);

        //console.log("Focus "+cellIndex+" model="+model.length);
        if (cellIndex<0 || cellIndex>=modelSize) {
            return false;
        }

        var delegateIndex=grid.cellIndexToCellDelegate(cellIndex);
        var cellDelegate=grid.cellDelegates[delegateIndex];

  //      console.log("=>["+cellIndex+","+delegateIndex+"]="+cellDelegate);

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

        property int viewColumns: 7;

        property int viewRows: 4

        property int viewCells: 0;

        property var cellDelegates: ([])

        property int pageIndex;

        property Info info;

        property int infoRowIndex: -1;

        property var cellUpdate: ([]);

        property double

        repeatStop: 0;

        Component.onCompleted: {

        }

        onHeightChanged: {
            //console.log("Width="+width+" height="+height);

            viewColumns=Math.floor((width+horizontalSpacing)/(cellWidth+horizontalSpacing));

            viewRows=Math.ceil((height+verticalSpacing)/(cellHeight+verticalSpacing));

            viewCells=viewColumns*(viewRows+1); // Pour le scroll

            //console.log("width="+width+" height="+height+" viewColumns="+viewColumns+" viewRows="+viewRows+" viewCells="+viewCells);

            cellShownCount=viewCells;

            updateLayout();
        }

        onContentYChanged: {
            updateContentYChanged();
        }


        function updateContentYChanged() {
            if (!model) {
                return;
            }

            var rowY=contentY;
            if (info && info.y<rowY) {
                rowY-=info.height;
            }

            var rowIndex=Math.floor(rowY/(cellHeight+verticalSpacing));
            pageIndex=rowIndex;

            var y=rowIndex*(widget.cellHeight+widget.verticalSpacing);
            if (info && infoRowIndex<rowIndex) {
                y+=info.height;
            }

            var modelSize=Math.max(widget.model.length, widget.modelSize);

            //console.log("contentY="+contentY+" rowY="+rowY+" rowIndex="+rowIndex+" y="+y);

            var created=0;
            var associated=0;

            for(var j=0;j<viewRows;j++, rowIndex++) {
                var idx=rowIndex*grid.viewColumns;
                var delegateIndex=cellIndexToCellDelegate(idx);

                for(var i=0;i<grid.viewColumns;i++,idx++,delegateIndex++) {
                    var cellModel=model[idx];
                    var cellDelegate=grid.cellDelegates[delegateIndex];

                    if (cellDelegate) {
                        if (cellDelegate.cellIndex===idx) {
                            if (cellDelegate.y!==y) {
                                cellDelegate.y=y;
                            }
                            if (!cellDelegate.visible) {
                                cellDelegate.visible=true;
                            }
                            if (cellDelegate.model!==cellModel) {
                                cellDelegate.model=cellModel;
                            }
                            if (cellDelegate.delayedUpdateModel) {
                                registerAsync(idx, cellDelegate);
                            }
                            continue;
                        }

                        if (idx>=modelSize) {
                            cellDelegate.visible=false;
                            continue;
                        }

                        cellDelegate.y=y;
                        cellDelegate.model=cellModel;
                        cellDelegate.cellIndex=idx;

                        if (cellDelegate.updateDelegate) {
                            cellDelegate.updateDelegate();
                        }

                        cellDelegate.visible=true;

                        if (cellDelegate.delayedUpdateModel) {
                            registerAsync(idx, cellDelegate);
                        }

                        associated++;
                        continue;
                    }

                    if (idx>=modelSize) {
                        continue;
                    }

                    cellDelegate=widget.delegate.createObject(grid.contentItem, {
                                                                  x: i*(widget.cellWidth+widget.horizontalSpacing),
                                                                  y: y,
                                                                  width: cellWidth,
                                                                  height: cellHeight,
                                                                  model: cellModel,
                                                                  cellIndex: idx
                                                              });

                    cellDelegate.onActiveFocusChanged.connect(delegateActiveFocus(cellDelegate));

                    cellDelegates[delegateIndex] = cellDelegate;
                    created++;

                    if (cellDelegate.delayedUpdateModel) {
                        registerAsync(idx, cellDelegate);
                    }
                }

                y+=widget.cellHeight+widget.verticalSpacing;
                if (grid.info && grid.infoRowIndex===rowIndex) {
                    grid.info.y=y;
                    y+=grid.info.height;
                }
            }

            if (associated || created) {
                //                console.log("Layout update: associated="+associated+" created="+created);
            }
        }

        function delegateActiveFocus(cellDelegate) {
            return function() {
                if (cellDelegate.activeFocus) {
                    focusIndex=cellDelegate.cellIndex;
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
            var rowIndex=Math.floor(cellIndex/grid.viewColumns);

            var delegateIndex = ((rowIndex % (grid.viewRows+1))*grid.viewColumns)+(cellIndex % grid.viewColumns);

            //console.log("toDelegateIndex("+cellIndex+")="+delegateIndex+"  rowIndex="+rowIndex+" grid.viewRows="+grid.viewRows);

            return delegateIndex;
        }

        function updateLayout() {
            if (!width || !widget.model) {
                return;
            }

            var now=Date.now();

            //console.log("Model="+widget.model+" "+(widget.model && widget.model.length));

            var modelSize=Math.max(widget.model.length, widget.modelSize);

            var ch=Math.floor((modelSize+viewColumns-1)/viewColumns)

            var h=ch*(cellHeight+verticalSpacing)-verticalSpacing;
            if (info) {
                h+=info.height;
            }

            h=Math.max(height, h);

            if (h!==contentHeight) {
                contentHeight=h;

                console.log("Change content height to "+h);
            }

            updateContentYChanged();

            now=Date.now()-now;
//            console.log("Construct delay="+now+"ms");
        }


        Keys.onPressed: {
            function markRepeat() {
                grid.repeatStop=Date.now()+250;
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
            id: timer
            interval: 50;
            running: false
            repeat: true

            onTriggered: {
                var now=Date.now();

                if (grid.repeatStop && grid.repeatStop>now) {
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
}
