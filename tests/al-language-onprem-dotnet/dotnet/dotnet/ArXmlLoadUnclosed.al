// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.xml.xmldocument.loadxml
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99200
// Probe: corpus issue 654 item 2: the error text and code when the DotNet System.Xml.XmlDocument.LoadXml gets an unclosed element ('<a>') and two
//   nested unclosed elements ('<a><b>'), in asserterror and in a TryFunction (GetLastErrorText, GetLastErrorCode, type of GetLastErrorObject).
//   Writer AE's probe LoadXml_Unclosed (lt-ae-dotnet/AeXmlDocumentLoadErrors.al) saw the '<a>' text on Linux; the Windows check of corpus
//   issue 654 gave the same text and code, so it is BC behavior. Every literal below is what the BC service tier produced on the corpus CI matrix.
// BC versions: 27, 28, 29
dotnet
{
    assembly("System.Xml")
    {
        type("System.Xml.XmlDocument"; LtArXDoc) { }
    }
    assembly("mscorlib")
    {
        type("System.Exception"; LtArXExc) { }
        type("System.Type"; LtArXType) { }
    }
}

codeunit 99200 "LT AR XmlDocument Unclosed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryLoadXml(Xml: Text)
    var
        Doc: DotNet LtArXDoc;
    begin
        Doc := Doc.XmlDocument();
        Doc.LoadXml(Xml);
    end;

    local procedure ObserveTry(Name: Text; Ok: Boolean)
    var
        Exc: DotNet LtArXExc;
        Kind: DotNet LtArXType;
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
    procedure LoadXml_UnclosedElement()
    var
        Doc: DotNet LtArXDoc;
    begin
        ClearLastError();
        ObserveTry('try', TryLoadXml('<a>'));
        Doc := Doc.XmlDocument();
        asserterror Doc.LoadXml('<a>');
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
    procedure LoadXml_TwoUnclosedElements()
    var
        Doc: DotNet LtArXDoc;
    begin
        ClearLastError();
        ObserveTry('try', TryLoadXml('<a><b>'));
        Doc := Doc.XmlDocument();
        asserterror Doc.LoadXml('<a><b>');
        Observer.ObserveError('asserterror');
        Observer.Expect('try ok', 'No');
        Observer.Expect('try text', 'A call to System.Xml.XmlDocument.LoadXml failed with this message: Unexpected end of file has occurred. The following elements are not closed: b, a. Line 1, position 7.');
        Observer.Expect('try code', 'DotNetInvoke:Xml');
        Observer.Expect('try type', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDotNetInvokeException');
        Observer.Expect('asserterror|text', 'A call to System.Xml.XmlDocument.LoadXml failed with this message: Unexpected end of file has occurred. The following elements are not closed: b, a. Line 1, position 7.');
        Observer.Expect('asserterror|code', 'DotNetInvoke:Xml');
        Observer.Verify();
    end;
}
