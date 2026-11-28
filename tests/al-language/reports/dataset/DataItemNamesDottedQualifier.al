// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-includecaption-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Temp Blob (Base Application); self-contained tables 75800, 75801, reports 75802, 75803, 75804, test codeunit 75805
// Corpus issue 1648: a report column whose source is a field qualified with a quoted data item name that holds a dot and a space,
//   for example column(X; "Dq. Row".Qty). Pinned before only apart: a quoted qualifier of the own item (streams/P138ColCaptionQualified.al)
//   and a dot inside a quoted data item name (reports/dataset/ReportDatasetNames.al).
// Probe: measured on BC on Linux 27.5, 28.5 and 29.0 (the corpus CI setup); every literal asserted below is what those tiers produced.
// Facts: Report.SaveAs(Xml), the Label lines (IncludeCaption) and the Column lines (value and decimalformatter) of columns over
//   "Dq. Row".<field>: Text, Decimal with DecimalPlaces 0:3, AutoFormatType 1, AutoFormatType 2, AutoFormatType 1 with DecimalPlaces 0:3,
//   a quoted field name with a dot ("Unit Amt."), a Decimal without properties, a column with its own DecimalPlaces, a method call on the qualified field ("Dq. Row".Name.ToUpper()); the same fields read
//   from a nested data item through the dotted parent name; the same report with undotted data item names (control); data item names
//   with a dot and no space and with two dots; the Label lines when the data item has no rows.
// Measured: a quoted data item name with a dot (and a space, or two dots) qualifies its fields exactly as an undotted name does:
//   every Label and Column line of report 75802 equals the line of the undotted control report 75803. IncludeCaption gives the
//   field Caption, or the field name when the field has none ('Unit Amt.', 'Plain'); the labels are written when the item has no
//   rows. The decimalformatter follows the field: DecimalPlaces 0:3 '#,##0.###', AutoFormatType 1 '#,##0.00', AutoFormatType 2
//   '#,##0.00###', no properties '#,##0.00', a column's own DecimalPlaces 4:4 '#,##0.0000'. An AutoFormatType 1 field of the
//   parent read in the child item gets '#,##0.####' (dotted and undotted alike). AutoFormatType 1 with DecimalPlaces 0:3 gives
//   '#,##0.00' on 28.5 and 29.0 and '#,##0.###' on 27.5 (guarded below; same split as ReportColumnFormatsHeaderRest.al).
//   A third part after the field ("Dq. Row".Qty.Foo) does not compile (AL0132, tests/must-not-compile/cases/3840); IncludeCaption
//   on "Dq. Row".Name.ToUpper() does not compile (AL0385, case 3841); without IncludeCaption that column holds 'ROW ONE'.
// BC versions: 27.5, 28.5, 29.0

table 75800 "LT DQ Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'DQ Id cap'; }
        field(2; Name; Text[30]) { Caption = 'DQ Name cap'; }
        field(3; Qty; Decimal) { Caption = 'DQ Qty cap'; DecimalPlaces = 0 : 3; }
        field(4; Amt; Decimal) { Caption = 'DQ Amt cap'; AutoFormatType = 1; }
        field(5; Unit; Decimal) { Caption = 'DQ Unit cap'; AutoFormatType = 2; }
        field(6; AmtPlaces; Decimal) { Caption = 'DQ AmtPlaces cap'; AutoFormatType = 1; DecimalPlaces = 0 : 3; }
        field(7; "Unit Amt."; Decimal) { DecimalPlaces = 0 : 1; }
        field(8; Plain; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 75801 "LT DQ Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'DQ Child Id cap'; }
        field(2; RowId; Integer) { }
        field(3; Note; Text[30]) { Caption = 'DQ Child Note cap'; }
        field(4; Price; Decimal) { Caption = 'DQ Child Price cap'; DecimalPlaces = 0 : 4; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// The data item names hold a dot and a space. Columns D* read fields of the own item through its name, C* of the child item.
report 75802 "LT DQ Dotted"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem("Dq. Row"; "LT DQ Row")
        {
            column(DName; "Dq. Row".Name) { IncludeCaption = true; }
            column(DQty; "Dq. Row".Qty) { IncludeCaption = true; }
            column(DAmt; "Dq. Row".Amt) { IncludeCaption = true; }
            column(DUnit; "Dq. Row".Unit) { IncludeCaption = true; }
            column(DAmtPlaces; "Dq. Row".AmtPlaces) { IncludeCaption = true; }
            column(DUnitAmt; "Dq. Row"."Unit Amt.") { IncludeCaption = true; }
            column(DPlain; "Dq. Row".Plain) { IncludeCaption = true; }
            column(DQtyOwnPlaces; "Dq. Row".Qty) { DecimalPlaces = 4 : 4; }
            column(DBareQty; Qty) { IncludeCaption = true; }
            column(DUpper; "Dq. Row".Name.ToUpper()) { }

            dataitem("Dq. Child"; "LT DQ Child")
            {
                DataItemLink = RowId = field(Id);

                column(CParentName; "Dq. Row".Name) { IncludeCaption = true; }
                column(CParentQty; "Dq. Row".Qty) { IncludeCaption = true; }
                column(CParentAmt; "Dq. Row".Amt) { IncludeCaption = true; }
                column(CNote; "Dq. Child".Note) { IncludeCaption = true; }
                column(CPrice; "Dq. Child".Price) { IncludeCaption = true; }
            }
        }
    }
}

// Control: the same columns with undotted data item names.
report 75803 "LT DQ Undotted"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(DqRow; "LT DQ Row")
        {
            column(DName; DqRow.Name) { IncludeCaption = true; }
            column(DQty; DqRow.Qty) { IncludeCaption = true; }
            column(DAmt; DqRow.Amt) { IncludeCaption = true; }
            column(DUnit; DqRow.Unit) { IncludeCaption = true; }
            column(DAmtPlaces; DqRow.AmtPlaces) { IncludeCaption = true; }
            column(DUnitAmt; DqRow."Unit Amt.") { IncludeCaption = true; }
            column(DPlain; DqRow.Plain) { IncludeCaption = true; }
            column(DQtyOwnPlaces; DqRow.Qty) { DecimalPlaces = 4 : 4; }
            column(DBareQty; Qty) { IncludeCaption = true; }
            column(DUpper; DqRow.Name.ToUpper()) { }

            dataitem(DqChild; "LT DQ Child")
            {
                DataItemLink = RowId = field(Id);

                column(CParentName; DqRow.Name) { IncludeCaption = true; }
                column(CParentQty; DqRow.Qty) { IncludeCaption = true; }
                column(CParentAmt; DqRow.Amt) { IncludeCaption = true; }
                column(CNote; DqChild.Note) { IncludeCaption = true; }
                column(CPrice; DqChild.Price) { IncludeCaption = true; }
            }
        }
    }
}

// Other dotted names: a dot without a space, and two dots with spaces.
report 75804 "LT DQ Dot Variants"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem("Dq.Row"; "LT DQ Row")
        {
            column(VName; "Dq.Row".Name) { IncludeCaption = true; }
            column(VQty; "Dq.Row".Qty) { IncludeCaption = true; }
            column(VAmt; "Dq.Row".Amt) { IncludeCaption = true; }
        }
        dataitem("Dq. R. Two"; "LT DQ Row")
        {
            column(WName; "Dq. R. Two".Name) { IncludeCaption = true; }
            column(WQty; "Dq. R. Two".Qty) { IncludeCaption = true; }
            column(WUnitAmt; "Dq. R. Two"."Unit Amt.") { IncludeCaption = true; }
        }
    }
}

codeunit 75805 "LT DQ Dotted Qualifier Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT DQ Row";
        Child: Record "LT DQ Child";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Row one';
        Row.Qty := 2.5;
        Row.Amt := 1234.5;
        Row.Unit := 1.23456;
        Row.AmtPlaces := 1234.5;
        Row."Unit Amt." := 3.25;
        Row.Plain := 7;
        Row.Insert();
        Child.Id := 10;
        Child.RowId := 1;
        Child.Note := 'C1';
        Child.Price := 0.5;
        Child.Insert();
    end;

    local procedure Clear()
    var
        Row: Record "LT DQ Row";
        Child: Record "LT DQ Child";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
    end;

    // The trimmed lines of the SaveAs Xml dataset that start with Keep, each in brackets.
    local procedure Lines(ReportId: Integer; Keep: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(ReportId, '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Line.Trim().StartsWith(Keep) then
                Result += '[' + Line.Trim() + ']';
        end;
        exit(Result);
    end;

    [Test]
    procedure Dotted_Labels_OwnAndChild()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('labels', Lines(Report::"LT DQ Dotted", '<Label '));
        Observer.Expect('labels', '[<Label name="DNameCaption">DQ Name cap</Label>][<Label name="DQtyCaption">DQ Qty cap</Label>][<Label name="DAmtCaption">DQ Amt cap</Label>][<Label name="DUnitCaption">DQ Unit cap</Label>][<Label name="DAmtPlacesCaption">DQ AmtPlaces cap</Label>][<Label name="DUnitAmtCaption">Unit Amt.</Label>][<Label name="DPlainCaption">Plain</Label>][<Label name="DBareQtyCaption">DQ Qty cap</Label>][<Label name="CParentNameCaption">DQ Name cap</Label>][<Label name="CParentQtyCaption">DQ Qty cap</Label>][<Label name="CParentAmtCaption">DQ Amt cap</Label>][<Label name="CNoteCaption">DQ Child Note cap</Label>][<Label name="CPriceCaption">DQ Child Price cap</Label>]');
        Observer.Verify();
    end;

    [Test]
    procedure Dotted_Columns_OwnItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('columns', Lines(Report::"LT DQ Dotted", '<Column name="D'));
#if BC28PLUS
        Observer.Expect('columns', '[<Column name="DName">Row one</Column>][<Column name="DQty" decimalformatter="#,##0.###">2.5</Column>][<Column name="DAmt" decimalformatter="#,##0.00">1234.5</Column>][<Column name="DUnit" decimalformatter="#,##0.00###">1.23456</Column>][<Column name="DAmtPlaces" decimalformatter="#,##0.00">1234.5</Column>][<Column name="DUnitAmt" decimalformatter="#,##0.#">3.25</Column>][<Column name="DPlain" decimalformatter="#,##0.00">7</Column>][<Column name="DQtyOwnPlaces" decimalformatter="#,##0.0000">2.5</Column>][<Column name="DBareQty" decimalformatter="#,##0.###">2.5</Column>][<Column name="DUpper">ROW ONE</Column>]');
#else
        Observer.Expect('columns', '[<Column name="DName">Row one</Column>][<Column name="DQty" decimalformatter="#,##0.###">2.5</Column>][<Column name="DAmt" decimalformatter="#,##0.00">1234.5</Column>][<Column name="DUnit" decimalformatter="#,##0.00###">1.23456</Column>][<Column name="DAmtPlaces" decimalformatter="#,##0.###">1234.5</Column>][<Column name="DUnitAmt" decimalformatter="#,##0.#">3.25</Column>][<Column name="DPlain" decimalformatter="#,##0.00">7</Column>][<Column name="DQtyOwnPlaces" decimalformatter="#,##0.0000">2.5</Column>][<Column name="DBareQty" decimalformatter="#,##0.###">2.5</Column>][<Column name="DUpper">ROW ONE</Column>]');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Dotted_Columns_ChildItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('columns', Lines(Report::"LT DQ Dotted", '<Column name="C'));
        Observer.Expect('columns', '[<Column name="CParentName">Row one</Column>][<Column name="CParentQty" decimalformatter="#,##0.###">2.5</Column>][<Column name="CParentAmt" decimalformatter="#,##0.####">1234.5</Column>][<Column name="CNote">C1</Column>][<Column name="CPrice" decimalformatter="#,##0.####">0.5</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure Dotted_Labels_WhenNoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear();
        Observer.Observe('labels', Lines(Report::"LT DQ Dotted", '<Label '));
        Observer.Observe('columns', Lines(Report::"LT DQ Dotted", '<Column '));
        Observer.Expect('labels', '[<Label name="DNameCaption">DQ Name cap</Label>][<Label name="DQtyCaption">DQ Qty cap</Label>][<Label name="DAmtCaption">DQ Amt cap</Label>][<Label name="DUnitCaption">DQ Unit cap</Label>][<Label name="DAmtPlacesCaption">DQ AmtPlaces cap</Label>][<Label name="DUnitAmtCaption">Unit Amt.</Label>][<Label name="DPlainCaption">Plain</Label>][<Label name="DBareQtyCaption">DQ Qty cap</Label>][<Label name="CParentNameCaption">DQ Name cap</Label>][<Label name="CParentQtyCaption">DQ Qty cap</Label>][<Label name="CParentAmtCaption">DQ Amt cap</Label>][<Label name="CNoteCaption">DQ Child Note cap</Label>][<Label name="CPriceCaption">DQ Child Price cap</Label>]');
        Observer.Expect('columns', '');
        Observer.Verify();
    end;

    [Test]
    procedure Undotted_Labels_OwnAndChild()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('labels', Lines(Report::"LT DQ Undotted", '<Label '));
        Observer.Expect('labels', '[<Label name="DNameCaption">DQ Name cap</Label>][<Label name="DQtyCaption">DQ Qty cap</Label>][<Label name="DAmtCaption">DQ Amt cap</Label>][<Label name="DUnitCaption">DQ Unit cap</Label>][<Label name="DAmtPlacesCaption">DQ AmtPlaces cap</Label>][<Label name="DUnitAmtCaption">Unit Amt.</Label>][<Label name="DPlainCaption">Plain</Label>][<Label name="DBareQtyCaption">DQ Qty cap</Label>][<Label name="CParentNameCaption">DQ Name cap</Label>][<Label name="CParentQtyCaption">DQ Qty cap</Label>][<Label name="CParentAmtCaption">DQ Amt cap</Label>][<Label name="CNoteCaption">DQ Child Note cap</Label>][<Label name="CPriceCaption">DQ Child Price cap</Label>]');
        Observer.Verify();
    end;

    [Test]
    procedure Undotted_Columns_OwnItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('columns', Lines(Report::"LT DQ Undotted", '<Column name="D'));
#if BC28PLUS
        Observer.Expect('columns', '[<Column name="DName">Row one</Column>][<Column name="DQty" decimalformatter="#,##0.###">2.5</Column>][<Column name="DAmt" decimalformatter="#,##0.00">1234.5</Column>][<Column name="DUnit" decimalformatter="#,##0.00###">1.23456</Column>][<Column name="DAmtPlaces" decimalformatter="#,##0.00">1234.5</Column>][<Column name="DUnitAmt" decimalformatter="#,##0.#">3.25</Column>][<Column name="DPlain" decimalformatter="#,##0.00">7</Column>][<Column name="DQtyOwnPlaces" decimalformatter="#,##0.0000">2.5</Column>][<Column name="DBareQty" decimalformatter="#,##0.###">2.5</Column>][<Column name="DUpper">ROW ONE</Column>]');
#else
        Observer.Expect('columns', '[<Column name="DName">Row one</Column>][<Column name="DQty" decimalformatter="#,##0.###">2.5</Column>][<Column name="DAmt" decimalformatter="#,##0.00">1234.5</Column>][<Column name="DUnit" decimalformatter="#,##0.00###">1.23456</Column>][<Column name="DAmtPlaces" decimalformatter="#,##0.###">1234.5</Column>][<Column name="DUnitAmt" decimalformatter="#,##0.#">3.25</Column>][<Column name="DPlain" decimalformatter="#,##0.00">7</Column>][<Column name="DQtyOwnPlaces" decimalformatter="#,##0.0000">2.5</Column>][<Column name="DBareQty" decimalformatter="#,##0.###">2.5</Column>][<Column name="DUpper">ROW ONE</Column>]');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Undotted_Columns_ChildItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('columns', Lines(Report::"LT DQ Undotted", '<Column name="C'));
        Observer.Expect('columns', '[<Column name="CParentName">Row one</Column>][<Column name="CParentQty" decimalformatter="#,##0.###">2.5</Column>][<Column name="CParentAmt" decimalformatter="#,##0.####">1234.5</Column>][<Column name="CNote">C1</Column>][<Column name="CPrice" decimalformatter="#,##0.####">0.5</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure DotVariants_LabelsAndColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('labels', Lines(Report::"LT DQ Dot Variants", '<Label '));
        Observer.Observe('columns', Lines(Report::"LT DQ Dot Variants", '<Column '));
        Observer.Expect('labels', '[<Label name="VNameCaption">DQ Name cap</Label>][<Label name="VQtyCaption">DQ Qty cap</Label>][<Label name="VAmtCaption">DQ Amt cap</Label>][<Label name="WNameCaption">DQ Name cap</Label>][<Label name="WQtyCaption">DQ Qty cap</Label>][<Label name="WUnitAmtCaption">Unit Amt.</Label>]');
        Observer.Expect('columns', '[<Column name="VName">Row one</Column>][<Column name="VQty" decimalformatter="#,##0.###">2.5</Column>][<Column name="VAmt" decimalformatter="#,##0.00">1234.5</Column>][<Column name="WName">Row one</Column>][<Column name="WQty" decimalformatter="#,##0.###">2.5</Column>][<Column name="WUnitAmt" decimalformatter="#,##0.#">3.25</Column>]');
        Observer.Verify();
    end;
}
