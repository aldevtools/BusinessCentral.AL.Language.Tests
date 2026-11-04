// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

xmlport 72151 "LT P121 XP LinkForce"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(RowEl; "LT P121 Row")
            {
                fieldelement(Id; RowEl.Id) { }
                tableelement(Child; "LT P121 Line")
                {
                    LinkTable = RowEl;
                    LinkFields = RowId = field(Id);
                    LinkTableForceInsert = true;

                    fieldelement(LineNo; Child.LineNo) { }
                    fieldelement(Amount; Child.Amount) { }
                }
            }
        }
    }

}

codeunit 72152 "LT P121 XP LinkForce Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_Import()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        Helper.ImportText(Xmlport::"LT P121 XP LinkForce", '<Root><RowEl><Id>71</Id><Child><LineNo>1</LineNo><Amount>9</Amount></Child><Child><LineNo>2</LineNo><Amount>8</Amount></Child></RowEl></Root>');
        Observer.Observe('rows', Helper.Rows());
        Observer.Expect('rows', '1:a:10,2:b:20,71::0,');
        Observer.Verify();
    end;

    [Test]
    procedure P121_Export()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(Xmlport::"LT P121 XP LinkForce"));
        Observer.ObserveError('af61');
        Observer.Expect('af61|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af61|code', 'InvalidStreamData');
        Observer.Verify();
    end;

}
