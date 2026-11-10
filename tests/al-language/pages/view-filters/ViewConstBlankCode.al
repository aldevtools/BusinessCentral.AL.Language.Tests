// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-sourcetableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own enum 66370, table 66371, pages 66372 to 66386, test codeunit 66389; Base Application
//   table Customer (only its number, as a constant)
// local object: the SourceTableView, SubPageView and SubPageLink definitions are what the tests measure.
// Probe (al-runner issue 7371: `SourceTableView = where("Document Type" = filter(Order), "Prod. Order No." = const(''), Type = const(Item))`
//   on a ListPart, "Prod. Order No." a Code[20] field): observation form, the values are read from the corpus CI matrix.
// Area: a page view with const('') on a Code field. As the SourceTableView of a List page: const('') on Code[20], Code[10] and Text[20],
//   filter('') and filter(<> ''), two blank consts, a blank const next to a value const, next to an unqualified enum filter and an Option
//   const (the reported shape), next to an enum-qualified const, with sorting(), and a view on an Integer field with
//   const(Database::"Table") and filter(Database::A | Database::B). As the SubPageView of ListParts on a Card: the same blank const
//   shapes, with a SubPageLink beside it, a SubPageLink with const('') and an enum-qualified const, and a ListPart that has the reported
//   SourceTableView of its own (with and without a SubPageLink of the host). Each page records the row
//   numbers it shows and the filters TestPage Filter.GetFilter answers for the fields of the view.
//   Rows: 1 Order/blank/blank/Item, 2 Order/P1/X/Item, 3 Quote/blank/blank/Item, 4 Order/blank/X/Resource, 5 Order/P2/blank/Item,
//   6 Order/blank/blank/Item; "Table Id" is the table's own number on rows 1, 3 and 4, 0 on rows 2 and 6, and Customer on row 5.
// Existing pins: testpage/CdObjects.al page "LT CD ConstOthers List" (const('') on a Text field), testpage/CdConst0D.al (filter('') on a
//   Date field), pages/subpagelink-empty-term/SubPageLinkEmptyTerm.al (SubPageLink const('') and filter('')),
//   record/qualified-enum-filters/TestQualifiedEnumFilters.al (an enum-qualified const in SourceTableView and SubPageView),
//   testpage/TsplCard.Page.al (SubPageLink with const(Database::X)).
// BC versions: 27, 28, 29 by CI

enum 66370 "PG VwBlank Type"
{
    Extensible = false;
    value(0; Quote) { }
    value(1; Order) { }
}

table 66371 "PG VwBlank Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Doc Type"; Enum "PG VwBlank Type") { }
        field(3; C20; Code[20]) { }
        field(4; C10; Code[10]) { }
        field(5; T; Text[20]) { }
        field(6; Kind; Option) { OptionMembers = " ",Item,Resource; }
        field(7; "Table Id"; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByC20; C20, Id) { }
    }
}

page 66372 "PG VwBlank C20Const"
{
    PageType = List;
    SourceTable = "PG VwBlank Row";
    SourceTableView = where(C20 = const(''));
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
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66373 "PG VwBlank Reported"
{
    PageType = List;
    SourceTable = "PG VwBlank Row";
    SourceTableView = where("Doc Type" = filter(Order), C20 = const(''), Kind = const(Item));
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
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66374 "PG VwBlank C10Const"
{
    PageType = List;
    SourceTable = "PG VwBlank Row";
    SourceTableView = where(C10 = const(''));
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
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66375 "PG VwBlank C20Filter"
{
    PageType = List;
    SourceTable = "PG VwBlank Row";
    SourceTableView = where(C20 = filter(''));
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
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66376 "PG VwBlank C20NotBlank"
{
    PageType = List;
    SourceTable = "PG VwBlank Row";
    SourceTableView = where(C20 = filter(<> ''));
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
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66377 "PG VwBlank TwoConst"
{
    PageType = List;
    SourceTable = "PG VwBlank Row";
    SourceTableView = where(C20 = const(''), C10 = const(''));
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
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66378 "PG VwBlank TextConst"
{
    PageType = List;
    SourceTable = "PG VwBlank Row";
    SourceTableView = where(T = const(''));
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
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66379 "PG VwBlank BlankAndValue"
{
    PageType = List;
    SourceTable = "PG VwBlank Row";
    SourceTableView = where(C20 = const(''), C10 = const('X'));
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
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66380 "PG VwBlank TableConst"
{
    PageType = List;
    SourceTable = "PG VwBlank Row";
    SourceTableView = where("Table Id" = const(Database::"PG VwBlank Row"));
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
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66381 "PG VwBlank TableList"
{
    PageType = List;
    SourceTable = "PG VwBlank Row";
    SourceTableView = where("Table Id" = filter(Database::"PG VwBlank Row" | Database::Customer));
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
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66382 "PG VwBlank EnumAndBlank"
{
    PageType = List;
    SourceTable = "PG VwBlank Row";
    SourceTableView = where("Doc Type" = const("PG VwBlank Type"::Order), C20 = const(''));
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
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66383 "PG VwBlank SortedBlank"
{
    PageType = List;
    SourceTable = "PG VwBlank Row";
    SourceTableView = sorting(C20, Id) where(C20 = const(''));
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
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66384 "PG VwBlank Part"
{
    PageType = ListPart;
    SourceTable = "PG VwBlank Row";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66386 "PG VwBlank ViewPart"
{
    PageType = ListPart;
    SourceTable = "PG VwBlank Row";
    SourceTableView = where("Doc Type" = filter(Order), C20 = const(''), Kind = const(Item));
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(C20Ctl; Rec.C20) { ApplicationArea = All; }
            }
        }
    }
}

page 66385 "PG VwBlank Host"
{
    PageType = Card;
    SourceTable = "PG VwBlank Row";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(C10Ctl; Rec.C10) { ApplicationArea = All; }
            }
            part(PartC20; "PG VwBlank Part") { ApplicationArea = All; SubPageView = where(C20 = const('')); }
            part(PartReported; "PG VwBlank Part") { ApplicationArea = All; SubPageView = where("Doc Type" = filter(Order), C20 = const(''), Kind = const(Item)); }
            part(PartC10; "PG VwBlank Part") { ApplicationArea = All; SubPageView = where(C10 = const('')); }
            part(PartTable; "PG VwBlank Part") { ApplicationArea = All; SubPageView = where("Table Id" = const(Database::"PG VwBlank Row")); }
            part(PartLinked; "PG VwBlank Part") { ApplicationArea = All; SubPageLink = C10 = field(C10); SubPageView = where(C20 = const('')); }
            part(PartLinkConst; "PG VwBlank Part") { ApplicationArea = All; SubPageLink = C20 = const(''), "Doc Type" = const("PG VwBlank Type"::Order); }
            part(PartOwnView; "PG VwBlank ViewPart") { ApplicationArea = All; }
            part(PartOwnViewLinked; "PG VwBlank ViewPart") { ApplicationArea = All; SubPageLink = C10 = field(C10); }
            part(PartEnum; "PG VwBlank Part") { ApplicationArea = All; SubPageView = where("Doc Type" = const("PG VwBlank Type"::Order), C20 = const('')); }
        }
    }
}

codeunit 66389 "PG VwBlank Tests"
{
    Subtype = Test;

    local procedure Initialize()
    var
        R: Record "PG VwBlank Row";
    begin
        R.DeleteAll();
        Add(1, R."Doc Type"::Order, '', '', '', R.Kind::Item, Database::"PG VwBlank Row");
        Add(2, R."Doc Type"::Order, 'P1', 'X', 't', R.Kind::Item, 0);
        Add(3, R."Doc Type"::Quote, '', '', '', R.Kind::Item, Database::"PG VwBlank Row");
        Add(4, R."Doc Type"::Order, '', 'X', '', R.Kind::Resource, Database::"PG VwBlank Row");
        Add(5, R."Doc Type"::Order, 'P2', '', 't', R.Kind::Item, Database::Customer);
        Add(6, R."Doc Type"::Order, '', '', '', R.Kind::Item, 0);
    end;

    local procedure Add(Id: Integer; DocType: Enum "PG VwBlank Type"; C20: Code[20]; C10: Code[10]; T: Text[20]; Kind: Option; TableId: Integer)
    var
        R: Record "PG VwBlank Row";
    begin
        R.Init();
        R.Id := Id;
        R."Doc Type" := DocType;
        R.C20 := C20;
        R.C10 := C10;
        R.T := T;
        R.Kind := Kind;
        R."Table Id" := TableId;
        R.Insert();
    end;

    local procedure TableNumbers(Value: Text): Text
    begin
        exit(Value.Replace(Format(Database::"PG VwBlank Row"), '<own table>'));
    end;

    [TryFunction]
    local procedure TryReadC20Const(var Rows: Text; var Filters: Text)
    var
        Pg: TestPage "PG VwBlank C20Const";
    begin
        Pg.OpenView();
        Filters := 'Doc Type=[' + Pg.Filter.GetFilter("Doc Type") + '] C20=[' + Pg.Filter.GetFilter(C20) + '] C10=[' + Pg.Filter.GetFilter(C10) + '] T=[' + Pg.Filter.GetFilter(T) + '] Kind=[' + Pg.Filter.GetFilter(Kind) + '] Table Id=[' + TableNumbers(Pg.Filter.GetFilter("Table Id")) + ']';
        if Pg.First() then
            repeat
                Rows += Pg.IdCtl.Value() + ' ';
            until not Pg.Next();
        Pg.Close();
    end;

    [Test]
    procedure SourceTableView_C20Const_RowsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
        Filters: Text;
    begin
        // SourceTableView const blank on Code[20]: where(C20 = const(''))
        Initialize();
        if TryReadC20Const(Rows, Filters) then begin
            Observer.Observe('rows', Rows);
            Observer.Observe('filters', Filters);
        end else begin
            Observer.Observe('rows before the error', Rows);
            Observer.ObserveError('open or read');
        end;
        Observer.Expect('rows', '1 2 3 4 5 6 ');
        Observer.Expect('filters', 'Doc Type=[] C20=[] C10=[] T=[] Kind=[] Table Id=[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadReported(var Rows: Text; var Filters: Text)
    var
        Pg: TestPage "PG VwBlank Reported";
    begin
        Pg.OpenView();
        Filters := 'Doc Type=[' + Pg.Filter.GetFilter("Doc Type") + '] C20=[' + Pg.Filter.GetFilter(C20) + '] C10=[' + Pg.Filter.GetFilter(C10) + '] T=[' + Pg.Filter.GetFilter(T) + '] Kind=[' + Pg.Filter.GetFilter(Kind) + '] Table Id=[' + TableNumbers(Pg.Filter.GetFilter("Table Id")) + ']';
        if Pg.First() then
            repeat
                Rows += Pg.IdCtl.Value() + ' ';
            until not Pg.Next();
        Pg.Close();
    end;

    [Test]
    procedure SourceTableView_Reported_RowsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
        Filters: Text;
    begin
        // the reported shape: where("Doc Type" = filter(Order), C20 = const(''), Kind = const(Item))
        Initialize();
        if TryReadReported(Rows, Filters) then begin
            Observer.Observe('rows', Rows);
            Observer.Observe('filters', Filters);
        end else begin
            Observer.Observe('rows before the error', Rows);
            Observer.ObserveError('open or read');
        end;
        Observer.Expect('rows', '1 2 5 6 ');
        Observer.Expect('filters', 'Doc Type=[1] C20=[] C10=[] T=[] Kind=[1] Table Id=[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadC10Const(var Rows: Text; var Filters: Text)
    var
        Pg: TestPage "PG VwBlank C10Const";
    begin
        Pg.OpenView();
        Filters := 'Doc Type=[' + Pg.Filter.GetFilter("Doc Type") + '] C20=[' + Pg.Filter.GetFilter(C20) + '] C10=[' + Pg.Filter.GetFilter(C10) + '] T=[' + Pg.Filter.GetFilter(T) + '] Kind=[' + Pg.Filter.GetFilter(Kind) + '] Table Id=[' + TableNumbers(Pg.Filter.GetFilter("Table Id")) + ']';
        if Pg.First() then
            repeat
                Rows += Pg.IdCtl.Value() + ' ';
            until not Pg.Next();
        Pg.Close();
    end;

    [Test]
    procedure SourceTableView_C10Const_RowsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
        Filters: Text;
    begin
        // Code[10]: where(C10 = const(''))
        Initialize();
        if TryReadC10Const(Rows, Filters) then begin
            Observer.Observe('rows', Rows);
            Observer.Observe('filters', Filters);
        end else begin
            Observer.Observe('rows before the error', Rows);
            Observer.ObserveError('open or read');
        end;
        Observer.Expect('rows', '1 2 3 4 5 6 ');
        Observer.Expect('filters', 'Doc Type=[] C20=[] C10=[] T=[] Kind=[] Table Id=[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadC20Filter(var Rows: Text; var Filters: Text)
    var
        Pg: TestPage "PG VwBlank C20Filter";
    begin
        Pg.OpenView();
        Filters := 'Doc Type=[' + Pg.Filter.GetFilter("Doc Type") + '] C20=[' + Pg.Filter.GetFilter(C20) + '] C10=[' + Pg.Filter.GetFilter(C10) + '] T=[' + Pg.Filter.GetFilter(T) + '] Kind=[' + Pg.Filter.GetFilter(Kind) + '] Table Id=[' + TableNumbers(Pg.Filter.GetFilter("Table Id")) + ']';
        if Pg.First() then
            repeat
                Rows += Pg.IdCtl.Value() + ' ';
            until not Pg.Next();
        Pg.Close();
    end;

    [Test]
    procedure SourceTableView_C20Filter_RowsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
        Filters: Text;
    begin
        // filter blank: where(C20 = filter(''))
        Initialize();
        if TryReadC20Filter(Rows, Filters) then begin
            Observer.Observe('rows', Rows);
            Observer.Observe('filters', Filters);
        end else begin
            Observer.Observe('rows before the error', Rows);
            Observer.ObserveError('open or read');
        end;
        Observer.Expect('rows', '1 3 4 6 ');
        Observer.Expect('filters', 'Doc Type=[] C20=[''''] C10=[] T=[] Kind=[] Table Id=[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadC20NotBlank(var Rows: Text; var Filters: Text)
    var
        Pg: TestPage "PG VwBlank C20NotBlank";
    begin
        Pg.OpenView();
        Filters := 'Doc Type=[' + Pg.Filter.GetFilter("Doc Type") + '] C20=[' + Pg.Filter.GetFilter(C20) + '] C10=[' + Pg.Filter.GetFilter(C10) + '] T=[' + Pg.Filter.GetFilter(T) + '] Kind=[' + Pg.Filter.GetFilter(Kind) + '] Table Id=[' + TableNumbers(Pg.Filter.GetFilter("Table Id")) + ']';
        if Pg.First() then
            repeat
                Rows += Pg.IdCtl.Value() + ' ';
            until not Pg.Next();
        Pg.Close();
    end;

    [Test]
    procedure SourceTableView_C20NotBlank_RowsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
        Filters: Text;
    begin
        // filter not blank: where(C20 = filter(<> ''))
        Initialize();
        if TryReadC20NotBlank(Rows, Filters) then begin
            Observer.Observe('rows', Rows);
            Observer.Observe('filters', Filters);
        end else begin
            Observer.Observe('rows before the error', Rows);
            Observer.ObserveError('open or read');
        end;
        Observer.Expect('rows', '2 5 ');
        Observer.Expect('filters', 'Doc Type=[] C20=[<>''''] C10=[] T=[] Kind=[] Table Id=[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadTwoConst(var Rows: Text; var Filters: Text)
    var
        Pg: TestPage "PG VwBlank TwoConst";
    begin
        Pg.OpenView();
        Filters := 'Doc Type=[' + Pg.Filter.GetFilter("Doc Type") + '] C20=[' + Pg.Filter.GetFilter(C20) + '] C10=[' + Pg.Filter.GetFilter(C10) + '] T=[' + Pg.Filter.GetFilter(T) + '] Kind=[' + Pg.Filter.GetFilter(Kind) + '] Table Id=[' + TableNumbers(Pg.Filter.GetFilter("Table Id")) + ']';
        if Pg.First() then
            repeat
                Rows += Pg.IdCtl.Value() + ' ';
            until not Pg.Next();
        Pg.Close();
    end;

    [Test]
    procedure SourceTableView_TwoConst_RowsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
        Filters: Text;
    begin
        // two blank consts: where(C20 = const(''), C10 = const(''))
        Initialize();
        if TryReadTwoConst(Rows, Filters) then begin
            Observer.Observe('rows', Rows);
            Observer.Observe('filters', Filters);
        end else begin
            Observer.Observe('rows before the error', Rows);
            Observer.ObserveError('open or read');
        end;
        Observer.Expect('rows', '1 2 3 4 5 6 ');
        Observer.Expect('filters', 'Doc Type=[] C20=[] C10=[] T=[] Kind=[] Table Id=[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadTextConst(var Rows: Text; var Filters: Text)
    var
        Pg: TestPage "PG VwBlank TextConst";
    begin
        Pg.OpenView();
        Filters := 'Doc Type=[' + Pg.Filter.GetFilter("Doc Type") + '] C20=[' + Pg.Filter.GetFilter(C20) + '] C10=[' + Pg.Filter.GetFilter(C10) + '] T=[' + Pg.Filter.GetFilter(T) + '] Kind=[' + Pg.Filter.GetFilter(Kind) + '] Table Id=[' + TableNumbers(Pg.Filter.GetFilter("Table Id")) + ']';
        if Pg.First() then
            repeat
                Rows += Pg.IdCtl.Value() + ' ';
            until not Pg.Next();
        Pg.Close();
    end;

    [Test]
    procedure SourceTableView_TextConst_RowsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
        Filters: Text;
    begin
        // Text[20]: where(T = const(''))
        Initialize();
        if TryReadTextConst(Rows, Filters) then begin
            Observer.Observe('rows', Rows);
            Observer.Observe('filters', Filters);
        end else begin
            Observer.Observe('rows before the error', Rows);
            Observer.ObserveError('open or read');
        end;
        Observer.Expect('rows', '1 2 3 4 5 6 ');
        Observer.Expect('filters', 'Doc Type=[] C20=[] C10=[] T=[] Kind=[] Table Id=[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadBlankAndValue(var Rows: Text; var Filters: Text)
    var
        Pg: TestPage "PG VwBlank BlankAndValue";
    begin
        Pg.OpenView();
        Filters := 'Doc Type=[' + Pg.Filter.GetFilter("Doc Type") + '] C20=[' + Pg.Filter.GetFilter(C20) + '] C10=[' + Pg.Filter.GetFilter(C10) + '] T=[' + Pg.Filter.GetFilter(T) + '] Kind=[' + Pg.Filter.GetFilter(Kind) + '] Table Id=[' + TableNumbers(Pg.Filter.GetFilter("Table Id")) + ']';
        if Pg.First() then
            repeat
                Rows += Pg.IdCtl.Value() + ' ';
            until not Pg.Next();
        Pg.Close();
    end;

    [Test]
    procedure SourceTableView_BlankAndValue_RowsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
        Filters: Text;
    begin
        // blank and value: where(C20 = const(''), C10 = const('X'))
        Initialize();
        if TryReadBlankAndValue(Rows, Filters) then begin
            Observer.Observe('rows', Rows);
            Observer.Observe('filters', Filters);
        end else begin
            Observer.Observe('rows before the error', Rows);
            Observer.ObserveError('open or read');
        end;
        Observer.Expect('rows', '2 4 ');
        Observer.Expect('filters', 'Doc Type=[] C20=[] C10=[X] T=[] Kind=[] Table Id=[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadTableConst(var Rows: Text; var Filters: Text)
    var
        Pg: TestPage "PG VwBlank TableConst";
    begin
        Pg.OpenView();
        Filters := 'Doc Type=[' + Pg.Filter.GetFilter("Doc Type") + '] C20=[' + Pg.Filter.GetFilter(C20) + '] C10=[' + Pg.Filter.GetFilter(C10) + '] T=[' + Pg.Filter.GetFilter(T) + '] Kind=[' + Pg.Filter.GetFilter(Kind) + '] Table Id=[' + TableNumbers(Pg.Filter.GetFilter("Table Id")) + ']';
        if Pg.First() then
            repeat
                Rows += Pg.IdCtl.Value() + ' ';
            until not Pg.Next();
        Pg.Close();
    end;

    [Test]
    procedure SourceTableView_TableConst_RowsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
        Filters: Text;
    begin
        // table constant: where("Table Id" = const(Database::"PG VwBlank Row"))
        Initialize();
        if TryReadTableConst(Rows, Filters) then begin
            Observer.Observe('rows', Rows);
            Observer.Observe('filters', Filters);
        end else begin
            Observer.Observe('rows before the error', Rows);
            Observer.ObserveError('open or read');
        end;
        Observer.Expect('rows', '1 3 4 ');
        Observer.Expect('filters', 'Doc Type=[] C20=[] C10=[] T=[] Kind=[] Table Id=[<own table>]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadTableList(var Rows: Text; var Filters: Text)
    var
        Pg: TestPage "PG VwBlank TableList";
    begin
        Pg.OpenView();
        Filters := 'Doc Type=[' + Pg.Filter.GetFilter("Doc Type") + '] C20=[' + Pg.Filter.GetFilter(C20) + '] C10=[' + Pg.Filter.GetFilter(C10) + '] T=[' + Pg.Filter.GetFilter(T) + '] Kind=[' + Pg.Filter.GetFilter(Kind) + '] Table Id=[' + TableNumbers(Pg.Filter.GetFilter("Table Id")) + ']';
        if Pg.First() then
            repeat
                Rows += Pg.IdCtl.Value() + ' ';
            until not Pg.Next();
        Pg.Close();
    end;

    [Test]
    procedure SourceTableView_TableList_RowsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
        Filters: Text;
    begin
        // table list: where("Table Id" = filter(Database::"PG VwBlank Row" | Database::Customer))
        Initialize();
        if TryReadTableList(Rows, Filters) then begin
            Observer.Observe('rows', Rows);
            Observer.Observe('filters', Filters);
        end else begin
            Observer.Observe('rows before the error', Rows);
            Observer.ObserveError('open or read');
        end;
        Observer.Expect('rows', '1 3 4 5 ');
        Observer.Expect('filters', 'Doc Type=[] C20=[] C10=[] T=[] Kind=[] Table Id=[<own table>|18]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadEnumAndBlank(var Rows: Text; var Filters: Text)
    var
        Pg: TestPage "PG VwBlank EnumAndBlank";
    begin
        Pg.OpenView();
        Filters := 'Doc Type=[' + Pg.Filter.GetFilter("Doc Type") + '] C20=[' + Pg.Filter.GetFilter(C20) + '] C10=[' + Pg.Filter.GetFilter(C10) + '] T=[' + Pg.Filter.GetFilter(T) + '] Kind=[' + Pg.Filter.GetFilter(Kind) + '] Table Id=[' + TableNumbers(Pg.Filter.GetFilter("Table Id")) + ']';
        if Pg.First() then
            repeat
                Rows += Pg.IdCtl.Value() + ' ';
            until not Pg.Next();
        Pg.Close();
    end;

    [Test]
    procedure SourceTableView_EnumAndBlank_RowsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
        Filters: Text;
    begin
        // qualified enum and blank: where("Doc Type" = const("PG VwBlank Type"::Order), C20 = const(''))
        Initialize();
        if TryReadEnumAndBlank(Rows, Filters) then begin
            Observer.Observe('rows', Rows);
            Observer.Observe('filters', Filters);
        end else begin
            Observer.Observe('rows before the error', Rows);
            Observer.ObserveError('open or read');
        end;
        Observer.Expect('rows', '1 2 4 5 6 ');
        Observer.Expect('filters', 'Doc Type=[1] C20=[] C10=[] T=[] Kind=[] Table Id=[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadSortedBlank(var Rows: Text; var Filters: Text)
    var
        Pg: TestPage "PG VwBlank SortedBlank";
    begin
        Pg.OpenView();
        Filters := 'Doc Type=[' + Pg.Filter.GetFilter("Doc Type") + '] C20=[' + Pg.Filter.GetFilter(C20) + '] C10=[' + Pg.Filter.GetFilter(C10) + '] T=[' + Pg.Filter.GetFilter(T) + '] Kind=[' + Pg.Filter.GetFilter(Kind) + '] Table Id=[' + TableNumbers(Pg.Filter.GetFilter("Table Id")) + ']';
        if Pg.First() then
            repeat
                Rows += Pg.IdCtl.Value() + ' ';
            until not Pg.Next();
        Pg.Close();
    end;

    [Test]
    procedure SourceTableView_SortedBlank_RowsAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
        Filters: Text;
    begin
        // sorting and blank: sorting(C20, Id) where(C20 = const(''))
        Initialize();
        if TryReadSortedBlank(Rows, Filters) then begin
            Observer.Observe('rows', Rows);
            Observer.Observe('filters', Filters);
        end else begin
            Observer.Observe('rows before the error', Rows);
            Observer.ObserveError('open or read');
        end;
        Observer.Expect('rows', '1 3 4 6 2 5 ');
        Observer.Expect('filters', 'Doc Type=[] C20=[] C10=[] T=[] Kind=[] Table Id=[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadPartC20(HostId: Integer; var Rows: Text)
    var
        Host: TestPage "PG VwBlank Host";
    begin
        Host.OpenView();
        Host.Filter.SetFilter(Id, Format(HostId));
        Host.First();
        if Host.PartC20.First() then
            repeat
                Rows += Host.PartC20.IdCtl.Value() + ' ';
            until not Host.PartC20.Next();
        Host.Close();
    end;

    [Test]
    procedure SubPage_PartC20_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        // SubPageView = where(C20 = const(''));
        Initialize();
        if TryReadPartC20(1, Rows) then
            Observer.Observe('host row 1 (C10 blank)', Rows)
        else begin
            Observer.Observe('host row 1 rows before the error', Rows);
            Observer.ObserveError('host row 1');
        end;
        Rows := '';
        if TryReadPartC20(2, Rows) then
            Observer.Observe('host row 2 (C10 X)', Rows)
        else begin
            Observer.Observe('host row 2 rows before the error', Rows);
            Observer.ObserveError('host row 2');
        end;
        Observer.Expect('host row 1 (C10 blank)', '1 3 4 6 ');
        Observer.Expect('host row 2 (C10 X)', '1 3 4 6 ');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadPartReported(HostId: Integer; var Rows: Text)
    var
        Host: TestPage "PG VwBlank Host";
    begin
        Host.OpenView();
        Host.Filter.SetFilter(Id, Format(HostId));
        Host.First();
        if Host.PartReported.First() then
            repeat
                Rows += Host.PartReported.IdCtl.Value() + ' ';
            until not Host.PartReported.Next();
        Host.Close();
    end;

    [Test]
    procedure SubPage_PartReported_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        // SubPageView = where("Doc Type" = filter(Order), C20 = const(''), Kind = const(Item));
        Initialize();
        if TryReadPartReported(1, Rows) then
            Observer.Observe('host row 1 (C10 blank)', Rows)
        else begin
            Observer.Observe('host row 1 rows before the error', Rows);
            Observer.ObserveError('host row 1');
        end;
        Rows := '';
        if TryReadPartReported(2, Rows) then
            Observer.Observe('host row 2 (C10 X)', Rows)
        else begin
            Observer.Observe('host row 2 rows before the error', Rows);
            Observer.ObserveError('host row 2');
        end;
        Observer.Expect('host row 1 (C10 blank)', '1 6 ');
        Observer.Expect('host row 2 (C10 X)', '1 6 ');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadPartC10(HostId: Integer; var Rows: Text)
    var
        Host: TestPage "PG VwBlank Host";
    begin
        Host.OpenView();
        Host.Filter.SetFilter(Id, Format(HostId));
        Host.First();
        if Host.PartC10.First() then
            repeat
                Rows += Host.PartC10.IdCtl.Value() + ' ';
            until not Host.PartC10.Next();
        Host.Close();
    end;

    [Test]
    procedure SubPage_PartC10_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        // SubPageView = where(C10 = const(''));
        Initialize();
        if TryReadPartC10(1, Rows) then
            Observer.Observe('host row 1 (C10 blank)', Rows)
        else begin
            Observer.Observe('host row 1 rows before the error', Rows);
            Observer.ObserveError('host row 1');
        end;
        Rows := '';
        if TryReadPartC10(2, Rows) then
            Observer.Observe('host row 2 (C10 X)', Rows)
        else begin
            Observer.Observe('host row 2 rows before the error', Rows);
            Observer.ObserveError('host row 2');
        end;
        Observer.Expect('host row 1 (C10 blank)', '1 3 5 6 ');
        Observer.Expect('host row 2 (C10 X)', '1 3 5 6 ');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadPartTable(HostId: Integer; var Rows: Text)
    var
        Host: TestPage "PG VwBlank Host";
    begin
        Host.OpenView();
        Host.Filter.SetFilter(Id, Format(HostId));
        Host.First();
        if Host.PartTable.First() then
            repeat
                Rows += Host.PartTable.IdCtl.Value() + ' ';
            until not Host.PartTable.Next();
        Host.Close();
    end;

    [Test]
    procedure SubPage_PartTable_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        // SubPageView = where("Table Id" = const(Database::"PG VwBlank Row"));
        Initialize();
        if TryReadPartTable(1, Rows) then
            Observer.Observe('host row 1 (C10 blank)', Rows)
        else begin
            Observer.Observe('host row 1 rows before the error', Rows);
            Observer.ObserveError('host row 1');
        end;
        Rows := '';
        if TryReadPartTable(2, Rows) then
            Observer.Observe('host row 2 (C10 X)', Rows)
        else begin
            Observer.Observe('host row 2 rows before the error', Rows);
            Observer.ObserveError('host row 2');
        end;
        Observer.Expect('host row 1 (C10 blank)', '1 3 4 ');
        Observer.Expect('host row 2 (C10 X)', '1 3 4 ');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadPartLinked(HostId: Integer; var Rows: Text)
    var
        Host: TestPage "PG VwBlank Host";
    begin
        Host.OpenView();
        Host.Filter.SetFilter(Id, Format(HostId));
        Host.First();
        if Host.PartLinked.First() then
            repeat
                Rows += Host.PartLinked.IdCtl.Value() + ' ';
            until not Host.PartLinked.Next();
        Host.Close();
    end;

    [Test]
    procedure SubPage_PartLinked_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        // SubPageLink = C10 = field(C10); SubPageView = where(C20 = const(''));
        Initialize();
        if TryReadPartLinked(1, Rows) then
            Observer.Observe('host row 1 (C10 blank)', Rows)
        else begin
            Observer.Observe('host row 1 rows before the error', Rows);
            Observer.ObserveError('host row 1');
        end;
        Rows := '';
        if TryReadPartLinked(2, Rows) then
            Observer.Observe('host row 2 (C10 X)', Rows)
        else begin
            Observer.Observe('host row 2 rows before the error', Rows);
            Observer.ObserveError('host row 2');
        end;
        Observer.Expect('host row 1 (C10 blank)', '1 3 6 ');
        Observer.Expect('host row 2 (C10 X)', '4 ');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadPartLinkConst(HostId: Integer; var Rows: Text)
    var
        Host: TestPage "PG VwBlank Host";
    begin
        Host.OpenView();
        Host.Filter.SetFilter(Id, Format(HostId));
        Host.First();
        if Host.PartLinkConst.First() then
            repeat
                Rows += Host.PartLinkConst.IdCtl.Value() + ' ';
            until not Host.PartLinkConst.Next();
        Host.Close();
    end;

    [Test]
    procedure SubPage_PartLinkConst_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        // SubPageLink = C20 = const(''), "Doc Type" = const("PG VwBlank Type"::Order);
        Initialize();
        if TryReadPartLinkConst(1, Rows) then
            Observer.Observe('host row 1 (C10 blank)', Rows)
        else begin
            Observer.Observe('host row 1 rows before the error', Rows);
            Observer.ObserveError('host row 1');
        end;
        Rows := '';
        if TryReadPartLinkConst(2, Rows) then
            Observer.Observe('host row 2 (C10 X)', Rows)
        else begin
            Observer.Observe('host row 2 rows before the error', Rows);
            Observer.ObserveError('host row 2');
        end;
        Observer.Expect('host row 1 (C10 blank)', '1 4 6 ');
        Observer.Expect('host row 2 (C10 X)', '1 4 6 ');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadPartEnum(HostId: Integer; var Rows: Text)
    var
        Host: TestPage "PG VwBlank Host";
    begin
        Host.OpenView();
        Host.Filter.SetFilter(Id, Format(HostId));
        Host.First();
        if Host.PartEnum.First() then
            repeat
                Rows += Host.PartEnum.IdCtl.Value() + ' ';
            until not Host.PartEnum.Next();
        Host.Close();
    end;

    [Test]
    procedure SubPage_PartEnum_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        // SubPageView = where("Doc Type" = const("PG VwBlank Type"::Order), C20 = const(''));
        Initialize();
        if TryReadPartEnum(1, Rows) then
            Observer.Observe('host row 1 (C10 blank)', Rows)
        else begin
            Observer.Observe('host row 1 rows before the error', Rows);
            Observer.ObserveError('host row 1');
        end;
        Rows := '';
        if TryReadPartEnum(2, Rows) then
            Observer.Observe('host row 2 (C10 X)', Rows)
        else begin
            Observer.Observe('host row 2 rows before the error', Rows);
            Observer.ObserveError('host row 2');
        end;
        Observer.Expect('host row 1 (C10 blank)', '1 4 6 ');
        Observer.Expect('host row 2 (C10 X)', '1 4 6 ');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadPartOwnView(HostId: Integer; var Rows: Text)
    var
        Host: TestPage "PG VwBlank Host";
    begin
        Host.OpenView();
        Host.Filter.SetFilter(Id, Format(HostId));
        Host.First();
        if Host.PartOwnView.First() then
            repeat
                Rows += Host.PartOwnView.IdCtl.Value() + ' ';
            until not Host.PartOwnView.Next();
        Host.Close();
    end;

    [Test]
    procedure SubPage_PartOwnView_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        // the part page has the reported SourceTableView of its own
        Initialize();
        if TryReadPartOwnView(1, Rows) then
            Observer.Observe('host row 1 (C10 blank)', Rows)
        else begin
            Observer.Observe('host row 1 rows before the error', Rows);
            Observer.ObserveError('host row 1');
        end;
        Rows := '';
        if TryReadPartOwnView(2, Rows) then
            Observer.Observe('host row 2 (C10 X)', Rows)
        else begin
            Observer.Observe('host row 2 rows before the error', Rows);
            Observer.ObserveError('host row 2');
        end;
        Observer.Expect('host row 1 (C10 blank)', '1 2 5 6 ');
        Observer.Expect('host row 2 (C10 X)', '1 2 5 6 ');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadPartOwnViewLinked(HostId: Integer; var Rows: Text)
    var
        Host: TestPage "PG VwBlank Host";
    begin
        Host.OpenView();
        Host.Filter.SetFilter(Id, Format(HostId));
        Host.First();
        if Host.PartOwnViewLinked.First() then
            repeat
                Rows += Host.PartOwnViewLinked.IdCtl.Value() + ' ';
            until not Host.PartOwnViewLinked.Next();
        Host.Close();
    end;

    [Test]
    procedure SubPage_PartOwnViewLinked_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        // the part page has the reported SourceTableView and the host adds SubPageLink = C10 = field(C10)
        Initialize();
        if TryReadPartOwnViewLinked(1, Rows) then
            Observer.Observe('host row 1 (C10 blank)', Rows)
        else begin
            Observer.Observe('host row 1 rows before the error', Rows);
            Observer.ObserveError('host row 1');
        end;
        Rows := '';
        if TryReadPartOwnViewLinked(2, Rows) then
            Observer.Observe('host row 2 (C10 X)', Rows)
        else begin
            Observer.Observe('host row 2 rows before the error', Rows);
            Observer.ObserveError('host row 2');
        end;
        Observer.Expect('host row 1 (C10 blank)', '1 5 6 ');
        Observer.Expect('host row 2 (C10 X)', '2 ');
        Observer.Verify();
    end;
}
