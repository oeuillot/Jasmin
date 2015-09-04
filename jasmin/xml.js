.pragma library

.import "util.js" as Util
.import fbx.async 1.0 as Async
.import "xmlParser.js" as XmlParser

var XMLNS_SUPPORT=false;

function $XML(nodes) {

    if (!(this instanceof $XML)) {
        if (!nodes && nodes!==null){
            return _EMPTY;
        }

        return new $XML(nodes);
    }

    if (nodes && nodes.length===1) {
        nodes=nodes[0];
    }

    this.nodes=(nodes)?nodes:undefined;

    if (nodes instanceof Array) {
        this.length = nodes.length;

    } else if (nodes){
        this.length = 1;
    }
}

$XML.prototype.constructor = $XML;

var _EMPTY=$XML(null);

$XML.prototype.xmlNodes = function(copy) {
    var nodes=this.nodes;
    if (!nodes) {
        return null;
    }

    if (nodes instanceof Array) {
        if (copy) {
            nodes=nodes.slice(0);
        }

        return nodes;
    }

    return [ nodes ];
}

$XML.prototype.xmlNode = function() {
    var nodes=this.nodes;
    if (!nodes) {
        return null;
    }

    if (nodes instanceof Array) {
        return nodes[0];
    }

    return nodes;
}

$XML.prototype.children=function() {
    var n=this.nodes;
    if (!n) {
        return _EMPTY;
    }

    var ret=[];

    if (n instanceof Array) {
        n.forEach(function (node) {
            var r2=_children(node);

            ret=ret.concat(r2);
        });
    } else {
        ret=_children(n);
    }

    if (!ret.length) {
        return _EMPTY;
    }

    return $XML(ret);
}

function _children(node) {
    var ret=[];

    switch(node.nodeType) {
    case 9:
        if (node.documentElement) {
            ret.push(node.documentElement);
        }
        break;

    case 1:
        var childNodes=node.childNodes;
        if (!childNodes) {
            break;
        }
        childNodes.forEach(function(c){
            if (c.nodeType===1) {
                ret.push(c);
            }
        });
        break;
    }
    return ret;
}

$XML.prototype.attr=function(name, xmlns) {
    var n=this.nodes;
    if (!n) {
        return "";
    }

    if (n instanceof Array) {
        for(var i=0;i<n.length;i++) {
            var ret=_attr(n[i], name, xmlns);
            if (ret!==undefined){
                return ret;
            }
        }

        return undefined;
    }

    return _attr(n, name, xmlns);
}

function _attr(node, name, xmlns) {
    var attributes=node.attributes;
    if (!attributes) {
        return;
    }

    for(var i=0;i<attributes.length;i++) {
        var attribute=attributes[i];

        var ns=attribute.namespaceURI
        if (ns && ns!==xmlns) {
            continue;
        }

        if (attribute.name!==name) {
            continue;
        }

        return attribute.value;
    }
}

$XML.prototype.text=function(mergeArray) {
    var n=this.nodes;
    if (!n) {
        return "";
    }

    if (n instanceof Array) {
        var ret=[];
        n.forEach(function(node) {
            ret.push(_getText(node));
        });

        if (mergeArray!==false) {
            ret=ret.join('');
        }

        return ret;
    }

    return _getText(n);
}

function _getText(n) {
    switch(n.nodeType) {
    case 1:
        var ret="";
        var ns=n.childNodes;
        if (!ns) {
            return ret;
        }

        ns.forEach(function(node) {
            var r = _getText(node);
            if (!r) {
                return;
            }

            ret+=r;
        });

        return ret;

    case 3:
    case 4:
        return n.nodeValue;
    }

    return undefined;
}

$XML.prototype.forEach=function(func) {
    var n=this.nodes;
    if (!n) {
        return undefined;
    }

    //console.log("ForEach "+n);

    if (n instanceof Array) {
        for(var i=0;i<n.length;i++) {
            //console.log("ForEach children #"+i);

            var ret=func($XML(n[i]));
            if (ret!==undefined){
                return ret;
            }
        }

        return undefined;
    }

    return func(this);
}

function _forEachChildElement(node, func) {

    if (node.nodeType===9) {
        var documentElement=node.documentElement;

        if (!documentElement || documentElement.nodeType!==1) {
            return null;
        }

        return func(documentElement);
    }

    var children=node.childNodes;
    if (!children) {
        return null;
    }

    for(var i=0;i<children.length;i++) {
        var child=children[i];

        if (child.nodeType!==1) {
            continue;
        }

        var ret=func(child);
        if (ret!==undefined) {
            return ret;
        }
    }

    return null;
}


$XML.prototype.first=function() {
    var n=this.nodes;
    if (n instanceof Array) {
        return $XML(n[0]);
    }

    return this;
}

$XML.prototype.byTagName=function(tagName, xmlns) {
    var ret=[];

    this.walk(function(n) {

        if (!_sameTagName(n, xmlns, tagName)) {
            //console.log("Walk on "+n.tagName+"/"+tagName+" FAILED");
            return;
        }

        //console.log("Walk on "+n.tagName+"/"+tagName+" FIND");

        ret.push(n);
    });

    if (!ret.length){
        return _EMPTY;
    }

    // console.log("Return "+ret.length);

    return $XML(ret);
}

$XML.prototype.walk=function(func) {
    var nodes=this.nodes;

    if (!nodes) {
        return;
    }

    var ns;
    if (nodes instanceof Array) {
        ns=nodes.slice(0);
    } else {
        ns = [nodes];
    }

    for(;ns.length;){
        var n=ns.shift();

        var ret=func(n);
        if (ret!==undefined){
            return ret;
        }

        switch(n.nodeType) {
        case 9:
            var documentElement=n.documentElement;
            if (!documentElement || documentElement.nodeType!==1) {
                break;
            }

            ns.push(documentElement);
            break;

        case 1:
            var children=n.childNodes;
            if (!children) {
                break;
            }

            children.forEach(function(child) {
                if (child.nodeType!==1) {
                    return;
                }

                ns.push(child);
            });
            break;
        }
    }

    return undefined;
}


$XML.prototype.toObject=function() {
    var node=this.nodes;
    if (!node) {
        return null;
    }

    if (node instanceof Array) {
        node=node[0];
    }

    return _toObject(node);
}


$XML.prototype.count=function() {
    var node=this.nodes;
    if (!node) {
        return 0;
    }

    if (node instanceof Array) {
        return node.length;
    }

    return 1;
}


$XML.prototype.toObjects=function() {
    var node=this.nodes;
    if (!node) {
        return [];
    }

    if (node instanceof Array) {
        var ret=[];
        for(var i=0;i<node.length;i++) {
            ret.push(_toObject(node[i]));
        }

        return ret;
    }

    return [_toObject(node)];
}

function _toObject(node) {

    var atts={};

    if (node.nodeType===9) {
        var child=node.documentElement;
        if (!child || child.nodeType!==1) {
            return atts;
        }

        atts[child.tagName]=_toObject(child);
        return atts;
    }

    if (node.nodeType!==1) {
        return atts;
    }

    var name=node.tagName;

    var children=node.childNodes;
    if (!children || !children.length) {
        return atts;
    }

    var type=0;
    for(var i=0;i<children.length;i++) {
        var child=children[i];

        if (child.nodeType===1) {
            if (type===3) {
                atts={};
            }
            type=1;

            var cur=atts[child.tagName];

            if (cur===undefined) {
                atts[child.tagName]=_toObject(child);
                continue;
            }

            if (!(cur instanceof Array)) {
                cur=[cur];
                atts[child.tagName]=cur;
            }
            cur.push(_toObject(child));
            continue;
        }

        if (child.nodeType===3) {
            if (type===1){
                continue;
            }

            if (type==0) {
                atts=child.nodeValue;
                type=3;
                continue;
            }

            atts+=child.nodeValue;
            continue;
        }
    }
    return atts;
}

$XML.prototype.byPath=function(path, xmlnsDef, log) {
    if (!xmlnsDef) {
        throw new Error("Xmlns must be defined !");
    }

    var node=this.nodes;
    if (!node) {
        return _EMPTY;
    }

    if (node instanceof Array) {
        var ret=[];
        for(var i=0;i<node.length;i++) {
            var r=_byPath(node[i], path, xmlnsDef, log);

            if (!r.nodes) {
                continue;
            }

            if (r.nodes instanceof Array) {
                ret=ret.concat(r.nodes);
                continue;
            }

            ret.push(r.nodes);
        }

        if (!ret.length) {
            return _EMPTY;
        }

        return $XML(ret);
    }

    return _byPath(node, path, xmlnsDef, log);
}

var _byPathWork={};
function _byPath(node, path, xmlnsDef, log) {
    if (log) {
        console.log("ByPath path="+path+" node="+node);
    }

    var ps=path.split('/');

    var ret=[];

    var defaultNamespaceURI=xmlnsDef[''];

    for(;ps.length;) {
        var p=ps.shift();
        if (!p) {
            continue;
        }

        var sp=XmlParser.splitName(p, _byPathWork);
        var namespaceURI=defaultNamespaceURI;
        if (sp.xmlns) {
            namespaceURI=xmlnsDef[sp.xmlns];
        }
        var tagName=sp.name;

        if (log) {
            console.log("Search segment="+p+" xmlns="+namespaceURI+" tagName="+tagName);
        }

        var r2=_forEachChildElement(node, function(child) {

            if (!_sameTagName(child, namespaceURI, tagName)) {
                if (log) {
                    console.log("Enter node="+child.tagName+" segment="+p+" => "+false);
                }
                return;
            }

            if (log) {
                console.log("Enter node="+child.tagName+" segment="+p+" => "+true);
            }

            if (ps.length) {
                node=child;
                return true;
            }

            ret.push(child);
        });
        if (!r2) {
            break;
        }
    }

    if (ret.length) {
        return $XML(ret);
    }

    return _EMPTY;
}

$XML.prototype.xtoString=function() {
    if (!this.nodes) {
        return "[$XML EMPTY]";
    }

    return "[$XML nodes="+Util.inspect(this.nodes,false,{})+"]";
}

var _sameTagWork={};
function _sameTagName(n, xmlns, tagName, log) {
    if (!n) {
        throw new Error("Internal error r=null xmlns="+xmlns+" tagName="+tagName);
    }

    if (log) {
        console.log("Compare xmlns=>"+n.namespaceURI+"/"+xmlns+"  tagName=>"+n.tagName+"/"+tagName);
    }

    if (n.namespaceURI!==xmlns){
        if (log) {
            console.log("NOT the same xmlns !");
        }
        return false;
    }

    var sp=XmlParser.splitName(n.tagName, _sameTagWork);
    var tName=sp.name;

    if (tName===tagName) {
        if (log) {
            console.log("Same TAG !");
        }
        return true;
    }

    if (log) {
        console.log("NOT the same TAG !");
    }

    return false;
}

function parseXML(text, xmlns, callbacks) {

   // console.log("Parse "+text);

    var document=XmlParser.parseXML(text, xmlns, callbacks);

    var deferred= Async.Deferred.resolved($XML(document));

    return deferred;
}


$XML.prototype.toArray = function() {
    var nodes=this.nodes;
    if (!nodes) {
        return [];
    }

    if (nodes instanceof Array) {
        var ret=[];

        nodes.forEach(function(n) {
            ret.push($XML(n));
        });

        return ret;
    }

    return [ this ];
}
