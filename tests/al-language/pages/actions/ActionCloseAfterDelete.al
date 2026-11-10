// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-close-method
// Scope: in-scope (Cloud). TestPage; PageHandler and ModalPageHandler with a TestPage.
// local object: the page actions (delete the shown rows and close, change the shown row through another record variable) are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own table 63440, log codeunit 63441, pages 63442 and 63443, test codeunit 63449
// Probe (al-runner issues 7368 and 7425): an action whose code changes the rows the page shows, and what the page does next.
//   7368: a journal Worksheet (filter on the batch in filter group 2) whose Post action deletes the lines of the batch through another record
//   variable (or through Rec), and then calls CurrPage.Close() when no line is left, else CurrPage.Update(false). Run with Page.RunModal, with
//   Page.Run and opened with OpenEdit; all lines deleted, and one of three deleted. The reading is the log (the triggers and the steps of the
//   action), whether the TestPage is still open after the action (a field read), the returned Action and the stored lines.
//   7425: a Worksheet whose first action writes a field of the selected row through another record variable (CurrPage.SetSelectionFilter,
//   Modify; the "Set Applies-to ID" shape of page "Apply Customer Entries"), with and without CurrPage.Update(false), and whose second
//   action reads Rec. The reading is what the page shows after the first action, what Rec and the stored row hold in the second action, and
//   the log. One variant filters the view on the field the action writes, so the changed row leaves the view.
//   Already pinned: testpage/Y1WorksheetPostLog.al and WbWorksheetPostDeletesLines.al (Post deletes the lines, no Close),
//   ui-handlers/TestPageModalSelfClose_Tests.al (CurrPage.Close() in an action that changes no row), pages/actions/R7114EditableBlobAction.al
//   and WfFlowFieldActionRec.al (an action whose code stores the shown row through another variable, then Close).
//   Log: C:<line> = OnAfterGetCurrRecord, R:<line> = OnAfterGetRecord, M:<line> = OnModifyRecord, Q:<action> = OnQueryClosePage, X = OnClosePage,
//   A:<step> = a step of an action.
// BC versions: 27, 28, 29

table 63440 "PNL JA Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Batch; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Amount; Decimal) { }
        field(4; "Applies-to ID"; Code[20]) { }
    }

    keys { key(PK; Batch, "Line No.") { Clustered = true; } }
}

codeunit 63441 "PNL JA Log"
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

page 63442 "PNL JA Journal"
{
    PageType = Worksheet;
    SourceTable = "PNL JA Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // Deletes every line of the batch through another record variable, as a posting codeunit does.
            action(Post)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Line: Record "PNL JA Line";
                begin
                    Line.SetRange(Batch, 'B1');
                    Line.DeleteAll();
                    Log.Add('A:deleted');
                    CloseOrUpdate();
                end;
            }
            // Deletes only the shown line through another record variable.
            action(PostCurrentLine)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Line: Record "PNL JA Line";
                begin
                    Line.Get(Rec.Batch, Rec."Line No.");
                    Line.Delete();
                    Log.Add('A:deleted');
                    CloseOrUpdate();
                end;
            }
            // Deletes every line through Rec itself.
            action(PostThroughRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.DeleteAll();
                    Log.Add('A:deleted');
                    CloseOrUpdate();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Batch, 'B1');
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Format(Rec."Line No."));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Log.Add('Q:' + Format(CloseAction));
        exit(true);
    end;

    trigger OnClosePage()
    begin
        Log.Add('X');
    end;

    local procedure CloseOrUpdate()
    begin
        if Rec.IsEmpty() then begin
            Log.Add('A:close');
            CurrPage.Close();
            Log.Add('A:after-close');
        end else begin
            Log.Add('A:update');
            CurrPage.Update(false);
        end;
    end;

    var
        Log: Codeunit "PNL JA Log";
}

page 63443 "PNL JA Entries"
{
    PageType = Worksheet;
    SourceTable = "PNL JA Line";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; Editable = false; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Applies-to ID"; Rec."Applies-to ID") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetAppliesToId)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    WriteId();
                end;
            }
            action(SetAppliesToIdUpdate)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    WriteId();
                    CurrPage.Update(false);
                end;
            }
            action(ShowOpenOnly)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.SetRange("Applies-to ID", '');
                    CurrPage.Update(false);
                end;
            }
            action(PostApplication)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Line: Record "PNL JA Line";
                begin
                    Line.SetRange("Applies-to ID", 'ME');
                    Log.Add('A:post rec=' + Format(Rec."Line No.") + '/' + Rec."Applies-to ID" + ' stored=' + Format(Line.Count()));
                    Line.ModifyAll(Amount, 0);
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

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('M:' + Format(Rec."Line No."));
    end;

    local procedure WriteId()
    var
        Line: Record "PNL JA Line";
    begin
        CurrPage.SetSelectionFilter(Line);
        if Line.FindSet(true) then
            repeat
                Line."Applies-to ID" := 'ME';
                Line.Modify();
            until Line.Next() = 0;
        Log.Add('A:set');
    end;

    var
        Log: Codeunit "PNL JA Log";
}

codeunit 63449 "PNL Action Close After Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PNL JA Log";
        Mode: Text;

    local procedure Initialize()
    var
        Line: Record "PNL JA Line";
    begin
        Line.DeleteAll();
        Observer.Discard();
        Log.Take();
        Mode := '';
    end;

    // Lines 10000, 20000, ... of batch B1 (amount 1, 2, ...), and one line of batch B2.
    local procedure Seed(Count: Integer)
    var
        Line: Record "PNL JA Line";
        i: Integer;
    begin
        for i := 1 to Count do begin
            Line.Init();
            Line.Batch := 'B1';
            Line."Line No." := i * 10000;
            Line.Amount := i;
            Line.Insert();
        end;
        Line.Init();
        Line.Batch := 'B2';
        Line."Line No." := 10000;
        Line.Amount := 99;
        Line.Insert();
    end;

    local procedure Stored(): Text
    var
        Line: Record "PNL JA Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line.Batch + '/' + Format(Line."Line No.") + '=' + Format(Line.Amount, 0, 9) + '/' + Line."Applies-to ID" + ';';
            until Line.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryInvoke(var P: TestPage "PNL JA Journal"; ActionName: Text)
    begin
        case ActionName of
            'POST':
                P.Post.Invoke();
            'CURRENT':
                P.PostCurrentLine.Invoke();
            'REC':
                P.PostThroughRec.Invoke();
        end;
    end;

    [TryFunction]
    local procedure TryReadLine(var P: TestPage "PNL JA Journal"; var Shown: Text)
    begin
        Shown := P."Line No.".Value() + '|' + P.Amount.Value();
    end;

    [TryFunction]
    local procedure TryOk(var P: TestPage "PNL JA Journal")
    begin
        P.OK().Invoke();
    end;

    // Invokes the action named in Mode, then reads a field (is the page still open) and, when it is, invokes OK.
    local procedure DriveJournal(var P: TestPage "PNL JA Journal")
    var
        Shown: Text;
    begin
        P.First();
        Observer.Observe('shown before', P."Line No.".Value());
        Log.Take();
        if TryInvoke(P, Mode) then
            Observer.Observe('invoke', 'ok')
        else
            Observer.ObserveError('invoke error');
        Observer.Observe('log of the action', Log.Take());
        if TryReadLine(P, Shown) then begin
            Observer.Observe('shown after', Shown);
            if TryOk(P) then
                Observer.Observe('OK', 'ok')
            else
                Observer.ObserveError('OK error');
        end else
            Observer.ObserveError('read after the action');
        Observer.Observe('log of the end of the handler', Log.Take());
    end;

    local procedure RunModalJournal(Count: Integer; ActionName: Text)
    var
        Line: Record "PNL JA Line";
        Result: Action;
    begin
        Seed(Count);
        Mode := ActionName;
        Line.SetRange(Batch, 'B1');
        Result := Page.RunModal(Page::"PNL JA Journal", Line);
        Observer.Observe('action', Format(Result));
        Observer.Observe('log after', Log.Take());
        Observer.Observe('stored', Stored());
    end;

    [Test]
    [HandlerFunctions('JournalModalHandler')]
    procedure Journal_RunModal_PostDeletesAllLines_CurrPageClose()
    begin
        // The reporter's steps of issue 7368.
        Initialize();
        RunModalJournal(2, 'POST');
        Observer.Expect('shown before', '10000');
        Observer.Expect('invoke', 'ok');
        Observer.Expect('log of the action', 'A:deleted A:close Q:LookupCancel X A:after-close ');
        Observer.Expect('read after the action|text', 'The TestPage is not open.');
        Observer.Expect('read after the action|code', 'TestPageNotOpened');
        Observer.Expect('log of the end of the handler', '');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('log after', '');
        Observer.Expect('stored', 'B2/10000=99/;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('JournalModalHandler')]
    procedure Journal_RunModal_PostDeletesOneLineOfOne_CurrPageClose()
    begin
        Initialize();
        RunModalJournal(1, 'CURRENT');
        Observer.Expect('shown before', '10000');
        Observer.Expect('invoke', 'ok');
        Observer.Expect('log of the action', 'A:deleted A:close Q:LookupCancel X A:after-close ');
        Observer.Expect('read after the action|text', 'The TestPage is not open.');
        Observer.Expect('read after the action|code', 'TestPageNotOpened');
        Observer.Expect('log of the end of the handler', '');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('log after', '');
        Observer.Expect('stored', 'B2/10000=99/;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('JournalModalHandler')]
    procedure Journal_RunModal_PostDeletesOneLineOfThree_Update()
    begin
        Initialize();
        RunModalJournal(3, 'CURRENT');
        Observer.Expect('shown before', '10000');
        Observer.Expect('invoke', 'ok');
        Observer.Expect('log of the action', 'A:deleted A:update C:20000 C:20000 ');
        Observer.Expect('shown after', '20000|2.00');
        Observer.Expect('OK', 'ok');
        Observer.Expect('log of the end of the handler', 'Q:LookupOK X ');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log after', '');
        Observer.Expect('stored', 'B1/20000=2/;B1/30000=3/;B2/10000=99/;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('JournalModalHandler')]
    procedure Journal_RunModal_PostDeletesThroughRec_CurrPageClose()
    begin
        Initialize();
        RunModalJournal(2, 'REC');
        Observer.Expect('shown before', '10000');
        Observer.Expect('invoke', 'ok');
        Observer.Expect('log of the action', 'A:deleted A:close Q:LookupCancel X A:after-close ');
        Observer.Expect('read after the action|text', 'The TestPage is not open.');
        Observer.Expect('read after the action|code', 'TestPageNotOpened');
        Observer.Expect('log of the end of the handler', '');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('log after', '');
        Observer.Expect('stored', 'B2/10000=99/;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('JournalRunHandler')]
    procedure Journal_Run_PostDeletesAllLines_CurrPageClose()
    var
        Line: Record "PNL JA Line";
    begin
        Initialize();
        Seed(2);
        Mode := 'POST';
        Line.SetRange(Batch, 'B1');
        Page.Run(Page::"PNL JA Journal", Line);
        Observer.Observe('log after', Log.Take());
        Observer.Observe('stored', Stored());
        Observer.Expect('shown before', '10000');
        Observer.Expect('invoke', 'ok');
        Observer.Expect('log of the action', 'A:deleted A:close Q:OK X A:after-close ');
        Observer.Expect('read after the action|text', 'The TestPage is not open.');
        Observer.Expect('read after the action|code', 'TestPageNotOpened');
        Observer.Expect('log of the end of the handler', '');
        Observer.Expect('log after', '');
        Observer.Expect('stored', 'B2/10000=99/;');
        Observer.Verify();
    end;

    [Test]
    procedure Journal_OpenEdit_PostDeletesAllLines_CurrPageClose()
    var
        P: TestPage "PNL JA Journal";
    begin
        Initialize();
        Seed(2);
        Mode := 'POST';
        P.OpenEdit();
        DriveJournal(P);
        Observer.Observe('stored', Stored());
        Observer.Expect('shown before', '10000');
        Observer.Expect('invoke', 'ok');
        Observer.Expect('log of the action', 'A:deleted A:close Q:OK X A:after-close ');
        Observer.Expect('read after the action|text', 'The TestPage is not open.');
        Observer.Expect('read after the action|code', 'TestPageNotOpened');
        Observer.Expect('log of the end of the handler', '');
        Observer.Expect('stored', 'B2/10000=99/;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure JournalModalHandler(var P: TestPage "PNL JA Journal")
    begin
        DriveJournal(P);
    end;

    [PageHandler]
    procedure JournalRunHandler(var P: TestPage "PNL JA Journal")
    begin
        DriveJournal(P);
    end;

    // ---- issue 7425: an action writes the shown row through another record variable, a second action follows ----

    local procedure DriveEntries(var P: TestPage "PNL JA Entries")
    begin
        P.First();
        if Mode.Contains('FILTER') then
            P.ShowOpenOnly.Invoke();
        Observer.Observe('shown before', P."Line No.".Value() + '|' + P."Applies-to ID".Value());
        Log.Take();
        if Mode.Contains('UPDATE') then
            P.SetAppliesToIdUpdate.Invoke()
        else
            P.SetAppliesToId.Invoke();
        Observer.Observe('log of the first action', Log.Take());
        Observer.Observe('shown after the first action', P."Line No.".Value() + '|' + P."Applies-to ID".Value());
        Observer.Observe('log of the read', Log.Take());
        P.PostApplication.Invoke();
        Observer.Observe('log of the second action', Log.Take());
        Observer.Observe('shown after the second action', P."Line No.".Value() + '|' + P.Amount.Value() + '|' + P."Applies-to ID".Value());
        Observer.Observe('log of the second read', Log.Take());
    end;

    local procedure RunModalEntries(NewMode: Text)
    var
        Line: Record "PNL JA Line";
        Result: Action;
    begin
        Seed(3);
        Mode := NewMode;
        Line.SetRange(Batch, 'B1');
        Result := Page.RunModal(Page::"PNL JA Entries", Line);
        Observer.Observe('action', Format(Result));
        Observer.Observe('log after', Log.Take());
        Observer.Observe('stored', Stored());
    end;

    [Test]
    [HandlerFunctions('EntriesModalHandler')]
    procedure Entries_RunModal_ActionWritesShownRow_ThenSecondAction()
    begin
        // The shape of issue 7425: "Set Applies-to ID", then "Post Application".
        Initialize();
        RunModalEntries('PLAIN');
        Observer.Expect('shown before', '10000|');
        Observer.Expect('log of the first action', 'R:10000 A:set R:10000 R:10000 R:20000 R:30000 R:10000 R:10000 C:10000 ');
        Observer.Expect('shown after the first action', '10000|ME');
        Observer.Expect('log of the read', '');
        Observer.Expect('log of the second action', 'R:10000 A:post rec=10000/ME stored=1 R:10000 R:10000 R:20000 R:30000 R:10000 R:10000 C:10000 ');
        Observer.Expect('shown after the second action', '10000|0.00|ME');
        Observer.Expect('log of the second read', '');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log after', '');
        Observer.Expect('stored', 'B1/10000=0/ME;B1/20000=2/;B1/30000=3/;B2/10000=99/;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EntriesModalHandler')]
    procedure Entries_RunModal_ActionWritesShownRowAndUpdates_ThenSecondAction()
    begin
        Initialize();
        RunModalEntries('UPDATE');
        Observer.Expect('shown before', '10000|');
        Observer.Expect('log of the first action', 'R:10000 A:set R:10000 R:10000 R:20000 R:30000 R:10000 R:10000 C:10000 ');
        Observer.Expect('shown after the first action', '10000|ME');
        Observer.Expect('log of the read', '');
        Observer.Expect('log of the second action', 'R:10000 A:post rec=10000/ME stored=1 R:10000 R:10000 R:20000 R:30000 R:10000 R:10000 C:10000 ');
        Observer.Expect('shown after the second action', '10000|0.00|ME');
        Observer.Expect('log of the second read', '');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log after', '');
        Observer.Expect('stored', 'B1/10000=0/ME;B1/20000=2/;B1/30000=3/;B2/10000=99/;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EntriesModalHandler')]
    procedure Entries_RunModal_FilteredOnWrittenField_ActionWritesShownRow_ThenSecondAction()
    begin
        Initialize();
        RunModalEntries('FILTER');
        Observer.Expect('shown before', '10000|');
        Observer.Expect('log of the first action', 'R:10000 A:set R:20000 R:20000 R:30000 R:20000 R:20000 C:20000 ');
        Observer.Expect('shown after the first action', '20000|');
        Observer.Expect('log of the read', '');
        Observer.Expect('log of the second action', 'R:20000 A:post rec=20000/ stored=1 R:20000 R:20000 R:30000 R:20000 R:20000 C:20000 ');
        Observer.Expect('shown after the second action', '20000|2.00|');
        Observer.Expect('log of the second read', '');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log after', '');
        Observer.Expect('stored', 'B1/10000=0/ME;B1/20000=2/;B1/30000=3/;B2/10000=99/;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('EntriesModalHandler')]
    procedure Entries_RunModal_FilteredOnWrittenField_ActionWritesShownRowAndUpdates_ThenSecondAction()
    begin
        Initialize();
        RunModalEntries('FILTER,UPDATE');
        Observer.Expect('shown before', '10000|');
        Observer.Expect('log of the first action', 'R:10000 A:set R:20000 R:20000 R:30000 R:20000 R:20000 C:20000 ');
        Observer.Expect('shown after the first action', '20000|');
        Observer.Expect('log of the read', '');
        Observer.Expect('log of the second action', 'R:20000 A:post rec=20000/ stored=1 R:20000 R:20000 R:30000 R:20000 R:20000 C:20000 ');
        Observer.Expect('shown after the second action', '20000|2.00|');
        Observer.Expect('log of the second read', '');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log after', '');
        Observer.Expect('stored', 'B1/10000=0/ME;B1/20000=2/;B1/30000=3/;B2/10000=99/;');
        Observer.Verify();
    end;

    [Test]
    procedure Entries_OpenEdit_ActionWritesShownRow_ThenSecondAction()
    var
        P: TestPage "PNL JA Entries";
    begin
        Initialize();
        Seed(3);
        Mode := 'PLAIN';
        P.OpenEdit();
        P.Filter.SetFilter(Batch, 'B1');
        DriveEntries(P);
        P.Close();
        Observer.Observe('log after', Log.Take());
        Observer.Observe('stored', Stored());
        Observer.Expect('shown before', '10000|');
        Observer.Expect('log of the first action', 'R:10000 A:set R:10000 R:10000 R:20000 R:30000 R:10000 R:10000 C:10000 ');
        Observer.Expect('shown after the first action', '10000|ME');
        Observer.Expect('log of the read', '');
        Observer.Expect('log of the second action', 'R:10000 A:post rec=10000/ME stored=1 R:10000 R:10000 R:20000 R:30000 R:10000 R:10000 C:10000 ');
        Observer.Expect('shown after the second action', '10000|0.00|ME');
        Observer.Expect('log of the second read', '');
        Observer.Expect('log after', '');
        Observer.Expect('stored', 'B1/10000=0/ME;B1/20000=2/;B1/30000=3/;B2/10000=99/;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure EntriesModalHandler(var P: TestPage "PNL JA Entries")
    begin
        DriveEntries(P);
        P.OK().Invoke();
    end;
}
