package  
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.TextField;
	import gs.TweenLite;
	
	/**
	* ...
	* @author Ian Marsh
	*/
	public class LoadSaveListItem extends Sprite
	{
		// Stage Instances
		private var _bg:Sprite;
		private var _label:TextField;
		private var _highlight:MovieClip;
		private var _textMargin:Number;
		
		private var _index:int;
		
		public function LoadSaveListItem() 
		{
			init();
		}
		
		private function init()
		{
			_bg = bg;
			_label = label;
			_highlight = highlight;
			
			_textMargin = _label.x;
			_highlight.visible = false;
			this.cacheAsBitmap = true;
		}
		
		public function setHighlight(lit:Boolean)
		{
			_highlight.visible = lit;
			if (lit)
			{
				_highlight.alpha = 0;
				TweenLite.to(_highlight, 1, { alpha:1 } );
				TweenLite.to(_label, 0.5, { x:2*_textMargin } );
			}
			else
			{
				TweenLite.killTweensOf(_label);
				_label.x = _textMargin;
			}
		}
		
		public function setLabel(str:String)
		{
			_label.text = str;
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