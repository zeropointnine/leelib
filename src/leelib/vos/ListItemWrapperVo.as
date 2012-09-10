package leelib.vos
{
	import leelib.interfaces.IListItemData;
	
	/**
	 * Generic VO implementing IListItemData
	 */
	public class ListItemWrapperVo implements IListItemData
	{
		public var object:Object;
		private var _listItemSubclass:Class;
		
		public function ListItemWrapperVo($listItemSubclass:Class, $o:Object)
		{
			_listItemSubclass = $listItemSubclass;
			object = $o;
		}
		
		public function get listItemSubclass():Class
		{
			return _listItemSubclass;
		}
	}
}