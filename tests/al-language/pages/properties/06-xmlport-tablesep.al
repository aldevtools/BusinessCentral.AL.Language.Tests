// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

xmlport 72163 "LT P121 XP TableSep"
{
    Direction = Both;
    Format = VariableText;
    FieldSeparator = ';';
    TableSeparator = '#T#';
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(RowEl; "LT P121 Row")
            {
                fieldelement(Id; RowEl.Id) { }
                fieldelement(Txt; RowEl.Txt) { }
            }
        }
    }

}

codeunit 72164 "LT P121 XP TableSep Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_ExportImport()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        Observer.Observe('text', Helper.ExportText(Xmlport::"LT P121 XP TableSep"));
        Helper.Seed();
        Helper.ImportText(Xmlport::"LT P121 XP TableSep", '61;x#T#62;y');
        Observer.Observe('rows_import', Helper.Rows());
        Observer.Expect('text', '"1";"a"|"2";"b"|');
        Observer.Expect('rows_import', '1:a:10,2:b:20,61:x#T#62:0,');
        Observer.Verify();
    end;

}
