package leelib.ui
{
	import com.greensock.TweenLite;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	
	import leelib.graphics.GrUtil;
	
	
	public class ScrollArea extends Component
	{
		private var _value:Number;
		
		private var _mask:Sprite;
		private var _holder:Sprite;
			private var _content:DisplayObject
		
		private var _scrollbar:ScrollBar;
		
		private var _bottomPadding:Number = 0;
		
		private var _contentHeightProperty:String;
		
		private var _debug:Sprite;
		
		private var _sizeNowFlag:Boolean;
		
		/**
		 * Scrollbar stays independent, does not get reparented 
		 */
		public function ScrollArea($scrollbar:ScrollBar, $width:Number, $height:Number):void
		{
			_scrollbar = $scrollbar;
			_scrollbar.addEventListener(Event.CHANGE, onScrollbarChange);

			_holder = new Sprite();
			this.addChild(_holder);
			
			_mask = GrUtil.makeRect(100,100);
			this.addChild(_mask);
			
			this.mask = _mask;
			
			_debug = GrUtil.makeRect(100,100, 0xff0000, 0.33);
			_debug.visible = false;
			this.addChild(_debug);
			
			_contentHeightProperty = "height";

			reset();
			setSize($width,$height);
		}
		
		public function set contentHeightProperty($s:String):void
		{
			_contentHeightProperty = $s;
			
			size();
		}
		
		public function addContent($d:DisplayObject, $bottomPadding:Number=0):void
		{
			_content = $d;
			_bottomPadding = $bottomPadding; // kludge, or feature?

			while (_holder.numChildren > 0) {
				_holder.removeChildAt(0);
			}
			_holder.addChild($d);
			
			size();
		}
		
		public function reset():void
		{
			_value = 0;			
			_scrollbar.value = 0;
			_sizeNowFlag = true;
			size()
		}
		
		public function get value():Number
		{
			return _value;
		}
		
		public function set value($n:Number):void
		{
			_value = $n;
			size();
		}
		
		private function onScrollbarChange($e:Event):void
		{
			_value = _scrollbar.value;
			size();
		}
		
		private function get contentHeight():Number
		{
			if (!_content) return NaN;
			return _content[_contentHeightProperty]; 
		}
		
		/**
		 * Does not affect content dimensions 
		 */
		public override function setSize($width:Number, $height:Number, $dontSizeYet:Boolean=false):void
		{
			if (contentHeight > $height && contentHeight - 10 < $height) { // obviate awkward small-pixel scrolls
				setSize($width, $height - 10);
				return;
			}
			
			_sizeWidth = $width;
			_sizeHeight = $height;
			
			_mask.width = $width;
			_mask.height = $height;
			_debug.width = $width;
			_debug.height = $height;
			
			if (!$dontSizeYet) size();
		}
		
		/**
		 * Call this after any change to content height
		 */
		public override function size():void
		{
			var y:Number = -( contentHeight - _mask.height) * _value;
			TweenLite.to(_holder, (_sizeNowFlag ? 0 : 0.4), { y:y } );
			
			_scrollbar.enabled = (contentHeight - 2 >= _sizeHeight); // hack, for now
			
			_scrollbar.thumbHeightPercentage = Math.min(_sizeHeight / contentHeight, 1);
			
			if (_sizeNowFlag) _sizeNowFlag = false;
		}
	}
}