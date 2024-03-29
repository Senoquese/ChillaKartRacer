package  
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import gs.TweenLite;
	import flash.external.ExternalInterface;
	
	/**
	* ...
	* @author Ian Marsh
	*/
	public class RosterListItem extends Sprite
	{
		public static var ITEM_HEIGHT:int = 25;
		
		// Stage Instances
		private var _bg:Sprite;
		private var _playerName:TextField;
		private var _score:TextField;
		private var _ping:TextField;
		private var _x1:MovieClip;
		private var _x2:MovieClip;
		private var _x3:MovieClip;
		private var _textMargin:Number;
		
		private var _index:int;
		
		public function RosterListItem() 
		{
			init();
		}
		
		private function init()
		{
			_bg = bg;
			_playerName = playerName;
			_score = score;
			_ping = ping;
			_x1 = x1;
			_x2 = x2;
			_x3 = x3;
			trace(_x1.name);
			trace(_x2.name);
			trace(_x3.name);
			_x1.addEventListener(MouseEvent.CLICK, xClick);
			_x2.addEventListener(MouseEvent.CLICK, xClick);
			_x3.addEventListener(MouseEvent.CLICK, xClick);
			
			_textMargin = _playerName.x;
			this.cacheAsBitmap = true;
		}
		
		private function xClick(e:MouseEvent)
		{
			var x:MovieClip = MovieClip(e.target);
			var option:String;
			if (x == _x1) option = 'amute';
			if (x == _x2) option = 'vmute';
			if (x == _x3) option = 'kick';
			if (x.currentFrame == 1)
			{
				x.gotoAndStop(2);
				ExternalInterface.call('optionEnabled', option);
			}
			else
			{
				x.gotoAndStop(1);
				ExternalInterface.call('optionDisabled', option);
			}
		}
		
		public function setContents(str:String)
		{
			var params:Array = str.split(',');
			_playerName.htmlText = params[0];
			_score.text = params[1];
			_ping.text = params[2];
			_x1.gotoAndStop(parseInt(params[3])+1);
			_x2.gotoAndStop(parseInt(params[4])+1);
			_x3.gotoAndStop(parseInt(params[5])+1);
		}
		
		public function setIndex(index:int)
		{
			_index = index;
			_bg.y = (_index % 2 == 0) ? 0 : -_bg.height / 2;
		}		
		
		public function getIndex():int
		{
			return _index;
		}
	}
	
}