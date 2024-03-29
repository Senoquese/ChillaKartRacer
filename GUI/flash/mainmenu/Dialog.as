package  
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	
	/**
	 * dimensions: 400 x 253
	 * 
	 * External Interface:
	 * setTitle(str:String)
	 * setBody(str:String)
	 * setLeftButtonLabel(str:String)
	 * setRightButtonLabel(str:String)	// setting str to '' hides the right button
	 * 
	 * External calls;
	 * leftButtonClick()
	 * rightButtonClick()
	 */
	public class Dialog extends Sprite
	{
		private var _title:TextField;
		private var _body:TextField;
		private var _leftButton:LoadSaveButton;
		private var _rightButton:LoadSaveButton;
		
		public function Dialog() 
		{
			_title = title;
			_body = body;
			_leftButton = leftButton;
			_rightButton = rightButton;
			
			_leftButton.addEventListener(MouseEvent.CLICK, leftButtonClicked);
			_rightButton.addEventListener(MouseEvent.CLICK, rightButtonClicked);
			
			ExternalInterface.addCallback('setTitle', setTitle);
			ExternalInterface.addCallback('setBody', setBody);
			ExternalInterface.addCallback('setLeftButtonLabel', setLeftButtonLabel);
			ExternalInterface.addCallback('setRightButtonLabel', setRightButtonLabel);
			
			ExternalInterface.addCallback('gc', gc);
			//test();
		}
		
		public function setTitle(str:String):void
		{
			_title.text = str;
		}
		
		public function setBody(str:String):void
		{
			_body.htmlText = str;
			_body.y = 120 - _body.textHeight / 2;
		}
		
		public function setLeftButtonLabel(str:String):void
		{
			_leftButton.setLabel(str);
		}
		public function setRightButtonLabel(str:String):void
		{
			_rightButton.setLabel(str);
			if (str == '')
			{
				_rightButton.visible = false;
				_leftButton.x = 200 - _leftButton.width / 2;
			}
			else {
				_rightButton.visible = true;
				_leftButton.x = 42;
			}
		}
		private function leftButtonClicked(e:MouseEvent):void
		{
			trace('leftButtonClicked');
			ExternalInterface.call('leftButtonClick');
		}
		private function rightButtonClicked(e:MouseEvent):void
		{
			trace('rightButtonClicked');
			ExternalInterface.call('rightButtonClick');
		}
		
		public function test():void
		{
			setTitle('Test Title');
			setBody('This is a test.<br>This is only a test.<br>Were this a real error box<br>you would already be dead');
			setLeftButtonLabel('OK');
			setRightButtonLabel('');
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