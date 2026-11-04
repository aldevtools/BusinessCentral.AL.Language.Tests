// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-readfrom-method-text-xmlreadoptions-xmldocument
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72553
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "BigText.Read, Media.ImportStream with a file name, XmlReadOptions (issue 22)" - `XmlDocument.ReadFrom(Text, XmlReadOptions, var XmlDocument)`
// Facts: ReadFrom with default options, PreserveWhitespace(true) and (false), then WriteTo
// BC versions: 29 (27 and 28 by CI)

codeunit 72553 "LT PnE Xml Read Options"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Written(Doc: XmlDocument): Text
    var
        R: Text;
    begin
        Doc.WriteTo(R);
        exit(R);
    end;

    [Test]
    procedure ReadFrom_InnerWhitespace()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Opt: XmlReadOptions;
        Src: Text;
    begin
        Src := '<root>  <a/>  </root>';
        Observer.Observe('noOptions', Format(XmlDocument.ReadFrom(Src, Doc)) + '|' + Written(Doc));
        Observer.Observe('defaultOptions', Format(XmlDocument.ReadFrom(Src, Opt, Doc)) + '|' + Written(Doc));
        Opt.PreserveWhitespace(true);
        Observer.Observe('preserveTrue', Format(XmlDocument.ReadFrom(Src, Opt, Doc)) + '|' + Written(Doc));
        Opt.PreserveWhitespace(false);
        Observer.Observe('preserveFalse', Format(XmlDocument.ReadFrom(Src, Opt, Doc)) + '|' + Written(Doc));
        Observer.Expect('noOptions', 'Yes|<?xml version="1.0" encoding="utf-16"?>\r\n<root>  <a />  </root>');
        Observer.Expect('defaultOptions', 'Yes|<?xml version="1.0" encoding="utf-16"?>\r\n<root>  <a />  </root>');
        Observer.Expect('preserveTrue', 'Yes|<?xml version="1.0" encoding="utf-16"?>\r\n<root>  <a />  </root>');
        Observer.Expect('preserveFalse', 'Yes|<?xml version="1.0" encoding="utf-16"?>\r\n<root>  <a />  </root>');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_OuterWhitespace()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Opt: XmlReadOptions;
        Src: Text;
    begin
        Src := ' <root/> ';
        Observer.Observe('noOptions', Format(XmlDocument.ReadFrom(Src, Doc)) + '|' + Written(Doc));
        Observer.Observe('defaultOptions', Format(XmlDocument.ReadFrom(Src, Opt, Doc)) + '|' + Written(Doc));
        Opt.PreserveWhitespace(true);
        Observer.Observe('preserveTrue', Format(XmlDocument.ReadFrom(Src, Opt, Doc)) + '|' + Written(Doc));
        Opt.PreserveWhitespace(false);
        Observer.Observe('preserveFalse', Format(XmlDocument.ReadFrom(Src, Opt, Doc)) + '|' + Written(Doc));
        Observer.Expect('noOptions', 'Yes|<?xml version="1.0" encoding="utf-16"?> <root /> ');
        Observer.Expect('defaultOptions', 'Yes|<?xml version="1.0" encoding="utf-16"?> <root /> ');
        Observer.Expect('preserveTrue', 'Yes|<?xml version="1.0" encoding="utf-16"?> <root /> ');
        Observer.Expect('preserveFalse', 'Yes|<?xml version="1.0" encoding="utf-16"?> <root /> ');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_NewlinesAndText()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Opt: XmlReadOptions;
        Src: Text;
        Lf: Text[1];
    begin
        Lf[1] := 10;
        Src := '<root>' + Lf + Lf + '<a> x </a>' + Lf + '</root>';
        Observer.Observe('noOptions', Format(XmlDocument.ReadFrom(Src, Doc)) + '|' + Written(Doc));
        Observer.Observe('defaultOptions', Format(XmlDocument.ReadFrom(Src, Opt, Doc)) + '|' + Written(Doc));
        Opt.PreserveWhitespace(true);
        Observer.Observe('preserveTrue', Format(XmlDocument.ReadFrom(Src, Opt, Doc)) + '|' + Written(Doc));
        Opt.PreserveWhitespace(false);
        Observer.Observe('preserveFalse', Format(XmlDocument.ReadFrom(Src, Opt, Doc)) + '|' + Written(Doc));
        Observer.Expect('noOptions', 'Yes|<?xml version="1.0" encoding="utf-16"?>\r\n<root>\r\n\r\n<a> x </a>\r\n</root>');
        Observer.Expect('defaultOptions', 'Yes|<?xml version="1.0" encoding="utf-16"?>\r\n<root>\r\n\r\n<a> x </a>\r\n</root>');
        Observer.Expect('preserveTrue', 'Yes|<?xml version="1.0" encoding="utf-16"?>\r\n<root>\r\n\r\n<a> x </a>\r\n</root>');
        Observer.Expect('preserveFalse', 'Yes|<?xml version="1.0" encoding="utf-16"?>\r\n<root>\r\n\r\n<a> x </a>\r\n</root>');
        Observer.Verify();
    end;
}
