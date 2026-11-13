// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 76410-76414 (WEQ Doc Type, WEQ Row, WEQ Temp Worksheet, WEQ Temp List,
//   WEQ Phys Worksheet, WEQ Tests)
// Probe: from al-runner issue 6924 (an outside reporter's suite: a search Worksheet on a temporary source table that an action fills; the test
//   filters a Boolean field without a control with '=1', then an Enum field with '=<value>', calls First(), then filters '<>' and calls
//   First() again). TempListOffPageBooleanFilter.al measured a List page with an Option field; this file adds the Worksheet page type, an
//   Enum field (first value and other values), an Option field on the Worksheet, an Enum field on a List, and a Worksheet over a database table.
// Area: TestPage.Filter.SetFilter followed by GetFilter and a walk with First()/Next(), on
//   - pages: WEQ Temp Worksheet (Worksheet, SourceTableTemporary), WEQ Temp List (List, SourceTableTemporary), WEQ Phys Worksheet (Worksheet,
//     database table);
//   - fields: DocType (Enum, control), HidType (Enum, no control), Kind (Option, control), IsHist (Boolean, no control);
//   - texts: '=Quote' (first value), '=Order', '=Invoice', '<>Quote', 'Quote', 'Order', '=0', '=1', '1', and for IsHist '=1', '=0', '1', '0'.
// Rows (Id, DocType = Kind = HidType, IsHist): 1 Quote No, 2 Order No, 3 Invoice Yes, 4 Order Yes. The temporary pages get them from the
//   action Fill (DeleteAll, four rows, FindFirst, CurrPage.Update(false)).
// local object: the page shapes (Worksheet, SourceTableTemporary, a field with no control) are what the test checks.
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0

enum 76410 "WEQ Doc Type"
{
    Extensible = false;

    value(0; Quote) { }
    value(1; "Order") { }
    value(2; Invoice) { }
}

table 76410 "WEQ Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; DocType; Enum "WEQ Doc Type") { }
        field(3; HidType; Enum "WEQ Doc Type") { }
        field(4; Kind; Option)
        {
            OptionMembers = Quote,"Order",Invoice;
        }
        field(5; IsHist; Boolean) { }
        field(6; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure AddRow(NewId: Integer; NewType: Enum "WEQ Doc Type"; NewHist: Boolean)
    begin
        Rec.Init();
        Rec.Id := NewId;
        Rec.DocType := NewType;
        Rec.HidType := NewType;
        Rec.Kind := NewType.AsInteger();
        Rec.IsHist := NewHist;
        Rec.Name := 'R' + Format(NewId);
        Rec.Insert();
    end;

    procedure FourRows()
    begin
        Rec.Reset();
        Rec.DeleteAll();
        AddRow(1, "WEQ Doc Type"::Quote, false);
        AddRow(2, "WEQ Doc Type"::"Order", false);
        AddRow(3, "WEQ Doc Type"::Invoice, true);
        AddRow(4, "WEQ Doc Type"::"Order", true);
    end;
}

page 76411 "WEQ Temp Worksheet"
{
    PageType = Worksheet;
    SourceTable = "WEQ Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'WEQ Temp Worksheet';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(DocTypeCtl; Rec.DocType) { ApplicationArea = All; }
                field(KindCtl; Rec.Kind) { ApplicationArea = All; }
                field(NameCtl; Rec.Name)
                {
                    ApplicationArea = All;
                    StyleExpr = Rec.IsHist;
                    Style = Strong;
                }
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
                    Rec.FourRows();
                    if Rec.FindFirst() then;
                    CurrPage.Update(false);
                end;
            }
        }
    }
}

page 76412 "WEQ Temp List"
{
    PageType = List;
    SourceTable = "WEQ Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'WEQ Temp List';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(DocTypeCtl; Rec.DocType) { ApplicationArea = All; }
                field(KindCtl; Rec.Kind) { ApplicationArea = All; }
                field(NameCtl; Rec.Name)
                {
                    ApplicationArea = All;
                    StyleExpr = Rec.IsHist;
                    Style = Strong;
                }
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
                    Rec.FourRows();
                    if Rec.FindFirst() then;
                    CurrPage.Update(false);
                end;
            }
        }
    }
}

page 76413 "WEQ Phys Worksheet"
{
    PageType = Worksheet;
    SourceTable = "WEQ Row";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'WEQ Phys Worksheet';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(DocTypeCtl; Rec.DocType) { ApplicationArea = All; }
                field(KindCtl; Rec.Kind) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 76414 "WEQ Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "WEQ Row";
    begin
        Row.DeleteAll();
        ClearLastError();
    end;

    // ---- Temp Worksheet ----

    local procedure WalkWs(var P: TestPage "WEQ Temp Worksheet"): Text
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
    local procedure TrySetWs(var P: TestPage "WEQ Temp Worksheet"; FieldName: Text; FilterText: Text)
    begin
        case FieldName of
            'DocType':
                P.Filter.SetFilter(DocType, FilterText);
            'HidType':
                P.Filter.SetFilter(HidType, FilterText);
            'Kind':
                P.Filter.SetFilter(Kind, FilterText);
            'IsHist':
                P.Filter.SetFilter(IsHist, FilterText);
        end;
    end;

    local procedure GetWs(var P: TestPage "WEQ Temp Worksheet"; FieldName: Text): Text
    begin
        case FieldName of
            'DocType':
                exit(P.Filter.GetFilter(DocType));
            'HidType':
                exit(P.Filter.GetFilter(HidType));
            'Kind':
                exit(P.Filter.GetFilter(Kind));
            'IsHist':
                exit(P.Filter.GetFilter(IsHist));
        end;
    end;

    local procedure WsCase(FieldName: Text; FilterText: Text): Text
    var
        P: TestPage "WEQ Temp Worksheet";
        Result: Text;
    begin
        P.OpenView();
        P.Fill.Invoke();
        ClearLastError();
        if TrySetWs(P, FieldName, FilterText) then
            Result := 'filter=' + GetWs(P, FieldName) + ' rows=' + WalkWs(P)
        else
            Result := 'error=' + GetLastErrorCode() + ':' + GetLastErrorText();
        P.Close();
        exit(Result);
    end;

    // ---- Temp List ----

    local procedure WalkList(var P: TestPage "WEQ Temp List"): Text
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
    local procedure TrySetList(var P: TestPage "WEQ Temp List"; FieldName: Text; FilterText: Text)
    begin
        case FieldName of
            'DocType':
                P.Filter.SetFilter(DocType, FilterText);
            'HidType':
                P.Filter.SetFilter(HidType, FilterText);
            'Kind':
                P.Filter.SetFilter(Kind, FilterText);
            'IsHist':
                P.Filter.SetFilter(IsHist, FilterText);
        end;
    end;

    local procedure GetList(var P: TestPage "WEQ Temp List"; FieldName: Text): Text
    begin
        case FieldName of
            'DocType':
                exit(P.Filter.GetFilter(DocType));
            'HidType':
                exit(P.Filter.GetFilter(HidType));
            'Kind':
                exit(P.Filter.GetFilter(Kind));
            'IsHist':
                exit(P.Filter.GetFilter(IsHist));
        end;
    end;

    local procedure ListCase(FieldName: Text; FilterText: Text): Text
    var
        P: TestPage "WEQ Temp List";
        Result: Text;
    begin
        P.OpenView();
        P.Fill.Invoke();
        ClearLastError();
        if TrySetList(P, FieldName, FilterText) then
            Result := 'filter=' + GetList(P, FieldName) + ' rows=' + WalkList(P)
        else
            Result := 'error=' + GetLastErrorCode() + ':' + GetLastErrorText();
        P.Close();
        exit(Result);
    end;

    // ---- Phys Worksheet ----

    local procedure WalkPhys(var P: TestPage "WEQ Phys Worksheet"): Text
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
    local procedure TrySetPhys(var P: TestPage "WEQ Phys Worksheet"; FieldName: Text; FilterText: Text)
    begin
        case FieldName of
            'DocType':
                P.Filter.SetFilter(DocType, FilterText);
            'HidType':
                P.Filter.SetFilter(HidType, FilterText);
            'Kind':
                P.Filter.SetFilter(Kind, FilterText);
            'IsHist':
                P.Filter.SetFilter(IsHist, FilterText);
        end;
    end;

    local procedure GetPhys(var P: TestPage "WEQ Phys Worksheet"; FieldName: Text): Text
    begin
        case FieldName of
            'DocType':
                exit(P.Filter.GetFilter(DocType));
            'HidType':
                exit(P.Filter.GetFilter(HidType));
            'Kind':
                exit(P.Filter.GetFilter(Kind));
            'IsHist':
                exit(P.Filter.GetFilter(IsHist));
        end;
    end;

    local procedure PhysCase(FieldName: Text; FilterText: Text): Text
    var
        P: TestPage "WEQ Phys Worksheet";
        Result: Text;
    begin
        P.OpenView();
        ClearLastError();
        if TrySetPhys(P, FieldName, FilterText) then
            Result := 'filter=' + GetPhys(P, FieldName) + ' rows=' + WalkPhys(P)
        else
            Result := 'error=' + GetLastErrorCode() + ':' + GetLastErrorText();
        P.Close();
        exit(Result);
    end;

    local procedure SeedPhys()
    var
        Row: Record "WEQ Row";
    begin
        Row.FourRows();
    end;

    // ---- Tests: Temp Worksheet ----

    [Test]
    procedure TempWorksheet_EnumWithControl_Texts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('=Quote', WsCase('DocType', '=Quote'));
        Observer.Observe('=Order', WsCase('DocType', '=Order'));
        Observer.Observe('=Invoice', WsCase('DocType', '=Invoice'));
        Observer.Observe('<>Quote', WsCase('DocType', '<>Quote'));
        Observer.Observe('Quote', WsCase('DocType', 'Quote'));
        Observer.Observe('Order', WsCase('DocType', 'Order'));
        Observer.Observe('=0', WsCase('DocType', '=0'));
        Observer.Observe('=1', WsCase('DocType', '=1'));
        Observer.Observe('1', WsCase('DocType', '1'));
        Observer.Finish();
    end;

    [Test]
    procedure TempWorksheet_EnumWithoutControl_Texts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('=Quote', WsCase('HidType', '=Quote'));
        Observer.Observe('=Order', WsCase('HidType', '=Order'));
        Observer.Observe('<>Quote', WsCase('HidType', '<>Quote'));
        Observer.Observe('Order', WsCase('HidType', 'Order'));
        Observer.Finish();
    end;

    [Test]
    procedure TempWorksheet_Option_Texts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('=Quote', WsCase('Kind', '=Quote'));
        Observer.Observe('=Order', WsCase('Kind', '=Order'));
        Observer.Observe('=Invoice', WsCase('Kind', '=Invoice'));
        Observer.Observe('<>Quote', WsCase('Kind', '<>Quote'));
        Observer.Observe('Order', WsCase('Kind', 'Order'));
        Observer.Observe('=1', WsCase('Kind', '=1'));
        Observer.Finish();
    end;

    [Test]
    procedure TempWorksheet_BooleanWithoutControl_Texts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('=1', WsCase('IsHist', '=1'));
        Observer.Observe('=0', WsCase('IsHist', '=0'));
        Observer.Observe('1', WsCase('IsHist', '1'));
        Observer.Observe('0', WsCase('IsHist', '0'));
        Observer.Finish();
    end;

    [Test]
    procedure TempWorksheet_ReportedSequence_FirstValue()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "WEQ Temp Worksheet";
    begin
        // The reported order: the action, a Boolean '=1' on the field without a control, '=Quote' on the Enum, First(), '<>Quote', First().
        Initialize();
        P.OpenView();
        P.Fill.Invoke();
        Observer.Observe('first after action', Format(P.First()) + '|' + P.IdCtl.Value());
        P.Filter.SetFilter(IsHist, '=1');
        Observer.Observe('ishist filter', P.Filter.GetFilter(IsHist));
        P.Filter.SetFilter(DocType, '=Quote');
        Observer.Observe('doctype filter', P.Filter.GetFilter(DocType));
        Observer.Observe('first after =Quote', Format(P.First()));
        Observer.Observe('rows after =Quote', WalkWs(P));
        P.Filter.SetFilter(DocType, '<>Quote');
        Observer.Observe('doctype filter <>', P.Filter.GetFilter(DocType));
        Observer.Observe('first after <>Quote', Format(P.First()));
        Observer.Observe('rows after <>Quote', WalkWs(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TempWorksheet_ReportedSequence_OtherValue()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "WEQ Temp Worksheet";
    begin
        // The same order with '=Order' (not the first value), then '<>Order' and '<>Quote'.
        Initialize();
        P.OpenView();
        P.Fill.Invoke();
        P.Filter.SetFilter(IsHist, '=1');
        P.Filter.SetFilter(DocType, '=Order');
        Observer.Observe('doctype filter', P.Filter.GetFilter(DocType));
        Observer.Observe('first after =Order', Format(P.First()) + '|' + P.IdCtl.Value());
        Observer.Observe('rows after =Order', WalkWs(P));
        P.Filter.SetFilter(DocType, '<>Order');
        Observer.Observe('doctype filter <>Order', P.Filter.GetFilter(DocType));
        Observer.Observe('rows after <>Order', WalkWs(P));
        P.Filter.SetFilter(DocType, '<>Quote');
        Observer.Observe('doctype filter <>Quote', P.Filter.GetFilter(DocType));
        Observer.Observe('rows after <>Quote', WalkWs(P));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TempWorksheet_BareFilterThenEqFilter()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "WEQ Temp Worksheet";
    begin
        // A filter that holds ('Order') replaced by an '=' text on the same field, and a Boolean '1' kept while the Enum gets '=Invoice'.
        Initialize();
        P.OpenView();
        P.Fill.Invoke();
        P.Filter.SetFilter(DocType, 'Order');
        Observer.Observe('rows after Order', WalkWs(P));
        P.Filter.SetFilter(DocType, '=Quote');
        Observer.Observe('filter after =Quote', P.Filter.GetFilter(DocType));
        Observer.Observe('rows after =Quote', WalkWs(P));
        P.Filter.SetFilter(IsHist, '1');
        P.Filter.SetFilter(DocType, '=Invoice');
        Observer.Observe('filters', P.Filter.GetFilter(IsHist) + '|' + P.Filter.GetFilter(DocType));
        Observer.Observe('rows after 1 and =Invoice', WalkWs(P));
        P.Close();
        Observer.Finish();
    end;

    // ---- Tests: Temp List ----

    [Test]
    procedure TempList_Enum_Texts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Observer.Observe('=Quote', ListCase('DocType', '=Quote'));
        Observer.Observe('=Order', ListCase('DocType', '=Order'));
        Observer.Observe('=Invoice', ListCase('DocType', '=Invoice'));
        Observer.Observe('<>Quote', ListCase('DocType', '<>Quote'));
        Observer.Observe('Order', ListCase('DocType', 'Order'));
        Observer.Observe('hidden =Order', ListCase('HidType', '=Order'));
        Observer.Observe('hidden Order', ListCase('HidType', 'Order'));
        Observer.Finish();
    end;

    [Test]
    procedure TempList_Option_OtherValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // TempListOffPageBooleanFilter.al measured '=Quote' (the first member) on a List; these are the other members.
        Initialize();
        Observer.Observe('=Order', ListCase('Kind', '=Order'));
        Observer.Observe('=Invoice', ListCase('Kind', '=Invoice'));
        Observer.Observe('<>Quote', ListCase('Kind', '<>Quote'));
        Observer.Observe('=1', ListCase('Kind', '=1'));
        Observer.Observe('ishist =1', ListCase('IsHist', '=1'));
        Observer.Finish();
    end;

    // ---- Tests: Phys Worksheet ----

    [Test]
    procedure PhysWorksheet_Texts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        SeedPhys();
        Observer.Observe('enum =Quote', PhysCase('DocType', '=Quote'));
        Observer.Observe('enum =Order', PhysCase('DocType', '=Order'));
        Observer.Observe('enum <>Quote', PhysCase('DocType', '<>Quote'));
        Observer.Observe('enum Order', PhysCase('DocType', 'Order'));
        Observer.Observe('hidden enum =Order', PhysCase('HidType', '=Order'));
        Observer.Observe('option =Order', PhysCase('Kind', '=Order'));
        Observer.Observe('bool =1', PhysCase('IsHist', '=1'));
        Observer.Observe('bool 1', PhysCase('IsHist', '1'));
        Observer.Finish();
    end;
}
