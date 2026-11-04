// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// XmlPort encodings: Encoding / TextEncoding properties, byte lengths of exported blobs, import of differently encoded input, special characters.
// BC versions: 29 (27 and 28 by CI)

codeunit 73505 "LT XpT Encoding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Encoding_Utf8DefaultLength()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Müller € ß', 1, 1, true, 'C', 0D);
        asserterror Observer.Observe('xml', Helper.ExportText(73410));
        Observer.ObserveError('af21');
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('af21|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af21|code', 'InvalidStreamData');
        Observer.Expect('len', '514');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_XmlUtf16Property()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Müller € ß', 1, 1, true, 'C', 0D);
        Observer.Observe('xml', Helper.ExportTextEnc(73420, TextEncoding::UTF16));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?><NL><Root><NL>  <Item><NL>    <Id>1</Id><NL>    <Name>Müller € ß</Name><NL>  </Item><NL></Root>');
        Observer.Expect('len', '278');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_XmlUtf16ReadAsUtf8()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Mü', 1, 1, true, 'C', 0D);
        asserterror Observer.Observe('xml', Helper.ExportText(73420));
        Observer.ObserveError('af48');
        Observer.Expect('af48|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af48|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_XmlUtf16EmptyLength()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('xml', Helper.ExportTextEnc(73420, TextEncoding::UTF16));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?><NL><Root><NL>  <Item><NL>    <Id>0</Id><NL>    <Name /><NL>  </Item><NL></Root>');
        Observer.Expect('len', '248');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_CsvUtf8Length()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Müller € ß', 1, 1, true, 'C', 0D);
        Observer.Observe('csv', Helper.ExportText(73413));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('csv', '"1","Müller € ß","1","1.00","Yes"');
        Observer.Expect('len', '40');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_CsvWindowsLength()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Müller ß', 1, 1, true, 'C', 0D);
        Observer.Observe('csv', Helper.ExportTextEnc(73433, TextEncoding::Windows));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('csv', '"1","Müller ß","1","1.00","Yes"');
        Observer.Expect('len', '31');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_CsvWindowsEuroLength()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a€', 1, 1, true, 'C', 0D);
        Observer.Observe('csv', Helper.ExportTextEnc(73433, TextEncoding::Windows));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('csv', '"1","a€","1","1.00","Yes"');
        Observer.Expect('len', '25');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_CsvWindowsUnmappable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a✓b', 1, 1, true, 'C', 0D);
        Observer.Observe('csv', Helper.ExportTextEnc(73433, TextEncoding::Windows));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('csv', '"1","a?b","1","1.00","Yes"');
        Observer.Expect('len', '26');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_CsvUtf16Length()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Müller ß', 1, 1, true, 'C', 0D);
        Observer.Observe('csv', Helper.ExportTextEnc(73434, TextEncoding::UTF16));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('csv', '"1","Müller ß","1","1.00","Yes"');
        Observer.Expect('len', '64');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_CsvMsDosLength()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'Müller ß', 1, 1, true, 'C', 0D);
        Observer.Observe('csv', Helper.ExportTextEnc(73437, TextEncoding::MSDos));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('csv', '"1","Müller ß","1","1.00","Yes"');
        Observer.Expect('len', '31');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_ImportCsvWindows()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImportEnc(73433, '1,Müller ß,5,1.5,1', TextEncoding::Windows));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_ImportCsvUtf16()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImportEnc(73434, '1,Müller €,5,1.5,1', TextEncoding::UTF16));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_ImportCsvUtf8IntoWindowsXmlport()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImportEnc(73433, '1,Müller,5,1.5,1', TextEncoding::UTF8));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'error:If you choose XMLport format Fixed Text or Variable Text, then the root element must have source type Text.|XmlPortInvalidNodeType');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_ImportXmlUtf16Input()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImportEnc(73410, '<?xml version="1.0" encoding="utf-16"?><Root><Item><Id>1</Id><Name>Mü€</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>', TextEncoding::UTF16));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|Mü€|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_ImportXmlUtf16DeclaredButUtf8Bytes()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImportEnc(73410, '<?xml version="1.0" encoding="utf-16"?><Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>', TextEncoding::UTF8));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:There is no Unicode byte order mark. Cannot switch to Unicode.|XmlPortImport:Xml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_ImportXmlDeclaredLatin1()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImportEnc(73410, '<?xml version="1.0" encoding="iso-8859-1"?><Root><Item><Id>1</Id><Name>Mü</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>', TextEncoding::Windows));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|Mü|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_ImportXmlBomUtf8()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '' + Helper.Chr(65279) + '<Root><Item><Id>1</Id><Name>Mü</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|Mü|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_ExportXmlPrologText()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        asserterror Observer.Observe('xml', CopyStr(Helper.ExportText(73410), 1, 60));
        Observer.ObserveError('af235');
        Observer.Expect('af235|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af235|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_ExportEmojiSurrogate()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a😀b', 1, 1, true, 'C', 0D);
        asserterror Observer.Observe('xml', Helper.ExportText(73410));
        Observer.ObserveError('af248');
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Expect('af248|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af248|code', 'InvalidStreamData');
        Observer.Expect('len', '502');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_ImportControlCharacterEntity()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>a&#1;b</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Expect('err', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_ImportTabAndEntityNewline()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73410, '<Root><Item><Id>1</Id><Name>a&#9;b&#10;c</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|a b c|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Encoding_ExportControlCharacters()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'a' + Helper.Chr(1) + 'b' + Helper.Chr(9) + 'c', 1, 1, true, 'C', 0D);
        asserterror Observer.Observe('xml', Helper.ExportText(73410));
        Observer.ObserveError('af285');
        Observer.Expect('af285|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af285|code', 'InvalidStreamData');
        Observer.Verify();
    end;
}
