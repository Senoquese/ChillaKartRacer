package  
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	
	/**
	 * Dimensions: 256 x 128
	 * QA: Gina Marsh
	 * @author Ian Marsh http://eeenmachine.com
	 * 
	 * External Interface:
	 * 
	 * setTime(seconds:Number)
	 */
	public class GameTimer extends Sprite
	{
		private var _time:TextField;
		private var _testTime:int;
		
		public function GameTimer() 
		{
			_time = time;
			ExternalInterface.addCallback('setTime', setTime);
			
			ExternalInterface.addCallback('gc', gc);
			//test();
		}
		
		public function setTime(seconds:Number):void
		{
			var rem:int = int(seconds) % 60;
			_time.text = Math.floor(seconds / 60) + ':' + (rem < 10 ? '0' + rem : rem);
		}
		
		private function test():void
		{
			_testTime = 0;
			setTime(0);
			addEventListener(Event.ENTER_FRAME, test2);
		}
		
		private function test2(e:Event):void
		{
			setTime(_testTime++);
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