// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcsums-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 78002 "LT AD Dur Row"
// Probe: Record.CalcSums on a Duration field that is in a key's SumIndexFields and on one that is not, alone and with a Decimal field, with and
// without a filter, on an empty set and on a record that was set before; the result or the error text and code, and the value of the fields afterwards.
// FieldRef.CalcSum on a Duration is pinned in recordref/lt-fieldref-calcsum-types. Object ids 78002 - 78003.

table 78002 "LT AD Dur Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Dur; Duration) { }
        field(3; Dec; Decimal) { }
        field(4; DurPlain; Duration) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; SumIndexFields = Dur, Dec; }
    }
}

codeunit 78003 "LT AD CalcSums Duration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AD Dur Row";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 3 do begin
            Row.Init();
            Row.Id := Index;
            Row.Dur := Index * 1000;
            Row.Dec := Index;
            Row.DurPlain := Index * 60000;
            Row.Insert();
        end;
    end;

    [TryFunction]
    local procedure TrySums1(var Row: Record "LT AD Dur Row")
    begin
        Row.CalcSums(Dur);
    end;

    [TryFunction]
    local procedure TrySums2(var Row: Record "LT AD Dur Row")
    begin
        Row.CalcSums(Dur, Dec);
    end;

    [TryFunction]
    local procedure TrySumsPlain(var Row: Record "LT AD Dur Row")
    begin
        Row.CalcSums(DurPlain);
    end;

    local procedure State(var Row: Record "LT AD Dur Row"): Text
    begin
        exit('id=' + Format(Row.Id) + '|dur=' + Format(Row.Dur) + '|ms=' + Format(Row.Dur, 0, 9) + '|dec=' + Format(Row.Dec) + '|plain=' + Format(Row.DurPlain, 0, 9));
    end;

    local procedure Failed(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure CalcSums_Duration_All()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AD Dur Row";
    begin
        Seed();
        ClearLastError();
        if TrySums1(Row) then
            Observer.Observe('fresh_record', 'ok|' + State(Row))
        else
            Observer.Observe('fresh_record', Failed());
        Clear(Row);
        Row.Id := 99;
        Row.Dur := 777;
        Row.Dec := 5;
        Row.DurPlain := 888;
        ClearLastError();
        if TrySums1(Row) then
            Observer.Observe('preset_record', 'ok|' + State(Row))
        else
            Observer.Observe('preset_record', Failed());
        Clear(Row);
        ClearLastError();
        if TrySums2(Row) then
            Observer.Observe('two_fields', 'ok|' + State(Row))
        else
            Observer.Observe('two_fields', Failed());
        Observer.Expect('fresh_record', 'ok|id=0|dur=6 seconds|ms=P0DT0H0M6.0S|dec=0|plain=P0DT0H0M0.0S');
        Observer.Expect('preset_record', 'ok|id=99|dur=6 seconds|ms=P0DT0H0M6.0S|dec=5|plain=P0DT0H0M0.888S');
        Observer.Expect('two_fields', 'ok|id=0|dur=6 seconds|ms=P0DT0H0M6.0S|dec=6|plain=P0DT0H0M0.0S');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSums_Duration_Filtered()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AD Dur Row";
    begin
        Seed();
        Row.SetRange(Id, 2, 3);
        ClearLastError();
        if TrySums1(Row) then
            Observer.Observe('range_2_3', 'ok|' + State(Row))
        else
            Observer.Observe('range_2_3', Failed());
        Row.SetRange(Id, 50);
        Row.Dur := 123;
        ClearLastError();
        if TrySums1(Row) then
            Observer.Observe('empty_set', 'ok|' + State(Row))
        else
            Observer.Observe('empty_set', Failed());
        Row.Reset();
        Row.Get(3);
        ClearLastError();
        if TrySums1(Row) then
            Observer.Observe('after_get', 'ok|' + State(Row))
        else
            Observer.Observe('after_get', Failed());
        Observer.Expect('range_2_3', 'ok|id=0|dur=5 seconds|ms=P0DT0H0M5.0S|dec=0|plain=P0DT0H0M0.0S');
        Observer.Expect('empty_set', 'ok|id=0|dur=|ms=P0DT0H0M0.0S|dec=0|plain=P0DT0H0M0.0S');
        Observer.Expect('after_get', 'ok|id=3|dur=6 seconds|ms=P0DT0H0M6.0S|dec=3|plain=P0DT0H3M0.0S');
        Observer.Verify();
    end;

    [Test]
    procedure CalcSums_Duration_NotInSumIndexFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AD Dur Row";
    begin
        Seed();
        Row.DurPlain := 5;
        ClearLastError();
        if TrySumsPlain(Row) then
            Observer.Observe('plain', 'ok|' + State(Row))
        else
            Observer.Observe('plain', Failed());
        Observer.Expect('plain', 'ok|id=0|dur=|ms=P0DT0H0M0.0S|dec=0|plain=P0DT0H6M0.0S');
        Observer.Verify();
    end;
}
