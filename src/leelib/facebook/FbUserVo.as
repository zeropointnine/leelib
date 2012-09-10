package leelib.facebook
{

	
	import flash.display.BitmapData;
	
	import leelib.util.Out;

	/**
	 * Stores most all user-account info as requested from FB via FbUtil.
	 * Parses various JSON data from Facebook service into various VO's, etc.
	 * 
	 * Designed for with just one instance in mind (the logged-in user of the app) 
	 */
	public class FbUserVo extends BaseVo
	{
		public var firstName:String;
		public var lastName:String;
		public var name:String; 		// TODO: Resolve issue of name, versus first+last
		
		public var gender:String; 		// male, female, ???
		
		public var location:String;
		public var locationWork:String;
		
		public var birthDayString:String;
		public var birthDayMonth:int = 0;
		public var birthDayDay:int = 0;
		public var birthDayYear:int = 0;

		public var musicNames:Array;
		
		public var friends:Array; // array of FbFriendVo's
		public var albums:Array; // array of FbAlbumVo's
		
		public var profileImageSquare:BitmapData;
		public var profileImageLarge:BitmapData
		
		
		public function FbUserVo()
		{
		}
		
		public function getProfilePicturesAlbum():AlbumVo
		{
			if (! albums) return null;
			
			for each (var vo:AlbumVo in albums) {
				if (vo.name.toLowerCase() == "profile pictures") return vo;
			}
			
			trace('iffy...');
			return AlbumVo(albums[albums.length-1]);
		}
		
		public function getBiggestAlbum():AlbumVo
		{
			if (! albums) return null;
			
			var max:int = 0;
			var idx:int = -1;
			for (var i:int = 0; i < albums.length; i++)
			{
				var vo:AlbumVo = albums[i];
				if (vo.count > max){
					max = vo.count;
					idx = i;
				}
				
			}
			if (idx == -1) return null;
			if (max == 0) return null;
			
			return albums[idx];
		}
		

		public function parseUserInfo($o:Object):void
		{
			if (!$o) return;
			
			if ($o.id) id = $o.id;
			if ($o.first_name) firstName = $o.first_name;
			if ($o.last_name) lastName = $o.last_name;
			if ($o.name) name = $o.name;
			if ($o.gender) gender = $o.gender;
			if ($o.location && $o.location.name) location = $o.location.name;
			
			if ($o.work) {
				// parse "work" for location
				for (var i:int = 0; i < $o.work.length; i++) {
					if ($o.work[i].location && $o.work[i].location.name) {
						locationWork = $o.work[i].location.name;
						break;
					}
				}
			}

			Out.d('FbUserVo.parseUserInfo() - USER INFO:', id, firstName, lastName, gender, location, locationWork);
			
			if (! id) {
				Out.e('FbUserVo.parseUserInfo() - NO ID!');
			}
			
		}
		
		public function parseAlbumList($o:Object):void
		{
			if ($o && $o.data)
			{
				albums = [];
				for (var i:int = 0; i < $o.data.length; i++) 
				{
					var id:String = $o.data[i].id;
					var name:String = $o.data[i].name;
					var count:int = parseInt($o.data[i].count);
					var vo:AlbumVo = new AlbumVo(id,name,count);
					albums.push(vo);
				}			
			}
			trace('ALBUMS:', albums);
		}
		
		public function parseLikes($o:Object):void
		{
			// parse likes for music specifically
			
			if ($o && $o.data) 
			{
				musicNames = [];
				for (var i:int = 0; i < $o.data.length; i++) 
				{
					var cat:String = $o.data[i].category;
					var val:String = $o.data[i].name;
					if (cat && cat.toLowerCase().indexOf("music") > -1) musicNames.push(val);
				}
			}

			trace('LIKEBANDS:', musicNames);
		}
		
		public function parseFriends($o:Object):void
		{
			if ($o && $o.data) 
			{
				friends = [];
				
				for (var i:int = 0; i < $o.data.length; i++) 
				{
					var name:String = $o.data[i].name;
					var id:String = $o.data[i].id;
					var vo:FbFriendVo = new FbFriendVo(id,name);
					friends.push(vo);
				}
			}
			
			// sort, too
			friends.sortOn("name", Array.CASEINSENSITIVE);
			
			trace('FRIENDS:', friends.length, friends);
		}
		
		//
		
		public function parseFeedForFriendActivity($o:Object):void
		{
			// tally friend activity on user's wall by looking at 
			// item's from object, and also looking at 
			// comments/from inside of item
			
			if (! $o || ! $o.data) {
				trace('FbUserVo.parseFeedForFriendActivity() - NO DATA');	
				return;
			} 
			if ($o.data.length == 0) {
				trace('FbUserVo.parseFeedForFriendActivity() - NO ITEMS IN FEED');
				return;
			}
			
			var i:int;
			var id:String;
			var vo:FbFriendVo;
			for (i = 0; i < $o.data.length; i++) 
			{
				if (! $o.data[i].from) continue;
				
				id = $o.data[i].from.id;
				vo = getFriendById(id);
				if (vo) {
					vo.activityTally++;
				}
				
				if (! $o.data[i].comments || ! $o.data[i].comments.data) continue;
				
				for (var j:int = 0; j < $o.data[i].comments.data.length; j++)
				{
					if ($o.data[i].comments.data[j].from) {
						id = $o.data[i].comments.data[j].from.id;
						vo = getFriendById(id);
						if (vo) {
							vo.activityTally++;
						}
					}
				}
			}
			
			// * friends sorted by activity
			friends.sort(friendSort);
			
			var s:String = "MOST ACTIVE WALL FRIENDS: ";
			for (i = 0; i < Math.min(friends.length,10); i++) {
				vo = friends[i];
				s += vo.name + " " + vo.activityTally + ", ";
			}
			trace(s);
		}
		
		private function getFriendById($id:String):FbFriendVo
		{
			for each (var vo:FbFriendVo in friends) {
				if (vo.id == $id) return vo;
			}
			return null;
		}
		
		private function friendSort($a:FbFriendVo, $b:FbFriendVo):int
		{
			if ($a.activityTally > $b.activityTally)
				return -1;
			else if ($a.activityTally < $b.activityTally)
				return +1;
			else
				return 0;
		}
	}
}
