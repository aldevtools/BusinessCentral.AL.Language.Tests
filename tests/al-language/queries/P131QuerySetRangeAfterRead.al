// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-setrange-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73659, query 73656, codeunit 73658
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Query.SetRange / SetFilter after Open and after Read (error or ignored, rows read afterwards), after the last Read, after Close, and
//        a second Open after a SetRange made between reads.
// BC versions: 29 (27 and 28 by CI)

table 73659 "LT P131 QSimple"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Code[10]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 73656 "LT P131 Q Simple"
{
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Rows; "LT P131 QSimple")
        {
            column(Id; Id) { }
            column(Nm; Name) { }
        }
    }
}

codeunit 73658 "LT P131 Query SetRange"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P131 QSimple";
        I: Integer;
    begin
        R.DeleteAll();
        for I := 1 to 5 do begin
            R.Id := I;
            R.Name := 'N' + Format(I);
            R.Insert();
        end;
    end;

    [TryFunction]
    local procedure TrySetRange(var Q: Query "LT P131 Q Simple"; Lo: Integer; Hi: Integer)
    begin
        Q.SetRange(Id, Lo, Hi);
    end;

    [TryFunction]
    local procedure TrySetFilter(var Q: Query "LT P131 Q Simple"; Expr: Text)
    begin
        Q.SetFilter(Id, Expr);
    end;

    local procedure SetRangeOutcome(var Q: Query "LT P131 Q Simple"; Lo: Integer; Hi: Integer): Text
    begin
        ClearLastError();
        if TrySetRange(Q, Lo, Hi) then
            exit('no error');
        exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure SetFilterOutcome(var Q: Query "LT P131 Q Simple"; Expr: Text): Text
    begin
        ClearLastError();
        if TrySetFilter(Q, Expr) then
            exit('no error');
        exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReadRest(var Q: Query "LT P131 Q Simple"): Text
    var
        Result: Text;
    begin
        while Q.Read() do
            Result += Format(Q.Id) + ',';
        exit(Result);
    end;

    [Test]
    procedure P131_Query_SetRangeAfterFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Simple";
    begin
        Seed();
        Q.Open();
        Observer.Observe('first read', Format(Q.Read()) + '|' + Format(Q.Id));
        Observer.Observe('set range 4..5', SetRangeOutcome(Q, 4, 5));
        Observer.Observe('filters', Q.GetFilters());
        asserterror Observer.Observe('rest', ReadRest(Q));
        Observer.ObserveError('af102');
        Q.Close();
        Q.Open();
        Observer.Observe('reopen', ReadRest(Q));
        Q.Close();
        Observer.Expect('first read', 'Yes|1');
        Observer.Expect('set range 4..5', 'no error');
        Observer.Expect('filters', 'Id: 4..5');
        Observer.Expect('af102|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af102|code', 'Query');
        Observer.Expect('reopen', '');
        Observer.Verify();
    end;

    [Test]
    procedure P131_Query_SetFilterAfterRead_ThenReopen()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Simple";
    begin
        Seed();
        Q.Open();
        Observer.Observe('first read', Format(Q.Read()) + '|' + Format(Q.Id));
        Observer.Observe('second read', Format(Q.Read()) + '|' + Format(Q.Id));
        Observer.Observe('set filter', SetFilterOutcome(Q, '>=4'));
        Observer.Observe('filters', Q.GetFilters());
        asserterror Observer.Observe('third read', Format(Q.Read()) + '|' + Format(Q.Id));
        Observer.ObserveError('af123');
        Q.Close();
        Observer.Observe('filters after close', Q.GetFilters());
        Q.Open();
        Observer.Observe('reopen', ReadRest(Q));
        Q.Close();
        Observer.Expect('first read', 'Yes|1');
        Observer.Expect('second read', 'Yes|2');
        Observer.Expect('set filter', 'no error');
        Observer.Expect('filters', 'Id: >=4');
        Observer.Expect('af123|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af123|code', 'Query');
        Observer.Expect('filters after close', 'Id: >=4');
        Observer.Expect('reopen', '');
        Observer.Verify();
    end;

    [Test]
    procedure P131_Query_SetRangeAfterLastRead_AndAfterClose()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Simple";
    begin
        Seed();
        Q.Open();
        Observer.Observe('all', ReadRest(Q));
        Observer.Observe('read after end', Format(Q.Read()));
        Observer.Observe('set range after end', SetRangeOutcome(Q, 2, 3));
        asserterror Observer.Observe('read after set', Format(Q.Read()));
        Observer.ObserveError('af144');
        Q.Close();
        Observer.Observe('set range after close', SetRangeOutcome(Q, 2, 3));
        Q.Open();
        Observer.Observe('reopen', ReadRest(Q));
        Q.Close();
        Observer.Observe('read after close', Format(Q.Read()));
        Observer.Expect('all', '1,2,3,4,5,');
        Observer.Expect('read after end', 'No');
        Observer.Expect('set range after end', 'no error');
        Observer.Expect('af144|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af144|code', 'Query');
        Observer.Expect('set range after close', 'no error');
        Observer.Expect('reopen', '');
        Observer.Expect('read after close', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P131_Query_SetRangeBetweenOpenAndRead_Control()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Simple";
    begin
        Seed();
        Q.Open();
        Observer.Observe('set range before first read', SetRangeOutcome(Q, 2, 3));
        asserterror Observer.Observe('rows', ReadRest(Q));
        Observer.ObserveError('af164');
        Q.Close();
        Observer.Observe('second set range', SetRangeOutcome(Q, 4, 4));
        Q.Open();
        Observer.Observe('rows after reopen', ReadRest(Q));
        Q.Close();
        Observer.Expect('set range before first read', 'no error');
        Observer.Expect('af164|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af164|code', 'Query');
        Observer.Expect('second set range', 'no error');
        Observer.Expect('rows after reopen', '');
        Observer.Verify();
    end;

    [Test]
    procedure P131_Query_SetRangeOnTheSameColumnTwiceAfterRead()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P131 Q Simple";
    begin
        Seed();
        Q.SetRange(Id, 1, 3);
        Q.Open();
        Observer.Observe('first read', Format(Q.Read()) + '|' + Format(Q.Id));
        Observer.Observe('widen', SetRangeOutcome(Q, 1, 5));
        asserterror Observer.Observe('rest', ReadRest(Q));
        Observer.ObserveError('af185');
        Q.Close();
        Observer.Observe('filters', Q.GetFilters());
        Q.Open();
        Observer.Observe('reopen', ReadRest(Q));
        Q.Close();
        Observer.Expect('first read', 'Yes|1');
        Observer.Expect('widen', 'no error');
        Observer.Expect('af185|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af185|code', 'Query');
        Observer.Expect('filters', 'Id: 1..5');
        Observer.Expect('reopen', '');
        Observer.Verify();
    end;
}
