unit Delphi.Random.Analysis;

{
  Statistical tests for judging the quality of a random number source.

  The tests take a sample source callback (TRandomSampleFunc) and return their
  results in records - they know nothing about where the numbers come from or
  how the results are presented, so any generator can be analysed the same way.

  Included tests:
    - FrequencyTest        monobit + byte chi-square (casual tests, most
                           generators pass, including simple PRNGs)
    - BirthdaySpacingsTest Marsaglia's birthday spacings test from the Diehard
                           suite - exposes the lattice structure of LCGs
    - PredictionTest       models the source as a 32 bit LCG and tries to
                           recover the state, i.e. tests predictability

  Sample width: FrequencyTest and BirthdaySpacingsTest consume full 32 bit
  samples. PredictionTest consumes 16 bit observations (the low 16 bits of each
  returned value are used), one per generator step.
}

interface

type
  // A source of random values to analyse. Returns the next sample.
  TRandomSampleFunc = reference to function: UInt32;

  TFrequencyResult = record
    OnesPercent: Double;      // monobit: percentage of 1 bits, expect ~50
    MonobitPassed: Boolean;
    ByteChiSquare: Double;    // chi-square over byte values, expect ~255
    ChiSquarePassed: Boolean;
  end;

  TBirthdaySpacingsResult = record
    Duplicates: Integer;      // total duplicated spacings over all trials
    Expected: Integer;        // expected duplicates for a good generator
    Sigma: Double;            // deviation from Expected, in standard deviations
    Passed: Boolean;
  end;

  TPredictionResult = record
    StateRecovered: Boolean;  // an LCG state consistent with the observations was found
    CandidateCount: Integer;  // number of matching states (1 = uniquely determined)
    PredictedHits: Integer;   // correctly predicted future values
    PredictedCount: Integer;  // future values attempted
    Passed: Boolean;          // True when the source is NOT predictable as an LCG
  end;

const
  //Delphi RTL Random uses this multiplier: RandSeed := RandSeed * $8088405 + 1 (mod 2^32)
  LCG_MULTIPLIER = $8088405;

  //32 bit sample space, used as "number of days" in the birthday spacings test
  SAMPLE_SPACE = 4294967296.0;

  DEFAULT_FREQUENCY_BYTES = 1024 * 1024;
  DEFAULT_BIRTHDAY_TRIALS = 1000;
  DEFAULT_BIRTHDAY_SAMPLES = 4096;    // m; with n = 2^32 gives lambda = m^3 / (4n) = 4
  DEFAULT_PREDICTION_OBSERVATIONS = 3; // 3 outputs pin the 32 bit LCG state uniquely
  DEFAULT_PREDICTION_PREDICTED = 10;

  //Pass/fail thresholds
  MONOBIT_TOLERANCE = 0.1;      // max percent away from 50
  CHI_SQUARE_CRITICAL = 311.0;  // ~ p = 0.01 for 255 degrees of freedom
  BIRTHDAY_SIGMA_LIMIT = 4.0;

function NextLCGState(const AState: UInt32): UInt32;

function FrequencyTest(const ANextSample: TRandomSampleFunc;
  const AByteCount: Integer = DEFAULT_FREQUENCY_BYTES): TFrequencyResult;

function BirthdaySpacingsTest(const ANextSample: TRandomSampleFunc;
  const ATrials: Integer = DEFAULT_BIRTHDAY_TRIALS;
  const ASampleCount: Integer = DEFAULT_BIRTHDAY_SAMPLES): TBirthdaySpacingsResult;

function PredictionTest(const ANextObservation: TRandomSampleFunc;
  const AObservationCount: Integer = DEFAULT_PREDICTION_OBSERVATIONS;
  const APredictCount: Integer = DEFAULT_PREDICTION_PREDICTED): TPredictionResult;

implementation

uses
  System.Math, System.Generics.Collections;

{$IFOPT Q+}
  {$DEFINE OVERFLOW_CHECKS_WERE_ON}
  {$Q-}
{$ENDIF}
function NextLCGState(const AState: UInt32): UInt32;
begin
  //One step of the RTL Random generator, wraps around at 2^32 by design
  Result := AState * LCG_MULTIPLIER + 1;
end;
{$IFDEF OVERFLOW_CHECKS_WERE_ON}
  {$Q+}
  {$UNDEF OVERFLOW_CHECKS_WERE_ON}
{$ENDIF}

function FrequencyTest(const ANextSample: TRandomSampleFunc;
  const AByteCount: Integer = DEFAULT_FREQUENCY_BYTES): TFrequencyResult;
var
  LData: TArray<Byte>;
  LIndex: Integer;
  LBit: Integer;
  LOnes: Int64;
  LHistogram: array [Byte] of Integer;
  LExpected: Double;
  LByte: Integer;
  LValue: UInt32;
  LByteCount: Integer;
begin
  //Round down to a whole number of 32 bit samples
  LByteCount := (AByteCount div SizeOf(UInt32)) * SizeOf(UInt32);
  SetLength(LData, LByteCount);

  LIndex := 0;
  while LIndex < LByteCount do
  begin
    LValue := ANextSample;
    LData[LIndex] := Byte(LValue shr 24);
    LData[LIndex + 1] := Byte(LValue shr 16);
    LData[LIndex + 2] := Byte(LValue shr 8);
    LData[LIndex + 3] := Byte(LValue);

    Inc(LIndex, SizeOf(UInt32));
  end;

  LOnes := 0;
  FillChar(LHistogram, SizeOf(LHistogram), 0);

  for LIndex := 0 to LByteCount - 1 do
  begin
    Inc(LHistogram[LData[LIndex]]);

    for LBit := 0 to 7 do
      if (LData[LIndex] shr LBit) and 1 = 1 then
        Inc(LOnes);
  end;

  Result.OnesPercent := LOnes * 100 / (Int64(LByteCount) * 8);
  Result.MonobitPassed := Abs(Result.OnesPercent - 50) < MONOBIT_TOLERANCE;

  LExpected := LByteCount / 256;
  Result.ByteChiSquare := 0;

  for LByte := 0 to 255 do
    Result.ByteChiSquare := Result.ByteChiSquare + Sqr(LHistogram[LByte] - LExpected) / LExpected;

  Result.ChiSquarePassed := Result.ByteChiSquare < CHI_SQUARE_CRITICAL;
end;

function BirthdaySpacingsTest(const ANextSample: TRandomSampleFunc;
  const ATrials: Integer = DEFAULT_BIRTHDAY_TRIALS;
  const ASampleCount: Integer = DEFAULT_BIRTHDAY_SAMPLES): TBirthdaySpacingsResult;
var
  LSamples: TArray<UInt32>;
  LSpacings: TArray<UInt32>;
  LTrial: Integer;
  LIndex: Integer;
  LExpectedPerTrial: Double;
begin
  // Marsaglia's birthday spacings test (Diehard): take m samples as "birthdays"
  // in a year of n = 2^32 days, sort them, take the spacings between neighbors
  // and count how many spacings are duplicated. For a good generator the number
  // of duplicates is Poisson distributed with lambda = m^3 / (4n) per trial.
  // LCGs fail decisively because their outputs lie on a lattice, which makes the
  // spacings far more repetitive than chance.
  Result.Duplicates := 0;
  SetLength(LSamples, ASampleCount);
  SetLength(LSpacings, ASampleCount - 1);

  for LTrial := 1 to ATrials do
  begin
    for LIndex := 0 to ASampleCount - 1 do
      LSamples[LIndex] := ANextSample;

    TArray.Sort<UInt32>(LSamples);

    for LIndex := 0 to ASampleCount - 2 do
      LSpacings[LIndex] := LSamples[LIndex + 1] - LSamples[LIndex];

    TArray.Sort<UInt32>(LSpacings);

    for LIndex := 1 to ASampleCount - 2 do
      if LSpacings[LIndex] = LSpacings[LIndex - 1] then
        Inc(Result.Duplicates);
  end;

  LExpectedPerTrial := (Double(ASampleCount) * ASampleCount * ASampleCount) / (4.0 * SAMPLE_SPACE);
  Result.Expected := Round(ATrials * LExpectedPerTrial);

  //Poisson: the total count has variance equal to its mean
  if Result.Expected > 0 then
    Result.Sigma := (Result.Duplicates - Result.Expected) / Sqrt(Result.Expected)
  else
    Result.Sigma := 0;

  Result.Passed := Abs(Result.Sigma) < BIRTHDAY_SIGMA_LIMIT;
end;

function PredictionTest(const ANextObservation: TRandomSampleFunc;
  const AObservationCount: Integer = DEFAULT_PREDICTION_OBSERVATIONS;
  const APredictCount: Integer = DEFAULT_PREDICTION_PREDICTED): TPredictionResult;
var
  LObserved: TArray<UInt32>;
  LActual: TArray<UInt32>;
  LLow: UInt32;
  LState: UInt32;
  LCandidate: UInt32;
  LIndex: Integer;
  LMatches: Boolean;
begin
  // A 32 bit LCG whose top 16 bits are observed (Random(N) = state * N shr 32,
  // so Random($10000) = state shr 16) can be broken: take the first observation
  // as the high 16 bits of the state, brute force the missing low 16 bits and
  // keep the states whose following steps reproduce the rest of the observations.
  // With 3 observations the state is uniquely determined and every future value
  // follows. A source with no such state (e.g. RDRAND) is unpredictable.
  SetLength(LObserved, AObservationCount);
  SetLength(LActual, APredictCount);

  for LIndex := 0 to AObservationCount - 1 do
    LObserved[LIndex] := ANextObservation and $FFFF;

  for LIndex := 0 to APredictCount - 1 do
    LActual[LIndex] := ANextObservation and $FFFF;

  Result.CandidateCount := 0;
  Result.PredictedCount := APredictCount;
  Result.PredictedHits := 0;
  LCandidate := 0;

  for LLow := 0 to $FFFF do
  begin
    LState := (LObserved[0] shl 16) or LLow;
    LMatches := True;

    for LIndex := 1 to AObservationCount - 1 do
    begin
      LState := NextLCGState(LState);

      if (LState shr 16) <> LObserved[LIndex] then
      begin
        LMatches := False;
        Break;
      end;
    end;

    if LMatches then
    begin
      Inc(Result.CandidateCount);
      LCandidate := LState;   // state after the last observation
    end;
  end;

  Result.StateRecovered := Result.CandidateCount > 0;

  if Result.StateRecovered then
  begin
    LState := LCandidate;

    for LIndex := 0 to APredictCount - 1 do
    begin
      LState := NextLCGState(LState);

      if (LState shr 16) = LActual[LIndex] then
        Inc(Result.PredictedHits);
    end;
  end;

  //A generator that can be modelled and predicted as an LCG has failed
  Result.Passed := not Result.StateRecovered;
end;

end.
