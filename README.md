# Delphi.RdRand

Library for the CPU-implemented random number generator instructions RDRAND and RDSEED.

### Usage

```pascal
uses
  Delphi.RdRnd;

var
  LValue: UInt64;
begin
  if RDInstructionsAvailable.RDSEED and TryRDSEED64(LValue) then
    // use LValue
end;
```

The same API is available on both 32 and 64 bit builds: `RDRAND32`/`RDSEED32`,
`RDRAND64`/`RDSEED64` and their `Try*` variants. On a 64 bit build the 32 bit functions use
the native 32 bit form of the instruction; on a 32 bit build the 64 bit values are composed
from two 32 bit reads. (With RDRAND/RDSEED every bit is of equal quality — unlike with
classic PRNGs there is no "weaker" half to avoid.)

The `Try*` functions return `False` if the CPU could not deliver a value within the retry count
(RDSEED especially can run out of entropy under heavy use). The plain `RDRAND64`/`RDSEED64`
functions return 0 in that case, which is indistinguishable from a valid zero.

Always check `RDInstructionsAvailable` first — calling the functions on a CPU without
RDRAND/RDSEED support raises an invalid opcode exception.

### Supported CPUs

* Intel and AMD x86/x64 processors that report RDRAND/RDSEED support via CPUID
* On other CPUs (e.g. Windows on ARM) the unit still compiles: `RDInstructionsAvailable` reports both instructions as unavailable and the `Try*` functions return `False`

### Forum post about this
* https://en.delphipraxis.net/topic/10271-getting-rdseed-with-delphi/?tab=comments#comment-81748
  * Special thanks to the Delphi Praxis users (who made the vast majority of the implementation and gave a lot of insight on this matter).
    * DelphiUdIT (implementation, RDRAND and RDSEED instruction availability checks)
    * Kas Ob

### TODO:
* Testing that it actually works on different CPU models and brands as expected
