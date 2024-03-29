package  
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.text.*;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	
	/**
	* ColorPicker dimensions:369x277
	* ---- Expected C++ Functions ----
	* colorPick(r, b, g);
	* - rgb components are 0-255.
	* closeColorPicker();
	*/
	public class ColorPicker extends Sprite
	{
		private var _colorWheel:Bitmap;
		private var _colorData:BitmapData;
		private var _colorCont:Sprite;
		private var _cursor:Sprite;
		private var _lastColor:int;
		private var _sampling:Boolean;
		
		public function ColorPicker()
		{
			init();
		}
		
		private function init()
		{
			_colorData = new ColorWheel(0, 0);
			_colorWheel = new Bitmap(_colorData);
			_colorCont = new Sprite();
			_colorCont.addChild(_colorWheel);
			_cursor = new Cursor();
			_colorCont.addChild(_cursor);
			addChild(_colorCont);
			_colorCont.x = 18;
			_colorCont.y = 9;
			_cursor.visible = false;
			_sampling = false;
			_colorCont.addEventListener(Event.ENTER_FRAME, sample);
			_colorCont.addEventListener(MouseEvent.MOUSE_DOWN, startSampling);
			_colorCont.addEventListener(MouseEvent.MOUSE_UP, stopSampling);
			close.addEventListener(MouseEvent.CLICK, closePicker);
			
			ExternalInterface.addCallback('gc', gc);
		}

		private function closePicker(e:MouseEvent)
		{
			trace("picker close");
			ExternalInterface.call("closeColorPicker");
		}
		
		private function startSampling(e:MouseEvent)
		{
			trace("start sampling");
			_sampling = true;
		}
		
		private function stopSampling(e:MouseEvent)
		{
			trace("stop sampling");
			_sampling = false;
		}
		
		private function sample(e:Event)
		{
			if (!visible || !_sampling)
				return;
			var c:int = _colorData.getPixel32(_colorCont.mouseX, _colorCont.mouseY);
			if (c == _lastColor)
				return;
			else if (c != 0)
			{
				var a:int = c >> 24 & 0xFF;
				var r:int = c >> 16 & 0xFF;
				var g:int = c >> 8 & 0xFF;
				var b:int = c & 0xFF;
				Rval.text = String(r);
				Gval.text = String(g);
				Bval.text = String(b);
				_cursor.visible = true;
				_cursor.x = _colorCont.mouseX - _cursor.width/2;
				_cursor.y = _colorCont.mouseY - _cursor.height / 2;
				_lastColor = c;
				ExternalInterface.call("colorPick", Number(r), Number(g), Number(b));
			}
			else
			{
				_sampling = false;
				_cursor.visible = false;
				Rval.text = Gval.text = Bval.text = "";
			}
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