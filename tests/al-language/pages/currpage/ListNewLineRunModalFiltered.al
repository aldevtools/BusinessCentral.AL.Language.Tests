// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// local object: the table field's OnValidate that inserts the page's new line, and the page triggers that log, are what is under test
// Fixtures used: Probe Observer (69160); own table 97067, log codeunit 97068, pages 97069 to 97072, opener codeunits 97077 and 97075,
//   test codeunit 97074
// Probe (al-runner issue 8186, the reporter's open path): the same new-line steps as pages/currpage/ListNewLineCodeInsertUpdate.al, but the
//   page is opened through Page.RunModal on a record filtered to one group, as the reporter's repro does. A List page stands on its new
//   line (New()). SetValue on Name runs the table field's OnValidate, which inserts Rec itself (Insert(true), with an AutoIncrement key
//   field), and then the control's OnValidate, which calls CurrPage.Update() or CurrPage.Update(false). Readings: the page and table
//   triggers each step runs, the row the page shows after the refresh, the rows the table holds (with their group), where a later
//   SetValue lands, Previous()/Next() from there, and what OK or Close saves.
//   Cells: a page without page triggers (the reporter's page) and a page with OnNewRecord, OnInsertRecord, OnModifyRecord,
//   OnAfterGetRecord and OnAfterGetCurrRecord, each with and without AutoSplitKey; opened with Page.RunModal on a record filtered with
//   SetRange to one group (a row of another group outside the view), Page.RunModal on an unfiltered record, Page.RunModal on a record
//   filtered with SetFilter to two groups, TestPage.Trap and Page.Run on the record filtered to one group, and OpenEdit with the filter
//   set on the TestPage after the open; an empty view and a view with one row before; Update() and Update(false); the reporter's exact
//   handler steps (New, SetValue Name, read Name, SetValue Value, OK) under TransactionModel AutoCommit; and TestPage.Trap followed by
//   Page.RunModal without a ModalPageHandler (through Codeunit.Run).
//   Facts (the logs are the pin's notation: T.V/T.I/T.M table triggers, P.* page triggers):
//   - Page.RunModal on the record filtered with SetRange to one group behaves as the OpenEdit pin, step for step: the new line gets
//     the filter's group, the table field inserts it, Update() modifies it (Update(false) does not), the refresh shows it, the next
//     SetValue lands on it, and Previous()/Next() save it. Without AutoSplitKey, through TestPage.Trap and Page.Run, and with OpenEdit
//     plus a TestPage filter set after the open, every reading is the same.
//   - The reporter's handler steps (no Previous/Next): OK saves Value on the inserted row (the OK logs T.M(X/V)), and the table holds
//     the inserted row with Value V next to the row that was there before.
//   - Page.RunModal on an unfiltered record: the same, with a blank group on the inserted row.
//   - Page.RunModal on a record filtered with SetFilter to two groups: the new line gets no group, so the inserted row lies outside
//     the view. After Update() the page shows the row before (or an empty new line on an empty view), the next SetValue lands there,
//     and Next() saves it there (on an empty view Next() inserts that empty line as a second row with Value V).
//   - TestPage.Trap does not catch Page.RunModal: the trapped TestPage stays closed. Without a ModalPageHandler, BC 27 raises
//     "Unhandled UI: ModalPage <id>"; BC 28 and 29 raise nothing and Page.RunModal returns.
//   Measured on local BC 27.5, 28.5 and 29.0 containers.
// BC versions: 27, 28, 29

table 97067 "LT NR Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Group Code"; Code[10]) { }
        field(2; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }
        field(3; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT NR Log";
            begin
                Log.Add('T.V(' + Name + ')');
                if "Entry No." = 0 then
                    Insert(true);
            end;
        }
        field(4; Value; Text[30]) { }
    }

    keys
    {
        key(PK; "Group Code", "Entry No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT NR Log";
    begin
        Log.Add('T.I(' + "Group Code" + ':' + Name + ')');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT NR Log";
    begin
        Log.Add('T.M(' + Name + '/' + Value + ')');
    end;
}

// The reporter's page: no page trigger; the control calls Update() or Update(false) (the log codeunit's switch).
page 97069 "LT NR Lines Quiet"
{
    PageType = List;
    SourceTable = "LT NR Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        if Log.IsUpdateFalse() then
                            CurrPage.Update(false)
                        else
                            CurrPage.Update();
                    end;
                }
                field(Value; Rec.Value) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "LT NR Log";
}

// The same page without AutoSplitKey.
page 97070 "LT NR Lines Quiet No Split"
{
    PageType = List;
    SourceTable = "LT NR Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        if Log.IsUpdateFalse() then
                            CurrPage.Update(false)
                        else
                            CurrPage.Update();
                    end;
                }
                field(Value; Rec.Value) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "LT NR Log";
}

// A page whose triggers log each step.
page 97071 "LT NR Lines Logged"
{
    PageType = List;
    SourceTable = "LT NR Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('P.V(' + Log.Bool(Rec."Entry No." <> 0) + ')');
                        if Log.IsUpdateFalse() then
                            CurrPage.Update(false)
                        else
                            CurrPage.Update();
                        Log.Add('P.V.end');
                    end;
                }
                field(Value; Rec.Value) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('P.NEW');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('P.INS(' + Rec.Name + ')');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('P.MOD(' + Rec.Name + '/' + Rec.Value + ')');
        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('P.AGR(' + Rec.Name + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR(' + Rec.Name + ')');
    end;

    var
        Log: Codeunit "LT NR Log";
}

// The same page without AutoSplitKey.
page 97072 "LT NR Lines Logged No Split"
{
    PageType = List;
    SourceTable = "LT NR Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('P.V(' + Log.Bool(Rec."Entry No." <> 0) + ')');
                        if Log.IsUpdateFalse() then
                            CurrPage.Update(false)
                        else
                            CurrPage.Update();
                        Log.Add('P.V.end');
                    end;
                }
                field(Value; Rec.Value) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('P.NEW');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('P.INS(' + Rec.Name + ')');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('P.MOD(' + Rec.Name + '/' + Rec.Value + ')');
        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('P.AGR(' + Rec.Name + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR(' + Rec.Name + ')');
    end;

    var
        Log: Codeunit "LT NR Log";
}

codeunit 97068 "LT NR Log"
{
    SingleInstance = true;

    var
        Buffer: Text;
        UpdateFalse: Boolean;

    procedure Reset(NewUpdateFalse: Boolean)
    begin
        Buffer := '';
        UpdateFalse := NewUpdateFalse;
    end;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;

    procedure IsUpdateFalse(): Boolean
    begin
        exit(UpdateFalse);
    end;

    procedure Bool(Value: Boolean): Text
    begin
        if Value then
            exit('T');
        exit('F');
    end;
}

// Opens a page on a record, as the reporter's app codeunit does. FilterMode: 0 no filter, 1 SetRange to group G2, 2 SetFilter G2|G3.
codeunit 97077 "LT NR Opener"
{
    procedure Open(PageId: Integer; FilterMode: Integer; Modal: Boolean)
    var
        Line: Record "LT NR Line";
    begin
        case FilterMode of
            1:
                Line.SetRange("Group Code", 'G2');
            2:
                Line.SetFilter("Group Code", 'G2|G3');
        end;
        if Modal then
            Page.RunModal(PageId, Line)
        else
            Page.Run(PageId, Line);
    end;
}

// Page.RunModal on the record filtered to group G2, as a codeunit of its own (the test runs it through Codeunit.Run).
codeunit 97075 "LT NR Modal Opener"
{
    trigger OnRun()
    var
        Line: Record "LT NR Line";
        Log: Codeunit "LT NR Log";
    begin
        Line.SetRange("Group Code", 'G2');
        Page.RunModal(Page::"LT NR Lines Quiet", Line);
        Log.Add('runmodal returned');
    end;
}

codeunit 97074 "LT NR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT NR Log";
        ReporterSequence: Boolean;

    // OtherGroupRow: a row of group G1 outside the filtered view. RowBefore: a row 'A' in group G2 (blank group when OtherGroupRow is false).
    local procedure Initialize(OtherGroupRow: Boolean; RowBefore: Boolean; UpdateFalse: Boolean; Reporter: Boolean)
    var
        Line: Record "LT NR Line";
    begin
        Clear(Observer);
        Line.DeleteAll();
        if OtherGroupRow then begin
            Line.Init();
            Line."Group Code" := 'G1';
            Line.Name := 'O';
            Line.Insert();
        end;
        if RowBefore then begin
            Line.Init();
            if OtherGroupRow then
                Line."Group Code" := 'G2';
            Line.Name := 'A';
            Line.Insert();
        end;
        Commit();
        Log.Reset(UpdateFalse);
        ReporterSequence := Reporter;
    end;

    local procedure GroupRows(): Text
    var
        Line: Record "LT NR Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line."Group Code" + ':' + Line.Name + '/' + Line.Value + ',';
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure DriveQuiet(var Lines: TestPage "LT NR Lines Quiet")
    begin
        Observer.Observe('open', Log.Take());
        if not ReporterSequence then
            Observer.Observe('openshown', Lines.Name.Value() + '/' + Lines.Value.Value());
        Lines.New();
        Observer.Observe('new', Log.Take());
        Lines.Name.SetValue('X');
        Observer.Observe('setname', Log.Take());
        if ReporterSequence then
            Observer.Observe('shown', Lines.Name.Value())
        else
            Observer.Observe('shown', Lines.Name.Value() + '/' + Lines.Value.Value());
        Observer.Observe('rows1', GroupRows());
        Lines.Value.SetValue('V');
        Observer.Observe('setvalue', Log.Take());
        Observer.Observe('rows2', GroupRows());
        if ReporterSequence then
            exit;
        Observer.Observe('shown2', Lines.Name.Value() + '/' + Lines.Value.Value());
        Observer.Observe('prev', Log.Bool(Lines.Previous()) + '/' + Lines.Name.Value());
        Observer.Observe('prevlog', Log.Take());
        Observer.Observe('next', Log.Bool(Lines.Next()) + '/' + Lines.Name.Value());
        Observer.Observe('nextlog', Log.Take());
    end;

    local procedure DriveQuietNoSplit(var Lines: TestPage "LT NR Lines Quiet No Split")
    begin
        Observer.Observe('open', Log.Take());
        if not ReporterSequence then
            Observer.Observe('openshown', Lines.Name.Value() + '/' + Lines.Value.Value());
        Lines.New();
        Observer.Observe('new', Log.Take());
        Lines.Name.SetValue('X');
        Observer.Observe('setname', Log.Take());
        if ReporterSequence then
            Observer.Observe('shown', Lines.Name.Value())
        else
            Observer.Observe('shown', Lines.Name.Value() + '/' + Lines.Value.Value());
        Observer.Observe('rows1', GroupRows());
        Lines.Value.SetValue('V');
        Observer.Observe('setvalue', Log.Take());
        Observer.Observe('rows2', GroupRows());
        if ReporterSequence then
            exit;
        Observer.Observe('shown2', Lines.Name.Value() + '/' + Lines.Value.Value());
        Observer.Observe('prev', Log.Bool(Lines.Previous()) + '/' + Lines.Name.Value());
        Observer.Observe('prevlog', Log.Take());
        Observer.Observe('next', Log.Bool(Lines.Next()) + '/' + Lines.Name.Value());
        Observer.Observe('nextlog', Log.Take());
    end;

    local procedure DriveLogged(var Lines: TestPage "LT NR Lines Logged")
    begin
        Observer.Observe('open', Log.Take());
        if not ReporterSequence then
            Observer.Observe('openshown', Lines.Name.Value() + '/' + Lines.Value.Value());
        Lines.New();
        Observer.Observe('new', Log.Take());
        Lines.Name.SetValue('X');
        Observer.Observe('setname', Log.Take());
        if ReporterSequence then
            Observer.Observe('shown', Lines.Name.Value())
        else
            Observer.Observe('shown', Lines.Name.Value() + '/' + Lines.Value.Value());
        Observer.Observe('rows1', GroupRows());
        Lines.Value.SetValue('V');
        Observer.Observe('setvalue', Log.Take());
        Observer.Observe('rows2', GroupRows());
        if ReporterSequence then
            exit;
        Observer.Observe('shown2', Lines.Name.Value() + '/' + Lines.Value.Value());
        Observer.Observe('prev', Log.Bool(Lines.Previous()) + '/' + Lines.Name.Value());
        Observer.Observe('prevlog', Log.Take());
        Observer.Observe('next', Log.Bool(Lines.Next()) + '/' + Lines.Name.Value());
        Observer.Observe('nextlog', Log.Take());
    end;

    local procedure DriveLoggedNoSplit(var Lines: TestPage "LT NR Lines Logged No Split")
    begin
        Observer.Observe('open', Log.Take());
        if not ReporterSequence then
            Observer.Observe('openshown', Lines.Name.Value() + '/' + Lines.Value.Value());
        Lines.New();
        Observer.Observe('new', Log.Take());
        Lines.Name.SetValue('X');
        Observer.Observe('setname', Log.Take());
        if ReporterSequence then
            Observer.Observe('shown', Lines.Name.Value())
        else
            Observer.Observe('shown', Lines.Name.Value() + '/' + Lines.Value.Value());
        Observer.Observe('rows1', GroupRows());
        Lines.Value.SetValue('V');
        Observer.Observe('setvalue', Log.Take());
        Observer.Observe('rows2', GroupRows());
        if ReporterSequence then
            exit;
        Observer.Observe('shown2', Lines.Name.Value() + '/' + Lines.Value.Value());
        Observer.Observe('prev', Log.Bool(Lines.Previous()) + '/' + Lines.Name.Value());
        Observer.Observe('prevlog', Log.Take());
        Observer.Observe('next', Log.Bool(Lines.Next()) + '/' + Lines.Name.Value());
        Observer.Observe('nextlog', Log.Take());
    end;

    [ModalPageHandler]
    procedure QuietModalHandler(var Lines: TestPage "LT NR Lines Quiet")
    begin
        DriveQuiet(Lines);
        Lines.OK().Invoke();
        Observer.Observe('ok', Log.Take());
    end;

    [ModalPageHandler]
    procedure QuietNoSplitModalHandler(var Lines: TestPage "LT NR Lines Quiet No Split")
    begin
        DriveQuietNoSplit(Lines);
        Lines.OK().Invoke();
        Observer.Observe('ok', Log.Take());
    end;

    [ModalPageHandler]
    procedure LoggedModalHandler(var Lines: TestPage "LT NR Lines Logged")
    begin
        DriveLogged(Lines);
        Lines.OK().Invoke();
        Observer.Observe('ok', Log.Take());
    end;

    [ModalPageHandler]
    procedure LoggedNoSplitModalHandler(var Lines: TestPage "LT NR Lines Logged No Split")
    begin
        DriveLoggedNoSplit(Lines);
        Lines.OK().Invoke();
        Observer.Observe('ok', Log.Take());
    end;

    [Test]
    [HandlerFunctions('QuietModalHandler')]
    procedure NewLineRM_Quiet_RunModalFiltered_Update_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, false, false, false);
        Opener.Open(Page::"LT NR Lines Quiet", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);T.M(X/);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'F/X');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'T.M(X/V);');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QuietModalHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure NewLineRM_Quiet_RunModalFiltered_Update_EmptyView_ReporterSteps()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, false, false, true);
        Opener.Open(Page::"LT NR Lines Quiet", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);T.M(X/);');
        Observer.Expect('shown', 'X');
        Observer.Expect('rows1', 'G1:O/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:X/,');
        Observer.Expect('ok', 'T.M(X/V);');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QuietModalHandler')]
    procedure NewLineRM_Quiet_RunModalUnfiltered_Update_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(false, false, false, false);
        Opener.Open(Page::"LT NR Lines Quiet", 0, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(:X);T.M(X/);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', ':X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', ':X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'F/X');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'T.M(X/V);');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', ':X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QuietModalHandler')]
    procedure NewLineRM_Quiet_RunModalRangeFilter_Update_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, false, false, false);
        Opener.Open(Page::"LT NR Lines Quiet", 2, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(:X);T.M(X/);');
        Observer.Expect('shown', '/');
        Observer.Expect('rows1', ':X/,G1:O/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', ':X/,G1:O/,');
        Observer.Expect('shown2', '/V');
        Observer.Expect('prev', 'F/');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'T.I(:);');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', ':X/,:/V,G1:O/,');
        Observer.Verify();
    end;

    [Test]
    procedure NewLineRM_Quiet_TrapRunFiltered_Update_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
        Lines: TestPage "LT NR Lines Quiet";
    begin
        Initialize(true, false, false, false);
        Lines.Trap();
        Opener.Open(Page::"LT NR Lines Quiet", 1, false);
        DriveQuiet(Lines);
        Lines.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);T.M(X/);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'F/X');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'T.M(X/V);');
        Observer.Expect('close', '');
        Observer.Expect('rows3', 'G1:O/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    procedure NewLineRM_Quiet_OpenEditFilterAfterOpen_Update_EmptyView()
    var
        Lines: TestPage "LT NR Lines Quiet";
    begin
        Initialize(true, false, false, false);
        Lines.OpenEdit();
        Lines.Filter.SetFilter("Group Code", 'G2');
        DriveQuiet(Lines);
        Lines.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);T.M(X/);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'F/X');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'T.M(X/V);');
        Observer.Expect('close', '');
        Observer.Expect('rows3', 'G1:O/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QuietModalHandler')]
    procedure NewLineRM_Quiet_RunModalFiltered_UpdateFalse_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, false, true, false);
        Opener.Open(Page::"LT NR Lines Quiet", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'F/X');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'T.M(X/V);');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    procedure NewLineRM_Quiet_TrapRunFiltered_UpdateFalse_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
        Lines: TestPage "LT NR Lines Quiet";
    begin
        Initialize(true, false, true, false);
        Lines.Trap();
        Opener.Open(Page::"LT NR Lines Quiet", 1, false);
        DriveQuiet(Lines);
        Lines.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'F/X');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'T.M(X/V);');
        Observer.Expect('close', '');
        Observer.Expect('rows3', 'G1:O/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QuietNoSplitModalHandler')]
    procedure NewLineRM_QuietNoSplit_RunModalFiltered_Update_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, false, false, false);
        Opener.Open(Page::"LT NR Lines Quiet No Split", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);T.M(X/);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'F/X');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'T.M(X/V);');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    procedure NewLineRM_QuietNoSplit_TrapRunFiltered_Update_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
        Lines: TestPage "LT NR Lines Quiet No Split";
    begin
        Initialize(true, false, false, false);
        Lines.Trap();
        Opener.Open(Page::"LT NR Lines Quiet No Split", 1, false);
        DriveQuietNoSplit(Lines);
        Lines.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);T.M(X/);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'F/X');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'T.M(X/V);');
        Observer.Expect('close', '');
        Observer.Expect('rows3', 'G1:O/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoggedModalHandler')]
    procedure NewLineRM_Logged_RunModalFiltered_Update_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, false, false, false);
        Opener.Open(Page::"LT NR Lines Logged", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', 'P.NEW;P.AGCR();P.NEW;P.AGCR();');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', 'P.NEW;P.AGCR();');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);P.V(T);P.MOD(X/);T.M(X/);P.V.end;P.AGR(X);P.AGR(X);P.AGCR(X);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'F/X');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'P.MOD(X/V);T.M(X/V);P.NEW;P.AGCR();');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoggedModalHandler')]
    procedure NewLineRM_Logged_RunModalRangeFilter_Update_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, false, false, false);
        Opener.Open(Page::"LT NR Lines Logged", 2, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', 'P.NEW;P.AGCR();P.NEW;P.AGCR();');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', 'P.NEW;P.AGCR();');
        Observer.Expect('setname', 'T.V(X);T.I(:X);P.V(T);P.MOD(X/);T.M(X/);P.V.end;P.NEW;P.AGCR();P.NEW;P.AGCR();');
        Observer.Expect('shown', '/');
        Observer.Expect('rows1', ':X/,G1:O/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', ':X/,G1:O/,');
        Observer.Expect('shown2', '/V');
        Observer.Expect('prev', 'F/');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'P.INS();T.I(:);P.NEW;P.AGCR();');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', ':/V,:X/,G1:O/,');
        Observer.Verify();
    end;

    [Test]
    procedure NewLineRM_Logged_TrapRunFiltered_Update_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
        Lines: TestPage "LT NR Lines Logged";
    begin
        Initialize(true, false, false, false);
        Lines.Trap();
        Opener.Open(Page::"LT NR Lines Logged", 1, false);
        DriveLogged(Lines);
        Lines.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', 'P.NEW;P.AGCR();P.NEW;P.AGCR();');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', 'P.NEW;P.AGCR();');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);P.V(T);P.MOD(X/);T.M(X/);P.V.end;P.AGR(X);P.AGR(X);P.AGCR(X);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'F/X');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'P.MOD(X/V);T.M(X/V);P.NEW;P.AGCR();');
        Observer.Expect('close', '');
        Observer.Expect('rows3', 'G1:O/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoggedModalHandler')]
    procedure NewLineRM_Logged_RunModalFiltered_UpdateFalse_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, false, true, false);
        Opener.Open(Page::"LT NR Lines Logged", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', 'P.NEW;P.AGCR();P.NEW;P.AGCR();');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', 'P.NEW;P.AGCR();');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);P.V(T);P.V.end;P.AGR(X);P.AGR(X);P.AGCR(X);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'F/X');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'P.MOD(X/V);T.M(X/V);P.NEW;P.AGCR();');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoggedNoSplitModalHandler')]
    procedure NewLineRM_LoggedNoSplit_RunModalFiltered_Update_EmptyView()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, false, false, false);
        Opener.Open(Page::"LT NR Lines Logged No Split", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', 'P.NEW;P.AGCR();P.NEW;P.AGCR();');
        Observer.Expect('openshown', '/');
        Observer.Expect('new', 'P.NEW;P.AGCR();');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);P.V(T);P.MOD(X/);T.M(X/);P.V.end;P.AGR(X);P.AGR(X);P.AGCR(X);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'F/X');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'P.MOD(X/V);T.M(X/V);P.NEW;P.AGCR();');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QuietModalHandler')]
    procedure NewLineRM_Quiet_RunModalFiltered_Update_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, true, false, false);
        Opener.Open(Page::"LT NR Lines Quiet", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);T.M(X/);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'T/A');
        Observer.Expect('prevlog', 'T.M(X/V);');
        Observer.Expect('next', 'T/X');
        Observer.Expect('nextlog', '');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:A/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QuietModalHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure NewLineRM_Quiet_RunModalFiltered_Update_RowBefore_ReporterSteps()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, true, false, true);
        Opener.Open(Page::"LT NR Lines Quiet", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);T.M(X/);');
        Observer.Expect('shown', 'X');
        Observer.Expect('rows1', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('ok', 'T.M(X/V);');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:A/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QuietModalHandler')]
    procedure NewLineRM_Quiet_RunModalUnfiltered_Update_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(false, true, false, false);
        Opener.Open(Page::"LT NR Lines Quiet", 0, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(:X);T.M(X/);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', ':A/,:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', ':A/,:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'T/A');
        Observer.Expect('prevlog', 'T.M(X/V);');
        Observer.Expect('next', 'T/X');
        Observer.Expect('nextlog', '');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', ':A/,:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QuietModalHandler')]
    procedure NewLineRM_Quiet_RunModalRangeFilter_Update_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, true, false, false);
        Opener.Open(Page::"LT NR Lines Quiet", 2, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(:X);T.M(X/);');
        Observer.Expect('shown', 'A/');
        Observer.Expect('rows1', ':X/,G1:O/,G2:A/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', ':X/,G1:O/,G2:A/,');
        Observer.Expect('shown2', 'A/V');
        Observer.Expect('prev', 'F/A');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'T.M(A/V);');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', ':X/,G1:O/,G2:A/V,');
        Observer.Verify();
    end;

    [Test]
    procedure NewLineRM_Quiet_TrapRunFiltered_Update_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
        Lines: TestPage "LT NR Lines Quiet";
    begin
        Initialize(true, true, false, false);
        Lines.Trap();
        Opener.Open(Page::"LT NR Lines Quiet", 1, false);
        DriveQuiet(Lines);
        Lines.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);T.M(X/);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'T/A');
        Observer.Expect('prevlog', 'T.M(X/V);');
        Observer.Expect('next', 'T/X');
        Observer.Expect('nextlog', '');
        Observer.Expect('close', '');
        Observer.Expect('rows3', 'G1:O/,G2:A/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    procedure NewLineRM_Quiet_OpenEditFilterAfterOpen_Update_RowBefore()
    var
        Lines: TestPage "LT NR Lines Quiet";
    begin
        Initialize(true, true, false, false);
        Lines.OpenEdit();
        Lines.Filter.SetFilter("Group Code", 'G2');
        DriveQuiet(Lines);
        Lines.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);T.M(X/);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'T/A');
        Observer.Expect('prevlog', 'T.M(X/V);');
        Observer.Expect('next', 'T/X');
        Observer.Expect('nextlog', '');
        Observer.Expect('close', '');
        Observer.Expect('rows3', 'G1:O/,G2:A/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QuietModalHandler')]
    procedure NewLineRM_Quiet_RunModalFiltered_UpdateFalse_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, true, true, false);
        Opener.Open(Page::"LT NR Lines Quiet", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'T/A');
        Observer.Expect('prevlog', 'T.M(X/V);');
        Observer.Expect('next', 'T/X');
        Observer.Expect('nextlog', '');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:A/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    procedure NewLineRM_Quiet_TrapRunFiltered_UpdateFalse_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
        Lines: TestPage "LT NR Lines Quiet";
    begin
        Initialize(true, true, true, false);
        Lines.Trap();
        Opener.Open(Page::"LT NR Lines Quiet", 1, false);
        DriveQuiet(Lines);
        Lines.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'T/A');
        Observer.Expect('prevlog', 'T.M(X/V);');
        Observer.Expect('next', 'T/X');
        Observer.Expect('nextlog', '');
        Observer.Expect('close', '');
        Observer.Expect('rows3', 'G1:O/,G2:A/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QuietNoSplitModalHandler')]
    procedure NewLineRM_QuietNoSplit_RunModalFiltered_Update_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, true, false, false);
        Opener.Open(Page::"LT NR Lines Quiet No Split", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);T.M(X/);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'T/A');
        Observer.Expect('prevlog', 'T.M(X/V);');
        Observer.Expect('next', 'T/X');
        Observer.Expect('nextlog', '');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:A/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    procedure NewLineRM_QuietNoSplit_TrapRunFiltered_Update_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
        Lines: TestPage "LT NR Lines Quiet No Split";
    begin
        Initialize(true, true, false, false);
        Lines.Trap();
        Opener.Open(Page::"LT NR Lines Quiet No Split", 1, false);
        DriveQuietNoSplit(Lines);
        Lines.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', '');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', '');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);T.M(X/);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'T/A');
        Observer.Expect('prevlog', 'T.M(X/V);');
        Observer.Expect('next', 'T/X');
        Observer.Expect('nextlog', '');
        Observer.Expect('close', '');
        Observer.Expect('rows3', 'G1:O/,G2:A/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoggedModalHandler')]
    procedure NewLineRM_Logged_RunModalFiltered_Update_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, true, false, false);
        Opener.Open(Page::"LT NR Lines Logged", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', 'P.AGR(A);P.AGR(A);P.AGCR(A);');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', 'P.NEW;P.AGCR();');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);P.V(T);P.MOD(X/);T.M(X/);P.V.end;P.AGR(X);P.AGR(A);P.AGR(X);P.AGR(X);P.AGCR(X);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'T/A');
        Observer.Expect('prevlog', 'P.MOD(X/V);T.M(X/V);P.AGR(A);P.AGR(A);P.AGCR(A);');
        Observer.Expect('next', 'T/X');
        Observer.Expect('nextlog', 'P.AGR(X);P.AGR(X);P.AGCR(X);');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:A/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoggedModalHandler')]
    procedure NewLineRM_Logged_RunModalRangeFilter_Update_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, true, false, false);
        Opener.Open(Page::"LT NR Lines Logged", 2, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', 'P.AGR(A);P.AGR(A);P.AGCR(A);');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', 'P.NEW;P.AGCR();');
        Observer.Expect('setname', 'T.V(X);T.I(:X);P.V(T);P.MOD(X/);T.M(X/);P.V.end;P.AGR(A);P.AGR(A);P.AGCR(A);');
        Observer.Expect('shown', 'A/');
        Observer.Expect('rows1', ':X/,G1:O/,G2:A/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', ':X/,G1:O/,G2:A/,');
        Observer.Expect('shown2', 'A/V');
        Observer.Expect('prev', 'F/A');
        Observer.Expect('prevlog', '');
        Observer.Expect('next', 'T/');
        Observer.Expect('nextlog', 'P.MOD(A/V);T.M(A/V);P.NEW;P.AGCR();');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', ':X/,G1:O/,G2:A/V,');
        Observer.Verify();
    end;

    [Test]
    procedure NewLineRM_Logged_TrapRunFiltered_Update_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
        Lines: TestPage "LT NR Lines Logged";
    begin
        Initialize(true, true, false, false);
        Lines.Trap();
        Opener.Open(Page::"LT NR Lines Logged", 1, false);
        DriveLogged(Lines);
        Lines.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', 'P.AGR(A);P.AGR(A);P.AGCR(A);');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', 'P.NEW;P.AGCR();');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);P.V(T);P.MOD(X/);T.M(X/);P.V.end;P.AGR(X);P.AGR(A);P.AGR(X);P.AGR(X);P.AGCR(X);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'T/A');
        Observer.Expect('prevlog', 'P.MOD(X/V);T.M(X/V);P.AGR(A);P.AGR(A);P.AGCR(A);');
        Observer.Expect('next', 'T/X');
        Observer.Expect('nextlog', 'P.AGR(X);P.AGR(X);P.AGCR(X);');
        Observer.Expect('close', '');
        Observer.Expect('rows3', 'G1:O/,G2:A/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoggedModalHandler')]
    procedure NewLineRM_Logged_RunModalFiltered_UpdateFalse_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, true, true, false);
        Opener.Open(Page::"LT NR Lines Logged", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', 'P.AGR(A);P.AGR(A);P.AGCR(A);');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', 'P.NEW;P.AGCR();');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);P.V(T);P.V.end;P.AGR(X);P.AGR(A);P.AGR(X);P.AGR(X);P.AGCR(X);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'T/A');
        Observer.Expect('prevlog', 'P.MOD(X/V);T.M(X/V);P.AGR(A);P.AGR(A);P.AGCR(A);');
        Observer.Expect('next', 'T/X');
        Observer.Expect('nextlog', 'P.AGR(X);P.AGR(X);P.AGCR(X);');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:A/,G2:X/V,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LoggedNoSplitModalHandler')]
    procedure NewLineRM_LoggedNoSplit_RunModalFiltered_Update_RowBefore()
    var
        Opener: Codeunit "LT NR Opener";
    begin
        Initialize(true, true, false, false);
        Opener.Open(Page::"LT NR Lines Logged No Split", 1, true);
        Observer.Observe('afterrun', Log.Take());
        Observer.Observe('rows3', GroupRows());
        Observer.Expect('open', 'P.AGR(A);P.AGR(A);P.AGCR(A);');
        Observer.Expect('openshown', 'A/');
        Observer.Expect('new', 'P.NEW;P.AGCR();');
        Observer.Expect('setname', 'T.V(X);T.I(G2:X);P.V(T);P.MOD(X/);T.M(X/);P.V.end;P.AGR(X);P.AGR(A);P.AGR(X);P.AGR(X);P.AGCR(X);');
        Observer.Expect('shown', 'X/');
        Observer.Expect('rows1', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('setvalue', '');
        Observer.Expect('rows2', 'G1:O/,G2:A/,G2:X/,');
        Observer.Expect('shown2', 'X/V');
        Observer.Expect('prev', 'T/A');
        Observer.Expect('prevlog', 'P.MOD(X/V);T.M(X/V);P.AGR(A);P.AGR(A);P.AGCR(A);');
        Observer.Expect('next', 'T/X');
        Observer.Expect('nextlog', 'P.AGR(X);P.AGR(X);P.AGCR(X);');
        Observer.Expect('ok', '');
        Observer.Expect('afterrun', '');
        Observer.Expect('rows3', 'G1:O/,G2:A/,G2:X/V,');
        Observer.Verify();
    end;

    // TestPage.Trap, then Page.RunModal without a ModalPageHandler, run through Codeunit.Run so that an error is caught either way.
    [Test]
    procedure NewLineRM_Quiet_TrapThenRunModal_NoModalHandler()
    var
        Lines: TestPage "LT NR Lines Quiet";
        Shown: Text;
        Ran: Boolean;
    begin
        Initialize(true, false, false, false);
        Lines.Trap();
        Ran := Codeunit.Run(Codeunit::"LT NR Modal Opener");
        Observer.Observe('runmodal raised', Log.Bool(not Ran));
        Observer.Observe('runmodal error', GetLastErrorText());
        ClearLastError();
        Observer.Observe('log', Log.Take());
        Observer.Observe('trapped page readable', Log.Bool(TryReadTrapped(Lines, Shown)));
        Observer.Observe('trapped page shows', Shown);
        Observer.Observe('read error', GetLastErrorText());
        ClearLastError();
        Observer.Observe('rows', GroupRows());
#if BC28PLUS
        Observer.Expect('runmodal raised', 'F');
        Observer.Expect('runmodal error', '');
        Observer.Expect('log', 'runmodal returned;');
        Observer.Expect('trapped page readable', 'F');
        Observer.Expect('trapped page shows', '');
        Observer.Expect('read error', 'The TestPage is not open.');
        Observer.Expect('rows', 'G1:O/,');
#else
        Observer.Expect('runmodal raised', 'T');
        Observer.Expect('runmodal error', 'Unhandled UI: ModalPage 97069');
        Observer.Expect('log', '');
        Observer.Expect('trapped page readable', 'F');
        Observer.Expect('trapped page shows', '');
        Observer.Expect('read error', 'The TestPage is not open.');
        Observer.Expect('rows', 'G1:O/,');
#endif
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadTrapped(var Lines: TestPage "LT NR Lines Quiet"; var Shown: Text)
    begin
        Shown := Lines.Name.Value() + '/' + Lines.Value.Value();
        Lines.Close();
    end;
}
