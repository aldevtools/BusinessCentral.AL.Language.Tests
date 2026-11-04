// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74019
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: Clear on HttpRequestMessage, HttpContent, XmlDocument, FilterPageBuilder
// BC versions: 29
// Tag: P95

codeunit 74019 "LT P95 Clear Http Xml"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearHttpXml()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        Cnt: HttpContent;
        Txt: Text;
        Xd: XmlDocument;
        Xe: XmlElement;
        FP: FilterPageBuilder;
    begin
        Req.Method := 'POST';
        Req.SetRequestUri('http://localhost/p95');
        Clear(Req);
        Observer.Observe('request', '[' + Req.Method + '][' + Req.GetRequestUri() + ']');
        Cnt.WriteFrom('abc');
        Clear(Cnt);
        Cnt.ReadAs(Txt);
        Observer.Observe('content', '[' + Txt + ']');
        Xd := XmlDocument.Create();
        Xd.Add(XmlElement.Create('root'));
        Clear(Xd);
        Observer.Observe('xml_has_root', Format(Xd.GetRoot(Xe)));
        FP.AddTable('Rows', 2000000038);
        Clear(FP);
        Observer.Observe('filterpage_count', Format(FP.Count()));

        Observer.Expect('request', '[GET][]');
        Observer.Expect('content', '[]');
        Observer.Expect('xml_has_root', 'No');
        Observer.Expect('filterpage_count', '0');
        Observer.Verify();
    end;

}
