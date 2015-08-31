
function Parser(strict, options) {
    this.strict=strict;

    this.options=options;
    this.mode=0;

    this._elementName=null;
}

Parser.prototype.write=function(chunck) {
    start=0
    length=chunck.length;
    var end=start+length;

    var mode=this.mode;
    var idx, idx2, autoclose;
    for(;start<end;) {
        switch (mode) {
        case 0:
            // Start ELEMENT
            idx=chunck.indexOf('<', start);
            mode=1;
            start=idx+1;
            break;

        case 1:
            // Element NAME
            autoclose=false;
            idx=chunck.indexOf('>', start);
            if (idx>0) {
                if (chunck[start-1]==='/') {
                    autoclose=true;
                }

                var en=chunck.substring(start, idx-(autoclose?1:0));
                idx2=en.indexOf(' ');
                if (idx2<0) {
                    this._elementName=en;
                    start=idx+1;

                    if (autoclose) {
                        mode=0;
                        break;
                    }
                } else {
                    this._elementName=chunck.substring(start, start+idx2);
                    start=idx2+1
                }

                mode=2;
                break;
            }

            idx2=chunck.indexOf(' ',start);
            if ((idx<0 && idx2>0) || (idx2>0 && idx2<idx)) {
                this._elementName=chunck.substring(start, idx2);
                start=idx2+1;

            } else if (idx>0) {
                this._elementName=chunck.substring(start, idx);
                start=idx+1;
            }
            mode=2;
            break;

        case 2:
            // Element attributes

        case 3:
            // Element close (autoclose ?)

        case 4:
            // Text
        }
    }

}


function parser() {
    return new Parser(strict, options);
}

