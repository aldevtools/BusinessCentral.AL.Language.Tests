// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

xmlport 72167 "LT P121 XP Unbound"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(RowEl; "LT P121 Row")
            {
                fieldelement(Id; RowEl.Id) { }
                textelement(Free)
                {
                    Unbound = true;

                    trigger OnBeforePassVariable()
                    begin
                        Free := 'free' + Format(RowEl.Id);
                    end;
                }
            }
        }
    }

}

codeunit 72168 "LT P121 XP Unbound Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_Export()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        Observer.Verify();
    end;

}
