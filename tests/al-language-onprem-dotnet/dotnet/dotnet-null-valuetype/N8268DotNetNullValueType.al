// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160); test codeunit 61421 (writer N8268, AL Runner issue 8268)
// Probe: a DotNet variable that was never assigned (null) passed into a .NET value-type parameter.
//        Constructors: DateTimeOffset(DateTime, TimeSpan) and Regex(String, RegexOptions, TimeSpan) with a null TimeSpan and/or
//        a null RegexOptions, and the control with every argument assigned. A constructor whose overload set has a
//        reference-type alternative at the null position: StringBuilder(Int32, Int32) next to StringBuilder(String, Int32),
//        told apart by MaxCapacity.
//        Static calls: Convert.ToString(Byte, Int32), Convert.ToString(Int32, Int32), Convert.ToInt32(Boolean),
//        DateTime.Compare(DateTime, DateTime) with the null argument.
//        Instance methods (not constructors): DateTime.Add(TimeSpan), TimeSpan.Add(TimeSpan), StringBuilder.Remove(Int32, Int32).
//        Calls whose outcome was not known beforehand run inside a [TryFunction] helper; the test records whether it
//        failed, then the value or GetLastErrorText / GetLastErrorCode.
// Values: every literal asserted is what BC produced on the corpus CI legs.
// BC versions: 27, 28, 29

dotnet
{
    assembly(mscorlib)
    {
        type(System.DateTimeOffset; LtN82DateTimeOffset) { }
        type(System.DateTime; LtN82DateTime) { }
        type(System.TimeSpan; LtN82TimeSpan) { }
        type(System.Convert; LtN82Convert) { }
        type(System.Byte; LtN82Byte) { }
        type(System.Int32; LtN82Int32) { }
        type(System.Boolean; LtN82Boolean) { }
        type(System.Text.StringBuilder; LtN82StringBuilder) { }
    }
    assembly(System)
    {
        type(System.Text.RegularExpressions.Regex; LtN82Regex) { }
        type(System.Text.RegularExpressions.RegexOptions; LtN82RegexOptions) { }
    }
}

codeunit 61421 "LT N8268 Null Into ValueType"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        ResultText: Text;

    // Cell 1: constructor, null TimeSpan.
    [Test]
    procedure Ctor_DateTimeOffset_NullTimeSpan()
    var
        D: DotNet LtN82DateTime;
        TS: DotNet LtN82TimeSpan;
        DTO: DotNet LtN82DateTimeOffset;
    begin
        D := D.UtcNow();
        asserterror DTO := DTO.DateTimeOffset(D, TS);
        Observer.ObserveError('dto_null_ts');
        Observer.Finish();
    end;

    // Control of cell 1: every argument assigned.
    [Test]
    procedure Ctor_DateTimeOffset_AssignedTimeSpan()
    var
        D: DotNet LtN82DateTime;
        TS: DotNet LtN82TimeSpan;
        DTO: DotNet LtN82DateTimeOffset;
    begin
        D := D.UtcNow();
        TS := TS.TimeSpan(0, 0, 0);
        DTO := DTO.DateTimeOffset(D, TS);
        Observer.Observe('dto_offset_ticks', Format(DTO.Offset.Ticks));
        Observer.Observe('dto_equals_d', Format(DTO.UtcDateTime.Equals(D)));
        Observer.Finish();
    end;

    // Cell 2: constructor, RegexOptions assigned, null TimeSpan.
    [Test]
    procedure Ctor_Regex_NullTimeSpan()
    var
        R: DotNet LtN82Regex;
        Opt: DotNet LtN82RegexOptions;
        TS: DotNet LtN82TimeSpan;
    begin
        Opt := Opt.None;
        asserterror R := R.Regex('a+', Opt, TS);
        Observer.ObserveError('regex_null_ts');
        Observer.Finish();
    end;

    // Neighbor of cell 2: null RegexOptions (an enum), TimeSpan assigned.
    [Test]
    procedure Ctor_Regex_NullOptions()
    var
        R: DotNet LtN82Regex;
        Opt: DotNet LtN82RegexOptions;
        TS: DotNet LtN82TimeSpan;
    begin
        TS := TS.TimeSpan(0, 0, 5);
        Observer.Observe('regex_null_opt_failed', Format(not TryRegex(R, Opt, TS)));
        Observer.Observe('regex_null_opt_result', ResultText);
        Observer.ObserveError('regex_null_opt');
        Observer.Finish();
    end;

    // Neighbor of cell 2: both RegexOptions and TimeSpan null (the mutation shape "new Regex (String, null, TimeSpan)").
    [Test]
    procedure Ctor_Regex_NullOptionsAndTimeSpan()
    var
        R: DotNet LtN82Regex;
        Opt: DotNet LtN82RegexOptions;
        TS: DotNet LtN82TimeSpan;
    begin
        Observer.Observe('regex_null_both_failed', Format(not TryRegex(R, Opt, TS)));
        Observer.Observe('regex_null_both_result', ResultText);
        Observer.ObserveError('regex_null_both');
        Observer.Finish();
    end;

    // Control of cell 2: every argument assigned.
    [Test]
    procedure Ctor_Regex_Assigned()
    var
        R: DotNet LtN82Regex;
        Opt: DotNet LtN82RegexOptions;
        TS: DotNet LtN82TimeSpan;
    begin
        Opt := Opt.None;
        TS := TS.TimeSpan(0, 0, 5);
        R := R.Regex('a+', Opt, TS);
        Observer.Observe('regex_assigned_match', Format(R.IsMatch('baab')));
        Observer.Finish();
    end;

    // Cell 3: static call, null Byte.
    [Test]
    procedure Static_ConvertToString_NullByte()
    var
        B: DotNet LtN82Byte;
        Cv: DotNet LtN82Convert;
        Tx: Text;
    begin
        Tx := Cv.ToString(B, 2);
        Observer.Observe('tostring_null_byte', Tx);
        Observer.Finish();
    end;

    // Control of cell 3: Byte assigned.
    [Test]
    procedure Static_ConvertToString_AssignedByte()
    var
        B: DotNet LtN82Byte;
        Cv: DotNet LtN82Convert;
    begin
        B := Cv.ToByte(5);
        Observer.Observe('tostring_byte_5', Cv.ToString(B, 2));
        Observer.Finish();
    end;

    // Static call, null Int32.
    [Test]
    procedure Static_ConvertToString_NullInt32()
    var
        I: DotNet LtN82Int32;
        Cv: DotNet LtN82Convert;
    begin
        Observer.Observe('tostring_null_int32_failed', Format(not TryToStringInt32(I)));
        Observer.Observe('tostring_null_int32_result', ResultText);
        Observer.ObserveError('tostring_null_int32');
        Observer.Finish();
    end;

    // Static call, null Boolean.
    [Test]
    procedure Static_ConvertToInt32_NullBoolean()
    var
        Bo: DotNet LtN82Boolean;
    begin
        Observer.Observe('toint32_null_bool_failed', Format(not TryToInt32Bool(Bo)));
        Observer.Observe('toint32_null_bool_result', ResultText);
        Observer.ObserveError('toint32_null_bool');
        Observer.Finish();
    end;

    // Static call, null DateTime (compared with DateTime.MinValue).
    [Test]
    procedure Static_DateTimeCompare_NullDateTime()
    var
        DN: DotNet LtN82DateTime;
    begin
        Observer.Observe('compare_null_dt_failed', Format(not TryCompareDateTime(DN)));
        Observer.Observe('compare_null_dt_result', ResultText);
        Observer.ObserveError('compare_null_dt');
        Observer.Finish();
    end;

    // Instance method, null TimeSpan argument on a DateTime.
    [Test]
    procedure Instance_DateTimeAdd_NullTimeSpan()
    var
        TS: DotNet LtN82TimeSpan;
    begin
        Observer.Observe('dt_add_null_ts_failed', Format(not TryDateTimeAdd(TS)));
        Observer.Observe('dt_add_null_ts_result', ResultText);
        Observer.ObserveError('dt_add_null_ts');
        Observer.Finish();
    end;

    // Instance method, null TimeSpan argument on a TimeSpan.
    [Test]
    procedure Instance_TimeSpanAdd_NullTimeSpan()
    var
        TS: DotNet LtN82TimeSpan;
    begin
        Observer.Observe('ts_add_null_ts_failed', Format(not TryTimeSpanAdd(TS)));
        Observer.Observe('ts_add_null_ts_result', ResultText);
        Observer.ObserveError('ts_add_null_ts');
        Observer.Finish();
    end;

    // Instance method, null Int32 argument on a StringBuilder (Remove(Int32 startIndex, Int32 length)).
    [Test]
    procedure Instance_StringBuilderRemove_NullInt32()
    var
        I: DotNet LtN82Int32;
    begin
        Observer.Observe('sb_remove_null_int32_failed', Format(not TrySbRemove(I)));
        Observer.Observe('sb_remove_null_int32_result', ResultText);
        Observer.ObserveError('sb_remove_null_int32');
        Observer.Finish();
    end;

    // Constructor with a reference-type alternative at the null position:
    // StringBuilder(Int32 capacity, Int32 maxCapacity) and StringBuilder(String value, Int32 capacity).
    // MaxCapacity tells which overload bound: 5 for (Int32, Int32), 2147483647 for (String, Int32).
    [Test]
    procedure Ctor_StringBuilder_NullInt32_RefAlternative()
    var
        I: DotNet LtN82Int32;
    begin
        Observer.Observe('sb_ctor_null_int32_failed', Format(not TrySbCtor(I)));
        Observer.Observe('sb_ctor_null_int32_result', ResultText);
        Observer.ObserveError('sb_ctor_null_int32');
        Observer.Finish();
    end;

    // Control of the overload cell: Int32 assigned (0).
    [Test]
    procedure Ctor_StringBuilder_AssignedInt32()
    var
        I: DotNet LtN82Int32;
        Cv: DotNet LtN82Convert;
        SB: DotNet LtN82StringBuilder;
    begin
        I := Cv.ToInt32(0);
        SB := SB.StringBuilder(I, 5);
        Observer.Observe('sb_ctor_int32_0_max', Format(SB.MaxCapacity));
        Observer.Observe('sb_ctor_int32_0_text', SB.ToString());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryRegex(var R: DotNet LtN82Regex; Opt: DotNet LtN82RegexOptions; TS: DotNet LtN82TimeSpan)
    begin
        ResultText := '';
        R := R.Regex('a+', Opt, TS);
        ResultText := Format(R.IsMatch('baab'));
    end;

    [TryFunction]
    local procedure TryToStringInt32(I: DotNet LtN82Int32)
    var
        Cv: DotNet LtN82Convert;
    begin
        ResultText := '';
        ResultText := Cv.ToString(I, 2);
    end;

    [TryFunction]
    local procedure TryToInt32Bool(Bo: DotNet LtN82Boolean)
    var
        Cv: DotNet LtN82Convert;
    begin
        ResultText := '';
        ResultText := Format(Cv.ToInt32(Bo));
    end;

    [TryFunction]
    local procedure TryCompareDateTime(DN: DotNet LtN82DateTime)
    var
        DMin: DotNet LtN82DateTime;
    begin
        ResultText := '';
        DMin := DMin.DateTime(1, 1, 1); // equals DateTime.MinValue (a field, not reachable from AL)
        ResultText := Format(DMin.Compare(DN, DMin));
    end;

    [TryFunction]
    local procedure TryDateTimeAdd(TS: DotNet LtN82TimeSpan)
    var
        D: DotNet LtN82DateTime;
        D2: DotNet LtN82DateTime;
    begin
        ResultText := '';
        D := D.UtcNow();
        D2 := D.Add(TS);
        ResultText := Format(D2.Equals(D));
    end;

    [TryFunction]
    local procedure TryTimeSpanAdd(TS: DotNet LtN82TimeSpan)
    var
        T1: DotNet LtN82TimeSpan;
        T2: DotNet LtN82TimeSpan;
    begin
        ResultText := '';
        T1 := T1.TimeSpan(1, 0, 0);
        T2 := T1.Add(TS);
        ResultText := Format(T2.Ticks);
    end;

    [TryFunction]
    local procedure TrySbRemove(I: DotNet LtN82Int32)
    var
        SB: DotNet LtN82StringBuilder;
    begin
        ResultText := '';
        SB := SB.StringBuilder('abcdef');
        SB.Remove(I, 2);
        ResultText := SB.ToString();
    end;

    [TryFunction]
    local procedure TrySbCtor(I: DotNet LtN82Int32)
    var
        SB: DotNet LtN82StringBuilder;
    begin
        ResultText := '';
        SB := SB.StringBuilder(I, 5);
        ResultText := Format(SB.MaxCapacity) + '|' + SB.ToString();
    end;
}
