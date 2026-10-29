// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-writeto-method
// Scope: in-scope
// Fixtures used: codeunit 69160 "Probe Observer", codeunit 85909 "LT DE Helper", System Application codeunit "Temp Blob"; self-contained codeunits 85906, 85907, 85908
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Writer TV (2026-10-29, TV_* tests in codeunit 85907): WriteTo(OutStream) bytes of documents built in code with and without a declaration, and
//   an XmlWriteOptions passed as content to XmlDocument.Add and XmlElement.Add.
// Leads (corpus issue 671):
//  - "XmlDocument.ReadFrom(InStream) fails with '0x00 is an invalid character'" (microsoft/AL#5235): XML text written with Write(Text)
//    (which adds a zero byte) or WriteText, then read back with XmlDocument.ReadFrom(InStream).
//  - "XML declaration encoding name casing" (microsoft/AL#2759) and "XmlDocument with ISO-8859-1 declaration written to an OutStream"
//    (microsoft/AL#660): what WriteTo(Text) and WriteTo(OutStream) write for a declaration created with ISO-8859-1, iso-8859-1, UTF-8 and
//    Windows-1252, and the bytes of an a-umlaut on OutStreams created with TextEncoding::Windows and MSDos.
//  - "XmlAttribute.Create('xmlns', uri) namespace declaration" (microsoft/AL#1900): adding such an attribute to an element and writing it.

codeunit 85906 "LT DE Xml ReadFrom ZeroByte"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Xml(): Text
    begin
        exit('<?xml version="1.0" encoding="UTF-8"?><Envelope><Header><Id>12345</Id></Header><Body><Item No="1">First</Item><Item No="2">Second</Item></Body></Envelope>');
    end;

    [TryFunction]
    local procedure TryRead(var TempBlob: Codeunit "Temp Blob"; var RootName: Text)
    var
        InS: InStream;
        Doc: XmlDocument;
        Root: XmlElement;
    begin
        TempBlob.CreateInStream(InS);
        XmlDocument.ReadFrom(InS, Doc);
        Doc.GetRoot(Root);
        RootName := Root.Name();
    end;

    local procedure ObserveRead(var Observer: Codeunit "Probe Observer"; Name: Text; var TempBlob: Codeunit "Temp Blob")
    var
        RootName: Text;
    begin
        Observer.Observe(Name + ' length', Format(TempBlob.Length()));
        ClearLastError();
        if TryRead(TempBlob, RootName) then
            Observer.Observe(Name + ' readfrom', 'ok ' + RootName)
        else
            Observer.Observe(Name + ' readfrom', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure ReadFromInStream_AfterWriteAndWriteText()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Xml());
        ObserveRead(Observer, 'writetext', TempBlob);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        OutS.Write(Xml());
        ObserveRead(Observer, 'write', TempBlob);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.Write(Xml());
        ObserveRead(Observer, 'write utf8', TempBlob);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        OutS.Write('<Envelope><Id>1</Id></Envelope>');
        ObserveRead(Observer, 'write no declaration', TempBlob);
        Observer.Expect('writetext length', '154');
        Observer.Expect('writetext readfrom', 'ok Envelope');
        Observer.Expect('write length', '155');
        Observer.Expect('write readfrom', 'error The following exception was encountered when processing XML data: ''''.'', hexadecimal value 0x00, is an invalid character. Line 1, position 155.'' at line 1 and position 155.|Xml:Xml');
        Observer.Expect('write utf8 length', '155');
        Observer.Expect('write utf8 readfrom', 'error The following exception was encountered when processing XML data: ''''.'', hexadecimal value 0x00, is an invalid character. Line 1, position 155.'' at line 1 and position 155.|Xml:Xml');
        Observer.Expect('write no declaration length', '32');
        Observer.Expect('write no declaration readfrom', 'error The following exception was encountered when processing XML data: ''''.'', hexadecimal value 0x00, is an invalid character. Line 1, position 32.'' at line 1 and position 32.|Xml:Xml');
        Observer.Verify();
    end;
}

codeunit 85907 "LT DE Xml Declaration Encoding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Build(Encoding: Text; Standalone: Text; var Doc: XmlDocument)
    var
        Helper: Codeunit "LT DE Helper";
        Root: XmlElement;
    begin
        Doc := XmlDocument.Create();
        Doc.SetDeclaration(XmlDeclaration.Create('1.0', Encoding, Standalone));
        Root := XmlElement.Create('a');
        Root.Add(XmlText.Create(Helper.Umlaut()));
        Doc.Add(Root);
    end;

    local procedure ObserveText(var Observer: Codeunit "Probe Observer"; Encoding: Text)
    var
        Doc: XmlDocument;
        T: Text;
    begin
        Build(Encoding, '', Doc);
        Doc.WriteTo(T);
        Observer.Observe(Encoding + ' text', T);
    end;

    local procedure ObserveStream(var Observer: Codeunit "Probe Observer"; Name: Text; Encoding: Text; Standalone: Text; StreamEncoding: TextEncoding)
    var
        Helper: Codeunit "LT DE Helper";
        TempBlob: Codeunit "Temp Blob";
        Doc: XmlDocument;
        OutS: OutStream;
    begin
        Build(Encoding, Standalone, Doc);
        TempBlob.CreateOutStream(OutS, StreamEncoding);
        Doc.WriteTo(OutS);
        Observer.Observe(Name + ' bytes', Helper.HexOf(TempBlob));
    end;

    [Test]
    procedure WriteToText_EncodingNameCasing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveText(Observer, 'ISO-8859-1');
        ObserveText(Observer, 'iso-8859-1');
        ObserveText(Observer, 'UTF-8');
        ObserveText(Observer, 'Windows-1252');
        Observer.Expect('ISO-8859-1 text', '<?xml version="1.0" encoding="ISO-8859-1" standalone=""?>\r\n<a>ä</a>');
        Observer.Expect('iso-8859-1 text', '<?xml version="1.0" encoding="iso-8859-1" standalone=""?>\r\n<a>ä</a>');
        Observer.Expect('UTF-8 text', '<?xml version="1.0" encoding="UTF-8" standalone=""?>\r\n<a>ä</a>');
        Observer.Expect('Windows-1252 text', '<?xml version="1.0" encoding="Windows-1252" standalone=""?>\r\n<a>ä</a>');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToOutStream_EncodingNameCasing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStream(Observer, 'ISO-8859-1 utf8 stream', 'ISO-8859-1', '', TextEncoding::UTF8);
        ObserveStream(Observer, 'UTF-8 utf8 stream', 'UTF-8', '', TextEncoding::UTF8);
        ObserveStream(Observer, 'Windows-1252 utf8 stream', 'Windows-1252', '', TextEncoding::UTF8);
        Observer.Expect('ISO-8859-1 utf8 stream bytes', '3C 3F 78 6D 6C 20 76 65 72 73 69 6F 6E 3D 22 31 2E 30 22 20 65 6E 63 6F 64 69 6E 67 3D 22 49 53 4F 2D 38 38 35 39 2D 31 22 20 73 74 61 6E 64 61 6C 6F 6E 65 3D 22 22 3F 3E 0D 0A 3C 61 3E E4 3C 2F 61 3E');
        Observer.Expect('UTF-8 utf8 stream bytes', 'EF BB BF 3C 3F 78 6D 6C 20 76 65 72 73 69 6F 6E 3D 22 31 2E 30 22 20 65 6E 63 6F 64 69 6E 67 3D 22 55 54 46 2D 38 22 20 73 74 61 6E 64 61 6C 6F 6E 65 3D 22 22 3F 3E 0D 0A 3C 61 3E C3 A4 3C 2F 61 3E');
        Observer.Expect('Windows-1252 utf8 stream bytes', '3C 3F 78 6D 6C 20 76 65 72 73 69 6F 6E 3D 22 31 2E 30 22 20 65 6E 63 6F 64 69 6E 67 3D 22 57 69 6E 64 6F 77 73 2D 31 32 35 32 22 20 73 74 61 6E 64 61 6C 6F 6E 65 3D 22 22 3F 3E 0D 0A 3C 61 3E E4 3C 2F 61 3E');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToOutStream_Iso88591_WindowsAndMSDosStreams()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStream(Observer, 'ISO-8859-1 yes windows stream', 'ISO-8859-1', 'yes', TextEncoding::Windows);
        ObserveStream(Observer, 'ISO-8859-1 yes msdos stream', 'ISO-8859-1', 'yes', TextEncoding::MSDos);
        Observer.Expect('ISO-8859-1 yes windows stream bytes', '3C 3F 78 6D 6C 20 76 65 72 73 69 6F 6E 3D 22 31 2E 30 22 20 65 6E 63 6F 64 69 6E 67 3D 22 49 53 4F 2D 38 38 35 39 2D 31 22 20 73 74 61 6E 64 61 6C 6F 6E 65 3D 22 79 65 73 22 3F 3E 0D 0A 3C 61 3E E4 3C 2F 61 3E');
        Observer.Expect('ISO-8859-1 yes msdos stream bytes', '3C 3F 78 6D 6C 20 76 65 72 73 69 6F 6E 3D 22 31 2E 30 22 20 65 6E 63 6F 64 69 6E 67 3D 22 49 53 4F 2D 38 38 35 39 2D 31 22 20 73 74 61 6E 64 61 6C 6F 6E 65 3D 22 79 65 73 22 3F 3E 0D 0A 3C 61 3E E4 3C 2F 61 3E');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToOutStream_LoadedIso88591Document()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT DE Helper";
        TempBlob: Codeunit "Temp Blob";
        Doc: XmlDocument;
        OutS: OutStream;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0" encoding="ISO-8859-1"?><a>' + Helper.Umlaut() + '</a>', Doc);
        TempBlob.CreateOutStream(OutS, TextEncoding::Windows);
        Doc.WriteTo(OutS);
        Observer.Observe('loaded windows stream bytes', Helper.HexOf(TempBlob));
        Observer.Expect('loaded windows stream bytes', '3C 3F 78 6D 6C 20 76 65 72 73 69 6F 6E 3D 22 31 2E 30 22 20 65 6E 63 6F 64 69 6E 67 3D 22 49 53 4F 2D 38 38 35 39 2D 31 22 3F 3E 0D 0A 3C 61 3E E4 3C 2F 61 3E');
        Observer.Verify();
    end;

    // ---- Writer TV (NP lane, 2026-10-29): WriteTo(OutStream) of a document built in code (XmlDocument.Create(), Create('', ''), with no
    // declaration and with XmlDeclaration.Create for utf-8/UTF-8/utf-16 with and without standalone 'yes'), on UTF-8, UTF-16 and default
    // streams and with XmlWriteOptions; an XmlWriteOptions passed as content to XmlDocument.Add and XmlElement.Add. ----

    local procedure TvBuild(Version: Text; Encoding: Text; Standalone: Text; WithDeclaration: Boolean; TwoArgCreate: Boolean; var Doc: XmlDocument)
    var
        Root: XmlElement;
    begin
        if TwoArgCreate then
            Doc := XmlDocument.Create('', '')
        else
            Doc := XmlDocument.Create();
        if WithDeclaration then
            Doc.SetDeclaration(XmlDeclaration.Create(Version, Encoding, Standalone));
        Root := XmlElement.Create('r');
        Root.Add(XmlElement.Create('c', '', 'x'));
        Doc.Add(Root);
    end;

    local procedure TvBytes(var Doc: XmlDocument; StreamEncoding: Text; UseOptions: Boolean): Text
    var
        Helper: Codeunit "LT DE Helper";
        TempBlob: Codeunit "Temp Blob";
        Options: XmlWriteOptions;
        OutS: OutStream;
    begin
        case StreamEncoding of
            'utf8':
                TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
            'utf16':
                TempBlob.CreateOutStream(OutS, TextEncoding::UTF16);
            'default':
                TempBlob.CreateOutStream(OutS);
        end;
        if UseOptions then begin
            Options.PreserveWhitespace(true);
            Doc.WriteTo(Options, OutS);
        end else
            Doc.WriteTo(OutS);
        exit(Helper.HexOf(TempBlob));
    end;

    local procedure TvReadBack(var Doc: XmlDocument): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Chunk: Text;
        All: Text;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Doc.WriteTo(OutS);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Chunk);
            All += Chunk + '|';
        end;
        exit(All);
    end;

    [Test]
    procedure TV_WriteToOutStream_BuiltWithoutDeclaration()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
    begin
        TvBuild('', '', '', false, false, Doc);
        Observer.Observe('create() utf8', TvBytes(Doc, 'utf8', false));
        Observer.Observe('create() readback', TvReadBack(Doc));
        TvBuild('', '', '', false, true, Doc);
        Observer.Observe('create(,) utf8', TvBytes(Doc, 'utf8', false));
        Observer.Observe('create(,) utf16 stream', TvBytes(Doc, 'utf16', false));
        Observer.Observe('create(,) default stream', TvBytes(Doc, 'default', false));
        Observer.Finish();
    end;

    [Test]
    procedure TV_WriteToOutStream_BuiltWithoutDeclaration_Options()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
    begin
        TvBuild('', '', '', false, true, Doc);
        Observer.Observe('create(,) options utf8', TvBytes(Doc, 'utf8', true));
        TvBuild('1.0', 'UTF-8', 'yes', true, true, Doc);
        Observer.Observe('UTF-8 yes options utf8', TvBytes(Doc, 'utf8', true));
        Observer.Finish();
    end;

    [Test]
    procedure TV_WriteToOutStream_Utf8Declarations()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
    begin
        TvBuild('1.0', 'UTF-8', 'yes', true, true, Doc);
        Observer.Observe('UTF-8 yes utf8', TvBytes(Doc, 'utf8', false));
        Observer.Observe('UTF-8 yes readback', TvReadBack(Doc));
        TvBuild('1.0', 'utf-8', 'yes', true, false, Doc);
        Observer.Observe('utf-8 yes utf8', TvBytes(Doc, 'utf8', false));
        TvBuild('1.0', 'utf-8', '', true, false, Doc);
        Observer.Observe('utf-8 none utf8', TvBytes(Doc, 'utf8', false));
        Observer.Finish();
    end;

    [Test]
    procedure TV_WriteToOutStream_Utf8Declaration_OtherStreams()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
    begin
        TvBuild('1.0', 'UTF-8', 'yes', true, true, Doc);
        Observer.Observe('UTF-8 yes utf16 stream', TvBytes(Doc, 'utf16', false));
        Observer.Observe('UTF-8 yes default stream', TvBytes(Doc, 'default', false));
        TvBuild('1.0', 'UTF-8', 'no', true, true, Doc);
        Observer.Observe('UTF-8 no utf8', TvBytes(Doc, 'utf8', false));
        Observer.Finish();
    end;

    [Test]
    procedure TV_WriteToOutStream_Utf16AndNoEncodingDeclarations()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
    begin
        TvBuild('1.0', 'utf-16', '', true, false, Doc);
        Observer.Observe('utf-16 none utf8', TvBytes(Doc, 'utf8', false));
        TvBuild('1.0', 'utf-16', 'yes', true, false, Doc);
        Observer.Observe('utf-16 yes utf8', TvBytes(Doc, 'utf8', false));
        TvBuild('1.0', '', '', true, false, Doc);
        Observer.Observe('no encoding utf8', TvBytes(Doc, 'utf8', false));
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TvTryDocAdd(var Doc: XmlDocument; Body: XmlElement; Options: XmlWriteOptions)
    begin
        Doc.Add(Body, Options);
    end;

    [TryFunction]
    local procedure TvTryElementAdd(var Parent: XmlElement; Child: XmlElement; Options: XmlWriteOptions)
    begin
        Parent.Add(Child, Options);
    end;

    local procedure TvAddOutcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure TvDocShape(var Doc: XmlDocument): Text
    var
        T: Text;
    begin
        Doc.WriteTo(T);
        exit(Format(Doc.GetChildNodes().Count()) + '|' + T);
    end;

    [Test]
    procedure TV_XmlWriteOptions_AsContent_DocumentAdd()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Body: XmlElement;
        Options: XmlWriteOptions;
        Fresh: XmlWriteOptions;
    begin
        Doc := XmlDocument.Create('', '');
        Body := XmlElement.Create('Body');
        Body.Add(XmlElement.Create('c', '', 'x'));
        Options.PreserveWhitespace(true);
        ClearLastError();
        Observer.Observe('doc add preserve true', TvAddOutcome(TvTryDocAdd(Doc, Body, Options)));
        Observer.Observe('doc after preserve true', TvDocShape(Doc));
        Doc := XmlDocument.Create();
        Doc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'yes'));
        Body := XmlElement.Create('Body');
        Body.Add(XmlElement.Create('c', '', 'x'));
        ClearLastError();
        Observer.Observe('doc add fresh options', TvAddOutcome(TvTryDocAdd(Doc, Body, Fresh)));
        Observer.Observe('doc after fresh options', TvDocShape(Doc));
        Observer.Observe('doc after fresh options readback', TvReadBack(Doc));
        Observer.Finish();
    end;

    [Test]
    procedure TV_XmlWriteOptions_AsContent_ElementAdd()
    var
        Observer: Codeunit "Probe Observer";
        Parent: XmlElement;
        Options: XmlWriteOptions;
        T: Text;
    begin
        Parent := XmlElement.Create('p');
        Options.PreserveWhitespace(false);
        ClearLastError();
        Observer.Observe('element add', TvAddOutcome(TvTryElementAdd(Parent, XmlElement.Create('c', '', 'x'), Options)));
        Parent.WriteTo(T);
        Observer.Observe('element after', Format(Parent.GetChildNodes().Count()) + '|' + T);
        Observer.Finish();
    end;
}

codeunit 85908 "LT DE Xml xmlns Attribute"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAdd(var E: XmlElement; A: XmlAttribute)
    begin
        E.Add(A);
    end;

    [TryFunction]
    local procedure TrySet(var E: XmlElement; Value: Text)
    begin
        E.SetAttribute('xmlns', Value);
    end;

    [TryFunction]
    local procedure TryWriteElement(E: XmlElement; var T: Text)
    begin
        E.WriteTo(T);
    end;

    [TryFunction]
    local procedure TryWriteDocument(E: XmlElement; var T: Text)
    var
        Doc: XmlDocument;
    begin
        Doc := XmlDocument.Create();
        Doc.Add(E);
        Doc.WriteTo(T);
    end;

    local procedure ObserveWrite(var Observer: Codeunit "Probe Observer"; Name: Text; E: XmlElement)
    var
        T: Text;
    begin
        ClearLastError();
        if TryWriteElement(E, T) then
            Observer.Observe(Name + ' element writeto', 'ok ' + T)
        else
            Observer.Observe(Name + ' element writeto', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryWriteDocument(E, T) then
            Observer.Observe(Name + ' document writeto', 'ok ' + T)
        else
            Observer.Observe(Name + ' document writeto', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe(Name + ' namespaceuri', '[' + E.NamespaceUri() + ']');
    end;

    local procedure ObserveAdd(var Observer: Codeunit "Probe Observer"; Name: Text; var E: XmlElement; A: XmlAttribute)
    begin
        ClearLastError();
        if TryAdd(E, A) then
            Observer.Observe(Name + ' add', 'ok')
        else
            Observer.Observe(Name + ' add', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure XmlnsAttribute_OnElementWithoutNamespace()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
    begin
        E := XmlElement.Create('Root');
        ObserveAdd(Observer, 'no ns', E, XmlAttribute.Create('xmlns', 'urn:x-obml:1.0'));
        ObserveWrite(Observer, 'no ns', E);
        Observer.Expect('no ns add', 'ok');
        Observer.Expect('no ns element writeto', 'error The following exception was encountered when processing XML data: ''The prefix '''' cannot be redefined from '''' to ''urn:x-obml:1.0'' within the same start element tag.'' at line 0 and position 0.|Xml:Xml');
        Observer.Expect('no ns document writeto', 'error The following exception was encountered when processing XML data: ''The prefix '''' cannot be redefined from '''' to ''urn:x-obml:1.0'' within the same start element tag.'' at line 0 and position 0.|Xml:Xml');
        Observer.Expect('no ns namespaceuri', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure XmlnsAttribute_OnElementWithSameNamespace()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
    begin
        E := XmlElement.Create('Root', 'urn:x-obml:1.0');
        ObserveAdd(Observer, 'same ns', E, XmlAttribute.Create('xmlns', 'urn:x-obml:1.0'));
        ObserveWrite(Observer, 'same ns', E);
        Observer.Expect('same ns add', 'ok');
        Observer.Expect('same ns element writeto', 'ok <Root xmlns="urn:x-obml:1.0" />');
        Observer.Expect('same ns document writeto', 'ok <?xml version="1.0" encoding="utf-16"?>\r\n<Root xmlns="urn:x-obml:1.0" />');
        Observer.Expect('same ns namespaceuri', '[urn:x-obml:1.0]');
        Observer.Verify();
    end;

    [Test]
    procedure XmlnsAttribute_OnElementWithOtherNamespace()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
    begin
        E := XmlElement.Create('Root', 'urn:other');
        ObserveAdd(Observer, 'other ns', E, XmlAttribute.Create('xmlns', 'urn:x-obml:1.0'));
        ObserveWrite(Observer, 'other ns', E);
        Observer.Expect('other ns add', 'ok');
        Observer.Expect('other ns element writeto', 'error The following exception was encountered when processing XML data: ''The prefix '''' cannot be redefined from ''urn:other'' to ''urn:x-obml:1.0'' within the same start element tag.'' at line 0 and position 0.|Xml:Xml');
        Observer.Expect('other ns document writeto', 'error The following exception was encountered when processing XML data: ''The prefix '''' cannot be redefined from ''urn:other'' to ''urn:x-obml:1.0'' within the same start element tag.'' at line 0 and position 0.|Xml:Xml');
        Observer.Expect('other ns namespaceuri', '[urn:other]');
        Observer.Verify();
    end;

    [Test]
    procedure XmlnsSetAttribute_OnElementWithoutNamespace()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
    begin
        E := XmlElement.Create('Root');
        ClearLastError();
        if TrySet(E, 'urn:x-obml:1.0') then
            Observer.Observe('setattribute', 'ok')
        else
            Observer.Observe('setattribute', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ObserveWrite(Observer, 'setattribute', E);
        Observer.Expect('setattribute', 'ok');
        Observer.Expect('setattribute element writeto', 'error The following exception was encountered when processing XML data: ''The prefix '''' cannot be redefined from '''' to ''urn:x-obml:1.0'' within the same start element tag.'' at line 0 and position 0.|Xml:Xml');
        Observer.Expect('setattribute document writeto', 'error The following exception was encountered when processing XML data: ''The prefix '''' cannot be redefined from '''' to ''urn:x-obml:1.0'' within the same start element tag.'' at line 0 and position 0.|Xml:Xml');
        Observer.Expect('setattribute namespaceuri', '[]');
        Observer.Verify();
    end;
}
