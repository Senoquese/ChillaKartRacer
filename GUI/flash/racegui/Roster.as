package  
{
	import flash.display.AVM1Movie;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	
	/**
	* SWF Dimensions: 600 x 600
	* External Interface
	* 
	* - setTitle(str:String)
	* - setPlayerTitle(str:String)
	* - setScoreTitle(str:String)
	* - setPingTitle(str:String)
	* - addItem(color:String, str:String)
	* 	color = FFFFFF
	* 	str = "name,score,ping,0,1,0"
	* 	example: "KickMe AMuteMe VMuteMe,-100,999,1,1,1"
	* - setItem(index:Number, color:String, contents:String)
	* - clearItems()
	* ExternalInterface.call('optionEnabled', option);
	* ExternalInterface.call('optionDisabled', option);
	* 	option = 'amute', 'vmute', 'kick'
	* 
	* CALLS
	* - LeftButtonClick(selectedIndex:Number, inputText:String)
	* - RightButtonClick(selectedIndex:Number, inputText:String)
	*/
	public class Roster extends MovieClip 
	{
		// Stage Instances
		private var _title:TextField;
		private var _playerTitle:TextField;
		private var _scoreTitle:TextField;
		private var _pingTitle:TextField;
		private var _list:RosterList;
		private var _scrollBar:MovieClip;
		private var _scrollTrack:MovieClip;
		private var _scrollDownButton:MovieClip;
		private var _scrollUpButton:MovieClip;
		private var _listMask:MovieClip;
		
		public function Roster() 
		{
			init();
			//test();
		}
		
		private function init()
		{
			_title = title;
			_playerTitle = playerTitle;
			_scoreTitle = scoreTitle;
			_pingTitle = pingTitle;
			_list = list;
			_scrollBar = scrollBar;
			_scrollTrack = scrollTrack;
			_scrollDownButton = scrollDownButton;
			_scrollUpButton = scrollUpButton;
			_listMask = listMask;
			_list.cacheAsBitmap = true;
			_listMask.cacheAsBitmap = true;
			_list.mask = _listMask;
			
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
			
			ExternalInterface.addCallback('setTitle', setTitle);
			ExternalInterface.addCallback('setPlayerTitle', setPlayerTitle);
			ExternalInterface.addCallback('setScoreTitle', setScoreTitle);
			ExternalInterface.addCallback('setPingTitle', setPingTitle);
			ExternalInterface.addCallback('addItem', addItem);
			ExternalInterface.addCallback('clearItems', clearItems);
			
			ExternalInterface.addCallback('gc', gc);
		}
		
		public function setTitle(str:String)
		{
			_title.text = str;
		}
		public function setPlayerTitle(str:String)
		{
			_playerTitle.text = str;
		}
		public function setScoreTitle(str:String)
		{
			_scoreTitle.text = str;
		}
		public function setPingTitle(str:String)
		{
			_pingTitle.text = str;
		}
		
		// Player name,score,ping,0,0,0
		public function addItem(color:String, str:String)
		{
			str = "<font color='#" + color + "'>" + str;
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
		
		private function test()
		{
			setTitle('Little Big Test Server');

			for (var i:int = 0; i < 8; i++)
			{
				addItem('FF00FF', 'Player ' + i + ',' + ((50-i)*10)+','+(50-i)+',0,1,0');
			}
			
			clearItems();
			
			for (var i:int = 0; i < 8; i++)
			{
				addItem('FF00FF', 'Player2 ' + i + ',' + ((50-i)*10)+','+(50-i)+',0,1,0');
			}
			
			//setItem(17, 'FF0000', 'Lucky Number 17,999,0,1,1,1');
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