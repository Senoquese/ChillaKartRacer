package  
{
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	
	/**
	 * Boost
	 * dimensions: 74 x 222
	 * @author Ian Marsh http://eeenmachine.com
	 * 
	 * setBoostPercent(percent:Number)
	 * - percent: Number in the range of 0..100
	 */
	public class Boost extends Sprite
	{
		
		private var _maxMaskHeight:int;
		private var _mask:Sprite;
		
		public function Boost() 
		{
			this.cacheAsBitmap = true;
			_mask = bmask;
			_maxMaskHeight = _mask.height;
			
			setBoostPercent(0);
			ExternalInterface.addCallback('setBoostPercent', setBoostPercent);
			
			ExternalInterface.addCallback('gc', gc);
		}
		
		public function setBoostPercent(percent:Number)
		{
			_mask.height = percent/100 * _maxMaskHeight;
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