package  
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	
	/**
	 * Dimensions: 320 x 128
	 * @author Brian Cronin
	 * 
	 * External Interface:
	 * 
	 * setStates(clientFPS:Number, serverFPS:Number, clientPing:Number, serverToClientSync:Number, inBytes:Number, inKSec:Number, inPacketsSec:Number, outBytes:Number, outKSec:Number, outPacketsSec:Number)
	 */
	public class NetworkDisplay extends Sprite
	{
		public function NetworkDisplay() 
		{
			ExternalInterface.addCallback('setStats', setStats);
			//test();
		}
		
		public function setStats(clientFPS:Number, serverFPS:Number, clientPing:Number, serverToClientSync:Number, inBytes:Number, inKSec:Number, inPacketsSec:Number, outBytes:Number, outKSec:Number, outPacketsSec:Number):void
		{
			fps.text = "FPS: " + FormatDecimals(clientFPS, 2);
			serverFPS = int((serverFPS) * 100) / 100;
			serverfps.text = "S FPS: " + serverFPS.toString();
			clientPing = int((clientPing) * 100) / 100;
			ping.text = "Ping: " + clientPing.toString();
			sync.text = "Sync: " + serverToClientSync.toString() + "/s";
			inbytes.text = "In: " + inBytes.toString();
			inksec.text = inKSec.toString() + " k/s";
			inpackets.text = "#Packets: " + inPacketsSec.toString() + "/s";
			outbytes.text = "Out: " + outBytes.toString();
			outksec.text = outKSec.toString() + " k/s";
			outpackets.text = "#Packets: " + outPacketsSec.toString() + "/s";
		}
		
		private function test():void
		{
			setStats(61.5734332434, 92, 111.42576, 20, 259, 12.4, 31.24, 42, 2.5, 4.2);
		}
		
		function FormatDecimals(num:Number, digits:uint):String
		{
			var tenToPower:Number = Math.pow(10, digits);
			var cropped:String = String(Math.round(num * tenToPower) / tenToPower);
					
			var decimalPosition:int;
					
			for (var i:int = 0; i < cropped.length; i++) 
			{
				if (cropped.charAt(i) == ".")
				{
					decimalPosition = i;
				}
			}
					
			var output:String = cropped;
			var decimals:String = cropped.substr(decimalPosition + 1, cropped.length);
			var missingZeros:Number = digits - decimals.length;
					
			if (decimals.length < digits && decimalPosition > 0)
			{
				for (var j:int = 0; j < missingZeros; j++) 
				{
					output += "0";
				}
			}
					
			return output;
		}
	}
	
}