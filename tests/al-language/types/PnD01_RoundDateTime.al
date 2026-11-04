// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-roundatetime-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects codeunit 72028
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles docs/probes-needed.md row: Probe batch 7 (npcore-partners) item 4, RoundDateTime(DateTime [, Precision [, Direction]]) - Probe wanted: RoundDateTime(dt,1000) ...
// Facts: RoundDateTime results (milliseconds after 2020-01-01 00:00:00) for below / on / above / half way values, precision 1000, 60000, 180000, 700000, directions < > =, defaults, other precision types, 0, negative, undefined DateTime, invalid directions
// BC versions: 29 (27 and 28 by CI)

codeunit 72028 "LT PnD RoundDateTime"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRound(Dt: DateTime; Prec: BigInteger; Dir: Text; var Res: DateTime)
    begin
        Res := RoundDateTime(Dt, Prec, Dir);
    end;

    [TryFunction]
    local procedure TryRoundDefaultDir(Dt: DateTime; Prec: BigInteger; var Res: DateTime)
    begin
        Res := RoundDateTime(Dt, Prec);
    end;

    [TryFunction]
    local procedure TryRoundDefaults(Dt: DateTime; var Res: DateTime)
    begin
        Res := RoundDateTime(Dt);
    end;

    [TryFunction]
    local procedure TryRoundDuration(Dt: DateTime; Prec: Duration; var Res: DateTime)
    begin
        Res := RoundDateTime(Dt, Prec);
    end;

    local procedure BaseDt(): DateTime
    begin
        exit(CreateDateTime(DMY2Date(1, 1, 2020), 000000T));
    end;

    local procedure Show(Res: DateTime): Text
    var
        D: Duration;
        Ms: BigInteger;
    begin
        if Res = 0DT then
            exit('undefined');
        D := Res - BaseDt();
        Ms := D;
        exit(Format(Ms));
    end;

    local procedure R(OffsetMs: BigInteger; Prec: BigInteger; Dir: Text): Text
    var
        Res: DateTime;
    begin
        if TryRound(BaseDt() + OffsetMs, Prec, Dir, Res) then
            exit(Show(Res));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure RD(OffsetMs: BigInteger; Prec: BigInteger): Text
    var
        Res: DateTime;
    begin
        if TryRoundDefaultDir(BaseDt() + OffsetMs, Prec, Res) then
            exit(Show(Res));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Prec1000_Equals()
    var
        Observer: Codeunit "Probe Observer";
        Offs: List of [BigInteger];
        O: BigInteger;
    begin
        Offs.AddRange(0, 1, 499, 500, 501, 999, 1000, 1499, 1500, 1501);
        foreach O in Offs do
            Observer.Observe('eq' + Format(O), R(O, 1000, '='));
        Observer.Expect('eq0', '0');
        Observer.Expect('eq1', '0');
        Observer.Expect('eq499', '0');
        Observer.Expect('eq500', '1000');
        Observer.Expect('eq501', '1000');
        Observer.Expect('eq999', '1000');
        Observer.Expect('eq1000', '1000');
        Observer.Expect('eq1499', '1000');
        Observer.Expect('eq1500', '2000');
        Observer.Expect('eq1501', '2000');
        Observer.Verify();
    end;

    [Test]
    procedure Prec1000_Down()
    var
        Observer: Codeunit "Probe Observer";
        Offs: List of [BigInteger];
        O: BigInteger;
    begin
        Offs.AddRange(0, 1, 499, 500, 501, 999, 1000, 1500);
        foreach O in Offs do
            Observer.Observe('down' + Format(O), R(O, 1000, '<'));
        Observer.Expect('down0', '0');
        Observer.Expect('down1', '0');
        Observer.Expect('down499', '0');
        Observer.Expect('down500', '0');
        Observer.Expect('down501', '0');
        Observer.Expect('down999', '0');
        Observer.Expect('down1000', '1000');
        Observer.Expect('down1500', '1000');
        Observer.Verify();
    end;

    [Test]
    procedure Prec1000_Up()
    var
        Observer: Codeunit "Probe Observer";
        Offs: List of [BigInteger];
        O: BigInteger;
    begin
        Offs.AddRange(0, 1, 499, 500, 501, 999, 1000, 1500);
        foreach O in Offs do
            Observer.Observe('up' + Format(O), R(O, 1000, '>'));
        Observer.Expect('up0', '0');
        Observer.Expect('up1', '1000');
        Observer.Expect('up499', '1000');
        Observer.Expect('up500', '1000');
        Observer.Expect('up501', '1000');
        Observer.Expect('up999', '1000');
        Observer.Expect('up1000', '1000');
        Observer.Expect('up1500', '2000');
        Observer.Verify();
    end;

    [Test]
    procedure Defaults_PrecisionAndDirection()
    var
        Observer: Codeunit "Probe Observer";
        Offs: List of [BigInteger];
        O: BigInteger;
        Res: DateTime;
    begin
        Offs.AddRange(0, 400, 500, 600, 1499, 1500);
        foreach O in Offs do begin
            Observer.Observe('dirdefault' + Format(O), RD(O, 1000));
            if TryRoundDefaults(BaseDt() + O, Res) then
                Observer.Observe('bothdefault' + Format(O), Show(Res))
            else
                Observer.Observe('bothdefault' + Format(O), 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        end;
        Observer.Expect('dirdefault0', '0');
        Observer.Expect('bothdefault0', '0');
        Observer.Expect('dirdefault400', '0');
        Observer.Expect('bothdefault400', '0');
        Observer.Expect('dirdefault500', '1000');
        Observer.Expect('bothdefault500', '1000');
        Observer.Expect('dirdefault600', '1000');
        Observer.Expect('bothdefault600', '1000');
        Observer.Expect('dirdefault1499', '1000');
        Observer.Expect('bothdefault1499', '1000');
        Observer.Expect('dirdefault1500', '2000');
        Observer.Expect('bothdefault1500', '2000');
        Observer.Verify();
    end;

    [Test]
    procedure Prec60000_AllDirections()
    var
        Observer: Codeunit "Probe Observer";
        Offs: List of [BigInteger];
        O: BigInteger;
    begin
        Offs.AddRange(0, 29999, 30000, 30001, 60000);
        foreach O in Offs do begin
            Observer.Observe('eq' + Format(O), R(O, 60000, '='));
            Observer.Observe('down' + Format(O), R(O, 60000, '<'));
            Observer.Observe('up' + Format(O), R(O, 60000, '>'));
        end;
        Observer.Expect('eq0', '0');
        Observer.Expect('down0', '0');
        Observer.Expect('up0', '0');
        Observer.Expect('eq29999', '0');
        Observer.Expect('down29999', '0');
        Observer.Expect('up29999', '60000');
        Observer.Expect('eq30000', '60000');
        Observer.Expect('down30000', '0');
        Observer.Expect('up30000', '60000');
        Observer.Expect('eq30001', '60000');
        Observer.Expect('down30001', '0');
        Observer.Expect('up30001', '60000');
        Observer.Expect('eq60000', '60000');
        Observer.Expect('down60000', '60000');
        Observer.Expect('up60000', '60000');
        Observer.Verify();
    end;

    [Test]
    procedure Prec180000_AllDirections()
    var
        Observer: Codeunit "Probe Observer";
        Offs: List of [BigInteger];
        O: BigInteger;
    begin
        Offs.AddRange(0, 89999, 90000, 90001, 180000);
        foreach O in Offs do begin
            Observer.Observe('eq' + Format(O), R(O, 180000, '='));
            Observer.Observe('down' + Format(O), R(O, 180000, '<'));
            Observer.Observe('up' + Format(O), R(O, 180000, '>'));
        end;
        Observer.Expect('eq0', '0');
        Observer.Expect('down0', '0');
        Observer.Expect('up0', '0');
        Observer.Expect('eq89999', '0');
        Observer.Expect('down89999', '0');
        Observer.Expect('up89999', '180000');
        Observer.Expect('eq90000', '180000');
        Observer.Expect('down90000', '0');
        Observer.Expect('up90000', '180000');
        Observer.Expect('eq90001', '180000');
        Observer.Expect('down90001', '0');
        Observer.Expect('up90001', '180000');
        Observer.Expect('eq180000', '180000');
        Observer.Expect('down180000', '180000');
        Observer.Expect('up180000', '180000');
        Observer.Verify();
    end;

    [Test]
    procedure Prec700000_DoesNotDivideADay()
    var
        Observer: Codeunit "Probe Observer";
        Offs: List of [BigInteger];
        O: BigInteger;
    begin
        Offs.AddRange(0, 349999, 350000, 700000, 3600000);
        foreach O in Offs do begin
            Observer.Observe('eq' + Format(O), R(O, 700000, '='));
            Observer.Observe('down' + Format(O), R(O, 700000, '<'));
            Observer.Observe('up' + Format(O), R(O, 700000, '>'));
        end;
        Observer.Expect('eq0', '200000');
        Observer.Expect('down0', '-500000');
        Observer.Expect('up0', '200000');
        Observer.Expect('eq349999', '200000');
        Observer.Expect('down349999', '200000');
        Observer.Expect('up349999', '900000');
        Observer.Expect('eq350000', '200000');
        Observer.Expect('down350000', '200000');
        Observer.Expect('up350000', '900000');
        Observer.Expect('eq700000', '900000');
        Observer.Expect('down700000', '200000');
        Observer.Expect('up700000', '900000');
        Observer.Expect('eq3600000', '3700000');
        Observer.Expect('down3600000', '3000000');
        Observer.Expect('up3600000', '3700000');
        Observer.Verify();
    end;

    [Test]
    procedure PrecisionTypesAndOddValues()
    var
        Observer: Codeunit "Probe Observer";
        Res: DateTime;
        Dur: Duration;
        Big: BigInteger;
    begin
        Dur := 180000;
        if TryRoundDuration(BaseDt() + 100000, Dur, Res) then
            Observer.Observe('duration3min', Show(Res))
        else
            Observer.Observe('duration3min', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Big := 180000;
        Observer.Observe('bigint3min', R(100000, Big, '='));
        Observer.Observe('prec0', R(100000, 0, '='));
        Observer.Observe('prec0down', R(100000, 0, '<'));
        Observer.Observe('precNeg', R(100000, -1000, '='));
        Observer.Observe('precNegDown', R(100000, -1000, '<'));
        Observer.Observe('prec1', R(100500, 1, '='));
        Big := 86400000;
        Big := Big * 10000;
        Observer.Observe('precHuge', R(100000, Big, '='));
        Observer.Observe('precOneDay', R(43200000, 86400000, '='));
        Observer.Observe('precOneDayUp', R(1, 86400000, '>'));
        Observer.Expect('duration3min', '180000');
        Observer.Expect('bigint3min', '180000');
        Observer.Expect('prec0', 'error:The contents ''0'' of ROUNDDATETIME parameter number 2 are invalid.|Argument');
        Observer.Expect('prec0down', 'error:The contents ''0'' of ROUNDDATETIME parameter number 2 are invalid.|Argument');
        Observer.Expect('precNeg', 'error:The contents ''-1000'' of ROUNDDATETIME parameter number 2 are invalid.|Argument');
        Observer.Expect('precNegDown', 'error:The contents ''-1000'' of ROUNDDATETIME parameter number 2 are invalid.|Argument');
        Observer.Expect('prec1', '100500');
        Observer.Expect('precHuge', '190944000000');
        Observer.Expect('precOneDay', '86400000');
        Observer.Expect('precOneDayUp', '86400000');
        Observer.Verify();
    end;

    [Test]
    procedure UndefinedDateTime()
    var
        Observer: Codeunit "Probe Observer";
        Res: DateTime;
    begin
        if TryRound(0DT, 1000, '=', Res) then
            Observer.Observe('undefEq', Show(Res))
        else
            Observer.Observe('undefEq', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        if TryRound(0DT, 60000, '>', Res) then
            Observer.Observe('undefUp', Show(Res))
        else
            Observer.Observe('undefUp', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        if TryRound(0DT, 60000, '<', Res) then
            Observer.Observe('undefDown', Show(Res))
        else
            Observer.Observe('undefDown', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        if TryRoundDefaults(0DT, Res) then
            Observer.Observe('undefDefaults', Show(Res))
        else
            Observer.Observe('undefDefaults', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('undefEq', 'undefined');
        Observer.Expect('undefUp', 'undefined');
        Observer.Expect('undefDown', 'undefined');
        Observer.Expect('undefDefaults', 'undefined');
        Observer.Verify();
    end;

    [Test]
    procedure InvalidDirections()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('empty', R(100000, 60000, ''));
        Observer.Observe('x', R(100000, 60000, 'x'));
        Observer.Observe('both', R(100000, 60000, '<>'));
        Observer.Observe('twoEq', R(100000, 60000, '=='));
        Observer.Observe('word', R(100000, 60000, 'up'));
        Observer.Observe('padded', R(100000, 60000, ' < '));
        Observer.Expect('empty', 'error:The contents '''' of ROUNDDATETIME parameter number 3 are invalid.|Argument');
        Observer.Expect('x', 'error:The contents ''x'' of ROUNDDATETIME parameter number 3 are invalid.|Argument');
        Observer.Expect('both', 'error:The contents ''<>'' of ROUNDDATETIME parameter number 3 are invalid.|Argument');
        Observer.Expect('twoEq', 'error:The contents ''=='' of ROUNDDATETIME parameter number 3 are invalid.|Argument');
        Observer.Expect('word', 'error:The contents ''up'' of ROUNDDATETIME parameter number 3 are invalid.|Argument');
        Observer.Expect('padded', 'error:The contents '' < '' of ROUNDDATETIME parameter number 3 are invalid.|Argument');
        Observer.Verify();
    end;
}
