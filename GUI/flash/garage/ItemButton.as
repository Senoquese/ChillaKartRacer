package  
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.URLRequest;
	import gs.TweenLite;
	
	public class ItemButton extends Sprite
	{
		private static var FADETIME:Number = 0.25;
		private var _isEmpty:Boolean;
		private var _itemCont:Loader;
		public var _item:Object;
		
		public function ItemButton() 
		{
			this.addEventListener(MouseEvent.ROLL_OVER, over);
			init();
			_itemCont = new Loader();
			addChild(_itemCont);
		}
		
		public function loadItem(item:Object, index:int)
		{
			//ItemPicker.Trace("loading image into Loader:" + _itemCont);
			_item = item;
			_itemCont.load(new URLRequest(_item.iconPath));
			_itemCont.alpha = 1 - (index+1) * 0.2;
			TweenLite.to(_itemCont, FADETIME * 3, { alpha:1 } );
			this.visible = true;
		}
		
		public function over(o:Object = null)
		{
			TweenLite.to(buttonOver, FADETIME, { alpha:1 } );
			TweenLite.to(_itemCont, 0.2, { y:-5, alpha:1 } );
		}
		
		public function out(o:Object = null)
		{
			TweenLite.to(buttonOver, FADETIME, { alpha:0 } );
			TweenLite.to(_itemCont, 0.2, { y:0, alpha:1 } );
		}
		
		public function select()
		{
			TweenLite.to(buttonSelected, FADETIME, { alpha:1 } );
		}
		
		public function unselect()
		{
			TweenLite.to(buttonSelected, FADETIME, { alpha:0 } );
		}
		
		private function init()
		{
			_isEmpty = true;
			buttonOver.alpha = 0;
			buttonSelected.alpha = 0;
			//if(_itemCont.content)
			//	_itemCont.unload();
			this.visible = false;
		}
		
		public function clear()
		{
			init();
		}
		
		private function isEmpty():Boolean
		{
			return _isEmpty;
		}
	}
	
}