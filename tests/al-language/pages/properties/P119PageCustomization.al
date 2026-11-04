// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: a page customization that modifies a field with Visible = false (pagecustomization/modify Visible) on page 71629 (P119PageFields.al): whether a TestPage sees the change.

pagecustomization "LT P119 Customization" customizes "LT P119 Fields Card"
{
    layout
    {
        modify(PhoneF)
        {
            Visible = false;
        }
    }
}

codeunit 71678 "LT P119 Customiz Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_CustomizedField()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Fields Card";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Phone := '555';
        Row.Insert();
        TP.OpenView();
        Observer.Observe('phone-visible', Format(TP.PhoneF.Visible()));
        Observer.Observe('phone-value', TP.PhoneF.Value());
        Observer.Observe('mail-visible', Format(TP.MailF.Visible()));
        TP.Close();
        Observer.Expect('phone-visible', 'Yes');
        Observer.Expect('phone-value', '555');
        Observer.Expect('mail-visible', 'Yes');
        Observer.Verify();
    end;
}
