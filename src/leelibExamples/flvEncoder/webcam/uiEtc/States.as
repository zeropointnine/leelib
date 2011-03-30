package leelibExamples.flvEncoder.webcam.uiEtc
{
	public class States
	{
		public static const WAITING_FOR_WEBCAM:String = "waitingForWebcam";
		public static const WAITING_FOR_RECORD:String = "waiting";
		public static const RECORDING:String = "recording";
		public static const ENCODING:String = "encoding";
		public static const SAVING:String = "waitingForClick";
		
		// saving to file is synchronous so needs no 'state'
	}
}