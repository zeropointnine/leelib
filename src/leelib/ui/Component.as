package leelib.ui
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import com.greensock.easing.Linear;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.dns.AAAARecord;
	import flash.utils.setTimeout;
	
	import leelib.facebook.PostVo;
	import leelib.util.Out;


	public class Component extends Sprite
	{
		public static const EVENT_LOADED:String = "Component.eventLoaded";
		public static const EVENT_SHOWCOMPLETE:String = "eventShowComplete";
		public static const EVENT_HIDECOMPLETE:String = "eventHideComplete";
		public static const EVENT_ROLLOVER:String = "eventRollOver";
		
		protected var _isInitialized:Boolean;
		protected var _isLoaded:Boolean;
		
		protected var _parentComponent:Component;
		protected var _childComponents:Array;
		protected var _sizeWidth:Number;
		protected var _sizeHeight:Number;
		protected var _originType:uint; 
		protected var _offsetX:Number;
		protected var _offsetY:Number;

		public static const ORIGIN_TL:uint = 0;
		public static const ORIGIN_CL:uint = 1;
		public static const ORIGIN_BL:uint = 2;
		public static const ORIGIN_TC:uint = 3;
		public static const ORIGIN_CC:uint = 4;
		public static const ORIGIN_BC:uint = 5;
		public static const ORIGIN_TR:uint = 6;
		public static const ORIGIN_CR:uint = 7;
		public static const ORIGIN_BR:uint = 8;

		
		public function Component()
		{
			_originType = ORIGIN_TL;
			_offsetX = 0;
			_offsetY = 0;
			_childComponents = [];
		}
		
		/**
		 * Subclasses should leave this alone and override doInit() instead 
		 */
		public function initialize($originType:uint, $rect:Rectangle):void
		{
			_sizeWidth = $rect.width; 
			_sizeHeight = $rect.height;
			
			this.originType = $originType;
			_offsetX = $rect.x;
			_offsetY = $rect.y;

			doInit();
			
			this.updatePosition();
			this.size();
			
			_isInitialized = true;
		}
		
		/**
		 * Subclasses should override this.
		 *
		 * Non-Component DisplayObjects might be positioned here -- 
		 * _if_ their position is not contingent on sizeWidth/Height;
		 * If they are, they should be positioned in size() instead.
		 */
		protected function doInit():void
		{
		}
		
		public function kill():void
		{
			// Override and super this.
			clearChildComponentArray();			
		}

		public function clearChildComponentArray():void
		{
			while (_childComponents.length > 0) {
				_childComponents.pop();
			}
		}
		
		
		public  function setSize($width:Number, $height:Number, $dontSizeYet:Boolean=false):void
		{
			
		}
		
		
		
		
		protected  function onClick(e:*):void{
			
		}

		
		/**
		 * Do any loading here and call onLoadComplete
		 */
		public function load():void
		{
		}
		protected function onLoadComplete(e:*=null):void
		{
			_isLoaded = true;
			this.dispatchEvent(new Event(Component.EVENT_LOADED));
		} 

		/**
		 * You should obviously initialize() and also load() before doing show()
		 */
		public function show():void
		{
			this.visible = true;
			this.alpha = 0;
			TweenLite.killTweensOf(this);
			TweenLite.to(this, 0.5, { alpha:1, onComplete:this.dispatchEvent, onCompleteParams:[new Event(EVENT_SHOWCOMPLETE)] } );
		}
		
		public function hide():void
		{
			TweenLite.killTweensOf(this);
			TweenLite.to(this, 0.33, { alpha:0, ease:Linear.easeNone, onComplete:hide_2} );
		}
		private function hide_2():void
		{
			this.visible = false;
			this.dispatchEvent(new Event(EVENT_HIDECOMPLETE)); 			
		}
		
		public function size():void
		{
			// Component does any _sizeWidth and _sizeHeight-dependent operations here.
			// Override in subclass.
		}
		
		// read only
		public function get isInitialized():Boolean
		{
			return _isInitialized;
		}

		// read only		
		public function get isLoaded():Boolean
		{
			return _isLoaded;
		}
		
		//
		// LAYOUT LOGIC
		//

		public function get parentComponent():Component
		{
			return _parentComponent;
		}
		public function set parentComponent($component:Component):void
		{
			_parentComponent = $component;
		}
		
		public function addChildComponent($c:Component, $at:int=-1):void
		{
			if ($at == -1) 
				this.addChild($c);
			else 
				this.addChildAt($c, $at);
			
			_childComponents.push($c);
			
			$c.parentComponent = this;
			
			if ( ! isNaN(_offsetX) && ! isNaN(_offsetY) ) $c.updatePosition();
			if ( ! isNaN(_sizeWidth) && ! isNaN(_sizeHeight) && ! ! isNaN($c.sizeWidth) && ! isNaN($c.sizeHeight) ) $c.size();
		}
		
		public function removeChildComponent($c:Component):void
		{
			var index:int =_childComponents.indexOf($c); 
			if (index > -1) { 
				_childComponents = _childComponents.splice(index, 1);
				$c.parentComponent = null;
			}
			
			if ($c.parent) $c.parent.removeChild($c);
		}
		
		public function removeChildComponents():void
		{
			for each (var c:Component in _childComponents) 
			{
				if (c.parent) c.parent.removeChild(c);
				c.parentComponent = null;
			}
			_childComponents = [];
		}
		
		public function get childComponents():Array
		{
			return _childComponents;
		}
		
		public function get sizeWidth():Number
		{
			return _sizeWidth;
		}
		public function set sizeWidth($n:Number):void
		{
			_sizeWidth = $n;
			if (_sizeHeight) this.size();
			updateChildrenPosition();
		}
		
		public function get sizeHeight():Number
		{
			return _sizeHeight;
		}
		public function set sizeHeight($n:Number):void
		{
			_sizeHeight = $n;
			if (_sizeWidth) this.size();
			updateChildrenPosition();
		}
		
		public function sizeWidthHeight($w:Number, $h:Number):void
		{
			_sizeWidth = $w;
			_sizeHeight = $h;

			this.size();
			updateChildrenPosition();
		}
		
		public function get originType():uint
		{
			return _originType;
		}
		public function set originType($type:uint):void
		{
			_originType = $type;

			if (! isNaN(_sizeWidth) && ! isNaN(_sizeHeight)) updatePosition();
		}
		
		
		/**
		 * Rem, "offset" is in relation to 'origin'.
		 * So if originType is "CC" (center-center), an offset of 0,0 means exactly centered. Etc.
		 */ 
		public function get offsetX():Number
		{
			return _offsetX;
		}
		public function set offsetX($n:Number):void
		{
			_offsetX = $n;
			this.updatePosition();
		}
		
		public function get offsetY():Number
		{
			return _offsetY;
		}
		public function set offsetY($n:Number):void
		{
			_offsetY = $n;
			this.updatePosition();
		}
		
		public function offsetXY($x:Number, $y:Number):void
		{
			_offsetX = $x;
			_offsetY = $y;
			this.updatePosition();
		}
		
		protected function updatePosition():void
		{
			if (! _parentComponent) return;
			
			switch (_originType)
			{
				case ORIGIN_TL:
					this.x = _offsetX;
					this.y = _offsetY;
					break;
				
				case ORIGIN_CL:
					this.x = _offsetX;
					this.y = _parentComponent.sizeHeight * 0.5 - _sizeHeight*0.5 + _offsetY;
					break;
				
				case ORIGIN_BL:
					this.x = _offsetX;
					this.y = _parentComponent.sizeHeight - _sizeHeight - _offsetY;
					break;
				
				case ORIGIN_TC:
					this.x = _parentComponent.sizeWidth * 0.5 - _sizeWidth*0.5 + _offsetX;
					this.y = _offsetY;
					break;
				
				case ORIGIN_CC:
					this.x = _parentComponent.sizeWidth * 0.5 - _sizeWidth*0.5 + _offsetX;
					this.y = _parentComponent.sizeHeight * 0.5 - _sizeHeight*0.5 + _offsetY;
					break;
				
				case ORIGIN_BC:
					this.x = _parentComponent.sizeWidth * 0.5 - _sizeWidth*0.5 + _offsetX;
					this.y = _parentComponent.sizeHeight - _sizeHeight - _offsetY;
					break;
				
				case ORIGIN_TR:
					this.x = _parentComponent.sizeWidth - _sizeWidth - _offsetX;
					this.y = _offsetY;
					break;
				
				case ORIGIN_CR:
					this.x = _parentComponent.sizeWidth - _sizeWidth - _offsetX;
					this.y = _parentComponent.sizeHeight * 0.5 - _sizeHeight*0.5 + _offsetY;
					break;
				
				case ORIGIN_BR:
					this.x = _parentComponent.sizeWidth - _sizeWidth - _offsetX;
					this.y = _parentComponent.sizeHeight - _sizeHeight - _offsetY;
					break;
			}
		}
		
		protected function updateChildrenPosition():void
		{
			for each (var c:Component in _childComponents)
			{
				c.updatePosition();
			}
		}

		// does not factor in scale
		public function getGlobalRect():Rectangle
		{
			var pt:Point = localToGlobal(new Point(this.x,this.y));
			return new Rectangle(pt.x, pt.y, pt.x + _sizeWidth, pt.y + _sizeHeight);
		}

		// Useful for setting viewport properties of things like StageWebView, which are in global coordinates 
		// Does not factor in scale
		//
		public function getGlobalRectOf($r:Rectangle):Rectangle
		{
			var pt:Point = localToGlobal(new Point(0,0));
			return new Rectangle(pt.x + $r.x, pt.y + $r.y, $r.width, $r.height);
		}

		// Test this...
		//
		// Remove all children recursively.
		// Remove childComponent references from any Components along the way.
		//
		public static function decompose($doc:DisplayObjectContainer, $killBitmapDatas:Boolean=false):void
		{
			while ($doc.numChildren > 0)
			{
				var dob:DisplayObject = $doc.getChildAt(0);
				
				if (dob is DisplayObjectContainer && ! (dob is Loader) )
				{
					decompose( DisplayObjectContainer(dob) );
				}
				else
				{
					if (dob is Bitmap && $killBitmapDatas) Bitmap(dob).bitmapData = null;
				}
				
				if ($doc is Component) Component($doc).clearChildComponentArray();
				
				$doc.removeChild(dob);
				
				if (dob is Loader) Loader(dob).unload();
			}
		}
	}
}