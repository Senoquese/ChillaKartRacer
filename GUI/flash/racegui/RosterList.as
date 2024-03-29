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
	public class RosterList extends Sprite
	{	
		public static var MASK_HEIGHT:int = 525;
		private var _startY:int;
		private var _scrollTargetY:Number;
		private var _sliding:Boolean;
		private var _maskHeight:Number;
		private var _selIndex:int;
		
		public function RosterList() 
		{
			init();
		}
		
		private function init()
		{
			_startY = y;
			_sliding = false;
			_selIndex = -1;
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
			_selIndex = -1;
			_scrollTargetY = 0;
		}
		
		public function addItem(item:String)
		{
			var newItem:RosterListItem = new RosterListItem();
			var length:int = numChildren;
			newItem.setIndex(length);
			newItem.setContents(item);
			//newItem.addEventListener(MouseEvent.CLICK, itemClicked);
			addChild(newItem);
			newItem.y = length * RosterListItem.ITEM_HEIGHT;
		}
		
		public function setItem(index:Number, item:String)
		{
			if (getChildAt(index))
			{
				RosterListItem(getChildAt(index)).setContents(item);
			}
		}
		
		private function itemClicked(event:MouseEvent)
		{
			
			if (_selIndex > -1)
			{
			}
			_selIndex = RosterListItem(event.target.parent).getIndex();
			trace('selIndex:' + _selIndex);
		}
		
		public function getSelectedIndex():Number
		{
			return Number(_selIndex);
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
	}
	
}