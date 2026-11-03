// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: fileuploadaction with Visible = false. A fileuploadaction is no TestPage member (TestPageLabelControlContracts.al): declared only, not observable; a plain action and a field are observed.

page 71666 "LT P119 FileUp Card"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(NameF; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PlainAct)
            {
                ApplicationArea = All;
                Caption = 'Plain';
                trigger OnAction()
                begin
                end;
            }
            fileuploadaction(UploadHidden)
            {
                ApplicationArea = All;
                Caption = 'Upload hidden';
                AllowMultipleFiles = true;
                Visible = false;
                trigger OnAction(Files: List of [FileUpload])
                begin
                end;
            }
        }
    }
}

codeunit 71667 "LT P119 FileUp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_NeighboursOfUploadAction()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 FileUp Card";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Up';
        Row.Insert();
        TP.OpenView();
        Observer.Observe('plain-visible', Format(TP.PlainAct.Visible()));
        Observer.Observe('name-value', TP.NameF.Value());
        TP.Close();
        Observer.Expect('plain-visible', 'Yes');
        Observer.Expect('name-value', 'Up');
        Observer.Verify();
    end;
}
