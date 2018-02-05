
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
~busses = [Bus.control(s), Bus.control(s)];

Routine.run {
	s.bootSync;

	SynthDef.new("whale", {
        Out.ar(0, SinOsc.ar(440) * SinOsc.ar(330) * In.kr(~busses[1]));
        Out.ar(1, SinOsc.ar(430) * In.kr(~busses[0]));
	}).send(s);

	s.sync;

	~synth = Synth.new("whale");
};

)
~busses[0].set(1)



(
/*this is the synth structure that will allow us to use a single PlayBuf and swing it
around a circle of 8 speakers by controlling the volume at each speaker individually*/
~busses = [Bus.control(s), Bus.control(s)];

Routine.run {
	s.bootSync;

	SynthDef.new("whale", {
        Out.ar(0, SinOsc.ar(440) * SinOsc.ar(330) * In.kr(~busses[1]));
        Out.ar(1, SinOsc.ar(430) * In.kr(~busses[0]));
	}).send(s);

	s.sync;

	~synth = Synth.new("whale");
};

)