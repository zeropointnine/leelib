package leelib.facebook
{
	
	
	/**
	 * Example usage:
	 * 
	 * 		To make a link post...
	 * 
	 * 			var vo:LinkPostVo = new LinkPostVo();
	 * 			vo.userMessage = "Hello"; // etc...
	 * 			_fbUtil.post(_fbUtil.user.id, vo.toGenericObjectForPost(), myResponseHandler);
	 */	
	public class PostVo
	{
		// The user's message ("message")
		public var userMessage:String; 
		
		// A link to the picture included with this post ("picture")
		public var pictureUrl:String;
		
		// The link attached to this post ("link")
		public var linkUrl:String;
		
		// The name of the link ("name")
		public var linkName:String;
		
		// The caption of the link (appears beneath the link name) ("caption")
		public var linkCaption:String;
		
		// A description of the link (appears beneath the link caption) ("description")
		public var linkDescription:String;
		
		// A string indicating the type for this post (including link, photo, video) ("type")
		// * Not sure what "photo" does that is different...
		public var postType:String = "link";
		
		// For the optional 'action' links at the bottom of a post. ("actions").
		// Expecting array of ActionVo's
		// Eg:  { 'name':'Action1', 'link':'http://www.yahoo.com' }
		public var actionVos:Array;
		
		// Docs also mention these, which I'm not so sure about...
		
		// User and id of the poster (??) (necessary?)
		// o.from = ...
		
		// Profiles mentioned or targeted in this post
		// Contains in data an array of objects, each with the name and Facebook id of the user
		// [How does this get used?...]
		// o.to = ... 

		
		public function PostVo()
		{
		}
		
		
		public function toGenericObjectForPost():Object
		{
			var o:Object = {};

			o.message = this.userMessage;
			o.picture = this.pictureUrl;
			o.link = this.linkUrl;
			o.name = this.linkName;
			o.caption = this.linkCaption;
			o.description = this.linkDescription;
			o.type = this.postType; 
			if (this.actionVos) {
				var s:String = JSON.stringify(this.actionVos)
				o.actions = s; 
			}
			
			return o;
		}
	}
}