// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-setrange-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT F3 Row (67075) and Log Mgt (67077)
// Probe: Query.SetRange / SetFilter after Open and after the first Read, after Close, and a second Open: does the filter change the rows still to read, is it an error, what does the query return afterwards.
// Object ids 67124 - 67125.

query 67124 "LT F3 Row Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT F3 Row")
        {
            column(No; "No.") { }
            column(Qty; Qty) { }
        }
    }
}

codeunit 67125 "LT F3 Query Range"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetRange(var Q: Query "LT F3 Row Query"; Low: Integer; High: Integer)
    begin
        Q.SetRange(Qty, Low, High);
    end;

    [TryFunction]
    local procedure TryDrain(var Q: Query "LT F3 Row Query"; var Result: Text)
    begin
        while Q.Read() do
            Result += Q.No + ',';
    end;

    local procedure Drain(var Q: Query "LT F3 Row Query"): Text
    var
        Result: Text;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryDrain(Q, Result);
        if Ok then
            exit(Result);
        exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode() + ' | read so far: ' + Result);
    end;

    [Test]
    procedure SetRange_AfterFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Q: Query "LT F3 Row Query";
        Ok: Boolean;
    begin
        Log.Seed(6);
        Q.Open();
        Observer.Observe('first_read', Format(Q.Read()));
        Observer.Observe('first_no', Q.No);
        ClearLastError();
        Ok := TrySetRange(Q, 4, 5);
        Observer.Observe('set_ok', Format(Ok));
        if not Ok then begin
            Observer.Observe('set_error', GetLastErrorText());
            Observer.Observe('set_code', GetLastErrorCode());
        end;
        Observer.Observe('rest', Drain(Q));
        Q.Close();
        Observer.Expect('first_read', 'Yes');
        Observer.Expect('first_no', 'R1001');
        Observer.Expect('set_ok', 'Yes');
        Observer.Expect('rest', 'error: The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function. | Query | read so far: ');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_AfterClose_ThenReopen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Q: Query "LT F3 Row Query";
        Ok: Boolean;
    begin
        Log.Seed(6);
        Q.Open();
        Observer.Observe('first_read', Format(Q.Read()));
        Q.Close();
        ClearLastError();
        Ok := TrySetRange(Q, 4, 5);
        Observer.Observe('set_ok', Format(Ok));
        if not Ok then begin
            Observer.Observe('set_error', GetLastErrorText());
            Observer.Observe('set_code', GetLastErrorCode());
        end;
        Q.Open();
        Observer.Observe('rows', Drain(Q));
        Q.Close();
        Observer.Expect('first_read', 'Yes');
        Observer.Expect('set_ok', 'Yes');
        Observer.Expect('rows', 'R1004,R1005,');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_AfterReadThenReopen_KeepsRange()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Q: Query "LT F3 Row Query";
    begin
        Log.Seed(6);
        Q.SetRange(Qty, 2, 3);
        Q.Open();
        Observer.Observe('first_pass', Drain(Q));
        Q.Close();
        Q.Open();
        Observer.Observe('second_pass', Drain(Q));
        Q.Close();
        Observer.Expect('first_pass', 'R1002,R1003,');
        Observer.Expect('second_pass', 'R1002,R1003,');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_BeforeOpen_Baseline()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Q: Query "LT F3 Row Query";
    begin
        Log.Seed(6);
        Q.SetRange(Qty, 4, 5);
        Q.Open();
        Observer.Observe('rows', Drain(Q));
        Q.Close();
        Observer.Expect('rows', 'R1004,R1005,');
        Observer.Verify();
    end;
}
