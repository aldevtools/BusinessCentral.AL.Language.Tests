// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-calcsum-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67154 "LT FCT Row"
// Probe: FieldRef.CalcSum on fields of every type other than Decimal and Integer: BigInteger (in the SumIndexFields list and outside it), Boolean, Date,
// Option, Duration, Time, DateTime, Code, and a FlowFilter field; the result or the error text and code, and the value of the field afterwards.
// Object ids 67154 - 67155.

table 67154 "LT FCT Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Big; BigInteger) { }
        field(3; BigPlain; BigInteger) { }
        field(4; Flag; Boolean) { }
        field(5; Day; Date) { }
        field(6; Opt; Option) { OptionMembers = Zero,One,Two; }
        field(7; Dur; Duration) { }
        field(8; Tm; Time) { }
        field(9; Stamp; DateTime) { }
        field(10; Cd; Code[10]) { }
        field(11; Dec; Decimal) { }
        field(12; FlowFilterDec; Decimal) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; SumIndexFields = Big, Dec; }
    }
}

codeunit 67155 "LT FCT CalcSum"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT FCT Row";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 3 do begin
            Row.Init();
            Row.Id := Index;
            Row.Big := Index * 10000000000L;
            Row.BigPlain := Index * 5;
            Row.Flag := Index <> 2;
            Row.Day := DMY2Date(Index, 1, 2024);
            Row.Opt := Index - 1;
            Row.Dur := Index * 1000;
            Row.Tm := 120000T + Index * 1000;
            Row.Stamp := CreateDateTime(DMY2Date(Index, 1, 2024), 120000T);
            Row.Cd := 'C' + Format(Index);
            Row.Dec := Index * 1.5;
            Row.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryCalcSum(var FR: FieldRef; var Result: Text)
    begin
        Result := Format(FR.CalcSum());
    end;

    local procedure Sum(FieldNo: Integer): Text
    var
        RR: RecordRef;
        FR: FieldRef;
        Result: Text;
    begin
        RR.Open(Database::"LT FCT Row");
        FR := RR.Field(FieldNo);
        ClearLastError();
        if TryCalcSum(FR, Result) then
            exit('ok:' + Result + '|value=' + Format(FR.Value));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|value=' + Format(FR.Value));
    end;

    [Test]
    procedure CalcSum_NumericTypes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('big_in_sumindex', Sum(2));
        Observer.Observe('big_not_in_sumindex', Sum(3));
        Observer.Observe('dec_in_sumindex', Sum(11));
        Observer.Observe('duration', Sum(7));
        Observer.Observe('option', Sum(6));
        Observer.Observe('flowfilter', Sum(12));
        Observer.Expect('big_in_sumindex', 'ok:Yes|value=60000000000');
        Observer.Expect('big_not_in_sumindex', 'ok:Yes|value=30');
        Observer.Expect('dec_in_sumindex', 'ok:Yes|value=9');
        Observer.Expect('duration', 'ok:Yes|value=6 seconds');
        Observer.Expect('option', 'error:Cannot calculate a sum of the values in the Opt field in the LT FCT Row table because one or more values are not normal numeric fields.|DB:Ok|value=Zero');
        Observer.Expect('flowfilter', 'error:Cannot calculate a sum of the values in the FlowFilterDec field in the LT FCT Row table because one or more values are not normal numeric fields.|DB:Ok|value=0');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSum_NonNumericTypes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('boolean', Sum(4));
        Observer.Observe('date', Sum(5));
        Observer.Observe('time', Sum(8));
        Observer.Observe('datetime', Sum(9));
        Observer.Observe('code', Sum(10));
        Observer.Observe('integer_key_field', Sum(1));
        Observer.Expect('boolean', 'error:Cannot calculate a sum of the values in the Flag field in the LT FCT Row table because one or more values are not normal numeric fields.|DB:Ok|value=No');
        Observer.Expect('date', 'error:Cannot calculate a sum of the values in the Day field in the LT FCT Row table because one or more values are not normal numeric fields.|DB:Ok|value=');
        Observer.Expect('time', 'error:Cannot calculate a sum of the values in the Tm field in the LT FCT Row table because one or more values are not normal numeric fields.|DB:Ok|value=');
        Observer.Expect('datetime', 'error:Cannot calculate a sum of the values in the Stamp field in the LT FCT Row table because one or more values are not normal numeric fields.|DB:Ok|value=');
        Observer.Expect('code', 'error:Cannot calculate a sum of the values in the Cd field in the LT FCT Row table because one or more values are not normal numeric fields.|DB:Ok|value=');
        Observer.Expect('integer_key_field', 'ok:Yes|value=6');
        Observer.Verify();
    end;
}
