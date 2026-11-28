// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-includecaption-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Temp Blob (Base Application); self-contained tables 75800, 75801, 75806, enum 75807, reports 75802-75804, 75808, 75809, test codeunits 75805, 75810 (part 2 below)
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

// Part 2 (al-runner lost pass 9330, report 99000763 "Prod. Order - List"): the field types and properties that report puts behind
//   a dotted data item name, as the second top-level data item. Objects: enum 75807, table 75806, reports 75808 (dotted), 75809
//   (undotted control), test codeunit 75810. Fields: Enum with value captions, Code with and without Caption, Integer with and
//   without Caption, Date, Text[100], Option with OptionCaption, Decimal AutoFormatType 0 + DecimalPlaces 0:5, Decimal
//   AutoFormatType 0 alone, AutoFormatType 2 + AutoFormatExpression '', AutoFormatType 1 + AutoFormatExpression ''. Columns with
//   IncludeCaption, without any property, and bare (unqualified) beside the dotted ones. Row 2 holds only its key (default values).
// Measured on BC on Linux 27.5, 28.5 and 29.0 (CI setup); all three tiers gave the same lines, so there is no version guard.
//   Every Label and Column line of the dotted report 75808 equals the line of the undotted control 75809.
//   IncludeCaption gives the field Caption for every type, or the field name when the field has none ('Bin Code', 'Seq').
//   Labels are written when the item has no rows. Column values: Enum and Option give the value caption ('DQ Released cap',
//   'DQ Simulated cap' for the default, 'DQ Open cap', ' ' for the blank option member); Code and Text the text, '' when empty;
//   Integer the number, 0 by default; Date '1/15/2026', '' for 0D. None of these has a decimalformatter. Decimal
//   decimalformatter: AutoFormatType 0 + DecimalPlaces 0:5 '#,##0.#####', AutoFormatType 0 alone '#,##0.00', AutoFormatType 2 +
//   AutoFormatExpression '' '#,##0.00###', AutoFormatType 1 + AutoFormatExpression '' '#,##0.00'; a zero value is '0'. A column
//   without IncludeCaption, and a bare column beside the dotted ones, give the same value and decimalformatter.

enum 75807 "LT DQ Status"
{
    Extensible = false;

    value(0; Simulated) { Caption = 'DQ Simulated cap'; }
    value(3; Released) { Caption = 'DQ Released cap'; }
}

table 75806 "LT DQ Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Status; Enum "LT DQ Status") { Caption = 'DQ Status cap'; }
        field(2; "Order No."; Code[20]) { Caption = 'DQ Order No. cap'; }
        field(3; "Line No."; Integer) { Caption = 'DQ Line No. cap'; }
        field(4; Description; Text[100]) { Caption = 'DQ Description cap'; }
        field(5; "Starting Date"; Date) { Caption = 'DQ Starting Date cap'; }
        field(6; Quantity; Decimal) { AutoFormatType = 0; Caption = 'DQ Quantity cap'; DecimalPlaces = 0 : 5; }
        field(7; "Unit Cost"; Decimal) { AutoFormatType = 2; AutoFormatExpression = ''; Caption = 'DQ Unit Cost cap'; }
        field(8; "Cost Amount"; Decimal) { AutoFormatType = 1; AutoFormatExpression = ''; Caption = 'DQ Cost Amount cap'; }
        field(9; Kind; Option) { Caption = 'DQ Kind cap'; OptionMembers = " ",Open,Closed; OptionCaption = ' ,DQ Open cap,DQ Closed cap'; }
        field(10; "Bin Code"; Code[10]) { }
        field(11; Seq; Integer) { }
        field(12; ZeroFmt; Decimal) { AutoFormatType = 0; Caption = 'DQ ZeroFmt cap'; }
    }

    keys
    {
        key(PK; "Order No.", "Line No.") { Clustered = true; }
    }
}

// The dotted item is the second top-level data item, as "Prod. Order Line" in report 99000763.
report 75808 "LT DQ Typed Dotted"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem("Dq. Head"; "LT DQ Row")
        {
            column(HName; "Dq. Head".Name) { IncludeCaption = true; }
        }
        dataitem("Dq. Line"; "LT DQ Line")
        {
            column(LStatus; "Dq. Line".Status) { IncludeCaption = true; }
            column(LOrderNo; "Dq. Line"."Order No.") { IncludeCaption = true; }
            column(LLineNo; "Dq. Line"."Line No.") { IncludeCaption = true; }
            column(LDescription; "Dq. Line".Description) { IncludeCaption = true; }
            column(LStartingDate; "Dq. Line"."Starting Date") { IncludeCaption = true; }
            column(LQuantity; "Dq. Line".Quantity) { IncludeCaption = true; }
            column(LUnitCost; "Dq. Line"."Unit Cost") { IncludeCaption = true; }
            column(LCostAmount; "Dq. Line"."Cost Amount") { IncludeCaption = true; }
            column(LKind; "Dq. Line".Kind) { IncludeCaption = true; }
            column(LBinCode; "Dq. Line"."Bin Code") { IncludeCaption = true; }
            column(LSeq; "Dq. Line".Seq) { IncludeCaption = true; }
            column(LZeroFmt; "Dq. Line".ZeroFmt) { IncludeCaption = true; }
            column(LStatusNoProp; "Dq. Line".Status) { }
            column(LQuantityNoProp; "Dq. Line".Quantity) { }
            column(LCostAmountNoProp; "Dq. Line"."Cost Amount") { }
            column(LStartingDateNoProp; "Dq. Line"."Starting Date") { }
            column(LBareStatus; Status) { IncludeCaption = true; }
            column(LBareQuantity; Quantity) { IncludeCaption = true; }
        }
    }
}

// Control: the same columns with undotted data item names.
report 75809 "LT DQ Typed Undotted"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(DqHead; "LT DQ Row")
        {
            column(HName; DqHead.Name) { IncludeCaption = true; }
        }
        dataitem(DqLine; "LT DQ Line")
        {
            column(LStatus; DqLine.Status) { IncludeCaption = true; }
            column(LOrderNo; DqLine."Order No.") { IncludeCaption = true; }
            column(LLineNo; DqLine."Line No.") { IncludeCaption = true; }
            column(LDescription; DqLine.Description) { IncludeCaption = true; }
            column(LStartingDate; DqLine."Starting Date") { IncludeCaption = true; }
            column(LQuantity; DqLine.Quantity) { IncludeCaption = true; }
            column(LUnitCost; DqLine."Unit Cost") { IncludeCaption = true; }
            column(LCostAmount; DqLine."Cost Amount") { IncludeCaption = true; }
            column(LKind; DqLine.Kind) { IncludeCaption = true; }
            column(LBinCode; DqLine."Bin Code") { IncludeCaption = true; }
            column(LSeq; DqLine.Seq) { IncludeCaption = true; }
            column(LZeroFmt; DqLine.ZeroFmt) { IncludeCaption = true; }
            column(LStatusNoProp; DqLine.Status) { }
            column(LQuantityNoProp; DqLine.Quantity) { }
            column(LCostAmountNoProp; DqLine."Cost Amount") { }
            column(LStartingDateNoProp; DqLine."Starting Date") { }
            column(LBareStatus; Status) { IncludeCaption = true; }
            column(LBareQuantity; Quantity) { IncludeCaption = true; }
        }
    }
}

codeunit 75810 "LT DQ Typed Qualifier Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT DQ Row";
        Line: Record "LT DQ Line";
    begin
        ClearAll();
        Row.Id := 1;
        Row.Name := 'Head one';
        Row.Insert();
        Line."Order No." := 'PO-1';
        Line."Line No." := 10000;
        Line.Status := Line.Status::Released;
        Line.Description := 'Line one';
        Line."Starting Date" := DMY2Date(15, 1, 2026);
        Line.Quantity := 12.34567;
        Line."Unit Cost" := 1.23456;
        Line."Cost Amount" := 1234.5;
        Line.Kind := Line.Kind::Open;
        Line."Bin Code" := 'B1';
        Line.Seq := 7;
        Line.ZeroFmt := 2.5;
        Line.Insert();
        Clear(Line);
        Line."Order No." := 'PO-1';
        Line."Line No." := 20000;
        Line.Insert();
    end;

    local procedure ClearAll()
    var
        Row: Record "LT DQ Row";
        Child: Record "LT DQ Child";
        Line: Record "LT DQ Line";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        Line.DeleteAll();
    end;

    // The trimmed lines of the SaveAs Xml dataset, each in brackets.
    local procedure Dataset(ReportId: Integer): Text
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
            Result += '[' + Line.Trim() + ']';
        end;
        exit(Result);
    end;

    // The bracketed lines of Xml that start with Keep.
    local procedure Pick(Xml: Text; Keep: Text): Text
    var
        Parts: List of [Text];
        Part: Text;
        Result: Text;
    begin
        Parts := Xml.Split(']');
        foreach Part in Parts do
            if Part.StartsWith('[' + Keep) then
                Result += Part + ']';
        exit(Result);
    end;

    local procedure ObserveLabels(var Observer: Codeunit "Probe Observer"; Xml: Text)
    begin
        Observer.Observe('labels head', Pick(Xml, '<Label name="H'));
        Observer.Observe('labels code int date text', Pick(Xml, '<Label name="LOrderNo') + Pick(Xml, '<Label name="LLineNo') + Pick(Xml, '<Label name="LDescription') + Pick(Xml, '<Label name="LStartingDate') + Pick(Xml, '<Label name="LBinCode') + Pick(Xml, '<Label name="LSeq'));
        Observer.Observe('labels enum option', Pick(Xml, '<Label name="LStatus') + Pick(Xml, '<Label name="LKind') + Pick(Xml, '<Label name="LBareStatus'));
        Observer.Observe('labels decimal', Pick(Xml, '<Label name="LQuantity') + Pick(Xml, '<Label name="LUnitCost') + Pick(Xml, '<Label name="LCostAmount') + Pick(Xml, '<Label name="LZeroFmt') + Pick(Xml, '<Label name="LBareQuantity'));
    end;

    local procedure ObserveCodeIntDate(var Observer: Codeunit "Probe Observer"; Xml: Text)
    begin
        Observer.Observe('LOrderNo', Pick(Xml, '<Column name="LOrderNo"'));
        Observer.Observe('LLineNo', Pick(Xml, '<Column name="LLineNo"'));
        Observer.Observe('LDescription', Pick(Xml, '<Column name="LDescription"'));
        Observer.Observe('LStartingDate', Pick(Xml, '<Column name="LStartingDate"'));
        Observer.Observe('LStartingDateNoProp', Pick(Xml, '<Column name="LStartingDateNoProp"'));
        Observer.Observe('LBinCode', Pick(Xml, '<Column name="LBinCode"'));
        Observer.Observe('LSeq', Pick(Xml, '<Column name="LSeq"'));
    end;

    local procedure ObserveEnumOption(var Observer: Codeunit "Probe Observer"; Xml: Text)
    begin
        Observer.Observe('LStatus', Pick(Xml, '<Column name="LStatus"'));
        Observer.Observe('LStatusNoProp', Pick(Xml, '<Column name="LStatusNoProp"'));
        Observer.Observe('LBareStatus', Pick(Xml, '<Column name="LBareStatus"'));
        Observer.Observe('LKind', Pick(Xml, '<Column name="LKind"'));
    end;

    local procedure ObserveDecimals(var Observer: Codeunit "Probe Observer"; Xml: Text)
    begin
        Observer.Observe('LQuantity', Pick(Xml, '<Column name="LQuantity"'));
        Observer.Observe('LQuantityNoProp', Pick(Xml, '<Column name="LQuantityNoProp"'));
        Observer.Observe('LBareQuantity', Pick(Xml, '<Column name="LBareQuantity"'));
        Observer.Observe('LUnitCost', Pick(Xml, '<Column name="LUnitCost"'));
        Observer.Observe('LCostAmount', Pick(Xml, '<Column name="LCostAmount"'));
        Observer.Observe('LCostAmountNoProp', Pick(Xml, '<Column name="LCostAmountNoProp"'));
        Observer.Observe('LZeroFmt', Pick(Xml, '<Column name="LZeroFmt"'));
    end;

    [Test]
    procedure TypedDotted_Labels()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ObserveLabels(Observer, Dataset(Report::"LT DQ Typed Dotted"));
        Observer.Expect('labels head', '[<Label name="HNameCaption">DQ Name cap</Label>]');
        Observer.Expect('labels code int date text', '[<Label name="LOrderNoCaption">DQ Order No. cap</Label>][<Label name="LLineNoCaption">DQ Line No. cap</Label>][<Label name="LDescriptionCaption">DQ Description cap</Label>][<Label name="LStartingDateCaption">DQ Starting Date cap</Label>][<Label name="LBinCodeCaption">Bin Code</Label>][<Label name="LSeqCaption">Seq</Label>]');
        Observer.Expect('labels enum option', '[<Label name="LStatusCaption">DQ Status cap</Label>][<Label name="LKindCaption">DQ Kind cap</Label>][<Label name="LBareStatusCaption">DQ Status cap</Label>]');
        Observer.Expect('labels decimal', '[<Label name="LQuantityCaption">DQ Quantity cap</Label>][<Label name="LUnitCostCaption">DQ Unit Cost cap</Label>][<Label name="LCostAmountCaption">DQ Cost Amount cap</Label>][<Label name="LZeroFmtCaption">DQ ZeroFmt cap</Label>][<Label name="LBareQuantityCaption">DQ Quantity cap</Label>]');
        Observer.Verify();
    end;

    [Test]
    procedure TypedDotted_Labels_WhenNoRows()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        ClearAll();
        Xml := Dataset(Report::"LT DQ Typed Dotted");
        ObserveLabels(Observer, Xml);
        Observer.Observe('columns', Pick(Xml, '<Column '));
        Observer.Expect('labels head', '[<Label name="HNameCaption">DQ Name cap</Label>]');
        Observer.Expect('labels code int date text', '[<Label name="LOrderNoCaption">DQ Order No. cap</Label>][<Label name="LLineNoCaption">DQ Line No. cap</Label>][<Label name="LDescriptionCaption">DQ Description cap</Label>][<Label name="LStartingDateCaption">DQ Starting Date cap</Label>][<Label name="LBinCodeCaption">Bin Code</Label>][<Label name="LSeqCaption">Seq</Label>]');
        Observer.Expect('labels enum option', '[<Label name="LStatusCaption">DQ Status cap</Label>][<Label name="LKindCaption">DQ Kind cap</Label>][<Label name="LBareStatusCaption">DQ Status cap</Label>]');
        Observer.Expect('labels decimal', '[<Label name="LQuantityCaption">DQ Quantity cap</Label>][<Label name="LUnitCostCaption">DQ Unit Cost cap</Label>][<Label name="LCostAmountCaption">DQ Cost Amount cap</Label>][<Label name="LZeroFmtCaption">DQ ZeroFmt cap</Label>][<Label name="LBareQuantityCaption">DQ Quantity cap</Label>]');
        Observer.Expect('columns', '');
        Observer.Verify();
    end;

    [Test]
    procedure TypedDotted_Columns_CodeIntegerDate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ObserveCodeIntDate(Observer, Dataset(Report::"LT DQ Typed Dotted"));
        Observer.Expect('LOrderNo', '[<Column name="LOrderNo">PO-1</Column>][<Column name="LOrderNo">PO-1</Column>]');
        Observer.Expect('LLineNo', '[<Column name="LLineNo">10000</Column>][<Column name="LLineNo">20000</Column>]');
        Observer.Expect('LDescription', '[<Column name="LDescription">Line one</Column>][<Column name="LDescription"></Column>]');
        Observer.Expect('LStartingDate', '[<Column name="LStartingDate">1/15/2026</Column>][<Column name="LStartingDate"></Column>]');
        Observer.Expect('LStartingDateNoProp', '[<Column name="LStartingDateNoProp">1/15/2026</Column>][<Column name="LStartingDateNoProp"></Column>]');
        Observer.Expect('LBinCode', '[<Column name="LBinCode">B1</Column>][<Column name="LBinCode"></Column>]');
        Observer.Expect('LSeq', '[<Column name="LSeq">7</Column>][<Column name="LSeq">0</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure TypedDotted_Columns_EnumOption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ObserveEnumOption(Observer, Dataset(Report::"LT DQ Typed Dotted"));
        Observer.Expect('LStatus', '[<Column name="LStatus">DQ Released cap</Column>][<Column name="LStatus">DQ Simulated cap</Column>]');
        Observer.Expect('LStatusNoProp', '[<Column name="LStatusNoProp">DQ Released cap</Column>][<Column name="LStatusNoProp">DQ Simulated cap</Column>]');
        Observer.Expect('LBareStatus', '[<Column name="LBareStatus">DQ Released cap</Column>][<Column name="LBareStatus">DQ Simulated cap</Column>]');
        Observer.Expect('LKind', '[<Column name="LKind">DQ Open cap</Column>][<Column name="LKind"> </Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure TypedDotted_Columns_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ObserveDecimals(Observer, Dataset(Report::"LT DQ Typed Dotted"));
        Observer.Expect('LQuantity', '[<Column name="LQuantity" decimalformatter="#,##0.#####">12.34567</Column>][<Column name="LQuantity" decimalformatter="#,##0.#####">0</Column>]');
        Observer.Expect('LQuantityNoProp', '[<Column name="LQuantityNoProp" decimalformatter="#,##0.#####">12.34567</Column>][<Column name="LQuantityNoProp" decimalformatter="#,##0.#####">0</Column>]');
        Observer.Expect('LBareQuantity', '[<Column name="LBareQuantity" decimalformatter="#,##0.#####">12.34567</Column>][<Column name="LBareQuantity" decimalformatter="#,##0.#####">0</Column>]');
        Observer.Expect('LUnitCost', '[<Column name="LUnitCost" decimalformatter="#,##0.00###">1.23456</Column>][<Column name="LUnitCost" decimalformatter="#,##0.00###">0</Column>]');
        Observer.Expect('LCostAmount', '[<Column name="LCostAmount" decimalformatter="#,##0.00">1234.5</Column>][<Column name="LCostAmount" decimalformatter="#,##0.00">0</Column>]');
        Observer.Expect('LCostAmountNoProp', '[<Column name="LCostAmountNoProp" decimalformatter="#,##0.00">1234.5</Column>][<Column name="LCostAmountNoProp" decimalformatter="#,##0.00">0</Column>]');
        Observer.Expect('LZeroFmt', '[<Column name="LZeroFmt" decimalformatter="#,##0.00">2.5</Column>][<Column name="LZeroFmt" decimalformatter="#,##0.00">0</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure TypedUndotted_Labels()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ObserveLabels(Observer, Dataset(Report::"LT DQ Typed Undotted"));
        Observer.Expect('labels head', '[<Label name="HNameCaption">DQ Name cap</Label>]');
        Observer.Expect('labels code int date text', '[<Label name="LOrderNoCaption">DQ Order No. cap</Label>][<Label name="LLineNoCaption">DQ Line No. cap</Label>][<Label name="LDescriptionCaption">DQ Description cap</Label>][<Label name="LStartingDateCaption">DQ Starting Date cap</Label>][<Label name="LBinCodeCaption">Bin Code</Label>][<Label name="LSeqCaption">Seq</Label>]');
        Observer.Expect('labels enum option', '[<Label name="LStatusCaption">DQ Status cap</Label>][<Label name="LKindCaption">DQ Kind cap</Label>][<Label name="LBareStatusCaption">DQ Status cap</Label>]');
        Observer.Expect('labels decimal', '[<Label name="LQuantityCaption">DQ Quantity cap</Label>][<Label name="LUnitCostCaption">DQ Unit Cost cap</Label>][<Label name="LCostAmountCaption">DQ Cost Amount cap</Label>][<Label name="LZeroFmtCaption">DQ ZeroFmt cap</Label>][<Label name="LBareQuantityCaption">DQ Quantity cap</Label>]');
        Observer.Verify();
    end;

    [Test]
    procedure TypedUndotted_Columns_CodeIntegerDate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ObserveCodeIntDate(Observer, Dataset(Report::"LT DQ Typed Undotted"));
        Observer.Expect('LOrderNo', '[<Column name="LOrderNo">PO-1</Column>][<Column name="LOrderNo">PO-1</Column>]');
        Observer.Expect('LLineNo', '[<Column name="LLineNo">10000</Column>][<Column name="LLineNo">20000</Column>]');
        Observer.Expect('LDescription', '[<Column name="LDescription">Line one</Column>][<Column name="LDescription"></Column>]');
        Observer.Expect('LStartingDate', '[<Column name="LStartingDate">1/15/2026</Column>][<Column name="LStartingDate"></Column>]');
        Observer.Expect('LStartingDateNoProp', '[<Column name="LStartingDateNoProp">1/15/2026</Column>][<Column name="LStartingDateNoProp"></Column>]');
        Observer.Expect('LBinCode', '[<Column name="LBinCode">B1</Column>][<Column name="LBinCode"></Column>]');
        Observer.Expect('LSeq', '[<Column name="LSeq">7</Column>][<Column name="LSeq">0</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure TypedUndotted_Columns_EnumOption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ObserveEnumOption(Observer, Dataset(Report::"LT DQ Typed Undotted"));
        Observer.Expect('LStatus', '[<Column name="LStatus">DQ Released cap</Column>][<Column name="LStatus">DQ Simulated cap</Column>]');
        Observer.Expect('LStatusNoProp', '[<Column name="LStatusNoProp">DQ Released cap</Column>][<Column name="LStatusNoProp">DQ Simulated cap</Column>]');
        Observer.Expect('LBareStatus', '[<Column name="LBareStatus">DQ Released cap</Column>][<Column name="LBareStatus">DQ Simulated cap</Column>]');
        Observer.Expect('LKind', '[<Column name="LKind">DQ Open cap</Column>][<Column name="LKind"> </Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure TypedUndotted_Columns_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ObserveDecimals(Observer, Dataset(Report::"LT DQ Typed Undotted"));
        Observer.Expect('LQuantity', '[<Column name="LQuantity" decimalformatter="#,##0.#####">12.34567</Column>][<Column name="LQuantity" decimalformatter="#,##0.#####">0</Column>]');
        Observer.Expect('LQuantityNoProp', '[<Column name="LQuantityNoProp" decimalformatter="#,##0.#####">12.34567</Column>][<Column name="LQuantityNoProp" decimalformatter="#,##0.#####">0</Column>]');
        Observer.Expect('LBareQuantity', '[<Column name="LBareQuantity" decimalformatter="#,##0.#####">12.34567</Column>][<Column name="LBareQuantity" decimalformatter="#,##0.#####">0</Column>]');
        Observer.Expect('LUnitCost', '[<Column name="LUnitCost" decimalformatter="#,##0.00###">1.23456</Column>][<Column name="LUnitCost" decimalformatter="#,##0.00###">0</Column>]');
        Observer.Expect('LCostAmount', '[<Column name="LCostAmount" decimalformatter="#,##0.00">1234.5</Column>][<Column name="LCostAmount" decimalformatter="#,##0.00">0</Column>]');
        Observer.Expect('LCostAmountNoProp', '[<Column name="LCostAmountNoProp" decimalformatter="#,##0.00">1234.5</Column>][<Column name="LCostAmountNoProp" decimalformatter="#,##0.00">0</Column>]');
        Observer.Expect('LZeroFmt', '[<Column name="LZeroFmt" decimalformatter="#,##0.00">2.5</Column>][<Column name="LZeroFmt" decimalformatter="#,##0.00">0</Column>]');
        Observer.Verify();
    end;
}
