package leelib.util
{
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.clearInterval;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setInterval;

	public class DebugObjectsUnderMouse
	{
		private static var _stage:Stage;
		private static var _tf:TextField;
		private static var _id:Number;
		
		public static function start($stage:Stage, $x:Number, $y:Number):void
		{
			_stage = $stage;
			_tf = new TextField();
			_tf.width = 500;
			_tf.height = 300;
			_tf.mouseEnabled = false;
			_tf.x = $x;
			_tf.y = $y;
			var f:TextFormat = new TextFormat("_sans",10);
			_tf.defaultTextFormat = f;
			_stage.addChild(_tf);
			
			_id = setInterval(poll, 100);
		}
		
		private static function poll():void
		{
			var pt:Point = new Point(_stage.mouseX, _stage.mouseY);
			var a:Array = _stage.getObjectsUnderPoint(pt);
			var s:String = "";
			
			for (var i:int = 0; i < a.length; i++) 
			{ 
				var d:DisplayObject = a[i];
				if (d == _tf) continue;
				
				var p:Point = d.localToGlobal(new Point());
				
				s += d.name + " " + 
					getQualifiedClassName(d) + "  " + 
					int(p.x).toString()+","+int(p.y).toString() + "  " + 
					int(d.width).toString()+"x"+int(d.height).toString() + "\r"; 
			}
			
			_tf.text = s;
		}
		
		public static function stop():void
		{
			if (_tf) {
				clearInterval(_id);
				_stage.removeChild(_tf);
				_tf = null;
			}
		}
	}
}