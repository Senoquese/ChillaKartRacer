package  
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.LocalConnection;
	import flash.text.AntiAliasType;
	import flash.text.Font;
	import flash.text.TextField;
	import fl.controls.*;
	import flash.text.TextFormat;
	
	/**
	 * Dimensions: 700 x 557
	 * @author Ian Marsh http://eeenmachine.com
	 * 
	 * setTabName(tab:Number, name:String):void
	 * - tab: [1..5]
	 * - name: label for that page #
	 * 
	 * setWidgetData(tab:Number, widgetId:String, data:String, selected:String = '0'):void
	 * - ComboBox ex: setWidgetData(1, 'myCombo', 'one|1,two|2,three|3,four|4', '2');
	 * - Slider ex: setWidgetData(1, 'mySlider', '75');
	 * 
	 * setLeftButtonLabel(str:String)
	 * setRightButtonLabel(str:String)
	 * 
	 * External Interface Calls
	 * comboBoxChange(widgetID:String, selData:String)
	 * sliderChange(widgetID:String, value:Number)
	 * textInputChange(widgetID:String, value:String)
	 * keyInputClick(widgetID:String)
	 * leftButtonClick()
	 * rightButtonClick()
	 * doneLoading()
	 */
	public class Settings extends MovieClip
	{
		private var _curTab:int = 1;
		private var _xml:XML;
		private var _labelFormat:TextFormat;
		private var _itemFormat:TextFormat;
		private var _widgetIds:Object;
		private var _leftButton:LoadSaveButton;
		private var _rightButton:LoadSaveButton;
		
		private var _delRoman:Font;
		
		public function Settings() 
		{
			gotoTab(1);
			
			MovieClip(this['tabButton1']).addEventListener(MouseEvent.CLICK, tabClicked);
			MovieClip(this['tabButton2']).addEventListener(MouseEvent.CLICK, tabClicked);
			MovieClip(this['tabButton3']).addEventListener(MouseEvent.CLICK, tabClicked);
			MovieClip(this['tabButton4']).addEventListener(MouseEvent.CLICK, tabClicked);
			MovieClip(this['tabButton5']).addEventListener(MouseEvent.CLICK, tabClicked);
			
			_delRoman = new DelRoman();
			_labelFormat = new TextFormat();
			_labelFormat.color = 0xCCCCCC;
			_labelFormat.font = "Delicious-Roman";
			_labelFormat.size = 20;
			
			_itemFormat = new TextFormat();
			_itemFormat.color = 0xCCCCCC;
			_itemFormat.font = "Tahoma,Arial,Verdana";
			_itemFormat.size = 14;
			_itemFormat.bold = true;
			
			_widgetIds = new Object();
			
			var uLoader:URLLoader = new URLLoader();
			uLoader.addEventListener(Event.COMPLETE, xmlLoaded);
			uLoader.load(new URLRequest('Settings.xml'));
			
			_leftButton = leftButton;
			_rightButton = rightButton;
			_leftButton.addEventListener(MouseEvent.CLICK, leftButtonClicked);
			_rightButton.addEventListener(MouseEvent.CLICK, rightButtonClicked);
			
			ExternalInterface.addCallback('setTabName', setTabName);
			ExternalInterface.addCallback('setWidgetData', setWidgetData);
			ExternalInterface.addCallback('setLeftButtonLabel', setLeftButtonLabel);
			ExternalInterface.addCallback('setRightButtonLabel', setRightButtonLabel);
			ExternalInterface.addCallback('gc', gc);
		}
		
		private function xmlLoaded(e:Event):void
		{
			_xml = new XML(URLLoader(e.target).data);
			var pages:XMLList = _xml.descendants('page');
			
			for (var i:int = 0; i < pages.length() && i < 5; i++)
			{
				var page:XML = pages[i];
				setTabName(i + 1, page.attribute('label'));
				
				var pageWidgets:XMLList = page.children();
				
				for (var j:int = 0; j < pageWidgets.length(); j++)
				{
					var widget:XML = pageWidgets[j];
					trace("found widget "+j+":" + pageWidgets[j].name());
					switch(pageWidgets[j].name().toString())
					{
						case 'ComboBox':
							var tf:TextField = new TextField();
							tf.antiAliasType = AntiAliasType.ADVANCED;
							tf.selectable = false;
							tf.autoSize = 'left';
							tf.defaultTextFormat = _labelFormat;
							tf.embedFonts = true;
							tf.text = widget.attribute('label');
							tf.y = parseInt(widget.attribute('y'));
							tf.x = parseInt(widget.attribute('x'));
							var cb:ComboBox = new ComboBox();
							cb.x = tf.x + tf.width;
							cb.y = tf.y + 1;// + tf.height - tf.textHeight;
							if (widget.attribute('width'))
								cb.width = parseInt(widget.attribute('width'));
							cb.textField.setStyle("textFormat", _itemFormat);
							cb.textField.textField.embedFonts = true;
							cb.addEventListener(Event.CHANGE, comboBoxChange);
							trace('widget id:' + widget.attribute('id'));
							cb.name = widget.attribute('id');
							MovieClip(this['panel' + (i + 1)]).addChild(cb);
							this['panel' + (i + 1)][widget.attribute('id')+'_'] = cb;
							MovieClip(this['panel' + (i + 1)]).addChild(tf);
							
							trace(cb.name);
						break;
						case 'Slider':
							var tf1:TextField = new TextField();
							tf1.antiAliasType = AntiAliasType.ADVANCED;
							tf1.selectable = false;
							tf1.autoSize = 'left';
							tf1.defaultTextFormat = _labelFormat;
							tf1.embedFonts = true;
							tf1.text = widget.attribute('label') + widget.attribute('min') + ' ';
							tf1.y = parseInt(widget.attribute('y'));
							tf1.x = parseInt(widget.attribute('x'));
							var sl:Slider = new Slider();
							sl.x = tf1.x + tf1.width;
							sl.y = tf1.y + tf1.height / 2;
							sl.minimum = parseFloat(widget.attribute('min'));
							sl.maximum = parseFloat(widget.attribute('max'));
							if (widget.attribute('width'))
								sl.width = parseInt(widget.attribute('width'));
							if (widget.attribute('tick'))
							{
								sl.tickInterval = parseFloat(widget.attribute('tick'));
								sl.snapInterval = parseFloat(widget.attribute('tick'));
							}
							var tf2:TextField = new TextField();
							tf2.antiAliasType = AntiAliasType.ADVANCED;
							tf2.selectable = false;
							tf2.autoSize = 'left';
							tf2.defaultTextFormat = _labelFormat;
							tf2.embedFonts = true;
							tf2.text = ' ' + widget.attribute('max');
							tf2.x = sl.x + sl.width;
							tf2.y = tf1.y;
							sl.name = widget.attribute('id');
							sl.addEventListener(Event.CHANGE, sliderChange);
							MovieClip(this['panel' + (i + 1)]).addChild(sl);
							this['panel' + (i + 1)][widget.attribute('id')+'_'] = sl;
							MovieClip(this['panel'+(i+1)]).addChild(tf1);
							MovieClip(this['panel'+(i+1)]).addChild(tf2);
						break;
						case 'TextInput':
							var tf3:TextField = new TextField();
							tf3.antiAliasType = AntiAliasType.ADVANCED;
							tf3.selectable = false;
							tf3.autoSize = 'left';
							tf3.defaultTextFormat = _labelFormat;
							tf3.embedFonts = true;
							tf3.text = widget.attribute('label');
							tf3.y = parseInt(widget.attribute('y'));
							tf3.x = parseInt(widget.attribute('x'));
							var textInput:TextInput = new TextInput();
							textInput.setStyle("textFormat", _itemFormat);
							textInput.textField.embedFonts = true;
							textInput.y = tf3.y;
							textInput.x = tf3.x + tf3.width;
							textInput.addEventListener(Event.CHANGE, textInputChange);
							textInput.name = widget.attribute('id');
							this['panel' + (i + 1)][widget.attribute('id')+'_'] = textInput;
							MovieClip(this['panel'+(i+1)]).addChild(tf3);
							MovieClip(this['panel'+(i+1)]).addChild(textInput);
						break;
						case 'KeyInput':
							var tf4:TextField = new TextField();
							tf4.antiAliasType = AntiAliasType.ADVANCED;
							tf4.selectable = false;
							tf4.autoSize = 'left';
							tf4.defaultTextFormat = _labelFormat;
							tf4.embedFonts = true;
							tf4.text = widget.attribute('label');
							tf4.y = parseInt(widget.attribute('y'));
							tf4.x = parseInt(widget.attribute('x'));
							var keyInput:TextInput = new TextInput();
							keyInput.setStyle("textFormat", _itemFormat);
							keyInput.textField.embedFonts = true;
							keyInput.y = tf4.y;
							keyInput.x = tf4.x + tf4.width;
							keyInput.name = widget.attribute('id');
							keyInput.addEventListener(MouseEvent.CLICK, keyInputClick);
							this['panel' + (i + 1)][widget.attribute('id')+'_'] = keyInput;
							MovieClip(this['panel'+(i+1)]).addChild(tf4);
							MovieClip(this['panel'+(i+1)]).addChild(keyInput);
						break;
					}
				}
			}
			
			ExternalInterface.call('doneLoading');
			//test();
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
		
		public function setTabName(tab:Number, name:String):void
		{
			TextField(this['tab' + int(tab)]).text = name;
		}
		
		public function setWidgetData(tab:Number, widgetId:String, data:String, selected:String):void
		{
			trace('setWidgetData:' + this['panel' + tab][widgetId+'_']);
			var widget:Object = this['panel' + tab][widgetId+'_'];
			
			if (!widget)
				return;
			
			if (widget is ComboBox)
			{
				var items:Array = data.split(',');
				var s:String;
				for each(s in items)
				{
					widget.addItem( { label:s.split('|')[0], data:s.split('|')[1] } );
				}
				trace('dropdown:' + widget.dropdown);
				widget.dropdown.setRendererStyle("textFormat", _itemFormat);
				widget.selectedIndex = parseInt(selected);
			}
			else if (widget is Slider)
			{
				widget.value = parseFloat(data);
			}
			else if (widget is TextInput)
			{
				widget.text = data;
				widget.editable = true;
			}
		}
		
		private function keyInputClick(e:Event):void
		{
			e.target.parent.editable = false;
			trace('keyInputClick: '+e.target.parent.name);
			ExternalInterface.call('keyInputClick', e.target.parent.name);
		}
		
		private function comboBoxChange(e:Event):void
		{
			trace(e.target.name + ":" + e.target.selectedItem.data);
			ExternalInterface.call('comboBoxChange', e.target.name, String(e.target.selectedItem.data));
		}
		
		private function sliderChange(e:Event):void
		{
			trace(e.target.name + ": " + e.target.value);
			ExternalInterface.call('sliderChange', e.target.name, Number(e.target.value));
		}
		
		private function textInputChange(e:Event):void
		{
			trace(e.target.name + ":" + e.target.text);
			ExternalInterface.call('textInputChange', e.target.name, e.target.text);
		}
		
		private function tabClicked(e:MouseEvent):void
		{
			switch(e.target)
			{
				case this['tabButton1']:
					gotoTab(1);
				break;
				case this['tabButton2']:
					gotoTab(2);
				break;
				case this['tabButton3']:
					gotoTab(3);
				break;
				case this['tabButton4']:
					gotoTab(4);
				break;
				case this['tabButton5']:
					gotoTab(5);
				break;
			}
		}
		
		public function gotoTab(t:int):void
		{
			this['tab1'].textColor = this['tab2'].textColor = this['tab3'].textColor = this['tab4'].textColor = this['tab5'].textColor = 0xCCCCCC;
			panel1.visible = panel2.visible = panel3.visible = panel4.visible = panel5.visible = false;
			_curTab = t;
			this['panel' + t].visible = true;
			//gotoAndStop(_curTab);
			
			var newTabLabel:TextField = TextField(this['tab' + _curTab]);
			newTabLabel.textColor = 0xb8fe00;
		}
		
		private function test():void
		{
			setWidgetData(1, 'test', 'one|1,two|2,three is a crowd|3,four|4', '2');
			setWidgetData(1, 'test2', 'one|1,two|2,three is a crowd|3,four|4', '2');
			setWidgetData(1, 'tslider', '75', '0');
			setWidgetData(1, 'tinput', 'wooords', '0');
			setWidgetData(1, 'tcapture', 'CTRL', '0');
			
			setLeftButtonLabel('Done');
			setRightButtonLabel('Cancel');
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