package leelib.ui
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Linear;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.ui.Mouse;
	
	import leelib.SingletonEnforcer;

	
	public class CursorManager
	{
		private static var _instance:CursorManager;
		
		private var _holder:Sprite;
		private var _stage:Stage;
		private var _cursorHolder:Sprite;
		
		// parallel associative arrays:
		private var _bitmaps:Array = []; 
		private var _offsetX:Array = [];
		private var _offsetY:Array = [];
		private var _disableMouse:Array = [];
		private var _fadesIn:Array = [];
		private var _rotates:Array = [];
		
		private var _id:String;

		private var _disabledMouseAt:Number;
		
		
		public function CursorManager($enforcer:SingletonEnforcer)
		{
			_cursorHolder = new Sprite();
		}
		
		public static function getInstance():CursorManager 
		{
			if (_instance == null) _instance = new CursorManager(new SingletonEnforcer());
			return _instance;
		}
		
		public function get holder():Sprite
		{
			return _holder;
		}
		
		/**
		 * Holder must be 'dedicated' and be on the display list
		 */		
		public function setHolderAndStage($holder:Sprite, $stage:Stage):void
		{
			if (_holder && _holder.contains(_cursorHolder)) _holder.removeChild(_cursorHolder);
			
			_stage = $stage;

			_holder = $holder;
			_holder.mouseEnabled = _holder.mouseChildren = false;
			_holder.addChild(_cursorHolder);
		}
		
		public function addCursor($id:String, $b:Bitmap, $offsetX:Number=NaN, $offsetY:Number=NaN, $disablesMouse:Boolean=false, $fadesIn:Boolean=false, $rotates:Boolean=false):void
		{
			_bitmaps[$id] = $b;
			_offsetX[$id] = isNaN($offsetX) ? $b.width/-2 : $offsetX ;
			_offsetY[$id] = isNaN($offsetY) ? $b.height/-2 : $offsetY;
			_disableMouse[$id] = $disablesMouse;
			_fadesIn[$id] = $fadesIn;
			_rotates[$id] = $rotates;
		}
		
		public function showCursor($id:String):void
		{
			if (!_holder) {
				throw new Error("Set holder first.");
			}

			if ($id != _id) reset();
			_id = $id;
			
			var b:Bitmap = _bitmaps[_id];
			b.x = _offsetX[_id];
			b.y = _offsetY[_id];
			_cursorHolder.addChild(b);
			
			TweenLite.to(_cursorHolder, (_fadesIn[_id] ? 0.66 : 0), { alpha:1, ease:Linear.easeNone } );
			if (_rotates[_id]) {
				TweenLite.to(_cursorHolder, 999, { rotation:180*999, ease:Linear.easeNone } );
			}
			
			onEf(null);
			_holder.addEventListener(Event.ENTER_FRAME, onEf);

			if (_disableMouse[_id]) {
				_stage.mouseChildren = false;
				_disabledMouseAt = new Date().getTime();
			}
			
			Mouse.hide();
		}
		
		public function clearCursor():void
		{
			reset();
		}
		
		public function get currentCursor():String
		{
			return _id;
		}
		
		private function reset():void
		{
			_id = null;
			
			_holder.removeEventListener(Event.ENTER_FRAME, onEf);

			TweenLite.killTweensOf(_cursorHolder);
			_cursorHolder.rotation = 0;
			_cursorHolder.alpha = 0;
			
			while (_cursorHolder.numChildren > 0) {
				_cursorHolder.removeChildAt(0);
			}
			_stage.mouseChildren = true;
			Mouse.show();
		}
		
		private function onEf(e:*):void
		{
			_cursorHolder.x = _holder.mouseX;
			_cursorHolder.y = _holder.mouseY;
		}
		
		// hah!
		public function get mouseWasJustDisabled():Boolean
		{
			var i:int = (new Date().getTime() - _disabledMouseAt);
			trace(i);
			return (i < 10);
		}
	}
}
