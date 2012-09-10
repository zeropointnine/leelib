package leelib.facebook
{
	import flash.display.Bitmap;

	
	public class ImageVo extends BaseVo
	{
		public var pictureUrl:String; // smaller size
		
		public var sourceUrl:String; // 'full' size
		public var width:int;
		public var height:int; 
		
		public var bitmap:Bitmap;
		
		
		public function ImageVo($id:String, $pictureUrl:String, $sourceUrl:String, $width:int, $height:int)
		{
			id = $id;
			pictureUrl = $pictureUrl;
			sourceUrl = $sourceUrl;
			width = $width;
			height = $height;
		}
		
		public function toString():String
		{
			return "[FbPhotoVo] " + id + ", " + pictureUrl + ", " + sourceUrl + ", " + width + ", " + height; 
		}
	}
}