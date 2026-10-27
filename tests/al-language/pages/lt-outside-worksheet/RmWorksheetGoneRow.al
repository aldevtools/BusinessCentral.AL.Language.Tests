// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 88260 - 88265 (writer RM)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: an action that deletes every row of the source table through another record variable (with and without CurrPage.Update(false))
//   on a page that shows one stored row: a Worksheet without the new-row line (InsertAllowed = false, the shape of page 5510 "Production
//   Journal"), the same Worksheet opened for viewing and run modally, a List without the new-row line, and a Worksheet with the new-row line.
//   What the page shows afterwards (the control value, First/Last/Next), which triggers ran (log), and whether the table is empty.
//   Log: R:<line> = OnAfterGetRecord, C:<line> = OnAfterGetCurrRecord, N:<line> = OnNewRecord, Q = OnQueryClosePage, X = OnClosePage.
// Result (BC 27.5, 28.5, 29.0 alike): the action runs and empties the table. Without the new-row line (Worksheet or List, InsertAllowed =
//   false; OpenEdit, OpenView or run modally; with or without CurrPage.Update(false)) the page reads the deleted row once more (R:10000), then
//   runs OnNewRecord and OnAfterGetCurrRecord once on a blank Rec (N:0;C:0;), shows blank controls, and First/Last/Next answer No; a second
//   action runs N:0;C:0; only. A Worksheet with the new-row line runs N:0;C:0; three times and shows Line No. 0. Closing an OpenEdit or
//   OpenView worksheet runs OnQueryClosePage and OnClosePage; a modal handler that returns leaves RunModal = LookupCancel.
// Source: al-runner issue 5752 (a partner app posts a Production Journal from a ModalPageHandler).
// BC versions: 27, 28, 29

table 88260 "LT RM Ws Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

page 88261 "LT RM Ws NoNew"
{
    PageType = Worksheet;
    SourceTable = "LT RM Ws Line";
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNoCtl; Rec."Line No.") { }
                field(DescriptionCtl; Rec.Description) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteAllUpdate)
            {
                Caption = 'Delete All Lines and Update';

                trigger OnAction()
                var
                    Line: Record "LT RM Ws Line";
                begin
                    Line.DeleteAll();
                    CurrPage.Update(false);
                end;
            }
            action(DeleteAllNoUpdate)
            {
                Caption = 'Delete All Lines';

                trigger OnAction()
                var
                    Line: Record "LT RM Ws Line";
                begin
                    Line.DeleteAll();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Format(Rec."Line No."));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('Q');
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    var
        Log: Codeunit "LT RM Ws Log";
}

page 88262 "LT RM List NoNew"
{
    PageType = List;
    SourceTable = "LT RM Ws Line";
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNoCtl; Rec."Line No.") { }
                field(DescriptionCtl; Rec.Description) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteAllUpdate)
            {
                Caption = 'Delete All Lines and Update';

                trigger OnAction()
                var
                    Line: Record "LT RM Ws Line";
                begin
                    Line.DeleteAll();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Format(Rec."Line No."));
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    var
        Log: Codeunit "LT RM Ws Log";
}

page 88263 "LT RM Ws WithNew"
{
    PageType = Worksheet;
    SourceTable = "LT RM Ws Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNoCtl; Rec."Line No.") { }
                field(DescriptionCtl; Rec.Description) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteAllUpdate)
            {
                Caption = 'Delete All Lines and Update';

                trigger OnAction()
                var
                    Line: Record "LT RM Ws Line";
                begin
                    Line.DeleteAll();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Format(Rec."Line No."));
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    var
        Log: Codeunit "LT RM Ws Log";
}

codeunit 88264 "LT RM Ws Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 88265 "LT RM Ws Gone Row Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RM Ws Log";

    local procedure InsertOneLine()
    var
        Line: Record "LT RM Ws Line";
    begin
        Line.DeleteAll();
        Line."Line No." := 10000;
        Line.Description := 'Only line';
        Line.Insert();
        Log.Reset();
    end;

    local procedure LineCount(): Text
    var
        Line: Record "LT RM Ws Line";
    begin
        exit(Format(Line.Count()));
    end;

    [Test]
    procedure RM_Ws_OpenEdit_DeleteAllUpdate()
    var
        Ws: TestPage "LT RM Ws NoNew";
    begin
        InsertOneLine();
        Ws.OpenEdit();
        Observer.Observe('open shown', Ws.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        Ws.DeleteAllUpdate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count', LineCount());
        Observer.Observe('first', Format(Ws.First()));
        Observer.Observe('first log', Log.Take());
        Observer.Observe('last', Format(Ws.Last()));
        Observer.Observe('next', Format(Ws.Next()));
        Observer.Observe('moves log', Log.Take());
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('count after close', LineCount());
        Observer.Expect('open shown', '10000');
        Observer.Expect('open log', 'R:10000;R:10000;C:10000;');
        Observer.Expect('action log', 'R:10000;N:0;C:0;');
        Observer.Expect('shown after action', '|');
        Observer.Expect('count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('first log', '');
        Observer.Expect('last', 'No');
        Observer.Expect('next', 'No');
        Observer.Expect('moves log', '');
        Observer.Expect('close log', 'Q;X;');
        Observer.Expect('count after close', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Ws_OpenEdit_DeleteAllNoUpdate()
    var
        Ws: TestPage "LT RM Ws NoNew";
    begin
        InsertOneLine();
        Ws.OpenEdit();
        Log.Take();
        Ws.DeleteAllNoUpdate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count', LineCount());
        Observer.Observe('first', Format(Ws.First()));
        Observer.Observe('first log', Log.Take());
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Expect('action log', 'R:10000;N:0;C:0;');
        Observer.Expect('shown after action', '|');
        Observer.Expect('count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('first log', '');
        Observer.Expect('close log', 'Q;X;');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Ws_OpenEdit_DeleteAllUpdate_Twice()
    var
        Ws: TestPage "LT RM Ws NoNew";
    begin
        InsertOneLine();
        Ws.OpenEdit();
        Log.Take();
        Ws.DeleteAllUpdate.Invoke();
        Log.Take();
        Ws.DeleteAllUpdate.Invoke();
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('shown after second action', Ws.LineNoCtl.Value());
        Ws.Close();
        Observer.Observe('count', LineCount());
        Observer.Expect('second action log', 'N:0;C:0;');
        Observer.Expect('shown after second action', '');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RM_Ws_OpenView_DeleteAllUpdate()
    var
        Ws: TestPage "LT RM Ws NoNew";
    begin
        InsertOneLine();
        Ws.OpenView();
        Log.Take();
        Ws.DeleteAllUpdate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count', LineCount());
        Observer.Observe('first', Format(Ws.First()));
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Expect('action log', 'R:10000;N:0;C:0;');
        Observer.Expect('shown after action', '|');
        Observer.Expect('count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('close log', 'Q;X;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DeleteAllUpdateHandler')]
    procedure RM_Ws_RunModal_DeleteAllUpdate()
    var
        Result: Action;
    begin
        InsertOneLine();
        Result := Page.RunModal(Page::"LT RM Ws NoNew");
        Observer.Observe('runmodal result', Format(Result));
        Observer.Observe('after runmodal log', Log.Take());
        Observer.Observe('count', LineCount());
        Observer.Expect('handler first', 'Yes');
        Observer.Expect('handler open log', 'R:10000;R:10000;C:10000;');
        Observer.Expect('handler action log', 'R:10000;N:0;C:0;');
        Observer.Expect('handler shown', '');
        Observer.Expect('handler first after', 'No');
        Observer.Expect('runmodal result', 'LookupCancel');
        Observer.Expect('after runmodal log', 'Q;X;');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure DeleteAllUpdateHandler(var Ws: TestPage "LT RM Ws NoNew")
    begin
        Observer.Observe('handler first', Format(Ws.First()));
        Observer.Observe('handler open log', Log.Take());
        Ws.DeleteAllUpdate.Invoke();
        Observer.Observe('handler action log', Log.Take());
        Observer.Observe('handler shown', Ws.LineNoCtl.Value());
        Observer.Observe('handler first after', Format(Ws.First()));
    end;

    [Test]
    procedure RM_ListNoNew_OpenEdit_DeleteAllUpdate()
    var
        List: TestPage "LT RM List NoNew";
    begin
        InsertOneLine();
        List.OpenEdit();
        Log.Take();
        List.DeleteAllUpdate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', List.LineNoCtl.Value() + '|' + List.DescriptionCtl.Value());
        Observer.Observe('count', LineCount());
        Observer.Observe('first', Format(List.First()));
        List.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Expect('action log', 'R:10000;N:0;C:0;');
        Observer.Expect('shown after action', '|');
        Observer.Expect('count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('close log', 'X;');
        Observer.Verify();
    end;

    [Test]
    procedure RM_WsWithNew_OpenEdit_DeleteAllUpdate()
    var
        Ws: TestPage "LT RM Ws WithNew";
    begin
        InsertOneLine();
        Ws.OpenEdit();
        Log.Take();
        Ws.DeleteAllUpdate.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count', LineCount());
        Observer.Observe('first', Format(Ws.First()));
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('count after close', LineCount());
        Observer.Expect('action log', 'R:10000;N:0;C:0;N:0;C:0;N:0;C:0;');
        Observer.Expect('shown after action', '0|');
        Observer.Expect('count', '0');
        Observer.Expect('first', 'No');
        Observer.Expect('close log', 'X;');
        Observer.Expect('count after close', '0');
        Observer.Verify();
    end;

    // ---- Writer SH, al-runner issue 5953: a List with Editable = false (and Insert/Delete/ModifyAllowed = false) opened with OpenView whose
    // action deletes the row it stands on through another record variable and calls CurrPage.Update(false); a temporary Worksheet whose
    // repeater shows its rows as a tree (ShowAsTree, IndentationColumn) and whose action empties Rec without CurrPage.Update.

    [Test]
    procedure SH_ListViewNotEditable_OpenView_DeleteCurrentUpdate()
    var
        List: TestPage "LT SH List View NoNew";
    begin
        InsertOneLine();
        List.OpenView();
        Observer.Observe('open shown', List.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        List.DeleteCurrent.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', List.LineNoCtl.Value() + '|' + List.DescriptionCtl.Value());
        Observer.Observe('count', LineCount());
        Observer.Observe('first', Format(List.First()));
        Observer.Observe('first log', Log.Take());
        List.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure SH_TreeWorksheetTemp_OpenEdit_EmptyRecNoUpdate()
    var
        Ws: TestPage "LT SH Tree Ws";
    begin
        Log.Reset();
        Ws.OpenEdit();
        Observer.Observe('open shown', Ws.LineNoCtl.Value());
        Observer.Observe('open log', Log.Take());
        Ws.EmptyRec.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown after action', Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('first', Format(Ws.First()));
        Observer.Observe('first log', Log.Take());
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure SH_TreeWorksheetTemp_OpenEdit_EmptyRecTwice()
    var
        Ws: TestPage "LT SH Tree Ws";
    begin
        Log.Reset();
        Ws.OpenEdit();
        Log.Take();
        Ws.EmptyRec.Invoke();
        Log.Take();
        Ws.EmptyRec.Invoke();
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('first', Format(Ws.First()));
        Ws.Close();
        Observer.Finish();
    end;

    // ---- Writer SH, al-runner issue 5960: a Worksheet with the new-row line (AutoSplitKey, DelayedInsert) opened on an empty table; an
    // action inserts two lines through another record variable without CurrPage.Update, a second action deletes all lines and calls
    // CurrPage.Update(false) (the flow of page 7372 "Bin Creation Worksheet").

    local procedure ShOpenEmptyFilled(var Ws: TestPage "LT SH Ws Filled By Action")
    var
        Line: Record "LT RM Ws Line";
    begin
        Line.DeleteAll();
        Log.Reset();
        Ws.OpenEdit();
        Observer.Observe('open shown', Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('open log', Log.Take());
        Ws.Calculate.Invoke();
        Observer.Observe('calculate log', Log.Take());
        Observer.Observe('shown after calculate', Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count after calculate', LineCount());
    end;

    [Test]
    procedure SH_WsWithNew_EmptyOpen_FillThenDeleteAllUpdate()
    var
        Ws: TestPage "LT SH Ws Filled By Action";
    begin
        ShOpenEmptyFilled(Ws);
        Ws.Create.Invoke();
        Observer.Observe('create log', Log.Take());
        Observer.Observe('shown after create', Ws.LineNoCtl.Value() + '|' + Ws.DescriptionCtl.Value());
        Observer.Observe('count after create', LineCount());
        Observer.Observe('first', Format(Ws.First()));
        Ws.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('count after close', LineCount());
        Observer.Finish();
    end;

    [Test]
    procedure SH_WsWithNew_EmptyOpen_FillThenWalk()
    var
        Ws: TestPage "LT SH Ws Filled By Action";
        Rows: Text;
    begin
        ShOpenEmptyFilled(Ws);
        if Ws.First() then
            repeat
                Rows += Ws.LineNoCtl.Value() + ',';
            until not Ws.Next();
        Observer.Observe('rows', Rows);
        Observer.Observe('walk log', Log.Take());
        Ws.Close();
        Observer.Observe('count after close', LineCount());
        Observer.Finish();
    end;
}

page 89439 "LT SH Ws Filled By Action"
{
    PageType = Worksheet;
    SourceTable = "LT RM Ws Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNoCtl; Rec."Line No.") { }
                field(DescriptionCtl; Rec.Description) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calculate)
            {
                Caption = 'Calculate';

                trigger OnAction()
                var
                    Line: Record "LT RM Ws Line";
                begin
                    Line."Line No." := 10000;
                    Line.Description := 'First';
                    Line.Insert();
                    Line."Line No." := 20000;
                    Line.Description := 'Second';
                    Line.Insert();
                end;
            }
            action(Create)
            {
                Caption = 'Create';

                trigger OnAction()
                var
                    Line: Record "LT RM Ws Line";
                begin
                    Line.DeleteAll();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Format(Rec."Line No."));
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    var
        Log: Codeunit "LT RM Ws Log";
}

page 89431 "LT SH List View NoNew"
{
    PageType = List;
    SourceTable = "LT RM Ws Line";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNoCtl; Rec."Line No.") { }
                field(DescriptionCtl; Rec.Description) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteCurrent)
            {
                Caption = 'Delete Current Line and Update';

                trigger OnAction()
                var
                    Line: Record "LT RM Ws Line";
                begin
                    Line.Get(Rec."Line No.");
                    Line.Delete();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Format(Rec."Line No."));
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    var
        Log: Codeunit "LT RM Ws Log";
}

table 89432 "LT SH Tree Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Description; Text[50]) { }
        field(3; Indentation; Integer) { }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

page 89433 "LT SH Tree Ws"
{
    PageType = Worksheet;
    SourceTable = "LT SH Tree Line";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                IndentationColumn = Rec.Indentation;
                IndentationControls = DescriptionCtl;
                ShowAsTree = true;
                field(LineNoCtl; Rec."Line No.") { }
                field(DescriptionCtl; Rec.Description) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EmptyRec)
            {
                Caption = 'Empty Rec';

                trigger OnAction()
                begin
                    Rec.Reset();
                    Rec.DeleteAll();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec."Line No." := 10000;
        Rec.Description := 'Only line';
        Rec.Insert();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Format(Rec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Format(Rec."Line No."));
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    var
        Log: Codeunit "LT RM Ws Log";
}
