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
/*this is the synth structure that will allow us to use a single PlayBuf and swing it
around a circle of 8 speakers by controlling the volume at each speaker individually*/
var numChannels = 8;
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
        ["PAN VAL", panValue].postln;
    }.loop;
});


s = Server.default;

s.options.numAnalogInChannels = 8;
s.options.numAnalogOutChannels = 8;
s.options.numDigitalChannels = 16;

s.options.blockSize = 16;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;

s.options.postln;

s.waitForBoot({
    Routine.run {
        s.bootSync;

        trackBuffer = Buffer.read(s, "/Users/avneeshsarwate/Downloads/BPB Black Friday Sample Pack 2017/CONTENT/ModeAudio/ModeAudio - BPB Exclusive Sounds 17/Eclipse - Dark Ambient Samples & Drones/Drone Samples/FloatingUp_Movement02.wav");

        SynthDef.new("whaleSpeakers", {
            // Out.ar(0, SinOsc.ar(440) * SinOsc.ar(330) * In.kr(busses[1]));
            // Out.ar(1, SinOsc.ar(430) * In.kr(busses[0]));
            var playBuf = PlayBuf.ar(1, trackBuffer, loop: 1);
            (0..(busses.size-1)).do({|ind| AnalogOut.ar(ind, playBuf * In.kr(busses[ind]))});
        }).send(s);

        s.sync;

        ~synth = Synth.new("whaleSpeakers");

        s.sync;

        randWalkTask.play;
    };

});
