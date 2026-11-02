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
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListAll(P, 'first'));
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('last', MoveListAll(P, 'last'));
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListAll(P, 'first'));
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('last', MoveListAll(P, 'last'));
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteAllAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListAll(P, 'first'));
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('last', MoveListAll(P, 'last'));
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListAll(P, 'first'));
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('last', MoveListAll(P, 'last'));
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListAll(P, 'first'));
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('last', MoveListAll(P, 'last'));
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteAllAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListAll(P, 'first'));
        Observer.Observe('next', MoveListAll(P, 'next'));
        Observer.Observe('last', MoveListAll(P, 'last'));
        Observer.Observe('previous', MoveListAll(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListNoNew(P, 'first'));
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('last', MoveListNoNew(P, 'last'));
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListNoNew(P, 'first'));
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('last', MoveListNoNew(P, 'last'));
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListNoNew(P, 'first'));
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('last', MoveListNoNew(P, 'last'));
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListNoNew(P, 'first'));
        Observer.Observe('next', MoveListNoNew(P, 'next'));
        Observer.Observe('last', MoveListNoNew(P, 'last'));
        Observer.Observe('previous', MoveListNoNew(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListReadOnly(P, 'first'));
        Observer.Observe('next', MoveListReadOnly(P, 'next'));
        Observer.Observe('last', MoveListReadOnly(P, 'last'));
        Observer.Observe('previous', MoveListReadOnly(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListReadOnly(P, 'first'));
        Observer.Observe('next', MoveListReadOnly(P, 'next'));
        Observer.Observe('last', MoveListReadOnly(P, 'last'));
        Observer.Observe('previous', MoveListReadOnly(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteAllAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListReadOnly(P, 'first'));
        Observer.Observe('next', MoveListReadOnly(P, 'next'));
        Observer.Observe('last', MoveListReadOnly(P, 'last'));
        Observer.Observe('previous', MoveListReadOnly(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListReadOnly(P, 'first'));
        Observer.Observe('next', MoveListReadOnly(P, 'next'));
        Observer.Observe('last', MoveListReadOnly(P, 'last'));
        Observer.Observe('previous', MoveListReadOnly(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListReadOnly(P, 'first'));
        Observer.Observe('next', MoveListReadOnly(P, 'next'));
        Observer.Observe('last', MoveListReadOnly(P, 'last'));
        Observer.Observe('previous', MoveListReadOnly(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteAllAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListReadOnly(P, 'first'));
        Observer.Observe('next', MoveListReadOnly(P, 'next'));
        Observer.Observe('last', MoveListReadOnly(P, 'last'));
        Observer.Observe('previous', MoveListReadOnly(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListNoInsMod(P, 'first'));
        Observer.Observe('next', MoveListNoInsMod(P, 'next'));
        Observer.Observe('last', MoveListNoInsMod(P, 'last'));
        Observer.Observe('previous', MoveListNoInsMod(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveListNoInsMod(P, 'first'));
        Observer.Observe('next', MoveListNoInsMod(P, 'next'));
        Observer.Observe('last', MoveListNoInsMod(P, 'last'));
        Observer.Observe('previous', MoveListNoInsMod(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('second action log', Log.Take());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveCardPlain(P, 'first'));
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('last', MoveCardPlain(P, 'last'));
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveCardPlain(P, 'first'));
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('last', MoveCardPlain(P, 'last'));
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteAllUpdateAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveCardPlain(P, 'first'));
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('last', MoveCardPlain(P, 'last'));
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.DeleteCurrentAct.Invoke();
        Observer.Observe('action log', Log.Take());
        Observer.Observe('shown', P.IdCtl.Value() + '|' + P.TxtCtl.Value());
        Observer.Observe('first', MoveCardPlain(P, 'first'));
        Observer.Observe('next', MoveCardPlain(P, 'next'));
        Observer.Observe('last', MoveCardPlain(P, 'last'));
        Observer.Observe('previous', MoveCardPlain(P, 'previous'));
        Observer.Observe('moves log', Log.Take());
        Observer.Observe('rows', Rows());
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
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
        P.Close();
        Observer.Finish();
    end;
}
