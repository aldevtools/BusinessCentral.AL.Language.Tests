// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: page 72351, codeunit 72352
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 72351 "LT P123 Label Card"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'P123 label card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                label(ClassLabel)
                {
                    ApplicationArea = All;
                    Caption = 'Plain label caption';
                    CaptionClass = '3,Class label caption';
                }
                label(PlainLabel)
                {
                    ApplicationArea = All;
                    Caption = 'Only plain';
                }
            }
        }
    }
}

codeunit 72352 "LT P123 Label Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_LabelCaptionClass()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT P123 Label Card";
    begin
        P.OpenView();
        Observer.Observe('class label caption', P.ClassLabel.Caption());
        Observer.Observe('plain label caption', P.PlainLabel.Caption());
        Observer.Observe('class label visible', Format(P.ClassLabel.Visible()));
        Observer.Expect('class label caption', 'Class label caption');
        Observer.Expect('plain label caption', 'Only plain');
        Observer.Expect('class label visible', 'Yes');
        Observer.Verify();
    end;
}
