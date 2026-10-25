// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 89000 "LT SC Cost Line" and 89003 "LT SC Other Line" of TestPageControlFieldArraySource.al; own page 89248, test codeunit 89249
// Facts: the "Page Control Field" (2000000192) row of controls whose source forms TestPageControlFieldArraySource.al does not cover: an array element with a
//   variable index (Costs[I]), an element of a two-dimensional array (Grid[1, 2]), a quoted variable name ("Unit Cost"), a field of a quoted record variable
//   ("Other Line".Amount), a procedure call (CostText()), a method call (Format(Rec.Quantity)) and a quoted field of Rec (Rec."Entry No." spelled with quotes).
//   Columns read: TableNo, FieldNo, Enabled, Editable, Visible, SourceExpression, OptionString, Sequence.
// BC answers: TableNo is the source table and FieldNo 0 for every non-field source; SourceExpression is the AL text as written (quotes kept, a
//   field of Rec without 'Rec.'); Editable is 'True' for variables and array elements, 'False' for calls.
// BC versions: 27, 28, 29

page 89248 "LT SM PCF Source Forms"
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
                field(CostIndexed; Costs[I]) { ApplicationArea = All; Caption = 'Cost I'; }
                field(GridCell; Grid[1, 2]) { ApplicationArea = All; Caption = 'Grid 1 2'; }
                field(QuotedVar; "Unit Cost") { ApplicationArea = All; Caption = 'Unit Cost'; }
                field(QuotedRecField; "Other Line".Amount) { ApplicationArea = All; Caption = 'Other Amount'; }
                field(ProcCall; CostText()) { ApplicationArea = All; Caption = 'Cost Text'; }
                field(FormatCall; Format(Rec.Quantity)) { ApplicationArea = All; Caption = 'Quantity Text'; }
                field(PlainQty; Rec.Quantity) { ApplicationArea = All; }
            }
        }
    }

    var
        Costs: array[2] of Decimal;
        Grid: array[2, 3] of Decimal;
        I: Integer;
        "Unit Cost": Decimal;
        "Other Line": Record "LT SC Other Line";

    local procedure CostText(): Text
    begin
        exit(Format(Costs[1]));
    end;
}

codeunit 89249 "LT SM PCF Source Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Row(ControlName: Text): Text
    var
        PageControlField: Record "Page Control Field";
    begin
        PageControlField.SetRange(PageNo, Page::"LT SM PCF Source Forms");
        PageControlField.SetRange(ControlName, ControlName);
        if not PageControlField.FindFirst() then
            exit('no row');
        exit(StrSubstNo('TableNo=%1 FieldNo=%2 Enabled=[%3] Editable=[%4] Visible=[%5] SourceExpression=[%6] OptionString=[%7] Sequence=%8',
            PageControlField.TableNo, PageControlField.FieldNo, PageControlField.Enabled, PageControlField.Editable,
            PageControlField.Visible, PageControlField.SourceExpression, PageControlField.OptionString, PageControlField.Sequence));
    end;

    [Test]
    procedure SourceForms_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Entry No.', Row('Entry No.'));
        Observer.Observe('CostIndexed', Row('CostIndexed'));
        Observer.Observe('GridCell', Row('GridCell'));
        Observer.Observe('QuotedVar', Row('QuotedVar'));
        Observer.Observe('QuotedRecField', Row('QuotedRecField'));
        Observer.Observe('ProcCall', Row('ProcCall'));
        Observer.Observe('FormatCall', Row('FormatCall'));
        Observer.Observe('PlainQty', Row('PlainQty'));
        Observer.Expect('Entry No.', 'TableNo=89000 FieldNo=1 Enabled=[true] Editable=[True] Visible=[true] SourceExpression=[Entry No.] OptionString=[] Sequence=0');
        Observer.Expect('CostIndexed', 'TableNo=89000 FieldNo=0 Enabled=[true] Editable=[True] Visible=[true] SourceExpression=[Costs[I]] OptionString=[] Sequence=1');
        Observer.Expect('GridCell', 'TableNo=89000 FieldNo=0 Enabled=[true] Editable=[True] Visible=[true] SourceExpression=[Grid[1, 2]] OptionString=[] Sequence=2');
        Observer.Expect('QuotedVar', 'TableNo=89000 FieldNo=0 Enabled=[true] Editable=[True] Visible=[true] SourceExpression=["Unit Cost"] OptionString=[] Sequence=3');
        Observer.Expect('QuotedRecField', 'TableNo=89000 FieldNo=0 Enabled=[true] Editable=[True] Visible=[true] SourceExpression=["Other Line".Amount] OptionString=[] Sequence=4');
        Observer.Expect('ProcCall', 'TableNo=89000 FieldNo=0 Enabled=[true] Editable=[False] Visible=[true] SourceExpression=[CostText()] OptionString=[] Sequence=5');
        Observer.Expect('FormatCall', 'TableNo=89000 FieldNo=0 Enabled=[true] Editable=[False] Visible=[true] SourceExpression=[Format(Rec.Quantity)] OptionString=[] Sequence=6');
        Observer.Expect('PlainQty', 'TableNo=89000 FieldNo=2 Enabled=[true] Editable=[True] Visible=[true] SourceExpression=[Quantity] OptionString=[] Sequence=7');
        Observer.Verify();
    end;
}
