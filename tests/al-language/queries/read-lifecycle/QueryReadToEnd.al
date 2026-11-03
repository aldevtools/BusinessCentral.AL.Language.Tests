// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-read-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 71409, query 71410
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a query read to its end (Read false): Read again, SetRange / SetFilter, Open again with and without Close, reading the new range; Open twice after the last row; SetRange after a partial read and after Close (error text and code through TryFunction, no read after an error that raised).
// BC versions: 29 (27 and 28 by CI)

table 71409 "LT QryEnd Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 71410 "LT QryEnd Rows"
{
    QueryType = Normal;
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Rows; "LT QryEnd Row")
        {
            column(Id; Id) { }
            column(Amount; Amount) { }
        }
    }
}

codeunit 71411 "LT Query Read To End"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT QryEnd Row";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 4 do begin
            R.Id := i;
            R.Amount := i * 10;
            R.Insert();
        end;
    end;

    local procedure Drain(var Q: Query "LT QryEnd Rows"): Text
    var
        Result: Text;
    begin
        while Q.Read() do
            Result += Format(Q.Id) + ',';
        exit(Result);
    end;

    [TryFunction]
    local procedure TryRange(var Q: Query "LT QryEnd Rows"; FromValue: Integer; ToValue: Integer)
    begin
        Q.SetRange(Id, FromValue, ToValue);
    end;

    [TryFunction]
    local procedure TryFilter(var Q: Query "LT QryEnd Rows"; FilterText: Text)
    begin
        Q.SetFilter(Id, FilterText);
    end;

    [TryFunction]
    local procedure TryOpen(var Q: Query "LT QryEnd Rows")
    begin
        Q.Open();
    end;

    [TryFunction]
    local procedure TryRead(var Q: Query "LT QryEnd Rows"; var Result: Boolean)
    begin
        Result := Q.Read();
    end;

    [Test]
    procedure SetRange_AfterLastRow_ThenOpenAndRead()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QryEnd Rows";
        Ok: Boolean;
        Got: Boolean;
    begin
        Seed();
        Q.Open();
        Observer.Observe('rows', Drain(Q));
        Ok := TryRange(Q, 2, 3);
        Observer.Observe('setrange ok', Format(Ok));
        Observer.ObserveError('setrange after end');
        Ok := TryOpen(Q);
        Observer.Observe('open ok', Format(Ok));
        Observer.ObserveError('open after setrange');
        Ok := TryRead(Q, Got);
        Observer.Observe('read ok', Format(Ok));
        Observer.Observe('read value', Format(Got));
        Observer.ObserveError('read after open');
        if Ok and Got then begin
            Observer.Observe('first id', Format(Q.Id));
            Observer.Observe('rest', Drain(Q));
        end;
        Q.Close();
        Observer.Expect('rows', '1,2,3,4,');
        Observer.Expect('setrange ok', 'Yes');
        Observer.Expect('setrange after end|text', '');
        Observer.Expect('setrange after end|code', '');
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('open after setrange|text', '');
        Observer.Expect('open after setrange|code', '');
        Observer.Expect('read ok', 'Yes');
        Observer.Expect('read value', 'Yes');
        Observer.Expect('read after open|text', '');
        Observer.Expect('read after open|code', '');
        Observer.Expect('first id', '2');
        Observer.Expect('rest', '3,');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_AfterLastRow_ThenOpenAndRead()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QryEnd Rows";
        Ok: Boolean;
        Got: Boolean;
    begin
        Seed();
        Q.Open();
        Observer.Observe('rows', Drain(Q));
        Ok := TryFilter(Q, '>=3');
        Observer.Observe('setfilter ok', Format(Ok));
        Observer.ObserveError('setfilter after end');
        Ok := TryOpen(Q);
        Observer.Observe('open ok', Format(Ok));
        Observer.ObserveError('open after setfilter');
        Ok := TryRead(Q, Got);
        Observer.Observe('read ok', Format(Ok));
        Observer.Observe('read value', Format(Got));
        Observer.ObserveError('read after open');
        if Ok and Got then begin
            Observer.Observe('first id', Format(Q.Id));
            Observer.Observe('rest', Drain(Q));
        end;
        Q.Close();
        Observer.Expect('rows', '1,2,3,4,');
        Observer.Expect('setfilter ok', 'Yes');
        Observer.Expect('setfilter after end|text', '');
        Observer.Expect('setfilter after end|code', '');
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('open after setfilter|text', '');
        Observer.Expect('open after setfilter|code', '');
        Observer.Expect('read ok', 'Yes');
        Observer.Expect('read value', 'Yes');
        Observer.Expect('read after open|text', '');
        Observer.Expect('read after open|code', '');
        Observer.Expect('first id', '3');
        Observer.Expect('rest', '4,');
        Observer.Verify();
    end;

    [Test]
    procedure Open_Twice_AfterLastRow()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QryEnd Rows";
        Ok: Boolean;
    begin
        Seed();
        Q.Open();
        Observer.Observe('rows', Drain(Q));
        Ok := TryOpen(Q);
        Observer.Observe('second open ok', Format(Ok));
        Observer.ObserveError('second open');
        Observer.Observe('rows after second open', Drain(Q));
        Ok := TryOpen(Q);
        Observer.Observe('third open ok', Format(Ok));
        Observer.ObserveError('third open');
        Observer.Observe('rows after third open', Drain(Q));
        Q.Close();
        Observer.Expect('rows', '1,2,3,4,');
        Observer.Expect('second open ok', 'Yes');
        Observer.Expect('second open|text', '');
        Observer.Expect('second open|code', '');
        Observer.Expect('rows after second open', '1,2,3,4,');
        Observer.Expect('third open ok', 'Yes');
        Observer.Expect('third open|text', '');
        Observer.Expect('third open|code', '');
        Observer.Expect('rows after third open', '1,2,3,4,');
        Observer.Verify();
    end;

    [Test]
    procedure Open_Twice_BeforeAnyRead()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QryEnd Rows";
        Ok: Boolean;
    begin
        Seed();
        Q.Open();
        Ok := TryOpen(Q);
        Observer.Observe('second open ok', Format(Ok));
        Observer.ObserveError('second open before read');
        Observer.Observe('rows', Drain(Q));
        Q.Close();
        Observer.Expect('second open ok', 'Yes');
        Observer.Expect('second open before read|text', '');
        Observer.Expect('second open before read|code', '');
        Observer.Expect('rows', '1,2,3,4,');
        Observer.Verify();
    end;

    [Test]
    procedure Close_AfterLastRow_ThenOpen()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QryEnd Rows";
    begin
        Seed();
        Q.Open();
        Observer.Observe('rows', Drain(Q));
        Q.Close();
        Q.Close();
        Observer.Observe('closed twice', 'ok');
        Q.Open();
        Observer.Observe('rows after reopen', Drain(Q));
        Q.Close();
        Observer.Expect('rows', '1,2,3,4,');
        Observer.Expect('closed twice', 'ok');
        Observer.Expect('rows after reopen', '1,2,3,4,');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_AfterPartialRead_NoClose()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QryEnd Rows";
        Ok: Boolean;
    begin
        Seed();
        Q.Open();
        Observer.Observe('read 1', Format(Q.Read()));
        Observer.Observe('id 1', Format(Q.Id));
        Ok := TryRange(Q, 3, 4);
        Observer.Observe('setrange ok', Format(Ok));
        Observer.ObserveError('setrange after partial read');
        Q.Close();
        Observer.Expect('read 1', 'Yes');
        Observer.Expect('id 1', '1');
        Observer.Expect('setrange ok', 'Yes');
        Observer.Expect('setrange after partial read|text', '');
        Observer.Expect('setrange after partial read|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_AfterPartialRead_ThenReopen()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QryEnd Rows";
        Ok: Boolean;
    begin
        Seed();
        Q.Open();
        Observer.Observe('read 1', Format(Q.Read()));
        Ok := TryRange(Q, 3, 4);
        Observer.Observe('setrange ok', Format(Ok));
        Q.Close();
        Q.Open();
        Observer.Observe('rows after close and open', Drain(Q));
        Q.Close();
        Observer.Expect('read 1', 'Yes');
        Observer.Expect('setrange ok', 'Yes');
        Observer.Expect('rows after close and open', '3,4,');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_AfterClose()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QryEnd Rows";
        Ok: Boolean;
    begin
        Seed();
        Q.Open();
        Observer.Observe('read 1', Format(Q.Read()));
        Q.Close();
        Ok := TryRange(Q, 3, 4);
        Observer.Observe('setrange after close ok', Format(Ok));
        Observer.ObserveError('setrange after close');
        Q.Open();
        Observer.Observe('rows', Drain(Q));
        Q.Close();
        Observer.Expect('read 1', 'Yes');
        Observer.Expect('setrange after close ok', 'Yes');
        Observer.Expect('setrange after close|text', '');
        Observer.Expect('setrange after close|code', '');
        Observer.Expect('rows', '3,4,');
        Observer.Verify();
    end;

    [Test]
    procedure Read_AfterClose_WithoutOpen()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QryEnd Rows";
        Ok: Boolean;
        Got: Boolean;
    begin
        Seed();
        Q.Open();
        Observer.Observe('rows', Drain(Q));
        Q.Close();
        Ok := TryRead(Q, Got);
        Observer.Observe('read after close ok', Format(Ok));
        Observer.Observe('read after close value', Format(Got));
        Observer.ObserveError('read after close');
        Observer.Expect('rows', '1,2,3,4,');
        Observer.Expect('read after close ok', 'Yes');
        Observer.Expect('read after close value', 'No');
        Observer.Expect('read after close|text', '');
        Observer.Expect('read after close|code', '');
        Observer.Verify();
    end;
}
