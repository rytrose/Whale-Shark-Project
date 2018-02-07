
(
s.waitForBoot{{


    Out.ar(0, [SinOsc.ar(440, 0, SinOsc.kr(2)) * SinOsc.ar(330, 0, SinOsc.kr(4)), SinOsc.ar(330, 0, 0.25)]);


}.play};

)

// "http://doc.sccode.org/Classes/PlayBuf.html"
// http://supercollider.sourceforge.net/wiki/index.php/If_statements_in_a_SynthDef

(
/*this is the synth structure that will allow us to use a single PlayBuf and swing it
around a circle of 8 speakers by controlling the volume at each speaker individually*/
var busses = Array.fill(8, {Bus.control(s)});
~busses = busses;
var trackBuffer = Buffer.read(s, "/Users/avneeshsarwate/Downloads/BPB Black Friday Sample Pack 2017/CONTENT/ModeAudio/ModeAudio - BPB Exclusive Sounds 17/Eclipse - Dark Ambient Samples & Drones/Drone Samples/FloatingUp_Movement02.wav");
var panValue = 0;
var randWalkState = true; //true is forwards
var markovWalk = {|pChange, state| if(1.0.rand < pChange, {state.not}, {state})};
var walkStep = 0.1;
var pChange = 0.05;
var randWalkTask = Task({
    {
        randWalkState = markovWalk.(pChange, randWalkState);
        panValue = (randWalkState + if(randWalkState, walkState, -walkStep)) % 8;
        //fill in calculating what two speakers are played through and by how much
    }.loop;
Routine.run {
	s.bootSync;

	SynthDef.new("whaleSpeakers", {
        Out.ar(0, SinOsc.ar(440) * SinOsc.ar(330) * In.kr(~busses[1]));
        Out.ar(1, SinOsc.ar(430) * In.kr(~busses[0]));
        (0..(busses.size-1)).do({|ind| AnalogOut.ar(ind, PlayBuf.ar(1, trackBuffer) * busses[ind])});
	}).send(s);

	s.sync;

	~synth = Synth.new("whaleSpeakers");
};

)
~busses[0].set(1)



(
/*this is the synth structure that will allow us to determine the note played by a transducer based on the color reading*/
//for transducer i, bus i*2 controls volume and i*2+1 controls pitch
var busses = Array.fill(8 * 2, {Bus.control(s)});
~busses = busses;

Routine.run {
	s.bootSync;

	SynthDef.new("whaleVibes", {
        Select
        Out.ar(0, SinOsc.ar(440) * SinOsc.ar(330) * In.kr(~busses[1]));
        Out.ar(1, SinOsc.ar(430) * In.kr(~busses[0]));
        (0..(busses.size-1)).do({|ind|
            var outputSignals = [SinOsc.ar(440)*busses[ind], SinOsc.ar(220)*busses[ind], SinOsc.ar(330)*busses[ind]];
            var condition = (busses[ind*2+1] > 0.33) + (busses[ind*2+1] > 0.66);
            AnalogOut.ar(ind*2, Select.ar(condition, outputSignals));
        });
	}).send(s);

	s.sync;

	~synth = Synth.new("whaleVibes");
};

)