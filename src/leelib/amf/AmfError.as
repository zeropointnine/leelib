package leelib.amf
{
	public class AmfError
	{
		public static const FAULT:String = "fault";
		public static const NETSTATUS:String = "netStatus";
		public static const TIMEOUT:String = "timeOut";
		
		public var errorType:String;
		public var netStatusInfo:Object;
		public var faultObject:Object;
		
		public function AmfError($errorType:String, $netStatusInfo:Object, $faultObject:Object)
		{
			errorType = $errorType;
			netStatusInfo = $netStatusInfo;
			faultObject = $faultObject;
		}		
		
		public function get description():String
		{
			if (errorType == TIMEOUT)
				return "Timeout";
			else if (errorType == FAULT)
				return faultObject.code + ": " + faultObject.description;
			else // NETSTATUS
				return netStatusInfo.description;
		}
	}
}