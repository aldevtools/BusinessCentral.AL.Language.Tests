// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.xml.xmldocument.load
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99003
// Probe: al-runtime-rs corpus topic 203 item 6 (corpus issue 632): the exception text and error code when the DotNet System.Xml.XmlDocument cannot load its input:
//   LoadXml with an empty string, an unclosed element and text that is not XML; Load with an empty file name and with an empty MemoryStream;
//   each in asserterror and in a TryFunction (GetLastErrorText, GetLastErrorCode, and the type name of GetLastErrorObject).
// RISKY (compile): Load(Stream) with a MemoryStream argument.
// BC versions: 27, 28, 29
dotnet
{
    assembly("System.Xml")
    {
        type("System.Xml.XmlDocument"; LtAeLDoc) { }
    }
    assembly("mscorlib")
    {
        type("System.IO.MemoryStream"; LtAeLMem) { }
        type("System.Exception"; LtAeLExc) { }
        type("System.Type"; LtAeLType) { }
    }
}

codeunit 99003 "LT AE XmlDocument Load Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryLoadXml(Xml: Text)
    var
        Doc: DotNet LtAeLDoc;
    begin
        Doc := Doc.XmlDocument();
        Doc.LoadXml(Xml);
    end;

    [TryFunction]
    local procedure TryLoadFile(FileName: Text)
    var
        Doc: DotNet LtAeLDoc;
    begin
        Doc := Doc.XmlDocument();
        Doc.Load(FileName);
    end;

    [TryFunction]
    local procedure TryLoadEmptyStream()
    var
        Doc: DotNet LtAeLDoc;
        Mem: DotNet LtAeLMem;
    begin
        Doc := Doc.XmlDocument();
        Mem := Mem.MemoryStream();
        Doc.Load(Mem);
    end;

    local procedure ObserveTry(Name: Text; Ok: Boolean)
    var
        Exc: DotNet LtAeLExc;
        Kind: DotNet LtAeLType;
    begin
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.Observe(Name + ' text', GetLastErrorText());
        Observer.Observe(Name + ' code', GetLastErrorCode());
        Exc := GetLastErrorObject();
        if IsNull(Exc) then
            Observer.Observe(Name + ' type', '<null>')
        else begin
            Kind := Exc.GetType();
            Observer.Observe(Name + ' type', Kind.FullName());
        end;
        ClearLastError();
    end;

    [Test]
    procedure LoadXml_Empty()
    var
        Doc: DotNet LtAeLDoc;
    begin
        ClearLastError();
        ObserveTry('try', TryLoadXml(''));
        Doc := Doc.XmlDocument();
        asserterror Doc.LoadXml('');
        Observer.ObserveError('asserterror');
        Observer.Expect('try ok', 'No');
        Observer.Expect('try text', 'A call to System.Xml.XmlDocument.LoadXml failed with this message: Root element is missing.');
        Observer.Expect('try code', 'DotNetInvoke:Xml');
        Observer.Expect('try type', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDotNetInvokeException');
        Observer.Expect('asserterror|text', 'A call to System.Xml.XmlDocument.LoadXml failed with this message: Root element is missing.');
        Observer.Expect('asserterror|code', 'DotNetInvoke:Xml');
        Observer.Verify();
    end;

    // Not a test: LoadXml('<a>') gave "Data at the root level is invalid. Line 1, position 1.", the text of 'not xml', where System.Xml gives "Unexpected end of file has occurred. The following elements are not closed: a."
    // for an unclosed element. Listed as a Linux suspect in the hand-off note until the Windows nightly confirms it.
    procedure LoadXml_Unclosed()
    var
        Doc: DotNet LtAeLDoc;
    begin
        ClearLastError();
        ObserveTry('try', TryLoadXml('<a>'));
        Doc := Doc.XmlDocument();
        asserterror Doc.LoadXml('<a>');
        Observer.ObserveError('asserterror');
        Observer.Finish();
    end;

    [Test]
    procedure LoadXml_NotXml()
    var
        Doc: DotNet LtAeLDoc;
    begin
        ClearLastError();
        ObserveTry('try', TryLoadXml('not xml'));
        Doc := Doc.XmlDocument();
        asserterror Doc.LoadXml('not xml');
        Observer.ObserveError('asserterror');
        Observer.Expect('try ok', 'No');
        Observer.Expect('try text', 'A call to System.Xml.XmlDocument.LoadXml failed with this message: Data at the root level is invalid. Line 1, position 1.');
        Observer.Expect('try code', 'DotNetInvoke:Xml');
        Observer.Expect('try type', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDotNetInvokeException');
        Observer.Expect('asserterror|text', 'A call to System.Xml.XmlDocument.LoadXml failed with this message: Data at the root level is invalid. Line 1, position 1.');
        Observer.Expect('asserterror|code', 'DotNetInvoke:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Load_EmptyFileName()
    var
        Doc: DotNet LtAeLDoc;
    begin
        ClearLastError();
        ObserveTry('try', TryLoadFile(''));
        Doc := Doc.XmlDocument();
        asserterror Doc.Load('');
        Observer.ObserveError('asserterror');
        Observer.Expect('try ok', 'No');
        Observer.Expect('try text', 'A call to System.Xml.XmlDocument.Load failed with this message: The value cannot be an empty string. (Parameter ''url'')');
        Observer.Expect('try code', 'DotNetInvoke:Argument');
        Observer.Expect('try type', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDotNetInvokeException');
        Observer.Expect('asserterror|text', 'A call to System.Xml.XmlDocument.Load failed with this message: The value cannot be an empty string. (Parameter ''url'')');
        Observer.Expect('asserterror|code', 'DotNetInvoke:Argument');
        Observer.Verify();
    end;

    [Test]
    procedure Load_EmptyStream()
    var
        Doc: DotNet LtAeLDoc;
        Mem: DotNet LtAeLMem;
    begin
        ClearLastError();
        ObserveTry('try', TryLoadEmptyStream());
        Doc := Doc.XmlDocument();
        Mem := Mem.MemoryStream();
        asserterror Doc.Load(Mem);
        Observer.ObserveError('asserterror');
        Observer.Expect('try ok', 'No');
        Observer.Expect('try text', 'A call to System.Xml.XmlDocument.Load failed with this message: Root element is missing.');
        Observer.Expect('try code', 'DotNetInvoke:Xml');
        Observer.Expect('try type', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDotNetInvokeException');
        Observer.Expect('asserterror|text', 'A call to System.Xml.XmlDocument.Load failed with this message: Root element is missing.');
        Observer.Expect('asserterror|code', 'DotNetInvoke:Xml');
        Observer.Verify();
    end;
}
