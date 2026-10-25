// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// XmlPort namespaces: prefixed and default namespace on export and import, mismatching prefixes and namespaces.
// BC versions: 29 (27 and 28 by CI)

codeunit 73503 "LT XpT Namespaces"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Export_PrefixedNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(73417));
        Observer.ObserveError('af21');
        Observer.Expect('af21|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af21|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Export_DefaultNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', Helper.ExportText(73418));
        Observer.ObserveError('af34');
        Observer.Expect('af34|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af34|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Import_PrefixedMatching()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73417, '<ns1:Root xmlns:ns1="urn:lt:xpt"><ns1:Item><ns1:Id>1</ns1:Id><ns1:Name>A</ns1:Name></ns1:Item></ns1:Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_PrefixedDifferentPrefix()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73417, '<x:Root xmlns:x="urn:lt:xpt"><x:Item><x:Id>1</x:Id><x:Name>A</x:Name></x:Item></x:Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_PrefixedNoNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73417, '<Root><Item><Id>1</Id><Name>A</Name></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_PrefixedWrongNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73417, '<ns1:Root xmlns:ns1="urn:other"><ns1:Item><ns1:Id>1</ns1:Id><ns1:Name>A</ns1:Name></ns1:Item></ns1:Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:The prefix  is not defined in the Namespaces property of the XMLPort.|XmlPortNodeProcess');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_DefaultNsMatching()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73418, '<Root xmlns="urn:lt:xpt"><Item><Id>1</Id><Name>A</Name></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_DefaultNsMissing()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73418, '<Root><Item><Id>1</Id><Name>A</Name></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'ok');
        Observer.Expect('items', '1|A|0|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_DefaultNsWrong()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73418, '<Root xmlns="urn:other"><Item><Id>1</Id><Name>A</Name></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_DefaultNsViaPrefixDeclaration()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73418, '<a:Root xmlns:a="urn:lt:xpt"><a:Item><a:Id>1</a:Id><a:Name>A</a:Name></a:Item></a:Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_NoNamespaceXmlportWithNamespacedInput()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root xmlns="urn:x"><Item><Id>1</Id><Name>A</Name><Qty>1</Qty><Amount>1</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:The element <Root> cannot be found in the object description.|XmlPortElementNotFound');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_NoNamespaceXmlportWithUnusedPrefixDecl()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root xmlns:z="urn:z"><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    // Writer SL (2026-10-25): the namespaced ports export UTF-16 (the default Encoding), so a UTF-8 read fails (Export_PrefixedNamespace);
    // read the same export through a UTF-16 InStream, and import the exported text again.
    [Test]
    procedure Export_PrefixedNamespace_Utf16()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Xml: Text;
    begin
        Helper.Wipe();
        Helper.Seed();
        Xml := Helper.ExportTextEnc(73417, TextEncoding::UTF16);
        Observer.Observe('xml', Xml);
        Observer.Observe('len', Format(Helper.LastLength()));
        Helper.Wipe();
        Observer.Observe('reimport', Helper.TryImportEnc(73417, Xml.Replace('<NL>', Helper.Chr(13) + Helper.Chr(10)), TextEncoding::UTF16));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Finish();
    end;

    [Test]
    procedure Export_DefaultNamespace_Utf16()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
        Xml: Text;
    begin
        Helper.Wipe();
        Helper.Seed();
        Xml := Helper.ExportTextEnc(73418, TextEncoding::UTF16);
        Observer.Observe('xml', Xml);
        Observer.Observe('len', Format(Helper.LastLength()));
        Helper.Wipe();
        Observer.Observe('reimport', Helper.TryImportEnc(73418, Xml.Replace('<NL>', Helper.Chr(13) + Helper.Chr(10)), TextEncoding::UTF16));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Finish();
    end;

    // Import into the prefixed port with the element names it exports under (prefix ns1 on Root and Item, none on the field elements).
    [Test]
    procedure Import_PrefixedAsExported()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('rootItemOnly', Helper.TryImport(73417, '<ns1:Root xmlns:ns1="urn:lt:xpt"><ns1:Item><Id>1</Id><Name>A</Name></ns1:Item></ns1:Root>'));
        Observer.Observe('items1', Helper.DumpItems());
        Helper.Wipe();
        Observer.Observe('utf16', Helper.TryImportEnc(73417, '<ns1:Root xmlns:ns1="urn:lt:xpt"><ns1:Item><ns1:Id>1</ns1:Id><ns1:Name>A</ns1:Name></ns1:Item></ns1:Root>', TextEncoding::UTF16));
        Observer.Observe('items2', Helper.DumpItems());
        Observer.Finish();
    end;
}
