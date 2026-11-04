// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

xmlport 72145 "LT P121 XP DefNsTrue"
{
    Direction = Both;
    Format = Xml;
    DefaultNamespace = 'urn:lt-p121';
    UseDefaultNamespace = true;
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

codeunit 72146 "LT P121 XP DefNsTrue Test"
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
        asserterror Observer.Observe('xml', Helper.ExportText(Xmlport::"LT P121 XP DefNsTrue"));
        Observer.ObserveError('af42');
        Helper.Seed();
        Helper.ImportText(Xmlport::"LT P121 XP DefNsTrue", '<Root xmlns="urn:lt-p121"><RowEl><Id>51</Id><Txt>ns</Txt></RowEl></Root>');
        Observer.Observe('rows_ns', Helper.Rows());
        Helper.Seed();
        asserterror Helper.ImportText(Xmlport::"LT P121 XP DefNsTrue", '<Root><RowEl><Id>52</Id><Txt>nons</Txt></RowEl></Root>');
        Observer.ObserveError('import_no_ns');
        Observer.Observe('rows_no_ns', Helper.Rows());
        Observer.Expect('af42|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af42|code', 'InvalidStreamData');
        Observer.Expect('rows_ns', '1:a:10,2:b:20,51:ns:0,');
        Observer.Expect('import_no_ns|text', 'The element <Root> cannot be found in the object description.');
        Observer.Expect('import_no_ns|code', 'XmlPortElementNotFound');
        Observer.Expect('rows_no_ns', '');
        Observer.Verify();
    end;

}
