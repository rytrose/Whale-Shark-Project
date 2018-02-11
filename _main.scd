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
var numChannels = 2;
var busses = Array.fill(numChannels, {Bus.control(s)});
var trackBuffer;
var panValue = 0;
var randWalkState = true; //true is forwards
var markovWalk = {|pChange, state| if(1.0.rand < pChange, {state.not}, {state})};
var walkStep = 0.005;
var pChange = 0.05;
var randWalkTask = Task({
    {
        randWalkState = markovWalk.(pChange, randWalkState);
        panValue = (panValue + if(randWalkState, walkStep, 0-walkStep)) % numChannels;
        //fill in calculating what two speakers are played through and by how much
        busses[panValue.floor].set(panValue%1);
        busses[panValue.ceil % numChannels].set(1 - (panValue%1));
        0.01.wait;
        // ["PAN VAL", panValue].postln;
    }.loop;
}); 
 
s = Server.default;

s.options.numAnalogInChannels = 8;
s.options.numAnalogOutChannels = 8;
s.options.numDigitalChannels = 16;

s.options.blockSize = 16;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2; // Need to change

s.options.postln;



s.waitForBoot({
	// "http://doc.sccode.org/Classes/PlayBuf.html"
	// http://supercollider.sourceforge.net/wiki/index.php/If_statements_in_a_SynthDef
	
	// Read Arduino from USB port
	p = SerialPort(
	    "/dev/ttyACM0",
	    baudrate: 9600);
	
	// Color values
	~avgBufferSize = 5;
	~r = Array.new(~avgBufferSize);
	~g = Array.new(~avgBufferSize);
	~b = Array.new(~avgBufferSize);
	~colorState = 0;
	~freqBus = Bus.control(s);
	    
	/*this is the synth structure that will allow us to use a single PlayBuf and swing it
	around a circle of 8 speakers by controlling the volume at each speaker individually*/
	~busses = [Bus.control(s), Bus.control(s)];
	
	 Routine.run {
        s.bootSync;


		Platform.resourceDir.postln;
        trackBuffer = Buffer.readChannel(s, Platform.resourceDir +/+ "sounds/FloatingUp_Movement02.wav", channels: [0]);

        SynthDef.new("whaleSpeakers", {
            // Out.ar(0, SinOsc.ar(440) * SinOsc.ar(330) * In.kr(busses[1]));
            // Out.ar(1, SinOsc.ar(430) * In.kr(busses[0]));
            var playBuf = PlayBuf.ar(1, trackBuffer, loop: 1);
            (0..(busses.size-1)).do({|ind| AnalogOut.ar(ind, playBuf.range(0.05, 0.95) * In.kr(busses[ind]))});
        }).send(s);

        s.sync;

        ~synth = Synth.new("whaleSpeakers");

        s.sync;

        randWalkTask.play;
    };

	// Read color and set proper frequency
	Routine.run ({
	    var byte, str, setColor;
	    
	    setColor = { arg r, g, b;
	    	var rSum, rAvg, gSum, gAvg, bSum, bAvg;
	   		if(~r.size < (~avgBufferSize + 1), {
	   			~r.add(r);
	   			~g.add(g);
	   			~b.add(b);
	   		}, {
	   			~r = ~r.shift(1, filler: r);
	   			~g = ~g.shift(1, filler: g);
	   			~b = ~b.shift(1, filler: b);
	   		});
	   		
	   		rSum = 0;
			~r.do{ arg item, i;
				rSum = rSum + item;
			};
			rAvg = rSum / ~r.size;
			
			gSum = 0;
			~g.do{ arg item, i;
				gSum = gSum + item;
			};
			gAvg = gSum / ~g.size;
			
			bSum = 0;
			~b.do{ arg item, i;
				bSum = bSum + item;
			};
			bAvg = bSum / ~b.size;
			
			~colorState = case
							{(rAvg > gAvg) && (rAvg > bAvg)} {~colorState = 0}
							{(gAvg > rAvg) && (gAvg > bAvg)} {~colorState = 1}
							{(bAvg > rAvg) && (bAvg > gAvg)} {~colorState = 2};
							
			~freqBus.set(~colorState);
		};
	    
	    inf.do{|i|
	        if(p.read==10, {
	            str = "";
	            while({byte = p.read; byte !=13 }, {
	                str= str++byte.asAscii;
	            });
	            if(str.contains("|"), {
	            	var arr = str.split($|);
	            	setColor.value(arr[0].asInteger, arr[1].asInteger, arr[2].asInteger);
	            });
	            
	        });
	    };
	   
	});
	
	// ~busses[0].set()

});
