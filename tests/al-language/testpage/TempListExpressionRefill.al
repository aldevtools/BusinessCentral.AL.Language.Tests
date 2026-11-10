// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 66410, page 66411, test codeunit 66412
// local object: the page's expression-bound controls, its temporary source table and its refill actions are what the tests measure.
// Probe (al-runner issue 7419: a non-editable List over a temporary source table whose OnOpenPage and actions refill Rec, with controls
//   bound to methods of the record; the handler invokes an action, sets a TestPage filter on "Field No.", goes to the first row and reads
//   the method-bound controls): observation form, the values are read from the corpus CI matrix.
// Area: what expression-bound controls show on a List over a temporary source table after an action that deletes every row of Rec and
//   inserts other rows. Control shapes: a method of the record (Rec.GetLocalOld()), a built-in call (Format(Rec."Field No.")), a
//   concatenation of two fields, a page variable the refill sets, next to field-bound controls. Refills: three other rows, the same
//   keys with other values, one row, no row; with and without CurrPage.Update(false); the refill leaves Rec on the last inserted row
//   (no FindFirst), as in the report. Reads: right after the action, after Filter.SetFilter on "Field No." and First, after Next, with
//   a filter no row matches, and after the filter is removed. Opened with OpenView and run modally through a ModalPageHandler.
// Existing pins: testpage/UjTempList.al (the same refills read through field-bound controls only), testpage/RmTempRefill.al (a Worksheet
//   that refills Rec), pages/expression-refresh/Y17ExprRefresh.al (a function control in a Worksheet after an action inserts one row).
// BC versions: 27, 28, 29 by CI

table 66410 "TP TmpExpr Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Field No."; Integer) { }
        field(3; "Old Value"; Text[50]) { }
        field(4; "New Value"; Text[50]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }

    procedure GetLocalOld(): Text
    begin
        if "Old Value" = '' then
            exit('');
        exit('L:' + "Old Value");
    end;

    procedure GetLocalNew(): Text
    begin
        if "New Value" = '' then
            exit('');
        exit('L:' + "New Value");
    end;
}

page 66411 "TP TmpExpr List"
{
    PageType = List;
    SourceTable = "TP TmpExpr Row";
    SourceTableTemporary = true;
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntryNoCtl; Rec."Entry No.") { ApplicationArea = All; }
                field(FieldNoCtl; Rec."Field No.") { ApplicationArea = All; }
                field(OldValueCtl; Rec."Old Value") { ApplicationArea = All; }
                field(OldLocalCtl; Rec.GetLocalOld()) { ApplicationArea = All; }
                field(NewLocalCtl; Rec.GetLocalNew()) { ApplicationArea = All; }
                field(FormatCtl; Format(Rec."Field No.")) { ApplicationArea = All; }
                field(ConcatCtl; Rec."Old Value" + '>' + Rec."New Value") { ApplicationArea = All; }
                field(FillCtl; FillName) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ThreeOther)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Fill('three other');
                end;
            }
            action(ThreeOtherUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Fill('three other');
                    CurrPage.Update(false);
                end;
            }
            action(SameKeys)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Fill('same keys');
                end;
            }
            action(OneRow)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Fill('one row');
                end;
            }
            action(NoRow)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Fill('no row');
                end;
            }
            action(NoRowUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Fill('no row');
                    CurrPage.Update(false);
                end;
            }
            action(ThreeOtherFindFirst)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Fill('three other');
                    if Rec.FindFirst() then;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Fill('open');
    end;

    var
        FillName: Text;

    local procedure Fill(Name: Text)
    begin
        FillName := Name;
        if not Rec.IsEmpty() then
            Rec.DeleteAll();
        case Name of
            'open':
                begin
                    AddRow(1, 7, 'a1', 'b1');
                    AddRow(2, 8, 'a2', 'b2');
                end;
            'three other':
                begin
                    AddRow(11, 7, 'm1', 'n1');
                    AddRow(12, 9, 'm2', 'n2');
                    AddRow(13, 7, 'm3', 'n3');
                end;
            'same keys':
                begin
                    AddRow(1, 7, 'x1', 'y1');
                    AddRow(2, 8, 'x2', 'y2');
                end;
            'one row':
                AddRow(21, 7, 'o1', 'p1');
        end;
    end;

    local procedure AddRow(EntryNo: Integer; FieldNo: Integer; OldValue: Text[50]; NewValue: Text[50])
    begin
        Rec.Init();
        Rec."Entry No." := EntryNo;
        Rec."Field No." := FieldNo;
        Rec."Old Value" := OldValue;
        Rec."New Value" := NewValue;
        Rec.Insert();
    end;
}

codeunit 66412 "TP TmpExpr Tests"
{
    Subtype = Test;

    var
        ModalObserver: Codeunit "Probe Observer";
        ModalAction: Text;
        ModalFilter: Text;

    local procedure Initialize()
    var
        R: Record "TP TmpExpr Row";
    begin
        R.DeleteAll();
    end;

    [TryFunction]
    local procedure TryCurrent(var H: TestPage "TP TmpExpr List"; var Result: Text)
    begin
        Result := StrSubstNo('%1 f=%2 old=%3 oldlocal=%4 newlocal=%5 format=%6 concat=%7 fill=%8', H.EntryNoCtl.Value(), H.FieldNoCtl.Value(), H.OldValueCtl.Value(),
            H.OldLocalCtl.Value(), H.NewLocalCtl.Value(), H.FormatCtl.Value(), H.ConcatCtl.Value(), H.FillCtl.Value());
    end;

    local procedure Current(var H: TestPage "TP TmpExpr List"): Text
    var
        Result: Text;
    begin
        if TryCurrent(H, Result) then
            exit(Result);
        Result := 'E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']';
        ClearLastError();
        exit(Result);
    end;

    local procedure Invoke(var H: TestPage "TP TmpExpr List"; ActionName: Text)
    begin
        case ActionName of
            'ThreeOther':
                H.ThreeOther.Invoke();
            'ThreeOtherUpdate':
                H.ThreeOtherUpdate.Invoke();
            'SameKeys':
                H.SameKeys.Invoke();
            'OneRow':
                H.OneRow.Invoke();
            'NoRow':
                H.NoRow.Invoke();
            'NoRowUpdate':
                H.NoRowUpdate.Invoke();
            'ThreeOtherFindFirst':
                H.ThreeOtherFindFirst.Invoke();
            'none':
                ;
            else
                Error('unknown action %1', ActionName);
        end;
    end;

    local procedure Steps(var Observer: Codeunit "Probe Observer"; var H: TestPage "TP TmpExpr List"; ActionName: Text; FilterValue: Text)
    var
        Moved: Boolean;
    begin
        Observer.Observe('opened', Current(H));
        Invoke(H, ActionName);
        Observer.Observe('after action', Current(H));
        H.Filter.SetFilter("Field No.", FilterValue);
        Observer.Observe('after filter ' + FilterValue, Current(H));
        Moved := H.First();
        Observer.Observe('first', Format(Moved, 0, 9) + ' ' + Current(H));
        Moved := H.Next();
        Observer.Observe('next', Format(Moved, 0, 9) + ' ' + Current(H));
        H.Filter.SetFilter("Field No.", '');
        Moved := H.First();
        Observer.Observe('filter removed, first', Format(Moved, 0, 9) + ' ' + Current(H));
        Moved := H.Last();
        Observer.Observe('last', Format(Moved, 0, 9) + ' ' + Current(H));
    end;

    local procedure ViewCase(ActionName: Text; FilterValue: Text; var Observer: Codeunit "Probe Observer")
    var
        H: TestPage "TP TmpExpr List";
    begin
        Initialize();
        H.OpenView();
        Steps(Observer, H, ActionName, FilterValue);
        H.Close();
    end;

    local procedure ModalCase(ActionName: Text; FilterValue: Text)
    var
        P: Page "TP TmpExpr List";
    begin
        Initialize();
        ModalAction := ActionName;
        ModalFilter := FilterValue;
        P.RunModal();
    end;

    [ModalPageHandler]
    procedure ListHandler(var H: TestPage "TP TmpExpr List")
    begin
        Steps(ModalObserver, H, ModalAction, ModalFilter);
        H.OK().Invoke();
    end;

    [Test]
    procedure OpenView_NoAction_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCase('none', '7', Observer);
        Observer.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        Observer.Expect('after action', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        Observer.Expect('after filter 7', '1 f=7 old=a1 oldlocal=L:a1 newlocal=L:b1 format=7 concat=a1>b1 fill=open');
        Observer.Expect('first', 'true 1 f=7 old=a1 oldlocal=L:a1 newlocal=L:b1 format=7 concat=a1>b1 fill=open');
        Observer.Expect('next', 'false 1 f=7 old=a1 oldlocal=L:a1 newlocal=L:b1 format=7 concat=a1>b1 fill=open');
        Observer.Expect('filter removed, first', 'true 1 f=7 old=a1 oldlocal=L:a1 newlocal=L:b1 format=7 concat=a1>b1 fill=open');
        Observer.Expect('last', 'true 2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_ThreeOtherRows_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCase('ThreeOther', '7', Observer);
        Observer.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        Observer.Expect('after action', '13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        Observer.Expect('after filter 7', '11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        Observer.Expect('first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        Observer.Expect('next', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        Observer.Expect('filter removed, first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        Observer.Expect('last', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_ThreeOtherRows_FilterOnSecondRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCase('ThreeOther', '9', Observer);
        Observer.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        Observer.Expect('after action', '13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        Observer.Expect('after filter 9', '12 f=9 old=m2 oldlocal=L:m2 newlocal=L:n2 format=9 concat=m2>n2 fill=three other');
        Observer.Expect('first', 'true 12 f=9 old=m2 oldlocal=L:m2 newlocal=L:n2 format=9 concat=m2>n2 fill=three other');
        Observer.Expect('next', 'false 12 f=9 old=m2 oldlocal=L:m2 newlocal=L:n2 format=9 concat=m2>n2 fill=three other');
        Observer.Expect('filter removed, first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        Observer.Expect('last', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_ThreeOtherRows_FilterWithoutMatch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCase('ThreeOther', '5', Observer);
        Observer.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        Observer.Expect('after action', '13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        Observer.Expect('after filter 5', ' f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('first', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('next', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('filter removed, first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        Observer.Expect('last', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_ThreeOtherRowsWithUpdate_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCase('ThreeOtherUpdate', '7', Observer);
        Observer.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        Observer.Expect('after action', '13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        Observer.Expect('after filter 7', '11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        Observer.Expect('first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        Observer.Expect('next', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        Observer.Expect('filter removed, first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        Observer.Expect('last', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_ThreeOtherRowsFindFirst_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCase('ThreeOtherFindFirst', '7', Observer);
        Observer.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        Observer.Expect('after action', '11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        Observer.Expect('after filter 7', '11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        Observer.Expect('first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        Observer.Expect('next', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        Observer.Expect('filter removed, first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        Observer.Expect('last', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_SameKeysOtherValues_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCase('SameKeys', '7', Observer);
        Observer.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        Observer.Expect('after action', '2 f=8 old=x2 oldlocal=L:x2 newlocal=L:y2 format=8 concat=x2>y2 fill=same keys');
        Observer.Expect('after filter 7', '1 f=7 old=x1 oldlocal=L:x1 newlocal=L:y1 format=7 concat=x1>y1 fill=same keys');
        Observer.Expect('first', 'true 1 f=7 old=x1 oldlocal=L:x1 newlocal=L:y1 format=7 concat=x1>y1 fill=same keys');
        Observer.Expect('next', 'false 1 f=7 old=x1 oldlocal=L:x1 newlocal=L:y1 format=7 concat=x1>y1 fill=same keys');
        Observer.Expect('filter removed, first', 'true 1 f=7 old=x1 oldlocal=L:x1 newlocal=L:y1 format=7 concat=x1>y1 fill=same keys');
        Observer.Expect('last', 'true 2 f=8 old=x2 oldlocal=L:x2 newlocal=L:y2 format=8 concat=x2>y2 fill=same keys');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_OneRow_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCase('OneRow', '7', Observer);
        Observer.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        Observer.Expect('after action', '21 f=7 old=o1 oldlocal=L:o1 newlocal=L:p1 format=7 concat=o1>p1 fill=one row');
        Observer.Expect('after filter 7', '21 f=7 old=o1 oldlocal=L:o1 newlocal=L:p1 format=7 concat=o1>p1 fill=one row');
        Observer.Expect('first', 'true 21 f=7 old=o1 oldlocal=L:o1 newlocal=L:p1 format=7 concat=o1>p1 fill=one row');
        Observer.Expect('next', 'false 21 f=7 old=o1 oldlocal=L:o1 newlocal=L:p1 format=7 concat=o1>p1 fill=one row');
        Observer.Expect('filter removed, first', 'true 21 f=7 old=o1 oldlocal=L:o1 newlocal=L:p1 format=7 concat=o1>p1 fill=one row');
        Observer.Expect('last', 'true 21 f=7 old=o1 oldlocal=L:o1 newlocal=L:p1 format=7 concat=o1>p1 fill=one row');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_NoRow_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCase('NoRow', '7', Observer);
        Observer.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        Observer.Expect('after action', ' f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('after filter 7', ' f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('first', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('next', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('filter removed, first', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('last', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_NoRowWithUpdate_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCase('NoRowUpdate', '7', Observer);
        Observer.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        Observer.Expect('after action', ' f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('after filter 7', ' f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('first', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('next', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('filter removed, first', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Expect('last', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_NoAction_FilterAndFirst()
    begin
        ModalCase('none', '7');
        ModalObserver.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        ModalObserver.Expect('after action', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        ModalObserver.Expect('after filter 7', '1 f=7 old=a1 oldlocal=L:a1 newlocal=L:b1 format=7 concat=a1>b1 fill=open');
        ModalObserver.Expect('first', 'true 1 f=7 old=a1 oldlocal=L:a1 newlocal=L:b1 format=7 concat=a1>b1 fill=open');
        ModalObserver.Expect('next', 'false 1 f=7 old=a1 oldlocal=L:a1 newlocal=L:b1 format=7 concat=a1>b1 fill=open');
        ModalObserver.Expect('filter removed, first', 'true 1 f=7 old=a1 oldlocal=L:a1 newlocal=L:b1 format=7 concat=a1>b1 fill=open');
        ModalObserver.Expect('last', 'true 2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        ModalObserver.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_ThreeOtherRows_FilterAndFirst()
    begin
        ModalCase('ThreeOther', '7');
        ModalObserver.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        ModalObserver.Expect('after action', '13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        ModalObserver.Expect('after filter 7', '11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        ModalObserver.Expect('first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        ModalObserver.Expect('next', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        ModalObserver.Expect('filter removed, first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        ModalObserver.Expect('last', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        ModalObserver.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_ThreeOtherRows_FilterWithoutMatch()
    begin
        ModalCase('ThreeOther', '5');
        ModalObserver.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        ModalObserver.Expect('after action', '13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        ModalObserver.Expect('after filter 5', ' f= old= oldlocal= newlocal= format= concat= fill=');
        ModalObserver.Expect('first', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        ModalObserver.Expect('next', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        ModalObserver.Expect('filter removed, first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        ModalObserver.Expect('last', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        ModalObserver.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_ThreeOtherRowsWithUpdate_FilterAndFirst()
    begin
        ModalCase('ThreeOtherUpdate', '7');
        ModalObserver.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        ModalObserver.Expect('after action', '13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        ModalObserver.Expect('after filter 7', '11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        ModalObserver.Expect('first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        ModalObserver.Expect('next', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        ModalObserver.Expect('filter removed, first', 'true 11 f=7 old=m1 oldlocal=L:m1 newlocal=L:n1 format=7 concat=m1>n1 fill=three other');
        ModalObserver.Expect('last', 'true 13 f=7 old=m3 oldlocal=L:m3 newlocal=L:n3 format=7 concat=m3>n3 fill=three other');
        ModalObserver.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_SameKeysOtherValues_FilterAndFirst()
    begin
        ModalCase('SameKeys', '8');
        ModalObserver.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        ModalObserver.Expect('after action', '2 f=8 old=x2 oldlocal=L:x2 newlocal=L:y2 format=8 concat=x2>y2 fill=same keys');
        ModalObserver.Expect('after filter 8', '2 f=8 old=x2 oldlocal=L:x2 newlocal=L:y2 format=8 concat=x2>y2 fill=same keys');
        ModalObserver.Expect('first', 'true 2 f=8 old=x2 oldlocal=L:x2 newlocal=L:y2 format=8 concat=x2>y2 fill=same keys');
        ModalObserver.Expect('next', 'false 2 f=8 old=x2 oldlocal=L:x2 newlocal=L:y2 format=8 concat=x2>y2 fill=same keys');
        ModalObserver.Expect('filter removed, first', 'true 1 f=7 old=x1 oldlocal=L:x1 newlocal=L:y1 format=7 concat=x1>y1 fill=same keys');
        ModalObserver.Expect('last', 'true 2 f=8 old=x2 oldlocal=L:x2 newlocal=L:y2 format=8 concat=x2>y2 fill=same keys');
        ModalObserver.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_NoRow_FilterAndFirst()
    begin
        ModalCase('NoRow', '7');
        ModalObserver.Expect('opened', '2 f=8 old=a2 oldlocal=L:a2 newlocal=L:b2 format=8 concat=a2>b2 fill=open');
        ModalObserver.Expect('after action', ' f= old= oldlocal= newlocal= format= concat= fill=');
        ModalObserver.Expect('after filter 7', ' f= old= oldlocal= newlocal= format= concat= fill=');
        ModalObserver.Expect('first', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        ModalObserver.Expect('next', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        ModalObserver.Expect('filter removed, first', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        ModalObserver.Expect('last', 'false  f= old= oldlocal= newlocal= format= concat= fill=');
        ModalObserver.Verify();
    end;
}
