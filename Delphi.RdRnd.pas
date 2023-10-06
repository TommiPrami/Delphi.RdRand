unit Delphi.RdRnd;

interface

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

implementation

{$IF Defined(WIN64)}
function RDSEED64(const ARetryCount: UInt64 = 10): UInt64;
asm
  .noframe
  mov     RDX, aRetryCount
  inc     RDX
@LOOP:
  dec     RDX
  js      @Exit
  DB      $48, $0F, $C7, $F8  // RDSEED RAX
  jnc     @LOOP
@EXIT:
end;

function RDRAND64(const ARetryCount: UInt64 = 10): UInt64;
asm
  .noframe
  mov     RDX, aRetryCount
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

function RDSEED64(const ARetryCount: UInt32 = 10): UInt64;
var
  LValue1: UInt32;
  LValue2: UInt32;
begin
  LValue1 := RDSEED32(ARetryCount);
  LValue2 := RDSEED32(ARetryCount);

  Result := UInt64(LValue1) shl 32 or LValue2;
end;

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


end.
