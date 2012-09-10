package leelib.graphics
{
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	/**
	 * 	FrameAnimUtil v1.0
	 * 
	 * 	- No wraparound.
	 * 	- Simple ease-out option.
	 * 
	 * 	Note, this adds a few properties to the passed-in movieclip:
	 * 		frameDest; callback; useEaseOut; currentFrameScalar; easeOutDivider; step
	 * 
	 *	@author Lee
	 */
	public class FrameAnimUtil
	{
		static private var _instance:FrameAnimUtil;

		public function FrameAnimUtil(enforcer:SingletonEnforcer)
		{
		}

		public static function getInstance():FrameAnimUtil
		{
			if (FrameAnimUtil._instance == null) FrameAnimUtil._instance = new FrameAnimUtil(new SingletonEnforcer());
			return FrameAnimUtil._instance;
		}
		
		public function clear($mc:MovieClip):void
		{
			if ($mc) {
				$mc.removeEventListener(Event.ENTER_FRAME, playTo_EnterFrame);
				delete $mc.frameDest;
				delete $mc.callback;
				delete $mc.useEaseOut;
				delete $mc.currentFrameScalar;
				delete $mc.step;
			}
		}
		
		public function isPlaying($mc:MovieClip):Boolean
		{
			return ($mc.frameDest != null)
		}
		
		public function playTo($mc:MovieClip, $frame:*, $callback:Function=null, $step:Number=1, $useEaseOut:Boolean=false, $easeOutDivider:Number=4):void
		{
			if ($frame is Number)
				$mc.frameDest = $frame; // creates new property on movieclip!
			else if ($frame is String)
				$mc.frameDest = frameNumFromLabel($mc, $frame);
			else
				throw new Error("$frame param must be Number or String");

			if ($mc.frameDest == $mc.currentFrame) 
			{
				var callback:Function = $callback;
				clear($mc);
				if (callback is Function) callback();
				return;
			}

			$mc.currentFrameScalar = $mc.currentFrame
			$mc.callback = $callback;
			$mc.useEaseOut = $useEaseOut;
			$mc.easeOutDivider = $easeOutDivider;
			$mc.step = Math.abs($step);
			$mc.addEventListener(Event.ENTER_FRAME, playTo_EnterFrame, false,0,true);
		}
		
		private function playTo_EnterFrame(e:Event):void
		{
			var mc:MovieClip = e.target as MovieClip;
			
			// End condition
			if (mc.currentFrame == mc.frameDest) 
			{
				var callback:Function = mc.callback;
				clear(mc);
				if (callback is Function) callback();
				return;
			}

			var amount:Number;
			if (mc.useEaseOut)
				amount = (mc.frameDest - mc.currentFrameScalar) / mc.easeOutDivider;
			else
				amount = ( (mc.frameDest > mc.currentFrameScalar) ? mc.step : -mc.step );
				
			mc.currentFrameScalar += amount;
			mc.gotoAndStop( Math.round(mc.currentFrameScalar) );
			
		}
		
		public function frameNumFromLabel($mc:MovieClip, $label:String):int
		{
			for (var i:int = 0; i < $mc.currentLabels.length; i++)
			{
				var l:FrameLabel = $mc.currentLabels[i];
				if ($label == l.name) return l.frame;
			}
			
			trace("FrameAnimUtil.frameNumFromLabel() - No such frameLabel.");
			return -1;
		}
		
		/**
		 * @param $mc
		 * @param $a			Array of frames to which to animate to, in sequence
		 * @param $callback		Function to call at _end_ of whole sequence
		 * 
		 * TO DO: Ability to cancel!
		 */
		public function playSequence($mc:MovieClip, $a:Array, $callback:Function):void
		{
			// trace('seq', $mc, $a, $callback);
			
			// End condition:
			if ($a.length == 0) {
				if ($callback != null) $callback();
				return;
			}
			
			var fn:Function = function():void { playSequence($mc, $a, $callback); }
			var frame:uint = $a.shift();

			var useEasing:Boolean = ($a.length == 1) ? true :false; // hardcoded -- CHANGE ME !
			playTo($mc, frame, fn, 1, useEasing);
		}
	}
}

class SingletonEnforcer {}