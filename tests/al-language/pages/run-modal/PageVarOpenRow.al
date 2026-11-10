// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run--method
// Scope: in-scope (Cloud). PageHandler and ModalPageHandler with a TestPage.
// local object: the page procedures that position or fill Rec before the page runs, and the page shapes, are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own table 63420, log codeunit 63421, pages 63422 to 63427, test codeunit 63429
// Probe (al-runner issues 7474, 7443 and 7420): which row a page opens on when its own procedure set up Rec before the page ran.
//   7474: a Page variable whose procedure calls Rec.Get (no SetRecord) and is then run with RunModal: a StandardDialog, a Card and a List over
//   a stored table that holds rows before that row. Control cases: SetRecord, and Get of the first row. The reading is the row the handler
//   sees, the log, the returned Action, and the row and page variable the page's procedure returns afterwards.
//   7443: a list whose procedure calls CurrPage.Run() or CurrPage.RunModal(), over an empty temporary source, a temporary source of two rows
//   and an empty stored table; the handler types a row on the new-row line. The reading is the row the page opens on, the log, and the rows
//   the page variable's Rec holds after the page closed.
//   7420: a temporary Worksheet with SourceTableView = sorting(Seq) and InsertAllowed = false whose procedure inserted the rows before Run()
//   or RunModal(), so Rec stands on the row inserted last, which is a middle row of the view. The reading is the row it opens on, the rows
//   First / Next walk through, and the log.
//   Already pinned: pages/onopenpage-moves-rec/QtTempWorksheetObjects.al (a temporary Worksheet in the primary key, and SetCurrentKey then Get,
//   RunModal), ui-handlers/Y72PageHandlerSetUpVariable.al (Page-typed handlers), pages/currpage/PageVarSetRecordTableView.al (SetRecord and
//   SetTableView), pages/currpage/Y50UpdateNeverRun.al (CurrPage.RunModal() of a NavigatePage with no source table).
//   Log: O:<code> = Rec at the end of OnOpenPage, R:<code> = OnAfterGetRecord, C:<code> = OnAfterGetCurrRecord, N = OnNewRecord,
//   I:<code> = OnInsertRecord, X = OnClosePage.
// BC versions: 27, 28, 29

table 63420 "PNL OR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Seq; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(BySeq; Seq) { }
    }
}

codeunit 63421 "PNL OR Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ' ';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 63422 "PNL OR Dialog"
{
    PageType = StandardDialog;
    SourceTable = "PNL OR Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; Editable = false; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Weight; Weight) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if HasRow then
            Weight := 7;
        Log.Add('O:' + Rec."Code");
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Code");
    end;

    procedure SetRow(RowCode: Code[10])
    begin
        Rec.Get(RowCode);
        HasRow := true;
    end;

    procedure GetValues(): Text
    begin
        exit(Rec."Code" + '|' + Rec.Name + '|' + Format(Weight, 0, 9));
    end;

    var
        Log: Codeunit "PNL OR Log";
        HasRow: Boolean;
        Weight: Decimal;
}

page 63423 "PNL OR Card"
{
    PageType = Card;
    SourceTable = "PNL OR Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; Editable = false; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Weight; Weight) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if HasRow then
            Weight := 7;
        Log.Add('O:' + Rec."Code");
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Code");
    end;

    procedure SetRow(RowCode: Code[10])
    begin
        Rec.Get(RowCode);
        HasRow := true;
    end;

    procedure GetValues(): Text
    begin
        exit(Rec."Code" + '|' + Rec.Name + '|' + Format(Weight, 0, 9));
    end;

    var
        Log: Codeunit "PNL OR Log";
        HasRow: Boolean;
        Weight: Decimal;
}

page 63424 "PNL OR List"
{
    PageType = List;
    SourceTable = "PNL OR Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; Editable = false; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Weight; Weight) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if HasRow then
            Weight := 7;
        Log.Add('O:' + Rec."Code");
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Code");
    end;

    procedure SetRow(RowCode: Code[10])
    begin
        Rec.Get(RowCode);
        HasRow := true;
    end;

    procedure GetValues(): Text
    begin
        exit(Rec."Code" + '|' + Rec.Name + '|' + Format(Weight, 0, 9));
    end;

    var
        Log: Codeunit "PNL OR Log";
        HasRow: Boolean;
        Weight: Decimal;
}

page 63425 "PNL OR Temp Pick"
{
    PageType = List;
    SourceTable = "PNL OR Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Tag = '' then
            Error('No tag was set.');
        Log.Add('O:' + Rec."Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Name := 'new';
        Log.Add('N');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Code");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('I:' + Rec."Code");
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    procedure Preload(Count: Integer)
    var
        i: Integer;
    begin
        for i := 1 to Count do begin
            Rec.Init();
            Rec."Code" := 'P' + Format(i);
            Rec.Name := 'preloaded';
            Rec.Insert();
        end;
    end;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    procedure RunPick(NewTag: Text)
    begin
        Tag := NewTag;
        CurrPage.Run();
    end;

    procedure RunPickModal(NewTag: Text)
    begin
        Tag := NewTag;
        CurrPage.RunModal();
    end;

    procedure Dump() Result: Text
    begin
        Result := 'on ' + Rec."Code" + ': ';
        if Rec.FindSet() then
            repeat
                Result += Rec."Code" + '=' + Rec.Name + ';';
            until Rec.Next() = 0;
    end;

    var
        Log: Codeunit "PNL OR Log";
        Tag: Text;
}

page 63426 "PNL OR Stored Pick"
{
    PageType = List;
    SourceTable = "PNL OR Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Tag = '' then
            Error('No tag was set.');
        Log.Add('O:' + Rec."Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Name := 'new';
        Log.Add('N');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Code");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('I:' + Rec."Code");
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    procedure Preload(Count: Integer)
    var
        i: Integer;
    begin
        for i := 1 to Count do begin
            Rec.Init();
            Rec."Code" := 'P' + Format(i);
            Rec.Name := 'preloaded';
            Rec.Insert();
        end;
    end;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    procedure RunPick(NewTag: Text)
    begin
        Tag := NewTag;
        CurrPage.Run();
    end;

    procedure RunPickModal(NewTag: Text)
    begin
        Tag := NewTag;
        CurrPage.RunModal();
    end;

    procedure Dump() Result: Text
    begin
        Result := 'on ' + Rec."Code" + ': ';
        if Rec.FindSet() then
            repeat
                Result += Rec."Code" + '=' + Rec.Name + ';';
            until Rec.Next() = 0;
    end;

    var
        Log: Codeunit "PNL OR Log";
        Tag: Text;
}

page 63427 "PNL OR Temp Ws"
{
    PageType = Worksheet;
    SourceTable = "PNL OR Row";
    SourceTableTemporary = true;
    SourceTableView = sorting(Seq);
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; Editable = false; }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field(Seq; Rec.Seq) { ApplicationArea = All; Editable = false; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Code");
    end;

    procedure SetSource(var Source: Record "PNL OR Row" temporary)
    begin
        if not Rec.IsEmpty() then
            Rec.DeleteAll();
        Source.FindSet();
        repeat
            Rec.Init();
            Rec.TransferFields(Source);
            Rec.Insert();
        until Source.Next() = 0;
    end;

    procedure Dump() Result: Text
    begin
        Result := 'on ' + Rec."Code" + ': ';
        if Rec.FindSet() then
            repeat
                Result += Rec."Code" + '=' + Rec.Name + ';';
            until Rec.Next() = 0;
    end;

    var
        Log: Codeunit "PNL OR Log";
}

codeunit 63429 "PNL Page Var Open Row"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PNL OR Log";

    local procedure Initialize()
    var
        Row: Record "PNL OR Row";
    begin
        Row.DeleteAll();
        Observer.Discard();
        Log.Take();
    end;

    // Stored rows A, B, C, D.
    local procedure Seed()
    var
        Row: Record "PNL OR Row";
        i: Integer;
    begin
        for i := 1 to 4 do begin
            Row.Init();
            Row."Code" := CopyStr('ABCD', i, 1);
            Row.Name := 'name ' + Row."Code";
            Row.Seq := i;
            Row.Insert();
        end;
    end;

    local procedure Stored(): Text
    var
        Row: Record "PNL OR Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Row."Code" + '=' + Row.Name + ';';
            until Row.Next() = 0;
        exit(Result);
    end;

    // ---- issue 7474: Rec.Get in a procedure of the Page variable, then RunModal ----

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Dialog_GetThirdRowInProcedure_RunModal()
    var
        Dlg: Page "PNL OR Dialog";
        Result: Action;
    begin
        // The reporter's steps of issue 7474.
        Initialize();
        Seed();
        Clear(Dlg);
        Dlg.SetRow('C');
        Result := Dlg.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Observe('values after', Dlg.GetValues());
        Observer.Observe('log after', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Dialog_GetFirstRowInProcedure_RunModal()
    var
        Dlg: Page "PNL OR Dialog";
        Result: Action;
    begin
        Initialize();
        Seed();
        Dlg.SetRow('A');
        Result := Dlg.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Observe('values after', Dlg.GetValues());
        Observer.Observe('log after', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Dialog_SetRecordThirdRow_RunModal()
    var
        Row: Record "PNL OR Row";
        Dlg: Page "PNL OR Dialog";
        Result: Action;
    begin
        Initialize();
        Seed();
        Row.Get('C');
        Dlg.SetRecord(Row);
        Result := Dlg.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Observe('values after', Dlg.GetValues());
        Observer.Observe('log after', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Dialog_NoRowSet_RunModal()
    var
        Dlg: Page "PNL OR Dialog";
        Result: Action;
    begin
        Initialize();
        Seed();
        Result := Dlg.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Observe('values after', Dlg.GetValues());
        Observer.Observe('log after', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_GetThirdRowInProcedure_RunModal()
    var
        Card: Page "PNL OR Card";
        Result: Action;
    begin
        Initialize();
        Seed();
        Card.SetRow('C');
        Result := Card.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Observe('values after', Card.GetValues());
        Observer.Observe('log after', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure List_GetThirdRowInProcedure_RunModal()
    var
        List: Page "PNL OR List";
        Result: Action;
    begin
        Initialize();
        Seed();
        List.SetRow('C');
        Result := List.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Observe('values after', List.GetValues());
        Observer.Observe('log after', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListRunHandler')]
    procedure List_GetThirdRowInProcedure_Run()
    var
        List: Page "PNL OR List";
    begin
        Initialize();
        Seed();
        List.SetRow('C');
        List.Run();
        Observer.Observe('log after', Log.Take());
        Observer.Finish();
    end;

    [ModalPageHandler]
    procedure DialogHandler(var Dlg: TestPage "PNL OR Dialog")
    begin
        Observer.Observe('log at handler', Log.Take());
        Observer.Observe('shown', Dlg."Code".Value() + '|' + Dlg.Name.Value() + '|' + Dlg.Weight.Value());
        Dlg.Weight.SetValue(51);
        Dlg.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CardHandler(var Card: TestPage "PNL OR Card")
    begin
        Observer.Observe('log at handler', Log.Take());
        Observer.Observe('shown', Card."Code".Value() + '|' + Card.Name.Value() + '|' + Card.Weight.Value());
        Card.Weight.SetValue(51);
        Card.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ListHandler(var List: TestPage "PNL OR List")
    begin
        Observer.Observe('log at handler', Log.Take());
        Observer.Observe('shown', List."Code".Value() + '|' + List.Name.Value() + '|' + List.Weight.Value());
        List.Weight.SetValue(51);
        List.OK().Invoke();
    end;

    [PageHandler]
    procedure ListRunHandler(var List: TestPage "PNL OR List")
    begin
        Observer.Observe('log at handler', Log.Take());
        Observer.Observe('shown', List."Code".Value() + '|' + List.Name.Value() + '|' + List.Weight.Value());
        Observer.Observe('next', Format(List.Next()));
        Observer.Observe('shown after next', List."Code".Value());
    end;

    // ---- issue 7443: CurrPage.Run() and CurrPage.RunModal() in a procedure of the page ----

    [TryFunction]
    local procedure TryTypeTemp(var Pick: TestPage "PNL OR Temp Pick"; var Moved: Boolean)
    begin
        Pick."Code".Value := 'T1';
        Moved := Pick.Next();
    end;

    [TryFunction]
    local procedure TryTypeStored(var Pick: TestPage "PNL OR Stored Pick"; var Moved: Boolean)
    begin
        Pick."Code".Value := 'T1';
        Moved := Pick.Next();
    end;

    [Test]
    [HandlerFunctions('TempPickHandler')]
    procedure TempPick_Empty_CurrPageRun_HandlerTypesRow()
    var
        Pick: Page "PNL OR Temp Pick";
    begin
        // The reporter's steps of issue 7443.
        Initialize();
        Pick.RunPick('doc');
        Observer.Observe('log after', Log.Take());
        Observer.Observe('page rec after', Pick.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TempPickHandler')]
    procedure TempPick_Empty_VariableRun_HandlerTypesRow()
    var
        Pick: Page "PNL OR Temp Pick";
    begin
        Initialize();
        Pick.SetTag('doc');
        Pick.Run();
        Observer.Observe('log after', Log.Take());
        Observer.Observe('page rec after', Pick.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TempPickModalHandler')]
    procedure TempPick_Empty_CurrPageRunModal_HandlerTypesRow()
    var
        Pick: Page "PNL OR Temp Pick";
    begin
        Initialize();
        Pick.RunPickModal('doc');
        Observer.Observe('log after', Log.Take());
        Observer.Observe('page rec after', Pick.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('TempPickHandler')]
    procedure TempPick_TwoRowsPreloaded_CurrPageRun_HandlerTypesRow()
    var
        Pick: Page "PNL OR Temp Pick";
    begin
        Initialize();
        Pick.Preload(2);
        Pick.RunPick('doc');
        Observer.Observe('log after', Log.Take());
        Observer.Observe('page rec after', Pick.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure TempPick_Empty_CurrPageRun_NoTag_OnOpenPageError()
    var
        Pick: Page "PNL OR Temp Pick";
    begin
        Initialize();
        asserterror Pick.RunPick('');
        Observer.ObserveError('run');
        Observer.Observe('log after', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('StoredPickHandler')]
    procedure StoredPick_EmptyTable_CurrPageRun_HandlerTypesRow()
    var
        Pick: Page "PNL OR Stored Pick";
    begin
        Initialize();
        Pick.RunPick('doc');
        Observer.Observe('log after', Log.Take());
        Observer.Observe('page rec after', Pick.Dump());
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [PageHandler]
    procedure TempPickHandler(var Pick: TestPage "PNL OR Temp Pick")
    var
        Moved: Boolean;
    begin
        Observer.Observe('log at handler', Log.Take());
        Observer.Observe('opened on', Pick."Code".Value() + '|' + Pick.Name.Value());
        if TryTypeTemp(Pick, Moved) then
            Observer.Observe('typed, next', Format(Moved))
        else
            Observer.ObserveError('type error');
        Observer.Observe('log after typing', Log.Take());
    end;

    [ModalPageHandler]
    procedure TempPickModalHandler(var Pick: TestPage "PNL OR Temp Pick")
    var
        Moved: Boolean;
    begin
        Observer.Observe('log at handler', Log.Take());
        Observer.Observe('opened on', Pick."Code".Value() + '|' + Pick.Name.Value());
        if TryTypeTemp(Pick, Moved) then
            Observer.Observe('typed, next', Format(Moved))
        else
            Observer.ObserveError('type error');
        Observer.Observe('log after typing', Log.Take());
        Pick.OK().Invoke();
    end;

    [PageHandler]
    procedure StoredPickHandler(var Pick: TestPage "PNL OR Stored Pick")
    var
        Moved: Boolean;
    begin
        Observer.Observe('log at handler', Log.Take());
        Observer.Observe('opened on', Pick."Code".Value() + '|' + Pick.Name.Value());
        if TryTypeStored(Pick, Moved) then
            Observer.Observe('typed, next', Format(Moved))
        else
            Observer.ObserveError('type error');
        Observer.Observe('log after typing', Log.Take());
    end;

    // ---- issue 7420: a temporary Worksheet sorted by a secondary key, filled by a procedure before Run ----

    // Inserted in the order A, B, C, D (Rec is left on D). Seq: A 30, B 10, C 40, D 20, so the view shows B, D, A, C.
    local procedure FillSource(var Source: Record "PNL OR Row" temporary; Count: Integer)
    var
        i: Integer;
    begin
        for i := 1 to Count do begin
            Source.Init();
            Source."Code" := CopyStr('ABCD', i, 1);
            Source.Name := 'name ' + Source."Code";
            case i of
                1:
                    Source.Seq := 30;
                2:
                    Source.Seq := 10;
                3:
                    Source.Seq := 40;
                4:
                    Source.Seq := 20;
            end;
            Source.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryWsOk(var Ws: TestPage "PNL OR Temp Ws")
    begin
        Ws.OK().Invoke();
    end;

    local procedure ReadWs(var Ws: TestPage "PNL OR Temp Ws")
    var
        Rows: Text;
    begin
        Observer.Observe('log at handler', Log.Take());
        Observer.Observe('opened on', Ws."Code".Value());
        if Ws.First() then
            repeat
                Rows += Ws."Code".Value() + ',';
            until not Ws.Next();
        Observer.Observe('rows', Rows);
        Observer.Observe('log of the walk', Log.Take());
        Ws.First();
        Ws.Name.SetValue('changed');
        Observer.Observe('row edited', Ws."Code".Value() + '|' + Ws.Name.Value());
        Observer.Observe('log of the edit', Log.Take());
        if TryWsOk(Ws) then
            Observer.Observe('OK', 'ok')
        else
            Observer.ObserveError('OK error');
    end;

    [Test]
    [HandlerFunctions('WsHandler')]
    procedure TempWs_SecondaryKeyView_FilledBeforeRun_Run()
    var
        Source: Record "PNL OR Row" temporary;
        Ws: Page "PNL OR Temp Ws";
    begin
        // The reporter's steps of issue 7420.
        Initialize();
        FillSource(Source, 4);
        Source.FindSet();
        Ws.SetSource(Source);
        Ws.Run();
        Observer.Observe('log after', Log.Take());
        Observer.Observe('page rec after', Ws.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsModalHandler')]
    procedure TempWs_SecondaryKeyView_FilledBeforeRun_RunModal()
    var
        Source: Record "PNL OR Row" temporary;
        Ws: Page "PNL OR Temp Ws";
        Result: Action;
    begin
        Initialize();
        FillSource(Source, 4);
        Source.FindSet();
        Ws.SetSource(Source);
        Result := Ws.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Observe('log after', Log.Take());
        Observer.Observe('page rec after', Ws.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsHandler')]
    procedure TempWs_SecondaryKeyView_LastInsertedIsFirstOfView_Run()
    var
        Source: Record "PNL OR Row" temporary;
        Ws: Page "PNL OR Temp Ws";
    begin
        // Two rows: A (Seq 30), B (Seq 10). Rec is left on B, the first row of the view.
        Initialize();
        FillSource(Source, 2);
        Source.FindSet();
        Ws.SetSource(Source);
        Ws.Run();
        Observer.Observe('log after', Log.Take());
        Observer.Observe('page rec after', Ws.Dump());
        Observer.Finish();
    end;

    [PageHandler]
    procedure WsHandler(var Ws: TestPage "PNL OR Temp Ws")
    begin
        ReadWs(Ws);
    end;

    [ModalPageHandler]
    procedure WsModalHandler(var Ws: TestPage "PNL OR Temp Ws")
    begin
        ReadWs(Ws);
    end;
}
