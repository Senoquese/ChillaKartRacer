package  
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author DefaultUser (Tools -> Custom Arguments...)
	 */
	public class ServerListEvent extends Event
	{
		public static var ITEM_SELECT:String = 'ITEM_SELECT';
		
		public var listItem:ServerListItem;
		
		public function ServerListEvent(type:String, item:ServerListItem) 
		{
			super(type);
			listItem = item;
		}
		
	}
	
}