// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; own dotnet aliases LtTz*; self-contained codeunit 99361
// Probe: an AL DateTime handed to .NET (System.DateTime, System.TimeZoneInfo) around daylight saving transitions
// (aldevtools/BusinessCentral.AL.Runner#8587). Every UTC moment is built in AL with Evaluate(Dt, '<yyyy-mm-dd>T<hh:mm:ss>Z', 9).
//   - the DateTimeKind and the round-trip text ('o') BC gives an AL DateTime in a DotNet DateTime variable,
//   - TimeZoneInfo.GetUtcOffset and IsDaylightSavingTime of W. Europe, AUS Eastern and Pacific Standard Time one second before, at and
//     one second after each 2023 transition, and for W. Europe at the transitions of the current year (computed from Today with the EU
//     rule: last Sunday of March and of October, 01:00 UTC; the observation names carry no year),
//   - GetUtcOffset of a DateTime made in .NET (kind Unspecified and kind Utc),
//   - IsAmbiguousTime, IsInvalidTime, ConvertTimeFromUtc, ConvertTime and ConvertTimeToUtc with an AL DateTime at the 2023 transitions.
// A Duration is shown as Format(d) and Format(d, 0, 9); a DateTime as Format(d, 0, 9); a DotNet DateTime as ToString('o') and its Kind.
// Every call runs in a TryFunction and is observed as ok:<result> or error:<text>|<code>.
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.TimeZoneInfo"; LtTzInfo) { }
        type("System.DateTime"; LtTzDateTime) { }
        type("System.DateTimeKind"; LtTzKind) { }
    }
}

codeunit 99361 "LT DotNet TzDst"
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

    local procedure FindZone(ZoneId: Text; var Zone: DotNet LtTzInfo)
    begin
        Zone := Zone.FindSystemTimeZoneById(ZoneId);
    end;

    local procedure DescribeDn(Dn: DotNet LtTzDateTime): Text
    begin
        exit(Dn.ToString('o') + ' kind=' + Dn.Kind.ToString());
    end;

    [TryFunction]
    local procedure DoMember(ZoneId: Text; Dt: DateTime; Member: Text; var R: Text)
    var
        Zone: DotNet LtTzInfo;
        TzStatic: DotNet LtTzInfo;
        Dn: DotNet LtTzDateTime;
        ResultDt: DateTime;
        Dur: Duration;
    begin
        FindZone(ZoneId, Zone);
        case Member of
            'offset':
                begin
                    Dur := Zone.GetUtcOffset(Dt);
                    R := Format(Dur) + '|' + Format(Dur, 0, 9);
                end;
            'isdst':
                R := Format(Zone.IsDaylightSavingTime(Dt));
            'ambiguous':
                R := Format(Zone.IsAmbiguousTime(Dt));
            'invalid':
                R := Format(Zone.IsInvalidTime(Dt));
            'fromutc':
                begin
                    Dn := TzStatic.ConvertTimeFromUtc(Dt, Zone);
                    ResultDt := Dn;
                    R := DescribeDn(Dn) + ' al=' + Format(ResultDt, 0, 9);
                end;
            'convert':
                begin
                    Dn := TzStatic.ConvertTime(Dt, Zone);
                    ResultDt := Dn;
                    R := DescribeDn(Dn) + ' al=' + Format(ResultDt, 0, 9);
                end;
            'toutc':
                begin
                    Dn := TzStatic.ConvertTimeToUtc(Dt, Zone);
                    ResultDt := Dn;
                    R := DescribeDn(Dn) + ' al=' + Format(ResultDt, 0, 9);
                end;
        end;
    end;

    local procedure Run(ZoneId: Text; Dt: DateTime; Member: Text): Text
    var
        R: Text;
    begin
        ClearLastError();
        if DoMember(ZoneId, Dt, Member, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure RunAt(ZoneId: Text; Moment: Text; Member: Text): Text
    begin
        exit(Run(ZoneId, Utc(Moment), Member));
    end;

    // The last Sunday of the month in the year of Today, as yyyy-mm-dd.
    local procedure LastSunday(MonthNo: Integer): Text
    var
        D: Date;
    begin
        D := CalcDate('<CM>', DMY2Date(1, MonthNo, Date2DMY(Today(), 3)));
        while Date2DWY(D, 1) <> 7 do
            D := D - 1;
        exit(Format(D, 0, 9));
    end;

    local procedure CurrentYear(MonthNo: Integer; DayNo: Integer): Text
    begin
        exit(Format(DMY2Date(DayNo, MonthNo, Date2DMY(Today(), 3)), 0, 9));
    end;

    local procedure ObserveWEurope2023(Member: Text; var Obs: Codeunit "Probe Observer")
    begin
        Obs.Observe('weu_' + Member + '_2023-01-15T12:00:00Z', RunAt('W. Europe Standard Time', '2023-01-15T12:00:00Z', Member));
        Obs.Observe('weu_' + Member + '_2023-07-15T12:00:00Z', RunAt('W. Europe Standard Time', '2023-07-15T12:00:00Z', Member));
        Obs.Observe('weu_' + Member + '_2023-03-26T00:59:59Z', RunAt('W. Europe Standard Time', '2023-03-26T00:59:59Z', Member));
        Obs.Observe('weu_' + Member + '_2023-03-26T01:00:00Z', RunAt('W. Europe Standard Time', '2023-03-26T01:00:00Z', Member));
        Obs.Observe('weu_' + Member + '_2023-03-26T01:00:01Z', RunAt('W. Europe Standard Time', '2023-03-26T01:00:01Z', Member));
        Obs.Observe('weu_' + Member + '_2023-10-29T00:59:59Z', RunAt('W. Europe Standard Time', '2023-10-29T00:59:59Z', Member));
        Obs.Observe('weu_' + Member + '_2023-10-29T01:00:00Z', RunAt('W. Europe Standard Time', '2023-10-29T01:00:00Z', Member));
        Obs.Observe('weu_' + Member + '_2023-10-29T01:00:01Z', RunAt('W. Europe Standard Time', '2023-10-29T01:00:01Z', Member));
    end;

    local procedure ObserveAus2023(Member: Text; var Obs: Codeunit "Probe Observer")
    begin
        Obs.Observe('aus_' + Member + '_2023-04-01T15:59:59Z', RunAt('AUS Eastern Standard Time', '2023-04-01T15:59:59Z', Member));
        Obs.Observe('aus_' + Member + '_2023-04-01T16:00:00Z', RunAt('AUS Eastern Standard Time', '2023-04-01T16:00:00Z', Member));
        Obs.Observe('aus_' + Member + '_2023-04-01T16:00:01Z', RunAt('AUS Eastern Standard Time', '2023-04-01T16:00:01Z', Member));
        Obs.Observe('aus_' + Member + '_2023-09-30T15:59:59Z', RunAt('AUS Eastern Standard Time', '2023-09-30T15:59:59Z', Member));
        Obs.Observe('aus_' + Member + '_2023-09-30T16:00:00Z', RunAt('AUS Eastern Standard Time', '2023-09-30T16:00:00Z', Member));
        Obs.Observe('aus_' + Member + '_2023-09-30T16:00:01Z', RunAt('AUS Eastern Standard Time', '2023-09-30T16:00:01Z', Member));
    end;

    local procedure ObservePacific2023(Member: Text; var Obs: Codeunit "Probe Observer")
    begin
        Obs.Observe('pac_' + Member + '_2023-03-12T09:59:59Z', RunAt('Pacific Standard Time', '2023-03-12T09:59:59Z', Member));
        Obs.Observe('pac_' + Member + '_2023-03-12T10:00:00Z', RunAt('Pacific Standard Time', '2023-03-12T10:00:00Z', Member));
        Obs.Observe('pac_' + Member + '_2023-03-12T10:00:01Z', RunAt('Pacific Standard Time', '2023-03-12T10:00:01Z', Member));
        Obs.Observe('pac_' + Member + '_2023-11-05T08:59:59Z', RunAt('Pacific Standard Time', '2023-11-05T08:59:59Z', Member));
        Obs.Observe('pac_' + Member + '_2023-11-05T09:00:00Z', RunAt('Pacific Standard Time', '2023-11-05T09:00:00Z', Member));
        Obs.Observe('pac_' + Member + '_2023-11-05T09:00:01Z', RunAt('Pacific Standard Time', '2023-11-05T09:00:01Z', Member));
    end;

    // Names carry no year: the values follow the EU rule in every year.
    local procedure ObserveWEuropeCurrentYear(Member: Text; var Obs: Codeunit "Probe Observer")
    begin
        Obs.Observe('weu_' + Member + '_cur_jan15_12:00:00Z', RunAt('W. Europe Standard Time', CurrentYear(1, 15) + 'T12:00:00Z', Member));
        Obs.Observe('weu_' + Member + '_cur_jul15_12:00:00Z', RunAt('W. Europe Standard Time', CurrentYear(7, 15) + 'T12:00:00Z', Member));
        Obs.Observe('weu_' + Member + '_cur_lastsunmar_00:59:59Z', RunAt('W. Europe Standard Time', LastSunday(3) + 'T00:59:59Z', Member));
        Obs.Observe('weu_' + Member + '_cur_lastsunmar_01:00:00Z', RunAt('W. Europe Standard Time', LastSunday(3) + 'T01:00:00Z', Member));
        Obs.Observe('weu_' + Member + '_cur_lastsunmar_01:00:01Z', RunAt('W. Europe Standard Time', LastSunday(3) + 'T01:00:01Z', Member));
        Obs.Observe('weu_' + Member + '_cur_lastsunoct_00:59:59Z', RunAt('W. Europe Standard Time', LastSunday(10) + 'T00:59:59Z', Member));
        Obs.Observe('weu_' + Member + '_cur_lastsunoct_01:00:00Z', RunAt('W. Europe Standard Time', LastSunday(10) + 'T01:00:00Z', Member));
        Obs.Observe('weu_' + Member + '_cur_lastsunoct_01:00:01Z', RunAt('W. Europe Standard Time', LastSunday(10) + 'T01:00:01Z', Member));
    end;

    [TryFunction]
    local procedure DoKind(Dt: DateTime; var R: Text)
    var
        Dn: DotNet LtTzDateTime;
    begin
        Dn := Dt;
        R := DescribeDn(Dn) + ' format=' + Format(Dn.Kind);
    end;

    local procedure KindOf(Dt: DateTime): Text
    var
        R: Text;
    begin
        ClearLastError();
        if DoKind(Dt, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoZoneId(ZoneId: Text; var R: Text)
    var
        Zone: DotNet LtTzInfo;
    begin
        FindZone(ZoneId, Zone);
        R := Zone.Id + ' supportsdst=' + Format(Zone.SupportsDaylightSavingTime);
    end;

    local procedure ZoneFound(ZoneId: Text): Text
    var
        R: Text;
    begin
        ClearLastError();
        if DoZoneId(ZoneId, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoDotNetMade(WithKind: Text; Member: Text; var R: Text)
    var
        Zone: DotNet LtTzInfo;
        Dn: DotNet LtTzDateTime;
        DnKind: DotNet LtTzKind;
        Dur: Duration;
    begin
        FindZone('W. Europe Standard Time', Zone);
        case WithKind of
            'unspecified':
                Dn := Dn.DateTime(2023, 3, 26, 1, 0, 0);
            'utc':
                begin
                    DnKind := DnKind.Utc;
                    Dn := Dn.DateTime(2023, 3, 26, 1, 0, 0, DnKind);
                end;
        end;
        case Member of
            'kind':
                R := DescribeDn(Dn) + ' format=' + Format(Dn.Kind);
            'offset':
                begin
                    Dur := Zone.GetUtcOffset(Dn);
                    R := Format(Dur) + '|' + Format(Dur, 0, 9);
                end;
            'isdst':
                R := Format(Zone.IsDaylightSavingTime(Dn));
        end;
    end;

    local procedure DotNetMade(WithKind: Text; Member: Text): Text
    var
        R: Text;
    begin
        ClearLastError();
        if DoDotNetMade(WithKind, Member, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Kind_AlDateTimeInDotNet_WinterSummer()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('zone_weu', ZoneFound('W. Europe Standard Time'));
        Obs.Observe('zone_aus', ZoneFound('AUS Eastern Standard Time'));
        Obs.Observe('zone_pac', ZoneFound('Pacific Standard Time'));
        Obs.Observe('kind_2023-01-15T12:00:00Z', KindOf(Utc('2023-01-15T12:00:00Z')));
        Obs.Observe('kind_2023-07-15T12:00:00Z', KindOf(Utc('2023-07-15T12:00:00Z')));
        Obs.Finish();
    end;

    [Test]
    procedure GetUtcOffset_WEurope_2023()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveWEurope2023('offset', Obs);
        Obs.Finish();
    end;

    [Test]
    procedure GetUtcOffset_AusEastern_2023()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveAus2023('offset', Obs);
        Obs.Finish();
    end;

    [Test]
    procedure GetUtcOffset_Pacific_2023()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObservePacific2023('offset', Obs);
        Obs.Finish();
    end;

    [Test]
    procedure GetUtcOffset_WEurope_CurrentYear()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveWEuropeCurrentYear('offset', Obs);
        Obs.Finish();
    end;

    [Test]
    procedure IsDaylightSavingTime_WEurope_2023()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveWEurope2023('isdst', Obs);
        Obs.Finish();
    end;

    [Test]
    procedure IsDaylightSavingTime_AusEasternPacific_2023()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveAus2023('isdst', Obs);
        ObservePacific2023('isdst', Obs);
        Obs.Finish();
    end;

    [Test]
    procedure IsDaylightSavingTime_WEurope_CurrentYear()
    var
        Obs: Codeunit "Probe Observer";
    begin
        ObserveWEuropeCurrentYear('isdst', Obs);
        Obs.Finish();
    end;

    [Test]
    procedure DotNetMadeDateTime_UnspecifiedAndUtc_WEurope()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('unspecified_kind', DotNetMade('unspecified', 'kind'));
        Obs.Observe('unspecified_offset', DotNetMade('unspecified', 'offset'));
        Obs.Observe('unspecified_isdst', DotNetMade('unspecified', 'isdst'));
        Obs.Observe('utc_kind', DotNetMade('utc', 'kind'));
        Obs.Observe('utc_offset', DotNetMade('utc', 'offset'));
        Obs.Observe('utc_isdst', DotNetMade('utc', 'isdst'));
        Obs.Finish();
    end;

    [Test]
    procedure AmbiguousInvalid_WEurope_2023Transitions()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('ambiguous_2023-03-26T01:00:00Z', RunAt('W. Europe Standard Time', '2023-03-26T01:00:00Z', 'ambiguous'));
        Obs.Observe('invalid_2023-03-26T01:00:00Z', RunAt('W. Europe Standard Time', '2023-03-26T01:00:00Z', 'invalid'));
        Obs.Observe('ambiguous_2023-10-29T01:00:00Z', RunAt('W. Europe Standard Time', '2023-10-29T01:00:00Z', 'ambiguous'));
        Obs.Observe('invalid_2023-10-29T01:00:00Z', RunAt('W. Europe Standard Time', '2023-10-29T01:00:00Z', 'invalid'));
        Obs.Finish();
    end;

    [Test]
    procedure Convert_WEurope_2023Transitions()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('fromutc_2023-03-26T01:00:00Z', RunAt('W. Europe Standard Time', '2023-03-26T01:00:00Z', 'fromutc'));
        Obs.Observe('convert_2023-03-26T01:00:00Z', RunAt('W. Europe Standard Time', '2023-03-26T01:00:00Z', 'convert'));
        Obs.Observe('toutc_2023-03-26T01:00:00Z', RunAt('W. Europe Standard Time', '2023-03-26T01:00:00Z', 'toutc'));
        Obs.Observe('fromutc_2023-10-29T01:00:00Z', RunAt('W. Europe Standard Time', '2023-10-29T01:00:00Z', 'fromutc'));
        Obs.Observe('convert_2023-10-29T01:00:00Z', RunAt('W. Europe Standard Time', '2023-10-29T01:00:00Z', 'convert'));
        Obs.Observe('toutc_2023-10-29T01:00:00Z', RunAt('W. Europe Standard Time', '2023-10-29T01:00:00Z', 'toutc'));
        Obs.Finish();
    end;
}
