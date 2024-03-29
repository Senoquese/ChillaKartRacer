package  
{
	import flash.display.AVM1Movie;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	
	/**
	* SWF Dimensions: 400x393
	* External Interface
	* 
	* - setTitle(str:String)
	* - enableInput(enabled:Boolean)
	* - setInput(str:String)
	* - getInput():String
	* - setLeftButtonLabel(str:String)
	* - setRightButtonLabel(str:String)
	* - addItem(str:String)
	* - clearItems()
	* 
	* CALLS
	* - LeftButtonClick(selectedIndex:Number, inputText:String)
	* - RightButtonClick(selectedIndex:Number, inputText:String)
	*/
	public class LoadSave extends MovieClip 
	{
		// Stage Instances
		private var _title:TextField;
		private var _input:TextField;
		private var _leftButton:LoadSaveButton;
		private var _rightButton:LoadSaveButton;
		private var _list:LoadSaveList;
		private var _scrollBar:MovieClip;
		private var _scrollTrack:MovieClip;
		private var _scrollDownButton:MovieClip;
		private var _scrollUpButton:MovieClip;
		private var _listMask:MovieClip;
		
		private var _inputEnabled:Boolean;
		
		public function LoadSave() 
		{
			init();
		}
		
		private function init()
		{
			_title = title;
			_input = input;
			_leftButton = leftButton;
			_rightButton = rightButton;
			_list = list;
			_scrollBar = scrollBar;
			_scrollTrack = scrollTrack;
			_scrollDownButton = scrollDownButton;
			_scrollUpButton = scrollUpButton;
			_listMask = listMask;
			
			_scrollBar.visible = false;
			_scrollBar.y = _scrollTrack.y;
			_list.setMaskHeight(_listMask.height);
			_scrollBar.addEventListener(MouseEvent.MOUSE_DOWN, startScrollDrag);
			//_scrollBar.addEventListener(MouseEvent.ROLL_OUT, stopScrollDrag);
			addEventListener(Event.MOUSE_LEAVE, stopScrollDrag);
			_scrollBar.addEventListener(MouseEvent.MOUSE_UP, stopScrollDrag);
			_scrollDownButton.addEventListener(MouseEvent.MOUSE_DOWN, scrollButtonClick);
			_scrollUpButton.addEventListener(MouseEvent.MOUSE_DOWN, scrollButtonClick);
			_scrollDownButton.addEventListener(MouseEvent.MOUSE_UP, scrollButtonUp);
			_scrollUpButton.addEventListener(MouseEvent.MOUSE_UP, scrollButtonUp);
			_scrollDownButton.addEventListener(MouseEvent.ROLL_OUT, scrollButtonUp);
			_scrollUpButton.addEventListener(MouseEvent.ROLL_OUT, scrollButtonUp);
			
			_leftButton.addEventListener(MouseEvent.CLICK, leftButtonClick);
			_rightButton.addEventListener(MouseEvent.CLICK, rightButtonClick);
			
			
			//test();
			
			ExternalInterface.addCallback('setTitle', setTitle);
			ExternalInterface.addCallback('setInput', setInput);
			ExternalInterface.addCallback('getInput', getInput);
			ExternalInterface.addCallback('enableInput', enableInput);
			ExternalInterface.addCallback('setLeftButtonLabel', setLeftButtonLabel);
			ExternalInterface.addCallback('setRightButtonLabel', setRightButtonLabel);
			ExternalInterface.addCallback('addItem', addItem);
			ExternalInterface.addCallback('clearItems', clearItems);
			ExternalInterface.addCallback('gc', gc);
		}
		
		public function setTitle(str:String)
		{
			_title.text = str;
		}
		
		public function setInput(str:String)
		{
			_input.text = str;
		}
		public function getInput():String
		{
			return _input.text;
		}
		public function enableInput(enabled:Boolean)
		{
			_inputEnabled = enabled;
			_input.visible = _inputEnabled;
		}
		
		public function setLeftButtonLabel(str:String)
		{
			_leftButton.setLabel(str);
		}
		public function setRightButtonLabel(str:String)
		{
			_rightButton.setLabel(str);
		}
		
		public function addItem(str:String)
		{
			_list.addItem(str);
			if (_list.height > _listMask.height)
			{
				_scrollBar.visible = true;
				_scrollDownButton.gotoAndStop(2);
				_scrollUpButton.gotoAndStop(2);
			}
		}
		public function clearItems()
		{
			_list.clearItems();
			_scrollBar.visible = false;
			_scrollDownButton.gotoAndStop(1);
			_scrollUpButton.gotoAndStop(1);
		}

		private function scrollButtonClick(event:MouseEvent)
		{
			if (_scrollBar.visible)
			{
				var button:MovieClip = MovieClip(event.target);
				button.gotoAndStop(3);
				if (button == _scrollUpButton)
				{
					_scrollBar.y = Math.max(_scrollTrack.y, _scrollBar.y - (_listMask.height / _list.height) * _scrollTrack.height);
				}
				else
				{
					_scrollBar.y = Math.min(_scrollTrack.y+_scrollTrack.height, _scrollBar.y + (_listMask.height / _list.height) * _scrollTrack.height);
				}
				_list.scrollTo((_scrollBar.y - _scrollTrack.y)/_scrollTrack.height);
			}
		}
		private function scrollButtonUp(event:MouseEvent)
		{
			MovieClip(event.target).gotoAndStop(_scrollBar.visible?2:1);
		}
		
		private function startScrollDrag(event:MouseEvent)
		{
			//_scrollBar.startDrag();
			addEventListener(MouseEvent.MOUSE_MOVE, scrollDrag);
			_scrollBar.gotoAndStop(2);
		}
		private function stopScrollDrag(event:MouseEvent)
		{
			//_scrollBar.stopDrag();
			removeEventListener(MouseEvent.MOUSE_MOVE, scrollDrag);
			_scrollBar.gotoAndStop(1);
		}
		private function scrollDrag(event:MouseEvent)
		{
			_scrollBar.y = event.stageY - _scrollBar.height/2;
			_scrollBar.y = Math.max(_scrollTrack.y, _scrollBar.y);
			_scrollBar.y = Math.min(_scrollTrack.y + _scrollTrack.height, _scrollBar.y);
			
			_list.scrollTo((_scrollBar.y - _scrollTrack.y)/_scrollTrack.height);
			
			if (event.localX < -2*_scrollBar.width || event.localX > 1.5*_scrollBar.width)
				stopScrollDrag(null);
			if (event.stageY < (_scrollTrack.y-4*_scrollBar.height) || event.stageY > _scrollTrack.y + _scrollTrack.height + 2*_scrollBar.height)
				stopScrollDrag(null);
		}
		
		private function leftButtonClick(event:MouseEvent)
		{
			trace('leftButtonClick');
			ExternalInterface.call('LeftButtonClick', _list.getSelectedIndex(), _input.text);
		}
		private function rightButtonClick(event:MouseEvent)
		{
			trace('rightButtonClick');
			ExternalInterface.call('RightButtonClick', _list.getSelectedIndex(), _input.text);
		}
		
		private function test()
		{
			setTitle('Test Title');
			setInput('Test Input');
			setLeftButtonLabel('Button A');
			setRightButtonLabel('Button B');
			
			for (var i:int = 0; i < 50; i++)
			{
				addItem('Test List Item ' + i);
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