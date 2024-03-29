package  
{
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.text.TextField;
	
	/**
	* ...
	* @author Ian Marsh
	*/
	public class LoadSaveButton extends MovieClip
	{
		// Stage Instances
		private var _label:TextField;
		
		public function LoadSaveButton() 
		{
			init();
		}
		
		private function init()
		{
			_label = label;
			
			addEventListener(MouseEvent.ROLL_OVER, onMouseOver);
			addEventListener(MouseEvent.ROLL_OUT, onMouseOut);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		public function setLabel(str:String)
		{
			_label.text = str;
		}
		
		private function onMouseOver(event:MouseEvent)
		{
			gotoAndStop(2);
		}
		
		private function onMouseOut(event:MouseEvent)
		{
			gotoAndStop(1);
		}
		
		private function onMouseDown(event:MouseEvent)
		{
			gotoAndStop(3);
		}
		
		private function onMouseUp(event:MouseEvent)
		{
			gotoAndStop(2);
		}
	}
	
}