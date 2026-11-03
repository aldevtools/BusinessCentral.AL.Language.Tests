// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Temp Blob (System Application); own objects in DgXmlPortLeadObjects.al (86020-86029, 86031-86033)
// Facts: corpus issue 671 items 106 to 111: the TableSeparator default between two root tables of a VariableText export
// (microsoft/AL issue 6416); what an empty or undeclared namespace prefix exports (Learn: Namespaces, NamespacePrefix); Boolean export and import text under session language 1031 and 1033 (issue 7243); the SOAP envelope
// xmlport of issue 246 (prefixed text elements with DefaultNamespace and UseDefaultNamespace); an import of a value longer than
// 2048 characters into a text element and into a Text[2048] field (issue 2870); Import from an InStream of a stored Blob and
// from an InStream that was never created (issue 5218).
// BC versions: 27, 28, 29

codeunit 86030 "LT DG XmlPort Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedTwoTables()
    var
        Item: Record "LT DG Item";
        Line: Record "LT DG Line";
    begin
        Item.DeleteAll();
        Line.DeleteAll();
        Item.Id := 1;
        Item.Name := 'Alpha';
        Item.Insert();
        Item.Id := 2;
        Item.Name := 'Beta';
        Item.Insert();
        Line.Id := 7;
        Line.Note := 'L7';
        Line.Insert();
        Line.Id := 8;
        Line.Note := 'L8';
        Line.Insert();
    end;

    local procedure SeedBool()
    var
        Item: Record "LT DG Item";
    begin
        Item.DeleteAll();
        Item.Id := 1;
        Item.Flag := true;
        Item.Insert();
        Item.Id := 2;
        Item.Flag := false;
        Item.Insert();
    end;

    local procedure ExportText(XmlPortId: Integer; Encoding: TextEncoding): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Big: BigText;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlPortId, OutS);
        TempBlob.CreateInStream(InS, Encoding);
        Big.Read(InS);
        if Big.Length() = 0 then
            exit('<empty>');
        Big.GetSubText(Result, 1, Big.Length());
        exit(Result);
    end;

    local procedure TryExportText(XmlPortId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Big: BigText;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        if not Xmlport.Export(XmlPortId, OutS) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Big.Read(InS);
        Big.GetSubText(Result, 1, Big.Length());
        exit(Result);
    end;

    local procedure ImportText(XmlPortId: Integer; Content: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        ClearLastError();
        if Xmlport.Import(XmlPortId, InS) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure FlagOf(Id: Integer): Text
    var
        Item: Record "LT DG Item";
    begin
        if not Item.Get(Id) then
            exit('none');
        if Item.Flag then
            exit('true');
        exit('false');
    end;

    // One Boolean value through an import: 'true'/'false' (the stored Flag), or the error code.
    local procedure ImportBool(XmlPortId: Integer; Value: Text): Text
    var
        Item: Record "LT DG Item";
        Content: Text;
        Outcome: Text;
    begin
        Item.DeleteAll();
        Commit();
        if XmlPortId = Xmlport::"LT DG Csv Bool" then
            Content := '"1","' + Value + '"'
        else
            Content := '<Root><Item><Id>1</Id><Flag>' + Value + '</Flag></Item></Root>';
        Outcome := ImportText(XmlPortId, Content);
        Commit();
        if Outcome = 'ok' then
            exit(FlagOf(1));
        exit('err ' + GetLastErrorCode());
    end;

    local procedure ImportBoolRow(XmlPortId: Integer): Text
    var
        Values: List of [Text];
        Value: Text;
        Result: Text;
    begin
        Values.AddRange('Yes', 'No', 'Ja', 'Nein', 'true', 'false', '1', '0');
        foreach Value in Values do
            Result += Value + '=' + ImportBool(XmlPortId, Value) + ';';
        exit(Result);
    end;

    local procedure LongText(Length: Integer): Text
    var
        Tb: TextBuilder;
        i: Integer;
    begin
        for i := 1 to Length do
            Tb.Append(Format(i mod 10));
        exit(Tb.ToText());
    end;

    local procedure ImportLongTxt(Length: Integer): Text
    var
        Xp: XmlPort "LT DG Long Import";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Outcome: Text;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<Root><Txt>' + LongText(Length) + '</Txt></Root>');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetSource(InS);
        ClearLastError();
        if Xp.Import() then
            Outcome := 'ok'
        else
            Outcome := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        if StrLen(Outcome) > 300 then
            Outcome := CopyStr(Outcome, 1, 120) + '...' + CopyStr(Outcome, StrLen(Outcome) - 179);
        exit(Outcome + ' length=' + Format(Xp.TxtLength()));
    end;

    local procedure ImportLongField(Length: Integer): Text
    var
        Item: Record "LT DG Item";
        Outcome: Text;
    begin
        Item.DeleteAll();
        Commit();
        Outcome := ImportText(Xmlport::"LT DG Long Import", '<Root><Item><Id>5</Id><Long>' + LongText(Length) + '</Long></Item></Root>');
        Commit();
        if StrLen(Outcome) > 300 then
            Outcome := CopyStr(Outcome, 1, 120) + '...' + CopyStr(Outcome, StrLen(Outcome) - 179);
        if Item.Get(5) then
            exit(Outcome + ' stored=' + Format(StrLen(Item.Long)));
        exit(Outcome + ' stored=none');
    end;

    [Test]
    procedure Item106_TwoTablesDefaultSeparator()
    var
        Observer: Codeunit "Probe Observer";
        Xp: XmlPort "LT DG Csv Two Default";
    begin
        SeedTwoTables();
        Observer.Observe('getter', '[' + Xp.TableSeparator() + ']');
        Observer.Observe('export', ExportText(Xmlport::"LT DG Csv Two Default", TextEncoding::MSDos));
        Observer.Expect('getter', '[\r\n\r\n]');
        Observer.Expect('export', '"1","Alpha"\r\n"2","Beta"\r\n\r\n"7","L7"\r\n"8","L8"');
        Observer.Verify();
    end;

    [Test]
    procedure Item106_TwoTablesNewLineSeparator()
    var
        Observer: Codeunit "Probe Observer";
        Xp: XmlPort "LT DG Csv Two NewLine";
    begin
        SeedTwoTables();
        Observer.Observe('getter', '[' + Xp.TableSeparator() + ']');
        Observer.Observe('export', ExportText(Xmlport::"LT DG Csv Two NewLine", TextEncoding::MSDos));
        Observer.Expect('getter', '[\r\n]');
        Observer.Expect('export', '"1","Alpha"\r\n"2","Beta"\r\n"7","L7"\r\n"8","L8"');
        Observer.Verify();
    end;

    [Test]
    procedure Item107_BoolExportByLanguage()
    var
        Observer: Codeunit "Probe Observer";
        OldLanguage: Integer;
    begin
        OldLanguage := GlobalLanguage();
        SeedBool();
        GlobalLanguage(1033);
        Observer.Observe('format_1033', Format(true) + '/' + Format(false));
        Observer.Observe('legacy_1033', ExportText(Xmlport::"LT DG Xml Bool Legacy", TextEncoding::UTF16));
        Observer.Observe('xml_1033', ExportText(Xmlport::"LT DG Xml Bool Xml", TextEncoding::UTF16));
        Observer.Observe('csv_1033', ExportText(Xmlport::"LT DG Csv Bool", TextEncoding::MSDos));
        GlobalLanguage(1031);
        Observer.Observe('format_1031', Format(true) + '/' + Format(false));
        Observer.Observe('legacy_1031', ExportText(Xmlport::"LT DG Xml Bool Legacy", TextEncoding::UTF16));
        Observer.Observe('xml_1031', ExportText(Xmlport::"LT DG Xml Bool Xml", TextEncoding::UTF16));
        Observer.Observe('csv_1031', ExportText(Xmlport::"LT DG Csv Bool", TextEncoding::MSDos));
        GlobalLanguage(OldLanguage);
        Observer.Expect('format_1033', 'Yes/No');
        Observer.Expect('legacy_1033', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Flag>Yes</Flag>\r\n  </Item>\r\n  <Item>\r\n    <Id>2</Id>\r\n    <Flag>No</Flag>\r\n  </Item>\r\n</Root>');
        Observer.Expect('xml_1033', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Flag>true</Flag>\r\n  </Item>\r\n  <Item>\r\n    <Id>2</Id>\r\n    <Flag>false</Flag>\r\n  </Item>\r\n</Root>');
        Observer.Expect('csv_1033', '"1","Yes"\r\n"2","No"');
        Observer.Expect('format_1031', 'Ja/Nein');
        Observer.Expect('legacy_1031', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Flag>Ja</Flag>\r\n  </Item>\r\n  <Item>\r\n    <Id>2</Id>\r\n    <Flag>Nein</Flag>\r\n  </Item>\r\n</Root>');
        Observer.Expect('xml_1031', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root>\r\n  <Item>\r\n    <Id>1</Id>\r\n    <Flag>true</Flag>\r\n  </Item>\r\n  <Item>\r\n    <Id>2</Id>\r\n    <Flag>false</Flag>\r\n  </Item>\r\n</Root>');
        Observer.Expect('csv_1031', '"1","Ja"\r\n"2","Nein"');
        Observer.Verify();
    end;

    [Test]
    procedure Item107_BoolImportByLanguage()
    var
        Observer: Codeunit "Probe Observer";
        OldLanguage: Integer;
    begin
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Observer.Observe('legacy_1033', ImportBoolRow(Xmlport::"LT DG Xml Bool Legacy"));
        Observer.Observe('xml_1033', ImportBoolRow(Xmlport::"LT DG Xml Bool Xml"));
        Observer.Observe('csv_1033', ImportBoolRow(Xmlport::"LT DG Csv Bool"));
        Observer.Observe('legacy_1033_ja', ImportText(Xmlport::"LT DG Xml Bool Legacy", '<Root><Item><Id>1</Id><Flag>Ja</Flag></Item></Root>'));
        GlobalLanguage(1031);
        Observer.Observe('legacy_1031', ImportBoolRow(Xmlport::"LT DG Xml Bool Legacy"));
        Observer.Observe('xml_1031', ImportBoolRow(Xmlport::"LT DG Xml Bool Xml"));
        Observer.Observe('csv_1031', ImportBoolRow(Xmlport::"LT DG Csv Bool"));
        Observer.Observe('legacy_1031_yes', ImportText(Xmlport::"LT DG Xml Bool Legacy", '<Root><Item><Id>1</Id><Flag>Yes</Flag></Item></Root>'));
        GlobalLanguage(OldLanguage);
        Observer.Expect('legacy_1033', 'Yes=true;No=false;Ja=err Evaluate;Nein=err Evaluate;true=true;false=false;1=true;0=false;');
        Observer.Expect('xml_1033', 'Yes=err Evaluate;No=err Evaluate;Ja=err Evaluate;Nein=err Evaluate;true=true;false=false;1=true;0=false;');
        Observer.Expect('csv_1033', 'Yes=true;No=false;Ja=err Evaluate;Nein=err Evaluate;true=true;false=false;1=true;0=false;');
        Observer.Expect('legacy_1033_ja', 'error:The value "Ja" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('legacy_1031', 'Yes=err Evaluate;No=err Evaluate;Ja=true;Nein=false;true=true;false=false;1=true;0=false;');
        Observer.Expect('xml_1031', 'Yes=err Evaluate;No=err Evaluate;Ja=err Evaluate;Nein=err Evaluate;true=true;false=false;1=true;0=false;');
        Observer.Expect('csv_1031', 'Yes=err Evaluate;No=err Evaluate;Ja=true;Nein=false;true=true;false=false;1=true;0=false;');
        Observer.Expect('legacy_1031_yes', 'error:Der Wert „Yes“ kann nicht in Typ Boolean ausgewertet werden.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Item108_NamespaceRules()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT DG Item";
    begin
        Item.DeleteAll();
        Item.Id := 9;
        Item.Insert();
        Observer.Observe('empty_prefix', TryExportText(Xmlport::"LT DG Ns Empty Prefix"));
        Observer.Observe('undeclared', TryExportText(Xmlport::"LT DG Ns Undeclared"));
        Observer.Expect('empty_prefix', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<Root xmlns="urn:microsoft-dynamics-nav/xmlports/x86031">\r\n  <Item>\r\n    <Id>9</Id>\r\n  </Item>\r\n</Root>');
        Observer.Expect('undeclared', '<?xml version="1.0" encoding="UTF-16" standalone="no"?>\r\n<q:Root xmlns:p="urn:lt-dg-p" xmlns:q="q">\r\n  <Item>\r\n    <Id>9</Id>\r\n  </Item>\r\n</q:Root>');
        Observer.Verify();
    end;

    // Linux suspect, queued for the Windows check (not a [Test]): on Linux BC 29.0 this export ends the test with an uncatchable
    // 'Unexpected CLR exception thrown.: System.NullReferenceException' in NavXmlPortXmlAdapter.GetNamespaceUriStringFromDefinedNamespaces.
    procedure Item108_PrefixWithoutNamespacesProbe()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT DG Item";
    begin
        Item.DeleteAll();
        Item.Id := 9;
        Item.Insert();
        Observer.Observe('no_namespaces', TryExportText(Xmlport::"LT DG Ns No Namespaces"));
        Observer.Finish();
    end;

    [Test]
    procedure Item109_SoapEnvelopeExport()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT DG Item";
    begin
        Item.DeleteAll();
        Item.Id := 3;
        Item.Name := 'ASDF';
        Item.Insert();
        Observer.Observe('export', ExportText(Xmlport::"LT DG Soap", TextEncoding::UTF8));
        Observer.Expect('export', '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n<Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.xmlsoap.org/soap/envelope/">\r\n  <soap:Body>\r\n    <ValidateLicense xmlns="http://tempuri.org/">\r\n      <session>ASDF</session>\r\n      <instance>3</instance>\r\n    </ValidateLicense>\r\n  </soap:Body>\r\n</Envelope>');
        Observer.Verify();
    end;

    [Test]
    procedure Item110_LongTextElement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('txt_2048', ImportLongTxt(2048));
        Observer.Observe('txt_2049', ImportLongTxt(2049));
        Observer.Observe('txt_4096', ImportLongTxt(4096));
        Observer.Observe('txt_5000', ImportLongTxt(5000));
        Observer.Expect('txt_2048', 'ok length=2048');
        Observer.Expect('txt_2049', 'error:The value ''1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123...567890123456789012345678901234567890123456789012345678901234567890123456789'' has a length 2049, which exceeds the maximum size of the destination type Text.|XmlPortTypeSizeExceeded length=0');
        Observer.Expect('txt_4096', 'error:The value ''1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123...234567890123456789012345678901234567890123456789012345678901234567890123456'' has a length 4096, which exceeds the maximum size of the destination type Text.|XmlPortTypeSizeExceeded length=0');
        Observer.Expect('txt_5000', 'error:The value ''1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123...678901234567890123456789012345678901234567890123456789012345678901234567890'' has a length 5000, which exceeds the maximum size of the destination type Text.|XmlPortTypeSizeExceeded length=0');
        Observer.Verify();
    end;

    [Test]
    procedure Item110_LongTextField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field_2048', ImportLongField(2048));
        Observer.Observe('field_2049', ImportLongField(2049));
        Observer.Observe('field_5000', ImportLongField(5000));
        Observer.Expect('field_2048', 'ok stored=2048');
        Observer.Expect('field_2049', 'error:The length of the string is 2049, but it must be less than or equal to 2048 characters. Value: 1234567890123456789...567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890...|StringLengthExceeded stored=none');
        Observer.Expect('field_5000', 'error:The length of the string is 5000, but it must be less than or equal to 2048 characters. Value: 1234567890123456789...567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890...|StringLengthExceeded stored=none');
        Observer.Verify();
    end;

    [Test]
    procedure Item111_ImportFromStoredBlob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT DG Blob";
        Item: Record "LT DG Item";
        Xp: XmlPort "LT DG Xml Bool Xml";
        OutS: OutStream;
        InS: InStream;
    begin
        Item.DeleteAll();
        Row.DeleteAll();
        Row.Id := 1;
        Row.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<Root><Item><Id>4</Id><Flag>true</Flag></Item></Root>');
        Row.Insert();
        Clear(Row);
        Row.Get(1);
        Row.CalcFields(Data);
        Row.Data.CreateInStream(InS, TextEncoding::UTF8);
        Xp.SetSource(InS);
        Xp.Import();
        Observer.Observe('flag', FlagOf(4));
        Observer.Expect('flag', 'true');
        Observer.Verify();
    end;

    [Test]
    procedure Item111_ImportFromStreamNeverCreated()
    var
        Observer: Codeunit "Probe Observer";
        Xp: XmlPort "LT DG Xml Bool Xml";
        InS: InStream;
    begin
        Xp.SetSource(InS);
        asserterror Xp.Import();
        Observer.ObserveError('instance');
        asserterror Xmlport.Import(Xmlport::"LT DG Xml Bool Xml", InS);
        Observer.ObserveError('static');
        Observer.Expect('instance|text', 'Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.');
        Observer.Expect('instance|code', 'NotInitialized');
        Observer.Expect('static|text', 'Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.');
        Observer.Expect('static|code', 'NotInitialized');
        Observer.Verify();
    end;
}
