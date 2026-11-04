// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

xmlport 72161 "LT P121 XP ReqFilt"
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
                RequestFilterFields = Id, Txt;

                fieldelement(Id; RowEl.Id) { }
                fieldelement(Txt; RowEl.Txt) { }
            }
        }
    }

}

codeunit 72162 "LT P121 XP ReqFilt Test"
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
        asserterror Observer.Observe('xml', Helper.ExportText(Xmlport::"LT P121 XP ReqFilt"));
        Observer.ObserveError('af42');
        Observer.Expect('af42|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af42|code', 'InvalidStreamData');
        Observer.Verify();
    end;

}
