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

/*this is the synth structure that will allow us to determine the note played by a transducer based on the color reading*/
//for transducer i, bus i*2 controls volume and i*2+1 controls pitch
var numChannels = 1;
var busses = Array.fill(numChannels * 2, {Bus.control(s)});

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
    ~d = 0;


    Routine.run {
        s.bootSync;

        SynthDef.new("whaleVibes", {
            // Out.ar(0, SinOsc.ar(440) * SinOsc.ar(330) * In.kr(~busses[1]));
            // Out.ar(1, SinOsc.ar(430) * In.kr(~busses[0]));
            (0..(busses.size/2-1)).do({|ind|
                var outputSignals = [SinOsc.ar(440), SinOsc.ar(220), SinOsc.ar(330)];
                var pitchBus = In.kr(busses[ind*2+1]);
                var condition = (pitchBus > 0.33) + (pitchBus > 0.66);
                Out.ar(ind, Select.ar(condition, outputSignals) * In.kr(busses[ind*2]));
            });
        }).send(s);

        s.sync;

        ~synth = Synth.new("whaleSpeakers");
    };

    Routine.run {
        s.bootSync;

        SynthDef.new("whaleActuators", {
            var cond = (~vbusses[0] > .3) + (~busses[0] > .6);
            AnalogOut.ar(0, Select.ar(cond, [SinOsc.ar(440), SinOsc.ar(220), SinOsc.ar(330)]))
        }).send(s);

        s.sync;

        ~synth = Synth.new("whaleActuators");
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
                ("b:"+ ~b).postln;
                busses[1].set(~r);

                //write serial values to busses here with ~busses[i].set(val)
            });
        };
    });

});
