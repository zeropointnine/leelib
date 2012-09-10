package  leelib.vos
{
	import leelib.loadUtil.LoadUtil;
	import leelib.interfaces.IAsyncAssetData;
	import leelib.interfaces.IListItemData;

	/**
	 * Generic VO implementing IListItemData
	 */
	public class ListItemIAssetWrapperVo implements IListItemData, IAsyncAssetData
	{
		public var object:Object;
		private var _listItemSubclass:Class;
		private var _objectAssetField:String;
		
		public function ListItemIAssetWrapperVo($listItemSubclass:Class, $o:Object, $objectAssetField:String)
		{
			_listItemSubclass = $listItemSubclass;
			_objectAssetField = $objectAssetField;
			object = $o;
		}
		
		/* IListItemData */
		public function get listItemSubclass():Class
		{
			return _listItemSubclass;
		}
		
		/* IAsyncAssetData */
		public function get assetUrl():String
		{
			return object[_objectAssetField];
		}
		public function get loadUtilAssetType():String
		{
			return LoadUtil.TYPE_IMAGE;
		}
	}
}