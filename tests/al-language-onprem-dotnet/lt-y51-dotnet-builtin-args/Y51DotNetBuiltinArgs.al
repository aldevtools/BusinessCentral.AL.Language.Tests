// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160); own table 99390, test codeunit 99391 (writer Y51, gap cycle 5 spec G5-22)
// Probe: a DotNet value passed straight to a builtin parameter: a System.String into ErrorInfo.Create (also in a Collect scope, from a
//        String[] walked with foreach, and a String that holds no object), a System.IO.MemoryStream into the InStream parameter of
//        XmlDocument.ReadFrom (3 and 2 arguments, Position 0 and 3, text that is not XML), Media.ImportStream (Position 0 and 4) and
//        JsonObject.ReadFrom, and a MemoryStream that holds no object. Observed: the builtin result, the stream Position after the call,
//        the bytes the Media holds, error texts and codes.
//        Already pinned nearby: TestDotNetValueKindsContracts.al (CopyStream with a MemoryStream), lt-dotnet-interop/DotNetOperandStringEq.al.
// Values: every literal asserted is what BC 27.5, 28.5 and 29.0 (Linux CI containers) produced; #if BC29PLUS where 29.0 differs.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.String"; LtY51DnString) { }
        type("System.String[]"; LtY51DnStringArray) { }
        type("System.IO.MemoryStream"; LtY51DnMemoryStream) { }
        type("System.Text.Encoding"; LtY51DnEncoding) { }
    }
}

table 99390 "LT Y51 DN Media"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Logo; Media) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 99391 "LT Y51 DotNet Builtin Args"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Mem(Content: Text; var MS: DotNet LtY51DnMemoryStream)
    var
        Enc: DotNet LtY51DnEncoding;
    begin
        MS := MS.MemoryStream(Enc.UTF8().GetBytes(Content));
    end;

    local procedure Bytes10(var MS: DotNet LtY51DnMemoryStream)
    var
        I: Integer;
    begin
        MS := MS.MemoryStream();
        for I := 1 to 10 do
            MS.WriteByte(64 + I);
        MS.Position := 0;
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RaiseAll(Messages: DotNet LtY51DnStringArray)
    var
        ErrorMsg: DotNet LtY51DnString;
    begin
        foreach ErrorMsg in Messages do
            Error(ErrorInfo.Create(ErrorMsg, true));
    end;

    [TryFunction]
    local procedure TryCreateInfo(S: DotNet LtY51DnString; var Info: ErrorInfo)
    begin
        Info := ErrorInfo.Create(S);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure DotNetString_ErrorInfoCreate()
    var
        S: DotNet LtY51DnString;
        Source: DotNet LtY51DnString;
        Info: ErrorInfo;
        Collected: List of [ErrorInfo];
        One: ErrorInfo;
        All: Text;
    begin
        S := 'LT dn message';
        Info := ErrorInfo.Create(S, true);
        Observer.Observe('msg', Info.Message);
        Observer.Observe('collectible', Format(Info.Collectible));
        Source := 'LT dn one,LT dn two';
        RaiseAll(Source.Split(','));
        Observer.Observe('has_collected', Format(HasCollectedErrors()));
        Collected := GetCollectedErrors();
        Observer.Observe('collected_count', Format(Collected.Count()));
        foreach One in Collected do
            All += One.Message + '|' + Format(One.Collectible) + ';';
        Observer.Observe('collected', All);
        ClearCollectedErrors();
        Observer.Expect('msg', 'LT dn message');
        Observer.Expect('collectible', 'Yes');
        Observer.Expect('has_collected', 'Yes');
        Observer.Expect('collected_count', '2');
        Observer.Expect('collected', 'LT dn one|Yes;LT dn two|Yes;');
        Observer.Verify();
    end;

    // Linux suspect (held, not a [Test]): ErrorInfo.Create with a DotNet String that holds no object succeeds in a TryFunction, then
    // StrLen(Info.Message) ends the test with an uncatchable "Unexpected CLR exception thrown.: System.ArgumentNullException: Value cannot
    // be null. (Parameter 'source')" (at ALSystemString.ALStrLen) on the Linux containers 27.5, 28.5, 29.0. Waits for the Windows check.
    procedure Suspect_NullDotNetString_ErrorInfoCreate()
    var
        Null: DotNet LtY51DnString;
        Info: ErrorInfo;
    begin
        if TryCreateInfo(Null, Info) then
            Observer.Observe('null_create', 'ok|' + Info.Message + '|' + Format(StrLen(Info.Message)))
        else
            Observer.ObserveError('null_create');
        Observer.Finish();
    end;

    local procedure ReadXml(Name: Text; MS: DotNet LtY51DnMemoryStream; ThreeArgs: Boolean)
    var
        ReadOptions: XmlReadOptions;
        Doc: XmlDocument;
        Ok: Boolean;
        Xml: Text;
    begin
        ClearLastError();
        ReadOptions.PreserveWhitespace(true);
        if ThreeArgs then
            Ok := XmlDocument.ReadFrom(MS, ReadOptions, Doc)
        else
            Ok := XmlDocument.ReadFrom(MS, Doc);
        Observer.Observe('ok_' + Name, Format(Ok));
        if Ok then begin
            Doc.WriteTo(Xml);
            Observer.Observe('xml_' + Name, Xml);
        end else
            Observer.ObserveError('err_' + Name);
        Observer.Observe('pos_after_' + Name, Format(MS.Position));
    end;

    [Test]
    procedure DotNetMemoryStream_XmlDocumentReadFrom()
    var
        MS: DotNet LtY51DnMemoryStream;
    begin
        Mem('<p><img src="a"/></p>', MS);
        ReadXml('pos0', MS, true);
        Mem('<p><img src="a"/></p>', MS);
        MS.Position := 3;
        ReadXml('pos3', MS, true);
        Mem('<p><br></p>', MS);
        ReadXml('notxml', MS, true);
        Mem('<p> <b>x</b> </p>', MS);
        ReadXml('twoargs', MS, false);
        Observer.Expect('ok_pos0', 'Yes');
        Observer.Expect('xml_pos0', '<?xml version="1.0" encoding="utf-16"?>\r\n<p>\r\n  <img src="a" />\r\n</p>');
        Observer.Expect('pos_after_pos0', '21');
        Observer.Expect('ok_pos3', 'Yes');
        Observer.Expect('xml_pos3', '<?xml version="1.0" encoding="utf-16"?>\r\n<p>\r\n  <img src="a" />\r\n</p>');
        Observer.Expect('pos_after_pos3', '21');
        Observer.Expect('ok_notxml', 'No');
        Observer.Expect('err_notxml|text', 'The following exception was encountered when processing XML data: ''The ''br'' start tag on line 1 position 5 does not match the end tag of ''p''. Line 1, position 10.'' at line 1 and position 10.');
        Observer.Expect('err_notxml|code', 'Xml:Xml');
        Observer.Expect('pos_after_notxml', '11');
        Observer.Expect('ok_twoargs', 'Yes');
        Observer.Expect('xml_twoargs', '<?xml version="1.0" encoding="utf-16"?>\r\n<p> <b>x</b> </p>');
        Observer.Expect('pos_after_twoargs', '17');
        Observer.Verify();
    end;

    local procedure Import(Name: Text; Id: Integer; MS: DotNet LtY51DnMemoryStream; Mime: Text)
    var
        M: Record "LT Y51 DN Media";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        B: Byte;
        Got: Text;
        MediaId: Guid;
    begin
        M.Id := Id;
        MediaId := M.Logo.ImportStream(MS, 'logo', Mime);
        M.Insert();
        Observer.Observe('hasvalue_' + Name, Format(M.Logo.HasValue()));
        Observer.Observe('mediaid_null_' + Name, Format(IsNullGuid(MediaId)));
        Observer.Observe('pos_after_' + Name, Format(MS.Position));
        TempBlob.CreateOutStream(OutS);
        M.Logo.ExportStream(OutS);
        Observer.Observe('bytes_' + Name, Format(TempBlob.Length()));
        if Mime = 'text/plain' then begin
            TempBlob.CreateInStream(InS);
            while not InS.EOS() do begin
                InS.Read(B);
                Got += Format(B) + ',';
            end;
            Observer.Observe('content_' + Name, Got);
        end;
    end;

    [Test]
    procedure DotNetMemoryStream_MediaImportStream_Text()
    var
        M: Record "LT Y51 DN Media";
        MS: DotNet LtY51DnMemoryStream;
    begin
        M.DeleteAll();
        Bytes10(MS);
        Import('pos0', 1, MS, 'text/plain');
        Bytes10(MS);
        MS.Position := 4;
        Import('pos4', 2, MS, 'text/plain');
        Observer.Expect('hasvalue_pos0', 'Yes');
        Observer.Expect('mediaid_null_pos0', 'No');
        Observer.Expect('pos_after_pos0', '10');
        Observer.Expect('bytes_pos0', '10');
        Observer.Expect('content_pos0', 'A,B,C,D,E,F,G,H,I,J,');
        Observer.Expect('hasvalue_pos4', 'Yes');
        Observer.Expect('mediaid_null_pos4', 'No');
        Observer.Expect('pos_after_pos4', '10');
        Observer.Expect('bytes_pos4', '10');
        Observer.Expect('content_pos4', 'A,B,C,D,E,F,G,H,I,J,');
        Observer.Verify();
    end;

    [Test]
    procedure DotNetMemoryStream_MediaImportStream_Png()
    var
        M: Record "LT Y51 DN Media";
        MS: DotNet LtY51DnMemoryStream;
    begin
        M.DeleteAll();
        Bytes10(MS);
        Import('png', 3, MS, 'image/png');
#if BC29PLUS
        Observer.Expect('hasvalue_png', 'Yes');
        Observer.Expect('mediaid_null_png', 'No');
        Observer.Expect('pos_after_png', '10');
        Observer.Expect('bytes_png', '10');
#else
        Observer.Expect('hasvalue_png', 'No');
        Observer.Expect('mediaid_null_png', 'Yes');
        Observer.Expect('pos_after_png', '0');
        Observer.Expect('bytes_png', '0');
#endif
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryReadNull(MS: DotNet LtY51DnMemoryStream; var Ok: Boolean)
    var
        Doc: XmlDocument;
    begin
        Ok := XmlDocument.ReadFrom(MS, Doc);
    end;

    [Test]
    procedure DotNetMemoryStream_Null_XmlReadFrom()
    var
        MS: DotNet LtY51DnMemoryStream;
        Ok: Boolean;
    begin
        ClearLastError();
        if TryReadNull(MS, Ok) then begin
            Observer.Observe('null_readfrom', 'ok|' + Format(Ok));
            Observer.ObserveError('null_readfrom_last');
        end else
            Observer.ObserveError('null_readfrom');
        Observer.Expect('null_readfrom|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDotNet to Microsoft.Dynamics.Nav.Runtime.NavInStream.');
        Observer.Expect('null_readfrom|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure DotNetMemoryStream_Null_ImportStream()
    var
        M: Record "LT Y51 DN Media";
        MS: DotNet LtY51DnMemoryStream;
    begin
        M.DeleteAll();
        M.Id := 4;
        asserterror M.Logo.ImportStream(MS, 'logo', 'image/png');
        Observer.ObserveError('null_import');
        Observer.Observe('null_import_hasvalue', Format(M.Logo.HasValue()));
        Observer.Expect('null_import|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDotNet to Microsoft.Dynamics.Nav.Runtime.NavInStream.');
        Observer.Expect('null_import|code', 'Conversion');
        Observer.Expect('null_import_hasvalue', 'No');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryPosition(MS: DotNet LtY51DnMemoryStream; var Pos: BigInteger)
    begin
        Pos := MS.Position;
    end;

    [Test]
    procedure DotNetMemoryStream_JsonObjectReadFrom()
    var
        MS: DotNet LtY51DnMemoryStream;
        J: JsonObject;
        Ok: Boolean;
        Json: Text;
        Pos: BigInteger;
    begin
        Mem('{"a":1,"b":"x"}', MS);
        Ok := J.ReadFrom(MS);
        Observer.Observe('ok_json', Format(Ok));
        J.WriteTo(Json);
        Observer.Observe('json', Json);
        ClearLastError();
        if TryPosition(MS, Pos) then
            Observer.Observe('pos_after_json', Format(Pos))
        else
            Observer.ObserveError('pos_after_json');
        Observer.Finish();
    end;
}
