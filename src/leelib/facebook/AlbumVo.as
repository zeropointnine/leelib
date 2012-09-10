package leelib.facebook
{
	// Stores album properties we're interested in
	public class AlbumVo extends BaseVo
	{
		public var name:String;
		public var count:int;

		public var imageVos:Array; // of FbPhotoVo's; must be obtained in a separate request


		public function AlbumVo($id:String, $name:String, $count:int)
		{
			id = $id;
			name = $name;
			count = $count;
		}

		
		public function toString():String
		{
			return "[FbAlbumVo] " + id + ", " + name + ", " + count;
		}
		
		
		public function parsePhotos($o:Object):void 
		{
			if ($o && $o.data) 
			{
				imageVos = [];
				for (var i:int = 0; i < $o.data.length; i++) 
				{
					var id:String = $o.data[i].id;
					var pictureUrl:String = $o.data[i].picture;
					var sourceUrl:String = $o.data[i].source;
					var width:int = parseInt($o.data[i].width);
					var height:int = parseInt($o.data[i].height);
					var vo:ImageVo= new ImageVo(id, pictureUrl, sourceUrl, width, height);
					imageVos.push(vo);
					
					trace(i, id, width,height, pictureUrl);
				}
			}
			trace('PHOTOS IN ALBUM:', imageVos);
		}
		
		
	}
}