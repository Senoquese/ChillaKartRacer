/**
 * Dimensions: 600x600
 * External Interface
 * setStandings(standings:String)
 * - standings: comma seperated string of players in order of standings
 */

package  
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	
	public class Standings extends Sprite
	{
		private var _first:TextField;
		private var _second:TextField;
		private var _third:TextField;
		private var _col1:TextField;
		private var _col2:TextField;
		private var _col3:TextField;
		
		public function Standings() 
		{
			_first = first;
			_second = second;
			_third = third;
			_col1 = col1;
			_col2 = col2;
			_col3 = col3;
			
			_first.text = _second.text = _third.text = _col1.text = _col2.text = _col3.text = '';
			
			ExternalInterface.addCallback('setStandings', setStandings);
			
			ExternalInterface.addCallback('gc', gc);
			//test();
		}
		
		public function setStandings(standings:String)
		{
			_first.text = _second.text = _third.text = _col1.text = _col2.text = _col3.text = '';
			var standArr:Array = standings.split(',');
			_first.text = standArr[0];
			if(standArr.length > 1)
				_second.text = standArr[1];
			if(standArr.length > 2)
				_third.text = standArr[2];
			
			var i:int;
			for (i = 3; i < 13 && i < standArr.length; i++)
			{
				_col1.appendText((i + 1) + '. ' + standArr[i] + '\n');
			}
			
			for (i = 13; i < 23 && i < standArr.length; i++)
			{
				_col2.appendText((i + 1) + '. ' + standArr[i] + '\n');
			}
			
			for (i = 23; i < 33 && i < standArr.length; i++)
			{
				_col3.appendText((i + 1) + '. ' + standArr[i] + '\n');
			}
		}
		
		private function test()
		{
			var arr:Array = new Array();
			for (var i:int = 0; i < 32; i++)
			{
				arr.push('Player_' + (i + 1));
			}
			setStandings(arr.join(','));
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