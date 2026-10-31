// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects in Y37LinkFilterObjects.al (92600-92611)
// Probe: gap cycle 3 spec C3-11 (writer Y37). Every literal asserted below is what the BC service tier produced.
// Facts: a SubPageLink or RunPageLink `<target> = field(filter(<host field>))` reads the host field's VALUE as a filter expression on the
//   target field: which rows the part shows for a single value, a `|` list, a range, a wildcard and a blank value; the filter on a FlowFilter
//   target (and the FlowField it drives); a Provider part whose RecordId target gets the formatted RecordId of the provider's row; the same
//   in a RunPageLink; a host field that is a FlowFilter field; a host value changed while the page is open. The part logs (OnOpenPage) the
//   filters of filter group 0 and 4 and GetFilter of the target fields.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
