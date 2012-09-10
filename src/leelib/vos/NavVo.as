package leelib.vos
{
	import leelib.screens.AcScreen;
	
	public class NavVo
	{
		public var screenInstance:AcScreen;
		public var screenClass:Class;
		
		public function NavVo($instance:AcScreen, $class:Class=null)
		{
			if ($instance && ! $class)
			{
				screenInstance = $instance;
				screenClass = Object($instance).constructor; 
			}
			else if (! $instance)
			{
				screenInstance = null;
				screenClass = $class;
			}
		}
		
		public function toString():String
		{
			return "[NavVo] " + screenClass + " " + screenInstance; 
		}
	}
}


