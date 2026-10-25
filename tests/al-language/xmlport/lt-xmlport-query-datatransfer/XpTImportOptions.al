// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// XmlPort import with MinOccurs, AutoReplace/AutoUpdate/AutoSave, Skip/Break, attributes, LinkFields, FormatEvaluate and Direction.
// BC versions: 29 (27 and 28 by CI)

codeunit 73502 "LT XpT Import Options"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Import_OptionalMissingName()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73419, '<Root><Item><Id>1</Id><Qty>5</Qty></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1||5|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_OptionalAllPresent()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73419, '<Root><Item><Id>1</Id><Name>N</Name><Qty>5</Qty><Category>C</Category></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|N|5|0|false|C|;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_OptionalMissingQtyRequired()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73419, '<Root><Item><Id>1</Id><Name>N</Name></Item></Root>'));
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The element ''Item'' has incomplete content. List of possible elements expected: ''Qty''.|XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AutoReplaceExisting()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'old', 1, 9, true, 'Z', 20240101D);
        Commit();
        Observer.Observe('import1', Helper.TryImport(73426, '<Root><Item><Id>1</Id><Name>new</Name><Qty>7</Qty></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|new|7|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AutoUpdateExisting()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, 'old', 1, 9, true, 'Z', 20240101D);
        Commit();
        Observer.Observe('import1', Helper.TryImport(73427, '<Root><Item><Id>1</Id><Name>new</Name><Qty>7</Qty></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|new|7|9|true|Z|2024-01-01;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AutoUpdateNewRow()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73427, '<Root><Item><Id>5</Id><Name>new</Name><Qty>7</Qty></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '5|new|7|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AutoSaveFalse()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73428, '<Root><Item><Id>5</Id><Name>new</Name><Qty>7</Qty></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_BreakStopsAfterSecond()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73425, '<Root><Item><Id>1</Id><Name>a</Name><Qty>1</Qty></Item><Item><Id>2</Id><Name>b</Name><Qty>2</Qty></Item><Item><Id>3</Id><Name>c</Name><Qty>3</Qty></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|a|1|0|false||;2|b|2|0|false||;3|c|3|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_SkipDoesNotInsert()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73424, '<Root><Item><Id>1</Id><Name>a</Name><Qty>10</Qty></Item><Item><Id>2</Id><Name>b</Name><Qty>20</Qty></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|a|10|0|false||;2|b|20|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_Attributes()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73411, '<Root><Item Id="1" Name="A"><Qty>5</Qty></Item><Item Id="2" Name="B"><Qty>6</Qty></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|0|false||;2|B|6|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AttributesMissing()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73411, '<Root><Item Id="1"><Qty>5</Qty></Item></Root>'));
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The required attribute ''Name'' is missing.|XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AttributesAsElements()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73411, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty></Item></Root>'));
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The required attribute ''Id'' is missing.|XmlPortInvalidXml');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AttributeOrderSwapped()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73411, '<Root><Item Name="A" Id="1"><Qty>5</Qty></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AttributeSingleQuotes()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73411, '<Root><Item Id=''1'' Name=''A''><Qty>5</Qty></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_AttributeEscaped()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73411, '<Root><Item Id="1" Name="a&amp;b&quot;c"><Qty>5</Qty></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|a&b"c|5|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_LinkFieldsNested()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73412, '<Root><Item><Id>1</Id><Name>A</Name><Line><LineId>10</LineId><Descr>d1</Descr></Line><Line><LineId>11</LineId><Descr>d2</Descr></Line></Item><Item><Id>2</Id><Name>B</Name><Line><LineId>12</LineId><Descr>d3</Descr></Line></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Observe('lines', Helper.DumpLines());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|0|0|false||;2|B|0|0|false||;');
        Observer.Expect('lines', '10|1|d1|0;11|0|d2|0;12|2|d3|0;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_LinkFieldsNoChildren()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73412, '<Root><Item><Id>1</Id><Name>A</Name></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Observe('lines', Helper.DumpLines());
        Observer.Expect('import1', 'error:Imported XML cannot validate with the schema: The element ''Item'' has incomplete content. List of possible elements expected: ''Line''.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Expect('lines', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_LinkFieldsChildOutsideParent()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73412, '<Root><Line><LineId>10</LineId><Descr>d1</Descr></Line></Root>'));
        Observer.Observe('lines', Helper.DumpLines());
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Line''. List of possible elements expected: ''Item''.|XmlPortInvalidXml');
        Observer.Expect('lines', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_TextElementsAndAttributes()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73421, '<Doc Ver="v9"><Title>T &amp; U</Title></Doc>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '9999|T & U|v9|0|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_TextElementsMissingAttribute()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73421, '<Doc><Title>T</Title></Doc>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:Imported XML cannot validate with the schema: The required attribute ''Ver'' is missing.|XmlPortInvalidXml');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_TextElementEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73421, '<Doc Ver=""><Title/></Doc>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '9999|||0|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_FormatEvaluateXml_XmlValues()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73431, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_FormatEvaluateXml_LegacyValues()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73431, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1,5</Amount><Active>Yes</Active><Category>C</Category><StampDate>15.01.24</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('err', 'error:The value "1,5" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('items', '');
        Observer.Verify();
    end;

    [Test]
    procedure Import_FormatEvaluateLegacy_XmlValues()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73432, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>true</Active><Category>C</Category><StampDate>2024-01-15</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_FormatEvaluateLegacy_LegacyValues()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73432, '<Root><Item><Id>1</Id><Name>A</Name><Qty>5</Qty><Amount>1.5</Amount><Active>Yes</Active><Category>C</Category><StampDate>01/15/2024</StampDate></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|5|1.5|true|C|2024-01-15;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_OnlyDirectionImport()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73416, '<Root><Item><Id>1</Id><Name>A</Name></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|A|0|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Import_OnlyDirectionImportExportFails()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        asserterror Helper.ExportText(73416);
        Observer.ObserveError('err');
        Observer.Expect('err|text', 'The XMLPort ''LT XpT Import Only'' is designed for import only.');
        Observer.Expect('err|code', 'XmlPortImportDirection');
        Observer.Verify();
    end;

    [Test]
    procedure Export_OnlyDirectionExportImportFails()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('err', Helper.TryImport(73415, '<Root><Item><Id>1</Id><Name>A</Name></Item></Root>'));
        Observer.Expect('err', 'error:The XMLPort ''LT XpT Export Only'' is designed for export only.|XmlPortExportDirection');
        Observer.Verify();
    end;

    [Test]
    procedure Import_PreserveWhitespace()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('import1', Helper.TryImport(73435, '<Root><Item><Id>1</Id><Name>  a  b  </Name></Item></Root>'));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('import1', 'ok');
        Observer.Expect('items', '1|  a  b  |0|0|false||;');
        Observer.Verify();
    end;

    [Test]
    procedure Export_PreserveWhitespace()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, '  a  b  ', 1, 1, true, 'C', 0D);
        asserterror Observer.Observe('xml', Helper.ExportText(73435));
        Observer.ObserveError('af371');
        Observer.Expect('af371|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af371|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    // Writer SL (2026-10-25): port 73435 exports UTF-16 (the default Encoding); read the export of Export_PreserveWhitespace through a UTF-16 InStream.
    [Test]
    procedure Export_PreserveWhitespace_Utf16()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.AddItem(1, '  a  b  ', 1, 1, true, 'C', 0D);
        Helper.AddItem(2, 'x', 1, 1, true, 'C', 0D);
        Observer.Observe('xml', Helper.ExportTextEnc(73435, TextEncoding::UTF16));
        Observer.Observe('len', Format(Helper.LastLength()));
        Observer.Finish();
    end;
}
