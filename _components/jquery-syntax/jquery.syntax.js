// This file is part of the "jQuery.Syntax" project, and is distributed under the MIT License.
Function.prototype.bind||(Function.prototype.bind=function(a){var b=Array.prototype.slice.call(arguments,1),c=this;return function(){return c.apply(a,b)}});function ResourceLoader(a){this.dependencies={};this.loading={};this.loader=a}ResourceLoader.prototype._finish=function(a){var b=this.dependencies[a];if(b){a=this._loaded.bind(this,a);for(var c=0;c<b.length;c+=1)a=this.get.bind(this,b[c],a);a()}else this._loaded(a)};
ResourceLoader.prototype._loaded=function(a){var b=this[a],c=this.loading[a];this.loading[a]=null;if(b)for(a=0;a<c.length;a+=1)c[a](b);else alert("ResourceLoader: Could not load resource named "+a)};ResourceLoader.prototype.dependency=function(a,b){if(!this[b]||this.loading[name])this.dependencies[a]?this.dependencies[a].push(b):this.dependencies[a]=[b]};
ResourceLoader.prototype.get=function(a,b){void 0==a?b():this.loading[a]?this.loading[a].push(b):this[a]?b(this[a]):(this.loading[a]=[b],this.loader(a,this._finish.bind(this,a)))};
var Syntax={root:null,aliases:{},styles:{},themes:{},lib:{},cacheScripts:!0,cacheStyleSheets:!0,codeSelector:"code:not(.highlighted)",defaultOptions:{theme:"base",replace:!0,linkify:!0},brushes:new ResourceLoader(function(a,b){a=Syntax.aliases[a]||a;Syntax.getResource("jquery.syntax.brush",a,b)}),loader:new ResourceLoader(function(a,b){Syntax.getResource("jquery.syntax",a,b)}),getStyles:function(a){var b=jQuery("<link>");jQuery("head").append(b);Syntax.cacheStyleSheets||(a=a+"?"+Math.random());b.attr({rel:"stylesheet",
type:"text/css",href:a})},getScript:function(a,b){var c=document.createElement("script");c.onreadystatechange=function(){!this.onload||"loaded"!=this.readyState&&"complete"!=this.readyState||(this.onload(),this.onload=null)};c.onload=b;c.type="text/javascript";Syntax.cacheScripts||(a=a+"?"+Math.random());c.src=a;document.getElementsByTagName("head")[0].appendChild(c)},getResource:function(a,b,c){Syntax.detectRoot();a=a+"."+b;if(b=this.styles[a])for(var d=0;d<b.length;d+=1)this.getStyles(this.root+
b[d]);Syntax.getScript(this.root+a+".js",c)},alias:function(a,b){Syntax.aliases[a]=a;for(var c=0;c<b.length;c+=1)Syntax.aliases[b[c]]=a},brushAliases:function(a){var b=[],c;for(c in Syntax.aliases)Syntax.aliases[c]===a&&b.push(c);return b},brushNames:function(){var a=[],b;for(b in Syntax.aliases)b===Syntax.aliases[b]&&a.push(b);return a},detectRoot:function(){if(null==Syntax.root){var a=jQuery("script").filter(function(){return this.src.match(/jquery\.syntax/)}).get(0);a&&(a=a.src.match(/.*\//))&&
(Syntax.root=a[0])}}};jQuery.fn.syntax=function(a,b){0!=this.length&&(a=jQuery.extend(Syntax.defaultOptions,a),Syntax.loader.get("core",function(c){Syntax.highlight(this,a,b)}.bind(this)))};jQuery.syntax=function(a,b){jQuery(Syntax.codeSelector,a?a.context:null).syntax(a,b)};