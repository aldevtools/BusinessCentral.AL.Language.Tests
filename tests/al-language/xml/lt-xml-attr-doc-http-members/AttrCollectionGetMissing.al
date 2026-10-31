// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlattributecollection/xmlattributecollection-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own test codeunit 91362
// Probe: observe probe (writer Y7, 2026-10-30, asked by an al-runtime-rs runtime agent); every literal asserted below is what the BC service tier produced
//   (SaaS sandbox BC 29 first, then the corpus CI legs).
// Facts: XmlAttributeCollection.Get(Name, NamespaceUri, Attr) with an empty namespace when the attribute is missing, when it exists only in a namespace, and
//   with a namespace when it exists only without one: the Boolean result, what the Attr variable holds afterwards (a fresh one and one that already held an
//   attribute), and the same calls as statements (result unused): no error or the error text and code. xml/XmlAttributes.al:187 pins the two-argument Get
//   of a missing attribute used as an expression.
// BC versions: 27, 28, 29

codeunit 91362 "LT Y7 Xml Attr Get Missing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Root(var E: XmlElement)
    var
        Doc: XmlDocument;
    begin
        XmlDocument.ReadFrom('<root a="1" xmlns:p="urn:p" p:b="2" />', Doc);
        Doc.GetRoot(E);
    end;

    [TryFunction]
    local procedure TryShow(A: XmlAttribute; var Shown: Text)
    begin
        Shown := A.Name() + '=' + A.Value();
    end;

    local procedure Show(A: XmlAttribute): Text
    var
        Shown: Text;
    begin
        if TryShow(A, Shown) then
            exit(Shown);
        Shown := 'E[' + CopyStr(GetLastErrorText(), 1, 120) + '|' + GetLastErrorCode() + ']';
        ClearLastError();
        exit(Shown);
    end;

    [TryFunction]
    local procedure TryGetStatement3(Attrs: XmlAttributeCollection; Name: Text; Ns: Text; var A: XmlAttribute)
    begin
        Attrs.Get(Name, Ns, A);
    end;

    [TryFunction]
    local procedure TryGetStatement2(Attrs: XmlAttributeCollection; Name: Text; var A: XmlAttribute)
    begin
        Attrs.Get(Name, A);
    end;

    local procedure Statement3(var Observer: Codeunit "Probe Observer"; ObsKey: Text; Attrs: XmlAttributeCollection; Name: Text; Ns: Text)
    var
        A: XmlAttribute;
    begin
        ClearLastError();
        if TryGetStatement3(Attrs, Name, Ns, A) then
            Observer.Observe(ObsKey, 'ok|' + Show(A))
        else begin
            Observer.Observe(ObsKey, 'E[' + CopyStr(GetLastErrorText(), 1, 160) + '|' + GetLastErrorCode() + ']');
            ClearLastError();
        end;
    end;

    [Test]
    procedure Y7_AttrGet_EmptyNamespace_Expression()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
        Attrs: XmlAttributeCollection;
        Fresh: XmlAttribute;
        Held: XmlAttribute;
        Present: XmlAttribute;
    begin
        Root(E);
        Attrs := E.Attributes();
        Observer.Observe('missing, empty ns', Format(Attrs.Get('zz', '', Fresh)));
        Observer.Observe('missing, fresh attr after', Show(Fresh));
        Attrs.Get('a', Held);
        Observer.Observe('missing, held attr', Format(Attrs.Get('zz', '', Held)));
        Observer.Observe('missing, held attr after', Show(Held));
        Observer.Observe('present, empty ns', Format(Attrs.Get('a', '', Present)));
        Observer.Observe('present, empty ns attr', Show(Present));
        Clear(Present);
        Observer.Observe('only in ns, empty ns', Format(Attrs.Get('b', '', Present)));
        Observer.Observe('only in ns, attr after', Show(Present));
        Clear(Present);
        Observer.Observe('only in ns, its ns', Format(Attrs.Get('b', 'urn:p', Present)));
        Observer.Observe('only in ns, its ns attr', Show(Present));
        Clear(Present);
        Observer.Observe('no ns, asked with a ns', Format(Attrs.Get('a', 'urn:p', Present)));
        Observer.Observe('no ns, asked with a ns attr', Show(Present));
        Observer.Observe('missing, other ns', Format(Attrs.Get('zz', 'urn:x', Present)));
        Observer.Expect('missing, empty ns', 'No');
        Observer.Expect('missing, fresh attr after', 'E[Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute variable not initialized.|NotInitialized]');
        Observer.Expect('missing, held attr', 'No');
        Observer.Expect('missing, held attr after', 'a=1');
        Observer.Expect('present, empty ns', 'Yes');
        Observer.Expect('present, empty ns attr', 'a=1');
        Observer.Expect('only in ns, empty ns', 'No');
        Observer.Expect('only in ns, attr after', 'E[Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute variable not initialized.|NotInitialized]');
        Observer.Expect('only in ns, its ns', 'Yes');
        Observer.Expect('only in ns, its ns attr', 'p:b=2');
        Observer.Expect('no ns, asked with a ns', 'No');
        Observer.Expect('no ns, asked with a ns attr', 'E[Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute variable not initialized.|NotInitialized]');
        Observer.Expect('missing, other ns', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Y7_AttrGet_EmptyNamespace_Statement()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
        Attrs: XmlAttributeCollection;
        A: XmlAttribute;
    begin
        Root(E);
        Attrs := E.Attributes();
        Statement3(Observer, 'missing, empty ns', Attrs, 'zz', '');
        Statement3(Observer, 'present, empty ns', Attrs, 'a', '');
        Statement3(Observer, 'only in ns, empty ns', Attrs, 'b', '');
        Statement3(Observer, 'missing, other ns', Attrs, 'zz', 'urn:x');
        ClearLastError();
        if TryGetStatement2(Attrs, 'zz', A) then
            Observer.Observe('missing, two arguments', 'ok|' + Show(A))
        else
            Observer.Observe('missing, two arguments', 'E[' + CopyStr(GetLastErrorText(), 1, 160) + '|' + GetLastErrorCode() + ']');
        ClearLastError();
        Observer.Expect('missing, empty ns', 'E[The XML node with the name ''{}zz'' could not be found.|XmlNodeNotFound]');
        Observer.Expect('present, empty ns', 'ok|a=1');
        Observer.Expect('only in ns, empty ns', 'E[The XML node with the name ''{}b'' could not be found.|XmlNodeNotFound]');
        Observer.Expect('missing, other ns', 'E[The XML node with the name ''{urn:x}zz'' could not be found.|XmlNodeNotFound]');
        Observer.Expect('missing, two arguments', 'E[The XML node with the name ''zz'' could not be found.|XmlNodeNotFound]');
        Observer.Verify();
    end;
}
