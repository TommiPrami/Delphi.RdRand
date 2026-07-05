# Delphi.RdRand

Library for the CPU-implemented random number generator instructions RDRAND and RDSEED.

* `Source\Delphi.RdRnd.pas` — the library, a single unit with no dependencies
* `Demo\Delphi.RdRnd.Demo.dproj` — VCL demo application

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

Always check `RDInstructionsAvailable` first — calling the functions on an x86/x64 CPU
without RDRAND/RDSEED support raises an invalid opcode exception. The record is filled
once at unit initialization via CPUID:

```pascal
var
  RDInstructionsAvailable: TRDRANDAvailable;  // .RDRAND and .RDSEED Booleans
```

### API

The same API is available on every platform and bitness — no IFDEFs needed in calling code.

Single values:

```pascal
function TryRDSEED32(out AValue: UInt32; const ARetryCount: UInt32 = 10): Boolean;
function TryRDRAND32(out AValue: UInt32; const ARetryCount: UInt32 = 10): Boolean;
function TryRDSEED64(out AValue: UInt64; const ARetryCount: UInt32 = 10): Boolean;
function TryRDRAND64(out AValue: UInt64; const ARetryCount: UInt32 = 10): Boolean;

function RDSEED32(const ARetryCount: UInt32 = 10): UInt32;
function RDRAND32(const ARetryCount: UInt32 = 10): UInt32;
function RDSEED64(const ARetryCount: UInt32 = 10): UInt64;
function RDRAND64(const ARetryCount: UInt32 = 10): UInt64;
```

Buffer fill (RDRAND based), with both a TStream style untyped parameter and a
`Pointer` + byte count overload:

```pascal
function TryFillRandom(const ABuffer: Pointer; const ACount: NativeInt; const ARetryCount: UInt32 = 10): Boolean;
function TryFillRandom(var ABuffer; const ACount: NativeInt; const ARetryCount: UInt32 = 10): Boolean;

procedure FillRandom(const ABuffer: Pointer; const ACount: NativeInt; const ARetryCount: UInt32 = 10);
procedure FillRandom(var ABuffer; const ACount: NativeInt; const ARetryCount: UInt32 = 10);
```

```pascal
var
  LKey: array [0..31] of Byte;
begin
  if TryFillRandom(LKey, SizeOf(LKey)) then
    // use LKey
end;
```

Typed pointer variables (`PByte` and friends) bind to the `Pointer` overload, so they fill
the memory they point to, not the pointer variable itself.

### Failure and retry semantics

Every function makes one attempt + up to `ARetryCount` retries. The RDSEED retry loops
execute a `PAUSE` instruction between attempts, as Intel recommends.

The `Try*` functions return `False` if the CPU could not deliver a value within the retries —
the `out` value is 0 and a `TryFillRandom` buffer is completely zeroed in that case, so it
never contains half-filled or stale data. The plain functions return 0 on failure, which is
indistinguishable from a valid zero — prefer the `Try*` functions when failure matters.

RDRAND practically never fails (a few retries always suffice). RDSEED reads the hardware
entropy source directly and legitimately runs dry under heavy use: hammered in a tight
loop with zero retries, well over half of the calls can fail. The demo application makes
this visible.

### RDRAND or RDSEED?

* **RDRAND** — output of a DRBG (deterministic random bit generator, AES based) that is
  re-seeded frequently from the entropy source. Use for bulk random data and general use.
  `FillRandom` uses it.
* **RDSEED** — conditioned entropy straight from the hardware source. Slower and can run
  dry; meant for seeding other generators (or generating long-lived key material).

With RDRAND/RDSEED every bit is of equal quality — unlike with classic PRNGs there is no
"weaker" half to avoid. That is also why on a 64 bit build the 32 bit functions simply use
the native 32 bit form of the instruction, and on a 32 bit build the 64 bit values are
composed from two 32 bit reads.

### Supported CPUs and platforms

* Intel and AMD x86/x64 processors that report RDRAND/RDSEED support via CPUID
* Win32 and Win64 tested; the conditionals are CPU based (`CPUX86`/`CPUX64`), not OS based
* On other CPUs (e.g. Windows on ARM) the unit still compiles: `RDInstructionsAvailable`
  reports both instructions as unavailable, the `Try*` functions return `False` and the
  plain functions return 0

### Demo application

The VCL demo in `Demo\` has two tabs:

* **API demo** — availability check, every scalar function, a `TryFillRandom` hex dump, and
  an RDSEED entropy stress test (2 million zero-retry calls with a failure percentage)
* **Randomness bitmaps** — the classic [pseudo-random vs. random](https://www.r-bloggers.com/2011/11/pseudo-random-vs-random-numbers-in-r-2/)
  noise comparison: Delphi RTL `Random` and RDRAND side by side, as black/white
  (one random bit per pixel) and as random colors (`TryFillRandom` straight into the
  bitmap scanlines), with timings

### Forum post about this
* https://en.delphipraxis.net/topic/10271-getting-rdseed-with-delphi/?tab=comments#comment-81748
  * Special thanks to the Delphi Praxis users (who made the vast majority of the implementation and gave a lot of insight on this matter).
    * DelphiUdIT (implementation, RDRAND and RDSEED instruction availability checks)
    * Kas Ob

### TODO:
* Testing that it actually works on different CPU models and brands as expected
