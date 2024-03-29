package  
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	import gs.TweenLite;
	
	/**
	 * Dimensions: 469 x 95
	 * @author Ian Marsh http://eeenmachine.com
	 * 
	 * External Interface:
	 * 
	 * setTime(seconds:Number)
	 * setLeftScore(score:Number)
	 * setRightScore(score:Number)
	 */
	public class ScoreTimer extends Sprite
	{
		private var _time:TextField;
		private var _leftScore:TextField;
		private var _rightScore:TextField;
		private var _testTime:int;
		
		public function ScoreTimer() 
		{
			_time = time;
			_leftScore = leftScore;
			_rightScore = rightScore;
			ExternalInterface.addCallback('setTime', setTime);
			ExternalInterface.addCallback('setLeftScore', setLeftScore);
			ExternalInterface.addCallback('setRightScore', setRightScore);
			
			ExternalInterface.addCallback('gc', gc);
			//test();
		}
		
		public function setTime(seconds:Number):void
		{
			var rem:int = int(seconds) % 60;
			_time.text = Math.floor(seconds / 60) + ':' + (rem < 10 ? '0' + rem : rem);
		}
		
		public function setLeftScore(score:Number):void
		{
			_leftScore.text = String(score);
			TweenLite.to(_leftScore, 0.15, { scaleX:1.1, scaleY:1.1, onComplete:function(){TweenLite.to(_leftScore,0.15,{scaleX:1,scaleY:1})} } );
		}
		
		public function setRightScore(score:Number):void
		{
			_rightScore.text = String(score);
			TweenLite.to(_rightScore, 0.15, { scaleX:1.1, scaleY:1.1, onComplete:function(){TweenLite.to(_rightScore,0.15,{scaleX:1,scaleY:1})} } );
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
			if(_testTime % 100 == 0)
				setLeftScore(Math.floor(_testTime / 100));
			if(_testTime % 75 == 0)	
				setRightScore(Math.floor(_testTime / 75));
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