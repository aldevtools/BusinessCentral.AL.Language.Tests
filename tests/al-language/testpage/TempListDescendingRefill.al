// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 66413, pages 66414 and 66415, test codeunit 66416
// local object: the pages' expression-bound controls, their temporary source table, their SourceTableView and their refill actions are what
//   the tests measure.
// Probe (al-runner issue 7419, the reporter's own page shape: a non-editable List over a temporary source table with
//   `SourceTableView = sorting(...) order(descending)`, whose OnOpenPage and actions refill Rec; controls bound to methods of the record;
//   the handler invokes an action, sets a TestPage filter on "Field No.", goes to the first row and reads the method-bound controls):
//   observation form, the values are read from the corpus CI matrix.
// Area: testpage/TempListExpressionRefill.al pins the same page without a SourceTableView. Here the same refills and reads on a List
//   whose SourceTableView sorts descending, once by the primary key and once by a second key whose order differs from the primary key's
//   (as in the report: sorting("Table No.", "Date and Time") order(descending)). Refills: three other rows, three other rows then
//   FindFirst, no row. Reads: right after the action, after Filter.SetFilter on "Field No." and First, after Next, with a filter no row
//   matches, after the filter is removed, and Last. Opened with OpenView and run modally through a ModalPageHandler.
// BC versions: 27, 28, 29 by CI

table 66413 "TP TmpExprD Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Group No."; Integer) { }
        field(3; Stamp; Integer) { }
        field(4; "Field No."; Integer) { }
        field(5; "Old Value"; Text[50]) { }
        field(6; "New Value"; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByStamp; "Group No.", Stamp) { }
    }

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

page 66414 "TP TmpExprD PkDesc"
{
    PageType = List;
    SourceTable = "TP TmpExprD Row";
    SourceTableTemporary = true;
    SourceTableView = sorting("Entry No.") order(descending);
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
                field(StampCtl; Rec.Stamp) { ApplicationArea = All; }
                field(FieldNoCtl; Rec."Field No.") { ApplicationArea = All; }
                field(OldValueCtl; Rec."Old Value") { ApplicationArea = All; }
                field(OldLocalCtl; Rec.GetLocalOld()) { ApplicationArea = All; }
                field(NewLocalCtl; Rec.GetLocalNew()) { ApplicationArea = All; }
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
            action(ThreeOtherFindFirst)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Fill('three other');
                    if Rec.FindFirst() then;
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
                    AddRow(1, 20, 7, 'a1', 'b1');
                    AddRow(2, 10, 8, 'a2', 'b2');
                    AddRow(3, 30, 7, 'a3', 'b3');
                end;
            'three other':
                begin
                    AddRow(11, 5, 7, 'm1', 'n1');
                    AddRow(12, 40, 9, 'm2', 'n2');
                    AddRow(13, 15, 7, 'm3', 'n3');
                end;
        end;
    end;

    local procedure AddRow(EntryNo: Integer; StampValue: Integer; FieldNo: Integer; OldValue: Text[50]; NewValue: Text[50])
    begin
        Rec.Init();
        Rec."Entry No." := EntryNo;
        Rec."Group No." := 1;
        Rec.Stamp := StampValue;
        Rec."Field No." := FieldNo;
        Rec."Old Value" := OldValue;
        Rec."New Value" := NewValue;
        Rec.Insert();
    end;
}

page 66415 "TP TmpExprD KeyDesc"
{
    PageType = List;
    SourceTable = "TP TmpExprD Row";
    SourceTableTemporary = true;
    SourceTableView = sorting("Group No.", Stamp) order(descending);
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
                field(StampCtl; Rec.Stamp) { ApplicationArea = All; }
                field(FieldNoCtl; Rec."Field No.") { ApplicationArea = All; }
                field(OldValueCtl; Rec."Old Value") { ApplicationArea = All; }
                field(OldLocalCtl; Rec.GetLocalOld()) { ApplicationArea = All; }
                field(NewLocalCtl; Rec.GetLocalNew()) { ApplicationArea = All; }
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
            action(ThreeOtherFindFirst)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Fill('three other');
                    if Rec.FindFirst() then;
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
                    AddRow(1, 20, 7, 'a1', 'b1');
                    AddRow(2, 10, 8, 'a2', 'b2');
                    AddRow(3, 30, 7, 'a3', 'b3');
                end;
            'three other':
                begin
                    AddRow(11, 5, 7, 'm1', 'n1');
                    AddRow(12, 40, 9, 'm2', 'n2');
                    AddRow(13, 15, 7, 'm3', 'n3');
                end;
        end;
    end;

    local procedure AddRow(EntryNo: Integer; StampValue: Integer; FieldNo: Integer; OldValue: Text[50]; NewValue: Text[50])
    begin
        Rec.Init();
        Rec."Entry No." := EntryNo;
        Rec."Group No." := 1;
        Rec.Stamp := StampValue;
        Rec."Field No." := FieldNo;
        Rec."Old Value" := OldValue;
        Rec."New Value" := NewValue;
        Rec.Insert();
    end;
}

codeunit 66416 "TP TmpExprD Tests"
{
    Subtype = Test;

    var
        ModalObserver: Codeunit "Probe Observer";
        ModalAction: Text;
        ModalFilter: Text;

    local procedure Initialize()
    var
        R: Record "TP TmpExprD Row";
    begin
        R.DeleteAll();
    end;

    [TryFunction]
    local procedure TryCurrentPK(var H: TestPage "TP TmpExprD PkDesc"; var Result: Text)
    begin
        Result := StrSubstNo('%1 s=%2 f=%3 old=%4 oldlocal=%5 newlocal=%6 fill=%7', H.EntryNoCtl.Value(), H.StampCtl.Value(), H.FieldNoCtl.Value(),
            H.OldValueCtl.Value(), H.OldLocalCtl.Value(), H.NewLocalCtl.Value(), H.FillCtl.Value());
    end;

    local procedure CurrentPK(var H: TestPage "TP TmpExprD PkDesc"): Text
    var
        Result: Text;
    begin
        if TryCurrentPK(H, Result) then
            exit(Result);
        Result := 'E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']';
        ClearLastError();
        exit(Result);
    end;

    local procedure InvokePK(var H: TestPage "TP TmpExprD PkDesc"; ActionName: Text)
    begin
        case ActionName of
            'ThreeOther':
                H.ThreeOther.Invoke();
            'ThreeOtherFindFirst':
                H.ThreeOtherFindFirst.Invoke();
            'NoRow':
                H.NoRow.Invoke();
            'none':
                ;
            else
                Error('unknown action %1', ActionName);
        end;
    end;

    local procedure StepsPK(var Observer: Codeunit "Probe Observer"; var H: TestPage "TP TmpExprD PkDesc"; ActionName: Text; FilterValue: Text)
    var
        Moved: Boolean;
    begin
        Observer.Observe('opened', CurrentPK(H));
        InvokePK(H, ActionName);
        Observer.Observe('after action', CurrentPK(H));
        H.Filter.SetFilter("Field No.", FilterValue);
        Observer.Observe('after filter ' + FilterValue, CurrentPK(H));
        Moved := H.First();
        Observer.Observe('first', Format(Moved, 0, 9) + ' ' + CurrentPK(H));
        Moved := H.Next();
        Observer.Observe('next', Format(Moved, 0, 9) + ' ' + CurrentPK(H));
        H.Filter.SetFilter("Field No.", '');
        Moved := H.First();
        Observer.Observe('filter removed, first', Format(Moved, 0, 9) + ' ' + CurrentPK(H));
        Moved := H.Next();
        Observer.Observe('filter removed, next', Format(Moved, 0, 9) + ' ' + CurrentPK(H));
        Moved := H.Last();
        Observer.Observe('last', Format(Moved, 0, 9) + ' ' + CurrentPK(H));
    end;

    local procedure ViewCasePK(ActionName: Text; FilterValue: Text; var Observer: Codeunit "Probe Observer")
    var
        H: TestPage "TP TmpExprD PkDesc";
    begin
        Initialize();
        H.OpenView();
        StepsPK(Observer, H, ActionName, FilterValue);
        H.Close();
    end;

    local procedure ModalCasePK(ActionName: Text; FilterValue: Text)
    var
        P: Page "TP TmpExprD PkDesc";
    begin
        Initialize();
        ModalAction := ActionName;
        ModalFilter := FilterValue;
        P.RunModal();
    end;

    [ModalPageHandler]
    procedure ListHandlerPK(var H: TestPage "TP TmpExprD PkDesc")
    begin
        StepsPK(ModalObserver, H, ModalAction, ModalFilter);
        H.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryCurrentKEY(var H: TestPage "TP TmpExprD KeyDesc"; var Result: Text)
    begin
        Result := StrSubstNo('%1 s=%2 f=%3 old=%4 oldlocal=%5 newlocal=%6 fill=%7', H.EntryNoCtl.Value(), H.StampCtl.Value(), H.FieldNoCtl.Value(),
            H.OldValueCtl.Value(), H.OldLocalCtl.Value(), H.NewLocalCtl.Value(), H.FillCtl.Value());
    end;

    local procedure CurrentKEY(var H: TestPage "TP TmpExprD KeyDesc"): Text
    var
        Result: Text;
    begin
        if TryCurrentKEY(H, Result) then
            exit(Result);
        Result := 'E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']';
        ClearLastError();
        exit(Result);
    end;

    local procedure InvokeKEY(var H: TestPage "TP TmpExprD KeyDesc"; ActionName: Text)
    begin
        case ActionName of
            'ThreeOther':
                H.ThreeOther.Invoke();
            'ThreeOtherFindFirst':
                H.ThreeOtherFindFirst.Invoke();
            'NoRow':
                H.NoRow.Invoke();
            'none':
                ;
            else
                Error('unknown action %1', ActionName);
        end;
    end;

    local procedure StepsKEY(var Observer: Codeunit "Probe Observer"; var H: TestPage "TP TmpExprD KeyDesc"; ActionName: Text; FilterValue: Text)
    var
        Moved: Boolean;
    begin
        Observer.Observe('opened', CurrentKEY(H));
        InvokeKEY(H, ActionName);
        Observer.Observe('after action', CurrentKEY(H));
        H.Filter.SetFilter("Field No.", FilterValue);
        Observer.Observe('after filter ' + FilterValue, CurrentKEY(H));
        Moved := H.First();
        Observer.Observe('first', Format(Moved, 0, 9) + ' ' + CurrentKEY(H));
        Moved := H.Next();
        Observer.Observe('next', Format(Moved, 0, 9) + ' ' + CurrentKEY(H));
        H.Filter.SetFilter("Field No.", '');
        Moved := H.First();
        Observer.Observe('filter removed, first', Format(Moved, 0, 9) + ' ' + CurrentKEY(H));
        Moved := H.Next();
        Observer.Observe('filter removed, next', Format(Moved, 0, 9) + ' ' + CurrentKEY(H));
        Moved := H.Last();
        Observer.Observe('last', Format(Moved, 0, 9) + ' ' + CurrentKEY(H));
    end;

    local procedure ViewCaseKEY(ActionName: Text; FilterValue: Text; var Observer: Codeunit "Probe Observer")
    var
        H: TestPage "TP TmpExprD KeyDesc";
    begin
        Initialize();
        H.OpenView();
        StepsKEY(Observer, H, ActionName, FilterValue);
        H.Close();
    end;

    local procedure ModalCaseKEY(ActionName: Text; FilterValue: Text)
    var
        P: Page "TP TmpExprD KeyDesc";
    begin
        Initialize();
        ModalAction := ActionName;
        ModalFilter := FilterValue;
        P.RunModal();
    end;

    [ModalPageHandler]
    procedure ListHandlerKEY(var H: TestPage "TP TmpExprD KeyDesc")
    begin
        StepsKEY(ModalObserver, H, ModalAction, ModalFilter);
        H.OK().Invoke();
    end;

    [Test]
    procedure PkDescending_OpenView_NoAction_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCasePK('none', '7', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure PkDescending_OpenView_ThreeOtherRows_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCasePK('ThreeOther', '7', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure PkDescending_OpenView_ThreeOtherRows_FilterOnSecondRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCasePK('ThreeOther', '9', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure PkDescending_OpenView_ThreeOtherRows_FilterWithoutMatch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCasePK('ThreeOther', '5', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure PkDescending_OpenView_ThreeOtherRowsFindFirst_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCasePK('ThreeOtherFindFirst', '7', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure PkDescending_OpenView_NoRow_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCasePK('NoRow', '7', Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandlerPK')]
    procedure PkDescending_RunModal_NoAction_FilterAndFirst()
    begin
        ModalCasePK('none', '7');
        ModalObserver.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandlerPK')]
    procedure PkDescending_RunModal_ThreeOtherRows_FilterAndFirst()
    begin
        ModalCasePK('ThreeOther', '7');
        ModalObserver.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandlerPK')]
    procedure PkDescending_RunModal_ThreeOtherRows_FilterWithoutMatch()
    begin
        ModalCasePK('ThreeOther', '5');
        ModalObserver.Finish();
    end;

    [Test]
    procedure KeyDescending_OpenView_NoAction_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCaseKEY('none', '7', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure KeyDescending_OpenView_ThreeOtherRows_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCaseKEY('ThreeOther', '7', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure KeyDescending_OpenView_ThreeOtherRows_FilterOnSecondRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCaseKEY('ThreeOther', '9', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure KeyDescending_OpenView_ThreeOtherRows_FilterWithoutMatch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCaseKEY('ThreeOther', '5', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure KeyDescending_OpenView_ThreeOtherRowsFindFirst_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCaseKEY('ThreeOtherFindFirst', '7', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure KeyDescending_OpenView_NoRow_FilterAndFirst()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ViewCaseKEY('NoRow', '7', Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandlerKEY')]
    procedure KeyDescending_RunModal_NoAction_FilterAndFirst()
    begin
        ModalCaseKEY('none', '7');
        ModalObserver.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandlerKEY')]
    procedure KeyDescending_RunModal_ThreeOtherRows_FilterAndFirst()
    begin
        ModalCaseKEY('ThreeOther', '7');
        ModalObserver.Finish();
    end;

    [Test]
    [HandlerFunctions('ListHandlerKEY')]
    procedure KeyDescending_RunModal_ThreeOtherRows_FilterWithoutMatch()
    begin
        ModalCaseKEY('ThreeOther', '5');
        ModalObserver.Finish();
    end;
}
