// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 90420
// Probe: observation form (Finish), values to be converted to Expect after a real-BC run
// Facts: Clear(x) on XmlElement / XmlNode / XmlDocument variables: what the cleared variable reads as, and whether a second variable that holds the same node still sees it
// BC versions: 27, 28, 29
codeunit 90420 "LT UL Clear Xml Ref"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryName(E: XmlElement; var Result: Text)
    begin
        Result := E.Name();
    end;

    [TryFunction]
    local procedure TryNodeIsElement(N: XmlNode; var Result: Boolean)
    begin
        Result := N.IsXmlElement();
    end;

    [TryFunction]
    local procedure TryNodeAsElementName(N: XmlNode; var Result: Text)
    var
        E: XmlElement;
    begin
        E := N.AsXmlElement();
        Result := E.Name();
    end;

    [TryFunction]
    local procedure TryDocRoot(D: XmlDocument; var Result: Text)
    var
        R: XmlElement;
    begin
        D.GetRoot(R);
        Result := R.Name();
    end;

    local procedure Probe(Observer: Codeunit "Probe Observer"; Label: Text; E: XmlElement)
    var
        Txt: Text;
    begin
        if TryName(E, Txt) then
            Observer.Observe(Label + '|name', Txt)
        else
            Observer.ObserveError(Label + '|name');
    end;

    [Test]
    procedure ClearXmlElement_SecondVariable()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
        Alias: XmlElement;
        Doc: XmlDocument;
        Root: XmlElement;
        Child: XmlElement;
        Txt: Text;
    begin
        Doc := XmlDocument.Create();
        Root := XmlElement.Create('root');
        Doc.Add(Root);
        Child := XmlElement.Create('child');
        Root.Add(Child);
        E := Child;
        Alias := Child;
        Clear(E);
        Probe(Observer, 'cleared element', E);
        Probe(Observer, 'alias element', Alias);
        Probe(Observer, 'original variable', Child);
        Doc.GetRoot(Root);
        Observer.Observe('root text after clear', Root.AsXmlNode().AsXmlElement().InnerXml());
        Observer.Observe('child still in doc', Format(Root.GetChildElements().Count()));
        E := XmlElement.Create('again');
        Probe(Observer, 'cleared element reassigned', E);
        Observer.Finish();
    end;

    [Test]
    procedure ClearXmlElement_NeverAssigned()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
    begin
        Probe(Observer, 'never assigned', E);
        Clear(E);
        Probe(Observer, 'cleared never assigned', E);
        Observer.Finish();
    end;

    [Test]
    procedure ClearXmlNode_SecondVariable()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
        N: XmlNode;
        Alias: XmlNode;
        B: Boolean;
        Txt: Text;
    begin
        E := XmlElement.Create('elem');
        N := E.AsXmlNode();
        Alias := N;
        Clear(N);
        if TryNodeIsElement(N, B) then
            Observer.Observe('cleared node|is element', Format(B))
        else
            Observer.ObserveError('cleared node|is element');
        if TryNodeAsElementName(N, Txt) then
            Observer.Observe('cleared node|as element name', Txt)
        else
            Observer.ObserveError('cleared node|as element name');
        if TryNodeIsElement(Alias, B) then
            Observer.Observe('alias node|is element', Format(B))
        else
            Observer.ObserveError('alias node|is element');
        if TryNodeAsElementName(Alias, Txt) then
            Observer.Observe('alias node|as element name', Txt)
        else
            Observer.ObserveError('alias node|as element name');
        Observer.Observe('source element name', E.Name());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryWrite(D: XmlDocument; var Result: Text)
    begin
        D.WriteTo(Result);
    end;

    [TryFunction]
    local procedure TryAddFresh(D: XmlDocument)
    begin
        D.Add(XmlElement.Create('fresh'));
    end;

    local procedure Write(Observer: Codeunit "Probe Observer"; Label: Text; D: XmlDocument)
    var
        Out: Text;
    begin
        if TryWrite(D, Out) then
            Observer.Observe(Label + '|writeto', Out)
        else
            Observer.ObserveError(Label + '|writeto');
    end;

    [Test]
    procedure ClearXmlDocument_SecondVariable()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        Alias: XmlDocument;
        Txt: Text;
    begin
        D := XmlDocument.Create();
        D.Add(XmlElement.Create('root'));
        Alias := D;
        Clear(D);
        if TryDocRoot(D, Txt) then
            Observer.Observe('cleared doc|root', Txt)
        else
            Observer.ObserveError('cleared doc|root');
        if TryDocRoot(Alias, Txt) then
            Observer.Observe('alias doc|root', Txt)
        else
            Observer.ObserveError('alias doc|root');
        Write(Observer, 'cleared doc', D);
        Write(Observer, 'alias doc', Alias);
        if TryAddFresh(D) then
            Observer.Observe('cleared doc|add', 'ok')
        else
            Observer.ObserveError('cleared doc|add');
        Write(Observer, 'cleared doc after add', D);
        Write(Observer, 'alias doc after add', Alias);
        Observer.Finish();
    end;
}
