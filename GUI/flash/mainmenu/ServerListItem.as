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
	public class ServerListItem extends Sprite
	{
		public static var ITEM_HEIGHT:int = 25;
		
		// Stage Instances
		private var _bg:Sprite;
		private var _serverName:TextField;
		private var _address:TextField;
		private var _map:TextField;
		private var _players:TextField;
		private var _ping:TextField;
		private var _hilight:MovieClip;
		
		public var pingVal:int;
		public var playersVal:int;
		public var mapVal:String;
		public var addressVal:String;
		public var nameVal:String;
		
		private var _index:int;
		
		public function ServerListItem() 
		{
			init();
		}
		
		private function init()
		{
			_bg = bg;
			_hilight = hilight;
			_serverName = serverName;
			_address = address;
			_map = map;
			_players = players;
			_ping = ping;
			
			_hilight.alpha = 0;
			this.cacheAsBitmap = true;
		}
		
		public function getServerName():String
		{
			return _serverName.text;
		}
		
		public function setContents(str:String)
		{
			var params:Array = str.split(',');
			_serverName.htmlText = params[0];
			_address.text = params[1];
			_map.htmlText = params[2];
			_players.text = params[3];
			_ping.text = params[4];
			
			pingVal = parseInt(_ping.text);
			playersVal = parseInt(_players.text.split('/')[0]);
			mapVal = _map.text;
			addressVal = _address.text;
			nameVal = _serverName.text;
			
			// set ping color
			if (pingVal <= 80) {
				// white
				_ping.textColor = 0x4AF700;
			}
			else if (pingVal <= 150) {
				// yellow
				_ping.textColor = 0xF7DD00;
			}
			else {
				// red
				_ping.textColor = 0xFF0000;
			}
			
		}
		
		public function getContents():String
		{
			return _serverName.text + ',' + _address.text + ',' + _map.text + ',' + _players.text + ',' + _ping.text;
		}
		
		public function setHilight(lit:Boolean):void
		{
			TweenLite.to(_hilight, 0.25, { alpha:lit?0.5:0 } );
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