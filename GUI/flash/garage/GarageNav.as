package  
{
	import flash.display.*;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.media.Sound;
	import gs.TweenLite;
	import flash.net.*;
	import flash.media.Sound;
	
	/**
	 * GarageNav ExternalInterface
	 * 
	 * ---- Expected C++ Functions ----
	 * ButtonClick(cat:String, id:String):void
	 * - cat:	Category that the clicked button is in.
	 * - id:	Unique identifier for the clicked button.
	 * 
	 * PlaySoundFromPath
	*/
	public class GarageNav extends Sprite
	{	
		private var _buttonProps:Object;
		private var _testSound:Sound;
		
		public function GarageNav() 
		{
			init();
		}
		
		private function init()
		{
			dotOn.alpha = 0;
			dotOn.x = kartsButton.x;
			
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest("GarageNav.xml");
			loader.addEventListener(Event.COMPLETE, xmlLoaded);
			loader.load(request);
			
			ExternalInterface.addCallback('gc', gc);
		}
		
		private function buttonClicked(e:Event)
		{	
			if (!_buttonProps)
				return;
			trace("clicked:" + e.target.name);
			var obj:Object = _buttonProps[e.target.name];
			var cat:String = obj.cat;
			var id:String = obj.id;
			var sound:String = obj.sound;
			//sound.play();
			trace(e.target.name+":"+cat+", "+id);
			
			// animate
			dotOn.alpha = 0;
			dotOn.y = e.target.y;
			if (id != 'import' && cat != 'exit')
			{
				TweenLite.to(dotOn, 0.5, { alpha:1 } );
			}
			ExternalInterface.call("ButtonClick", cat, id);
			trace("Playing sound:" + sound);
			ExternalInterface.call("PlaySoundFromPath", sound);
		}
		
		private function buttonOver(e:Event)
		{
			var sound:String = "GUI\\flash\\garage\\sounds\\Item_Rollovers.wav"
			//Trace("Playing sound:" + sound);
			ExternalInterface.call("PlaySoundFromPath", sound);
		}
		
		private function xmlLoaded(e:Event)
		{
			var configXml:XML = new XML(URLLoader(e.target).data);
			
			_buttonProps = new Object();
			
			var buttons:XMLList = configXml.descendants('button');
			for (var i:int = 0; i < buttons.length(); i++)
			{
				var b:XML = buttons[i];
				var name:String = b.attribute('name');
				trace("loading button:" + name);
				var obj:Object = new Object();
				obj.cat = b.attribute('cat');
				obj.id = b.attribute('id');
				var sound:String = b.attribute('sound');
				//sound.load(new URLRequest(b.attribute('sound')));
				obj.sound = sound;
				_buttonProps[name] = obj;
				this[name].addEventListener(MouseEvent.CLICK, buttonClicked);
				this[name].addEventListener(MouseEvent.ROLL_OVER, buttonOver);
			}
			
			// Test for item picker
			//var ldr:Loader = new Loader();
			//ldr.load(new URLRequest('icon.png'));
			//this.addChild(ldr);
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