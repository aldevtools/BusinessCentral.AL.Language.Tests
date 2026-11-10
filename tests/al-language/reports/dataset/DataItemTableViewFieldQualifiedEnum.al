// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemtableview-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// local object: the filter text in the properties of these objects is under test (enums 62310 and 62311, table 62312,
//   report 62314, page 62315, query 62316, log 62317).
// Area: an enum or option value in a table view filter that is qualified with the FIELD name (`Type::Item`, the shape of Sales Line
//   in al-runner issue 7423), not with the enum type name. The field Type has the enum "RPT TvQ Kind", so `Type::Item` can only be
//   the field-qualified form.
//   Forms: filter(Type::Item), const(Type::Item), filter(<>Type::Item), a list, a range, two fields in one view, an Option field,
//   and as controls the plain member name and the enum-type-qualified form.
//   Places: report DataItemTableView, page SourceTableView, CalcFormula of a FlowField, query DataItemTableFilter.
//   Observed: the view text (GetView) and the rows each place reads.
// Already pinned elsewhere: the enum-type-qualified form in CalcFormula and SourceTableView (record/qualified-enum-filters/
//   TestQualifiedEnumFilters.al, record/enum-lists-ranges/EnumFilterListsRanges.al).
// BC versions: 27-29
enum 62310 "RPT TvQ Kind"
{
    Extensible = false;

    value(0; " ") { }
    value(1; Item) { }
    value(2; Resource) { }
    value(5; Charge) { }
}

enum 62311 "RPT TvQ Doc"
{
    Extensible = false;

    value(0; Quote) { }
    value(1; "Order") { }
    value(2; Invoice) { }
}

table 62312 "RPT TvQ Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; Type; Enum "RPT TvQ Kind") { }
        field(3; "Document Type"; Enum "RPT TvQ Doc") { }
        field(4; "Opt Kind"; Option) { OptionMembers = None,Small,Large; }
        // The FlowFields are in the table they count: a field-qualified value is resolved in the object that holds the property, so
        // a CalcFormula in another table cannot name `Type::Item` (AL0118 with the AL 17 compiler).
        field(10; "Item Lines"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("RPT TvQ Line" where(Type = filter(Type::Item)));
        }
        field(11; "Not Item Lines"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("RPT TvQ Line" where(Type = filter(<> Type::Item)));
        }
        field(12; "Item Or Res Lines"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("RPT TvQ Line" where(Type = filter(Type::Item | Type::Resource)));
        }
        field(13; "Const Item Lines"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("RPT TvQ Line" where(Type = const(Type::Item)));
        }
        field(14; "Quote Order Item Lines"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("RPT TvQ Line" where(Type = filter(Type::Item), "Document Type" = filter("Document Type"::Quote | "Document Type"::"Order")));
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

codeunit 62317 "RPT TvQ Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 62314 "RPT TvQ Views"
{
    ProcessingOnly = true;
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(FilterField; "RPT TvQ Line")
        {
            DataItemTableView = where(Type = filter(Type::Item));

            trigger OnPreDataItem()
            begin
                L.Add('FilterField view=' + FilterField.GetView());
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('FilterField row ' + Format(FilterField."Line No."));
            end;
        }
        dataitem(ConstField; "RPT TvQ Line")
        {
            DataItemTableView = where(Type = const(Type::Item));

            trigger OnPreDataItem()
            begin
                L.Add('ConstField view=' + ConstField.GetView());
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('ConstField row ' + Format(ConstField."Line No."));
            end;
        }
        dataitem(NotEqual; "RPT TvQ Line")
        {
            DataItemTableView = where(Type = filter(<> Type::Item));

            trigger OnPreDataItem()
            begin
                L.Add('NotEqual view=' + NotEqual.GetView());
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('NotEqual row ' + Format(NotEqual."Line No."));
            end;
        }
        dataitem(ListOfTwo; "RPT TvQ Line")
        {
            DataItemTableView = where(Type = filter(Type::Item | Type::Charge));

            trigger OnPreDataItem()
            begin
                L.Add('ListOfTwo view=' + ListOfTwo.GetView());
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('ListOfTwo row ' + Format(ListOfTwo."Line No."));
            end;
        }
        dataitem(RangeOf; "RPT TvQ Line")
        {
            DataItemTableView = where(Type = filter(Type::Item .. Type::Resource));

            trigger OnPreDataItem()
            begin
                L.Add('RangeOf view=' + RangeOf.GetView());
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('RangeOf row ' + Format(RangeOf."Line No."));
            end;
        }
        // The reporter's shape: two fields, the second with a list.
        dataitem(TwoFields; "RPT TvQ Line")
        {
            DataItemTableView = sorting("Line No.") where(Type = filter(Type::Item), "Document Type" = filter("Document Type"::Quote | "Document Type"::"Order"));

            trigger OnPreDataItem()
            begin
                L.Add('TwoFields view=' + TwoFields.GetView());
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('TwoFields row ' + Format(TwoFields."Line No."));
            end;
        }
        dataitem(OptionField; "RPT TvQ Line")
        {
            DataItemTableView = where("Opt Kind" = filter("Opt Kind"::Small | "Opt Kind"::Large));

            trigger OnPreDataItem()
            begin
                L.Add('OptionField view=' + OptionField.GetView());
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('OptionField row ' + Format(OptionField."Line No."));
            end;
        }
        // Controls: the plain member name and the enum-type-qualified form.
        dataitem(PlainMember; "RPT TvQ Line")
        {
            DataItemTableView = where(Type = const(Item));

            trigger OnPreDataItem()
            begin
                L.Add('PlainMember view=' + PlainMember.GetView());
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('PlainMember row ' + Format(PlainMember."Line No."));
            end;
        }
        dataitem(TypeQualified; "RPT TvQ Line")
        {
            DataItemTableView = where(Type = filter("RPT TvQ Kind"::Item));

            trigger OnPreDataItem()
            begin
                L.Add('TypeQualified view=' + TypeQualified.GetView());
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('TypeQualified row ' + Format(TypeQualified."Line No."));
            end;
        }
    }

    var
        L: Codeunit "RPT TvQ Log";
}

page 62315 "RPT TvQ List"
{
    PageType = List;
    SourceTable = "RPT TvQ Line";
    SourceTableView = where(Type = filter(Type::Item), "Document Type" = filter(<> "Document Type"::Invoice));
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        L: Codeunit "RPT TvQ Log";
    begin
        L.Add('page view=' + Rec.GetView() + ' count=' + Format(Rec.Count()));
    end;
}

query 62316 "RPT TvQ Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Line; "RPT TvQ Line")
        {
            DataItemTableFilter = Type = filter(Type::Item | Type::Resource), "Document Type" = const("Document Type"::"Order");

            column(LineNo; "Line No.") { }
        }
    }
}

codeunit 62318 "RPT TvQ Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "RPT TvQ Log";

    // Line 1 blank/Quote/None, 2 Item/Quote/Small, 3 Item/Order/Large, 4 Resource/Order/None, 5 Charge/Invoice/Small, 6 Item/Invoice/Large.
    local procedure Seed()
    var
        Line: Record "RPT TvQ Line";
    begin
        Line.DeleteAll();
        Add(1, Line.Type::" ", Line."Document Type"::Quote, Line."Opt Kind"::None);
        Add(2, Line.Type::Item, Line."Document Type"::Quote, Line."Opt Kind"::Small);
        Add(3, Line.Type::Item, Line."Document Type"::"Order", Line."Opt Kind"::Large);
        Add(4, Line.Type::Resource, Line."Document Type"::"Order", Line."Opt Kind"::None);
        Add(5, Line.Type::Charge, Line."Document Type"::Invoice, Line."Opt Kind"::Small);
        Add(6, Line.Type::Item, Line."Document Type"::Invoice, Line."Opt Kind"::Large);
        L.Take();
    end;

    local procedure Add(No: Integer; Kind: Enum "RPT TvQ Kind"; Doc: Enum "RPT TvQ Doc"; Opt: Option)
    var
        Line: Record "RPT TvQ Line";
    begin
        Line.Init();
        Line."Line No." := No;
        Line.Type := Kind;
        Line."Document Type" := Doc;
        Line."Opt Kind" := Opt;
        Line.Insert();
    end;

    local procedure Part(Log: Text; Name: Text): Text
    var
        Entry: Text;
        Result: Text;
    begin
        foreach Entry in Log.Split(';') do
            if Entry.StartsWith(Name + ' ') then
                Result += Entry.Substring(StrLen(Name) + 2) + ';';
        exit(Result);
    end;

    [Test]
    procedure TableView_FieldQualifiedEnum_ReportDataItems_EnumField()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Seed();
        Report.Run(Report::"RPT TvQ Views", false);
        Log := L.Take();
        Observer.Observe('filter(Type::Item)', Part(Log, 'FilterField'));
        Observer.Observe('const(Type::Item)', Part(Log, 'ConstField'));
        Observer.Observe('filter(<>Type::Item)', Part(Log, 'NotEqual'));
        Observer.Observe('filter(Type::Item|Type::Charge)', Part(Log, 'ListOfTwo'));
        Observer.Observe('filter(Type::Item..Type::Resource)', Part(Log, 'RangeOf'));
        Observer.Finish();
    end;

    [Test]
    procedure TableView_FieldQualifiedEnum_ReportDataItems_TwoFieldsOptionAndControls()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Seed();
        Report.Run(Report::"RPT TvQ Views", false);
        Log := L.Take();
        Observer.Observe('two fields', Part(Log, 'TwoFields'));
        Observer.Observe('option field', Part(Log, 'OptionField'));
        Observer.Observe('control const(Item)', Part(Log, 'PlainMember'));
        Observer.Observe('control filter("RPT TvQ Kind"::Item)', Part(Log, 'TypeQualified'));
        Observer.Finish();
    end;

    [Test]
    procedure TableView_FieldQualifiedEnum_PageSourceTableView()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "RPT TvQ List";
        Rows: Text;
    begin
        Seed();
        Pg.OpenView();
        Observer.Observe('open', L.Take());
        if Pg.First() then
            repeat
                Rows += Pg."Line No.".Value + ' ';
            until not Pg.Next();
        Pg.Close();
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;

    [Test]
    procedure TableView_FieldQualifiedEnum_CalcFormula()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "RPT TvQ Line";
    begin
        Seed();
        Head.Get(1);
        Head.CalcFields("Item Lines", "Not Item Lines", "Item Or Res Lines", "Const Item Lines", "Quote Order Item Lines");
        Observer.Observe('filter(Type::Item)', Format(Head."Item Lines"));
        Observer.Observe('filter(<>Type::Item)', Format(Head."Not Item Lines"));
        Observer.Observe('filter(Type::Item|Type::Resource)', Format(Head."Item Or Res Lines"));
        Observer.Observe('const(Type::Item)', Format(Head."Const Item Lines"));
        Observer.Observe('two fields', Format(Head."Quote Order Item Lines"));
        Observer.Finish();
    end;

    [Test]
    procedure TableView_FieldQualifiedEnum_QueryDataItemTableFilter()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "RPT TvQ Query";
        Rows: Text;
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Rows += Format(Q.LineNo) + ' ';
        Q.Close();
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;
}
