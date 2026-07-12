<CoundSynthesizer>
<CsOptions>
-+rtmidi=NULL -M0 --midi-key=5 --midi-velocity=6 -n
</CsOptions>
<CsInstruments>

sr = 48000
ksmps = 32
nchnls = 2
0dbfs = 1

massign 0, 0

#include "addons/synths/amsynth_common.inc"

#define INSTRUMENT_NAME #synth#
#define INSTRUMENT_CHANNEL #1#

#include "addons/synths/amsynth_instr.inc"

#define INSTRUMENT_NAME #jump#
#define INSTRUMENT_CHANNEL #2#

#include "addons/synths/amsynth_instr.inc"
maxalloc "$INSTRUMENT_NAME", 2, 1

#define INSTRUMENT_NAME #shoot#
#define INSTRUMENT_CHANNEL #3#

#include "addons/synths/amsynth_instr.inc"
maxalloc "$INSTRUMENT_NAME", 2, 1

</CsInstruments>
<CsScore>
f 1 0 16384 10 1 ;sine
f 0 z
i "synth_mixer" 0 -1
i "jump_mixer" 0 -1
i "shoot_mixer" 0 -1

</CsScore>
</CsoundSynthesizer>
