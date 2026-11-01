// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 93629 (writer Y67, gap cycle 6 follow-up)
// Probe: a Variant that holds a DEFINED Date (the first valid date, early, 1899/1900 edges, 2000, a leap day, a date in 2026, the last valid
//   date, a closing date), a Time, a DateTime, a Duration, an Integer, a BigInteger, a Decimal, a Boolean or a Text number, assigned to
//   Integer, Decimal, BigInteger, Duration, Text, Date, Time, DateTime and Boolean. Values are Format(.., 0, 9) or error:<text>|<code>.
//   types/lt-y62-undefined-date/Y62UndefinedDate.al pins 0D, 0T, 0DT and 20260115D into the first five targets.
// BC versions: 27, 28, 29

codeunit 93629 "LT Y67 Variant Numeric"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure ToInteger(V: Variant; var Txt: Text)
    var
        T: Integer;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToDecimal(V: Variant; var Txt: Text)
    var
        T: Decimal;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToBigInteger(V: Variant; var Txt: Text)
    var
        T: BigInteger;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToDuration(V: Variant; var Txt: Text)
    var
        T: Duration;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToText(V: Variant; var Txt: Text)
    var
        T: Text;
    begin
        T := V;
        Txt := T;
    end;

    [TryFunction]
    local procedure ToDate(V: Variant; var Txt: Text)
    var
        T: Date;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToTime(V: Variant; var Txt: Text)
    var
        T: Time;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToDateTime(V: Variant; var Txt: Text)
    var
        T: DateTime;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    [TryFunction]
    local procedure ToBoolean(V: Variant; var Txt: Text)
    var
        T: Boolean;
    begin
        T := V;
        Txt := Format(T, 0, 9);
    end;

    local procedure Targets(V: Variant): Text
    var
        Txt: Text;
        All: Text;
        k: Integer;
        Ok: Boolean;
    begin
        for k := 1 to 9 do begin
            ClearLastError();
            Txt := '';
            case k of
                1:
                    Ok := ToInteger(V, Txt);
                2:
                    Ok := ToDecimal(V, Txt);
                3:
                    Ok := ToBigInteger(V, Txt);
                4:
                    Ok := ToDuration(V, Txt);
                5:
                    Ok := ToText(V, Txt);
                6:
                    Ok := ToDate(V, Txt);
                7:
                    Ok := ToTime(V, Txt);
                8:
                    Ok := ToDateTime(V, Txt);
                9:
                    Ok := ToBoolean(V, Txt);
            end;
            if not Ok then
                Txt := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
            All += Txt + ' ; ';
        end;
        exit(All);
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; V: Variant)
    begin
        Observer.Observe(Name, Targets(V));
    end;

    [Test]
    procedure DefinedDates_IntoNumbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, '17530101D', 17530101D);
        Show(Observer, '17530102D', 17530102D);
        Show(Observer, '18991231D', 18991231D);
        Show(Observer, '19000101D', 19000101D);
        Show(Observer, '19991231D', 19991231D);
        Show(Observer, '20000101D', 20000101D);
        Observer.Finish();
    end;

    [Test]
    procedure DefinedDates_IntoNumbers_More()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, '20240229D', 20240229D);
        Show(Observer, '20260115D', 20260115D);
        Show(Observer, '20261231D', 20261231D);
        Show(Observer, '99991231D', 99991231D);
        Show(Observer, 'closing 20260115D', ClosingDate(20260115D));
        Show(Observer, 'closing 17530101D', ClosingDate(17530101D));
        Observer.Finish();
    end;

    [Test]
    procedure TimesAndDateTimes_IntoNumbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, '000000T', 000000T);
        Show(Observer, '120000T', 120000T);
        Show(Observer, '235959.999T', 235959.999T);
        Show(Observer, 'dt 20260115 120000', CreateDateTime(20260115D, 120000T));
        Show(Observer, 'dt 20000101 000000', CreateDateTime(20000101D, 000000T));
        Show(Observer, 'dt closing', CreateDateTime(ClosingDate(20260115D), 120000T));
        Observer.Finish();
    end;

    [Test]
    procedure OtherNumericTypes_IntoNumbers()
    var
        Observer: Codeunit "Probe Observer";
        Dur: Duration;
        Big: BigInteger;
        Dec: Decimal;
        Int: Integer;
        Flag: Boolean;
        Cd: Code[10];
    begin
        Dur := 1500;
        Evaluate(Big, '5000000000');
        Dec := 2.5;
        Int := -7;
        Flag := true;
        Cd := '12';
        Show(Observer, 'duration 1500', Dur);
        Show(Observer, 'biginteger', Big);
        Show(Observer, 'decimal 2.5', Dec);
        Show(Observer, 'integer -7', Int);
        Show(Observer, 'boolean true', Flag);
        Show(Observer, 'code 12', Cd);
        Observer.Finish();
    end;

    [Test]
    procedure TextNumbers_IntoNumbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'text 12', '12');
        Show(Observer, 'text 12.5', '12.5');
        Show(Observer, 'text 20260115', '20260115');
        Show(Observer, 'text true', 'true');
        Show(Observer, 'text empty', '');
        Show(Observer, 'text abc', 'abc');
        Observer.Finish();
    end;
}
