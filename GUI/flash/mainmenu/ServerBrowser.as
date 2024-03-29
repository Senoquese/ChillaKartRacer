package  
{
	import flash.display.AVM1Movie;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	
	/**
	* SWF Dimensions: 600 x 600
	* External Interface
	* 
	* - setTitle(str:String)
	* - setServerNameTitle(str:String)
	* - setAddressTitle(str:String)
	* - setMapTitle(str:String)
	* - setPlayerTitle(str:String)
	* - setPingTitle(str:String)
	* - setEnterAddressTitle(str:String)
	* - setLeftButtonLabel(str:String)
	* - setRightButtonLabel(str:String)
	* - test() // populate with test data
	* 
	* - addItem(str:String)
	* 	str = "serverName,ip,mapName,playerCount,ping"
	* - clearItems()
	* - reSort()	// call when you're done adding items
	* 
	* CALLS
	* - leftButtonClick(selectedIndex:Number, inputText:String)
	* - rightButtonClick(selectedIndex:Number, inputText:String)
	* - closeButtonClick();
	* - customIPChange(str:String)
	* - serverSelected(serverInfo:String);
	* 		serverInfo = "serverName,ip,mapName,playerCount,ping"
	*/
	public class ServerBrowser extends MovieClip 
	{
		// Stage Instances
		private var _title:TextField;
		private var _serverNameTitle:TextField;
		private var _addressTitle:TextField;
		private var _mapTitle:TextField;
		private var _playersTitle:TextField;
		private var _pingTitle:TextField;
		private var _enterAddressTitle:TextField;
		private var _list:ServerList;
		private var _scrollBar:MovieClip;
		private var _scrollTrack:MovieClip;
		private var _scrollDownButton:MovieClip;
		private var _scrollUpButton:MovieClip;
		private var _listMask:MovieClip;
		private var _leftButton:LoadSaveButton;
		private var _rightButton:LoadSaveButton;
		private var _input:TextField;
		private var _curSort:String;
		private var _closeButton:SimpleButton;
		
		public function ServerBrowser() 
		{
			init();
			//test();
		}
		
		private function init()
		{
			_title = title;
			_serverNameTitle = serverNameTitle;
			_addressTitle = addressTitle;
			_mapTitle = mapTitle;
			_playersTitle = playersTitle;
			_pingTitle = pingTitle;
			
			_curSort = 'name';
			
			_pingTitle.addEventListener(MouseEvent.CLICK, titleClicked);
			_playersTitle.addEventListener(MouseEvent.CLICK, titleClicked);
			_mapTitle.addEventListener(MouseEvent.CLICK, titleClicked);
			_addressTitle.addEventListener(MouseEvent.CLICK, titleClicked);
			_serverNameTitle.addEventListener(MouseEvent.CLICK, titleClicked);
			
			_enterAddressTitle = enterAddressTitle;
			_list = list;
			_scrollBar = scrollBar;
			_scrollTrack = scrollTrack;
			_scrollDownButton = scrollDownButton;
			_scrollUpButton = scrollUpButton;
			_listMask = listMask;
			_list.cacheAsBitmap = true;
			_listMask.cacheAsBitmap = true;
			_list.mask = _listMask;
			_input = input;
			_input.addEventListener(Event.CHANGE, inputChanged);
			_rightButton = rightButton;
			_leftButton = leftButton;
			_leftButton.addEventListener(MouseEvent.CLICK, leftButtonClicked);
			_rightButton.addEventListener(MouseEvent.CLICK, rightButtonClicked);
			_closeButton = closeButton;
			_closeButton.addEventListener(MouseEvent.CLICK, closeButtonClicked);
			
			_title.text = '';
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
			
			_list.addEventListener(ServerListEvent.ITEM_SELECT, itemSelected);
			
			ExternalInterface.addCallback('setTitle', setTitle);
			ExternalInterface.addCallback('setServerNameTitle', setServerNameTitle);
			ExternalInterface.addCallback('setAddressTitle', setAddressTitle);
			ExternalInterface.addCallback('setMapTitle', setMapTitle);
			ExternalInterface.addCallback('setPlayersTitle', setPlayersTitle);
			ExternalInterface.addCallback('setPingTitle', setPingTitle);
			ExternalInterface.addCallback('setEnterAddressTitle', setEnterAddressTitle);
			
			ExternalInterface.addCallback('setLeftButtonLabel', setLeftButtonLabel);
			ExternalInterface.addCallback('setRightButtonLabel', setRightButtonLabel);
			
			ExternalInterface.addCallback('reSort', reSort);
			
			ExternalInterface.addCallback('addItem', addItem);
			ExternalInterface.addCallback('clearItems', clearItems);
			
			ExternalInterface.addCallback('test', test);
			ExternalInterface.addCallback('gc', gc);
		}
		
		public function closeButtonClicked(e:MouseEvent):void
		{
			trace("close clicked");
			ExternalInterface.call("closeButtonClick");
		}
		
		public function getCustomServerAddress():String
		{
			return _input.text;
		}
		public function getSelectedServerString():String
		{
			var sli:ServerListItem = _list.getSelectedItem();
			if (sli)
				return sli.getContents();
			else
				return '';
		}
		
		public function reSort():void
		{
			sortBy(_curSort);
		}
		
		public function setTitle(str:String)
		{
			_title.text = str;
		}
		public function setServerNameTitle(str:String)
		{
			_serverNameTitle.text = str;
		}
		public function setAddressTitle(str:String)
		{
			_addressTitle.text = str;
		}
		public function setMapTitle(str:String)
		{
			_mapTitle.text = str;
		}
		public function setPlayersTitle(str:String)
		{
			_playersTitle.text = str;
		}
		public function setPingTitle(str:String)
		{
			_pingTitle.text = str;
		}
		public function setEnterAddressTitle(str:String)
		{
			_enterAddressTitle.text = str;
		}
		
		public function setLeftButtonLabel(str:String):void
		{
			_leftButton.setLabel(str);
		}
		public function setRightButtonLabel(str:String):void
		{
			_rightButton.setLabel(str);
		}
		private function leftButtonClicked(e:MouseEvent):void
		{
			trace('leftButtonClicked');
			ExternalInterface.call('leftButtonClick');
		}
		private function rightButtonClicked(e:MouseEvent):void
		{
			trace('rightButtonClicked');
			ExternalInterface.call('rightButtonClick');
		}
		
		private function inputChanged(e:Event):void
		{
			_list.unSelect();
			_title.text = _input.text;
			trace(_input.text);
			ExternalInterface.call('customIPChange', _input.text);
		}
		
		private function titleClicked(e:Event):void
		{
			switch(e.target)
			{
				case _pingTitle:
					sortBy('ping');
				break;
				case _playersTitle:
					sortBy('players');
				break;
				case _mapTitle:
					sortBy('map');
				break;
				case _addressTitle:
					sortBy('address');
				break;
				case _serverNameTitle:
					sortBy('name');
				break;
			}
		}
		
		// Player name,score,ping,0,0,0
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
			if (_list.getSelectedItem())
				_title.text = '';
			_list.clearItems();
			_scrollBar.visible = false;
			_scrollBar.y = _scrollTrack.y;
			_scrollDownButton.gotoAndStop(1);
			_scrollUpButton.gotoAndStop(1);
			
		}

		public function sortBy(cat:String):void
		{
			_scrollBar.visible = false;
			_scrollBar.y = _scrollTrack.y;
			_scrollDownButton.gotoAndStop(1);
			_scrollUpButton.gotoAndStop(1);
			
			if (_list.getSelectedItem())
				_title.text = '';
			
			_list.sortBy(cat);
			
			clearTitleColors();
			var sortTitle:TextField;
			switch(cat)
			{
				case 'name':
					sortTitle = _serverNameTitle;
				break;
				case 'address':
					sortTitle = _addressTitle;
				break;
				case 'map':
					sortTitle = _mapTitle;
				break;
				case 'players':
					sortTitle = _playersTitle;
				break;
				case 'ping':
					sortTitle = _pingTitle;
				break;
			}
			sortTitle.textColor = 0xB9FD01;
			_curSort = cat;
			
			if (_list.height > _listMask.height)
			{
				_scrollBar.visible = true;
				_scrollDownButton.gotoAndStop(2);
				_scrollUpButton.gotoAndStop(2);
			}
		}
		
		private function clearTitleColors():void
		{
			_playersTitle.textColor = 0xFFFFFF;
			_pingTitle.textColor = 0xFFFFFF;
			_serverNameTitle.textColor = 0xFFFFFF;
			_addressTitle.textColor = 0xFFFFFF;
			_mapTitle.textColor = 0xFFFFFF;
		}
		
		private function itemSelected(e:ServerListEvent):void
		{
			_input.text = '';
			_title.text = e.listItem.getServerName();
	
			var cont:String;
			if (_list.getSelectedItem())
				cont = _list.getSelectedItem().getContents();
			else
				cont = '';
				
			trace(cont);
			ExternalInterface.call('serverSelected', cont);
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
			//setTitle('Little Big Test Server');

			setLeftButtonLabel('Join');
			setRightButtonLabel('Refresh');
			
			var mapNames:Array = ['Spaghetti West', 'Chute Shoot', 'Chill Mountain', 'Champion Circuit', 'Fall Out', 'Tag Bowl'];
			
			for (var i:int = 0; i < 28; i++)
			{
				addItem('Server Name '+i+',255.255.255.'+i+','+mapNames[Math.floor(Math.random()*mapNames.length)]+','+(Math.floor(Math.random()*32))+'/32,'+(Math.floor(Math.random()*300)));
			}
			
			reSort();
			
			/*clearItems();
			
			for (i = 0; i < 8; i++)
			{
				addItem('FF00FF', 'Player2 ' + i + ',' + ((50-i)*10)+','+(50-i)+',0,1,0');
			}
			*/
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