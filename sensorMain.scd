/**
This script exemplifies the use of SuperCollider on Bela.
When a project contains a `_main.scd` file, `sclang` is started
and the content of the file is executed.
If you want to interact with SuperCollider running on the board
from within the SuperCollider IDE on your computer, check out 
the 12-SuperCollider/remote examples instead.
Those files also include more code examples to interface with
Bela-specific UGens.

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
	var avgBufferSize, rValues, gValues, bValues, distanceValues, colorStates, numSerialPorts, colorBusses, distanceBusses;
	
	"USB Ports".postln;
	SerialPort.listDevices;
	"-----".postln;
	
	SerialPort.devicePattern = "/dev/ttyUSB*";
	numSerialPorts = SerialPort.devices.size + 1;
	
	// Color values
	avgBufferSize = 5;
	rValues = Array.fill(numSerialPorts, {Array.fill(avgBufferSize, 0)});
	gValues = Array.fill(numSerialPorts, {Array.fill(avgBufferSize, 0)});
	bValues = Array.fill(numSerialPorts, {Array.fill(avgBufferSize, 0)});
	distanceValues = Array.fill(numSerialPorts, 0);
	colorStates = Array.fill(numSerialPorts, 0);
	colorBusses = Array.fill(numSerialPorts, {Bus.control(s)});
	distanceBusses = Array.fill(numSerialPorts, {Bus.control(s)});
	
	(0..(numSerialPorts-1)).do({ |index|
	
		var serialRoutineFunc = {
		    var port, byte, str, setColor;
		    
		    if(index == 0, 
		    	{
		    		port = SerialPort(
		    			"/dev/ttyACM0",
	    				baudrate: 9600,
	    				crtscts: true);
		    	}, 
		    	{
		    		port = SerialPort(
		    			"/dev/ttyUSB" ++ (index-1),
	    				baudrate: 9600,
	    				crtscts: true);
		    	}
		    );
		    
		    setColor = { arg r, g, b;
		    	var rSum, rAvg, gSum, gAvg, bSum, bAvg;
		    	
		   		if(rValues[index].size < (avgBufferSize + 1), {
		   			rValues[index].add(r);
		   			gValues[index].add(g);
		   			bValues[index].add(b);
		   		}, {
		   			rValues[index] = rValues[index].shift(1, filler: r);
		   			gValues[index] = gValues[index].shift(1, filler: g);
		   			bValues[index] = bValues[index].shift(1, filler: b);
		   		});
		   		
		   		rSum = 0;
				rValues[index].do{ arg item, i;
					rSum = rSum + item;
				};
				rAvg = rSum / rValues[index].size;
				
				gSum = 0;
				gValues[index].do{ arg item, i;
					gSum = gSum + item;
				};
				gAvg = gSum / gValues[index].size;
				
				bSum = 0;
				bValues[index].do{ arg item, i;
					bSum = bSum + item;
				};
				bAvg = bSum / bValues[index].size;
				
				case
					{(rAvg > gAvg) && (rAvg > bAvg)} {colorStates[index] = 0}
					{(gAvg > rAvg) && (gAvg > bAvg)} {colorStates[index] = 1}
					{(bAvg > rAvg) && (bAvg > gAvg)} {colorStates[index] = 2};
					
				colorBusses[index].set(colorStates[index]);
			};
		    
		    inf.do{
		    	if(port.read==10, {
		            str = "";
		            while({byte = port.read; byte !=13 }, {
		                str= str++byte.asAscii;
		            });
		            if(str.contains("|"), {
		            	var arr = str.split($|);
		            	
		            	if(arr.size < 4, 
			            	{
			            		[index, "Bad data"].postln;
			            	},
			            	{
			            		setColor.(arr[0].asInteger, arr[1].asInteger, arr[2].asInteger);
			            		distanceValues[index] = arr[3].asFloat;
			            		distanceBusses[index].set(distanceValues[index]);
			            	}
		            	);
		            });
		            
		        });
		    };
		};
	
		Routine.run(serialRoutineFunc);
	});
	
	   
	/*this is the synth structure that will allow us to use a single PlayBuf and swing it
	around a circle of 8 speakers by controlling the volume at each speaker individually*/
	
	 Routine.run {
        s.bootSync;

        SynthDef.new("whaleSpeakers", {
            // Out.ar(0, SinOsc.ar(440) * SinOsc.ar(330) * In.kr(busses[1]));
            // Out.ar(1, SinOsc.ar(430) * In.kr(busses[0]));
            (0..(numSerialPorts-1)).do({|ind| AnalogOut.ar(ind, SinOsc.ar((ind+1) * 220 + (30  * In.kr(colorBusses[ind]))) * (1 - (In.kr(distanceBusses[ind]) / 50)))});
        }).send(s);

        s.sync;

        ~synth = Synth.new("whaleSpeakers");

        s.sync;
    };

});
