package  
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.text.*;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	import gs.TweenLite;
	
	/**
	* Alert.as
	* dimensions: 196 x 97
	* 
	* External Interface
	* - showMessage(message:String, color:String)
	* - hide()
	*/
	public class Alert extends Sprite
	{
		private var _clip:MovieClip;
		private var _messageText:TextField;
		
		public function Alert() 
		{
			init();
			//TEST();
		}

		private function init()
		{
			trace("Position init...");
			_clip = clip;
			_messageText = clip.messageText;
			_clip.x = -_clip.width;
			visible = false;
			ExternalInterface.addCallback('showMessage', showMessage);
			ExternalInterface.addCallback('hide', hide);
			
			ExternalInterface.addCallback('gc', gc);
		}
		
		private function TEST(event:Event = null)
		{
			if (visible)
			{
				hide();
			}
			else {
				showMessage(new Date().toTimeString(), 'FF00FF');
			}
			
			if (!hasEventListener(MouseEvent.CLICK))
				addEventListener(MouseEvent.CLICK, TEST);
		}
		
		public function showMessage(message:String, color:String)
		{
			_messageText.text = message;
			var tf:TextFormat = _messageText.getTextFormat();
			tf.color = parseInt('0x' + color);
			_messageText.setTextFormat(tf);
			
			visible = true;
			TweenLite.to(_clip, 0.75, { x:0 } );
		}
		
		public function hide()
		{
			//TweenLite.to(_clip, 0.75, { x: -_clip.width, onComplete:hidden } );
		}
		
		public function hidden()
		{
			visible = false;
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