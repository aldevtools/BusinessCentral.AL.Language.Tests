// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; own dotnet aliases LtDk*; self-contained codeunit 99362
// Probe: the DateTimeKind of a DotNet System.DateTime and the members that read it (aldevtools/BusinessCentral.AL.Runner#9052, #9092).
// Neighbor of timezone-info/DotNetTimeZoneDst.al (an AL DateTime in a DotNet DateTime has kind Utc).
//   - origins (one test each, every one at the moment 2023-01-15T12:00:00Z unless named): an AL DateTime parameter, an AL local
//     variable, CreateDateTime, the constructor DateTime(y, m, d, h, n, s) with no kind / kind Utc / kind Local, DateTime.Parse of a
//     text with Z, without a suffix, with +02:00 and of Format(Dt, 0, 9), DateTime(1970, 1, 1, 0, 0, 0, Utc).Add(TimeSpan), a .NET
//     value of each kind assigned to an AL DateTime and back to DotNet, a DotNet-to-DotNet copy, a .NET value stored in a Variant and
//     read back into DotNet, and the sum "DotNet DateTime + Duration" assigned back to DotNet (0 and 2 hours).
//   - per origin: the value itself, ToUniversalTime(), ToLocalTime() (each as ToString('o'), Kind and the AL DateTime read back with
//     Format(.., 0, 9)), ToBinary(), ToFileTime(), ToString() and Evaluate of that text into an AL DateTime, ToString with K and zzz,
//     and ToUniversalTime().ToString('R').
//   - DateTime.Now and DateTime.UtcNow: kinds, conversions and their distance (within 5 seconds, or whole hours) to each other and to
//     CurrentDateTime; and the shape "Dn := Dn.Now; Dn := Dn.ToUniversalTime() + Offset; Evaluate(Result, Dn.ToString())".
// Every call on a fixed moment runs in a TryFunction and is observed as ok:<result> or error:<text>|<code>.
// Measured locally on BC on Linux 27.5, 28.5 and 29.0 (the CI leg setup):
//   - the service tier's local time zone is UTC: TimeZoneInfo.Local has base offset 0 and no DST, Now and UtcNow are within
//     5 seconds, and the default Format of an AL DateTime shows the UTC clock time. So Local and Utc moments are equal here; the
//     kind still shows in Kind, ToString('o') (Z, +00:00 or no suffix), the K format and ToBinary.
//   - kind Utc: every AL DateTime origin, the constructor with Utc, the epoch Add, ToUniversalTime() of any kind, and every value that
//     went through AL: a .NET value of any kind assigned to an AL DateTime and back, a DotNet DateTime in a Variant read back into
//     DotNet, and "DotNet DateTime + Duration" (the sum is an AL DateTime). The kind is not kept through AL.
//   - kind Local: DateTime.Now, the constructor with Local, Parse of a text with Z or with an offset (converted to the local clock),
//     ToLocalTime() of any kind, and a DotNet-to-DotNet copy of a Local value.
//   - kind Unspecified: the constructor without kind and Parse without a suffix; ToUniversalTime() and ToLocalTime() of it keep the
//     clock time (host zone UTC).
//   - reading any of them back into an AL DateTime gives the same clock time with Z; ToString() is the en-US text
//     "1/15/2023 12:00:00 PM", which Evaluate reads back as the same moment; ToUniversalTime().ToString('R') is "Sun, 15 Jan 2023
//     12:00:00 GMT". The Now shape gives a result within 5 seconds of CurrentDateTime with Offset 0, and 2 hours later with Offset 2h.
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.DateTime"; LtDkDateTime) { }
        type("System.DateTimeKind"; LtDkKind) { }
        type("System.TimeSpan"; LtDkSpan) { }
        type("System.TimeZoneInfo"; LtDkZone) { }
    }
}

codeunit 99362 "LT DotNet DtKind"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Utc(Moment: Text): DateTime
    var
        Dt: DateTime;
    begin
        Evaluate(Dt, Moment, 9);
        exit(Dt);
    end;

    local procedure Describe(Dn: DotNet LtDkDateTime): Text
    var
        Al: DateTime;
    begin
        Al := Dn;
        exit(Dn.ToString('o') + ' kind=' + Dn.Kind.ToString() + ' al=' + Format(Al, 0, 9));
    end;

    // The DotNet DateTime of an origin. Dt is a by-value DateTime parameter (the origin 'al-param').
    local procedure Make(Origin: Text; Dt: DateTime; var Dn: DotNet LtDkDateTime)
    var
        Kind: DotNet LtDkKind;
        Span: DotNet LtDkSpan;
        Other: DotNet LtDkDateTime;
        Al: DateTime;
        V: Variant;
        Off: Duration;
        EpochTicks: BigInteger;
    begin
        case Origin of
            'al-param':
                Dn := Dt;
            'al-local':
                begin
                    Al := Utc('2023-01-15T12:00:00Z');
                    Dn := Al;
                end;
            'createdatetime':
                Dn := CreateDateTime(DMY2Date(15, 1, 2023), 120000T);
            'ctor-unspecified':
                Dn := Dn.DateTime(2023, 1, 15, 12, 0, 0);
            'ctor-utc':
                begin
                    Kind := Kind.Utc;
                    Dn := Dn.DateTime(2023, 1, 15, 12, 0, 0, Kind);
                end;
            'ctor-local':
                begin
                    Kind := Kind.Local;
                    Dn := Dn.DateTime(2023, 1, 15, 12, 0, 0, Kind);
                end;
            'parse-z':
                Dn := Dn.Parse('2023-01-15T12:00:00Z');
            'parse-nosuffix':
                Dn := Dn.Parse('2023-01-15T12:00:00');
            'parse-offset':
                Dn := Dn.Parse('2023-01-15T12:00:00+02:00');
            'parse-alformat9':
                Dn := Dn.Parse(Format(Dt, 0, 9));
            'epoch-add':
                begin
                    Kind := Kind.Utc;
                    Dn := Dn.DateTime(1970, 1, 1, 0, 0, 0, Kind);
                    EpochTicks := 1673784000;
                    EpochTicks := EpochTicks * 10000000;
                    Dn := Dn.Add(Span.FromTicks(EpochTicks));
                end;
            'roundtrip-unspecified', 'roundtrip-utc', 'roundtrip-local':
                begin
                    Make('ctor-' + CopyStr(Origin, 11), Dt, Other);
                    Al := Other;
                    Dn := Al;
                end;
            'dotnet-copy-local':
                begin
                    Make('ctor-local', Dt, Other);
                    Dn := Other;
                end;
            'variant-unspecified', 'variant-local':
                begin
                    Make('ctor-' + CopyStr(Origin, 9), Dt, Other);
                    V := Other;
                    Dn := V;
                end;
            'alsum0-param':
                begin
                    Dn := Dt;
                    Dn := Dn.ToUniversalTime() + Off;
                end;
            'alsum2h-param':
                begin
                    Off := 2 * 60 * 60 * 1000;
                    Dn := Dt;
                    Dn := Dn.ToUniversalTime() + Off;
                end;
            'alsum0-unspecified', 'alsum0-local':
                begin
                    Make('ctor-' + CopyStr(Origin, 8), Dt, Other);
                    Dn := Other + Off;
                end;
        end;
    end;

    [TryFunction]
    local procedure DoStep(Origin: Text; Dt: DateTime; Step: Text; var R: Text)
    var
        Dn: DotNet LtDkDateTime;
        X: DotNet LtDkDateTime;
        Al: DateTime;
        S: Text;
    begin
        Make(Origin, Dt, Dn);
        case Step of
            'self':
                R := Describe(Dn);
            'touniversal':
                begin
                    X := Dn.ToUniversalTime();
                    R := Describe(X);
                end;
            'tolocal':
                begin
                    X := Dn.ToLocalTime();
                    R := Describe(X);
                end;
            'tobinary':
                R := Format(Dn.ToBinary());
            'tofiletime':
                R := Format(Dn.ToFileTime());
            'tostring':
                begin
                    S := Dn.ToString();
                    if Evaluate(Al, S) then
                        R := S + ' eval=' + Format(Al, 0, 9)
                    else
                        R := S + ' eval=failed';
                end;
            'format-K':
                R := Dn.ToString('yyyy-MM-ddTHH:mm:ssK');
            'format-zzz':
                R := Dn.ToString('HH:mm zzz');
            'touniversal-R':
                R := Dn.ToUniversalTime().ToString('R');
        end;
    end;

    local procedure Run(Origin: Text; Step: Text): Text
    var
        R: Text;
    begin
        ClearLastError();
        if DoStep(Origin, Utc('2023-01-15T12:00:00Z'), Step, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ObserveOrigin(Origin: Text; var Obs: Codeunit "Probe Observer")
    begin
        Obs.Observe('self', Run(Origin, 'self'));
        Obs.Observe('touniversal', Run(Origin, 'touniversal'));
        Obs.Observe('tolocal', Run(Origin, 'tolocal'));
        Obs.Observe('tobinary', Run(Origin, 'tobinary'));
        Obs.Observe('tofiletime', Run(Origin, 'tofiletime'));
        Obs.Observe('tostring', Run(Origin, 'tostring'));
        Obs.Observe('format-K', Run(Origin, 'format-K'));
        Obs.Observe('format-zzz', Run(Origin, 'format-zzz'));
        Obs.Observe('touniversal-R', Run(Origin, 'touniversal-R'));
    end;

    // The 'o' text without the moment: Z, the offset (+hh:mm) or none.
    local procedure Suffix(S: Text): Text
    begin
        if S.EndsWith('Z') then
            exit('Z');
        if StrLen(S) > 6 then
            if CopyStr(S, StrLen(S) - 5, 1) in ['+', '-'] then
                exit(CopyStr(S, StrLen(S) - 5));
        exit('none');
    end;

    local procedure KindAndSuffix(Dn: DotNet LtDkDateTime): Text
    begin
        exit(Dn.Kind.ToString() + ' ' + Suffix(Dn.ToString('o')));
    end;

    // A - B in whole hours, and whether A and B lie within 5 seconds of each other.
    local procedure Apart(A: DotNet LtDkDateTime; B: DotNet LtDkDateTime): Text
    var
        Diff: BigInteger;
    begin
        Diff := A.Ticks - B.Ticks;
        if (Diff < 50000000) and (Diff > -50000000) then
            exit('within5s');
        exit('hours=' + Format(Round(Diff / 10000000 / 3600, 1)));
    end;

    local procedure ApartAl(A: DateTime; B: DateTime): Text
    var
        Diff: BigInteger;
    begin
        Diff := A - B;
        if (Diff < 5000) and (Diff > -5000) then
            exit('within5s');
        exit('hours=' + Format(Round(Diff / 3600000, 1)));
    end;

    [Test]
    procedure Host_TimeZone_Facts()
    var
        Obs: Codeunit "Probe Observer";
        Zone: DotNet LtDkZone;
        DnNow: DotNet LtDkDateTime;
        DnUtcNow: DotNet LtDkDateTime;
        Off: Duration;
    begin
        Zone := Zone.Local;
        Off := Zone.BaseUtcOffset;
        Obs.Observe('local_base_offset', Format(Off, 0, 9));
        Obs.Observe('local_supports_dst', Format(Zone.SupportsDaylightSavingTime));
        DnNow := DnNow.Now;
        DnUtcNow := DnUtcNow.UtcNow;
        Obs.Observe('now_minus_utcnow', Apart(DnNow, DnUtcNow));
        Obs.Observe('format_al_2023-01-15T12:00:00Z', Format(Utc('2023-01-15T12:00:00Z')));
        Obs.Observe('format_al_2023-07-15T12:00:00Z', Format(Utc('2023-07-15T12:00:00Z')));
        Obs.Expect('local_base_offset', 'P0DT0H0M0.0S');
        Obs.Expect('local_supports_dst', 'No');
        Obs.Expect('now_minus_utcnow', 'within5s');
        Obs.Expect('format_al_2023-01-15T12:00:00Z', '01/15/23 12:00 PM');
        Obs.Expect('format_al_2023-07-15T12:00:00Z', '07/15/23 12:00 PM');
        Obs.Verify();
    end;

    [Test]
    procedure NowUtcNow_KindAndConversions()
    var
        Obs: Codeunit "Probe Observer";
        DnNow: DotNet LtDkDateTime;
        DnUtcNow: DotNet LtDkDateTime;
        X: DotNet LtDkDateTime;
        Al: DateTime;
    begin
        DnNow := DnNow.Now;
        DnUtcNow := DnUtcNow.UtcNow;
        Obs.Observe('now', KindAndSuffix(DnNow));
        Obs.Observe('utcnow', KindAndSuffix(DnUtcNow));
        X := DnNow.ToUniversalTime();
        Obs.Observe('now_touniversal', KindAndSuffix(X));
        Obs.Observe('now_touniversal_vs_utcnow', Apart(X, DnUtcNow));
        X := DnNow.ToLocalTime();
        Obs.Observe('now_tolocal', KindAndSuffix(X));
        Obs.Observe('now_tolocal_vs_now', Apart(X, DnNow));
        X := DnUtcNow.ToLocalTime();
        Obs.Observe('utcnow_tolocal', KindAndSuffix(X));
        Obs.Observe('utcnow_tolocal_vs_now', Apart(X, DnNow));
        X := DnUtcNow.ToUniversalTime();
        Obs.Observe('utcnow_touniversal', KindAndSuffix(X));
        Al := DnNow;
        Obs.Observe('now_al_vs_currentdatetime', ApartAl(Al, CurrentDateTime()));
        Al := DnUtcNow;
        Obs.Observe('utcnow_al_vs_currentdatetime', ApartAl(Al, CurrentDateTime()));
        X := Al;
        Obs.Observe('utcnow_al_back_to_dotnet', KindAndSuffix(X));
        Al := DnNow;
        X := Al;
        Obs.Observe('now_al_back_to_dotnet', KindAndSuffix(X));
        Obs.Expect('now', 'Local +00:00');
        Obs.Expect('utcnow', 'Utc Z');
        Obs.Expect('now_touniversal', 'Utc Z');
        Obs.Expect('now_touniversal_vs_utcnow', 'within5s');
        Obs.Expect('now_tolocal', 'Local +00:00');
        Obs.Expect('now_tolocal_vs_now', 'within5s');
        Obs.Expect('utcnow_tolocal', 'Local +00:00');
        Obs.Expect('utcnow_tolocal_vs_now', 'within5s');
        Obs.Expect('utcnow_touniversal', 'Utc Z');
        Obs.Expect('now_al_vs_currentdatetime', 'within5s');
        Obs.Expect('utcnow_al_vs_currentdatetime', 'within5s');
        Obs.Expect('utcnow_al_back_to_dotnet', 'Utc Z');
        Obs.Expect('now_al_back_to_dotnet', 'Utc Z');
        Obs.Verify();
    end;

    [Test]
    procedure Now_ToUniversalTimePlusDuration_EvaluateToString()
    var
        Obs: Codeunit "Probe Observer";
        Dn: DotNet LtDkDateTime;
        Off: Duration;
        Result: DateTime;
    begin
        Dn := Dn.Now;
        Dn := Dn.ToUniversalTime() + Off;
        Obs.Observe('off0_kind', KindAndSuffix(Dn));
        Obs.Observe('off0_evaluate', Format(Evaluate(Result, Dn.ToString())));
        Obs.Observe('off0_result_vs_currentdatetime', ApartAl(Result, CurrentDateTime()));
        Off := 2 * 60 * 60 * 1000;
        Dn := Dn.Now;
        Dn := Dn.ToUniversalTime() + Off;
        Obs.Observe('off2h_kind', KindAndSuffix(Dn));
        Obs.Observe('off2h_evaluate', Format(Evaluate(Result, Dn.ToString())));
        Obs.Observe('off2h_result_vs_currentdatetime', ApartAl(Result, CurrentDateTime()));
        Dn := Dn.Now;
        Obs.Observe('now_tostring_evaluate', Format(Evaluate(Result, Dn.ToString())));
        Obs.Observe('now_tostring_result_vs_currentdatetime', ApartAl(Result, CurrentDateTime()));
        Dn := Dn.UtcNow;
        Obs.Observe('utcnow_tostring_evaluate', Format(Evaluate(Result, Dn.ToString())));
        Obs.Observe('utcnow_tostring_result_vs_currentdatetime', ApartAl(Result, CurrentDateTime()));
        Obs.Expect('off0_kind', 'Utc Z');
        Obs.Expect('off0_evaluate', 'Yes');
        Obs.Expect('off0_result_vs_currentdatetime', 'within5s');
        Obs.Expect('off2h_kind', 'Utc Z');
        Obs.Expect('off2h_evaluate', 'Yes');
        Obs.Expect('off2h_result_vs_currentdatetime', 'hours=2');
        Obs.Expect('now_tostring_evaluate', 'Yes');
        Obs.Expect('now_tostring_result_vs_currentdatetime', 'within5s');
        Obs.Expect('utcnow_tostring_evaluate', 'Yes');
        Obs.Expect('utcnow_tostring_result_vs_currentdatetime', 'within5s');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_AlParam()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('al-param', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_AlLocal()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('al-local', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_CreateDateTime()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('createdatetime', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_CtorUnspecified()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('ctor-unspecified', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000 kind=Unspecified al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:638093808000000000');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_CtorUtc()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('ctor-utc', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_CtorLocal()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('ctor-local', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:-8585278228854775808');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00+00:00');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_ParseZ()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('parse-z', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:-8585278228854775808');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00+00:00');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_ParseNoSuffix()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('parse-nosuffix', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000 kind=Unspecified al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:638093808000000000');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_ParseOffset()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('parse-offset', Obs);
        Obs.Expect('self', 'ok:2023-01-15T10:00:00.0000000+00:00 kind=Local al=2023-01-15T10:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T10:00:00.0000000Z kind=Utc al=2023-01-15T10:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T10:00:00.0000000+00:00 kind=Local al=2023-01-15T10:00:00Z');
        Obs.Expect('tobinary', 'ok:-8585278300854775808');
        Obs.Expect('tofiletime', 'ok:133182504000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 10:00:00 AM eval=2023-01-15T10:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T10:00:00+00:00');
        Obs.Expect('format-zzz', 'ok:10:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 10:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_ParseAlFormat9()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('parse-alformat9', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:-8585278228854775808');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00+00:00');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_EpochAdd()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('epoch-add', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_RoundTripUnspecified()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('roundtrip-unspecified', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_RoundTripUtc()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('roundtrip-utc', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_RoundTripLocal()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('roundtrip-local', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_DotNetCopyLocal()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('dotnet-copy-local', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:-8585278228854775808');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00+00:00');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_VariantUnspecified()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('variant-unspecified', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_VariantLocal()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('variant-local', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_AlSumZeroParam()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('alsum0-param', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_AlSumTwoHoursParam()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('alsum2h-param', Obs);
        Obs.Expect('self', 'ok:2023-01-15T14:00:00.0000000Z kind=Utc al=2023-01-15T14:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T14:00:00.0000000Z kind=Utc al=2023-01-15T14:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T14:00:00.0000000+00:00 kind=Local al=2023-01-15T14:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779898427387904');
        Obs.Expect('tofiletime', 'ok:133182648000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 2:00:00 PM eval=2023-01-15T14:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T14:00:00Z');
        Obs.Expect('format-zzz', 'ok:14:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 14:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_AlSumZeroUnspecified()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('alsum0-unspecified', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;

    [Test]
    procedure Origin_AlSumZeroLocal()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveOrigin('alsum0-local', Obs);
        Obs.Expect('self', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('touniversal', 'ok:2023-01-15T12:00:00.0000000Z kind=Utc al=2023-01-15T12:00:00Z');
        Obs.Expect('tolocal', 'ok:2023-01-15T12:00:00.0000000+00:00 kind=Local al=2023-01-15T12:00:00Z');
        Obs.Expect('tobinary', 'ok:5249779826427387904');
        Obs.Expect('tofiletime', 'ok:133182576000000000');
        Obs.Expect('tostring', 'ok:1/15/2023 12:00:00 PM eval=2023-01-15T12:00:00Z');
        Obs.Expect('format-K', 'ok:2023-01-15T12:00:00Z');
        Obs.Expect('format-zzz', 'ok:12:00 +00:00');
        Obs.Expect('touniversal-R', 'ok:Sun, 15 Jan 2023 12:00:00 GMT');
        Obs.Verify();
    end;
}
