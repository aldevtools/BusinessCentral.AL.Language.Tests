// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects of PnAQueryObjects.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Query: Open does not run the query: the first Read does, with the filters set at that time; SetRange and Open after a Read
// Facts: when a Query takes its filters: SetRange between Open and the first Read, SetRange and Open after a Read, Close then SetRange then Open
// BC versions: 29 (27 and 28 by CI)

codeunit 70128 "LT PnA Q OpenRead"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Q: Query "LT PnA Q Plain";

    local procedure Seed()
    var
        S: Record "LT PnA Q Src";
        i: Integer;
    begin
        S.DeleteAll();
        for i := 1 to 5 do begin
            S.Entry := i;
            S.Grp := 'G';
            S.Name := 'n' + Format(i);
            S.Qty := i;
            S.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryOp(Op: Integer; Arg: Integer)
    begin
        case Op of
            1:
                Q.SetRange(Entry, Arg);
            2:
                Q.Open();
            3:
                Q.Close();
            4:
                Q.SetRange(Qty, Arg);
            5:
                Q.SetFilter(Entry, '>%1', Arg);
        end;
    end;

    local procedure Op(var Observer: Codeunit "Probe Observer"; Name: Text; OpNo: Integer; Arg: Integer)
    begin
        Observer.Observe(Name, Format(TryOp(OpNo, Arg)));
        Observer.ObserveError(Name);
    end;

    local procedure ReadAll(): Text
    var
        R: Text;
    begin
        while Q.Read() do
            R += Format(Q.Entry) + ',';
        exit(R);
    end;

    [Test]
    procedure SetRangeBetweenOpenAndFirstRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Op(Observer, 'open', 2, 0);
        Op(Observer, 'setrange-after-open', 1, 3);
        asserterror Observer.Observe('rows', ReadAll());
        Observer.ObserveError('af73');
        Op(Observer, 'close', 3, 0);
        Observer.Expect('open', 'Yes');
        Observer.Expect('open|text', '');
        Observer.Expect('open|code', '');
        Observer.Expect('setrange-after-open', 'Yes');
        Observer.Expect('setrange-after-open|text', '');
        Observer.Expect('setrange-after-open|code', '');
        Observer.Expect('af73|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af73|code', 'Query');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetRangeBeforeOpen_ThenChangedBeforeFirstRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Op(Observer, 'setrange-before', 1, 2);
        Op(Observer, 'open', 2, 0);
        Op(Observer, 'setrange-after-open', 1, 4);
        asserterror Observer.Observe('rows', ReadAll());
        Observer.ObserveError('af89');
        asserterror Observer.Observe('read-after-end', Format(Q.Read()));
        Observer.ObserveError('af91');
        Op(Observer, 'close', 3, 0);
        Observer.Expect('setrange-before', 'Yes');
        Observer.Expect('setrange-before|text', '');
        Observer.Expect('setrange-before|code', '');
        Observer.Expect('open', 'Yes');
        Observer.Expect('open|text', '');
        Observer.Expect('open|code', '');
        Observer.Expect('setrange-after-open', 'Yes');
        Observer.Expect('setrange-after-open|text', '');
        Observer.Expect('setrange-after-open|code', '');
        Observer.Expect('af89|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af89|code', 'Query');
        Observer.Expect('af91|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af91|code', 'Query');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetRangeAndOpenAfterRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Op(Observer, 'open', 2, 0);
        Observer.Observe('first-read', Format(Q.Read()));
        Observer.Observe('first-entry', Format(Q.Entry));
        Op(Observer, 'setrange-after-read', 1, 4);
        Op(Observer, 'setrange-other-field-after-read', 4, 4);
        Op(Observer, 'setfilter-after-read', 5, 3);
        Op(Observer, 'open-after-read', 2, 0);
        Observer.Observe('next-read', Format(Q.Read()));
        Observer.Observe('next-entry', Format(Q.Entry));
        Op(Observer, 'close', 3, 0);
        Observer.Expect('open', 'Yes');
        Observer.Expect('open|text', '');
        Observer.Expect('open|code', '');
        Observer.Expect('first-read', 'Yes');
        Observer.Expect('first-entry', '1');
        Observer.Expect('setrange-after-read', 'Yes');
        Observer.Expect('setrange-after-read|text', '');
        Observer.Expect('setrange-after-read|code', '');
        Observer.Expect('setrange-other-field-after-read', 'Yes');
        Observer.Expect('setrange-other-field-after-read|text', '');
        Observer.Expect('setrange-other-field-after-read|code', '');
        Observer.Expect('setfilter-after-read', 'Yes');
        Observer.Expect('setfilter-after-read|text', '');
        Observer.Expect('setfilter-after-read|code', '');
        Observer.Expect('open-after-read', 'Yes');
        Observer.Expect('open-after-read|text', '');
        Observer.Expect('open-after-read|code', '');
        Observer.Expect('next-read', 'Yes');
        Observer.Expect('next-entry', '4');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure CloseSetRangeReopen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Op(Observer, 'open', 2, 0);
        Observer.Observe('first-read', Format(Q.Read()));
        Op(Observer, 'close', 3, 0);
        Op(Observer, 'setrange-after-close', 1, 4);
        Op(Observer, 'open-again', 2, 0);
        Observer.Observe('rows', ReadAll());
        Op(Observer, 'close-again', 3, 0);
        Op(Observer, 'close-twice', 3, 0);
        Observer.Observe('read-closed', Format(Q.Read()));
        Op(Observer, 'open-third', 2, 0);
        Observer.Observe('rows-third', ReadAll());
        Op(Observer, 'open-while-open', 2, 0);
        Observer.Expect('open', 'Yes');
        Observer.Expect('open|text', '');
        Observer.Expect('open|code', '');
        Observer.Expect('first-read', 'Yes');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('setrange-after-close', 'Yes');
        Observer.Expect('setrange-after-close|text', '');
        Observer.Expect('setrange-after-close|code', '');
        Observer.Expect('open-again', 'Yes');
        Observer.Expect('open-again|text', '');
        Observer.Expect('open-again|code', '');
        Observer.Expect('rows', '4,');
        Observer.Expect('close-again', 'Yes');
        Observer.Expect('close-again|text', '');
        Observer.Expect('close-again|code', '');
        Observer.Expect('close-twice', 'Yes');
        Observer.Expect('close-twice|text', '');
        Observer.Expect('close-twice|code', '');
        Observer.Expect('read-closed', 'No');
        Observer.Expect('open-third', 'Yes');
        Observer.Expect('open-third|text', '');
        Observer.Expect('open-third|code', '');
        Observer.Expect('rows-third', '4,');
        Observer.Expect('open-while-open', 'Yes');
        Observer.Expect('open-while-open|text', '');
        Observer.Expect('open-while-open|code', '');
        Observer.Verify();
    end;

    // Writer PX (probes-needed "Query": TopNumberOfRows and SecurityFiltering after Open are not pinned): each call between Open and the first
    // Read, after a Read, and before Open, then the rows read (5 rows of Seed, Entry 1..5).
    // Rule seen: TopNumberOfRows after Open (before or after a Read) is accepted, and the next Read raises the metadata-changed error until Open
    // again; SecurityFiltering after Open or after a Read raises nothing and the reading goes on (it does not need a new Open).
    [TryFunction]
    local procedure PxTryTop(N: Integer)
    begin
        Q.TopNumberOfRows(N);
    end;

    [TryFunction]
    local procedure PxTrySecurity()
    begin
        Q.SecurityFiltering(SecurityFilter::Filtered);
    end;

    [TryFunction]
    local procedure PxTryReadAll(var Rows: Text)
    begin
        Rows := ReadAll();
    end;

    local procedure PxRead(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Rows: Text;
    begin
        Observer.Observe(Name, Format(PxTryReadAll(Rows)) + ' ' + Rows);
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure PX_TopNumberOfRows_AroundOpen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Q.Open();
        Observer.Observe('top-after-open', Format(PxTryTop(2)));
        Observer.ObserveError('top-after-open');
        PxRead(Observer, 'read-after-top');
        Q.Close();
        Clear(Q);
        Q.TopNumberOfRows(2);
        Q.Open();
        PxRead(Observer, 'top-before-open');
        Clear(Q);
        Q.Open();
        Observer.Observe('first-read', Format(Q.Read()));
        Observer.Observe('top-after-read', Format(PxTryTop(1)));
        Observer.ObserveError('top-after-read');
        PxRead(Observer, 'read-after-top-after-read');
        Q.Open();
        PxRead(Observer, 'reopen-after-top');
        Observer.Expect('top-after-open', 'Yes');
        Observer.Expect('top-after-open|text', '');
        Observer.Expect('top-after-open|code', '');
        Observer.Expect('read-after-top', 'No ');
        Observer.Expect('read-after-top|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('read-after-top|code', 'Query');
        Observer.Expect('top-before-open', 'Yes 1,2,');
        Observer.Expect('top-before-open|text', '');
        Observer.Expect('top-before-open|code', '');
        Observer.Expect('first-read', 'Yes');
        Observer.Expect('top-after-read', 'Yes');
        Observer.Expect('top-after-read|text', '');
        Observer.Expect('top-after-read|code', '');
        Observer.Expect('read-after-top-after-read', 'No ');
        Observer.Expect('read-after-top-after-read|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('read-after-top-after-read|code', 'Query');
        Observer.Expect('reopen-after-top', 'Yes 1,');
        Observer.Expect('reopen-after-top|text', '');
        Observer.Expect('reopen-after-top|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure PX_SecurityFiltering_AroundOpen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Q.Open();
        Observer.Observe('security-after-open', Format(PxTrySecurity()));
        Observer.ObserveError('security-after-open');
        PxRead(Observer, 'read-after-security');
        Q.Close();
        Clear(Q);
        Q.Open();
        Observer.Observe('first-read', Format(Q.Read()));
        Observer.Observe('security-after-read', Format(PxTrySecurity()));
        Observer.ObserveError('security-after-read');
        PxRead(Observer, 'read-after-security-after-read');
        Q.Open();
        PxRead(Observer, 'reopen-after-security');
        Observer.Observe('security-value', Format(Q.SecurityFiltering()));
        Observer.Expect('security-after-open', 'Yes');
        Observer.Expect('security-after-open|text', '');
        Observer.Expect('security-after-open|code', '');
        Observer.Expect('read-after-security', 'Yes 1,2,3,4,5,');
        Observer.Expect('read-after-security|text', '');
        Observer.Expect('read-after-security|code', '');
        Observer.Expect('first-read', 'Yes');
        Observer.Expect('security-after-read', 'Yes');
        Observer.Expect('security-after-read|text', '');
        Observer.Expect('security-after-read|code', '');
        Observer.Expect('read-after-security-after-read', 'Yes 2,3,4,5,');
        Observer.Expect('read-after-security-after-read|text', '');
        Observer.Expect('read-after-security-after-read|code', '');
        Observer.Expect('reopen-after-security', 'Yes 1,2,3,4,5,');
        Observer.Expect('reopen-after-security|text', '');
        Observer.Expect('reopen-after-security|code', '');
        Observer.Expect('security-value', 'Filtered');
        Observer.Verify();
    end;

    // Writer TH, al-runner issue 6039 (follow-up to PX_TopNumberOfRows_AroundOpen): TopNumberOfRows called on a query that is still open
    // after a Read that ended the reading (an empty result, or the end of the rows), then Open again without Close. Base App table 7346
    // "Internal Movement Header" does this twice on one query variable. The new top applies to the next Open, nothing is raised by the call.
    [Test]
    procedure TH_TopAfterEmptyOpen_ThenReopen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Q.SetRange(Grp, 'X');
        Q.TopNumberOfRows(1);
        Observer.Observe('open-empty', Format(Q.Open()));
        Observer.Observe('read-empty', Format(Q.Read()));
        Q.SetRange(Grp);
        Observer.Observe('top-while-open', Format(PxTryTop(1)));
        Observer.ObserveError('top-while-open');
        Observer.Observe('top-getter', Format(Q.TopNumberOfRows()));
        Observer.Observe('reopen', Format(Q.Open()));
        PxRead(Observer, 'rows-after-reopen');
        Observer.Expect('open-empty', 'Yes');
        Observer.Expect('read-empty', 'No');
        Observer.Expect('top-while-open', 'Yes');
        Observer.Expect('top-while-open|text', '');
        Observer.Expect('top-while-open|code', '');
        Observer.Expect('top-getter', '1');
        Observer.Expect('reopen', 'Yes');
        Observer.Expect('rows-after-reopen', 'Yes 1,');
        Observer.Expect('rows-after-reopen|text', '');
        Observer.Expect('rows-after-reopen|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure TH_TopAfterFullRead_ThenReopen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Observer.Observe('open', Format(Q.Open()));
        Observer.Observe('first-pass', ReadAll());
        Observer.Observe('top-while-open', Format(PxTryTop(2)));
        Observer.ObserveError('top-while-open');
        Observer.Observe('top-getter', Format(Q.TopNumberOfRows()));
        Observer.Observe('reopen', Format(Q.Open()));
        PxRead(Observer, 'rows-after-reopen');
        Observer.Observe('top-getter-after', Format(Q.TopNumberOfRows()));
        Observer.Expect('open', 'Yes');
        Observer.Expect('first-pass', '1,2,3,4,5,');
        Observer.Expect('top-while-open', 'Yes');
        Observer.Expect('top-while-open|text', '');
        Observer.Expect('top-while-open|code', '');
        Observer.Expect('top-getter', '2');
        Observer.Expect('reopen', 'Yes');
        Observer.Expect('rows-after-reopen', 'Yes 1,2,');
        Observer.Expect('rows-after-reopen|text', '');
        Observer.Expect('rows-after-reopen|code', '');
        Observer.Expect('top-getter-after', '2');
        Observer.Verify();
    end;

    // The query is left open by a Read that returned false and the new top is lowered then raised again: only the last value before the
    // next Open counts, and a Read between the TopNumberOfRows call and the Open raises the metadata-changed error.
    [Test]
    procedure TH_TopTwiceWhileOpen_LastValueCounts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Q.Open();
        Observer.Observe('first-pass', ReadAll());
        Q.TopNumberOfRows(1);
        Q.TopNumberOfRows(3);
        PxRead(Observer, 'read-before-reopen');
        Observer.Observe('reopen', Format(Q.Open()));
        PxRead(Observer, 'rows-after-reopen');
        Observer.Expect('first-pass', '1,2,3,4,5,');
        Observer.Expect('read-before-reopen', 'No ');
        Observer.Expect('read-before-reopen|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('read-before-reopen|code', 'Query');
        Observer.Expect('reopen', 'Yes');
        Observer.Expect('rows-after-reopen', 'Yes 1,2,3,');
        Observer.Expect('rows-after-reopen|text', '');
        Observer.Expect('rows-after-reopen|code', '');
        Observer.Verify();
    end;
}
