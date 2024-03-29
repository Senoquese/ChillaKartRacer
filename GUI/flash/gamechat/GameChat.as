package  
{
	import flash.display.*;
	import flash.filters.DropShadowFilter;
	import flash.text.*;
	import flash.events.*;
	import flash.net.*;
	import flash.external.ExternalInterface;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	import gs.TweenLite;
	
	/**
	 * GameChat ExternalInterface
	 * 
	 * showInput():void
	 * - Reveals the input text field.
	 * 
	 * addMessage(message:String, color:String = null):void
	 * - message:	The text of the message.
	 * - color:		Optional color for the entire message.
	 * 
	 * addPlayerMessage(color:String, name:String, message:String):void
	 * - color:		The color for the player's name.
	 * - name:		The player's name.
	 * - message:	The text of the message.
	 **/
	public class GameChat extends Sprite
	{
		var _focus:Boolean;
		var _configUrl:String = 'GameChat.xml';
		var _inputCont:Sprite;
		var _inputField:TextField;
		var _inputTextY:Number;
		var _inputLeftImg:Loader;
		var _inputMiddleImg:Loader;
		var _inputRightImg:Loader;
		var _chatHistory:TextField;
		var _mask:Loader;
		var _loadQueue:Array;
		var _fontFace:String;
		var _fontSize:int;
		var _fontColor:String;
		var _chatTimeout:Number = 30000;
		var _timeoutTimer:Timer;
		
		public function GameChat() 
		{
			init();
		}
		
		private function init()
		{
			stage.align     = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(Event.RESIZE, doLayout);
			
			_inputCont = new Sprite();
			_focus = false;
			_inputCont.visible = false;
			addChild(_inputCont);
			_inputLeftImg = new Loader();
			_inputMiddleImg = new Loader();
			_inputRightImg = new Loader();
			_inputField = new TextField();
			_inputCont.addChild(_inputLeftImg);
			_inputCont.addChild(_inputMiddleImg);
			_inputCont.addChild(_inputRightImg);
			_inputCont.addChild(_inputField);
			_chatHistory = new TextField();
			addChild(_chatHistory);
			_mask = new Loader();
			addChild(_mask);
			
			_loadQueue = new Array();
			_loadQueue.push(_inputLeftImg);
			_loadQueue.push(_inputMiddleImg);
			_loadQueue.push(_inputRightImg);
			
			var urlReq:URLRequest = new URLRequest(_configUrl);
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, xmlLoaded);
			urlLoader.load(urlReq);
			
			_timeoutTimer = new Timer(_chatTimeout, 1);
			_timeoutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, hideChat);
			
			ExternalInterface.addCallback("showInput", showInput);
			ExternalInterface.addCallback("addMessage", addMessage);
			ExternalInterface.addCallback("addPlayerMessage", addPlayerMessage);
			
			ExternalInterface.addCallback('gc', gc);
		}
		
		public function showInput():void
		{
			if (!_focus)
			{
				_timeoutTimer.stop();
				_inputCont.visible = true;
				_inputCont.alpha = 0;
				stage.focus = _inputField;
				stage.addEventListener(Event.ENTER_FRAME, animate);
				_focus = true;
				_timeoutTimer.start();
				TweenLite.to(this, 1.0, { alpha:1 } );
			}
		}
		
		public function hideChat(e:TimerEvent)
		{
			TweenLite.to(this, 1.0, { alpha:0 } );
		}
		
		public function addMessage(message:String, color:String = null):void
		{
			_chatHistory.htmlText += '<font color="#'+(color?color:_fontColor)+'">'+message+'</font><br>';
			positionChatHistory();
			_timeoutTimer.stop();
			_timeoutTimer.start();
			TweenLite.to(this, 1.0, { alpha:1 } );
		}
		
		public function addPlayerMessage(color:String, name:String, message:String):void
		{
			var s:String = '<font color="#'+color+'">'+name+'</font><font color="#'+_fontColor+'">: '+message+'</font><br>';
			_chatHistory.htmlText += s;
			positionChatHistory();
			_timeoutTimer.stop();
			_timeoutTimer.start();
			TweenLite.to(this, 1.0, { alpha:1 } );
		}
		
		private function sendMessage()
		{
			// testing
			//if (_inputField.text.length > 0)
			{
				//addPlayerMessage('ff0000', 'eeenmachine', _inputField.text);
				ExternalInterface.call("SendMessage", _inputField.text);
			}
			
			trace("sending message:" + _inputField.text);
			_inputField.text = "";
			_focus = false;
			stage.addEventListener(Event.ENTER_FRAME, animate);
			_timeoutTimer.stop();
			_timeoutTimer.start();
			TweenLite.to(this, 1.0, { alpha:1 } );
		}
		
		private function animate(e:Event)
		{
			if (_focus)
			{
				if (_inputCont.alpha < 1)
				{
					_inputCont.alpha += (1 - _inputCont.alpha) / 2;
					if (_inputCont.alpha > 0.99)
					{
						_inputCont.alpha = 1;
						stage.removeEventListener(Event.ENTER_FRAME, animate);
					}
				}
			}
			else
			{
				if (_inputCont.alpha > 0)
				{
					_inputCont.alpha += (0 - _inputCont.alpha) / 2;
					if (_inputCont.alpha < 0.01)
					{
						_inputCont.alpha = 0;
						_inputCont.visible = false;
						stage.removeEventListener(Event.ENTER_FRAME, animate);
						_focus = false;
					}
				}
			}
		}
		
		private function positionChatHistory()
		{
			if (_chatHistory.textHeight > stage.stageHeight)
			{
				var i:int = _chatHistory.htmlText.indexOf('</P>')+4;
				var trimmed:String = _chatHistory.htmlText.substr(i, _chatHistory.htmlText.length - i);
				_chatHistory.htmlText = trimmed;
			}
			_chatHistory.y = _inputCont.y - _chatHistory.textHeight;
			_chatHistory.height = _chatHistory.textHeight + _fontSize;
		}
		
		private function xmlLoaded(e:Event)
		{
			var configXml:XML = new XML(URLLoader(e.target).data);
			
			// load input graphics
			var inputNode:XML = XMLList(configXml.descendants('input'))[0];
			var leftUrl:String = inputNode.attribute('left');
			var middleUrl:String = inputNode.attribute('middle');
			var rightUrl:String = inputNode.attribute('right');
			_inputTextY = parseFloat(inputNode.attribute('textY'));
			_inputLeftImg.contentLoaderInfo.addEventListener(Event.COMPLETE, imgLoaded);
			_inputMiddleImg.contentLoaderInfo.addEventListener(Event.COMPLETE, imgLoaded);
			_inputRightImg.contentLoaderInfo.addEventListener(Event.COMPLETE, imgLoaded);
			_inputLeftImg.load(new URLRequest(leftUrl));
			_inputMiddleImg.load(new URLRequest(middleUrl));
			_inputRightImg.load(new URLRequest(rightUrl));
			
			var fontNode:XML = XMLList(configXml.descendants('font'))[0];
			_fontFace = fontNode.attribute('face');
			_fontSize = parseInt(fontNode.attribute('size'));
			_fontColor = fontNode.attribute('color');
			setupInputField();
			setupChatHistory();
			
			var maskNode:XML = XMLList(configXml.descendants('mask'))[0];
			var maskUrl:String = maskNode.attribute('img');
			_mask.contentLoaderInfo.addEventListener(Event.COMPLETE, maskLoaded);
			_mask.load(new URLRequest(maskUrl));
		}
		
		private function maskLoaded(e:Event)
		{
			_mask.width = stage.stageWidth;
			_mask.cacheAsBitmap = _chatHistory.cacheAsBitmap = true;
			_chatHistory.mask = _mask;
		}
		
		private function imgLoaded(e:Event)
		{
			_loadQueue.splice(_loadQueue.indexOf(e.target), 1);
			doLayout();
		}
		
		private function setupInputField()
		{
			_inputField.multiline = false;
			_inputField.wordWrap = false;
			//_inputField.selectable = false;
			_inputField.type = TextFieldType.INPUT;
			var format:TextFormat = new TextFormat();
            format.font = _fontFace;
            format.color = parseInt('0x' + _fontColor);
            format.size = _fontSize;
            _inputField.defaultTextFormat = format;
			_inputField.filters = [new DropShadowFilter(1)];
			//_inputField.text = "Testing...";
			stage.focus = _inputField;
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		}
		
		private function setupChatHistory()
		{
			_chatHistory.multiline = true;
			_chatHistory.wordWrap = true;
			_chatHistory.selectable = false;
			_chatHistory.type = TextFieldType.DYNAMIC;
			var format:TextFormat = new TextFormat();
            format.font = _fontFace;
            format.color = parseInt('0x' + _fontColor);
            format.size = _fontSize;
            _chatHistory.defaultTextFormat = format;
			_chatHistory.filters = [new DropShadowFilter(1)];
		}
		
		private function keyDown(e:KeyboardEvent)
		{
			if (e.keyCode == Keyboard.ENTER)
			{
				sendMessage();
			}
			else
			{
				showInput();
			}
		}
		
		private function doLayout(e:Event = null)
		{
			if (_loadQueue.length > 0)
			{
				return;
			}
			
			_inputLeftImg.x = 0;
			_inputCont.y = stage.stageHeight - _inputLeftImg.height;
			_inputMiddleImg.x = _inputField.x = _inputLeftImg.width;
			_inputRightImg.x = stage.stageWidth - _inputRightImg.width;
			_inputMiddleImg.width = _inputField.width = _inputRightImg.x - _inputLeftImg.width;
			_inputField.height = _inputMiddleImg.height;
			_inputField.y = _inputTextY;
			_chatHistory.width = stage.stageWidth;
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