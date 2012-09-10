package leelib.facebook
{
	import flash.display.Bitmap;

	public class FbFriendVo extends BaseVo
	{
		public var name:String;
		public var nameLowerCase:String; // used for internal sort routine
		public var activityTally:int;
		
		
		public function FbFriendVo($id:String, $name:String)
		{
			id = $id;
			name = $name;
			nameLowerCase = name.toLowerCase();
		}
		
		public function get iconUrl():String
		{
			return FbUtilMobile.getInstance().makeImageUrl(this.id, "small", false);
		}
		
		public function toString():String
		{
			return "[FbFriendVo] " + id + ", " + name;
		}
	}
}