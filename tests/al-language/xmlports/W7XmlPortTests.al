// Batch 7 probes: xmlport container text element triggers, MinOccurs / MaxOccurs on import, a refused guarded import, declared Encoding, Xmlport.Run. Observe only.
codeunit 68622 "W7 XP Run Import"
{
    trigger OnRun()
    begin
        Xmlport.Run(Xmlport::"W7 XP Occ Rows", false, true);
    end;
}

codeunit 68520 "W7 XmlPort Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure XmlSource(Content: Text; var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
    end;

    [Test]
    procedure ContainerTextElement_Export_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        Util: Codeunit "W7 Stream Util";
        TempBlob: Codeunit "Temp Blob";
        XP: XmlPort "W7 XP Container";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        XP.SetDestination(OutS);
        XP.Export();
        Observer.Observe('log', XP.GetLog());
        Observer.Observe('xml', Util.Lines(TempBlob, TextEncoding::UTF16));
        Observer.Expect('log', 'Pre;Cont.BeforePass;Leaf.BeforePass;Post;');
        Observer.Expect('xml', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>|<Root>|  <Cont>|    <Leaf>leafvalue</Leaf>|  </Cont>|</Root>|');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryImportContainer(Content: Text; var XP: XmlPort "W7 XP Container")
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        XmlSource(Content, TempBlob, InS);
        XP.SetSource(InS);
        XP.Import();
    end;

    [Test]
    procedure ContainerTextElement_Import_TriggerOrder()
    var
        Observer: Codeunit "Probe Observer";
        XP: XmlPort "W7 XP Container";
        XP2: XmlPort "W7 XP Container";
        XP3: XmlPort "W7 XP Container";
    begin
        Observer.Observe('child only ok', Format(TryImportContainer('<Root><Cont><Leaf>abc</Leaf></Cont></Root>', XP)));
        Observer.ObserveError('child only');
        Observer.Observe('child only log', XP.GetLog());
        Observer.Observe('text in the container ok', Format(TryImportContainer('<Root><Cont>direct<Leaf>abc</Leaf></Cont></Root>', XP2)));
        Observer.ObserveError('text in the container');
        Observer.Observe('text in the container log', XP2.GetLog());
        Observer.Observe('empty container ok', Format(TryImportContainer('<Root><Cont/></Root>', XP3)));
        Observer.ObserveError('empty container');
        Observer.Observe('empty container log', XP3.GetLog());
        Observer.Expect('child only ok', 'Yes');
        Observer.Expect('child only|text', '');
        Observer.Expect('child only|code', '');
        Observer.Expect('child only log', 'Pre;Leaf.AfterAssign=abc;Cont.AfterAssign=;Post;');
        Observer.Expect('text in the container ok', 'Yes');
        Observer.Expect('text in the container|text', '');
        Observer.Expect('text in the container|code', '');
        Observer.Expect('text in the container log', 'Pre;Leaf.AfterAssign=abc;Cont.AfterAssign=direct;Post;');
        Observer.Expect('empty container ok', 'No');
        Observer.Expect('empty container|text', 'Imported XML cannot validate with the schema: The element ''Cont'' has incomplete content. List of possible elements expected: ''Leaf''.');
        Observer.Expect('empty container|code', 'XmlPortInvalidXml');
        Observer.Expect('empty container log', 'Pre;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryImportOccurrence(Content: Text; var XP: XmlPort "W7 XP Occurrence")
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        XmlSource(Content, TempBlob, InS);
        XP.SetSource(InS);
        XP.Import();
    end;

    local procedure ObserveOccurrence(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Text)
    var
        XP: XmlPort "W7 XP Occurrence";
    begin
        Observer.Observe(Name + ' ok', Format(TryImportOccurrence(Content, XP)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', XP.GetLog());
    end;

    [Test]
    procedure Occurrence_TextElements_MissingAndOptional()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveOccurrence(Observer, 'all present', '<Root><Req>r</Req><Opt>o</Opt><Once>1</Once><Many>a</Many><Many>b</Many></Root>');
        ObserveOccurrence(Observer, 'only required', '<Root><Req>r</Req><Once>1</Once></Root>');
        ObserveOccurrence(Observer, 'required missing', '<Root><Opt>o</Opt><Once>1</Once></Root>');
        ObserveOccurrence(Observer, 'once-element missing', '<Root><Req>r</Req><Opt>o</Opt></Root>');
        ObserveOccurrence(Observer, 'empty root', '<Root/>');
        Observer.Expect('all present ok', 'Yes');
        Observer.Expect('all present|text', '');
        Observer.Expect('all present|code', '');
        Observer.Expect('all present log', 'Req=r;Opt=o;Once=1;Many=a;Many=b;Post;');
        Observer.Expect('only required ok', 'Yes');
        Observer.Expect('only required|text', '');
        Observer.Expect('only required|code', '');
        Observer.Expect('only required log', 'Req=r;Once=1;Post;');
        Observer.Expect('required missing ok', 'No');
        Observer.Expect('required missing|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Opt''. List of possible elements expected: ''Req''.');
        Observer.Expect('required missing|code', 'XmlPortInvalidXml');
        Observer.Expect('required missing log', '');
        Observer.Expect('once-element missing ok', 'No');
        Observer.Expect('once-element missing|text', 'Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Opt, Once''.');
        Observer.Expect('once-element missing|code', 'XmlPortInvalidXml');
        Observer.Expect('once-element missing log', 'Req=r;Opt=o;');
        Observer.Expect('empty root ok', 'No');
        Observer.Expect('empty root|text', 'Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''Req''.');
        Observer.Expect('empty root|code', 'XmlPortInvalidXml');
        Observer.Expect('empty root log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Occurrence_TextElements_RepeatedAndMisplaced()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveOccurrence(Observer, 'once-element twice', '<Root><Req>r</Req><Once>1</Once><Once>2</Once></Root>');
        ObserveOccurrence(Observer, 'required twice', '<Root><Req>r</Req><Req>s</Req><Once>1</Once></Root>');
        ObserveOccurrence(Observer, 'unbounded three times', '<Root><Req>r</Req><Once>1</Once><Many>a</Many><Many>b</Many><Many>c</Many></Root>');
        ObserveOccurrence(Observer, 'order swapped', '<Root><Opt>o</Opt><Req>r</Req><Once>1</Once></Root>');
        ObserveOccurrence(Observer, 'unknown element', '<Root><Req>r</Req><Once>1</Once><Extra>x</Extra></Root>');
        ObserveOccurrence(Observer, 'unknown element first', '<Root><Extra>x</Extra><Req>r</Req><Once>1</Once></Root>');
        Observer.Expect('once-element twice ok', 'No');
        Observer.Expect('once-element twice|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Once''. List of possible elements expected: ''Many''.');
        Observer.Expect('once-element twice|code', 'XmlPortInvalidXml');
        Observer.Expect('once-element twice log', 'Req=r;Once=1;');
        Observer.Expect('required twice ok', 'Yes');
        Observer.Expect('required twice|text', '');
        Observer.Expect('required twice|code', '');
        Observer.Expect('required twice log', 'Req=r;Req=s;Once=1;Post;');
        Observer.Expect('unbounded three times ok', 'Yes');
        Observer.Expect('unbounded three times|text', '');
        Observer.Expect('unbounded three times|code', '');
        Observer.Expect('unbounded three times log', 'Req=r;Once=1;Many=a;Many=b;Many=c;Post;');
        Observer.Expect('order swapped ok', 'No');
        Observer.Expect('order swapped|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Opt''. List of possible elements expected: ''Req''.');
        Observer.Expect('order swapped|code', 'XmlPortInvalidXml');
        Observer.Expect('order swapped log', '');
        Observer.Expect('unknown element ok', 'No');
        Observer.Expect('unknown element|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Extra''. List of possible elements expected: ''Many''.');
        Observer.Expect('unknown element|code', 'XmlPortInvalidXml');
        Observer.Expect('unknown element log', 'Req=r;Once=1;');
        Observer.Expect('unknown element first ok', 'No');
        Observer.Expect('unknown element first|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''Extra''. List of possible elements expected: ''Req''.');
        Observer.Expect('unknown element first|code', 'XmlPortInvalidXml');
        Observer.Expect('unknown element first log', '');
        Observer.Verify();
    end;

    local procedure RowCount(): Integer
    var
        Row: Record "W7 XP Row";
    begin
        exit(Row.Count());
    end;

    local procedure ImportRows(Id: Integer; Content: Text; var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Row: Record "W7 XP Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Imported: Boolean;
    begin
        Row.DeleteAll();
        Commit();
        XmlSource(Content, TempBlob, InS);
        ClearLastError();
        Imported := Xmlport.Import(Id, InS);
        Observer.Observe(Name + ' imported', Format(Imported));
        Observer.ObserveError(Name);
        Commit();
        Observer.Observe(Name + ' rows', Format(RowCount()));
    end;

    [Test]
    procedure Occurrence_TableElement_ZeroOnceAndTwoRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportRows(Xmlport::"W7 XP Occ Rows", '<Root/>', Observer, 'optional, no row');
        ImportRows(Xmlport::"W7 XP Occ Rows", '<Root><T><Id>1</Id><Txt>a</Txt></T></Root>', Observer, 'optional, one row');
        ImportRows(Xmlport::"W7 XP Occ Rows", '<Root><T><Id>1</Id><Txt>a</Txt></T><T><Id>2</Id><Txt>b</Txt></T></Root>', Observer, 'optional, two rows');
        ImportRows(Xmlport::"W7 XP Rows", '<Root/>', Observer, 'default, no row');
        ImportRows(Xmlport::"W7 XP Rows", '<Root><T><Id>1</Id><Txt>a</Txt></T><T><Id>2</Id><Txt>b</Txt></T></Root>', Observer, 'default, two rows');
        Observer.Expect('optional, no row imported', 'Yes');
        Observer.Expect('optional, no row|text', '');
        Observer.Expect('optional, no row|code', '');
        Observer.Expect('optional, no row rows', '0');
        Observer.Expect('optional, one row imported', 'Yes');
        Observer.Expect('optional, one row|text', '');
        Observer.Expect('optional, one row|code', '');
        Observer.Expect('optional, one row rows', '1');
        Observer.Expect('optional, two rows imported', 'No');
        Observer.Expect('optional, two rows|text', 'Imported XML cannot validate with the schema: The element ''Root'' has invalid child element ''T''.');
        Observer.Expect('optional, two rows|code', 'XmlPortInvalidXml');
        Observer.Expect('optional, two rows rows', '0');
        Observer.Expect('default, no row imported', 'No');
        Observer.Expect('default, no row|text', 'Imported XML cannot validate with the schema: The element ''Root'' has incomplete content. List of possible elements expected: ''T''.');
        Observer.Expect('default, no row|code', 'XmlPortInvalidXml');
        Observer.Expect('default, no row rows', '0');
        Observer.Expect('default, two rows imported', 'Yes');
        Observer.Expect('default, two rows|text', '');
        Observer.Expect('default, two rows|code', '');
        Observer.Expect('default, two rows rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedStaticImport_RefusedBecauseAWriteIsPending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 XP Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Imported: Boolean;
    begin
        Row.DeleteAll();
        Commit();
        Row.Id := 100;
        Row.Insert();
        XmlSource('<Root><T><Id>1</Id><Txt>a</Txt></T></Root>', TempBlob, InS);
        ClearLastError();
        Imported := Xmlport.Import(Xmlport::"W7 XP Rows", InS);
        Observer.Observe('imported', Format(Imported));
        Observer.ObserveError('refused import');
        Observer.Observe('rows while the write is pending', Format(RowCount()));
        Observer.Observe('pending row still there', Format(Row.Get(100)));

        Commit();
        Clear(TempBlob);
        XmlSource('<Root><T><Id>1</Id><Txt>a</Txt></T></Root>', TempBlob, InS);
        Imported := Xmlport.Import(Xmlport::"W7 XP Rows", InS);
        Observer.Observe('imported after commit', Format(Imported));
        Observer.ObserveError('import after commit');
        Commit();
        Observer.Observe('rows after the second import', Format(RowCount()));
        Observer.Expect('imported', 'No');
        Observer.Expect('refused import|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('refused import|code', 'DB:Ok');
        Observer.Expect('rows while the write is pending', '1');
        Observer.Expect('pending row still there', 'Yes');
        Observer.Expect('imported after commit', 'Yes');
        Observer.Expect('import after commit|text', '');
        Observer.Expect('import after commit|code', '');
        Observer.Expect('rows after the second import', '2');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedStaticImport_BadDocumentWhileAWriteIsPending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 XP Row";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Imported: Boolean;
    begin
        Row.DeleteAll();
        Commit();
        Row.Id := 100;
        Row.Insert();
        XmlSource('<Root><Unknown/></Root>', TempBlob, InS);
        ClearLastError();
        Imported := Xmlport.Import(Xmlport::"W7 XP Rows", InS);
        Observer.Observe('imported', Format(Imported));
        Observer.ObserveError('refused import of a bad document');
        Observer.Expect('imported', 'No');
        Observer.Expect('refused import of a bad document|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('refused import of a bad document|code', 'DB:Ok');
        Observer.Verify();
    end;

    local procedure MetaEncoding(Id: Integer): Text
    var
        Meta: Record "XmlPort Metadata";
    begin
        if not Meta.Get(Id) then
            exit('no row');
        exit(Format(Meta.Encoding) + ' (' + Format(Meta.Encoding, 0, 9) + ') format=' + Format(Meta.Format));
    end;

    [Test]
    procedure XmlPortMetadata_DeclaredEncoding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('xml, Encoding = UTF8', MetaEncoding(Xmlport::"W7 XP Enc Utf8"));
        Observer.Observe('xml, Encoding = UTF16', MetaEncoding(Xmlport::"W7 XP Enc Utf16"));
        Observer.Observe('variable text, TextEncoding = MSDOS', MetaEncoding(Xmlport::"W7 XP Enc Vt Msdos"));
        Observer.Observe('variable text, TextEncoding = Windows', MetaEncoding(Xmlport::"W7 XP Enc Vt Windows"));
        Observer.Observe('variable text, TextEncoding = UTF8', MetaEncoding(Xmlport::"W7 XP Enc Vt Utf8"));
        Observer.Observe('variable text, TextEncoding = UTF16', MetaEncoding(Xmlport::"W7 XP Enc Vt Utf16"));
        Observer.Observe('variable text, none declared', MetaEncoding(Xmlport::"W7 XP Enc Vt None"));
        Observer.Observe('xml, none declared', MetaEncoding(Xmlport::"W7 XP Rows"));
        Observer.Expect('xml, Encoding = UTF8', 'UTF8 (0) format=Xml');
        Observer.Expect('xml, Encoding = UTF16', 'UTF16 (1) format=Xml');
        Observer.Expect('variable text, TextEncoding = MSDOS', 'UTF16 (1) format=VariableText');
        Observer.Expect('variable text, TextEncoding = Windows', 'UTF16 (1) format=VariableText');
        Observer.Expect('variable text, TextEncoding = UTF8', 'UTF16 (1) format=VariableText');
        Observer.Expect('variable text, TextEncoding = UTF16', 'UTF16 (1) format=VariableText');
        Observer.Expect('variable text, none declared', 'UTF16 (1) format=VariableText');
        Observer.Expect('xml, none declared', 'UTF16 (1) format=Xml');
        Observer.Verify();
    end;

    local procedure ExportHead(Id: Integer): Text
    var
        Util: Codeunit "W7 Stream Util";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(Id, OutS);
        exit(CopyStr(Util.Hex(TempBlob), 1, 150));
    end;

    [Test]
    procedure XmlPortExport_BytesPerDeclaredEncoding()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W7 XP Row";
        Accent: Text[1];
    begin
        Accent[1] := 233;
        Row.DeleteAll();
        Row.Id := 1;
        Row.Txt := 'x' + Accent;
        Row.Insert();
        Observer.Observe('xml, Encoding = UTF8', ExportHead(Xmlport::"W7 XP Enc Utf8"));
        Observer.Observe('xml, Encoding = UTF16', ExportHead(Xmlport::"W7 XP Enc Utf16"));
        Observer.Observe('variable text, MSDOS', ExportHead(Xmlport::"W7 XP Enc Vt Msdos"));
        Observer.Observe('variable text, Windows', ExportHead(Xmlport::"W7 XP Enc Vt Windows"));
        Observer.Observe('variable text, UTF8', ExportHead(Xmlport::"W7 XP Enc Vt Utf8"));
        Observer.Observe('variable text, UTF16', ExportHead(Xmlport::"W7 XP Enc Vt Utf16"));
        Observer.Observe('variable text, none declared', ExportHead(Xmlport::"W7 XP Enc Vt None"));
        Observer.Expect('xml, Encoding = UTF8', '3C 3F 78 6D 6C 20 76 65 72 73 69 6F 6E 3D 22 31 2E 30 22 20 65 6E 63 6F 64 69 6E 67 3D 22 55 54 46 2D 38 22 20 73 74 61 6E 64 61 6C 6F 6E 65 3D 22 6E ');
        Observer.Expect('xml, Encoding = UTF16', 'FF FE 3C 00 3F 00 78 00 6D 00 6C 00 20 00 76 00 65 00 72 00 73 00 69 00 6F 00 6E 00 3D 00 22 00 31 00 2E 00 30 00 22 00 20 00 65 00 6E 00 63 00 6F 00 ');
        Observer.Expect('variable text, MSDOS', '22 31 22 2C 22 78 82 22');
        Observer.Expect('variable text, Windows', '22 31 22 2C 22 78 E9 22');
        Observer.Expect('variable text, UTF8', 'EF BB BF 22 31 22 2C 22 78 C3 A9 22');
        Observer.Expect('variable text, UTF16', 'FF FE 22 00 31 00 22 00 2C 00 22 00 78 00 E9 00 22 00');
        Observer.Expect('variable text, none declared', '22 31 22 2C 22 78 82 22');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRunExport()
    begin
        Xmlport.Run(Xmlport::"W7 XP Export", false, false);
    end;

    [TryFunction]
    local procedure TryRunExportWithRecord(var Row: Record "W7 XP Row")
    begin
        Xmlport.Run(Xmlport::"W7 XP Export", false, false, Row);
    end;

    [Test]
    procedure XmlportRun_ImportWithoutASource()
    var
        Observer: Codeunit "Probe Observer";
        RunOk: Boolean;
    begin
        Commit();
        RunOk := Codeunit.Run(Codeunit::"W7 XP Run Import");
        // Windows: ok=No, NotSupportedFileDialogProvider (batch XP); fixed on Linux by bc-linux #141
        Observer.Observe('run import ok', Format(RunOk));
        Observer.ObserveError('run import');
        Observer.Expect('run import ok', 'No');
        Observer.Expect('run import|text', 'The operation cannot complete because it uses a feature that is not supported (AL File function.)');
        Observer.Expect('run import|code', 'NotSupportedFileDialogProvider:NotSupportedFileDialogProvider');
        Observer.Verify();
    end;
}
