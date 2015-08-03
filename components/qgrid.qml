import QtQuick 2.0

FocusScope {
    id: widget

    property int cellWidth: 154;

    property int cellHeight: 190;

    property int horizontalSpacing: 0;

    property int verticalSpacing: 0;

    property var model;

    property var delegate;

    onActiveFocusChanged: {
        console.log("Active focus "+activeFocus);

        if (activeFocus) {
            if (grid.pageIndex>=0) {
                var c=grid.cellDelegates[grid.pageIndex];

                if (c) {
                    c.forceActiveFocus();
                }
            }
        }
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

        console.log("y="+y+" cellHeight="+cellHeight+" component.y="+component.y+" component.height="+ch+" grid.contentY="+grid.contentY+" grid.height="+grid.height);

        if (ch>grid.height) {
            grid.contentY=info.y;
            console.log("0===>"+grid.contentY);
            return;
        }

        if (y<cellHeight) {
            if (component.y-grid.contentY+ch+cellHeight+verticalSpacing<grid.height) {
                var sy=component.y+ch+cellHeight+verticalSpacing-grid.height;
                grid.contentY=Math.max(0, sy);

                console.log("1===>"+grid.contentY);
                return;
            }

            console.log("2===>"+cy);
            grid.contentY=cy;
            return;
        }

        if (y+ch+cellHeight>grid.height) {
            var sy=component.y+ch+cellHeight-grid.height;

            console.log("SY="+sy+" grid.contentHeight="+grid.contentHeight+" component.height="+component.height);

            grid.contentY=Math.min(sy, grid.contentHeight-grid.height);
            console.log("3===>"+grid.contentY);
            return;
        }

        console.log("0===>");
    }

    function showInfo(item, infoComponent, params) {

        params=params || {};
        params.width=grid.width;

        if (grid.info) {
            grid.infoRowIndex=-1;
            grid.info.destroy();
            grid.info=null;
        }

        var rowIndex=item.cellIndex/grid.viewColumns;

        var info=infoComponent.createObject(grid.contentItem, params);

        grid.info=info;
        grid.infoRowIndex=rowIndex;

        info.onHeightChanged.connect(function() {
            var h=info.height;
            console.log("New height="+h);

            grid.updateLayout();
        });

        /*
        info['Components.onDestruction'].connect(function() {
            console.log("Info has been destroyed !");
            grid.infoRowIndex=-1;
            grid.updateLayout();
        });
*/
        grid.updateLayout();
        show(item, info);
        return info;
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
        if (cellIndex+grid.viewColumns>=model.length) {
            if (Math.floor(cellIndex/grid.viewColumns)===Math.floor((model.length-1)/grid.viewColumns)) {
                return false;
            }

            cellIndex=model.length-1;
        } else {
            cellIndex+=grid.viewColumns;
        }

        return focus(cellIndex);
    }


    function focus(cellIndex) {
        var model=widget.model;

        console.log("Focus "+cellIndex+" model="+model.length);
        if (!model || cellIndex<0 || cellIndex>=model.length) {
            return false;
        }

        var delegateIndex=grid.cellIndexToCellDelegate(cellIndex);
        var cellDelegate=grid.cellDelegates[delegateIndex];

        console.log("=>["+cellIndex+","+delegateIndex+"]="+cellDelegate);

        if (cellDelegate && cellDelegate.cellIndex===cellIndex) {
            cellDelegate.forceActiveFocus();
            return true;
        }

       console.log("Invalid cellIndex ? "+cellDelegate.cellIndex);
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

        Component.onCompleted: {

        }

        onHeightChanged: {
            //console.log("Width="+width+" height="+height);

            viewColumns=Math.floor((width+horizontalSpacing)/(cellWidth+horizontalSpacing));

            viewRows=Math.ceil((height+verticalSpacing)/(cellHeight+verticalSpacing));

            viewCells=viewColumns*(viewRows+1); // Pour le scroll

            //console.log("width="+width+" height="+height+" viewColumns="+viewColumns+" viewRows="+viewRows+" viewCells="+viewCells);

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
                        if (cellDelegate.model===cellModel) {
                            if (cellDelegate.y!==y) {
                                cellDelegate.y=y;
                            }
                            if (!cellDelegate.visible) {
                                cellDelegate.visible=true;
                            }

                            continue;
                        }

                        if (!cellModel) {
                            cellDelegate.visible=false;
                            continue;
                        }

                        cellDelegate.y=y;
                        cellDelegate.model=cellModel;
                        cellDelegate.visible=true;
                        cellDelegate.cellIndex=idx;

                        if (cellDelegate.delayedUpdateModel) {
                            registerAsync(idx, cellDelegate);
                        }

                        associated++;
                        continue;
                    }

                    if (!cellModel) {
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

                    cellDelegate.onActiveFocusChanged.connect(function() {
                       console.log("Item focus changed "+this.activeFocus);
                    });

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
                console.log("ContentY update: associated="+associated+" created="+created);
            }
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
            if (!width) {
                return;
            }

            var now=Date.now();

            //console.log("Model="+widget.model+" "+(widget.model && widget.model.length));

            var model=widget.model || [];

            var ch=Math.floor((model.length+viewColumns-1)/viewColumns)

            contentHeight=Math.max(height, ch*(cellHeight+verticalSpacing)-verticalSpacing)+((info)?info.height:0);

            updateContentYChanged();

            now=Date.now()-now;
            console.log("Construct delay="+now+"ms");
        }

        Timer {
            id: timer
            interval: 50;
            running: false
            repeat: true

            onTriggered: {
                //console.log("BING "+grid.cellUpdate.length);
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
                        continue;
                    }

                    //console.log("Process "+update.delegate);

                    if (update.delegate.delayedUpdateModel()===false) {
                        continue;
                    }

                    break;
                }
            }

        }
    }
}
