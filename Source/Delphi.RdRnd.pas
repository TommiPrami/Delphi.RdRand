unit Delphi.RdRnd;

interface

type
  TRDRANDAvailable = record
    RDRAND: Boolean;  // True if RDRAND is available
    RDSEED: Boolean;  // True if RDSEED is available
  end;

{
  The same API is available on every platform and bitness:
    - 64 bit x86: all functions use the native 64/32 bit instruction forms
    - 32 bit x86: the 64 bit values are composed from two 32 bit reads
    - non-x86 (e.g. Windows on ARM): everything compiles, RDInstructionsAvailable
      reports both instructions as unavailable and the Try* functions return False

  With RDRAND/RDSEED every bit is of equal quality - unlike with classic PRNGs
  there is no "weaker" half - so the 32 bit functions on a 64 bit build simply
  use the 32 bit form of the instruction.

  All functions make one attempt + up to ARetryCount retries.

  The Try* functions return False if the CPU could not deliver a value within the
  attempts (AValue is set to 0 in that case). The plain functions return 0 on
  failure, which is indistinguishable from a valid zero - prefer the Try*
  functions when failure matters (RDSEED especially can run out of entropy
  under heavy use).

  NOTE: The caller must check RDInstructionsAvailable first - executing these on
  an x86/x64 CPU without RDRAND/RDSEED support raises an invalid opcode exception.
}
  function TryRDSEED32(out AValue: UInt32; const ARetryCount: UInt32 = 10): Boolean;
  function TryRDRAND32(out AValue: UInt32; const ARetryCount: UInt32 = 10): Boolean;

  function TryRDSEED64(out AValue: UInt64; const ARetryCount: UInt32 = 10): Boolean;
  function TryRDRAND64(out AValue: UInt64; const ARetryCount: UInt32 = 10): Boolean;

  function RDSEED32(const ARetryCount: UInt32 = 10): UInt32;
  function RDRAND32(const ARetryCount: UInt32 = 10): UInt32;

  function RDSEED64(const ARetryCount: UInt32 = 10): UInt64;
  function RDRAND64(const ARetryCount: UInt32 = 10): UInt64;

var
  RDInstructionsAvailable: TRDRANDAvailable;

implementation

{$IF Defined(CPUX86) or Defined(CPUX64)}
const
  //ID strings to identify the CPU vendor; there are a multitude, but we focus on these
  VendorIDxIntel: array [0..11] of AnsiChar = 'GenuineIntel';
  VendorIDxAMD: array [0..11] of AnsiChar = 'AuthenticAMD';
{$ENDIF}

{$IF Defined(CPUX64)}
function TryRDSEED32(out AValue: UInt32; const ARetryCount: UInt32 = 10): Boolean;
asm
  .noframe
  // RCX = @AValue, EDX = ARetryCount
  inc     EDX
@LOOP:
  dec     EDX
  js      @FAIL
  DB      $0F, $C7, $F8        // RDSEED EAX
  jc      @SUCCESS
  DB      $F3, $90             // PAUSE, Intel recommends it between RDSEED retries
  jmp     @LOOP
@FAIL:
  xor     EAX, EAX
  mov     [RCX], EAX
  jmp     @DONE
@SUCCESS:
  mov     [RCX], EAX
  mov     EAX, $01
@DONE:
end;

function TryRDRAND32(out AValue: UInt32; const ARetryCount: UInt32 = 10): Boolean;
asm
  .noframe
  // RCX = @AValue, EDX = ARetryCount
  inc     EDX
@LOOP:
  dec     EDX
  js      @FAIL
  DB      $0F, $C7, $F0        // RDRAND EAX
  jnc     @LOOP
  mov     [RCX], EAX
  mov     EAX, $01
  jmp     @DONE
@FAIL:
  xor     EAX, EAX
  mov     [RCX], EAX
@DONE:
end;

function TryRDSEED64(out AValue: UInt64; const ARetryCount: UInt32 = 10): Boolean;
asm
  .noframe
  // RCX = @AValue, EDX = ARetryCount
  inc     EDX
@LOOP:
  dec     EDX
  js      @FAIL
  DB      $48, $0F, $C7, $F8   // RDSEED RAX
  jc      @SUCCESS
  DB      $F3, $90             // PAUSE, Intel recommends it between RDSEED retries
  jmp     @LOOP
@FAIL:
  xor     EAX, EAX
  mov     [RCX], RAX
  jmp     @DONE
@SUCCESS:
  mov     [RCX], RAX
  mov     EAX, $01
@DONE:
end;

function TryRDRAND64(out AValue: UInt64; const ARetryCount: UInt32 = 10): Boolean;
asm
  .noframe
  // RCX = @AValue, EDX = ARetryCount
  inc     EDX
@LOOP:
  dec     EDX
  js      @FAIL
  DB      $48, $0F, $C7, $F0   // RDRAND RAX
  jnc     @LOOP
  mov     [RCX], RAX
  mov     EAX, $01
  jmp     @DONE
@FAIL:
  xor     EAX, EAX
  mov     [RCX], RAX
@DONE:
end;
{$ELSEIF Defined(CPUX86)}
function TryRDSEED32(out AValue: UInt32; const ARetryCount: UInt32 = 10): Boolean;
asm
  // EAX = @AValue, EDX = ARetryCount
  mov     ECX, EAX             // Keep the pointer safe, RDSEED needs EAX
  inc     EDX
@LOOP:
  dec     EDX
  js      @FAIL
  DB      $0F, $C7, $F8        // RDSEED EAX
  jc      @SUCCESS
  DB      $F3, $90             // PAUSE, Intel recommends it between RDSEED retries
  jmp     @LOOP
@FAIL:
  xor     EAX, EAX
  mov     [ECX], EAX
  jmp     @DONE
@SUCCESS:
  mov     [ECX], EAX
  mov     EAX, $01
@DONE:
end;

function TryRDRAND32(out AValue: UInt32; const ARetryCount: UInt32 = 10): Boolean;
asm
  // EAX = @AValue, EDX = ARetryCount
  mov     ECX, EAX             // Keep the pointer safe, RDRAND needs EAX
  inc     EDX
@LOOP:
  dec     EDX
  js      @FAIL
  DB      $0F, $C7, $F0        // RDRAND EAX
  jnc     @LOOP
  mov     [ECX], EAX
  mov     EAX, $01
  jmp     @DONE
@FAIL:
  xor     EAX, EAX
  mov     [ECX], EAX
@DONE:
end;

function TryRDSEED64(out AValue: UInt64; const ARetryCount: UInt32 = 10): Boolean;
var
  LHigh: UInt32;
  LLow: UInt32;
begin
  Result := TryRDSEED32(LHigh, ARetryCount) and TryRDSEED32(LLow, ARetryCount);

  if Result then
    AValue := UInt64(LHigh) shl 32 or LLow
  else
    AValue := 0;
end;

function TryRDRAND64(out AValue: UInt64; const ARetryCount: UInt32 = 10): Boolean;
var
  LHigh: UInt32;
  LLow: UInt32;
begin
  Result := TryRDRAND32(LHigh, ARetryCount) and TryRDRAND32(LLow, ARetryCount);

  if Result then
    AValue := UInt64(LHigh) shl 32 or LLow
  else
    AValue := 0;
end;
{$ELSE}
function TryRDSEED32(out AValue: UInt32; const ARetryCount: UInt32 = 10): Boolean;
begin
  AValue := 0;
  Result := False;
end;

function TryRDRAND32(out AValue: UInt32; const ARetryCount: UInt32 = 10): Boolean;
begin
  AValue := 0;
  Result := False;
end;

function TryRDSEED64(out AValue: UInt64; const ARetryCount: UInt32 = 10): Boolean;
begin
  AValue := 0;
  Result := False;
end;

function TryRDRAND64(out AValue: UInt64; const ARetryCount: UInt32 = 10): Boolean;
begin
  AValue := 0;
  Result := False;
end;
{$ENDIF}

function RDSEED32(const ARetryCount: UInt32 = 10): UInt32;
begin
  TryRDSEED32(Result, ARetryCount);
end;

function RDRAND32(const ARetryCount: UInt32 = 10): UInt32;
begin
  TryRDRAND32(Result, ARetryCount);
end;

function RDSEED64(const ARetryCount: UInt32 = 10): UInt64;
begin
  TryRDSEED64(Result, ARetryCount);
end;

function RDRAND64(const ARetryCount: UInt32 = 10): UInt64;
begin
  TryRDRAND64(Result, ARetryCount);
end;

{$IF Defined(CPUX86) or Defined(CPUX64)}
{
  Internal functions, may be useful to implement other checks
  Tested in Win32 and Win64 Protected Mode, tested in virtual mode
  (WINXP - WIN11 32 bit and 64 bit).

  Not tested in real address mode.

  The Intel Documentation has more detail about CPUID.

  Jedi project has implemented TCPUInfo with more details.

  First check that the CPU supports the CPUID instruction.
  There are some exceptions to this rule, but only with very old
  32 bit processors - in 64-bit mode CPUID is always available.
}
{$IF Defined(CPUX64)}
function IsCPUIDValid: Boolean;
begin
  Result := True;
end;
{$ELSE}
function IsCPUIDValid: Boolean; register;
asm
  pushfd                               //Save EFLAGS
  pushfd                               //Store EFLAGS
  xor dword [esp], $00200000           //Invert the ID bit in stored EFLAGS
  popfd                                //Load stored EFLAGS (with ID bit inverted)
  pushfd                               //Store EFLAGS again (ID bit may or may not be inverted)
  pop eax                              //eax = modified EFLAGS (ID bit may or may not be inverted)
  xor eax,[esp]                        //eax = whichever bits were changed
  popfd                                //Restore original EFLAGS
  and eax, $00200000                   //eax = zero if ID bit can't be changed, else non-zero
  jz @quit
  mov EAX, $01                         //If the Result is Boolean, the return parameter should be in AL (true if AL <> 0)
  @quit:
end;
{$ENDIF}

{
  1) Check that the CPU is an Intel or AMD CPU, we know nothing about the others.
     We can presume that modern AMD processors have the same checks as Intel,
     but only for some instructions.

     No tests were made to verify this (no AMD processor available).

  2) Read the features of the CPU in use

  3) Read the new features of the CPU in use
}
procedure CPUIDGeneralCall(AInEAX: Cardinal; AInECX: Cardinal; out AReg_EAX, AReg_EBX, AReg_ECX, AReg_EDX); stdcall;
asm
 {$IFDEF CPUX64}
  // save context
  PUSH RBX
  // CPUID
  MOV EAX, AInEAX           //Generic function
  MOV ECX, AInECX           //Generic sub function
  //
  //For CPU VENDOR STRING EAX := $0
  //ECX is not used when EAX = $0
  //
  //For CPU Extension EAX := $01
  //ECX is not used when EAX = $01
  //
  //For CPU New Extension EAX := $07
  //ECX should be $00 to read if RDSEED is available
  //
  CPUID
  // store results
  MOV R8, AReg_EAX
  MOV R9, AReg_EBX
  MOV R10, AReg_ECX
  MOV R11, AReg_EDX
  MOV Cardinal PTR [R8], EAX
  MOV Cardinal PTR [R9], EBX
  MOV Cardinal PTR [R10], ECX
  MOV Cardinal PTR [R11], EDX
  // restore context
  POP RBX
 {$ELSE}
  // save context
  PUSH EDI
  PUSH EBX
  // CPUID
  MOV EAX, AInEAX           // Generic function
  MOV ECX, AInECX           // Generic sub function
  //
  //For CPU VENDOR STRING EAX := $0
  //ECX is not used when EAX = $0
  //
  //For CPU Extension EAX := $01
  //ECX is not used when EAX = $01
  //
  //For CPU New Extension EAX := $07
  //ECX should be $00 to read if RDSEED is available
  //
  CPUID
  // store results
  MOV EDI, AReg_EAX
  MOV Cardinal PTR [EDI], EAX
  MOV EAX, AReg_EBX
  MOV EDI, AReg_ECX
  MOV Cardinal PTR [EAX], EBX
  MOV Cardinal PTR [EDI], ECX
  MOV EAX, AReg_EDX
  MOV Cardinal PTR [EAX], EDX
  // restore context
  POP EBX
  POP EDI
 {$ENDIF}
end;
{$ENDIF}

// Function called from Initialization
function CheckRDInstructions: TRDRANDAvailable;
{$IF Defined(CPUX86) or Defined(CPUX64)}
var
  LVendorId: array [0..11] of AnsiChar;
  LHighValBase: Cardinal;
  LHighValExt1: Cardinal;
  LVersionInfo: Cardinal;
  LAdditionalInfo: Cardinal;
  LExFeatures: Cardinal;
  LStdFeatures: Cardinal;
  LUnUsed1: Cardinal;
  LUnUsed2: Cardinal;
  LNewFeatures: Cardinal;
{$ENDIF}
begin
  Result.RDRAND := False;
  Result.RDSEED := False;

{$IF Defined(CPUX86) or Defined(CPUX64)}
  //Check if the CPUID instruction is valid by testing bit 21 of EFLAGS
  if IsCPUIDValid then
  begin
    //Get the Vendor string with EAX = 0 and ECX = 0
    CPUIDGeneralCall(0, 0, LHighValBase, LVendorId[0], LVendorId[8], LVendorId[4]);

    //Verify that we are on a CPU that we support
    if (LVendorId = VendorIDxIntel) or (LVendorId = VendorIDxAMD) then
    begin
      //Now check if RDRAND and RDSEED are supported inside the extended CPUID flags
      if LHighValBase >= 1 then  //Supports extensions
      begin
        //With EAX = 1 and ECX = 0 the Extensions and the availability of RDRAND can be read
        CPUIDGeneralCall(1, 0, LVersionInfo, LAdditionalInfo, LExFeatures, LStdFeatures);

        //ExFeatures (ECX register) bit 30 is 1 if RDRAND is available
        if (LExFeatures and ($1 shl 30)) <> 0 then
          Result.RDRAND := True;

        if LHighValBase >= 7 then
        begin
          //With EAX = 7 and ECX = 0 the NEW Extensions and the availability of RDSEED can be read
          CPUIDGeneralCall(7, 0, LHighValExt1, LNewFeatures, LUnUsed1, LUnUsed2);

          //New Features (EBX register) bit 18 is 1 if RDSEED is available
          if (LNewFeatures and ($1 shl 18)) <> 0 then
            Result.RDSEED := True;
        end;
      end;
    end;
  end;
{$ENDIF}
end;

initialization
  RDInstructionsAvailable := CheckRDInstructions;

end.
