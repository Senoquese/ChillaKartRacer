﻿package{	/**	 * ExternalInterface	 * 	 * loadMap(imageUrl:String, mapWidth:Number, mapHeight:Number):void	 * - imageUrl:	The relative path to the mini map image.	 * - mapWidth:	The width of the map in world units.	 * - mapHeight:	The height of the map in world units.	 * 	 * setPlayerPosition(x:Number, y:Number, rot:Number, zoom:Number):void	 * - x:		The X position of the player in world units assuming the	 * 			origin is in the center of the map.	 * - y:		The Z position of the player in world units.	 * - rot:	The rotation in degrees of the player. 0=North, 90=East.	 * - zoom:	The amount to zoom out the map 0 = 1x, 100 = 2x.	 * 	 * setObjectPosition(type:String, id:String, x:Number, y:Number, rot:Number):void	 * - type:	The type of object as defined in the MiniMap XML.	 * - id:	The unique identifier among this type for the object.	 * - x:		The X position of the object in world units.	 * - y:		The Z position of the player in world units.	 * - rot:	The rotation in degrees of the object.	 * 	 * removeObject(type:String, id:String):void	 * - type:	The type of the object to remove.	 * - id:	The unique identifier of the object of the type to remove.	 * 	 * removeObjectsOfType(type:String):void	 * - type:	The type of the objects to remove.	 * 	 * removeAllObjects():void	 * - Removes all objects from the MiniMap. Automatically called when 	 *   loading a map.	 **/	import flash.display.*;	import flash.events.*;	import flash.geom.Point;	import flash.geom.Rectangle;	import flash.net.*;	import flash.external.ExternalInterface;		public class MiniMap extends Sprite	{		var _configUrl:String = 'MiniMap.xml';		var _configXml:XML;		var _mapWidth:Number;		var _mapHeight:Number;		var _mapCont:Sprite;		var _map:Loader;		var _dradisCont:Sprite;		var _locator:Loader;		var _overlay:Loader;		var _background:Loader;		var _mask:Loader;		var _dradisImages:Object;		var _dradis:Object;		var _lastRot:Number;		var _testRot:Number;				var _playerX:Number;		var _playerY:Number;		var _playerRot:Number;		var _playerZoom:Number;				var glocpos:Point;				function MiniMap()		{			var urlReq:URLRequest = new URLRequest(_configUrl);			var urlLoader:URLLoader = new URLLoader();			urlLoader.addEventListener(Event.COMPLETE, xmlLoaded, false, 0, true);			urlLoader.load(urlReq);						_background = new Loader();			addChild(_background);			_mapCont = new Sprite();			addChild(_mapCont);			_map = new Loader();			_map.contentLoaderInfo.addEventListener(Event.COMPLETE, mapLoaded, false, 0, true);			_mapCont.addChild(_map);			_dradisCont = new Sprite();			_mapCont.addChild(_dradisCont);			_locator = new Loader();			_locator.contentLoaderInfo.addEventListener(Event.COMPLETE, positionLocator, false, 0, true);			_mapCont.addChild(_locator);			_overlay = new Loader();			addChild(_overlay);			_mask = new Loader();			_mask.contentLoaderInfo.addEventListener(Event.COMPLETE, maskLoaded, false, 0, true);			addChild(_mask);						_dradisImages = new Object();			_dradis = new Object();						ExternalInterface.addCallback("loadMap", 			loadMap);			ExternalInterface.addCallback("setPlayerPosition", 	setPlayerPosition);			ExternalInterface.addCallback("setObjectPosition", 	setObjectPosition);			ExternalInterface.addCallback("removeObject", 		removeObject);			ExternalInterface.addCallback("removeObjectsOfType",removeObjectsOfType);			ExternalInterface.addCallback("removeAllObjects",	removeAllObjects);						ExternalInterface.addCallback('gc', gc);		}				private function Trace(str:String):void		{			ExternalInterface.call('Trace', str);		}				public function loadMap(imageUrl:String, mapWidth:Number, mapHeight:Number):void		{			// remove any existing objects			removeAllObjects();						// load map			Trace("loading map:" + imageUrl);			_mapWidth = mapWidth;			_mapHeight = mapHeight;			Trace("width:" + _mapWidth + ", height:" + _mapHeight);			_map.load(new URLRequest(imageUrl));		}				private function renderMap(e:Event)		{			_mapCont.x = _mapCont.y = 0;			_locator.rotation = _playerRot;						//_locator.x = (_map.width/2 + _playerX / (_mapWidth/2) * _map.width/2);			//_locator.y = (_map.height/2 + _playerY / (_mapHeight/2) * _map.height/2);						_locator.x = (_map.width/2 + _playerX / (_mapWidth/2) * _map.width/2);			_locator.y = (_map.height/2 + _playerY / (_mapHeight/2) * _map.height/2);			_mapCont.rotation = -_playerRot;							_mapCont.scaleX = _mapCont.scaleY = 1 - _playerZoom / 100 * 0.5;							glocpos = _mapCont.localToGlobal(new Point(_locator.x, _locator.y));			_mapCont.x = (94 - glocpos.x);			_mapCont.y = (94 - glocpos.y);			_lastRot = _playerRot;		}				public function setPlayerPosition(x:Number, y:Number, rot:Number, zoom:Number):void		{			_playerX = x;			_playerY = y;			_playerRot = rot;			_playerZoom = zoom;		}				public function setObjectPosition(type:String, id:String, x:Number, y:Number, rot:Number):void		{						// type exists?			if (_dradis[type] == undefined)			{				_dradis[type] = new Object();			}						// id exists?			if (_dradis[type][id] == undefined)			{				var contact:Loader = new Loader();				contact.load(new URLRequest(_dradisImages[type]));				_mapCont.addChildAt(contact, 1);				_dradis[type][id] = contact;			}						var o:Loader = _dradis[type][id];			o.visible = true;						// id positioned?			if (o.width > 0 && o.getChildAt(0).x == 0)			{				o.getChildAt(0).x = -o.width / 2;				o.getChildAt(0).y = -o.height / 2;			}						// position object			o.x = (_map.width/2 + x / (_mapWidth/2) * _map.width/2);			o.y = (_map.height/2 + y / (_mapHeight/2) * _map.height/2);			o.rotation = rot;		}				public function removeObject(type:String, id:String):void		{			Trace("Attempting to remove object:" + type + ", " + id);			if (type && id && _dradis)			{				if (_dradis[type])				{					if (_dradis[type][id])					{						Trace("Removing object:" + _dradis[type][id] + " from:"+_mapCont+" at index:"+_mapCont.getChildIndex(_dradis[type][id]));						_dradis[type][id].visible = false;						//(_mapCont.getChildIndex(_dradis[type][id]) > -1)						//_mapCont.removeChild(_dradis[type][id]);					}				}			}			Trace("Done Attempting to remove object:" + type + ", " + id);						/*			if (!type || !id)			{				return;			}			if (type.length == 0 || id.length == 0)			{				return;			}			if (!_dradis)			{				return;			}			var toast:Loader = Loader(_dradis[type][id]);			if (!toast)			{				return;			}			if (!_mapCont || !_dradis)			{				return;			}			if (_mapCont.getChildIndex(toast) >= 0)			{				_mapCont.removeChild(toast);			}			_dradis[type][id] = undefined;			*/		}				public function removeObjectsOfType(type:String):void		{			var id:String;			for (id in _dradis[type])			{				Trace("Attempting to remove id:" + id);				if(type && id) {					Trace("Removing id:" + id);					removeObject(type, id);				}			}		}				public function removeAllObjects():void		{			Trace("MiniMap.removeAllObjects()");			//_dradis = new Object();						var type:String;			for (type in _dradis)			{				Trace("attempting to remove type:" + type);				if (type) {					Trace("removing type:" + type);					removeObjectsOfType(type);				}			}		}				private function mapLoaded(e:Event)		{			Trace("map done loading");			Bitmap(_map.getChildAt(0)).smoothing = true;			_testRot = 0;			//this.addEventListener(Event.ENTER_FRAME, test);												this.addEventListener(Event.ENTER_FRAME, renderMap, false, 0, true);			ExternalInterface.call("MapLoaded");		}				private function maskLoaded(e:Event)		{			trace("mask done loading");			_mapCont.cacheAsBitmap = true;			_mask.cacheAsBitmap = true;			_mapCont.mask = _mask;			trace("mapCont.mask:" + _mapCont.mask);		}				private function positionLocator(e:Event)		{			Trace("locator done loading");			_locator.getChildAt(0).x -= _locator.getChildAt(0).width/2;			_locator.getChildAt(0).y -= _locator.getChildAt(0).height/2;		}				private function test(e:Event)		{			setPlayerPosition(0 + 800 * Math.sin(_testRot), 0 + 300 * Math.cos(_testRot), _testRot * 200, Math.sin(_testRot)*50+50);			setObjectPosition('kart', '0', 0 + 700 * Math.sin(_testRot), 0 + 250 * Math.cos(_testRot), _testRot * 200);			setObjectPosition('kart', '1', 0 + 600 * Math.sin(_testRot), 0 + 200 * Math.cos(_testRot), _testRot * 200);			_testRot += 0.01;		}				private function xmlLoaded(e:Event)		{			trace("xml done loading.");			_configXml = new XML(URLLoader(e.target).data);						// load player indicator			var locatorNode:XML = XMLList(_configXml.descendants('locator'))[0];			var url:String = locatorNode.attribute('img');			trace("loading locator:" + _locator);			_locator.load(new URLRequest(url));						// load background			var bgNode:XML = XMLList(_configXml.descendants('background'))[0];			url = bgNode.attribute('img');			trace("loading bg:" + url);			_background.load(new URLRequest(url));						// load overlay			var overlayNode:XML = XMLList(_configXml.descendants('overlay'))[0];			url = overlayNode.attribute('img');			trace("loading overlay:" + url);			_overlay.load(new URLRequest(url));						// load mask			var maskNode:XML = XMLList(_configXml.descendants('mask'))[0];			url = maskNode.attribute('img');			trace("loading mask:" + url);			_mask.load(new URLRequest(url));						// load trackables			var trackablesNode:XML = XMLList(_configXml.descendants('trackables'))[0];			var trackablesList:XMLList = trackablesNode.children();			for (var i:int = 0; i < trackablesList.length(); i++)			{				var trackable:XML = trackablesList[i];				_dradisImages[trackable.attribute('type')] = trackable.attribute('img')			}						// test			//loadMap("mmaps/champion_circuit_mm.png", 2000, 1000);						ExternalInterface.call("XMLLoaded");		}				private function gc():void		{			   // unsupported hack that seems to force a full GC			   try			   {					  var lc1:LocalConnection = new LocalConnection();					  var lc2:LocalConnection = new LocalConnection();					  lc1.connect('name');					  lc2.connect('name');			   }			   catch (e:Error)			   {			   }		}	}}