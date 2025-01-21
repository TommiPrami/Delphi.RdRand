unit Delphi.RdRnd;

interface

type
  TRDRANDAvailable = record
    RDRAND: Boolean;  // True if RDRAND is available
    RDSEED: Boolean;  // True if RDSEED is available
  end;

{$IF Defined(WIN64)}
  function RDSEED64(const ARetryCount: UInt64 = 10): UInt64;
  function RDRAND64(const ARetryCount: UInt64 = 10): UInt64;
{$ENDIF}

{$IF Defined(WIN32)}
  function RDSEED32(const ARetryCount: UInt32 = 10): UInt32;
  function RDRAND32(const ARetryCount: UInt32 = 10): UInt32;

  function RDSEED64(const ARetryCount: UInt32 = 10): UInt64;
  function RDRAND64(const ARetryCount: UInt32 = 10): UInt64;
{$ENDIF}

var
  RDInstructionsAvailable: TRDRANDAvailable;

implementation

const
  //ID string to identify CPU Vendor, the are a multitude .. but we focalize on this
  VendorIDxIntel: array [0..11] of AnsiChar = 'GenuineIntel';
  VendorIDxAMD: array [0..11] of AnsiChar = 'AuthenticAMD';

{$IF Defined(WIN64)}
function RDSEED64(const ARetryCount: UInt64 = 10): UInt64;
asm
  .noframe
  mov     RDX, ARetryCount
  inc     RDX
@LOOP:
  dec     RDX
  js      @Exit
  DB      $48, $0F, $C7, $F8  // RDSEED RAX
  jnc     @LOOP
@EXIT:
end;
{$ENDIF}

{$IF Defined(WIN64)}
function RDRAND64(const ARetryCount: UInt64 = 10): UInt64;
asm
  .noframe
  mov     RDX, ARetryCount
  inc     RDX
@LOOP:
  dec     RDX
  js      @Exit
  DB      $48, $0F, $C7, $F0  // RDRAND RAX
  jnc     @LOOP
@EXIT:
end;
{$ENDIF}

{$IF Defined(WIN32)}
function RDSEED32(const ARetryCount: UInt32 = 10): UInt32;
asm
  inc edx
@LOOP:
  dec     edx
  js      @Exit
  DB      $0F, $C7, $F8   // RDSEED EAX
  jnc     @LOOP
@EXIT:
end;
{$ENDIF}

{$IF Defined(WIN32)}
function RDRAND32(const ARetryCount: UInt32 = 10): UInt32;
asm
  inc edx
@LOOP:
  dec     edx
  js      @Exit
  DB      $48, $0F, $C7, $F0  // RDRAND EAX
  jnc     @LOOP
@EXIT:
end;
{$ENDIF}

{$IF Defined(WIN32)}
function RDSEED64(const ARetryCount: UInt32 = 10): UInt64;
var
  LValue1: UInt32;
  LValue2: UInt32;
begin
  LValue1 := RDSEED32(ARetryCount);
  LValue2 := RDSEED32(ARetryCount);

  Result := UInt64(LValue1) shl 32 or LValue2;
end;
{$ENDIF}

{$IF Defined(WIN32)}
function RDRAND64(const ARetryCount: UInt32 = 10): UInt64;
var
  LValue1: UInt32;
  LValue2: UInt32;
begin
  LValue1 := RDRAND32(ARetryCount);
  LValue2 := RDRAND32(ARetryCount);

  Result := UInt64(LValue1) shl 32 or LValue2;
end;
{$ENDIF}

{ 
  Internal functions, may be usefull to implement other check
  Tested in Win32 and Win64 Protected Mode, tested in virtual mode (WINXP - WIN11 32 bit and 64 bit), 
  not tested in real address mode
  The Intel Documentation has more detail about CPUID
  Jedi project has implemented TCPUInfo with more details.

  First check that the CPU supports CPUID instructions. There are some exceptions with this rule,
  but with very very old processors
}
function IsCPUIDValid: Boolean; register;
asm
 {$IFDEF WIN64}
  pushfq                               //Save EFLAGS
  pushfq                               //Store EFLAGS
  xor qword [esp], $00200000           //Invert the ID bit in stored EFLAGS
  popfq                                //Load stored EFLAGS (with ID bit inverted)
  pushfq                               //Store EFLAGS again (ID bit may or may not be inverted)
  pop rax                              //eax = modified EFLAGS (ID bit may or may not be inverted)
  xor rax, qword [esp]                 //eax = whichever bits were changed
  popfq                                //Restore original EFLAGS
  and RAX, $00200000                   //eax = zero if ID bit can't be changed, else non-zero
  jz @quit
  mov RAX, $01                         //If the Result is Boolean, the return parameter should be in A??? (true if A??? <> 0)
  @quit:
 {$ELSE}
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
 {$ENDIF}
end;

{
  1) Check that the CPU is an INTEL CPU, we don't know nothing about other's
     We can presume the AMD modern processors have the same check of INTEL, but only for some instructions.
     No test were made to verify this (no AMD processor available)

  2) Catch the features of the CPU in use

  3) Catch the new features of the CPU in use
}
procedure CPUIDGeneralCall(AInEAX: Cardinal; AInECX: Cardinal; out AReg_EAX, AReg_EBX, AReg_ECX, AReg_EDX); stdcall;
asm
 {$IFDEF WIN64}
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
  MOV R11, Reg_EDX
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
  MOV EAX, InEAX           //Generic function
  MOV ECX, InECX           //Generic sub function
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

// Function called from Initialization
function CheckRDInstructions: TRDRANDAvailable;
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
begin
  Result.RDRAND := False;
  Result.RDSEED := False;

  //Check if CPUID istruction is valid testing the bit 21 of EFLAGS
  if IsCPUIDValid then
  begin
    //Get the Vendor string with EAX = 0 and ECX = 0
    CPUIDGeneralCall(0, 0, LHighValBase, LVendorId[0], LVendorId[8], LVendorId[4]);

    //Verifiy that we are on CPU that we support
    if (LVendorId = VendorIDxIntel) or (LVendorId = VendorIDxAMD) then
    begin
      //Now check if RDRAND and RDSEED is supported inside the extended CPUID flags
      if LHighValBase >= 1 then  //Supports extensions
      begin
        //With EAX = 1 AND ECX = 0 the Extension and the available of RDRAND can be read
        CPUIDGeneralCall(1, 0, LVersionInfo, LAdditionalInfo, LExFeatures, LStdFeatures);

        //ExFeatures (ECX register) bit 30 is 1 if RDRAND is available
        if (LExFeatures and ($1 shl 30)) <> 0 then
          Result.RDRAND := True;

        if LHighValBase >= 7 then
        begin
          //With EAX = 7 AND ECX = 0 the NEW Extension and the available of RDSEED can be read
          CPUIDGeneralCall(7, 0, LHighValExt1, LNewFeatures, LUnUsed1, LUnUsed2);

          //New Features (EBX register) bit 18 is 1 if RDSEED is available
          if (LNewFeatures and ($1 shl 18)) <> 0 then
            Result.RDSEED := True;
        end;
      end;
    end;
  end;
end;

initialization
  RDInstructionsAvailable := CheckRDInstructions;

end.
