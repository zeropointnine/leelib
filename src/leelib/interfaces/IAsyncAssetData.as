package leelib.interfaces
{
	import flash.display.BitmapData;

	
	// Meant to be implemented on VO's that are used with AsyncAssetListItems.
	//
	// If the data element applied to the AsyncAssetListItem implements this,
	// ListView using the AsyncAssetListItem will load the asset using the value of assetUrl.
	//
	public interface IAsyncAssetData
	{
		function get assetUrl():String;
		function get loadUtilAssetType():String; 
	}
}
