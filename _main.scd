/**
This script exemplifies the use of SuperCollider on Bela.
When a project contains a `_main.scd` file, `sclang` is started
and the content of the file is executed.
If you want to interact with SuperCollider running on the board
from within the SuperCollider IDE on your computer, check out 
the 12-SuperCollider/remote examples instead.
Those files also include more code examples to interface with
Bela-specific UGens.
 */
s = Server.default;

s.options.numAnalogInChannels = 8;
s.options.numAnalogOutChannels = 8;
s.options.numDigitalChannels = 16;

s.options.blockSize = 16;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;

s.options.postln;

s.waitForBoot({
	// "http://doc.sccode.org/Classes/PlayBuf.html"
	// http://supercollider.sourceforge.net/wiki/index.php/If_statements_in_a_SynthDef
	
	// Read Arduino from USB port
	p = SerialPort(
	    "/dev/ttyACM0",
	    baudrate: 9600);
	
	// Color values
	~r = 0;
	~g = 0;
	~b = 0;
	    
	/*this is the synth structure that will allow us to use a single PlayBuf and swing it
	around a circle of 8 speakers by controlling the volume at each speaker individually*/
	~busses = [Bus.control(s), Bus.control(s)];
	
	Routine.run {
		s.bootSync;
	
		SynthDef.new("whale", {
	        Out.ar(0, SinOsc.ar(440	) * SinOsc.ar(330) * In.kr(~busses[1]));
	        Out.ar(1, SinOsc.ar(430) * In.kr(~busses[0]));
		}).send(s);
	
		s.sync;
	
		~synth = Synth.new("whale");
	};


	Routine.run ({
	    var byte, str;
	    inf.do{|i|
	        if(p.read==10, {
	            str = "";
	            while({byte = p.read; byte !=13 }, {
	                str= str++byte.asAscii;
	            });
	            if(str.contains("|"), {
	            	var arr = str.split($|);
	            	~r = arr[0].asInteger;
	            	~g = arr[1].asInteger;
	            	~b = arr[2].asInteger;
	            });
	            ("r:"+ ~r + ", ").post;
	            ("g:"+ ~g + ", ").post;
	            ("b:"+ ~r).postln;
	        });
	    };
	});
	
	// ~busses[0].set()

});
