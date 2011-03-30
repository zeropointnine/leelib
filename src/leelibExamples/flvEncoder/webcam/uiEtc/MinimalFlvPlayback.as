package leelibExamples.flvEncoder.webcam.uiEtc
{
	import flash.display.Sprite;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	public class MinimalFlvPlayback extends Sprite
	{
		private var _video:Video;
		private var _nc:NetConnection;
		private var _ns:NetStream;
		
		public function MinimalFlvPlayback()
		{
			_video = new Video();
			this.addChild(_video);
			
			_nc = new NetConnection();
			_nc.connect(null);
			
			_ns = new NetStream(_nc);
			_ns.client = this;
			
			_video.attachNetStream(_ns);
			
			_ns.play("c:/no_server_required.flv");
		}
		
		public function onMetaData($o:Object):void
		{
			for each (var s:String in $o) {
				trace(s, $o[s]);
			}
		}
	}
}