// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 97430-97433 (TP TmpFilter Row, TP TmpFilter List, TP TmpFilter Phys List,
//   TP TmpFilter Tests)
// Probe: from al-runner issue 6924 (a search list on a temporary source table that an action fills; the test then filters on a Boolean
//   field of the source table that has no control on the page, with the text '=1', and calls First()).
// Area: TestPage.Filter.SetFilter on a Boolean field of a list page, crossed with
//   - the source table: temporary (SourceTableTemporary = true, rows written by an action) or a database table;
//   - the field: Hidden has NO control on the page (it is only read by StyleExpr), Shown has a control;
//   - the filter text: '=1', '=0', '=Yes', '=No', '=true', '=false', '1', '0';
//   - the action: Fill (DeleteAll, four rows, FindFirst, CurrPage.Update(false)), FillPlain (DeleteAll and four rows, nothing else),
//     FillOne (one row with Hidden = false and Shown = false, FindFirst, CurrPage.Update(false)).
//   Each case reads: the rows before the action, the rows after it, whether SetFilter raised (code and text), the filter read back,
//   and the rows First()/Next() walk afterwards ('none' when First() is false).
// Already pinned elsewhere, not repeated: a filter on a Text field without a control on a database list (TestTestFilter.al,
//   TestFilter_SetFilter_AppliesToAFieldWithNoControlOnThePage), Record.SetFilter with Boolean words (TestFilterTextBooleanFindContracts.al,
//   SetFilter_BooleanField_AcceptedWords; BooleanFilterByLanguage.al), a filter on a field WITH a control on a temporary list that an
//   action rebuilt (UjTempList.al).
// local object: the page shape is what the test checks (SourceTableTemporary, a field with no control that StyleExpr reads).
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

table 97430 "TP TmpFilter Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Hidden; Boolean) { }
        field(4; Shown; Boolean) { }
        field(5; Kind; Option)
        {
            OptionMembers = Quote,"Order";
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 97431 "TP TmpFilter List"
{
    PageType = List;
    SourceTable = "TP TmpFilter Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Caption = 'TP TmpFilter List';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id)
                {
                    ApplicationArea = All;
                    StyleExpr = Rec.Hidden;
                    Style = Strong;
                }
                field(NameCtl; Rec.Name)
                {
                    ApplicationArea = All;
                    StyleExpr = Rec.Hidden;
                    Style = Strong;
                }
                field(ShownCtl; Rec.Shown) { ApplicationArea = All; }
                field(KindCtl; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Fill)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    FourRows();
                    if Rec.FindFirst() then;
                    CurrPage.Update(false);
                end;
            }
            action(FillPlain)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    FourRows();
                end;
            }
            action(FillOne)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Reset();
                    Rec.DeleteAll();
                    AddRow(1, 'A', false, false, Rec.Kind::Quote);
                    if Rec.FindFirst() then;
                    CurrPage.Update(false);
                end;
            }
        }
    }

    local procedure FourRows()
    begin
        Rec.Reset();
        Rec.DeleteAll();
        AddRow(1, 'A', false, false, Rec.Kind::Quote);
        AddRow(2, 'B', true, false, Rec.Kind::"Order");
        AddRow(3, 'C', false, true, Rec.Kind::Quote);
        AddRow(4, 'D', true, true, Rec.Kind::"Order");
    end;

    local procedure AddRow(NewId: Integer; NewName: Text[30]; NewHidden: Boolean; NewShown: Boolean; NewKind: Option)
    begin
        Rec.Init();
        Rec.Id := NewId;
        Rec.Name := NewName;
        Rec.Hidden := NewHidden;
        Rec.Shown := NewShown;
        Rec.Kind := NewKind;
        Rec.Insert();
    end;
}

page 97432 "TP TmpFilter Phys List"
{
    PageType = List;
    SourceTable = "TP TmpFilter Row";
    ApplicationArea = All;
    Caption = 'TP TmpFilter Phys List';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id)
                {
                    ApplicationArea = All;
                    StyleExpr = Rec.Hidden;
                    Style = Strong;
                }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(ShownCtl; Rec.Shown) { ApplicationArea = All; }
                field(KindCtl; Rec.Kind) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 97433 "TP TmpFilter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "TP TmpFilter Row";
    begin
        Row.DeleteAll();
        ClearLastError();
    end;

    local procedure Walk(var P: TestPage "TP TmpFilter List"): Text
    var
        Ids: Text;
    begin
        if not P.First() then
            exit('none');
        repeat
            Ids += P.IdCtl.Value() + ',';
        until not P.Next();
        exit(Ids);
    end;

    local procedure WalkPhys(var P: TestPage "TP TmpFilter Phys List"): Text
    var
        Ids: Text;
    begin
        if not P.First() then
            exit('none');
        repeat
            Ids += P.IdCtl.Value() + ',';
        until not P.Next();
        exit(Ids);
    end;

    [TryFunction]
    local procedure TrySet(var P: TestPage "TP TmpFilter List"; FieldName: Text; FilterText: Text)
    begin
        case FieldName of
            'Hidden':
                P.Filter.SetFilter(Hidden, FilterText);
            'Shown':
                P.Filter.SetFilter(Shown, FilterText);
            'Kind':
                P.Filter.SetFilter(Kind, FilterText);
        end;
    end;

    [TryFunction]
    local procedure TrySetPhys(var P: TestPage "TP TmpFilter Phys List"; FieldName: Text; FilterText: Text)
    begin
        case FieldName of
            'Hidden':
                P.Filter.SetFilter(Hidden, FilterText);
            'Shown':
                P.Filter.SetFilter(Shown, FilterText);
            'Kind':
                P.Filter.SetFilter(Kind, FilterText);
        end;
    end;

    local procedure ReadFilter(var P: TestPage "TP TmpFilter List"; FieldName: Text): Text
    begin
        case FieldName of
            'Hidden':
                exit(P.Filter.GetFilter(Hidden));
            'Shown':
                exit(P.Filter.GetFilter(Shown));
            'Kind':
                exit(P.Filter.GetFilter(Kind));
        end;
    end;

    local procedure ReadFilterPhys(var P: TestPage "TP TmpFilter Phys List"; FieldName: Text): Text
    begin
        case FieldName of
            'Hidden':
                exit(P.Filter.GetFilter(Hidden));
            'Shown':
                exit(P.Filter.GetFilter(Shown));
            'Kind':
                exit(P.Filter.GetFilter(Kind));
        end;
    end;

    local procedure InvokeFill(var P: TestPage "TP TmpFilter List"; ActionName: Text)
    begin
        case ActionName of
            'Fill':
                P.Fill.Invoke();
            'FillPlain':
                P.FillPlain.Invoke();
            'FillOne':
                P.FillOne.Invoke();
        end;
    end;

    // One case on the temporary list: open, action, one filter, walk.
    local procedure TempCase(ActionName: Text; FieldName: Text; FilterText: Text): Text
    var
        P: TestPage "TP TmpFilter List";
        Result: Text;
    begin
        P.OpenView();
        Result := 'open=' + Walk(P);
        InvokeFill(P, ActionName);
        Result += ' filled=' + Walk(P);
        ClearLastError();
        if TrySet(P, FieldName, FilterText) then begin
            Result += ' filter=' + ReadFilter(P, FieldName);
            Result += ' rows=' + Walk(P);
        end else
            Result += ' error=' + GetLastErrorCode() + ':' + GetLastErrorText();
        P.Close();
        exit(Result);
    end;

    // One case on the database list: three of the four rows exist before the page opens, one filter, walk.
    local procedure PhysCase(FieldName: Text; FilterText: Text): Text
    var
        P: TestPage "TP TmpFilter Phys List";
        Result: Text;
    begin
        P.OpenView();
        Result := 'open=' + WalkPhys(P);
        ClearLastError();
        if TrySetPhys(P, FieldName, FilterText) then begin
            Result += ' filter=' + ReadFilterPhys(P, FieldName);
            Result += ' rows=' + WalkPhys(P);
        end else
            Result += ' error=' + GetLastErrorCode() + ':' + GetLastErrorText();
        P.Close();
        exit(Result);
    end;

    local procedure SeedPhys()
    var
        Row: Record "TP TmpFilter Row";
    begin
        Row.DeleteAll();
        AddPhys(1, 'A', false, false, Row.Kind::Quote);
        AddPhys(2, 'B', true, false, Row.Kind::"Order");
        AddPhys(3, 'C', false, true, Row.Kind::Quote);
        AddPhys(4, 'D', true, true, Row.Kind::"Order");
    end;

    local procedure AddPhys(NewId: Integer; NewName: Text[30]; NewHidden: Boolean; NewShown: Boolean; NewKind: Option)
    var
        Row: Record "TP TmpFilter Row";
    begin
        Row.Init();
        Row.Id := NewId;
        Row.Name := NewName;
        Row.Hidden := NewHidden;
        Row.Shown := NewShown;
        Row.Kind := NewKind;
        Row.Insert();
    end;

    [Test]
    procedure TempList_Fill_FieldWithoutControl_BooleanTexts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('=1', TempCase('Fill', 'Hidden', '=1'));
        Observer.Observe('=0', TempCase('Fill', 'Hidden', '=0'));
        Observer.Observe('=Yes', TempCase('Fill', 'Hidden', '=Yes'));
        Observer.Observe('=No', TempCase('Fill', 'Hidden', '=No'));
        Observer.Observe('=true', TempCase('Fill', 'Hidden', '=true'));
        Observer.Observe('=false', TempCase('Fill', 'Hidden', '=false'));
        Observer.Observe('1', TempCase('Fill', 'Hidden', '1'));
        Observer.Observe('0', TempCase('Fill', 'Hidden', '0'));
        Observer.Finish();
    end;

    [Test]
    procedure TempList_Fill_FieldWithControl_BooleanTexts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('=1', TempCase('Fill', 'Shown', '=1'));
        Observer.Observe('=0', TempCase('Fill', 'Shown', '=0'));
        Observer.Observe('=Yes', TempCase('Fill', 'Shown', '=Yes'));
        Observer.Observe('=No', TempCase('Fill', 'Shown', '=No'));
        Observer.Observe('=true', TempCase('Fill', 'Shown', '=true'));
        Observer.Observe('=false', TempCase('Fill', 'Shown', '=false'));
        Observer.Observe('1', TempCase('Fill', 'Shown', '1'));
        Observer.Observe('0', TempCase('Fill', 'Shown', '0'));
        Observer.Finish();
    end;

    [Test]
    procedure TempList_FillPlain_BothFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('hidden =1', TempCase('FillPlain', 'Hidden', '=1'));
        Observer.Observe('hidden =0', TempCase('FillPlain', 'Hidden', '=0'));
        Observer.Observe('hidden =Yes', TempCase('FillPlain', 'Hidden', '=Yes'));
        Observer.Observe('shown =1', TempCase('FillPlain', 'Shown', '=1'));
        Observer.Observe('shown =0', TempCase('FillPlain', 'Shown', '=0'));
        Observer.Observe('shown =Yes', TempCase('FillPlain', 'Shown', '=Yes'));
        Observer.Finish();
    end;

    [Test]
    procedure TempList_FillOne_BothFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // The only row has Hidden = false and Shown = false.
        Initialize();
        Observer.Observe('hidden =1', TempCase('FillOne', 'Hidden', '=1'));
        Observer.Observe('hidden =0', TempCase('FillOne', 'Hidden', '=0'));
        Observer.Observe('hidden =Yes', TempCase('FillOne', 'Hidden', '=Yes'));
        Observer.Observe('hidden =No', TempCase('FillOne', 'Hidden', '=No'));
        Observer.Observe('shown =1', TempCase('FillOne', 'Shown', '=1'));
        Observer.Observe('shown =0', TempCase('FillOne', 'Shown', '=0'));
        Observer.Observe('shown =Yes', TempCase('FillOne', 'Shown', '=Yes'));
        Observer.Observe('shown =No', TempCase('FillOne', 'Shown', '=No'));
        Observer.Finish();
    end;

    [Test]
    procedure TempList_FillOne_FirstThenTwoFiltersThenFirst()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TP TmpFilter List";
    begin
        // The order of the reported test: the action, First(), a filter on the field without a control, a filter on an Option field
        // with a control, First().
        Initialize();
        P.OpenView();
        P.FillOne.Invoke();
        Observer.Observe('first after action', Format(P.First()) + '|' + P.IdCtl.Value());
        P.Filter.SetFilter(Hidden, '=1');
        Observer.Observe('hidden filter', P.Filter.GetFilter(Hidden));
        P.Filter.SetFilter(Kind, '=Quote');
        Observer.Observe('kind filter', P.Filter.GetFilter(Kind));
        Observer.Observe('first after filters', Format(P.First()));
        Observer.Observe('rows after filters', Walk(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TempList_Fill_FirstThenTwoFiltersThenFirst()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TP TmpFilter List";
    begin
        // Four rows: Hidden is true on rows 2 and 4, Kind is Quote on rows 1 and 3, so no row has both.
        Initialize();
        P.OpenView();
        P.Fill.Invoke();
        Observer.Observe('first after action', Format(P.First()) + '|' + P.IdCtl.Value());
        P.Filter.SetFilter(Hidden, '=1');
        Observer.Observe('rows after hidden filter', Walk(P));
        P.Filter.SetFilter(Kind, '=Quote');
        Observer.Observe('first after both filters', Format(P.First()));
        Observer.Observe('rows after both filters', Walk(P));
        P.Filter.SetFilter(Hidden, '=0');
        Observer.Observe('rows after hidden =0 and kind', Walk(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TempList_FilterBeforeAction_FieldWithoutControl()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TP TmpFilter List";
    begin
        // The filter is set on the empty page; the action writes the rows afterwards.
        Initialize();
        P.OpenView();
        P.Filter.SetFilter(Hidden, '=1');
        Observer.Observe('rows before action', Walk(P));
        P.Fill.Invoke();
        Observer.Observe('filter after action', P.Filter.GetFilter(Hidden));
        Observer.Observe('rows after action', Walk(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure DatabaseList_FieldWithoutControl_BooleanTexts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        SeedPhys();
        Observer.Observe('=1', PhysCase('Hidden', '=1'));
        Observer.Observe('=0', PhysCase('Hidden', '=0'));
        Observer.Observe('=Yes', PhysCase('Hidden', '=Yes'));
        Observer.Observe('=No', PhysCase('Hidden', '=No'));
        Observer.Observe('=true', PhysCase('Hidden', '=true'));
        Observer.Observe('=false', PhysCase('Hidden', '=false'));
        Observer.Observe('1', PhysCase('Hidden', '1'));
        Observer.Observe('0', PhysCase('Hidden', '0'));
        Observer.Finish();
    end;

    [Test]
    procedure DatabaseList_FieldWithControl_BooleanTexts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        SeedPhys();
        Observer.Observe('=1', PhysCase('Shown', '=1'));
        Observer.Observe('=0', PhysCase('Shown', '=0'));
        Observer.Observe('=Yes', PhysCase('Shown', '=Yes'));
        Observer.Observe('=No', PhysCase('Shown', '=No'));
        Observer.Observe('=true', PhysCase('Shown', '=true'));
        Observer.Observe('=false', PhysCase('Shown', '=false'));
        Observer.Observe('1', PhysCase('Shown', '1'));
        Observer.Observe('0', PhysCase('Shown', '0'));
        Observer.Finish();
    end;
}
