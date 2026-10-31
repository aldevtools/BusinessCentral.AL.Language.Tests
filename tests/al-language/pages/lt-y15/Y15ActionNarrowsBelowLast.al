// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 91730 - 91734 (writer Y15)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6468, follow-up to 6381 (a row of the new view follows: pages/lt-y5/Y5GoToKeyAfterActionFilter.al).
//   A List page over rows 1, 2, 3 (Included = true, true, false). OnOpenPage sets SetRange(Included, true). Action ShowAll clears
//   the filter, ShowIncluded sets it again, both with CurrPage.Update(false). ShowIncludedNoUpdate sets it without CurrPage.Update.
//   ShowOdd sets SetFilter(Id, '1|3') (row 3 follows row 2), ShowNone sets SetRange(Id, 100) (empty view).
//   The page stands on row 3 (Last) when an action drops row 3 from the view, so only earlier rows remain.
//   Page 91731 has no row triggers (the reporter's page); page 91732 is the same with OnAfterGetRecord / OnAfterGetCurrRecord logged.
// Source: al-runner issue 6468 (the reporter's repro passed on a real BC 29 container).
// BC versions: 27, 28, 29

table 91730 "LT Y15 NV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Included; Boolean) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 91731 "LT Y15 NV List"
{
    PageType = List;
    SourceTable = "LT Y15 NV Row";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Included; Rec.Included) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ShowAll)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.SetRange(Included);
                    CurrPage.Update(false);
                end;
            }
            action(ShowIncluded)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.SetRange(Included, true);
                    CurrPage.Update(false);
                end;
            }
            action(ShowIncludedNoUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.SetRange(Included, true);
                end;
            }
            action(ShowOdd)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.SetRange(Included);
                    Rec.SetFilter(Id, '1|3');
                    CurrPage.Update(false);
                end;
            }
            action(ShowNone)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.SetRange(Id, 100);
                    CurrPage.Update(false);
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.SetRange(Included, true);
    end;
}

page 91732 "LT Y15 NV List Logged"
{
    PageType = List;
    SourceTable = "LT Y15 NV Row";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Included; Rec.Included) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ShowAll)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.SetRange(Included);
                    CurrPage.Update(false);
                end;
            }
            action(ShowIncluded)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('action ' + Format(Rec.Id));
                    Rec.SetRange(Included, true);
                    CurrPage.Update(false);
                    Log.Add('updated ' + Format(Rec.Id));
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.SetRange(Included, true);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('agr' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT Y15 NV Log";
}

codeunit 91733 "LT Y15 NV Log"
{
    SingleInstance = true;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    var
        Entries: Text;
}

codeunit 91734 "LT Y15 NV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y15 NV Log";

    local procedure Seed()
    var
        Row: Record "LT Y15 NV Row";
    begin
        Log.Take();
        Row.DeleteAll();
        AddRow(1, true);
        AddRow(2, true);
        AddRow(3, false);
    end;

    local procedure AddRow(Id: Integer; Included: Boolean)
    var
        Row: Record "LT Y15 NV Row";
    begin
        Row.Id := Id;
        Row.Included := Included;
        Row.Insert();
    end;

    local procedure StandOnLast(var List: TestPage "LT Y15 NV List")
    begin
        List.OpenView();
        List.ShowAll.Invoke();
        if not List.Last() or (List.Id.AsInteger() <> 3) then
            Error('The full view must end at row 3.');
    end;

    // The reporter's test, with the row the page stands on right after the action and each move's return value.
    [Test]
    procedure Y15_NV_ReporterShape()
    var
        List: TestPage "LT Y15 NV List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('open', List.Id.Value());
        Observer.Observe('first', Format(List.First(), 0, 9) + '/' + List.Id.Value());
        List.ShowAll.Invoke();
        Observer.Observe('after show all', List.Id.Value());
        Observer.Observe('last', Format(List.Last(), 0, 9) + '/' + List.Id.Value());
        List.ShowIncluded.Invoke();
        Observer.Observe('after show included', List.Id.Value() + '/' + List.Included.Value());
        Observer.Observe('first again', Format(List.First(), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('next', Format(List.Next(), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('next end', Format(List.Next(), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('last again', Format(List.Last(), 0, 9) + '/' + List.Id.Value());
        List.Close();
        Observer.Finish();
    end;

    // Moves straight after the narrowing action, without First: Next, Previous from the row the page stands on.
    [Test]
    procedure Y15_NV_MovesStraightAfterAction()
    var
        List: TestPage "LT Y15 NV List";
    begin
        Seed();
        StandOnLast(List);
        List.ShowIncluded.Invoke();
        Observer.Observe('next', Format(List.Next(), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('previous', Format(List.Previous(), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('previous 2', Format(List.Previous(), 0, 9) + '/' + List.Id.Value());
        List.Close();

        StandOnLast(List);
        List.ShowIncluded.Invoke();
        Observer.Observe('previous first', Format(List.Previous(), 0, 9) + '/' + List.Id.Value());
        List.Close();
        Observer.Finish();
    end;

    // GoToRecord and GoToKey after the narrowing action: the dropped row 3 and the remaining rows 1 and 2.
    [Test]
    procedure Y15_NV_GoToAfterAction()
    var
        Row: Record "LT Y15 NV Row";
        List: TestPage "LT Y15 NV List";
    begin
        Seed();
        StandOnLast(List);
        List.ShowIncluded.Invoke();
        Row.Get(3);
        Observer.Observe('goto record 3', Format(List.GoToRecord(Row), 0, 9) + '/' + List.Id.Value());
        Row.Get(2);
        Observer.Observe('goto record 2', Format(List.GoToRecord(Row), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('goto key 3', Format(List.GoToKey(3), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('goto key 1', Format(List.GoToKey(1), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('next', Format(List.Next(), 0, 9) + '/' + List.Id.Value());
        List.Close();
        Observer.Finish();
    end;

    // The action sets the filter without CurrPage.Update(false).
    [Test]
    procedure Y15_NV_NarrowWithoutUpdate()
    var
        Row: Record "LT Y15 NV Row";
        List: TestPage "LT Y15 NV List";
    begin
        Seed();
        StandOnLast(List);
        List.ShowIncludedNoUpdate.Invoke();
        Observer.Observe('after action', List.Id.Value() + '/' + List.Included.Value());
        Row.Get(3);
        Observer.Observe('goto record 3', Format(List.GoToRecord(Row), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('first', Format(List.First(), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('next', Format(List.Next(), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('next end', Format(List.Next(), 0, 9) + '/' + List.Id.Value());
        List.Close();
        Observer.Finish();
    end;

    // Neighbours: the page stands on row 2 and the action drops it while row 3 follows; the action leaves no row at all.
    [Test]
    procedure Y15_NV_MiddleRowAndEmptyView()
    var
        List: TestPage "LT Y15 NV List";
    begin
        Seed();
        List.OpenView();
        List.ShowAll.Invoke();
        List.First();
        List.Next();
        Observer.Observe('on', List.Id.Value());
        List.ShowOdd.Invoke();
        Observer.Observe('after odd', List.Id.Value());
        Observer.Observe('odd next', Format(List.Next(), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('odd first', Format(List.First(), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('odd next 2', Format(List.Next(), 0, 9) + '/' + List.Id.Value());
        List.ShowNone.Invoke();
        Observer.Observe('after none', '[' + List.Id.Value() + ']');
        Observer.Observe('none first', Format(List.First(), 0, 9) + '/[' + List.Id.Value() + ']');
        Observer.Observe('none last', Format(List.Last(), 0, 9) + '/[' + List.Id.Value() + ']');
        List.Close();
        Observer.Finish();
    end;

    // The logged page: which row triggers run when the action drops the current last row.
    [Test]
    procedure Y15_NV_TriggersOnNarrowing()
    var
        List: TestPage "LT Y15 NV List Logged";
    begin
        Seed();
        List.OpenView();
        List.ShowAll.Invoke();
        List.Last();
        Observer.Observe('on', List.Id.Value());
        Log.Take();
        List.ShowIncluded.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('after action', List.Id.Value());
        Observer.Observe('first', Format(List.First(), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('first log', Log.Take());
        Observer.Observe('next', Format(List.Next(), 0, 9) + '/' + List.Id.Value());
        Observer.Observe('next log', Log.Take());
        List.Close();
        Observer.Finish();
    end;
}
