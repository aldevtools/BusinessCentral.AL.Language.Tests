// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

xmlport 72149 "LT P121 XP FieldValElem"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(RowEl; "LT P121 Row")
            {
                fieldelement(Id; RowEl.Id) { }
                fieldelement(Txt; RowEl.Txt)
                {
                    FieldValidate = Yes;
                }
                fieldelement(Qty; RowEl.Qty)
                {
                    FieldValidate = No;
                }
            }
        }
    }

}

codeunit 72150 "LT P121 XP FieldValElem Test"
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
        Helper.ImportText(Xmlport::"LT P121 XP FieldValElem", '<Root><RowEl><Id>21</Id><Txt>t21</Txt><Qty>5</Qty></RowEl></Root>');
        Observer.Observe('validate_log', Log.Take());
        Observer.Observe('rows', Helper.Rows());
        Observer.Expect('validate_log', 'val Txt=t21;');
        Observer.Expect('rows', '1:a:10,2:b:20,21:t21:5,');
        Observer.Verify();
    end;

}
