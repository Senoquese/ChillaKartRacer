package  
{
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.net.URLRequest;
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class MainMenuLoader extends Sprite
	{
		var loader:Loader;
		
		public function MainMenuLoader() 
		{
			loader = new Loader();
			addChild(loader);
			loader.load(new URLRequest('MainMenu.swf'));
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, reload);
		}
		
		private function reload(e:Event):void
		{
			trace('MainMenuLoader.reload');
			loader.unload();
			loader.load(new URLRequest('MainMenu.swf'));
		}
	}
	
}