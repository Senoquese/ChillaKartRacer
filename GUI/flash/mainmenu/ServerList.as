package  
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.events.*;
	/**
	* ...
	* @author Ian Marsh
	*/
	public class ServerList extends Sprite
	{	
		public static var MASK_HEIGHT:int = 450;
		private var _startY:int;
		private var _scrollTargetY:Number;
		private var _sliding:Boolean;
		private var _maskHeight:Number;
		private var _selItem:ServerListItem;
		
		public function ServerList() 
		{
			init();
		}
		
		private function init()
		{
			_startY = y;
			_sliding = false;
			_selItem = undefined;
			_scrollTargetY = 0;
		}
		
		public function setMaskHeight(h:Number)
		{
			_maskHeight = h;
		}
		
		public function clearItems()
		{
			while (numChildren > 0)
				removeChildAt(0);
			_selItem = undefined;
			_scrollTargetY = 0;
		}
		
		public function addItem(item:String)
		{
			var newItem:ServerListItem = new ServerListItem();
			var length:int = numChildren;
			newItem.setIndex(length);
			newItem.setContents(item);
			newItem.addEventListener(MouseEvent.CLICK, itemClicked);
			addChild(newItem);
			newItem.y = length * ServerListItem.ITEM_HEIGHT;
		}
		
		/*public function setItem(index:Number, item:String)
		{
			if (getChildAt(index))
			{
				ServerListItem(getChildAt(index)).setContents(item);
			}
		}*/
		
		private function itemClicked(event:MouseEvent):void
		{
			
			if (_selItem)
			{
				_selItem.setHilight(false);
			}
			_selItem = ServerListItem(event.target.parent);
			_selItem.setHilight(true);
			//ServerListItem(event.target.parent).
			trace('selIndex:' + _selItem.getIndex());
			
			dispatchEvent(new ServerListEvent(ServerListEvent.ITEM_SELECT, _selItem));
		}
		
		public function getSelectedIndex():Number
		{
			return Number(_selItem.getIndex());
		}
		
		public function getSelectedItem():ServerListItem
		{
			return _selItem;
		}
		
		public function unSelect():void
		{
			if (_selItem)
			{
				_selItem.setHilight(false);
				_selItem = undefined;
			}
		}
		
		public function scrollUp()
		{
			if (_scrollTargetY + _maskHeight - getChildAt(0).height > 0)
				_scrollTargetY -= getChildAt(0).height;
		}
		
		public function scrollDown()
		{
			
		}
		
		public function scrollTo(percent:Number)
		{
			percent = Math.min(percent, 1);
			percent = Math.max(percent, 0);
			//trace(percent);
			_scrollTargetY = _startY - percent * (height - MASK_HEIGHT);
			
			if (_sliding == false)
			{
				addEventListener(Event.ENTER_FRAME, slide);
			}
		}
		
		private function slide(event:Event)
		{
			y += (_scrollTargetY - y) / 6;
			if (Math.abs(_scrollTargetY - y) < 1)
			{
				_sliding = false;
				removeEventListener(Event.ENTER_FRAME, slide);
			}
		}
		
		public function sortBy(cat:String):void
		{
			var items:Array = new Array();
			while (numChildren > 0)
			{
				items.push(getChildAt(0));
				removeChildAt(0);
			}
			if (_selItem) _selItem.setHilight(false);
			_selItem = undefined;
			switch(cat)
			{
				case 'name':
					items.sortOn('nameVal', Array.DESCENDING);
				break;
				case 'address':
					items.sortOn('addressVal', Array.DESCENDING);
				break;
				case 'map':
					items.sortOn('mapVal', Array.DESCENDING);
				break;
				case 'players':
					items.sortOn('playersVal', Array.NUMERIC);
				break;
				case 'ping':
					items.sortOn('pingVal', Array.NUMERIC | Array.DESCENDING);
				break;
			}
			while (items.length > 0)
			{
				addItem(ServerListItem(items.pop()).getContents());
			}
			scrollTo(0);
		}
	}
	
}