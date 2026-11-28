// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73382, helper codeunit 73382, test codeunit 73383
// Probe (AL Runner pull request 9326, issue 9265; the values its review asks for): X := FR.Value() with FR a Date, Time or
//   DateTime field and X a plain local Integer, BigInteger, Decimal, Byte, Char, Duration, Option (A,B,C) or Boolean, for values
//   FvcTemporalIntoNumberPlaces.al does not measure: the Dates 1753-01-01 and 9999-12-31, the closing date
//   ClosingDate(2026-01-15), the Times 08:30:15 and 00:00:01, and the DateTime 1753-01-01 00:00:01. Neighbour of the Targets
//   tests of FvcTemporalIntoNumberPlaces.al (codeunit 73491).
//   Each cell runs in a TryFunction on a fresh RecordRef and records "ok: <Format(result, 0, 9)>" or "E: <GetLastErrorText> |
//   <GetLastErrorCode>". A test is <Source>_Targets.
//   Observe round: every test ends with Observer.Finish(), which fails the test with the readings (OBSERVE:...); nothing is asserted yet.
// BC versions: 27, 28, 29 by CI
table 73382 "LT FTM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(4; DtF; DateTime) { }
        field(5; DateF; Date) { }
        field(6; TimeF; Time) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73382 "LT FTM Probe"
{
    local procedure Source(var RR: RecordRef; var FR: FieldRef; Src: Text)
    begin
        RR.Open(Database::"LT FTM Row");
        case Src of
            'EarlyDate':
                begin
                    FR := RR.Field(5);
                    FR.Value := 17530101D;
                end;
            'LateDate':
                begin
                    FR := RR.Field(5);
                    FR.Value := 99991231D;
                end;
            'ClosingDate':
                begin
                    FR := RR.Field(5);
                    FR.Value := ClosingDate(20260115D);
                end;
            'Time083015':
                begin
                    FR := RR.Field(6);
                    FR.Value := 083015T;
                end;
            'Time000001':
                begin
                    FR := RR.Field(6);
                    FR.Value := 000001T;
                end;
            'DateTimeEarly':
                begin
                    FR := RR.Field(4);
                    FR.Value := CreateDateTime(17530101D, 000001T);
                end;
        end;
    end;

    [TryFunction]
    local procedure TryTarget(var FR: FieldRef; Target: Text; var Result: Text)
    var
        XInteger: Integer;
        XBigInteger: BigInteger;
        XDecimal: Decimal;
        XByte: Byte;
        XChar: Char;
        XDuration: Duration;
        XOption: Option A,B,C;
        XBoolean: Boolean;
    begin
        case Target of
            'Integer':
                begin
                    XInteger := FR.Value();
                    Result := Format(XInteger, 0, 9);
                end;
            'BigInteger':
                begin
                    XBigInteger := FR.Value();
                    Result := Format(XBigInteger, 0, 9);
                end;
            'Decimal':
                begin
                    XDecimal := FR.Value();
                    Result := Format(XDecimal, 0, 9);
                end;
            'Byte':
                begin
                    XByte := FR.Value();
                    Result := Format(XByte, 0, 9);
                end;
            'Char':
                begin
                    XChar := FR.Value();
                    Result := Format(XChar, 0, 9);
                end;
            'Duration':
                begin
                    XDuration := FR.Value();
                    Result := Format(XDuration, 0, 9);
                end;
            'Option':
                begin
                    XOption := FR.Value();
                    Result := Format(XOption, 0, 9);
                end;
            'Boolean':
                begin
                    XBoolean := FR.Value();
                    Result := Format(XBoolean, 0, 9);
                end;
        end;
    end;

    procedure TargetCell(var Observer: Codeunit "Probe Observer"; Src: Text; Target: Text)
    var
        RR: RecordRef;
        FR: FieldRef;
        Result: Text;
        T: Text;
    begin
        Source(RR, FR, Src);
        ClearLastError();
        if TryTarget(FR, Target, Result) then
            T := 'ok: ' + Result
        else
            T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        Observer.Observe(Target, T);
        RR.Close();
    end;
}

codeunit 73383 "LT FTM Value Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The Date 1753-01-01 into each target, in a plain local.
    [Test]
    procedure EarlyDate_Targets()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTM Probe";
    begin
        Probe.TargetCell(Observer, 'EarlyDate', 'Integer');
        Probe.TargetCell(Observer, 'EarlyDate', 'BigInteger');
        Probe.TargetCell(Observer, 'EarlyDate', 'Decimal');
        Probe.TargetCell(Observer, 'EarlyDate', 'Byte');
        Probe.TargetCell(Observer, 'EarlyDate', 'Char');
        Probe.TargetCell(Observer, 'EarlyDate', 'Duration');
        Probe.TargetCell(Observer, 'EarlyDate', 'Option');
        Probe.TargetCell(Observer, 'EarlyDate', 'Boolean');
        Observer.Finish();
    end;

    // The Date 9999-12-31 into each target, in a plain local.
    [Test]
    procedure LateDate_Targets()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTM Probe";
    begin
        Probe.TargetCell(Observer, 'LateDate', 'Integer');
        Probe.TargetCell(Observer, 'LateDate', 'BigInteger');
        Probe.TargetCell(Observer, 'LateDate', 'Decimal');
        Probe.TargetCell(Observer, 'LateDate', 'Byte');
        Probe.TargetCell(Observer, 'LateDate', 'Char');
        Probe.TargetCell(Observer, 'LateDate', 'Duration');
        Probe.TargetCell(Observer, 'LateDate', 'Option');
        Probe.TargetCell(Observer, 'LateDate', 'Boolean');
        Observer.Finish();
    end;

    // The closing date C01/15/26 into each target, in a plain local.
    [Test]
    procedure ClosingDate_Targets()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTM Probe";
    begin
        Probe.TargetCell(Observer, 'ClosingDate', 'Integer');
        Probe.TargetCell(Observer, 'ClosingDate', 'BigInteger');
        Probe.TargetCell(Observer, 'ClosingDate', 'Decimal');
        Probe.TargetCell(Observer, 'ClosingDate', 'Byte');
        Probe.TargetCell(Observer, 'ClosingDate', 'Char');
        Probe.TargetCell(Observer, 'ClosingDate', 'Duration');
        Probe.TargetCell(Observer, 'ClosingDate', 'Option');
        Probe.TargetCell(Observer, 'ClosingDate', 'Boolean');
        Observer.Finish();
    end;

    // The Time 08:30:15 into each target, in a plain local.
    [Test]
    procedure Time083015_Targets()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTM Probe";
    begin
        Probe.TargetCell(Observer, 'Time083015', 'Integer');
        Probe.TargetCell(Observer, 'Time083015', 'BigInteger');
        Probe.TargetCell(Observer, 'Time083015', 'Decimal');
        Probe.TargetCell(Observer, 'Time083015', 'Byte');
        Probe.TargetCell(Observer, 'Time083015', 'Char');
        Probe.TargetCell(Observer, 'Time083015', 'Duration');
        Probe.TargetCell(Observer, 'Time083015', 'Option');
        Probe.TargetCell(Observer, 'Time083015', 'Boolean');
        Observer.Finish();
    end;

    // The Time 00:00:01 into each target, in a plain local.
    [Test]
    procedure Time000001_Targets()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTM Probe";
    begin
        Probe.TargetCell(Observer, 'Time000001', 'Integer');
        Probe.TargetCell(Observer, 'Time000001', 'BigInteger');
        Probe.TargetCell(Observer, 'Time000001', 'Decimal');
        Probe.TargetCell(Observer, 'Time000001', 'Byte');
        Probe.TargetCell(Observer, 'Time000001', 'Char');
        Probe.TargetCell(Observer, 'Time000001', 'Duration');
        Probe.TargetCell(Observer, 'Time000001', 'Option');
        Probe.TargetCell(Observer, 'Time000001', 'Boolean');
        Observer.Finish();
    end;

    // The DateTime 1753-01-01 00:00:01 into each target, in a plain local.
    [Test]
    procedure DateTimeEarly_Targets()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTM Probe";
    begin
        Probe.TargetCell(Observer, 'DateTimeEarly', 'Integer');
        Probe.TargetCell(Observer, 'DateTimeEarly', 'BigInteger');
        Probe.TargetCell(Observer, 'DateTimeEarly', 'Decimal');
        Probe.TargetCell(Observer, 'DateTimeEarly', 'Byte');
        Probe.TargetCell(Observer, 'DateTimeEarly', 'Char');
        Probe.TargetCell(Observer, 'DateTimeEarly', 'Duration');
        Probe.TargetCell(Observer, 'DateTimeEarly', 'Option');
        Probe.TargetCell(Observer, 'DateTimeEarly', 'Boolean');
        Observer.Finish();
    end;
}
