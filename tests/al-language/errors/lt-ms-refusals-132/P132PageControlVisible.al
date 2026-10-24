// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73702 and page 73703
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Writer RV (al-runner issue 5786): controls whose Visible, Enabled or Editable is an expression over a source table field (Rec."Allow Edit",
//   Rec.Flag, not, a comparison, a field with a page variable) on a List page, own table 88723 and page 88724; test P132_RV_RecFieldExpressions.

table 73702 "LT P132 Ctl Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 73703 "LT P132 Ctl Page"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT P132 Ctl Row";

    layout
    {
        area(Content)
        {
            group(GrpVisVar)
            {
                Visible = ShowIt;
                field(InGrp; Rec.Name) { ApplicationArea = All; }
            }
            field(VisFalse; Rec.Name) { ApplicationArea = All; Visible = false; }
            field(VisTrue; Rec.Name) { ApplicationArea = All; Visible = true; }
            field(VisVar; Rec.Name) { ApplicationArea = All; Visible = ShowIt; }
            field(VisNotVar; Rec.Name) { ApplicationArea = All; Visible = not ShowIt; }
            field(VisAnd; Rec.Name) { ApplicationArea = All; Visible = ShowIt and ShowOther; }
            field(VisCmp; Rec.Name) { ApplicationArea = All; Visible = Cnt > 3; }
            field(EnVar; Rec.Name) { ApplicationArea = All; Enabled = ShowIt; }
            field(EnFalse; Rec.Name) { ApplicationArea = All; Enabled = false; }
            field(EdVar; Rec.Name) { ApplicationArea = All; Editable = ShowIt; }
            field(EdFalse; Rec.Name) { ApplicationArea = All; Editable = false; }
            field(AllVars; Rec.Name) { ApplicationArea = All; Visible = ShowIt; Enabled = ShowOther; Editable = not ShowIt; }
            field(Plain; Rec.Name) { ApplicationArea = All; }
        }
    }

    var
        ShowIt: Boolean;
        ShowOther: Boolean;
        Cnt: Integer;
}

table 88723 "LT RV Cost Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Quantity; Decimal) { }
        field(3; "Allow Edit"; Boolean) { }
        field(4; Flag; Boolean) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

page 88724 "LT RV Cost Line List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT RV Cost Line";

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
                    Editable = Rec."Allow Edit";
                    Visible = false;
                }
                field(EdRecPlain; Rec.Quantity) { ApplicationArea = All; Editable = Rec.Flag; }
                field(EdRecNot; Rec.Quantity) { ApplicationArea = All; Editable = not Rec."Allow Edit"; }
                field(EdRecCmp; Rec.Quantity) { ApplicationArea = All; Editable = Rec.Quantity > 0; }
                field(EdRecAndVar; Rec.Quantity) { ApplicationArea = All; Editable = Rec.Flag and EditAllowed; }
                field(VisRec; Rec.Quantity) { ApplicationArea = All; Visible = Rec.Flag; }
                field(EnRec; Rec.Quantity) { ApplicationArea = All; Enabled = Rec."Allow Edit"; }
            }
        }
    }

    var
        EditAllowed: Boolean;
}

codeunit 73704 "LT P132 Ctl Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ReadControl(var Observer: Codeunit "Probe Observer"; CtlName: Text)
    var
        PageControlField: Record "Page Control Field";
    begin
        PageControlField.SetRange(PageNo, Page::"LT P132 Ctl Page");
        PageControlField.SetRange(ControlName, CtlName);
        if not PageControlField.FindFirst() then begin
            Observer.Observe(CtlName, 'no row');
            exit;
        end;
        Observer.Observe(CtlName + '.Visible', PageControlField.Visible);
        Observer.Observe(CtlName + '.Enabled', PageControlField.Enabled);
        Observer.Observe(CtlName + '.Editable', PageControlField.Editable);
    end;

    [Test]
    procedure P132_VisibleExpressions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadControl(Observer, 'VisFalse');
        ReadControl(Observer, 'VisTrue');
        ReadControl(Observer, 'VisVar');
        ReadControl(Observer, 'VisNotVar');
        ReadControl(Observer, 'VisAnd');
        ReadControl(Observer, 'VisCmp');
        ReadControl(Observer, 'Plain');
        Observer.Expect('VisFalse.Visible', 'false');
        Observer.Expect('VisFalse.Enabled', 'true');
        Observer.Expect('VisFalse.Editable', 'True');
        Observer.Expect('VisTrue.Visible', 'true');
        Observer.Expect('VisTrue.Enabled', 'true');
        Observer.Expect('VisTrue.Editable', 'True');
        Observer.Expect('VisVar.Visible', 'p73703p73703ShowIt');
        Observer.Expect('VisVar.Enabled', 'true');
        Observer.Expect('VisVar.Editable', 'True');
        Observer.Expect('VisNotVar.Visible', 'not p73703p73703ShowIt');
        Observer.Expect('VisNotVar.Enabled', 'true');
        Observer.Expect('VisNotVar.Editable', 'True');
        Observer.Expect('VisAnd.Visible', 'p73703p73703ShowIt and p73703p73703ShowOther');
        Observer.Expect('VisAnd.Enabled', 'true');
        Observer.Expect('VisAnd.Editable', 'True');
        Observer.Expect('VisCmp.Visible', 'p73703p73703Cnt > 3');
        Observer.Expect('VisCmp.Enabled', 'true');
        Observer.Expect('VisCmp.Editable', 'True');
        Observer.Expect('Plain.Visible', 'true');
        Observer.Expect('Plain.Enabled', 'true');
        Observer.Expect('Plain.Editable', 'True');
        Observer.Verify();
    end;

    [Test]
    procedure P132_EnabledEditableExpressions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadControl(Observer, 'EnVar');
        ReadControl(Observer, 'EnFalse');
        ReadControl(Observer, 'EdVar');
        ReadControl(Observer, 'EdFalse');
        ReadControl(Observer, 'AllVars');
        Observer.Expect('EnVar.Visible', 'true');
        Observer.Expect('EnVar.Enabled', 'p73703p73703ShowIt');
        Observer.Expect('EnVar.Editable', 'True');
        Observer.Expect('EnFalse.Visible', 'true');
        Observer.Expect('EnFalse.Enabled', 'false');
        Observer.Expect('EnFalse.Editable', 'True');
        Observer.Expect('EdVar.Visible', 'true');
        Observer.Expect('EdVar.Enabled', 'true');
        Observer.Expect('EdVar.Editable', 'p73703p73703ShowIt');
        Observer.Expect('EdFalse.Visible', 'true');
        Observer.Expect('EdFalse.Enabled', 'true');
        Observer.Expect('EdFalse.Editable', 'false');
        Observer.Expect('AllVars.Visible', 'p73703p73703ShowIt');
        Observer.Expect('AllVars.Enabled', 'p73703p73703ShowOther');
        Observer.Expect('AllVars.Editable', 'not p73703p73703ShowIt');
        Observer.Verify();
    end;

    [Test]
    procedure P132_GroupWithVisibleExpression()
    var
        Observer: Codeunit "Probe Observer";
        PageControlField: Record "Page Control Field";
    begin
        ReadControl(Observer, 'InGrp');
        PageControlField.SetRange(PageNo, Page::"LT P132 Ctl Page");
        PageControlField.SetRange(ControlName, 'GrpVisVar');
        Observer.Observe('group_row_found', Format(PageControlField.FindFirst()));
        Observer.Expect('InGrp.Visible', 'true');
        Observer.Expect('InGrp.Enabled', 'true');
        Observer.Expect('InGrp.Editable', 'True');
        Observer.Expect('group_row_found', 'No');
        Observer.Verify();
    end;

    local procedure ReadRvControl(var Observer: Codeunit "Probe Observer"; CtlName: Text)
    var
        PageControlField: Record "Page Control Field";
    begin
        PageControlField.SetRange(PageNo, Page::"LT RV Cost Line List");
        PageControlField.SetRange(ControlName, CtlName);
        if not PageControlField.FindFirst() then begin
            Observer.Observe(CtlName, 'no row');
            exit;
        end;
        Observer.Observe(CtlName + '.Visible', PageControlField.Visible);
        Observer.Observe(CtlName + '.Enabled', PageControlField.Enabled);
        Observer.Observe(CtlName + '.Editable', PageControlField.Editable);
    end;

    // al-runner issue 5786: Visible, Enabled and Editable expressions over source table fields on a List page.
    [Test]
    procedure P132_RV_RecFieldExpressions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadRvControl(Observer, 'HiddenQuantity');
        ReadRvControl(Observer, 'EdRecPlain');
        ReadRvControl(Observer, 'EdRecNot');
        ReadRvControl(Observer, 'EdRecCmp');
        ReadRvControl(Observer, 'EdRecAndVar');
        ReadRvControl(Observer, 'VisRec');
        ReadRvControl(Observer, 'EnRec');
        ReadRvControl(Observer, 'Entry No.');
        Observer.Finish();
    end;
}
