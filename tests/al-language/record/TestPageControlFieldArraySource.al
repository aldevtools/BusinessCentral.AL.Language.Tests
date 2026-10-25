// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-object
// Scope: in-scope
// Fixtures used: own table 89000 and 89003, page 89001, test codeunit 89002
// Probe: from al-runner issue 5842 (reporter's real-BC run on 29.0.54011.55407); every literal asserted below is what
//   BC produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the "Page Control Field" (2000000192) row of a page control whose source is not a field of the page's
//   source table: an element of a page global array (Costs[1] with Editable = false, Costs[2] with no properties),
//   a field of a page global record of another table (OtherLine.Amount), and an expression (Costs[1] + Costs[2]).
//   Columns read: TableNo, FieldNo, Enabled, Editable, Visible, SourceExpression, OptionString, Sequence.
//   A row of another control of the same page (HiddenQuantity, Visible = false) is read as well.
// BC versions: all (CI)
// Neighbours: record/TestPageControlFieldControlTree.al pins variable-bound and field-bound rows.

table 89000 "LT SC Cost Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Quantity; Decimal) { }
    }
    keys
    {
        key(PK; "Entry No.") { }
    }
}

table 89003 "LT SC Other Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(5; Amount; Decimal) { }
    }
    keys
    {
        key(PK; "Entry No.") { }
    }
}

page 89001 "LT SC Cost Line List"
{
    PageType = List;
    SourceTable = "LT SC Cost Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(HiddenQuantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(CostOne; Costs[1])
                {
                    ApplicationArea = All;
                    Caption = 'Cost 1';
                    Editable = false;
                }
                field(CostTwo; Costs[2])
                {
                    ApplicationArea = All;
                    Caption = 'Cost 2';
                }
                field(OtherAmount; OtherLine.Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Other Amount';
                }
                field(CostSum; Costs[1] + Costs[2])
                {
                    ApplicationArea = All;
                    Caption = 'Cost Sum';
                }
            }
        }
    }

    var
        Costs: array[2] of Decimal;
        OtherLine: Record "LT SC Other Line";
}

codeunit 89002 "LT SC Control Field Arr Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Row(ControlName: Text): Text
    var
        PageControlField: Record "Page Control Field";
    begin
        PageControlField.SetRange(PageNo, Page::"LT SC Cost Line List");
        PageControlField.SetRange(ControlName, ControlName);
        if not PageControlField.FindFirst() then
            exit('no row');
        exit(StrSubstNo('TableNo=%1 FieldNo=%2 Enabled=[%3] Editable=[%4] Visible=[%5] SourceExpression=[%6] OptionString=[%7] Sequence=%8',
            PageControlField.TableNo, PageControlField.FieldNo, PageControlField.Enabled, PageControlField.Editable,
            PageControlField.Visible, PageControlField.SourceExpression, PageControlField.OptionString, PageControlField.Sequence));
    end;

    [Test]
    procedure HiddenControlReportsVisibleFalse()
    var
        PageControlField: Record "Page Control Field";
        IsVisible: Boolean;
    begin
        // [GIVEN] a page that also has a control bound to an array element
        // [WHEN] the row of another control (Visible = false) is read
        PageControlField.SetRange(PageNo, Page::"LT SC Cost Line List");
        PageControlField.SetRange(ControlName, 'HiddenQuantity');
        Assert.IsTrue(PageControlField.FindFirst(), 'No Page Control Field row for HiddenQuantity.');
        // [THEN] Visible evaluates to false
        Assert.IsTrue(Evaluate(IsVisible, PageControlField.Visible), 'Visible is not a Boolean: ' + PageControlField.Visible);
        Assert.IsFalse(IsVisible, 'HiddenQuantity reports Visible = ' + PageControlField.Visible);
    end;

    [Test]
    procedure ArrayElementControlRow()
    begin
        // [GIVEN] CostOne bound to Costs[1], Editable = false
        // [THEN] the source table's number, no field, the element as written, editable as declared
        Assert.AreEqual('TableNo=89000 FieldNo=0 Enabled=[true] Editable=[false] Visible=[true] SourceExpression=[Costs[1]] OptionString=[] Sequence=2',
            Row('CostOne'), 'Page Control Field row of CostOne');
    end;

    [Test]
    procedure ArrayElementControlWithoutPropertiesRow()
    begin
        // [GIVEN] CostTwo bound to Costs[2], no Editable property
        Assert.AreEqual('TableNo=89000 FieldNo=0 Enabled=[true] Editable=[true] Visible=[true] SourceExpression=[Costs[2]] OptionString=[] Sequence=3',
            Row('CostTwo'), 'Page Control Field row of CostTwo');
    end;

    [Test]
    procedure GlobalRecordFieldControlRow()
    begin
        // [GIVEN] OtherAmount bound to OtherLine.Amount, a field of a global record of another table
        Assert.AreEqual('TableNo=89000 FieldNo=0 Enabled=[true] Editable=[true] Visible=[true] SourceExpression=[OtherLine.Amount] OptionString=[] Sequence=4',
            Row('OtherAmount'), 'Page Control Field row of OtherAmount');
    end;

    [Test]
    procedure ExpressionControlRow()
    begin
        // [GIVEN] CostSum bound to the expression Costs[1] + Costs[2]
        Assert.AreEqual('TableNo=89000 FieldNo=0 Enabled=[true] Editable=[true] Visible=[true] SourceExpression=[Costs[1] + Costs[2]] OptionString=[] Sequence=5',
            Row('CostSum'), 'Page Control Field row of CostSum');
    end;
}
