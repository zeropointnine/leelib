package leelib.ui
{
	import flash.display.BitmapData;
	import flash.errors.IllegalOperationError;

	public class AbstractAsyncListItem extends AbstractListItem
	{
		public function AbstractAsyncListItem()
		{
			super();
		}

		public function setAsyncAsset($o:Object):void
		{
			throw new IllegalOperationError("Override me");
		}
		public function setAsyncAssetToBlank():void
		{
			throw new IllegalOperationError("Override me");
		}
		public function setAsyncAssetToLoading():void
		{
			throw new IllegalOperationError("Override me");
		}
		public function setAsyncAssetToError():void
		{
			throw new IllegalOperationError("Override me");
		}
	}
}