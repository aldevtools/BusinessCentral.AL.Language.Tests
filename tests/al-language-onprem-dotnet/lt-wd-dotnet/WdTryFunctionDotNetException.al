// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors-with-tryfunctions
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 99340-99342
// Probe: written against al-runner issue 6305. A .NET exception inside a TryFunction and inside a codeunit run with Codeunit.Run, where the caller reads only the Boolean result:
//        new System.Uri('12345') (UriFormatException) as in the System Application Uri.IsValidUri, and XmlDocument.LoadXml('') (XmlException) as in XML DOM Management.
//        Also the last error text and code afterwards. Every value asserted below is what the BC service tier produced.
// BC versions: 27, 28, 29
dotnet
{
    assembly("System")
    {
        type("System.Uri"; LtWdUri) { }
    }
    assembly("System.Xml")
    {
        type("System.Xml.XmlDocument"; LtWdXmlDoc) { }
    }
}

codeunit 99340 "LT WD Uri Check"
{
    [TryFunction]
    procedure IsValidUri(UriString: Text)
    var
        LocalUri: DotNet LtWdUri;
    begin
        LocalUri := LocalUri.Uri(UriString);
    end;

    procedure ResolveUrl(Url: Text): Text
    begin
        if IsValidUri(Url) then
            exit(Url);
        exit('https://example.com/link?id=' + Url);
    end;
}

codeunit 99341 "LT WD Xml Reader"
{
    trigger OnRun()
    var
        XmlDoc: DotNet LtWdXmlDoc;
    begin
        XmlDoc := XmlDoc.XmlDocument();
        XmlDoc.LoadXml('');
    end;
}

codeunit 99342 "LT WD TryFunction DotNet Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WD_TryFunction_DotNetException_BooleanOnly()
    var
        Observer: Codeunit "Probe Observer";
        UriCheck: Codeunit "LT WD Uri Check";
    begin
        Observer.Observe('valid', Format(UriCheck.IsValidUri('https://example.com/a')));
        Observer.Observe('not a uri', Format(UriCheck.IsValidUri('12345')));
        Observer.Observe('ResolveUrl valid', UriCheck.ResolveUrl('https://example.com/a'));
        Observer.Observe('ResolveUrl fallback', UriCheck.ResolveUrl('12345'));
        Observer.Finish();
    end;

    [Test]
    procedure WD_TryFunction_DotNetException_LastError()
    var
        Observer: Codeunit "Probe Observer";
        UriCheck: Codeunit "LT WD Uri Check";
    begin
        ClearLastError();
        Observer.Observe('not a uri', Format(UriCheck.IsValidUri('12345')));
        Observer.Observe('last error text', GetLastErrorText());
        Observer.Observe('last error code', GetLastErrorCode());
        Observer.Finish();
    end;

    [Test]
    procedure WD_CodeunitRun_DotNetException_BooleanOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Codeunit.Run', Format(Codeunit.Run(Codeunit::"LT WD Xml Reader")));
        Observer.Observe('negated', Format(not Codeunit.Run(Codeunit::"LT WD Xml Reader")));
        Observer.Finish();
    end;

    [Test]
    procedure WD_CodeunitRun_DotNetException_LastError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('Codeunit.Run', Format(Codeunit.Run(Codeunit::"LT WD Xml Reader")));
        Observer.Observe('last error text', GetLastErrorText());
        Observer.Observe('last error code', GetLastErrorCode());
        Observer.Finish();
    end;
}
