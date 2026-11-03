// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects in Y37LinkFilterObjects.al (92600-92611)
// Probe: gap cycle 3 spec C3-11 (writer Y37). Every literal asserted below is what the BC service tier produced.
// Facts: a SubPageLink or RunPageLink `<target> = field(filter(<host field>))` reads the host field's VALUE as a filter expression on the
//   target field: which rows the part shows for a single value, a `|` list, a range, a wildcard and a blank value; the filter on a FlowFilter
//   target (and the FlowField it drives); a Provider part whose RecordId target gets the formatted RecordId of the provider's row; the same
//   in a RunPageLink; a host field that is a FlowFilter field; a host value changed while the page is open. The part logs (OnOpenPage) the
//   filters of filter group 0 and 4 and GetFilter of the target fields.
//   BC (27.5, 28.5 Windows, SaaS 29 alike): the host value is applied as SetFilter on the target in filter group 4 (A1|A3 -> A1,A3; A1..A3 and
//   A* -> A1,A2,A3; <>A2 -> all but A2); a blank host value sets no filter at all (every row); a value longer than the Code[20] target raises
//   no error and the part shows no row. The link filter is not set yet in the part's OnOpenPage, it is at OnAfterGetCurrRecord. A FlowFilter
//   target gets the filter (FlowField sums D1 = 15.00, D1|D2 = 22.00). A Provider part with a RecordId target filters on the formatted
//   RecordId text ('LT Y37 LF Line: A1') and follows the provider's row; a blank value there shows every row. RunPageLink sets the same
//   filter in filter group 0 of the opened page. A host FlowFilter field links its filter text (TestPage.Filter or Page.Run with a filtered
//   record); a SetValue of the host field re-links the part at once.
// BC versions: 27, 28, 29

codeunit 92612 "LT Y37 LF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y37 LF Log";

    local procedure Seed(LineFilter: Text[250]; DeptFilterText: Text[250])
    var
        Line: Record "LT Y37 LF Line";
        Entry: Record "LT Y37 LF Entry";
        Host: Record "LT Y37 LF Host";
        Err: Record "LT Y37 LF Err";
    begin
        Line.DeleteAll();
        Entry.DeleteAll();
        Host.DeleteAll();
        Err.DeleteAll();
        AddLine('A1', 'D1', 1);
        AddLine('A2', 'D1', 2);
        AddLine('A3', 'D1', 3);
        AddLine('B1', 'D2', 4);
        AddLine('B2', 'D2', 5);
        AddEntry(1, 'D1', 10);
        AddEntry(2, 'D1', 5);
        AddEntry(3, 'D2', 7);
        Host.Init();
        Host."No." := 'H1';
        Host."Line Filter" := LineFilter;
        Host."Dept Filter Text" := DeptFilterText;
        Host.Insert();
        // One error row per line, and one for a row of another table.
        Line.FindSet();
        repeat
            Err.Init();
            Err."Entry No." += 1;
            Err."Record ID" := Line.RecordId;
            Err.Note := 'n-' + Line."No.";
            Err.Insert();
        until Line.Next() = 0;
        Err.Init();
        Err."Entry No." += 1;
        Err."Record ID" := Host.RecordId;
        Err.Note := 'n-H1';
        Err.Insert();
        Log.Take();
    end;

    local procedure AddLine(No: Code[20]; Dept: Code[10]; Amount: Decimal)
    var
        Line: Record "LT Y37 LF Line";
    begin
        Line.Init();
        Line."No." := No;
        Line.Dept := Dept;
        Line.Amount := Amount;
        Line.Insert();
    end;

    local procedure AddEntry(No: Integer; Dept: Code[10]; Amount: Decimal)
    var
        Entry: Record "LT Y37 LF Entry";
    begin
        Entry.Init();
        Entry."Entry No." := No;
        Entry.Dept := Dept;
        Entry.Amount := Amount;
        Entry.Insert();
    end;

    // Every line gets "Rec Id Filter" := Format(RecordId), except the line named Blank.
    local procedure FillRecIdFilters(Blank: Code[20])
    var
        Line: Record "LT Y37 LF Line";
    begin
        Line.FindSet();
        repeat
            if Line."No." = Blank then
                Line."Rec Id Filter" := ''
            else
                Line."Rec Id Filter" := Format(Line.RecordId);
            Line.Modify();
        until Line.Next() = 0;
    end;

    local procedure CardRows(var P: TestPage "LT Y37 LF Card"): Text
    var
        R: Text;
        i: Integer;
    begin
        if not P.LinesPart.First() then
            exit('<none>');
        repeat
            R += P.LinesPart.NoCtl.Value() + ',';
            i += 1;
        until (not P.LinesPart.Next()) or (i >= 10);
        exit(R);
    end;

    local procedure DocRows(var P: TestPage "LT Y37 LF Document"): Text
    var
        R: Text;
        i: Integer;
    begin
        if not P.LinesPart.First() then
            exit('<none>');
        repeat
            R += P.LinesPart.NoCtl.Value() + ',';
            i += 1;
        until (not P.LinesPart.Next()) or (i >= 10);
        exit(R);
    end;

    local procedure ErrRows(var P: TestPage "LT Y37 LF Document"): Text
    var
        R: Text;
        i: Integer;
    begin
        if not P.ErrPart.First() then
            exit('<none>');
        repeat
            R += P.ErrPart.EntryCtl.Value() + ',';
            i += 1;
        until (not P.ErrPart.Next()) or (i >= 10);
        exit(R);
    end;

    local procedure FlowRows(var P: TestPage "LT Y37 LF FlowFilter Card"): Text
    var
        R: Text;
        i: Integer;
    begin
        if not P.LinesPart.First() then
            exit('<none>');
        repeat
            R += P.LinesPart.NoCtl.Value() + ',';
            i += 1;
        until (not P.LinesPart.Next()) or (i >= 10);
        exit(R);
    end;

    local procedure ObserveCard(Name: Text; LineFilter: Text[250])
    var
        P: TestPage "LT Y37 LF Card";
    begin
        Seed(LineFilter, '');
        P.OpenEdit();
        P.GoToKey('H1');
        Observer.Observe(Name + ' open log', Log.Take());
        Observer.Observe(Name + ' rows', CardRows(P));
        P.Close();
        Log.Take();
    end;

    [TryFunction]
    local procedure TryOpenCard(var P: TestPage "LT Y37 LF Card")
    begin
        P.OpenEdit();
        P.GoToKey('H1');
    end;

    [Test]
    procedure LT_C311_Link_FilterValue()
    begin
        ObserveCard('A1', 'A1');
        ObserveCard('A1|A3', 'A1|A3');
        ObserveCard('A1..A3', 'A1..A3');
        ObserveCard('A*', 'A*');
        ObserveCard('B2', 'B2');
        ObserveCard('<>A2', '<>A2');
        Observer.Expect('A1 open log', 'LP.open f0=[] f4=[];LP.c A1 f0=[] f4=[No.: A1];LP.c A1 f0=[] f4=[No.: A1];');
        Observer.Expect('A1 rows', 'A1,');
        Observer.Expect('A1|A3 open log', 'LP.open f0=[] f4=[];LP.c A1 f0=[] f4=[No.: A1|A3];LP.c A1 f0=[] f4=[No.: A1|A3];');
        Observer.Expect('A1|A3 rows', 'A1,A3,');
        Observer.Expect('A1..A3 open log', 'LP.open f0=[] f4=[];LP.c A1 f0=[] f4=[No.: A1..A3];LP.c A1 f0=[] f4=[No.: A1..A3];');
        Observer.Expect('A1..A3 rows', 'A1,A2,A3,');
        Observer.Expect('A* open log', 'LP.open f0=[] f4=[];LP.c A1 f0=[] f4=[No.: A*];LP.c A1 f0=[] f4=[No.: A*];');
        Observer.Expect('A* rows', 'A1,A2,A3,');
        Observer.Expect('B2 open log', 'LP.open f0=[] f4=[];LP.c B2 f0=[] f4=[No.: B2];LP.c B2 f0=[] f4=[No.: B2];');
        Observer.Expect('B2 rows', 'B2,');
        Observer.Expect('<>A2 open log', 'LP.open f0=[] f4=[];LP.c A1 f0=[] f4=[No.: <>A2];LP.c A1 f0=[] f4=[No.: <>A2];');
        Observer.Expect('<>A2 rows', 'A1,A3,B1,B2,');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C311_Link_FilterNotParsable()
    var
        P: TestPage "LT Y37 LF Card";
    begin
        // 26 characters: longer than the Code[20] target field.
        Seed('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '');
        if TryOpenCard(P) then begin
            Observer.Observe('open', 'ok');
            Observer.Observe('open log', Log.Take());
            Observer.Observe('rows', CardRows(P));
            P.Close();
        end else
            Observer.ObserveError('open');
        // How often the part's OnOpenPage runs here differs (once on BC 27.5 and 28.5, three times on the SaaS BC 29 sandbox): not asserted.
        Observer.Ignore('open log');
        Observer.Expect('open', 'ok');
        Observer.Expect('rows', '<none>');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C311_Link_FilterBlank()
    var
        P: TestPage "LT Y37 LF Card";
    begin
        Seed('', '');
        P.OpenEdit();
        P.GoToKey('H1');
        Observer.Observe('open log', Log.Take());
        Observer.Observe('rows', CardRows(P));
        P.Close();
        Observer.Expect('open log', 'LP.open f0=[] f4=[];LP.c A1 f0=[] f4=[];LP.c A1 f0=[] f4=[];');
        Observer.Expect('rows', 'A1,A2,A3,B1,B2,');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C311_Link_FlowFilterTarget()
    var
        P: TestPage "LT Y37 LF Card";
    begin
        Seed('', 'D1');
        P.OpenEdit();
        P.GoToKey('H1');
        Observer.Observe('open log', Log.Take());
        P.LinesPart.First();
        Observer.Observe('first row dept amount', P.LinesPart.NoCtl.Value() + '|' + P.LinesPart.DeptAmountCtl.Value());
        Observer.Observe('rows', CardRows(P));
        P.Close();
        Seed('', 'D1|D2');
        P.OpenEdit();
        P.GoToKey('H1');
        Observer.Observe('D1|D2 open log', Log.Take());
        P.LinesPart.First();
        Observer.Observe('D1|D2 first row dept amount', P.LinesPart.NoCtl.Value() + '|' + P.LinesPart.DeptAmountCtl.Value());
        P.Close();
        Observer.Expect('open log', 'LP.open f0=[] f4=[];LP.c A1 f0=[] f4=[Dept Filter: D1];LP.c A1 f0=[] f4=[Dept Filter: D1];');
        Observer.Expect('first row dept amount', 'A1|15.00');
        Observer.Expect('rows', 'A1,A2,A3,B1,B2,');
        Observer.Expect('D1|D2 open log', 'LP.open f0=[] f4=[];LP.c A1 f0=[] f4=[Dept Filter: D1|D2];LP.c A1 f0=[] f4=[Dept Filter: D1|D2];');
        Observer.Expect('D1|D2 first row dept amount', 'A1|22.00');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C311_Provider_RecordIdFilter()
    var
        Line: Record "LT Y37 LF Line";
        Err: Record "LT Y37 LF Err";
        P: TestPage "LT Y37 LF Document";
    begin
        Seed('', '');
        FillRecIdFilters('');
        Line.Get('A1');
        Observer.Observe('A1 rec id filter text', Line."Rec Id Filter");
        P.OpenEdit();
        P.GoToKey('H1');
        Observer.Observe('open log', Log.Take());
        Observer.Observe('line', P.LinesPart.NoCtl.Value());
        Observer.Observe('err rows', ErrRows(P));
        Log.Take();
        Observer.Observe('line next', Format(P.LinesPart.Next()) + '|' + P.LinesPart.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('err rows after next', ErrRows(P));
        Log.Take();
        P.ErrPart.Filter.SetFilter(Note, 'n-A2');
        Observer.Observe('err note after part filter', P.ErrPart.NoteCtl.Value());
        P.ErrPart.Filter.SetFilter(Note, 'n-A3');
        Observer.Observe('err note after other part filter', P.ErrPart.NoteCtl.Value() + '|' + Format(P.ErrPart.First()));
        P.Close();
        // The same filter text set in code on the RecordId field.
        Err.SetFilter("Record ID", Line."Rec Id Filter");
        Observer.Observe('code SetFilter count', Format(Err.Count()));
        Observer.Observe('code GetFilter', Err.GetFilter("Record ID"));
        Observer.Expect('A1 rec id filter text', 'LT Y37 LF Line: A1');
        Observer.Expect('open log', 'LP.open f0=[] f4=[];EP.open f4=[];LP.c A1 f0=[] f4=[];EP.c 1 f4=[LT Y37 LF Line: A1];LP.c A1 f0=[] f4=[];');
        Observer.Expect('line', 'A1');
        Observer.Expect('err rows', '1,');
        Observer.Expect('line next', 'Yes|A2');
        Observer.Expect('next log', 'LP.c A2 f0=[] f4=[];EP.c 2 f4=[LT Y37 LF Line: A2];');
        Observer.Expect('err rows after next', '2,');
        Observer.Expect('err note after part filter', 'n-A2');
        Observer.Expect('err note after other part filter', '|No');
        Observer.Expect('code SetFilter count', '1');
        Observer.Expect('code GetFilter', 'LT Y37 LF Line: A1');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C311_Provider_RecordIdFilter_Blank()
    var
        P: TestPage "LT Y37 LF Document";
    begin
        Seed('', '');
        FillRecIdFilters('A1');
        P.OpenEdit();
        P.GoToKey('H1');
        Observer.Observe('open log', Log.Take());
        Observer.Observe('line', P.LinesPart.NoCtl.Value());
        Observer.Observe('err rows', ErrRows(P));
        Log.Take();
        P.LinesPart.Next();
        Observer.Observe('line next', P.LinesPart.NoCtl.Value());
        Observer.Observe('err rows after next', ErrRows(P));
        P.Close();
        Observer.Expect('open log', 'LP.open f0=[] f4=[];EP.open f4=[];LP.c A1 f0=[] f4=[];EP.c 1 f4=[];LP.c A1 f0=[] f4=[];EP.c 1 f4=[];');
        Observer.Expect('line', 'A1');
        Observer.Expect('err rows', '1,2,3,4,5,6,');
        Observer.Expect('line next', 'A2');
        Observer.Expect('err rows after next', '2,');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C311_Provider_LineFilterOnDocument()
    var
        P: TestPage "LT Y37 LF Document";
    begin
        Seed('A*', '');
        FillRecIdFilters('');
        P.OpenEdit();
        P.GoToKey('H1');
        Observer.Observe('open log', Log.Take());
        Observer.Observe('lines', DocRows(P));
        P.Close();
        Observer.Expect('open log', 'LP.open f0=[] f4=[];EP.open f4=[];LP.c A1 f0=[] f4=[No.: A*];EP.c 1 f4=[LT Y37 LF Line: A1];');
        Observer.Expect('lines', 'A1,A2,A3,');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C311_RunPageLink_FilterValue()
    var
        P: TestPage "LT Y37 LF Run Card";
        L: TestPage "LT Y37 LF Line List";
        R: Text;
        i: Integer;
    begin
        Seed('A1|A3', '');
        P.OpenView();
        P.GoToKey('H1');
        Log.Take();
        L.Trap();
        P.OpenLines.Invoke();
        Observer.Observe('open log', Log.Take());
        if L.First() then
            repeat
                R += L.NoCtl.Value() + ',';
                i += 1;
            until (not L.Next()) or (i >= 10);
        Observer.Observe('rows', R);
        L.Close();
        P.Close();
        Observer.Expect('open log', 'LL.open f0=[No.: A1|A3] f4=[];LL.c A1 f0=[No.: A1|A3] f4=[];');
        Observer.Expect('rows', 'A1,A3,');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C311_Link_HostFlowFilter()
    var
        Host: Record "LT Y37 LF Host";
        P: TestPage "LT Y37 LF FlowFilter Card";
    begin
        Seed('', '');
        P.OpenEdit();
        P.GoToKey('H1');
        Observer.Observe('no flowfilter open log', Log.Take());
        Observer.Observe('no flowfilter rows', FlowRows(P));
        Log.Take();
        P.Filter.SetFilter("No. FlowFilter", 'A1|A2');
        Observer.Observe('testpage filter log', Log.Take());
        Observer.Observe('testpage filter rows', FlowRows(P));
        P.Close();
        Log.Take();
        Host.SetFilter("No. FlowFilter", 'A1|A2');
        Host.FindFirst();
        P.Trap();
        Page.Run(Page::"LT Y37 LF FlowFilter Card", Host);
        Observer.Observe('page run open log', Log.Take());
        Observer.Observe('page run rows', FlowRows(P));
        P.Close();
        Observer.Expect('no flowfilter open log', 'LP.open f0=[] f4=[];LP.c A1 f0=[] f4=[];LP.c A1 f0=[] f4=[];');
        Observer.Expect('no flowfilter rows', 'A1,A2,A3,B1,B2,');
        Observer.Expect('testpage filter log', 'LP.c A2 f0=[] f4=[No.: A1|A2];');
        Observer.Expect('testpage filter rows', 'A1,A2,');
        Observer.Expect('page run open log', 'LP.open f0=[] f4=[];LP.c A1 f0=[] f4=[No.: A1|A2];');
        Observer.Expect('page run rows', 'A1,A2,');
        Observer.Verify();
    end;

    [Test]
    procedure LT_C311_Link_ValueChangedOnPage()
    var
        P: TestPage "LT Y37 LF Card";
    begin
        Seed('A1', '');
        P.OpenEdit();
        P.GoToKey('H1');
        Observer.Observe('rows A1', CardRows(P));
        Log.Take();
        P.LineFilterCtl.SetValue('B*');
        Observer.Observe('setvalue log', Log.Take());
        Observer.Observe('rows after setvalue', CardRows(P));
        Log.Take();
        P.UpdateAction.Invoke();
        Observer.Observe('update log', Log.Take());
        Observer.Observe('rows after update', CardRows(P));
        P.Close();
        Log.Take();
        P.OpenEdit();
        P.GoToKey('H1');
        Observer.Observe('reopen log', Log.Take());
        Observer.Observe('rows after reopen', CardRows(P));
        P.Close();
        Observer.Expect('rows A1', 'A1,');
        Observer.Expect('setvalue log', 'LP.c B1 f0=[] f4=[No.: B*];');
        Observer.Expect('rows after setvalue', 'B1,B2,');
        Observer.Expect('update log', 'LP.c B2 f0=[] f4=[No.: B*];');
        Observer.Expect('rows after update', 'B1,B2,');
        Observer.Expect('reopen log', 'LP.open f0=[] f4=[];LP.c B1 f0=[] f4=[No.: B*];LP.c B1 f0=[] f4=[No.: B*];');
        Observer.Expect('rows after reopen', 'B1,B2,');
        Observer.Verify();
    end;
}
