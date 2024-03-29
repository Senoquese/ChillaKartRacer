package  
{
	import flash.display.*;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.*;
	import flash.external.ExternalInterface;
	import gs.TweenLite;
	import flash.net.LocalConnection;
	
	/**
	* Movie Dimensions: 308 x 600.
	* ItemPicker External Interface
	* 
	* SwitchCategory(category:String)
	* - category:	The category of items to browse.
	*/
	public class ItemPicker extends Sprite
	{
	
		private static var PAGE_SIZE:int = 12;
		private static var NUM_BUCKETS:int = 6;
		private static var BUCKET_SPACING = 6;
		private static var BUTTON_ROWS = 4;
		private static var BUTTON_COLS = 3;
		private static var NUM_BUTTONS = BUTTON_ROWS * BUTTON_COLS;
		
		private var _buttons:Array;
		private var _selButton:ItemButton;
		private var _items:Array;
		private var _itemsToLoad:int;
		private var _querying:Boolean;
		private var _buckets:Array;
		private var _inited:Boolean;
		private var _query:Object;
		
		private var _curCategory:String;
		private var _equippedIndex:int;
		private var _equippedColors:String;
		private var _equippedColorArr:Array;
		private var _itemOffset:int;
		private var _totalItemCount:int;
		
		private var _paintSounds:Array;
		
		public function ItemPicker() 
		{
			Trace("Constructor Start");
			_inited = false;
			this.visible = false;
						
			ExternalInterface.addCallback("SwitchCategory", SwitchCategory);
			ExternalInterface.addCallback("SetCustomItem", SetCustomItem);
			ExternalInterface.addCallback("SetBucketColor", SetBucketColor);
			
			ExternalInterface.addCallback('gc', gc);
			
			Trace("Constructor End");
		}
		
		private function init()
		{
			Trace("Init Start");
			createBuckets();
			initButtons();
			bucket_select.visible = false;
			_items = new Array();
			
			_paintSounds = new Array();
			_paintSounds.push("GUI\\flash\\garage\\sounds\\Paint_1.wav");
			_paintSounds.push("GUI\\flash\\garage\\sounds\\Paint_2.wav");
			_paintSounds.push("GUI\\flash\\garage\\sounds\\Paint_3.wav");
			
			this.visible = true;
			this.alpha = 0;
			TweenLite.to(this, 0.5, { alpha:1 } );
			this.addEventListener(Event.ENTER_FRAME, checkQuery);
			_inited = true;
			Trace("Init End");
		}
		
		public static function Trace(msg:String)
		{
			ExternalInterface.call("Trace", msg);
			trace(msg);
		}
		
		private function SwitchCategory(type:String, count:Number, equippedIndex:Number, equippedColors:String)
		{
			if (!_inited)
			{
				init();
			}
			Trace("INIT CATEGORY START:"+type+", "+count+", "+equippedIndex+", "+equippedColors);
			/*
			if (_curCategory == type)
			{
				Trace("Already in category:" + type);
				return;
			}
			*/
			
			// set Category
			_curCategory = type;
			_totalItemCount = count;
			title.text = type;
			_equippedIndex = Math.floor(equippedIndex);
			_equippedColors = equippedColors;
			
			// TODO: make a function to do this
			var split:Array = _equippedColors.split(';');
			Trace((split.length-1) + " equipped colors.");
			_equippedColorArr = new Array(split.length - 1);
			for (var i:int = 0; i < split.length-1; i++)
			{
				//Trace("Filling bucket " + i + ": 0x" + split[i]);
				//fillBucket(i, parseInt('0x' + split[i]));
				_equippedColorArr[i] = parseInt('0x' + split[i]);
			}
			
			// Make the query
			var page:int = Math.floor(equippedIndex / NUM_BUTTONS);
			var q:Object = { type:_curCategory, offset:Number(page * NUM_BUTTONS), maxResults:Number(NUM_BUTTONS) };
			makeQuery(q);
			Trace("DONE INITING CATEGORY");
		}

		private function makeQuery(query:Object)
		{
			// Make the query
			Trace("QUERY...");
			Trace("query offset:" + query.offset);
			_itemsToLoad = Math.min(_totalItemCount-query.offset, NUM_BUTTONS);
			Trace("_itemsToLoad:" + _itemsToLoad);
			if (_itemsToLoad <= 0)
			{
				return;
			}
			_selButton = undefined;
			
			_querying = true;
			clearItems();
			// toggle page arrows
			_itemOffset = query.offset;
			pageText.text = (Math.floor(_itemOffset/NUM_BUTTONS)+1) + ' of ' + (Math.ceil(_totalItemCount/NUM_BUTTONS));
			pageLeft.visible = _itemOffset > 0;
			pageRight.visible = _totalItemCount - _itemOffset > NUM_BUTTONS;
			_query = query;
			//this.addEventListener(Event.ENTER_FRAME, checkQuery);
		}
		
		private function checkQuery(e:Event)
		{
			if (_query)
			{
				ExternalInterface.call("QueryCustomItems", _query.type, _query.offset, _query.maxResults);
				_query = undefined;
				//this.removeEventListener(Event.ENTER_FRAME, checkQuery);
			}
			else
			{
				if (itemName.textWidth > 270)
				{
					itemName.x -= 2;
					if (itemName.x + itemName.textWidth < 14)
					{
						itemName.x = 290;
					}
				}
			}
		}
		
		private function pageLeftClick(e:Event)
		{
			Trace("Page left click.");
			var q:Object = { type:_curCategory, offset:Number(_itemOffset - NUM_BUTTONS), maxResults:Number(NUM_BUTTONS) };
			Trace("type:" + q.type + ", offset:" + q.offset + ", maxResults:" + q.maxResults);
			var sound:String = "GUI\\flash\\garage\\sounds\\Arrow_Clicks.wav"
			Trace("Playing sound:" + sound);
			ExternalInterface.call("PlaySoundFromPath", sound);
			makeQuery(q);
		}
		
		private function pageRightClick(e:Event)
		{
			Trace("Page right click.");
			var q:Object = { type:_curCategory, offset:Number(_itemOffset + NUM_BUTTONS), maxResults:Number(NUM_BUTTONS) };
			Trace("type:" + q.type + ", offset:" + q.offset + ", maxResults:" + q.maxResults);
			var sound:String = "GUI\\flash\\garage\\sounds\\Arrow_Clicks.wav"
			Trace("Playing sound:" + sound);
			ExternalInterface.call("PlaySoundFromPath", sound);
			makeQuery(q);
		}
		
		private function initButtons()
		{
			_buttons = new Array(NUM_BUTTONS);
			for (var i:int = 0; i < NUM_BUTTONS; i++)
			{
				var butt:ItemButton = new ItemButton();
				buttonGuide.addChild(butt);
				butt.addEventListener(MouseEvent.MOUSE_OVER, this.buttonOver);
				butt.addEventListener(MouseEvent.MOUSE_OUT, this.buttonOut);
				butt.addEventListener(MouseEvent.CLICK, this.buttonClick);
				butt.x = i%BUTTON_COLS * butt.width;
				butt.y = Math.floor(i / BUTTON_COLS) * butt.height;
				trace("new button at " + butt.x + ", " + butt.y);
				_buttons[i] = butt;
			}
			pageLeft.addEventListener(MouseEvent.MOUSE_DOWN, this.pageLeftClick);
			pageRight.addEventListener(MouseEvent.MOUSE_DOWN, this.pageRightClick);
		}
		
		private function clearButtons()
		{
			for (var i:int = 0; i < _buttons.length; i++)
			{
				ItemButton(_buttons[i]).clear();
			}
			clearBuckets();
			bucket_select.visible = false;
			itemName.text = '';
		}
		
		private function buttonOver(me:Event)
		{
			Trace("buttonOver:" + me.target);
			var butt:ItemButton = ItemButton(me.target.parent);
			butt.over();
			setItemText(butt._item);
			var sound:String = "GUI\\flash\\garage\\sounds\\Item_Rollovers.wav"
			Trace("Playing sound:" + sound);
			ExternalInterface.call("PlaySoundFromPath", sound);
		}
		
		private function buttonOut(me:Event)
		{
			var butt:ItemButton = ItemButton(me.target.parent);
			butt.out();
			if (_selButton)
			{
				setItemText(_selButton._item);
			}
			else
			{
				setItemText(null);
			}
		}
		
		private function buttonClick(me:Event)
		{
			var butt:ItemButton = ItemButton(me.target.parent);
			if (_selButton)
			{
				//Trace("unselecting button:" + _selButton);
				_selButton.unselect();
			}
			butt.select();
			setItem(butt._item);
			_selButton = butt;
			var sound:String = "GUI\\flash\\garage\\sounds\\Item_Clicks.wav"
			Trace("Playing sound:" + sound);
			ExternalInterface.call("PlaySoundFromPath", sound);
		}
		
		private function clearItems()
		{
			_items = new Array();
		}
		
		public function SetCustomItem(name:String, iconPath:String, colors:String, description:String, author:String)
		{
			//return;
			Trace("Setting custom item "+_itemsToLoad+":" + name + ", " + colors + ", " + description + ", " + author);
			if (!_querying)
			{
				Trace("Abort custom item, not querying");
				return;
			}
			
			var item:Object = { type:_curCategory, name:name, iconPath:iconPath, colors:colors, desc:description, author:author };
			_items.push(item);
			_itemsToLoad--;
			//Trace(_itemsToLoad + " items left to load...");
			_querying = _itemsToLoad > 0;
			if (!_querying)
			{
				Trace("Query complete");
				doneQuerying();
			}
		}
		
		private function doneQuerying()
		{
			// load up the buttons
			clearButtons();
			//Trace("buttons:" + _buttons + ", length:" + _buttons.length);
			for (var i:int = 0; i < NUM_BUTTONS && i < _totalItemCount - _itemOffset; i++)
			{
				Trace("Loading " + i + ":" + _items[i].iconPath);
				ItemButton(_buttons[i]).loadItem(_items[i], i);
			}
			
			// select equipped items
			if (_equippedIndex >= _itemOffset && _equippedIndex < _itemOffset + NUM_BUTTONS)
			{
				Trace("Equipped index:" + _equippedIndex);
				Trace("Selected equipped button:" + (_equippedIndex % NUM_BUTTONS));
				_selButton = _buttons[_equippedIndex % NUM_BUTTONS];
				_selButton.select();
				Trace("Loading buckets from array:" + _equippedColorArr);
				loadBucketsFromArray(_equippedColorArr);
				setItemText(_selButton._item);
			}
			Trace("BUTTONS LOADED");
		}
		
		private function setItemText(item:Object)
		{
			var text:String = item == null ? '' : item.name + ' - ' + item.desc + ' - made by ' + item.author;
			itemName.x = 15;
			if (text.indexOf('00None') > -1)
				itemName.text = '';
			else
				itemName.text = text;
		}
		
		private function setItem(item:Object)
		{
			Trace("Colors:" + item.colors);
			loadBuckets(item.colors);
			//ItemSelected(string type, string name)
			ExternalInterface.call("ItemSelected", item.type, item.name);
		}
		
		private function createBuckets()
		{
			_buckets = new Array();
			for (var i:int = 0; i < NUM_BUCKETS; i++)
			{
				var bucketCont:Sprite = new Sprite();
				bucketCont.addChild(new Sprite());
				var b:Sprite = new Bucket();
				b.name = 'bucket';
				bucketCont.addChild(b);
				bucketGuide.addChild(bucketCont);
				bucketCont.x = i * (bucketCont.width + BUCKET_SPACING);
				bucketCont.visible = false;
				bucketCont.addEventListener(MouseEvent.CLICK, bucketClicked);
				_buckets[i] = bucketCont;
			}
			bucket_select.y = bucketGuide.y;
		}
		
		private function bucketClicked(e:Event)
		{
			Trace("Bucket Clicked");
			var index:int = _buckets.indexOf(e.target.parent);
			Trace("Color Selected:" + index);
			bucket_select.x = _buckets[index].x + bucketGuide.x;
			bucket_select.visible = true;
			ExternalInterface.call("BucketClicked", Number(index));
			var sound:String = _paintSounds[Math.floor(Math.random() * _paintSounds.length)];
			Trace("Playing sound:" + sound);
			ExternalInterface.call("PlaySoundFromPath", sound);
		}
		
		private function clearBuckets()
		{
			for (var i:int = 0; i < _buckets.length; i++)
			{
				_buckets[i].visible = false;
			}
			bucket_select.visible = false;
		}
		
		private function loadBuckets(colors:String)
		{
			clearBuckets();
			if (colors.length == 0)
				return;
			Trace("colorStr:" + colors);
			var split:Array = colors.split(';');
			Trace(split.length + " colors.");
			_equippedColorArr = new Array(split.length - 1);
			for (var i:int = 0; i < split.length-1; i++)
			{
				Trace("Filling bucket " + i + ": 0x" + split[i]);
				fillBucket(i, parseInt('0x' + split[i]));
				_equippedColorArr[i] = parseInt('0x' + split[i]);
			}
		}
		
		private function loadBucketsFromArray(colors:Array)
		{
			clearBuckets();
			if (colors.length == 0)
				return;
			Trace("colorArr:" + colors);
			Trace(colors.length + " colors.");
			for (var i:int = 0; i < colors.length; i++)
			{
				Trace("Filling bucket " + i + ": 0x" + colors[i]);
				fillBucket(i, colors[i]);
			}
		}
		
		public function SetBucketColor(index:Number, color:String)
		{
			_equippedColorArr[index] = parseInt('0x' + color);
			fillBucket(int(index), parseInt('0x' + color));
		}
		
		private function fillBucket(index:int, color:int)
		{
			//trace(index + ', ' + color);
			var bucket:Sprite = _buckets[index];
			trace(bucket);
			var paint:Sprite = bucket.getChildAt(0) as Sprite;
			paint.graphics.clear();
			paint.graphics.beginFill(color);
			paint.graphics.drawCircle(bucket.width/2, bucket.width/2, bucket.width / 2 - 2);
			paint.graphics.endFill();
			bucket.visible = true;
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