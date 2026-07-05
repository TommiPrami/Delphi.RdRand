unit DRRForm.Main;

interface

uses
  Winapi.Messages, Winapi.Windows, System.Classes, System.Diagnostics, System.SysUtils, System.Variants, Vcl.ComCtrls,
  Vcl.Controls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls;

type
  TDRRMainForm = class(TForm)
    ButtonClearLog: TButton;
    ButtonFillRandom: TButton;
    ButtonGenerateBitmaps: TButton;
    ButtonGenerateColorBitmaps: TButton;
    ButtonRDRAND32: TButton;
    ButtonRDRAND64: TButton;
    ButtonRDSEED32: TButton;
    ButtonRDSEED64: TButton;
    ButtonStressTest: TButton;
    ButtonTryRDRAND32: TButton;
    ButtonTryRDRAND64: TButton;
    ButtonTryRDSEED32: TButton;
    ButtonTryRDSEED64: TButton;
    ImageRDRAND: TImage;
    ImageRTLRandom: TImage;
    LabelBitmapRDRAND: TLabel;
    LabelBitmapRTL: TLabel;
    LabelRDRAND: TLabel;
    LabelRDSEED: TLabel;
    MemoLog: TMemo;
    PageControlMain: TPageControl;
    PanelTop: TPanel;
    TabSheetAPIDemo: TTabSheet;
    TabSheetRandomness: TTabSheet;
    procedure ButtonClearLogClick(Sender: TObject);
    procedure ButtonFillRandomClick(Sender: TObject);
    procedure ButtonGenerateBitmapsClick(Sender: TObject);
    procedure ButtonGenerateColorBitmapsClick(Sender: TObject);
    procedure ButtonRDRAND32Click(Sender: TObject);
    procedure ButtonRDRAND64Click(Sender: TObject);
    procedure ButtonRDSEED32Click(Sender: TObject);
    procedure ButtonRDSEED64Click(Sender: TObject);
    procedure ButtonStressTestClick(Sender: TObject);
    procedure ButtonTryRDRAND32Click(Sender: TObject);
    procedure ButtonTryRDRAND64Click(Sender: TObject);
    procedure ButtonTryRDSEED32Click(Sender: TObject);
    procedure ButtonTryRDSEED64Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function GenerateRDRANDColorNoise(const AImage: TImage): Boolean;
    function GenerateRDRANDNoise(const AImage: TImage): Boolean;
    procedure GenerateRTLColorNoise(const AImage: TImage);
    procedure GenerateRTLNoise(const AImage: TImage);
    procedure Log(const ALine: string);
    procedure StopAndShowElapsed(var AStopwatch: TStopwatch; const ALabel: TLabel; const AName: string);
  end;

var
  DRRMainForm: TDRRMainForm;

implementation

{$R *.dfm}

uses
  Delphi.RdRnd;

const
  NOISE_BITMAP_SIZE = 256;
  PIXEL_WHITE = $FFFFFFFF;
  PIXEL_BLACK = $FF000000;
  ALPHA_OPAQUE = $FF000000;

procedure TDRRMainForm.FormCreate(Sender: TObject);
const
  AVAILABILITY_TEXT: array [Boolean] of string = ('not available', 'available');
begin
  Randomize;

  // RDInstructionsAvailable is filled in the unit initialization via CPUID.
  // Always check it before calling the functions - on a CPU without the
  // instructions they raise an invalid opcode exception.
  LabelRDRAND.Caption := 'RDRAND: ' + AVAILABILITY_TEXT[RDInstructionsAvailable.RDRAND];
  LabelRDSEED.Caption := 'RDSEED: ' + AVAILABILITY_TEXT[RDInstructionsAvailable.RDSEED];

  ButtonRDRAND64.Enabled := RDInstructionsAvailable.RDRAND;
  ButtonRDRAND32.Enabled := RDInstructionsAvailable.RDRAND;
  ButtonTryRDRAND64.Enabled := RDInstructionsAvailable.RDRAND;
  ButtonTryRDRAND32.Enabled := RDInstructionsAvailable.RDRAND;
  ButtonRDSEED64.Enabled := RDInstructionsAvailable.RDSEED;
  ButtonRDSEED32.Enabled := RDInstructionsAvailable.RDSEED;
  ButtonTryRDSEED64.Enabled := RDInstructionsAvailable.RDSEED;
  ButtonTryRDSEED32.Enabled := RDInstructionsAvailable.RDSEED;
  ButtonStressTest.Enabled := RDInstructionsAvailable.RDSEED;
  ButtonFillRandom.Enabled := RDInstructionsAvailable.RDRAND;
end;

procedure TDRRMainForm.Log(const ALine: string);
begin
  MemoLog.Lines.Add(ALine);
end;

procedure TDRRMainForm.StopAndShowElapsed(var AStopwatch: TStopwatch; const ALabel: TLabel; const AName: string);
begin
  AStopwatch.Stop;

  ALabel.Caption := Format('%s - %s ms', [AName, FormatFloat('0.000', AStopwatch.Elapsed.TotalMilliseconds)]);
end;

procedure TDRRMainForm.ButtonRDRAND64Click(Sender: TObject);
begin
  // Plain API: returns the value directly, but a failure returns 0 which can
  // not be told apart from a valid random zero
  Log('RDRAND64 = ' + UIntToStr(RDRAND64));
end;

procedure TDRRMainForm.ButtonRDSEED64Click(Sender: TObject);
begin
  Log('RDSEED64 = ' + UIntToStr(RDSEED64));
end;

procedure TDRRMainForm.ButtonRDRAND32Click(Sender: TObject);
begin
  // The 32 bit functions are available on the 64 bit build too - on x64 they
  // use the native 32 bit form of the instruction
  Log('RDRAND32 = ' + UIntToStr(RDRAND32));
end;

procedure TDRRMainForm.ButtonRDSEED32Click(Sender: TObject);
begin
  Log('RDSEED32 = ' + UIntToStr(RDSEED32));
end;

procedure TDRRMainForm.ButtonTryRDRAND32Click(Sender: TObject);
var
  LValue: UInt32;
begin
  if TryRDRAND32(LValue) then
    Log('TryRDRAND32 = ' + UIntToStr(LValue))
  else
    Log('TryRDRAND32 failed - the CPU could not deliver a random value');
end;

procedure TDRRMainForm.ButtonTryRDSEED32Click(Sender: TObject);
var
  LValue: UInt32;
begin
  if TryRDSEED32(LValue) then
    Log('TryRDSEED32 = ' + UIntToStr(LValue))
  else
    Log('TryRDSEED32 failed - the entropy pool was empty, try again');
end;

procedure TDRRMainForm.ButtonTryRDRAND64Click(Sender: TObject);
var
  LValue: UInt64;
begin
  // Try API: False means the CPU could not deliver a value within the retries
  if TryRDRAND64(LValue) then
    Log('TryRDRAND64 = ' + UIntToStr(LValue))
  else
    Log('TryRDRAND64 failed - the CPU could not deliver a random value');
end;

procedure TDRRMainForm.ButtonFillRandomClick(Sender: TObject);
var
  LBuffer: array [0..31] of Byte;
  LHex: string;
  LIndex: Integer;
begin
  // TryFillRandom fills any buffer with random bytes - TStream style untyped
  // parameter, so arrays, records and raw memory all work
  if TryFillRandom(LBuffer, SizeOf(LBuffer)) then
  begin
    LHex := '';

    for LIndex := Low(LBuffer) to High(LBuffer) do
      LHex := LHex + IntToHex(LBuffer[LIndex], 2);

    Log('TryFillRandom 32 bytes = ' + LHex);
  end
  else
    Log('TryFillRandom failed - the CPU could not deliver enough random values');
end;

procedure TDRRMainForm.ButtonTryRDSEED64Click(Sender: TObject);
var
  LValue: UInt64;
begin
  if TryRDSEED64(LValue) then
    Log('TryRDSEED64 = ' + UIntToStr(LValue))
  else
    Log('TryRDSEED64 failed - the entropy pool was empty, try again');
end;

procedure TDRRMainForm.ButtonStressTestClick(Sender: TObject);
const
  CALL_COUNT = 2000000;
var
  LIndex: Integer;
  LFailCount: Integer;
  LValue: UInt64;
  LStopwatch: TStopwatch;
begin
  // RDSEED reads the hardware entropy source directly and legitimately runs
  // dry when hammered. Calling it with zero retries makes that visible - and
  // is the reason the Try* functions exist: every failure counted below would
  // have been a silent zero with the plain API.
  Screen.Cursor := crHourGlass;
  try
    LFailCount := 0;
    LStopwatch := TStopwatch.StartNew;

    for LIndex := 1 to CALL_COUNT do
      if not TryRDSEED64(LValue, 0) then
        Inc(LFailCount);

    LStopwatch.Stop;

    Log(Format('TryRDSEED64 with zero retries: %d failures / %d calls (%.1f%%) in %d ms',
      [LFailCount, CALL_COUNT, LFailCount * 100 / CALL_COUNT, LStopwatch.ElapsedMilliseconds]));
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TDRRMainForm.ButtonClearLogClick(Sender: TObject);
begin
  MemoLog.Lines.Clear;
end;

procedure TDRRMainForm.GenerateRTLNoise(const AImage: TImage);
var
  LBitmap: TBitmap;
  LX: Integer;
  LY: Integer;
  LPixel: PCardinal;
begin
  LBitmap := TBitmap.Create;
  try
    LBitmap.PixelFormat := pf32bit;
    LBitmap.SetSize(NOISE_BITMAP_SIZE, NOISE_BITMAP_SIZE);

    for LY := 0 to LBitmap.Height - 1 do
    begin
      LPixel := LBitmap.ScanLine[LY];

      for LX := 0 to LBitmap.Width - 1 do
      begin
        if Random(2) = 1 then
          LPixel^ := PIXEL_WHITE
        else
          LPixel^ := PIXEL_BLACK;

        Inc(LPixel);
      end;
    end;

    AImage.Picture.Bitmap.Assign(LBitmap);
  finally
    LBitmap.Free;
  end;
end;

function TDRRMainForm.GenerateRDRANDNoise(const AImage: TImage): Boolean;
var
  LBitmap: TBitmap;
  LX: Integer;
  LY: Integer;
  LPixel: PCardinal;
  LBits: UInt64;
  LBitsLeft: Integer;
begin
  LBitmap := TBitmap.Create;
  try
    LBitmap.PixelFormat := pf32bit;
    LBitmap.SetSize(NOISE_BITMAP_SIZE, NOISE_BITMAP_SIZE);

    LBitsLeft := 0;

    for LY := 0 to LBitmap.Height - 1 do
    begin
      LPixel := LBitmap.ScanLine[LY];

      for LX := 0 to LBitmap.Width - 1 do
      begin
        // One RDRAND64 call delivers 64 pixels worth of random bits
        if LBitsLeft = 0 then
        begin
          if not TryRDRAND64(LBits) then
            Exit(False);

          LBitsLeft := 64;
        end;

        if (LBits and 1) = 1 then
          LPixel^ := PIXEL_WHITE
        else
          LPixel^ := PIXEL_BLACK;

        LBits := LBits shr 1;
        Dec(LBitsLeft);
        Inc(LPixel);
      end;
    end;

    AImage.Picture.Bitmap.Assign(LBitmap);
    Result := True;
  finally
    LBitmap.Free;
  end;
end;

procedure TDRRMainForm.GenerateRTLColorNoise(const AImage: TImage);
var
  LBitmap: TBitmap;
  LX: Integer;
  LY: Integer;
  LPixel: PCardinal;
begin
  LBitmap := TBitmap.Create;
  try
    LBitmap.PixelFormat := pf32bit;
    LBitmap.SetSize(NOISE_BITMAP_SIZE, NOISE_BITMAP_SIZE);

    for LY := 0 to LBitmap.Height - 1 do
    begin
      LPixel := LBitmap.ScanLine[LY];

      for LX := 0 to LBitmap.Width - 1 do
      begin
        //One random byte per color channel
        LPixel^ := ALPHA_OPAQUE or (Cardinal(Random($100)) shl 16) or (Cardinal(Random($100)) shl 8)
          or Cardinal(Random($100));

        Inc(LPixel);
      end;
    end;

    AImage.Picture.Bitmap.Assign(LBitmap);
  finally
    LBitmap.Free;
  end;
end;

function TDRRMainForm.GenerateRDRANDColorNoise(const AImage: TImage): Boolean;
var
  LBitmap: TBitmap;
  LY: Integer;
begin
  LBitmap := TBitmap.Create;
  try
    LBitmap.PixelFormat := pf32bit;
    LBitmap.SetSize(NOISE_BITMAP_SIZE, NOISE_BITMAP_SIZE);

    // TryFillRandom straight into the bitmap memory through the ScanLine
    // pointer, one row at a time - a pf32bit row is Width * 4 bytes. The
    // alpha bytes get random data too, but TBitmap ignores them by default
    // (AlphaFormat = afIgnored).
    for LY := 0 to LBitmap.Height - 1 do
      if not TryFillRandom(LBitmap.ScanLine[LY], LBitmap.Width * SizeOf(Cardinal)) then
        Exit(False);

    AImage.Picture.Bitmap.Assign(LBitmap);
    Result := True;
  finally
    LBitmap.Free;
  end;
end;

procedure TDRRMainForm.ButtonGenerateColorBitmapsClick(Sender: TObject);
var
  LStopwatch: TStopwatch;
begin
  // Same idea as the black/white noise, but with a random color per pixel.
  // The RDRAND side shows how TryFillRandom can fill any memory block - here
  // the bitmap pixels themselves.
  Screen.Cursor := crHourGlass;
  try
    LStopwatch := TStopwatch.StartNew;
    GenerateRTLColorNoise(ImageRTLRandom);
    StopAndShowElapsed(LStopwatch, LabelBitmapRTL, 'Delphi RTL Random');

    if RDInstructionsAvailable.RDRAND then
    begin
      LStopwatch := TStopwatch.StartNew;

      if GenerateRDRANDColorNoise(ImageRDRAND) then
        StopAndShowElapsed(LStopwatch, LabelBitmapRDRAND, 'RDRAND')
      else
        LabelBitmapRDRAND.Caption := 'RDRAND - could not deliver enough random values';
    end
    else
      LabelBitmapRDRAND.Caption := 'RDRAND - not available on this CPU';
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TDRRMainForm.ButtonGenerateBitmapsClick(Sender: TObject);
var
  LStopwatch: TStopwatch;
begin
  // Black/white noise bitmaps, one random bit per pixel, as in
  // https://www.r-bloggers.com/2011/11/pseudo-random-vs-random-numbers-in-r-2/
  // A good generator shows no visible pattern, so to the eye these two should
  // look the same - the difference is that RDRAND bits come from hardware.
  Screen.Cursor := crHourGlass;
  try
    LStopwatch := TStopwatch.StartNew;
    GenerateRTLNoise(ImageRTLRandom);
    StopAndShowElapsed(LStopwatch, LabelBitmapRTL, 'Delphi RTL Random');

    if RDInstructionsAvailable.RDRAND then
    begin
      LStopwatch := TStopwatch.StartNew;

      if GenerateRDRANDNoise(ImageRDRAND) then
        StopAndShowElapsed(LStopwatch, LabelBitmapRDRAND, 'RDRAND')
      else
        LabelBitmapRDRAND.Caption := 'RDRAND - could not deliver enough random values';
    end
    else
      LabelBitmapRDRAND.Caption := 'RDRAND - not available on this CPU';
  finally
    Screen.Cursor := crDefault;
  end;
end;

end.
