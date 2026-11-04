// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlport/xmlport-export-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Triggered (60002), ALT Trigger Log (60003),
//                ALTFixtureCleanup (60019), shared Assert (60021); self-contained xmlports 68117..68119
// Probe: written against a real BC 27.5 service tier (en-US session, UTC); every literal below
// is what that tier produced. Other BC versions were not measured.
//
// Pins the bytes an XML XmlPort exports (UTF-16 with a byte order mark, an XML declaration,
// two-space indentation, `<X />` for an empty element), the text of every field type in an export,
// that Import runs the table's insert triggers and event subscribers, that a duplicate key in an
// import is reported when the transaction commits, and the text and code of the import errors.
// BC versions: 27.5

xmlport 68117 "Probe XP Both"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(U; "ALT Universal")
            {
                fieldattribute(Attr; U."Name Field") { }
                fieldelement(EntryNo; U."Entry No.") { }
                fieldelement(Txt; U."Text Field") { MinOccurs = Zero; }
                fieldelement(Dec; U."Decimal Field") { MinOccurs = Zero; }
                fieldelement(Bool; U."Boolean Field") { MinOccurs = Zero; }
                fieldelement(Dt; U."Date Field") { MinOccurs = Zero; }
                fieldelement(Opt; U."Option Field") { MinOccurs = Zero; }
                fieldelement(Tm; U."Time Field") { MinOccurs = Zero; }
                fieldelement(DtTm; U."DateTime Field") { MinOccurs = Zero; }
                fieldelement(Stat; U."Status Field") { MinOccurs = Zero; }
                fieldelement(Code_; U."Code Field") { MinOccurs = Zero; }
                fieldelement(Dur; U."Duration Field") { MinOccurs = Zero; }
            }
        }
    }
}

xmlport 68118 "Probe XP Export Only"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(U; "ALT Universal")
            {
                fieldelement(EntryNo; U."Entry No.") { }
            }
        }
    }
}

xmlport 68119 "Probe XP Import Only"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(U; "ALT Triggered")
            {
                fieldelement(EntryNo; U."Entry No.") { }
                fieldelement(Name; U.Name) { }
                fieldelement(Value; U.Value) { }
            }
        }
    }
}

codeunit 68120 "Probe XmlPort Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure ExportUniversal(var TempBlob: Codeunit "Temp Blob")
    var
        ALTUniversal: Record "ALT Universal";
        Export: XmlPort "Probe XP Both";
        OutStr: OutStream;
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal."Text Field" := '';
        ALTUniversal."Decimal Field" := 1234.5;
        ALTUniversal."Boolean Field" := true;
        ALTUniversal."Date Field" := DMY2Date(5, 3, 2024);
        ALTUniversal."Option Field" := ALTUniversal."Option Field"::Active;
        ALTUniversal."Time Field" := 143005T;
        ALTUniversal."DateTime Field" := CreateDateTime(DMY2Date(5, 3, 2024), 143005T);
        ALTUniversal."Code Field" := 'abc';
        ALTUniversal."Duration Field" := 90061001;
        ALTUniversal."Name Field" := 'a"b&<c>';
        ALTUniversal.Insert();

        ALTUniversal.Init();
        ALTUniversal."Entry No." := 2;
        ALTUniversal."Text Field" := 'x & <y>';
        ALTUniversal."Decimal Field" := -0.5;
        ALTUniversal.Insert();

        TempBlob.CreateOutStream(OutStr);
        Export.SetDestination(OutStr);
        Export.SetTableView(ALTUniversal);
        Export.Export();
    end;

    local procedure ExportedBase64(var TempBlob: Codeunit "Temp Blob"): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        exit(Base64Convert.ToBase64(InStr));
    end;

    local procedure ExportedText(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Line: Text;
        Result: Text;
        Lf: Text[1];
        First: Boolean;
    begin
        Lf[1] := 10;
        First := true;
        TempBlob.CreateInStream(InStr, TextEncoding::UTF16);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if not First then
                Result += Lf;
            Result += Line;
            First := false;
        end;
        exit(Result);
    end;

    [Test]
    procedure XmlPortExport_Bytes_AreUtf16WithByteOrderMarkAndDeclaration()
    // CLAIM: the stream starts with FF FE (UTF-16 LE byte order mark) followed by the declaration with encoding UTF-16 and standalone="no".
    var
        TempBlob: Codeunit "Temp Blob";
        Base64: Text;
    begin
        Initialize();

        ExportUniversal(TempBlob);

        Base64 := ExportedBase64(TempBlob);
        // //48AD8A = FF FE 3C 00 3F 00 = BOM, '<', '?' in UTF-16 LE.
        Assert.IsTrue(Base64.StartsWith('//48AD8AeABtAGwA'), 'BOM then "<?xml" in UTF-16 LE: ' + CopyStr(Base64, 1, 40));
    end;

    [Test]
    procedure XmlPortExport_Document_FullText()
    // CLAIM: declaration, LF line ends, two-space indentation, attribute escaping, `<X />` for an empty element, and the display text of each field type.
    var
        TempBlob: Codeunit "Temp Blob";
        Expected: Text;
        Lf: Text[1];
    begin
        Initialize();
        Lf[1] := 10;

        ExportUniversal(TempBlob);

        Expected := '<?xml version="1.0" encoding="UTF-16" standalone="no"?>' + Lf +
            '<Root>' + Lf +
            '  <U Attr="a&quot;b&amp;&lt;c&gt;">' + Lf +
            '    <EntryNo>1</EntryNo>' + Lf +
            '    <Txt />' + Lf +
            '    <Dec>1,234.50</Dec>' + Lf +
            '    <Bool>Yes</Bool>' + Lf +
            '    <Dt>03/05/24</Dt>' + Lf +
            '    <Opt>Active</Opt>' + Lf +
            '    <Tm> 2:30:05 PM</Tm>' + Lf +
            '    <DtTm>03/05/24 02:30 PM</DtTm>' + Lf +
            '    <Stat> </Stat>' + Lf +
            '    <Code_>ABC</Code_>' + Lf +
            '    <Dur>1 day 1 hour 1 minute 1 second 1 millisecond</Dur>' + Lf +
            '  </U>' + Lf +
            '  <U Attr="">' + Lf +
            '    <EntryNo>2</EntryNo>' + Lf +
            '    <Txt>x &amp; &lt;y&gt;</Txt>' + Lf +
            '    <Dec>-0.50</Dec>' + Lf +
            '    <Bool>No</Bool>' + Lf +
            '    <Dt />' + Lf +
            '    <Opt> </Opt>' + Lf +
            '    <Tm />' + Lf +
            '    <DtTm />' + Lf +
            '    <Stat> </Stat>' + Lf +
            '    <Code_ />' + Lf +
            '    <Dur />' + Lf +
            '  </U>' + Lf +
            '</Root>';
        Assert.AreEqual(Expected, ExportedText(TempBlob), 'full exported document');
    end;

    local procedure Feed(Xml: Text; var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Xml);
    end;

    local procedure ImportTriggered(Xml: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Import: XmlPort "Probe XP Import Only";
        InStr: InStream;
    begin
        Feed(Xml, TempBlob);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        Import.SetSource(InStr);
        Import.Import();
    end;

    local procedure ImportError(Xml: Text): Text
    begin
        ClearLastError();
        asserterror ImportTriggered(Xml);
        exit(GetLastErrorText());
    end;

    [Test]
    procedure XmlPortImport_RunsTheTableInsertTriggersAndEvents()
    // CLAIM: Import calls the table's insert triggers and the insert event subscribers for each row, in the order a plain Insert(true) does.
    var
        ALTTriggered: Record "ALT Triggered";
        ALTTriggerLog: Record "ALT Trigger Log";
        Calls: Text;
    begin
        Initialize();

        ImportTriggered('<Root><U><EntryNo>1</EntryNo><Name>n1</Name><Value>7</Value></U></Root>');

        Assert.AreEqual(1, ALTTriggered.Count(), 'one row imported');
        ALTTriggerLog.FindSet();
        repeat
            Calls += ALTTriggerLog.TriggerName + '/' + Format(ALTTriggerLog.SourceEntryNo) + ' ';
        until ALTTriggerLog.Next() = 0;
        Assert.AreEqual('TABLEONBEFOREINSERT/1 TABLEEXTONBEFOREINSERT/1 ONINSERT/1 TABLEEXTONINSERT/1 ONDATABASEINSERT/1 TABLEEXTONAFTERINSERT/1 TABLEONAFTERINSERT/1 ', Calls, 'trigger and event sequence');
    end;

    [Test]
    procedure XmlPortImport_DuplicateKey_IsReportedWhenTheTransactionCommits()
    // CLAIM: Import returns without error for a key that already exists; the failure comes out of the next Commit.
    var
        ALTTriggered: Record "ALT Triggered";
    begin
        Initialize();
        ALTTriggered.Init();
        ALTTriggered."Entry No." := 1;
        ALTTriggered.Insert();

        ImportTriggered('<Root><U><EntryNo>1</EntryNo><Name>again</Name><Value>8</Value></U></Root>');

        asserterror Commit();
        Assert.AreEqual('The record in table ALT Triggered already exists. Identification fields and values: Entry No.=''1''', GetLastErrorText(), 'text');
        Assert.AreEqual('DB:RecordExists', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure XmlPortImport_BadInteger_ThrowsEvaluate()
    begin
        Initialize();

        Assert.AreEqual('The value "abc" can''t be evaluated into type Integer.', ImportError('<Root><U><EntryNo>abc</EntryNo><Name>n</Name><Value>1</Value></U></Root>'), 'text');
        Assert.AreEqual('Evaluate', GetLastErrorCode(), 'code');
        Assert.AreEqual('The value "1.5" can''t be evaluated into type Integer.', ImportError('<Root><U><EntryNo>5</EntryNo><Name>n</Name><Value>1.5</Value></U></Root>'), 'text of a decimal in an integer element');
    end;

    [Test]
    procedure XmlPortImport_MalformedXml_Throws()
    begin
        Initialize();

        Assert.AreEqual('Unexpected end of file has occurred. The following elements are not closed: U, Root. Line 1, position 44.',
            ImportError('<Root><U><EntryNo>5</EntryNo><Name>n</Name>'), 'truncated document');
        Assert.AreEqual('XmlPortImport:Xml', GetLastErrorCode(), 'code of a truncated document');
        Assert.AreEqual('Data at the root level is invalid. Line 1, position 1.', ImportError('not xml at all'), 'not XML');
        Assert.AreEqual('XmlPortImport:Xml', GetLastErrorCode(), 'code of text that is not XML');
        Assert.AreEqual('Cannot import the specified XML document because the file is empty.', ImportError(''), 'empty stream');
        Assert.AreEqual('XmlPortData', GetLastErrorCode(), 'code of an empty stream');
    end;

    [Test]
    procedure XmlPortImport_SchemaMismatch_ThrowsXmlPortInvalidXml()
    begin
        Initialize();

        Assert.AreEqual('Imported XML cannot validate with the schema: The ''Other'' element is not declared.',
            ImportError('<Other><U><EntryNo>5</EntryNo></U></Other>'), 'wrong root');
        Assert.AreEqual('XmlPortInvalidXml', GetLastErrorCode(), 'code of a wrong root');
        Assert.AreEqual('Imported XML cannot validate with the schema: The element ''U'' has invalid child element ''Extra''.',
            ImportError('<Root><U><EntryNo>5</EntryNo><Name>n</Name><Value>1</Value><Extra>1</Extra></U></Root>'), 'extra element');
        Assert.AreEqual('Imported XML cannot validate with the schema: The element ''U'' has incomplete content. List of possible elements expected: ''Value''.',
            ImportError('<Root><U><EntryNo>5</EntryNo><Name>n</Name></U></Root>'), 'missing element');
    end;

    [Test]
    procedure XmlPortImport_ValueTooLongForField_Throws()
    begin
        Initialize();

        Assert.AreEqual('The length of the string is 51, but it must be less than or equal to 50 characters. Value: 01234567890123456789012345678901234567890123456789X',
            ImportError('<Root><U><EntryNo>6</EntryNo><Name>01234567890123456789012345678901234567890123456789X</Name><Value>1</Value></U></Root>'), 'text');
        Assert.AreEqual('StringLengthExceeded', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure XmlPortImport_EmptyIntegerElement_ImportsZero()
    var
        ALTTriggered: Record "ALT Triggered";
    begin
        Initialize();

        ImportTriggered('<Root><U><EntryNo>5</EntryNo><Name>n</Name><Value></Value></U></Root>');
        Commit();

        ALTTriggered.Get(5);
        Assert.AreEqual(0, ALTTriggered.Value, 'an empty element is 0');
    end;

    [Test]
    procedure XmlPort_WrongDirection_Throws()
    var
        ExportOnly: XmlPort "Probe XP Export Only";
        ImportOnly: XmlPort "Probe XP Import Only";
    begin
        Initialize();

        ClearLastError();
        asserterror ImportOnly.Export();
        Assert.AreEqual('The XMLPort ''Probe XP Import Only'' is designed for import only.', GetLastErrorText(), 'Export of an import-only xmlport');
        Assert.AreEqual('XmlPortImportDirection', GetLastErrorCode(), 'code');

        ClearLastError();
        asserterror ExportOnly.Import();
        Assert.AreEqual('The XMLPort ''Probe XP Export Only'' is designed for export only.', GetLastErrorText(), 'Import of an export-only xmlport');
        Assert.AreEqual('XmlPortExportDirection', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure XmlPortImport_AcceptsTheTextItExports()
    // CLAIM: the display text of each type that Export writes (Yes, 03/05/24, 1,234.50, ...) is read back by Import.
    var
        ALTUniversal: Record "ALT Universal";
        TempBlob: Codeunit "Temp Blob";
        Import: XmlPort "Probe XP Both";
        InStr: InStream;
    begin
        Initialize();
        Feed('<Root><U Attr="z"><EntryNo>1</EntryNo><Txt>t</Txt><Dec>1,234.50</Dec><Bool>Yes</Bool><Dt>03/05/24</Dt><Opt>Active</Opt><Tm> 2:30:05 PM</Tm><DtTm>03/05/24 02:30 PM</DtTm><Stat> </Stat><Code_>ABC</Code_><Dur>1 day</Dur></U></Root>', TempBlob);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        Import.SetSource(InStr);

        Import.Import();
        Commit();

        ALTUniversal.Get(1);
        Assert.AreEqual('1234.5', Format(ALTUniversal."Decimal Field", 0, 9), 'Decimal');
        Assert.IsTrue(ALTUniversal."Boolean Field", 'Boolean');
        Assert.AreEqual('2024-03-05', Format(ALTUniversal."Date Field", 0, 9), 'Date');
        Assert.AreEqual('Active', Format(ALTUniversal."Option Field"), 'Option');
        Assert.AreEqual('14:30:05', Format(ALTUniversal."Time Field", 0, 9), 'Time');
        Assert.AreEqual('2024-03-05T14:30:00Z', Format(ALTUniversal."DateTime Field", 0, 9), 'DateTime');
        Assert.AreEqual('ABC', ALTUniversal."Code Field", 'Code');
        Assert.AreEqual('z', ALTUniversal."Name Field", 'the attribute');
    end;
}
