package  
{
	import flash.display.*;
	import flash.filters.DropShadowFilter;
	import flash.text.*;
	import flash.events.*;
	import flash.net.*;
	import flash.external.ExternalInterface;
	
	/**
	 * NameTag ExternalInterface
	 * 
	 * setName(name:String):void
	 * - name:	The name to display.
	 * 
	 * setAlpha(alpha:Number):void
	 * - alpha:	The desired alpha value of the NameTag.
	 **/
	public class NameTag extends Sprite
	{
		var _positioned:Boolean;
		var _configUrl:String = 'NameTag.xml';
		var _tagCont:Sprite;
		var _tagField:TextField;
		var _tagTextY:Number;
		var _tagLeftImg:Loader;
		var _tagMiddleLeftImg:Loader;
		var _tagMiddleRightImg:Loader;
		var _tagRightImg:Loader;
		var _tagArrowImg:Loader;
		var _loadQueue:Array;
		var _fontFace:String;
		var _fontSize:int;
		var _fontColor:String;
		var _strokeColor:String;
		var _name:String;
		
		public function NameTag() 
		{
			init();
			
			// test
			//setName("Ramalamadingdong");
			//setAlpha(0.5);
		}
		
		private function init()
		{
			_positioned = false;
			_tagCont = new Sprite();
			_tagCont.visible = false;
			addChild(_tagCont);
			_tagLeftImg = new Loader();
			_tagMiddleLeftImg = new Loader();
			_tagMiddleRightImg = new Loader();
			_tagArrowImg = new Loader();
			_tagRightImg = new Loader();
			_tagField = new TextField();
			_tagCont.addChild(_tagLeftImg);
			_tagCont.addChild(_tagMiddleLeftImg);
			_tagCont.addChild(_tagMiddleRightImg);
			_tagCont.addChild(_tagArrowImg);
			_tagCont.addChild(_tagRightImg);
			_tagCont.addChild(_tagField);
			_tagCont.cacheAsBitmap = true;
			
			_loadQueue = new Array();
			_loadQueue.push(_tagLeftImg);
			_loadQueue.push(_tagMiddleRightImg);
			_loadQueue.push(_tagMiddleRightImg);
			_loadQueue.push(_tagArrowImg);
			_loadQueue.push(_tagRightImg);
			
			var urlReq:URLRequest = new URLRequest(_configUrl);
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, xmlLoaded);
			urlLoader.load(urlReq);
			
			ExternalInterface.addCallback("setName", setName);
			ExternalInterface.addCallback("setAlpha", setAlpha);
			
			ExternalInterface.addCallback('gc', gc);
		}
		
		public function setName(name:String):void
		{
			trace("setting name:" + name);
			_name = name;
			doLayout();
		}
		
		public function setAlpha(alpha:Number):void
		{
			_tagCont.alpha = alpha;
		}
		
		private function xmlLoaded(e:Event)
		{
			var configXml:XML = new XML(URLLoader(e.target).data);
			
			// load tag graphics
			var tagNode:XML = XMLList(configXml.descendants('tag'))[0];
			var leftUrl:String = tagNode.attribute('left');
			var middleUrl:String = tagNode.attribute('middle');
			var rightUrl:String = tagNode.attribute('right');
			var arrowUrl:String = tagNode.attribute('arrow');
			_tagTextY = parseFloat(tagNode.attribute('textY'));
			_tagLeftImg.contentLoaderInfo.addEventListener(Event.COMPLETE, imgLoaded);
			_tagMiddleLeftImg.contentLoaderInfo.addEventListener(Event.COMPLETE, imgLoaded);
			_tagMiddleRightImg.contentLoaderInfo.addEventListener(Event.COMPLETE, imgLoaded);
			_tagRightImg.contentLoaderInfo.addEventListener(Event.COMPLETE, imgLoaded);
			_tagArrowImg.contentLoaderInfo.addEventListener(Event.COMPLETE, imgLoaded);
			_tagLeftImg.load(new URLRequest(leftUrl));
			_tagMiddleLeftImg.load(new URLRequest(middleUrl));
			_tagMiddleRightImg.load(new URLRequest(middleUrl));
			_tagRightImg.load(new URLRequest(rightUrl));
			_tagArrowImg.load(new URLRequest(arrowUrl));
			
			var fontNode:XML = XMLList(configXml.descendants('font'))[0];
			_fontFace = fontNode.attribute('face');
			_fontSize = parseInt(fontNode.attribute('size'));
			_fontColor = fontNode.attribute('color');
			_strokeColor = fontNode.attribute('stroke');
			formatTagField();
		}
		
		private function imgLoaded(e:Event)
		{
			_loadQueue.splice(_loadQueue.indexOf(e.target), 1);
			doLayout();
		}
		
		private function formatTagField()
		{
			trace("formatting tag field");
			_tagField.type = TextFieldType.DYNAMIC;
			_tagField.multiline = _tagField.selectable = false;
			_tagField.autoSize = TextFieldAutoSize.LEFT;
			var format:TextFormat = new TextFormat();
			format.color = parseInt('0x' + _fontColor);
			format.font = _fontFace;
			format.size = _fontSize;
			_tagField.defaultTextFormat = format;
			_tagField.filters = [new DropShadowFilter(0,0,parseInt('0x'+_strokeColor),1,2,2,2)];
		}
		
		private function doLayout()
		{
			if (_loadQueue.length > 0 || !_name)
			{
				trace("not ready for layout");
				return;
			}
			trace("doing layout");
			_tagField.text = _name;
			//_tagField.width = _tagField.textWidth;
			_tagField.x = stage.stageWidth/2 - _tagField.width/2;
			var fieldX:int = _tagField.width < _tagArrowImg.width ? stage.stageWidth/2 - _tagArrowImg.width/2 : _tagField.x;
			fieldX = Math.round(fieldX);
			_tagLeftImg.x = fieldX - _tagLeftImg.width;
			_tagMiddleLeftImg.x = fieldX;
			_tagMiddleLeftImg.width = Math.max(0,stage.stageWidth/2 - _tagArrowImg.width/2 - _tagMiddleLeftImg.x);
			_tagArrowImg.x = _tagMiddleLeftImg.x + _tagMiddleLeftImg.width;
			_tagMiddleRightImg.x = _tagArrowImg.x + _tagArrowImg.width;
			_tagMiddleRightImg.width = Math.max(0,Math.ceil(_tagField.width/2 - _tagArrowImg.width/2));
			_tagRightImg.x = _tagMiddleRightImg.x + _tagMiddleRightImg.width;
			
			_tagLeftImg.y = _tagMiddleLeftImg.y = _tagArrowImg.y = _tagMiddleRightImg.y = _tagRightImg.y = stage.stageHeight - _tagArrowImg.height;
			_tagField.y = _tagArrowImg.y + _tagTextY;
			
			_tagCont.visible = true;
		}
		
		private function gc():void
		{
			   // unsupported hack that seems to force a full GC
			   try
			   {
					  var lc1:LocalConnection = new LocalConnection();
					  var lc2:LocalConnection = new LocalConnection();

					  lc1.connect('name');
					  lc2.connect('name');
			   }
			   catch (e:Error)
			   {
			   }
		}
	}
	
}