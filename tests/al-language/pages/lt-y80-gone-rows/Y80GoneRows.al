// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 94228 - 94235 and the test codeunits 94230 and 94236
// Probe (writer Y80, from the runtime lane rt-pages-1102c): (1) an action on a List that lost its only row, for the list shapes that
//   pages/lt-outside-worksheet/RmWorksheetGoneRow.al (no new-row line, all of Insert/Modify/Delete denied) and Y66 (temporary, read-only) do not
//   cover: a plain editable List, a List with InsertAllowed = false only, an Editable = false List, a List with Insert and Modify denied and Delete
//   allowed, each opened with OpenEdit and OpenView, the action deleting every row (with and without CurrPage.Update(false)) or only Rec. (2) moving
//   (Next, Previous, First, Last, GoToKey) onto a row that the table no longer has: code deletes the row, through another record variable, after
//   the page was opened and read. The pages log OnAfterGetRecord (R:), OnAfterGetCurrRecord (C:), OnNewRecord (N:) with the row id, and the table
//   OnDelete (D:), OnModify (M:), OnInsert (I:).
// BC versions: 27, 28, 29

table 94228 "LT Y80 Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { AutoIncrement = true; }
        field(2; Entry; Text[250]) { }
    }
    keys { key(PK; "Line No.") { Clustered = true; } }

    procedure Add(NewEntry: Text)
    var
        Line: Record "LT Y80 Log";
    begin
        Line.Entry := CopyStr(NewEntry, 1, 250);
        Line.Insert();
    end;

    procedure Take() Result: Text
    var
        Line: Record "LT Y80 Log";
    begin
        if Line.FindSet() then
            repeat
                if Result <> '' then
                    Result += ';';
                Result += Line.Entry;
            until Line.Next() = 0;
        Line.DeleteAll();
    end;
}

table 94229 "LT Y80 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Num; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('I:' + Format(Id));
    end;

    trigger OnModify()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('M:' + Format(Id));
    end;

    trigger OnDelete()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('D:' + Format(Id));
    end;
}

page 94231 "LT Y80 List All"
{
    PageType = List;
    SourceTable = "LT Y80 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(NumCtl; Rec.Num) { ApplicationArea = All; }
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
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('N:' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('Q');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('X');
    end;
}

page 94232 "LT Y80 List NoNew"
{
    PageType = List;
    SourceTable = "LT Y80 Row";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(NumCtl; Rec.Num) { ApplicationArea = All; }
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
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('N:' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('Q');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('X');
    end;
}

page 94233 "LT Y80 List ReadOnly"
{
    PageType = List;
    SourceTable = "LT Y80 Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(NumCtl; Rec.Num) { ApplicationArea = All; }
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
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('N:' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('Q');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('X');
    end;
}

page 94234 "LT Y80 List NoInsMod"
{
    PageType = List;
    SourceTable = "LT Y80 Row";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(TxtCtl; Rec.Txt) { ApplicationArea = All; }
                field(NumCtl; Rec.Num) { ApplicationArea = All; }
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
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('N:' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('Q');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('X');
    end;
}

page 94235 "LT Y80 Card Plain"
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
                field(NumCtl; Rec.Num) { ApplicationArea = All; }
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
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('R:' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('C:' + Format(Rec.Id));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('N:' + Format(Rec.Id));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('Q');
        exit(true);
    end;

    trigger OnClosePage()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('X');
    end;
}

codeunit 94230 "LT Y80 Gone Row Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed(Count: Integer)
    var
        Row: Record "LT Y80 Row";
        Log: Record "LT Y80 Log";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to Count do begin
            Row.Id := I * 10;
            Row.Txt := 'r' + Format(I * 10);
            Row.Insert();
        end;
        Log.DeleteAll();
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT Y80 Row";
    begin
        exit(Format(Row.Count()));
    end;

    [TryFunction]
    local procedure TryListAll(var P: TestPage "LT Y80 List All"; Which: Text; var Result: Text)
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
            'goto20':
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
            'delcur':
                begin
                    P.DeleteCurrentAct.Invoke();
                    Result := 'acted';
                end;
        end;
        Result += '|' + P.IdCtl.Value() + '|' + P.TxtCtl.Value();
    end;

    local procedure MoveListAll(var P: TestPage "LT Y80 List All"; Which: Text): Text
    var
        Result: Text;
    begin
        if TryListAll(P, Which, Result) then
            exit(Result);
        Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryListNoNew(var P: TestPage "LT Y80 List NoNew"; Which: Text; var Result: Text)
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
            'goto20':
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
            'delcur':
                begin
                    P.DeleteCurrentAct.Invoke();
                    Result := 'acted';
                end;
        end;
        Result += '|' + P.IdCtl.Value() + '|' + P.TxtCtl.Value();
    end;

    local procedure MoveListNoNew(var P: TestPage "LT Y80 List NoNew"; Which: Text): Text
    var
        Result: Text;
    begin
        if TryListNoNew(P, Which, Result) then
            exit(Result);
        Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryCardPlain(var P: TestPage "LT Y80 Card Plain"; Which: Text; var Result: Text)
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
            'goto20':
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
            'delcur':
                begin
                    P.DeleteCurrentAct.Invoke();
                    Result := 'acted';
                end;
        end;
        Result += '|' + P.IdCtl.Value() + '|' + P.TxtCtl.Value();
    end;

    local procedure MoveCardPlain(var P: TestPage "LT Y80 Card Plain"; Which: Text): Text
    var
        Result: Text;
    begin
        if TryCardPlain(P, Which, Result) then
            exit(Result);
        Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryListReadOnly(var P: TestPage "LT Y80 List ReadOnly"; Which: Text; var Result: Text)
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
            'goto20':
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
            'delcur':
                begin
                    P.DeleteCurrentAct.Invoke();
                    Result := 'acted';
                end;
        end;
        Result += '|' + P.IdCtl.Value() + '|' + P.TxtCtl.Value();
    end;

    local procedure MoveListReadOnly(var P: TestPage "LT Y80 List ReadOnly"; Which: Text): Text
    var
        Result: Text;
    begin
        if TryListReadOnly(P, Which, Result) then
            exit(Result);
        Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryListNoInsMod(var P: TestPage "LT Y80 List NoInsMod"; Which: Text; var Result: Text)
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
            'goto20':
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
            'delcur':
                begin
                    P.DeleteCurrentAct.Invoke();
                    Result := 'acted';
                end;
        end;
        Result += '|' + P.IdCtl.Value() + '|' + P.TxtCtl.Value();
    end;

    local procedure MoveListNoInsMod(var P: TestPage "LT Y80 List NoInsMod"; Which: Text): Text
    var
        Result: Text;
    begin
        if TryListNoInsMod(P, Which, Result) then
            exit(Result);
        Result := 'err|' + GetLastErrorCode() + '|' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [Test]
    procedure Y80_Gone_All_OpenEdit_DeleteAllUpdate()
    var
        P: TestPage "LT Y80 List All";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListAll(P, 'delallupd'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListAll(P, 'shown'));
        Observer.Observe('first', MoveListAll(P, 'first'));
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('last', MoveListAll(P, 'last'));
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListAll(P, 'delallupd'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListAll(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('first', 'false|0|');
        Observer.Expect('next', 'false|0|');
        Observer.Expect('last', 'false|0|');
        Observer.Expect('previous', 'false|0|');
        Observer.Expect('moves log', 'N:0;C:0;N:0;C:0');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'acted|0|');
        Observer.Expect('second action log', 'N:0;C:0;N:0;C:0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_All_OpenEdit_DeleteAll()
    var
        P: TestPage "LT Y80 List All";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListAll(P, 'delall'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListAll(P, 'shown'));
        Observer.Observe('first', MoveListAll(P, 'first'));
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('last', MoveListAll(P, 'last'));
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListAll(P, 'delall'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListAll(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('first', 'false|0|');
        Observer.Expect('next', 'false|0|');
        Observer.Expect('last', 'false|0|');
        Observer.Expect('previous', 'false|0|');
        Observer.Expect('moves log', 'N:0;C:0;N:0;C:0');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'acted|0|');
        Observer.Expect('second action log', 'N:0;C:0;N:0;C:0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_All_OpenEdit_DeleteCurrent()
    var
        P: TestPage "LT Y80 List All";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListAll(P, 'delcur'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListAll(P, 'shown'));
        Observer.Observe('first', MoveListAll(P, 'first'));
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('last', MoveListAll(P, 'last'));
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListAll(P, 'delcur'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListAll(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted|0|');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0;N:0;C:0;N:0;C:0');
        Observer.Expect('shown', 'shown|0|');
        Observer.Expect('first', 'false|0|');
        Observer.Expect('next', 'false|0|');
        Observer.Expect('last', 'false|0|');
        Observer.Expect('previous', 'false|0|');
        Observer.Expect('moves log', 'N:0;C:0;N:0;C:0');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'err|TestWrapped:CSideRecordNotFound|The LT Y80 Row does not exist. Identification fields and values: Id=''0''');
        Observer.Expect('second action log', 'D:0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_All_OpenView_DeleteAllUpdate()
    var
        P: TestPage "LT Y80 List All";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListAll(P, 'delallupd'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListAll(P, 'shown'));
        Observer.Observe('first', MoveListAll(P, 'first'));
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('last', MoveListAll(P, 'last'));
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListAll(P, 'delallupd'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListAll(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'acted||');
        Observer.Expect('second action log', '');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_All_OpenView_DeleteAll()
    var
        P: TestPage "LT Y80 List All";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListAll(P, 'delall'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListAll(P, 'shown'));
        Observer.Observe('first', MoveListAll(P, 'first'));
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('last', MoveListAll(P, 'last'));
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListAll(P, 'delall'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListAll(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'acted||');
        Observer.Expect('second action log', '');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_All_OpenView_DeleteCurrent()
    var
        P: TestPage "LT Y80 List All";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListAll(P, 'delcur'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListAll(P, 'shown'));
        Observer.Observe('first', MoveListAll(P, 'first'));
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('last', MoveListAll(P, 'last'));
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListAll(P, 'delcur'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListAll(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'err|TestWrapped:CSideRecordNotFound|The LT Y80 Row does not exist. Identification fields and values: Id=''0''');
        Observer.Expect('second action log', 'D:0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_NoNew_OpenEdit_DeleteAllUpdate()
    var
        P: TestPage "LT Y80 List NoNew";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListNoNew(P, 'delallupd'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListNoNew(P, 'shown'));
        Observer.Observe('first', MoveListNoNew(P, 'first'));
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('last', MoveListNoNew(P, 'last'));
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListNoNew(P, 'delallupd'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListNoNew(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'acted||');
        Observer.Expect('second action log', 'N:0;C:0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_NoNew_OpenEdit_DeleteCurrent()
    var
        P: TestPage "LT Y80 List NoNew";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListNoNew(P, 'delcur'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListNoNew(P, 'shown'));
        Observer.Observe('first', MoveListNoNew(P, 'first'));
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('last', MoveListNoNew(P, 'last'));
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListNoNew(P, 'delcur'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListNoNew(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'err|TestWrapped:CSideRecordNotFound|The LT Y80 Row does not exist. Identification fields and values: Id=''0''');
        Observer.Expect('second action log', 'D:0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_NoNew_OpenView_DeleteAllUpdate()
    var
        P: TestPage "LT Y80 List NoNew";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListNoNew(P, 'delallupd'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListNoNew(P, 'shown'));
        Observer.Observe('first', MoveListNoNew(P, 'first'));
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('last', MoveListNoNew(P, 'last'));
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListNoNew(P, 'delallupd'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListNoNew(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'acted||');
        Observer.Expect('second action log', '');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_NoNew_OpenView_DeleteCurrent()
    var
        P: TestPage "LT Y80 List NoNew";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListNoNew(P, 'delcur'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListNoNew(P, 'shown'));
        Observer.Observe('first', MoveListNoNew(P, 'first'));
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('last', MoveListNoNew(P, 'last'));
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListNoNew(P, 'delcur'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListNoNew(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'err|TestWrapped:CSideRecordNotFound|The LT Y80 Row does not exist. Identification fields and values: Id=''0''');
        Observer.Expect('second action log', 'D:0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_ReadOnly_OpenEdit_DeleteAllUpdate()
    var
        P: TestPage "LT Y80 List ReadOnly";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListReadOnly(P, 'delallupd'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListReadOnly(P, 'shown'));
        Observer.Observe('first', MoveListReadOnly(P, 'first'));
        Observer.Observe('next', MoveListReadOnly(P, 'next'));
        Observer.Observe('last', MoveListReadOnly(P, 'last'));
        Observer.Observe('previous', MoveListReadOnly(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListReadOnly(P, 'delallupd'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListReadOnly(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'acted||');
        Observer.Expect('second action log', '');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_ReadOnly_OpenEdit_DeleteAll()
    var
        P: TestPage "LT Y80 List ReadOnly";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListReadOnly(P, 'delall'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListReadOnly(P, 'shown'));
        Observer.Observe('first', MoveListReadOnly(P, 'first'));
        Observer.Observe('next', MoveListReadOnly(P, 'next'));
        Observer.Observe('last', MoveListReadOnly(P, 'last'));
        Observer.Observe('previous', MoveListReadOnly(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListReadOnly(P, 'delall'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListReadOnly(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'acted||');
        Observer.Expect('second action log', '');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_ReadOnly_OpenEdit_DeleteCurrent()
    var
        P: TestPage "LT Y80 List ReadOnly";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListReadOnly(P, 'delcur'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListReadOnly(P, 'shown'));
        Observer.Observe('first', MoveListReadOnly(P, 'first'));
        Observer.Observe('next', MoveListReadOnly(P, 'next'));
        Observer.Observe('last', MoveListReadOnly(P, 'last'));
        Observer.Observe('previous', MoveListReadOnly(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListReadOnly(P, 'delcur'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListReadOnly(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'err|TestWrapped:CSideRecordNotFound|The LT Y80 Row does not exist. Identification fields and values: Id=''0''');
        Observer.Expect('second action log', 'D:0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_ReadOnly_OpenView_DeleteAllUpdate()
    var
        P: TestPage "LT Y80 List ReadOnly";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListReadOnly(P, 'delallupd'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListReadOnly(P, 'shown'));
        Observer.Observe('first', MoveListReadOnly(P, 'first'));
        Observer.Observe('next', MoveListReadOnly(P, 'next'));
        Observer.Observe('last', MoveListReadOnly(P, 'last'));
        Observer.Observe('previous', MoveListReadOnly(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListReadOnly(P, 'delallupd'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListReadOnly(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'acted||');
        Observer.Expect('second action log', '');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_ReadOnly_OpenView_DeleteAll()
    var
        P: TestPage "LT Y80 List ReadOnly";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListReadOnly(P, 'delall'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListReadOnly(P, 'shown'));
        Observer.Observe('first', MoveListReadOnly(P, 'first'));
        Observer.Observe('next', MoveListReadOnly(P, 'next'));
        Observer.Observe('last', MoveListReadOnly(P, 'last'));
        Observer.Observe('previous', MoveListReadOnly(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListReadOnly(P, 'delall'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListReadOnly(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'acted||');
        Observer.Expect('second action log', '');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_ReadOnly_OpenView_DeleteCurrent()
    var
        P: TestPage "LT Y80 List ReadOnly";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListReadOnly(P, 'delcur'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListReadOnly(P, 'shown'));
        Observer.Observe('first', MoveListReadOnly(P, 'first'));
        Observer.Observe('next', MoveListReadOnly(P, 'next'));
        Observer.Observe('last', MoveListReadOnly(P, 'last'));
        Observer.Observe('previous', MoveListReadOnly(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListReadOnly(P, 'delcur'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListReadOnly(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'err|TestWrapped:CSideRecordNotFound|The LT Y80 Row does not exist. Identification fields and values: Id=''0''');
        Observer.Expect('second action log', 'D:0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_NoInsMod_OpenEdit_DeleteAllUpdate()
    var
        P: TestPage "LT Y80 List NoInsMod";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListNoInsMod(P, 'delallupd'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListNoInsMod(P, 'shown'));
        Observer.Observe('first', MoveListNoInsMod(P, 'first'));
        Observer.Observe('next', MoveListNoInsMod(P, 'next'));
        Observer.Observe('last', MoveListNoInsMod(P, 'last'));
        Observer.Observe('previous', MoveListNoInsMod(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListNoInsMod(P, 'delallupd'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListNoInsMod(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10;N:0;C:0');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'acted||');
        Observer.Expect('second action log', 'N:0;C:0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_NoInsMod_OpenView_DeleteAllUpdate()
    var
        P: TestPage "LT Y80 List NoInsMod";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveListNoInsMod(P, 'delallupd'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveListNoInsMod(P, 'shown'));
        Observer.Observe('first', MoveListNoInsMod(P, 'first'));
        Observer.Observe('next', MoveListNoInsMod(P, 'next'));
        Observer.Observe('last', MoveListNoInsMod(P, 'last'));
        Observer.Observe('previous', MoveListNoInsMod(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('second action', MoveListNoInsMod(P, 'delallupd'));
        Observer.Observe('second action log', Log.Take());
        Observer.Observe('close', MoveListNoInsMod(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;R:10;C:10');
        Observer.Expect('action', 'acted||');
        Observer.Expect('action log', 'R:10;D:10');
        Observer.Expect('shown', 'shown||');
        Observer.Expect('first', 'false||');
        Observer.Expect('next', 'false||');
        Observer.Expect('last', 'false||');
        Observer.Expect('previous', 'false||');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('second action', 'acted||');
        Observer.Expect('second action log', '');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', 'Q;X');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_Card_OpenEdit_DeleteAllUpdate()
    var
        P: TestPage "LT Y80 Card Plain";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveCardPlain(P, 'delallupd'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveCardPlain(P, 'shown'));
        Observer.Observe('first', MoveCardPlain(P, 'first'));
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('last', MoveCardPlain(P, 'last'));
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveCardPlain(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;C:10');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'R:10;D:10;Q;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('first', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('next', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('last', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('previous', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_Card_OpenEdit_DeleteCurrent()
    var
        P: TestPage "LT Y80 Card Plain";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveCardPlain(P, 'delcur'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveCardPlain(P, 'shown'));
        Observer.Observe('first', MoveCardPlain(P, 'first'));
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('last', MoveCardPlain(P, 'last'));
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveCardPlain(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;C:10');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'R:10;D:10;Q;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('first', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('next', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('last', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('previous', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_Card_OpenView_DeleteAllUpdate()
    var
        P: TestPage "LT Y80 Card Plain";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveCardPlain(P, 'delallupd'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveCardPlain(P, 'shown'));
        Observer.Observe('first', MoveCardPlain(P, 'first'));
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('last', MoveCardPlain(P, 'last'));
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveCardPlain(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;C:10');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'R:10;D:10;Q;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('first', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('next', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('last', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('previous', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Gone_Card_OpenView_DeleteCurrent()
    var
        P: TestPage "LT Y80 Card Plain";
        Log: Record "LT Y80 Log";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('action', MoveCardPlain(P, 'delcur'));
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', MoveCardPlain(P, 'shown'));
        Observer.Observe('first', MoveCardPlain(P, 'first'));
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('last', MoveCardPlain(P, 'last'));
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('close', MoveCardPlain(P, 'close'));
        Observer.Observe('close log', Log.Take());
        Observer.Expect('open log', 'R:10;C:10');
        Observer.Expect('action', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('action log', 'R:10;D:10;Q;X');
        Observer.Expect('shown', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('first', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('next', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('last', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('previous', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('moves log', '');
        Observer.Expect('rows', '0');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Expect('close log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_All_NextOntoDeleted()
    var
        P: TestPage "LT Y80 List All";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Row.Get(20);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveListAll(P, 'next'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveListAll(P, 'close'));
        Observer.Expect('open log', 'R:10;R:20;R:30;R:40;R:10;R:10;C:10');
        Observer.Expect('delete log', 'D:20');
        Observer.Expect('move', 'true|10|r10');
#if BC29PLUS
        Observer.Expect('move log', 'R:10;C:10;R:10;R:30;R:40;R:10;R:10;C:10');
#elif BC28PLUS
        Observer.Expect('move log', 'R:10;C:10;R:10;C:10');
#else
        Observer.Expect('move log', 'R:10;C:10;R:10;R:30;R:40;R:10;R:10;C:10');
#endif
        Observer.Expect('next', 'true|30|r30');
        Observer.Expect('next log', 'R:30;R:30;C:30');
        Observer.Expect('previous', 'true|10|r10');
        Observer.Expect('previous log', 'R:10;R:10;C:10');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_All_PreviousOntoDeleted()
    var
        P: TestPage "LT Y80 List All";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        P.Last();
        P.Previous();
        Observer.Observe('open log', Log.Take());
        Row.Get(20);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveListAll(P, 'previous'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveListAll(P, 'close'));
        Observer.Expect('open log', 'R:10;R:20;R:30;R:40;R:10;R:10;C:10;N:0;C:0;R:40;R:40;C:40;R:30;R:30;C:30');
        Observer.Expect('delete log', 'D:20');
#if BC29PLUS
        Observer.Expect('move', 'true|30|r30');
#elif BC28PLUS
        Observer.Expect('move', 'true|10|r10');
#else
        Observer.Expect('move', 'true|30|r30');
#endif
#if BC29PLUS
        Observer.Expect('move log', 'R:30;C:30;R:30;R:40;R:30;R:10;R:30;R:30;C:30');
#elif BC28PLUS
        Observer.Expect('move log', 'R:30;C:30;R:10;R:10;C:10');
#else
        Observer.Expect('move log', 'R:30;C:30;R:30;R:40;R:30;R:10;R:30;R:30;C:30');
#endif
#if BC29PLUS
        Observer.Expect('next', 'true|40|r40');
#elif BC28PLUS
        Observer.Expect('next', 'true|30|r30');
#else
        Observer.Expect('next', 'true|40|r40');
#endif
#if BC29PLUS
        Observer.Expect('next log', 'R:40;R:40;C:40');
#elif BC28PLUS
        Observer.Expect('next log', 'R:30;R:30;C:30');
#else
        Observer.Expect('next log', 'R:40;R:40;C:40');
#endif
#if BC29PLUS
        Observer.Expect('previous', 'true|30|r30');
#elif BC28PLUS
        Observer.Expect('previous', 'true|10|r10');
#else
        Observer.Expect('previous', 'true|30|r30');
#endif
#if BC29PLUS
        Observer.Expect('previous log', 'R:30;R:30;C:30');
#elif BC28PLUS
        Observer.Expect('previous log', 'R:10;R:10;C:10');
#else
        Observer.Expect('previous log', 'R:30;R:30;C:30');
#endif
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_All_FirstOntoDeleted()
    var
        P: TestPage "LT Y80 List All";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        P.Last();
        Observer.Observe('open log', Log.Take());
        Row.Get(10);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveListAll(P, 'first'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveListAll(P, 'close'));
        Observer.Expect('open log', 'R:10;R:20;R:30;R:40;R:10;R:10;C:10;N:0;C:0;R:40;R:40;C:40');
        Observer.Expect('delete log', 'D:10');
#if BC29PLUS
        Observer.Expect('move', 'true|40|r40');
#elif BC28PLUS
        Observer.Expect('move', 'true|20|r20');
#else
        Observer.Expect('move', 'true|40|r40');
#endif
#if BC29PLUS
        Observer.Expect('move log', 'R:40;C:40;R:40;R:30;R:20;R:40;R:40;C:40');
#elif BC28PLUS
        Observer.Expect('move log', 'R:40;C:40;R:20;R:20;C:20');
#else
        Observer.Expect('move log', 'R:40;C:40;R:40;R:30;R:20;R:40;R:40;C:40');
#endif
#if BC29PLUS
        Observer.Expect('next', 'true|0|');
#elif BC28PLUS
        Observer.Expect('next', 'true|30|r30');
#else
        Observer.Expect('next', 'true|0|');
#endif
#if BC29PLUS
        Observer.Expect('next log', 'N:0;C:0');
#elif BC28PLUS
        Observer.Expect('next log', 'R:30;R:30;C:30');
#else
        Observer.Expect('next log', 'N:0;C:0');
#endif
#if BC29PLUS
        Observer.Expect('previous', 'true|40|r40');
#elif BC28PLUS
        Observer.Expect('previous', 'true|20|r20');
#else
        Observer.Expect('previous', 'true|40|r40');
#endif
#if BC29PLUS
        Observer.Expect('previous log', 'R:40;R:40;C:40');
#elif BC28PLUS
        Observer.Expect('previous log', 'R:20;R:20;C:20');
#else
        Observer.Expect('previous log', 'R:40;R:40;C:40');
#endif
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_All_LastOntoDeleted()
    var
        P: TestPage "LT Y80 List All";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Row.Get(40);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveListAll(P, 'last'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveListAll(P, 'close'));
        Observer.Expect('open log', 'R:10;R:20;R:30;R:40;R:10;R:10;C:10');
        Observer.Expect('delete log', 'D:40');
#if BC29PLUS
        Observer.Expect('move', 'true|10|r10');
#elif BC28PLUS
        Observer.Expect('move', 'true|30|r30');
#else
        Observer.Expect('move', 'true|10|r10');
#endif
#if BC29PLUS
        Observer.Expect('move log', 'N:0;C:0;R:10;R:20;R:30;R:10;R:10;C:10');
#elif BC28PLUS
        Observer.Expect('move log', 'N:0;C:0;R:30;R:30;C:30');
#else
        Observer.Expect('move log', 'N:0;C:0;R:10;R:20;R:30;R:10;R:10;C:10');
#endif
#if BC29PLUS
        Observer.Expect('next', 'true|20|r20');
#elif BC28PLUS
        Observer.Expect('next', 'true|0|');
#else
        Observer.Expect('next', 'true|20|r20');
#endif
#if BC29PLUS
        Observer.Expect('next log', 'R:20;R:20;C:20');
#elif BC28PLUS
        Observer.Expect('next log', 'N:0;C:0');
#else
        Observer.Expect('next log', 'R:20;R:20;C:20');
#endif
#if BC29PLUS
        Observer.Expect('previous', 'true|10|r10');
#elif BC28PLUS
        Observer.Expect('previous', 'true|30|r30');
#else
        Observer.Expect('previous', 'true|10|r10');
#endif
#if BC29PLUS
        Observer.Expect('previous log', 'R:10;R:10;C:10');
#elif BC28PLUS
        Observer.Expect('previous log', 'R:30;R:30;C:30');
#else
        Observer.Expect('previous log', 'R:10;R:10;C:10');
#endif
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_All_GoToKeyDeleted()
    var
        P: TestPage "LT Y80 List All";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Row.Get(20);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveListAll(P, 'goto20'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveListAll(P, 'close'));
        Observer.Expect('open log', 'R:10;R:20;R:30;R:40;R:10;R:10;C:10');
        Observer.Expect('delete log', 'D:20');
        Observer.Expect('move', 'false|10|r10');
#if BC29PLUS
        Observer.Expect('move log', 'R:10;C:10;R:10;R:30;R:40;R:10;R:10;C:10;R:30;R:30;C:30;R:40;R:40;C:40;N:0;C:0;R:10;R:10;C:10');
#elif BC28PLUS
        Observer.Expect('move log', 'R:10;C:10;R:10;C:10;R:30;R:30;C:30;R:40;R:40;C:40;N:0;C:0;R:10;R:10;C:10');
#else
        Observer.Expect('move log', 'R:10;C:10;R:10;R:30;R:40;R:10;R:10;C:10;R:30;R:30;C:30;R:40;R:40;C:40;N:0;C:0;R:10;R:10;C:10');
#endif
        Observer.Expect('next', 'true|30|r30');
        Observer.Expect('next log', 'R:30;R:30;C:30');
        Observer.Expect('previous', 'true|10|r10');
        Observer.Expect('previous log', 'R:10;R:10;C:10');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_NoNew_NextOntoDeleted()
    var
        P: TestPage "LT Y80 List NoNew";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Row.Get(20);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveListNoNew(P, 'next'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveListNoNew(P, 'close'));
        Observer.Expect('open log', 'R:10;R:20;R:30;R:40;R:10;R:10;C:10');
        Observer.Expect('delete log', 'D:20');
        Observer.Expect('move', 'true|10|r10');
#if BC29PLUS
        Observer.Expect('move log', 'R:10;C:10;R:10;R:30;R:40;R:10;R:10;C:10');
#elif BC28PLUS
        Observer.Expect('move log', 'R:10;C:10;R:10;C:10');
#else
        Observer.Expect('move log', 'R:10;C:10;R:10;R:30;R:40;R:10;R:10;C:10');
#endif
        Observer.Expect('next', 'true|30|r30');
        Observer.Expect('next log', 'R:30;R:30;C:30');
        Observer.Expect('previous', 'true|10|r10');
        Observer.Expect('previous log', 'R:10;R:10;C:10');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_NoNew_PreviousOntoDeleted()
    var
        P: TestPage "LT Y80 List NoNew";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        P.Last();
        P.Previous();
        Observer.Observe('open log', Log.Take());
        Row.Get(20);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveListNoNew(P, 'previous'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveListNoNew(P, 'close'));
        Observer.Expect('open log', 'R:10;R:20;R:30;R:40;R:10;R:10;C:10;R:40;R:40;C:40;R:30;R:30;C:30');
        Observer.Expect('delete log', 'D:20');
#if BC29PLUS
        Observer.Expect('move', 'true|30|r30');
#elif BC28PLUS
        Observer.Expect('move', 'true|10|r10');
#else
        Observer.Expect('move', 'true|30|r30');
#endif
#if BC29PLUS
        Observer.Expect('move log', 'R:30;C:30;R:30;R:40;R:30;R:10;R:30;R:30;C:30');
#elif BC28PLUS
        Observer.Expect('move log', 'R:30;C:30;R:10;R:10;C:10');
#else
        Observer.Expect('move log', 'R:30;C:30;R:30;R:40;R:30;R:10;R:30;R:30;C:30');
#endif
#if BC29PLUS
        Observer.Expect('next', 'true|40|r40');
#elif BC28PLUS
        Observer.Expect('next', 'true|30|r30');
#else
        Observer.Expect('next', 'true|40|r40');
#endif
#if BC29PLUS
        Observer.Expect('next log', 'R:40;R:40;C:40');
#elif BC28PLUS
        Observer.Expect('next log', 'R:30;R:30;C:30');
#else
        Observer.Expect('next log', 'R:40;R:40;C:40');
#endif
#if BC29PLUS
        Observer.Expect('previous', 'true|30|r30');
#elif BC28PLUS
        Observer.Expect('previous', 'true|10|r10');
#else
        Observer.Expect('previous', 'true|30|r30');
#endif
#if BC29PLUS
        Observer.Expect('previous log', 'R:30;R:30;C:30');
#elif BC28PLUS
        Observer.Expect('previous log', 'R:10;R:10;C:10');
#else
        Observer.Expect('previous log', 'R:30;R:30;C:30');
#endif
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_NoNew_FirstOntoDeleted()
    var
        P: TestPage "LT Y80 List NoNew";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        P.Last();
        Observer.Observe('open log', Log.Take());
        Row.Get(10);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveListNoNew(P, 'first'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveListNoNew(P, 'close'));
        Observer.Expect('open log', 'R:10;R:20;R:30;R:40;R:10;R:10;C:10;R:40;R:40;C:40');
        Observer.Expect('delete log', 'D:10');
#if BC29PLUS
        Observer.Expect('move', 'true|40|r40');
#elif BC28PLUS
        Observer.Expect('move', 'true|20|r20');
#else
        Observer.Expect('move', 'true|40|r40');
#endif
#if BC29PLUS
        Observer.Expect('move log', 'R:40;C:40;R:40;R:30;R:20;R:40;R:40;C:40');
#elif BC28PLUS
        Observer.Expect('move log', 'R:40;C:40;R:20;R:20;C:20');
#else
        Observer.Expect('move log', 'R:40;C:40;R:40;R:30;R:20;R:40;R:40;C:40');
#endif
#if BC29PLUS
        Observer.Expect('next', 'false|40|r40');
#elif BC28PLUS
        Observer.Expect('next', 'true|30|r30');
#else
        Observer.Expect('next', 'false|40|r40');
#endif
#if BC29PLUS
        Observer.Expect('next log', '');
#elif BC28PLUS
        Observer.Expect('next log', 'R:30;R:30;C:30');
#else
        Observer.Expect('next log', '');
#endif
#if BC29PLUS
        Observer.Expect('previous', 'true|30|r30');
#elif BC28PLUS
        Observer.Expect('previous', 'true|20|r20');
#else
        Observer.Expect('previous', 'true|30|r30');
#endif
#if BC29PLUS
        Observer.Expect('previous log', 'R:30;R:30;C:30');
#elif BC28PLUS
        Observer.Expect('previous log', 'R:20;R:20;C:20');
#else
        Observer.Expect('previous log', 'R:30;R:30;C:30');
#endif
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_NoNew_LastOntoDeleted()
    var
        P: TestPage "LT Y80 List NoNew";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Row.Get(40);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveListNoNew(P, 'last'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveListNoNew(P, 'close'));
        Observer.Expect('open log', 'R:10;R:20;R:30;R:40;R:10;R:10;C:10');
        Observer.Expect('delete log', 'D:40');
#if BC29PLUS
        Observer.Expect('move', 'true|10|r10');
#elif BC28PLUS
        Observer.Expect('move', 'true|30|r30');
#else
        Observer.Expect('move', 'true|10|r10');
#endif
#if BC29PLUS
        Observer.Expect('move log', 'R:10;C:10;R:10;R:20;R:30;R:10;R:10;C:10');
#elif BC28PLUS
        Observer.Expect('move log', 'R:10;C:10;R:30;R:30;C:30');
#else
        Observer.Expect('move log', 'R:10;C:10;R:10;R:20;R:30;R:10;R:10;C:10');
#endif
#if BC29PLUS
        Observer.Expect('next', 'true|20|r20');
#elif BC28PLUS
        Observer.Expect('next', 'false|30|r30');
#else
        Observer.Expect('next', 'true|20|r20');
#endif
#if BC29PLUS
        Observer.Expect('next log', 'R:20;R:20;C:20');
#elif BC28PLUS
        Observer.Expect('next log', '');
#else
        Observer.Expect('next log', 'R:20;R:20;C:20');
#endif
#if BC29PLUS
        Observer.Expect('previous', 'true|10|r10');
#elif BC28PLUS
        Observer.Expect('previous', 'true|20|r20');
#else
        Observer.Expect('previous', 'true|10|r10');
#endif
#if BC29PLUS
        Observer.Expect('previous log', 'R:10;R:10;C:10');
#elif BC28PLUS
        Observer.Expect('previous log', 'R:20;R:20;C:20');
#else
        Observer.Expect('previous log', 'R:10;R:10;C:10');
#endif
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_NoNew_GoToKeyDeleted()
    var
        P: TestPage "LT Y80 List NoNew";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Row.Get(20);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveListNoNew(P, 'goto20'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveListNoNew(P, 'close'));
        Observer.Expect('open log', 'R:10;R:20;R:30;R:40;R:10;R:10;C:10');
        Observer.Expect('delete log', 'D:20');
        Observer.Expect('move', 'false|10|r10');
#if BC29PLUS
        Observer.Expect('move log', 'R:10;C:10;R:10;R:30;R:40;R:10;R:10;C:10;R:30;R:30;C:30;R:40;R:40;C:40;R:10;R:10;C:10');
#elif BC28PLUS
        Observer.Expect('move log', 'R:10;C:10;R:10;C:10;R:30;R:30;C:30;R:40;R:40;C:40;R:10;R:10;C:10');
#else
        Observer.Expect('move log', 'R:10;C:10;R:10;R:30;R:40;R:10;R:10;C:10;R:30;R:30;C:30;R:40;R:40;C:40;R:10;R:10;C:10');
#endif
        Observer.Expect('next', 'true|30|r30');
        Observer.Expect('next log', 'R:30;R:30;C:30');
        Observer.Expect('previous', 'true|10|r10');
        Observer.Expect('previous log', 'R:10;R:10;C:10');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_Card_NextOntoDeleted()
    var
        P: TestPage "LT Y80 Card Plain";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Row.Get(20);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveCardPlain(P, 'next'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveCardPlain(P, 'close'));
        Observer.Expect('open log', 'R:10;C:10');
        Observer.Expect('delete log', 'D:20');
        Observer.Expect('move', 'true|30|r30');
        Observer.Expect('move log', 'R:30;C:30');
        Observer.Expect('next', 'true|40|r40');
        Observer.Expect('next log', 'R:40;C:40');
        Observer.Expect('previous', 'true|30|r30');
        Observer.Expect('previous log', 'R:30;C:30');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_Card_PreviousOntoDeleted()
    var
        P: TestPage "LT Y80 Card Plain";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        P.Last();
        P.Previous();
        Observer.Observe('open log', Log.Take());
        Row.Get(20);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveCardPlain(P, 'previous'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveCardPlain(P, 'close'));
        Observer.Expect('open log', 'R:10;C:10;R:40;C:40;R:30;C:30');
        Observer.Expect('delete log', 'D:20');
        Observer.Expect('move', 'true|10|r10');
        Observer.Expect('move log', 'R:10;C:10');
        Observer.Expect('next', 'true|30|r30');
        Observer.Expect('next log', 'R:30;C:30');
        Observer.Expect('previous', 'true|10|r10');
        Observer.Expect('previous log', 'R:10;C:10');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_Card_FirstOntoDeleted()
    var
        P: TestPage "LT Y80 Card Plain";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        P.Last();
        Observer.Observe('open log', Log.Take());
        Row.Get(10);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveCardPlain(P, 'first'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveCardPlain(P, 'close'));
        Observer.Expect('open log', 'R:10;C:10;R:40;C:40');
        Observer.Expect('delete log', 'D:10');
        Observer.Expect('move', 'true|20|r20');
        Observer.Expect('move log', 'R:20;C:20');
        Observer.Expect('next', 'true|30|r30');
        Observer.Expect('next log', 'R:30;C:30');
        Observer.Expect('previous', 'true|20|r20');
        Observer.Expect('previous log', 'R:20;C:20');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_Card_LastOntoDeleted()
    var
        P: TestPage "LT Y80 Card Plain";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Row.Get(40);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveCardPlain(P, 'last'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveCardPlain(P, 'close'));
        Observer.Expect('open log', 'R:10;C:10');
        Observer.Expect('delete log', 'D:40');
        Observer.Expect('move', 'true|30|r30');
        Observer.Expect('move log', 'R:30;C:30');
        Observer.Expect('next', 'false|30|r30');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'true|20|r20');
        Observer.Expect('previous log', 'R:20;C:20');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure Y80_Moved_Card_GoToKeyDeleted()
    var
        P: TestPage "LT Y80 Card Plain";
        Log: Record "LT Y80 Log";
        Row: Record "LT Y80 Row";
    begin
        Seed(4);
        P.OpenEdit();
        Observer.Observe('open log', Log.Take());
        Row.Get(20);
        Row.Delete(true);
        Observer.Observe('delete log', Log.Take());
        Observer.Observe('move', MoveCardPlain(P, 'goto20'));
        Observer.Observe('move log', Log.Take());
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('close', MoveCardPlain(P, 'close'));
        Observer.Expect('open log', 'R:10;C:10');
        Observer.Expect('delete log', 'D:20');
        Observer.Expect('move', 'false|10|r10');
        Observer.Expect('move log', 'R:10;C:10;R:30;C:30;R:40;C:40;R:10;C:10');
        Observer.Expect('next', 'true|30|r30');
        Observer.Expect('next log', 'R:30;C:30');
        Observer.Expect('previous', 'true|10|r10');
        Observer.Expect('previous log', 'R:10;C:10');
        Observer.Expect('close', 'err|TestPageNotOpened|The TestPage is not open.');
        Observer.Verify();
    end;
}
