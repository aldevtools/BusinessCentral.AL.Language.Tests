// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

xmlport 72169 "LT P121 XP XmlName"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            XmlName = 'RenamedRoot';

            textattribute(Attr)
            {
                XmlName = 'RenamedAttr';

                trigger OnBeforePassVariable()
                begin
                    Attr := 'out';
                end;

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('attr=' + Attr);
                end;
            }
            textelement(Child)
            {
                XmlName = 'RenamedChild';

                trigger OnBeforePassVariable()
                begin
                    Child := 'childout';
                end;

                trigger OnAfterAssignVariable()
                begin
                    Log.Add('child=' + Child);
                end;
            }
        }
    }

    var
        Log: Codeunit "LT P121 Log";

}

codeunit 72170 "LT P121 XP XmlName Test"
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
        asserterror Observer.Observe('xml', Helper.ExportText(Xmlport::"LT P121 XP XmlName"));
        Observer.ObserveError('af67');
        Observer.Expect('af67|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af67|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure P121_Import()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Helper.ImportText(Xmlport::"LT P121 XP XmlName", '<RenamedRoot RenamedAttr="in1"><RenamedChild>c1</RenamedChild></RenamedRoot>');
        Observer.Observe('log', Log.Take());
        asserterror Helper.ImportText(Xmlport::"LT P121 XP XmlName", '<Root Attr="in2"><Child>c2</Child></Root>');
        Observer.ObserveError('import_codename');
        Observer.Observe('log_after_codename', Log.Take());
        Observer.Expect('log', 'attr=in1;child=c1;');
        Observer.Expect('import_codename|text', 'Imported XML cannot validate with the schema: The ''Root'' element is not declared.');
        Observer.Expect('import_codename|code', 'XmlPortInvalidXml');
        Observer.Expect('log_after_codename', '');
        Observer.Verify();
    end;

}
