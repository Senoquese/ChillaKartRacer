package  
{
	import flash.display.Sprite;
	import flash.events.*;
	import flash.text.*;
	import gs.TweenLite;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	
	/**
	* Position.as
	* dimensions: 196 x 97
	* 
	* External Interface
	* - setPlace(place:Number)
	* - setPlaces(places:Number)
	* - setLap(lap:Number)
	* - setLaps(laps:Number)
	*/
	public class Position extends Sprite
	{
		
		private var _placeText:TextField;
		private var _placesText:TextField;
		private var _lapText:TextField;
		private var _lapsText:TextField;
		
		public function Position() 
		{
			init();
			//TEST();
		}

		private function init()
		{
			trace("Position init...");
			_placeText = placeText;
			_placesText = placesText;
			_lapText = lapText;
			_lapsText = lapsText;
			
			reset();
			
			ExternalInterface.addCallback('setPlace', setPlace);
			ExternalInterface.addCallback('setPlaces', setPlaces);
			ExternalInterface.addCallback('setLap', setLap);
			ExternalInterface.addCallback('setLaps', setLaps);
			
			ExternalInterface.addCallback('gc', gc);
		}
		
		private function TEST(event:Event = null)
		{
			setPlace(Math.ceil(Math.random()*32));
			setPlaces(32);
			setLap(2);
			setLaps(4);
			
			if (!hasEventListener(MouseEvent.CLICK))
				addEventListener(MouseEvent.CLICK, TEST);
		}
		
		public function reset()
		{
			_placeText.text = _placesText.text = _lapsText.text = '0';
			_lapText.text = 'LAP 0';
		}
		
		public function setPlace(place:Number)
		{
			_placeText.text = place.toString();
			TweenLite.to(_placeText, 0.15, { scaleX:1.1, scaleY:1.1, onComplete:function(){TweenLite.to(_placeText,0.15,{scaleX:1,scaleY:1})} } );
		}
		
		public function setPlaces(places:Number)
		{
			_placesText.text = places.toString();
		}
		
		public function setLap(lap:Number)
		{
			_lapText.text = 'LAP ' + lap.toString();
		}
		
		public function setLaps(laps:Number)
		{
			_lapsText.text = laps.toString();
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