// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-class
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables, list pages and the log of pages/lt-y80-gone-rows/Y80GoneRows.al ("LT Y80 Row", "LT Y80 Log", "LT Y80 List All", "LT Y80 List NoNew", "LT Y80 List ReadOnly", "LT Y80 List NoInsMod"); own objects 94729, 94731 - 94733, 94742 and 94743, test codeunit 94730
// Probe (writer Y89, from the runtime lane rt-pages-1103g). (1) ONE move (Next, Previous, First, Last or GoToKey) on its own, as the first thing that happens, on a List that stands on its blank line
// because an action deleted its only row: pages/lt-y80-gone-rows/Y80GoneRows.al tries the moves one after the other, so the answer of a single move after the
// action is not pinned there. Per list shape, OpenEdit and OpenView, the action deleting every row with and without CurrPage.Update(false). (2) the CloseAction that
// OnQueryClosePage of a Card receives when BC closes the page by force (the page row is gone), with the trigger answering true and false, for the actions
// that delete the row, and the same for a regular Close, a modal Run and an OK / Cancel action. (3) (runtime lane rt-gone-last) the same forced close when the
// deleted row was the LAST row of the view and rows are left only before it (rows 10, 20, 30, the card on 30): the CloseAction and Rec.Id in
// OnQueryClosePage, Rec.Id in OnClosePage, and whether OnAfterGetRecord / OnAfterGetCurrRecord run for another row (page 94729), opened
// with OpenEdit, OpenView and Page.RunModal; and on the first row (rows after it) for comparison.
// BC versions: 27, 28, 29

table 94731 "LT Y89 Close Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { AutoIncrement = true; }
        field(2; Entry; Text[250]) { }
    }
    keys { key(PK; "Line No.") { Clustered = true; } }
}

page 94732 "LT Y89 Card Close True"
{
    PageType = Card;
    SourceTable = "LT Y80 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteAllAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "LT Y80 Row";
                begin
                    Row.DeleteAll(true);
                end;
            }
            action(DeleteAllUpdateAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "LT Y80 Row";
                begin
                    Row.DeleteAll(true);
                    CurrPage.Update(false);
                end;
            }
            action(DeleteCurrentAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
            action(CloseAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Record "LT Y89 Close Log";
    begin
        Log.Init();
        Log.Entry := 'Q:' + Format(CloseAction) + ':' + Format(Rec.Id);
        Log.Insert();
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Record "LT Y89 Close Log";
    begin
        Log.Init();
        Log.Entry := 'X';
        Log.Insert();
    end;
}

table 94742 "LT Y89 Last Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { AutoIncrement = true; }
        field(2; Entry; Text[250]) { }
    }
    keys { key(PK; "Line No.") { Clustered = true; } }
}

page 94743 "LT Y89 Card Last True"
{
    PageType = Card;
    SourceTable = "LT Y80 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteCurrentAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        AddLog('Q:' + Format(CloseAction) + ':' + Format(Rec.Id));
        exit(true);
    end;

    trigger OnClosePage()
    begin
        AddLog('X:' + Format(Rec.Id));
    end;

    local procedure AddLog(Entry: Text)
    var
        Log: Record "LT Y89 Last Log";
    begin
        Log.Init();
        Log.Entry := CopyStr(Entry, 1, MaxStrLen(Log.Entry));
        Log.Insert();
    end;
}

page 94729 "LT Y89 Card Close Get"
{
    PageType = Card;
    SourceTable = "LT Y80 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteCurrentAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AddLog('G:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        AddLog('C:' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        AddLog('Q:' + Format(CloseAction) + ':' + Format(Rec.Id));
        exit(true);
    end;

    trigger OnClosePage()
    begin
        AddLog('X:' + Format(Rec.Id));
    end;

    local procedure AddLog(Entry: Text)
    var
        Log: Record "LT Y89 Last Log";
    begin
        Log.Init();
        Log.Entry := CopyStr(Entry, 1, MaxStrLen(Log.Entry));
        Log.Insert();
    end;
}

page 94733 "LT Y89 Card Close False"
{
    PageType = Card;
    SourceTable = "LT Y80 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteAllAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "LT Y80 Row";
                begin
                    Row.DeleteAll(true);
                end;
            }
            action(DeleteAllUpdateAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "LT Y80 Row";
                begin
                    Row.DeleteAll(true);
                    CurrPage.Update(false);
                end;
            }
            action(DeleteCurrentAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
            action(CloseAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Record "LT Y89 Close Log";
    begin
        Log.Init();
        Log.Entry := 'Q:' + Format(CloseAction) + ':' + Format(Rec.Id);
        Log.Insert();
        exit(false);
    end;

    trigger OnClosePage()
    var
        Log: Record "LT Y89 Close Log";
    begin
        Log.Init();
        Log.Entry := 'X';
        Log.Insert();
    end;
}

codeunit 94730 "LT Y89 Gone Single Move"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        ModalAction: Text;

    local procedure Seed(Count: Integer)
    var
        Row: Record "LT Y80 Row";
        Log: Record "LT Y80 Log";
        CloseLog: Record "LT Y89 Close Log";
        LastLog: Record "LT Y89 Last Log";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to Count do begin
            Row.Id := I * 10;
            Row.Txt := 'r' + Format(I * 10);
            Row.Insert();
        end;
        Log.DeleteAll();
        CloseLog.DeleteAll();
        LastLog.DeleteAll();
    end;

    local procedure TakeLog(): Text
    var
        Log: Record "LT Y80 Log";
        Result: Text;
    begin
        if Log.FindSet() then
            repeat
                if Result <> '' then
                    Result += ';';
                Result += Log.Entry;
            until Log.Next() = 0;
        Log.DeleteAll();
        exit(Result);
    end;

    local procedure TakeLastLog(): Text
    var
        Log: Record "LT Y89 Last Log";
        Result: Text;
    begin
        if Log.FindSet() then
            repeat
                if Result <> '' then
                    Result += ';';
                Result += Log.Entry;
            until Log.Next() = 0;
        Log.DeleteAll();
        exit(Result);
    end;

    local procedure TakeCloseLog(): Text
    var
        Log: Record "LT Y89 Close Log";
        Result: Text;
    begin
        if Log.FindSet() then
            repeat
                if Result <> '' then
                    Result += ';';
                Result += Log.Entry;
            until Log.Next() = 0;
        Log.DeleteAll();
        exit(Result);
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT Y80 Row";
    begin
        exit(Format(Row.Count()));
    end;

    [TryFunction]
    local procedure TryAll(var P: TestPage "LT Y80 List All"; Which: Text; var Result: Text)
    begin
        case Which of
            'next':
                Result := Format(P.Next(), 0, 9);
            'previous':
                Result := Format(P.Previous(), 0, 9);
            'first':
                Result := Format(P.First(), 0, 9);
            'last':
                Result := Format(P.Last(), 0, 9);
            'goto':
                Result := Format(P.GoToKey(20), 0, 9);
            'shown':
                Result := 'shown';
            'close':
                begin
                    P.Close();
                    Result := 'closed';
                end;
            'delall':
                begin
                    P.DeleteAllAct.Invoke();
                    Result := 'acted';
                end;
            'delallupd':
                begin
                    P.DeleteAllUpdateAct.Invoke();
                    Result := 'acted';
                end;
        end;
        Result += '|' + P.IdCtl.Value() + '|' + P.TxtCtl.Value();
    end;

    local procedure MoveAll(var P: TestPage "LT Y80 List All"; Which: Text): Text
    var
        Result: Text;
    begin
        if TryAll(P, Which, Result) then
            exit(Result);
        Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryNoNew(var P: TestPage "LT Y80 List NoNew"; Which: Text; var Result: Text)
    begin
        case Which of
            'next':
                Result := Format(P.Next(), 0, 9);
            'previous':
                Result := Format(P.Previous(), 0, 9);
            'first':
                Result := Format(P.First(), 0, 9);
            'last':
                Result := Format(P.Last(), 0, 9);
            'goto':
                Result := Format(P.GoToKey(20), 0, 9);
            'shown':
                Result := 'shown';
            'close':
                begin
                    P.Close();
                    Result := 'closed';
                end;
            'delall':
                begin
                    P.DeleteAllAct.Invoke();
                    Result := 'acted';
                end;
            'delallupd':
                begin
                    P.DeleteAllUpdateAct.Invoke();
                    Result := 'acted';
                end;
        end;
        Result += '|' + P.IdCtl.Value() + '|' + P.TxtCtl.Value();
    end;

    local procedure MoveNoNew(var P: TestPage "LT Y80 List NoNew"; Which: Text): Text
    var
        Result: Text;
    begin
        if TryNoNew(P, Which, Result) then
            exit(Result);
        Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryReadOnly(var P: TestPage "LT Y80 List ReadOnly"; Which: Text; var Result: Text)
    begin
        case Which of
            'next':
                Result := Format(P.Next(), 0, 9);
            'previous':
                Result := Format(P.Previous(), 0, 9);
            'first':
                Result := Format(P.First(), 0, 9);
            'last':
                Result := Format(P.Last(), 0, 9);
            'goto':
                Result := Format(P.GoToKey(20), 0, 9);
            'shown':
                Result := 'shown';
            'close':
                begin
                    P.Close();
                    Result := 'closed';
                end;
            'delall':
                begin
                    P.DeleteAllAct.Invoke();
                    Result := 'acted';
                end;
            'delallupd':
                begin
                    P.DeleteAllUpdateAct.Invoke();
                    Result := 'acted';
                end;
        end;
        Result += '|' + P.IdCtl.Value() + '|' + P.TxtCtl.Value();
    end;

    local procedure MoveReadOnly(var P: TestPage "LT Y80 List ReadOnly"; Which: Text): Text
    var
        Result: Text;
    begin
        if TryReadOnly(P, Which, Result) then
            exit(Result);
        Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryNoInsMod(var P: TestPage "LT Y80 List NoInsMod"; Which: Text; var Result: Text)
    begin
        case Which of
            'next':
                Result := Format(P.Next(), 0, 9);
            'previous':
                Result := Format(P.Previous(), 0, 9);
            'first':
                Result := Format(P.First(), 0, 9);
            'last':
                Result := Format(P.Last(), 0, 9);
            'goto':
                Result := Format(P.GoToKey(20), 0, 9);
            'shown':
                Result := 'shown';
            'close':
                begin
                    P.Close();
                    Result := 'closed';
                end;
            'delall':
                begin
                    P.DeleteAllAct.Invoke();
                    Result := 'acted';
                end;
            'delallupd':
                begin
                    P.DeleteAllUpdateAct.Invoke();
                    Result := 'acted';
                end;
        end;
        Result += '|' + P.IdCtl.Value() + '|' + P.TxtCtl.Value();
    end;

    local procedure MoveNoInsMod(var P: TestPage "LT Y80 List NoInsMod"; Which: Text): Text
    var
        Result: Text;
    begin
        if TryNoInsMod(P, Which, Result) then
            exit(Result);
        Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure Y89_All_OpenEdit_delallupd_next()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('move', 'false|0|');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenEdit_delallupd_previous()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('move', 'false|0|');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenEdit_delallupd_first()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('move', 'false|0|');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenEdit_delallupd_last()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('move', 'false|0|');
        Observer.Expect('move log', 'N:0;C:0;N:0;C:0');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenEdit_delallupd_goto()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('move', 'false|0|');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenEdit_delall_next()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('move', 'false|0|');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenEdit_delall_previous()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('move', 'false|0|');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenEdit_delall_first()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('move', 'false|0|');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenEdit_delall_last()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('move', 'false|0|');
        Observer.Expect('move log', 'N:0;C:0;N:0;C:0');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenEdit_delall_goto()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('move', 'false|0|');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenView_delallupd_next()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenView_delallupd_previous()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenView_delallupd_first()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenView_delallupd_last()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenView_delallupd_goto()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenView_delall_next()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenView_delall_previous()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenView_delall_first()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenView_delall_last()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_All_OpenView_delall_goto()
    var
        P: TestPage "LT Y80 List All";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveAll(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveAll(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveAll(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveAll(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenEdit_delallupd_next()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenEdit_delallupd_previous()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenEdit_delallupd_first()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenEdit_delallupd_last()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenEdit_delallupd_goto()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenEdit_delall_next()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenEdit_delall_previous()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenEdit_delall_first()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenEdit_delall_last()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenEdit_delall_goto()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenView_delallupd_next()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenView_delallupd_previous()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenView_delallupd_first()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenView_delallupd_last()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenView_delallupd_goto()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenView_delall_next()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenView_delall_previous()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenView_delall_first()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenView_delall_last()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoNew_OpenView_delall_goto()
    var
        P: TestPage "LT Y80 List NoNew";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoNew(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoNew(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoNew(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoNew(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenEdit_delallupd_next()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenEdit_delallupd_previous()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenEdit_delallupd_first()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenEdit_delallupd_last()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenEdit_delallupd_goto()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenEdit_delall_next()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenEdit_delall_previous()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenEdit_delall_first()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenEdit_delall_last()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenEdit_delall_goto()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenView_delallupd_next()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenView_delallupd_previous()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenView_delallupd_first()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenView_delallupd_last()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenView_delallupd_goto()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenView_delall_next()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenView_delall_previous()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenView_delall_first()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenView_delall_last()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_ReadOnly_OpenView_delall_goto()
    var
        P: TestPage "LT Y80 List ReadOnly";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveReadOnly(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveReadOnly(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveReadOnly(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveReadOnly(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenEdit_delallupd_next()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenEdit_delallupd_previous()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenEdit_delallupd_first()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenEdit_delallupd_last()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenEdit_delallupd_goto()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenEdit_delall_next()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenEdit_delall_previous()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenEdit_delall_first()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenEdit_delall_last()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenEdit_delall_goto()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenView_delallupd_next()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenView_delallupd_previous()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenView_delallupd_first()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenView_delallupd_last()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenView_delallupd_goto()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delallupd'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenView_delall_next()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'next'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenView_delall_previous()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'previous'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenView_delall_first()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'first'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenView_delall_last()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'last'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_NoInsMod_OpenView_delall_goto()
    var
        P: TestPage "LT Y80 List NoInsMod";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog());
        Observer.Observe('action', MoveNoInsMod(P, 'delall'));
        Observer.Observe('action log', TakeLog());
        Observer.Observe('move', MoveNoInsMod(P, 'goto'));
        Observer.Observe('move log', TakeLog());
        Observer.Observe('shown', MoveNoInsMod(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveNoInsMod(P, 'close'));
        Observer.Observe('close log', TakeLog());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('move', 'false||');
        Observer.Expect('move log', '');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCardTrue(var P: TestPage "LT Y89 Card Close True"; Which: Text; var Result: Text)
    begin
        case Which of
            'delcur':
                begin
                    P.DeleteCurrentAct.Invoke();
                    Result := 'acted';
                end;
            'delallupd':
                begin
                    P.DeleteAllUpdateAct.Invoke();
                    Result := 'acted';
                end;
            'delall':
                begin
                    P.DeleteAllAct.Invoke();
                    Result := 'acted';
                end;
            'closeact':
                begin
                    P.CloseAct.Invoke();
                    Result := 'acted';
                end;
            'close':
                begin
                    P.Close();
                    Result := 'closed';
                end;
            'shown':
                Result := 'shown';
        end;
        Result += '|' + P.IdCtl.Value();
    end;

    local procedure DoCardTrue(var P: TestPage "LT Y89 Card Close True"; Which: Text): Text
    var
        Result: Text;
    begin
        if TryCardTrue(P, Which, Result) then
            exit(Result);
        Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure Y89_CA_True_OpenEdit_1Row_delcur()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'delcur'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:10/Q:OK:0;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenEdit_1Row_delallupd()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'delallupd'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:10/Q:OK:0;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenEdit_1Row_delall()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'delall'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:10/Q:OK:0;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenEdit_1Row_closeact()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'closeact'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', '/Q:OK:10;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '1');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenEdit_1Row_close()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'close'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', '/Q:OK:10;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '1');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenEdit_2Row_delcur()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(2);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'delcur'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:10/Q:OK:20;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '1');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenEdit_2Row_delallupd()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(2);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'delallupd'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:10;D:20/Q:OK:0;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenEdit_2Row_delall()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(2);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'delall'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:10;D:20/Q:OK:0;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenEdit_2Row_closeact()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(2);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'closeact'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', '/Q:OK:10;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '2');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenEdit_2Row_close()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(2);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'close'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', '/Q:OK:10;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '2');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenView_1Row_delcur()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'delcur'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:10/Q:OK:0;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenView_1Row_delallupd()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'delallupd'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:10/Q:OK:0;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenView_1Row_delall()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'delall'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:10/Q:OK:0;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenView_1Row_closeact()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'closeact'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', '/Q:OK:10;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '1');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenView_1Row_close()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'close'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', '/Q:OK:10;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '1');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenView_2Row_delcur()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(2);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'delcur'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:10/Q:OK:20;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '1');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenView_2Row_delallupd()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(2);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'delallupd'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:10;D:20/Q:OK:0;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenView_2Row_delall()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(2);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'delall'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:10;D:20/Q:OK:0;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenView_2Row_closeact()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(2);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'closeact'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', '/Q:OK:10;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '2');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenView_2Row_close()
    var
        P: TestPage "LT Y89 Card Close True";
    begin
        Seed(2);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardTrue(P, 'close'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardTrue(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardTrue(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', '/Q:OK:10;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '2');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCardFalse(var P: TestPage "LT Y89 Card Close False"; Which: Text; var Result: Text)
    begin
        case Which of
            'delcur':
                begin
                    P.DeleteCurrentAct.Invoke();
                    Result := 'acted';
                end;
            'delallupd':
                begin
                    P.DeleteAllUpdateAct.Invoke();
                    Result := 'acted';
                end;
            'delall':
                begin
                    P.DeleteAllAct.Invoke();
                    Result := 'acted';
                end;
            'closeact':
                begin
                    P.CloseAct.Invoke();
                    Result := 'acted';
                end;
            'close':
                begin
                    P.Close();
                    Result := 'closed';
                end;
            'shown':
                Result := 'shown';
        end;
        Result += '|' + P.IdCtl.Value();
    end;

    local procedure DoCardFalse(var P: TestPage "LT Y89 Card Close False"; Which: Text): Text
    var
        Result: Text;
    begin
        if TryCardFalse(P, Which, Result) then
            exit(Result);
        Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure Y89_CA_False_OpenEdit_1Row_delcur()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'delcur'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|');
        Observer.Expect('action log', 'D:10/Q:OK:0');
        Observer.Expect('shown', 'shown|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:0');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenEdit_1Row_delallupd()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'delallupd'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|');
        Observer.Expect('action log', 'D:10/Q:OK:0');
        Observer.Expect('shown', 'shown|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:0');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenEdit_1Row_delall()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'delall'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|');
        Observer.Expect('action log', 'D:10/Q:OK:0');
        Observer.Expect('shown', 'shown|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:0');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenEdit_1Row_closeact()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'closeact'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|10');
        Observer.Expect('action log', '/Q:OK:10;Q:OK:10');
        Observer.Expect('shown', 'shown|10');
        Observer.Expect('rows', '1');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:10');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenEdit_1Row_close()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'close'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', '/Q:OK:10');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '1');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenEdit_2Row_delcur()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(2);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'delcur'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|20');
        Observer.Expect('action log', 'D:10/Q:OK:10;Q:OK:10;Q:OK:20');
        Observer.Expect('shown', 'shown|20');
        Observer.Expect('rows', '1');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:20');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenEdit_2Row_delallupd()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(2);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'delallupd'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|');
        Observer.Expect('action log', 'D:10;D:20/Q:OK:0;Q:OK:20');
        Observer.Expect('shown', 'shown|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:0');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenEdit_2Row_delall()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(2);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'delall'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|');
        Observer.Expect('action log', 'D:10;D:20/Q:OK:0');
        Observer.Expect('shown', 'shown|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:0');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenEdit_2Row_closeact()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(2);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'closeact'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|10');
        Observer.Expect('action log', '/Q:OK:10;Q:OK:10');
        Observer.Expect('shown', 'shown|10');
        Observer.Expect('rows', '2');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:10');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenEdit_2Row_close()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(2);
        P.OpenEdit();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'close'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', '/Q:OK:10');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '2');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenView_1Row_delcur()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'delcur'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|');
        Observer.Expect('action log', 'D:10/Q:OK:0;Q:OK:10;Q:OK:10');
        Observer.Expect('shown', 'shown|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:0');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenView_1Row_delallupd()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'delallupd'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|');
        Observer.Expect('action log', 'D:10/Q:OK:0');
        Observer.Expect('shown', 'shown|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:0');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenView_1Row_delall()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'delall'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|');
        Observer.Expect('action log', 'D:10/Q:OK:0');
        Observer.Expect('shown', 'shown|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:0');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenView_1Row_closeact()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'closeact'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|10');
        Observer.Expect('action log', '/Q:OK:10;Q:OK:10');
        Observer.Expect('shown', 'shown|10');
        Observer.Expect('rows', '1');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:10');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenView_1Row_close()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'close'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', '/Q:OK:10');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '1');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenView_2Row_delcur()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(2);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'delcur'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|20');
        Observer.Expect('action log', 'D:10/Q:OK:10;Q:OK:10;Q:OK:20');
        Observer.Expect('shown', 'shown|20');
        Observer.Expect('rows', '1');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:20');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenView_2Row_delallupd()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(2);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'delallupd'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|');
        Observer.Expect('action log', 'D:10;D:20/Q:OK:0;Q:OK:20');
        Observer.Expect('shown', 'shown|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:0');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenView_2Row_delall()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(2);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'delall'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|');
        Observer.Expect('action log', 'D:10;D:20/Q:OK:0');
        Observer.Expect('shown', 'shown|');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:0');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenView_2Row_closeact()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(2);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'closeact'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'acted|10');
        Observer.Expect('action log', '/Q:OK:10;Q:OK:10');
        Observer.Expect('shown', 'shown|10');
        Observer.Expect('rows', '2');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/Q:OK:10');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_False_OpenView_2Row_close()
    var
        P: TestPage "LT Y89 Card Close False";
    begin
        Seed(2);
        P.OpenView();
        Observer.Observe('open log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('action', DoCardFalse(P, 'close'));
        Observer.Observe('action log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('shown', DoCardFalse(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardFalse(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeCloseLog());
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', '/Q:OK:10');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '2');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure DeleteCurrentModal(var P: TestPage "LT Y89 Card Close True")
    begin
        P.DeleteCurrentAct.Invoke();
        ModalAction := 'acted';
    end;

    [ModalPageHandler]
    procedure DeleteAllUpdateModal(var P: TestPage "LT Y89 Card Close True")
    begin
        P.DeleteAllUpdateAct.Invoke();
        ModalAction := 'acted';
    end;

    [ModalPageHandler]
    procedure DeleteAllModal(var P: TestPage "LT Y89 Card Close True")
    begin
        P.DeleteAllAct.Invoke();
        ModalAction := 'acted';
    end;

    [ModalPageHandler]
    procedure CloseActModal(var P: TestPage "LT Y89 Card Close True")
    begin
        P.CloseAct.Invoke();
        ModalAction := 'acted';
    end;

    [ModalPageHandler]
    procedure OkModal(var P: TestPage "LT Y89 Card Close True")
    begin
        P.OK().Invoke();
        ModalAction := 'ok';
    end;

    [ModalPageHandler]
    procedure CancelModal(var P: TestPage "LT Y89 Card Close True")
    begin
        P.Cancel().Invoke();
        ModalAction := 'cancel';
    end;

    [ModalPageHandler]
    procedure DeleteCurrentModalFalse(var P: TestPage "LT Y89 Card Close False")
    begin
        P.DeleteCurrentAct.Invoke();
        ModalAction := 'acted';
    end;

    [ModalPageHandler]
    procedure DeleteAllUpdateModalFalse(var P: TestPage "LT Y89 Card Close False")
    begin
        P.DeleteAllUpdateAct.Invoke();
        ModalAction := 'acted';
    end;

    [ModalPageHandler]
    procedure CloseActModalFalse(var P: TestPage "LT Y89 Card Close False")
    begin
        P.CloseAct.Invoke();
        ModalAction := 'acted';
    end;

    [Test]
    [HandlerFunctions('DeleteCurrentModal')]
    procedure Y89_CA_Modal_True_1Row_DeleteCurrent()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(1);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close True", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', 'D:10/Q:LookupCancel:0;X');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DeleteAllUpdateModal')]
    procedure Y89_CA_Modal_True_1Row_DeleteAllUpdate()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(1);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close True", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', 'D:10/Q:LookupCancel:0;X');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DeleteAllModal')]
    procedure Y89_CA_Modal_True_1Row_DeleteAll()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(1);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close True", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', 'D:10/Q:LookupCancel:0;X');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DeleteCurrentModalFalse')]
    procedure Y89_CA_Modal_False_1Row_DeleteCurrent()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(1);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close False", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'None');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', 'D:10/Q:LookupCancel:0;Q:LookupCancel:0');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DeleteAllUpdateModalFalse')]
    procedure Y89_CA_Modal_False_1Row_DeleteAllUpdate()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(1);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close False", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'None');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', 'D:10/Q:LookupCancel:0;Q:LookupCancel:0');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DeleteCurrentModal')]
    procedure Y89_CA_Modal_True_2Row_DeleteCurrent()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(2);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close True", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', 'D:10/Q:LookupCancel:20;X');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DeleteAllUpdateModal')]
    procedure Y89_CA_Modal_True_2Row_DeleteAllUpdate()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(2);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close True", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', 'D:10;D:20/Q:LookupCancel:0;X');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DeleteAllModal')]
    procedure Y89_CA_Modal_True_2Row_DeleteAll()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(2);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close True", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', 'D:10;D:20/Q:LookupCancel:0;X');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DeleteCurrentModalFalse')]
    procedure Y89_CA_Modal_False_2Row_DeleteCurrent()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(2);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close False", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'None');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', 'D:10/Q:LookupCancel:20;Q:LookupCancel:20');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DeleteAllUpdateModalFalse')]
    procedure Y89_CA_Modal_False_2Row_DeleteAllUpdate()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(2);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close False", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'None');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', 'D:10;D:20/Q:LookupCancel:0;Q:LookupCancel:0');
        Observer.Expect('rows', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CloseActModal')]
    procedure Y89_CA_Modal_True_CloseAct()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(1);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close True", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', '/Q:LookupCancel:10;X');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkModal')]
    procedure Y89_CA_Modal_True_Ok()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(1);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close True", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('handler', 'ok');
        Observer.Expect('log', '/Q:LookupOK:10;X');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelModal')]
    procedure Y89_CA_Modal_True_Cancel()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(1);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close True", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler', 'cancel');
        Observer.Expect('log', '/Q:LookupCancel:10;X');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CloseActModalFalse')]
    procedure Y89_CA_Modal_False_CloseAct()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(1);
        Row.FindFirst();
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close False", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeCloseLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'None');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', '/Q:LookupCancel:10;Q:LookupCancel:10;Q:LookupCancel:10');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure DeleteCurrentModalLast(var P: TestPage "LT Y89 Card Last True")
    begin
        P.DeleteCurrentAct.Invoke();
        ModalAction := 'acted';
    end;

    local procedure DoCardLast(var P: TestPage "LT Y89 Card Last True"; Which: Text): Text
    var
        Result: Text;
    begin
        if TryCardLast(P, Which, Result) then
            exit(Result);
        Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryCardLast(var P: TestPage "LT Y89 Card Last True"; Which: Text; var Result: Text)
    begin
        case Which of
            'delcur':
                begin
                    P.DeleteCurrentAct.Invoke();
                    Result := 'acted';
                end;
            'close':
                begin
                    P.Close();
                    Result := 'closed';
                end;
            'shown':
                Result := 'shown';
        end;
        Result += '|' + P.IdCtl.Value();
    end;

    [ModalPageHandler]
    procedure DeleteCurrentModalGet(var P: TestPage "LT Y89 Card Close Get")
    begin
        P.DeleteCurrentAct.Invoke();
        ModalAction := 'acted';
    end;

    local procedure DoCardGetDelete(var P: TestPage "LT Y89 Card Close Get"): Text
    begin
        if TryCardGetDelete(P) then
            exit('acted');
        exit('err|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryCardGetDelete(var P: TestPage "LT Y89 Card Close Get")
    begin
        P.DeleteCurrentAct.Invoke();
    end;

    local procedure CardTrueLastRow(View: Boolean)
    var
        P: TestPage "LT Y89 Card Last True";
    begin
        Seed(3);
        if View then
            P.OpenView()
        else
            P.OpenEdit();
        P.GoToKey(30);
        Observer.Observe('goto', P.IdCtl.Value());
        Observer.Observe('open log', TakeLog() + '/' + TakeLastLog());
        Observer.Observe('action', DoCardLast(P, 'delcur'));
        Observer.Observe('action log', TakeLog() + '/' + TakeLastLog());
        Observer.Observe('shown', DoCardLast(P, 'shown'));
        Observer.Observe('rows', Rows());
        Observer.Observe('close', DoCardLast(P, 'close'));
        Observer.Observe('close log', TakeLog() + '/' + TakeLastLog());
        Observer.Expect('goto', '30');
        Observer.Expect('open log', '/');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'D:30/Q:OK:20;X:20');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('rows', '2');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '/');
        Observer.Verify();
    end;

    local procedure CardGetOn(Id: Integer; OpenLog: Text; ActionLog: Text)
    var
        P: TestPage "LT Y89 Card Close Get";
    begin
        Seed(3);
        P.OpenEdit();
        P.GoToKey(Id);
        Observer.Observe('goto', P.IdCtl.Value());
        Observer.Observe('open log', TakeLog() + '/' + TakeLastLog());
        Observer.Observe('action', DoCardGetDelete(P));
        ClearLastError();
        Observer.Observe('action log', TakeLog() + '/' + TakeLastLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('goto', Format(Id));
        Observer.Expect('open log', OpenLog);
        Observer.Expect('action', 'acted');
        Observer.Expect('action log', ActionLog);
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Y89_CA_True_OpenEdit_3Row_delcur_last()
    begin
        CardTrueLastRow(false);
    end;

    [Test]
    procedure Y89_CA_True_OpenView_3Row_delcur_last()
    begin
        CardTrueLastRow(true);
    end;

    [Test]
    procedure Y89_CA_Get_OpenEdit_3Row_delcur_last()
    begin
        CardGetOn(30, '/G:10;C:10;G:10;C:10;G:20;C:20;G:30;C:30', 'D:30/G:30;G:20;Q:OK:20;X:20');
    end;

    [Test]
    procedure Y89_CA_Get_OpenEdit_3Row_delcur_first()
    begin
        CardGetOn(10, '/G:10;C:10;G:10;C:10', 'D:10/G:10;G:20;Q:OK:20;X:20');
    end;

    [Test]
    [HandlerFunctions('DeleteCurrentModalLast')]
    procedure Y89_CA_Modal_True_3Row_DeleteCurrentLast()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(3);
        Row.Get(30);
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Last True", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeLastLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', 'D:30/Q:LookupCancel:20;X:20');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DeleteCurrentModalGet')]
    procedure Y89_CA_Modal_Get_3Row_DeleteCurrentLast()
    var
        Row: Record "LT Y80 Row";
        Result: Action;
    begin
        Seed(3);
        Row.Get(30);
        ModalAction := '';
        Result := Page.RunModal(Page::"LT Y89 Card Close Get", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('handler', ModalAction);
        Observer.Observe('log', TakeLog() + '/' + TakeLastLog());
        Observer.Observe('rows', Rows());
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('handler', 'acted');
        Observer.Expect('log', 'D:30/G:30;C:30;G:30;G:20;Q:LookupCancel:20;X:20');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;
}
