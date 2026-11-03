// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-setrange-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74993, query 74994
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Query SetRange and SetFilter after Open and Read without Close (error text and code if any, rows read afterwards), after Close, between Open and the first Read, and with SetFilter on an aggregated column after a read
// BC versions: 29 (27 and 28 by CI)

table 74993 "LT P146 Q Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 74994 "LT P146 Q Rows"
{
    QueryType = Normal;

    elements
    {
        dataitem(Rows; "LT P146 Q Row")
        {
            column(Id; Id) { }
            column(Grp; Grp) { }
            column(Amount; Amount) { }
        }
    }
}

query 74995 "LT P146 Q Agg"
{
    QueryType = Normal;

    elements
    {
        dataitem(Rows; "LT P146 Q Row")
        {
            column(Grp; Grp) { }
            column(Total; Amount)
            {
                Method = Sum;
            }
        }
    }
}

codeunit 74996 "LT P146 Query Filter Read"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P146 Q Row";
    begin
        R.DeleteAll();
        Add(1, 'A', 10);
        Add(2, 'A', 20);
        Add(3, 'B', 30);
        Add(4, 'B', 40);
        Add(5, 'C', 50);
    end;

    local procedure Add(NewId: Integer; NewGrp: Code[10]; NewAmount: Decimal)
    var
        R: Record "LT P146 Q Row";
    begin
        R.Id := NewId;
        R.Grp := NewGrp;
        R.Amount := NewAmount;
        R.Insert();
    end;

    local procedure Drain(var Q: Query "LT P146 Q Rows"): Text
    var
        Result: Text;
    begin
        while Q.Read() do
            Result += Format(Q.Id) + ',';
        exit(Result);
    end;

    [TryFunction]
    local procedure TryRange(var Q: Query "LT P146 Q Rows"; FromValue: Integer; ToValue: Integer)
    begin
        Q.SetRange(Id, FromValue, ToValue);
    end;

    [TryFunction]
    local procedure TryFilter(var Q: Query "LT P146 Q Rows"; FilterText: Text)
    begin
        Q.SetFilter(Id, FilterText);
    end;

    [TryFunction]
    local procedure TryClearRange(var Q: Query "LT P146 Q Rows")
    begin
        Q.SetRange(Id);
    end;

    [TryFunction]
    local procedure TryAggFilter(var Q: Query "LT P146 Q Agg"; FilterText: Text)
    begin
        Q.SetFilter(Total, FilterText);
    end;

    [Test]
    procedure P146_SetFilter_AfterRead_NoClose()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P146 Q Rows";
        Ok: Boolean;
    begin
        Seed();
        Q.Open();
        Observer.Observe('read 1', Format(Q.Read()));
        Ok := TryFilter(Q, '>=4');
        Observer.Observe('setfilter ok', Format(Ok));
        Observer.ObserveError('setfilter after read');
        asserterror Observer.Observe('rest', Drain(Q));
        Observer.ObserveError('af155');
        Q.Close();
        Observer.Expect('read 1', 'Yes');
        Observer.Expect('setfilter ok', 'Yes');
        Observer.Expect('setfilter after read|text', '');
        Observer.Expect('setfilter after read|code', '');
        Observer.Expect('af155|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af155|code', 'Query');
        Observer.Verify();
    end;

    [Test]
    procedure P146_SetRange_AfterClose_ThenOpen()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P146 Q Rows";
        Ok: Boolean;
    begin
        Seed();
        Q.Open();
        Observer.Observe('read 1', Format(Q.Read()));
        Q.Close();
        Ok := TryRange(Q, 4, 5);
        Observer.Observe('setrange after close ok', Format(Ok));
        Observer.ObserveError('setrange after close');
        Q.Open();
        Observer.Observe('rows after reopen', Drain(Q));
        Q.Close();
        Ok := TryClearRange(Q);
        Observer.Observe('clear range ok', Format(Ok));
        Q.Open();
        Observer.Observe('rows after cleared range', Drain(Q));
        Q.Close();
        Observer.Expect('read 1', 'Yes');
        Observer.Expect('setrange after close ok', 'Yes');
        Observer.Expect('setrange after close|text', '');
        Observer.Expect('setrange after close|code', '');
        Observer.Expect('rows after reopen', '4,5,');
        Observer.Expect('clear range ok', 'Yes');
        Observer.Expect('rows after cleared range', '1,2,3,4,5,');
        Observer.Verify();
    end;

    [Test]
    procedure P146_SetRange_BetweenOpenAndFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P146 Q Rows";
        Ok: Boolean;
    begin
        Seed();
        Q.Open();
        Ok := TryRange(Q, 2, 3);
        Observer.Observe('setrange after open ok', Format(Ok));
        Observer.ObserveError('setrange after open');
        asserterror Observer.Observe('rows', Drain(Q));
        Observer.ObserveError('af198');
        Q.Close();
        Observer.Expect('setrange after open ok', 'Yes');
        Observer.Expect('setrange after open|text', '');
        Observer.Expect('setrange after open|code', '');
        Observer.Expect('af198|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af198|code', 'Query');
        Observer.Verify();
    end;
}
