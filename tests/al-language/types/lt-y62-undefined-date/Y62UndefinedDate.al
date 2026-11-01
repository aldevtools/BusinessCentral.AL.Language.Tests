// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datetime/datetime-data-type
// Scope: in-scope. Undefined temporal values (0D, 0T, 0DT): FieldRef.Value() of such fields passed to a procedure overloaded on Integer and
//   Variant (and on Decimal and Variant); 0DT - 0DT and the subtraction of the system fields of a record that was never inserted; a Variant that
//   holds 0D, 0T or 0DT assigned to Integer, Decimal, BigInteger, Duration and Text.
// Fixtures used: Probe Observer (69160); self-contained table 93264, codeunit 93263
// Probe: gap cycle 6, spec G6-22 (writer Y62). Every literal asserted below is what BC produced (corpus CI 27.5, 28.5, 29.0; SaaS sandbox BC 29).
// Facts: in the overload tests the text before the colon names the overload that ran (int, var, dec); values are Format(.., 0, 9) or
//   error:<text>|<code>.
// Results (same on 27.5, 28.5, 29.0 and the SaaS sandbox): FieldRef.Value() always takes the Variant overload; 0DT - 0DT is 0 (no error), so
//   is SystemModifiedAt - SystemCreatedAt of a record never inserted; a Variant holding 0D or 0T converts to 0 for the numbers and to a 0 Duration
//   but raises TypeConversion into Text; a Variant holding 0DT raises Conversion into Integer.
// BC versions: 27, 28, 29

table 93264 "LT Y62 UD Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Date) { }
        field(3; Tm; Time) { }
        field(4; Dt; DateTime) { }
        field(5; Dur; Duration) { }
        field(6; Dec; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93263 "LT Y62 Undefined Date"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y62 UD Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.D := 20260115D;
        Row.Tm := 123000T;
        Row.Dt := CreateDateTime(20260115D, 123000T);
        Row.Dur := 5000;
        Row.Dec := 7.5;
        Row.Insert();
    end;

    local procedure Num(Val: Integer): Text
    begin
        exit('int:' + Format(Val, 0, 9));
    end;

    local procedure Num(V: Variant): Text
    begin
        exit('var:' + Format(V, 0, 9));
    end;

    local procedure NumDec(Val: Decimal): Text
    begin
        exit('dec:' + Format(Val, 0, 9));
    end;

    local procedure NumDec(V: Variant): Text
    begin
        exit('var:' + Format(V, 0, 9));
    end;

    [TryFunction]
    local procedure TryNum(var FRef: FieldRef; var Txt: Text)
    begin
        Txt := Num(FRef.Value());
    end;

    [TryFunction]
    local procedure TryNumDec(var FRef: FieldRef; var Txt: Text)
    begin
        Txt := NumDec(FRef.Value());
    end;

    local procedure Pick(var RecRef: RecordRef; FieldNo: Integer): Text
    var
        FRef: FieldRef;
        Txt: Text;
        DecTxt: Text;
    begin
        FRef := RecRef.Field(FieldNo);
        ClearLastError();
        if not TryNum(FRef, Txt) then
            Txt := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        if not TryNumDec(FRef, DecTxt) then
            DecTxt := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        // the DateTime of row 2 in XML form depends on the server time zone: shown as <dt>
        exit((Txt + ' / ' + DecTxt).Replace(Format(CreateDateTime(20260115D, 123000T), 0, 9), '<dt>'));
    end;

    [Test]
    procedure FieldRefValue_OverloadPick_EmptyAndSet()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FieldNo: Integer;
        Id: Integer;
    begin
        Seed();
        RecRef.Open(Database::"LT Y62 UD Row");
        for Id := 1 to 2 do begin
            RecRef.Field(1).SetRange(Id);
            RecRef.FindFirst();
            for FieldNo := 2 to 6 do
                Observer.Observe('row' + Format(Id) + ' ' + RecRef.Field(FieldNo).Name, Pick(RecRef, FieldNo));
        end;
        RecRef.Close();
        Observer.Expect('row1 D', 'var: / var:');
        Observer.Expect('row1 Tm', 'var: / var:');
        Observer.Expect('row1 Dt', 'var: / var:');
        Observer.Expect('row1 Dur', 'var:P0DT0H0M0.0S / var:P0DT0H0M0.0S');
        Observer.Expect('row1 Dec', 'var:0 / var:0');
        Observer.Expect('row2 D', 'var:2026-01-15 / var:2026-01-15');
        Observer.Expect('row2 Tm', 'var:12:30:00 / var:12:30:00');
        Observer.Expect('row2 Dt', 'var:<dt> / var:<dt>');
        Observer.Expect('row2 Dur', 'var:P0DT0H0M5.0S / var:P0DT0H0M5.0S');
        Observer.Expect('row2 Dec', 'var:7.5 / var:7.5');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySub(A: DateTime; B: DateTime; var Result: Duration)
    begin
        Result := A - B;
    end;

    local procedure Sub(A: DateTime; B: DateTime): Text
    var
        Result: Duration;
    begin
        ClearLastError();
        if TrySub(A, B, Result) then
            exit('ok:[' + Format(Result) + ']|' + Format(Result, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryLess(A: DateTime; B: DateTime; Limit: Duration; var Result: Boolean)
    begin
        Result := A - B < Limit;
    end;

    local procedure Less(A: DateTime; B: DateTime; Limit: Duration): Text
    var
        Result: Boolean;
    begin
        ClearLastError();
        if TryLess(A, B, Limit, Result) then
            exit(Format(Result));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DateTimeSub_BothUndefined()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y62 UD Row";
        OneHour: Duration;
    begin
        OneHour := 60 * 60 * 1000;
        Observer.Observe('0DT - 0DT', Sub(0DT, 0DT));
        Observer.Observe('created is 0DT', Format(Row.SystemCreatedAt = 0DT));
        Observer.Observe('modified - created', Sub(Row.SystemModifiedAt, Row.SystemCreatedAt));
        Observer.Observe('0DT - 0DT < OneHour', Less(0DT, 0DT, OneHour));
        Observer.Observe('modified - created < OneHour', Less(Row.SystemModifiedAt, Row.SystemCreatedAt, OneHour));
        Observer.Observe('0DT - 0DT < 0', Less(0DT, 0DT, 0));
        Observer.Expect('0DT - 0DT', 'ok:[]|P0DT0H0M0.0S');
        Observer.Expect('created is 0DT', 'Yes');
        Observer.Expect('modified - created', 'ok:[]|P0DT0H0M0.0S');
        Observer.Expect('0DT - 0DT < OneHour', 'Yes');
        Observer.Expect('modified - created < OneHour', 'Yes');
        Observer.Expect('0DT - 0DT < 0', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure DateTimeSub_OneUndefined_AndDefinedPair()
    var
        Observer: Codeunit "Probe Observer";
        Dt: DateTime;
    begin
        Dt := CreateDateTime(20260115D, 123000T);
        Observer.Observe('Dt - 0DT', Sub(Dt, 0DT));
        Observer.Observe('0DT - Dt', Sub(0DT, Dt));
        Observer.Observe('Dt - Dt', Sub(Dt, Dt));
        Observer.Expect('Dt - 0DT', 'error:The date is not valid.|DateInvalid');
        Observer.Expect('0DT - Dt', 'error:The date is not valid.|DateInvalid');
        Observer.Expect('Dt - Dt', 'ok:[]|P0DT0H0M0.0S');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryInteger(V: Variant; var Txt: Text)
    var
        I: Integer;
    begin
        I := V;
        Txt := Format(I, 0, 9);
    end;

    [TryFunction]
    local procedure TryDecimal(V: Variant; var Txt: Text)
    var
        Dec: Decimal;
    begin
        Dec := V;
        Txt := Format(Dec, 0, 9);
    end;

    [TryFunction]
    local procedure TryBigInteger(V: Variant; var Txt: Text)
    var
        Big: BigInteger;
    begin
        Big := V;
        Txt := Format(Big, 0, 9);
    end;

    [TryFunction]
    local procedure TryDuration(V: Variant; var Txt: Text)
    var
        Dur: Duration;
    begin
        Dur := V;
        Txt := Format(Dur, 0, 9);
    end;

    [TryFunction]
    local procedure TryText(V: Variant; var Txt: Text)
    var
        T: Text;
    begin
        T := V;
        Txt := '[' + T + ']';
    end;

    local procedure Targets(V: Variant): Text
    var
        Txt: Text;
        All: Text;
        k: Integer;
        Ok: Boolean;
    begin
        for k := 1 to 5 do begin
            ClearLastError();
            Txt := '';
            case k of
                1:
                    Ok := TryInteger(V, Txt);
                2:
                    Ok := TryDecimal(V, Txt);
                3:
                    Ok := TryBigInteger(V, Txt);
                4:
                    Ok := TryDuration(V, Txt);
                5:
                    Ok := TryText(V, Txt);
            end;
            if not Ok then
                Txt := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
            All += Txt + ' ; ';
        end;
        exit(All);
    end;

    [Test]
    procedure VariantHoldingUndefined_IntoNumbers()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        V := 0D;
        Observer.Observe('0D', Targets(V));
        V := 0T;
        Observer.Observe('0T', Targets(V));
        V := 0DT;
        Observer.Observe('0DT', Targets(V));
        V := 20260115D;
        Observer.Observe('20260115D', Targets(V));
        Observer.Expect('0D', '0 ; 0 ; 0 ; P0DT0H0M0.0S ; error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.|TypeConversion ; ');
        Observer.Expect('0T', '0 ; 0 ; 0 ; P0DT0H0M0.0S ; error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.|TypeConversion ; ');
        Observer.Expect('0DT', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDateTime to System.Int32.|Conversion ; 0 ; 0 ; P0DT0H0M0.0S ; error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.|TypeConversion ; ');
        Observer.Expect('20260115D', '1479993 ; 1479993 ; 1479993 ; P0DT0H24M39.993S ; error:The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.|TypeConversion ; ');
        Observer.Verify();
    end;
}
