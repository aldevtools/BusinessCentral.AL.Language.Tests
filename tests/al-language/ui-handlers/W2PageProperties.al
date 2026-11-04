// Probe: Page.SetTableView(Rec) with a filtered, positioned record, SetRecord, Page.RunModal(Id, Rec), a sorted view, and CurrPage.PromptMode set to Prompt, Content and Generate in OnOpenPage.
// Settles: md:283 (SetTableView keeps the view and drops the position; PromptMode modes). The LookupMode / new-row line half is pinned already.

codeunit 68717 "W2 Page Props Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 68715 "W2 View List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Card Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
            }
        }
    }
}

page 68716 "W2 Prompt Page"
{
    PageType = PromptDialog;
    ApplicationArea = All;
    SourceTable = "W2 Card Row";
    SourceTableTemporary = true;
    UsageCategory = None;
    Extensible = false;

    layout
    {
        area(Prompt)
        {
            field(PromptField; Rec.Descr) { ApplicationArea = All; }
        }
        area(Content)
        {
            field(OutField; Rec.Grp) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                trigger OnAction()
                var
                    Log: Codeunit "W2 Page Props Log";
                begin
                    Log.Add('Generate.OnAction');
                end;
            }
            systemaction(OK) { }
            systemaction(Cancel) { }
        }
    }

    procedure SetMode(NewMode: Integer)
    begin
        ModeToSet := NewMode;
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "W2 Page Props Log";
    begin
        Log.Add('OnOpenPage(before=' + Format(CurrPage.PromptMode) + ')');
        case ModeToSet of
            0:
                CurrPage.PromptMode := PromptMode::Prompt;
            1:
                CurrPage.PromptMode := PromptMode::Content;
            2:
                CurrPage.PromptMode := PromptMode::Generate;
        end;
        Log.Add('OnOpenPage(after=' + Format(CurrPage.PromptMode) + ')');
    end;

    var
        ModeToSet: Integer;
}

codeunit 68718 "W2 Page Props Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerRows: Text;
        HandlerCurrent: Text;

    local procedure Seed()
    var
        Row: Record "W2 Card Row";
    begin
        Row.DeleteAll();
        AddRow('A', 'x');
        AddRow('B', 'y');
        AddRow('C', 'x');
        AddRow('D', 'x');
    end;

    local procedure AddRow(No: Code[10]; Grp: Text[10])
    var
        Row: Record "W2 Card Row";
    begin
        Row."No." := No;
        Row.Grp := Grp;
        Row.Insert();
    end;

    // ---- SetTableView / SetRecord ----

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure SetTableView_FilteredAndPositionedRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W2 Card Row";
        Pg: Page "W2 View List";
    begin
        Seed();
        Row.SetRange(Grp, 'x');
        Row.Get('C');
        Pg.SetTableView(Row);
        Pg.RunModal();
        Observer.Observe('current_at_open', HandlerCurrent);
        Observer.Observe('rows', HandlerRows);
        Observer.Expect('current_at_open', '[A]');
        Observer.Expect('rows', '[A][C][D][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure SetTableViewAndSetRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W2 Card Row";
        Pg: Page "W2 View List";
    begin
        Seed();
        Row.SetRange(Grp, 'x');
        Row.Get('C');
        Pg.SetTableView(Row);
        Pg.SetRecord(Row);
        Pg.RunModal();
        Observer.Observe('current_at_open', HandlerCurrent);
        Observer.Observe('rows', HandlerRows);
        Observer.Expect('current_at_open', '[C]');
        Observer.Expect('rows', '[A][C][D][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure SetRecordOnly_NoFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W2 Card Row";
        Pg: Page "W2 View List";
    begin
        Seed();
        Row.Get('C');
        Pg.SetRecord(Row);
        Pg.RunModal();
        Observer.Observe('current_at_open', HandlerCurrent);
        Observer.Observe('rows', HandlerRows);
        Observer.Expect('current_at_open', '[C]');
        Observer.Expect('rows', '[A][B][C][D][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure RunModalWithRecord_FilteredAndPositioned()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W2 Card Row";
    begin
        Seed();
        Row.SetRange(Grp, 'x');
        Row.Get('C');
        Page.RunModal(Page::"W2 View List", Row);
        Observer.Observe('current_at_open', HandlerCurrent);
        Observer.Observe('rows', HandlerRows);
        Observer.Expect('current_at_open', '[C]');
        Observer.Expect('rows', '[A][C][D][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure SetTableView_DescendingOrder()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W2 Card Row";
        Pg: Page "W2 View List";
    begin
        Seed();
        Row.SetRange(Grp, 'x');
        Row.Ascending(false);
        Pg.SetTableView(Row);
        Pg.RunModal();
        Observer.Observe('current_at_open', HandlerCurrent);
        Observer.Observe('rows', HandlerRows);
        Observer.Expect('current_at_open', '[A]');
        Observer.Expect('rows', '[D][C][A][]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure SetTableView_ThenFilterChangedInRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W2 Card Row";
        Pg: Page "W2 View List";
    begin
        Seed();
        Row.SetRange(Grp, 'x');
        Pg.SetTableView(Row);
        Row.SetRange(Grp, 'y');
        Pg.RunModal();
        Observer.Observe('current_at_open', HandlerCurrent);
        Observer.Observe('rows', HandlerRows);
        Observer.Expect('current_at_open', '[A]');
        Observer.Expect('rows', '[A][C][D][]');
        Observer.Verify();
    end;

    // ---- PromptMode ----

    [Test]
    [HandlerFunctions('PromptHandler')]
    procedure PromptMode_Prompt()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunPrompt(Observer, 0);
        Observer.Expect('run|ok', 'Yes');
        Observer.Expect('log', 'OnOpenPage(before=None);OnOpenPage(after=Prompt);PromptField readable;OutField readable;Generate.Visible=Yes;Generate.Enabled=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PromptHandler')]
    procedure PromptMode_Content()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunPrompt(Observer, 1);
        Observer.Expect('run|ok', 'Yes');
        Observer.Expect('log', 'OnOpenPage(before=None);OnOpenPage(after=Content);PromptField readable;OutField readable;Generate.Visible=Yes;Generate.Enabled=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PromptHandler')]
    procedure PromptMode_Generate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunPrompt(Observer, 2);
        Observer.Expect('run|ok', 'Yes');
        Observer.Expect('log', 'OnOpenPage(before=None);OnOpenPage(after=Generate);PromptField readable;OutField readable;Generate.Visible=Yes;Generate.Enabled=Yes;');
        Observer.Verify();
    end;

    local procedure RunPrompt(var Observer: Codeunit "Probe Observer"; Mode: Integer)
    var
        Log: Codeunit "W2 Page Props Log";
        Pg: Page "W2 Prompt Page";
        Ok: Boolean;
    begin
        Log.Take();
        Pg.SetMode(Mode);
        Ok := RunPromptPage(Pg);
        Observer.Observe('run|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run');
        Observer.Observe('log', Log.Take());
    end;

    [ModalPageHandler]
    procedure ViewHandler(var Pg: TestPage "W2 View List")
    var
        Found: Boolean;
    begin
        HandlerRows := '';
        HandlerCurrent := '[' + Pg."No.".Value() + ']';
        Found := Pg.First();
        while Found do begin
            HandlerRows += '[' + Pg."No.".Value() + ']';
            Found := Pg.Next();
        end;
    end;

    [ModalPageHandler]
    procedure PromptHandler(var Pg: TestPage "W2 Prompt Page")
    var
        Log: Codeunit "W2 Page Props Log";
        Seen: Boolean;
        Value: Text;
    begin
        if ReadPrompt(Pg, Value) then
            Log.Add('PromptField readable')
        else
            Log.Add('PromptField error: ' + GetLastErrorText());
        if ReadOut(Pg, Value) then
            Log.Add('OutField readable')
        else
            Log.Add('OutField error: ' + GetLastErrorText());
        if GenerateVisible(Pg, Seen) then
            Log.Add('Generate.Visible=' + Format(Seen))
        else
            Log.Add('Generate.Visible error: ' + GetLastErrorText());
        if GenerateEnabled(Pg, Seen) then
            Log.Add('Generate.Enabled=' + Format(Seen))
        else
            Log.Add('Generate.Enabled error: ' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure RunPromptPage(var Pg: Page "W2 Prompt Page")
    begin
        Pg.RunModal();
    end;

    [TryFunction]
    local procedure ReadPrompt(var Pg: TestPage "W2 Prompt Page"; var Value: Text)
    begin
        Value := Pg.PromptField.Value();
    end;

    [TryFunction]
    local procedure ReadOut(var Pg: TestPage "W2 Prompt Page"; var Value: Text)
    begin
        Value := Pg.OutField.Value();
    end;

    [TryFunction]
    local procedure GenerateVisible(var Pg: TestPage "W2 Prompt Page"; var Result: Boolean)
    begin
        Result := Pg.Generate.Visible();
    end;

    [TryFunction]
    local procedure GenerateEnabled(var Pg: TestPage "W2 Prompt Page"; var Result: Boolean)
    begin
        Result := Pg.Generate.Enabled();
    end;
}
