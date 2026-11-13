// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlelement/xmlelement-create-method
// Scope: in-scope. XmlElement.Create and XmlAttribute.Create with names that are not plain XML names (al-runner issue 7964, item 1):
//   an empty name, '1.0', '9abc', a name with two colons ('urn:Example-Namespace:TEST'), one prefix ('p:name'), a leading or trailing
//   colon, a space inside the name ('name with space'), a leading dot, and valid plain names as control; with and without a namespace URI.
// Fixtures used: Probe Observer (69160); self-contained codeunit 71896.
// Probe: written for al-runner issue 7964, observed on BC 27.5, 28.5 and 29.0. Every literal asserted below is what BC produced.
// Facts: <case> is either 'ok name=<Name> local=<LocalName> ns=<NamespaceUri> xml=<WriteTo>' after a call that did not fail,
//   or <case>|text and <case>|code (GetLastErrorText and GetLastErrorCode) after the [TryFunction] around the call returned false.
// BC versions: 27, 28, 29

codeunit 71896 "LT XmN Name Validity"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryElement(Name: Text; var Result: Text)
    var
        E: XmlElement;
        S: Text;
    begin
        E := XmlElement.Create(Name);
        E.WriteTo(S);
        Result := 'ok name=' + E.Name() + ' local=' + E.LocalName() + ' ns=' + E.NamespaceUri() + ' xml=' + S;
    end;

    [TryFunction]
    local procedure TryElementNs(Name: Text; Ns: Text; var Result: Text)
    var
        E: XmlElement;
        S: Text;
    begin
        E := XmlElement.Create(Name, Ns);
        E.WriteTo(S);
        Result := 'ok name=' + E.Name() + ' local=' + E.LocalName() + ' ns=' + E.NamespaceUri() + ' xml=' + S;
    end;

    [TryFunction]
    local procedure TryAttribute(Name: Text; var Result: Text)
    var
        A: XmlAttribute;
        S: Text;
    begin
        A := XmlAttribute.Create(Name, 'v');
        A.WriteTo(S);
        Result := 'ok name=' + A.Name() + ' local=' + A.LocalName() + ' ns=' + A.NamespaceUri() + ' xml=' + S;
    end;

    [TryFunction]
    local procedure TryAttributeNs(Name: Text; Ns: Text; var Result: Text)
    var
        A: XmlAttribute;
        S: Text;
    begin
        A := XmlAttribute.Create(Name, Ns, 'v');
        A.WriteTo(S);
        Result := 'ok name=' + A.Name() + ' local=' + A.LocalName() + ' ns=' + A.NamespaceUri() + ' xml=' + S;
    end;

    local procedure Element(CaseName: Text; Name: Text)
    var
        R: Text;
    begin
        ClearLastError();
        if TryElement(Name, R) then
            Observer.Observe(CaseName, R)
        else
            Observer.ObserveError(CaseName);
    end;

    local procedure ElementNs(CaseName: Text; Name: Text; Ns: Text)
    var
        R: Text;
    begin
        ClearLastError();
        if TryElementNs(Name, Ns, R) then
            Observer.Observe(CaseName, R)
        else
            Observer.ObserveError(CaseName);
    end;

    local procedure Attribute(CaseName: Text; Name: Text)
    var
        R: Text;
    begin
        ClearLastError();
        if TryAttribute(Name, R) then
            Observer.Observe(CaseName, R)
        else
            Observer.ObserveError(CaseName);
    end;

    local procedure AttributeNs(CaseName: Text; Name: Text; Ns: Text)
    var
        R: Text;
    begin
        ClearLastError();
        if TryAttributeNs(Name, Ns, R) then
            Observer.Observe(CaseName, R)
        else
            Observer.ObserveError(CaseName);
    end;

    [Test]
    procedure Element_Create_IssueNames()
    begin
        Element('empty', '');
        Element('one_dot_zero', '1.0');
        Element('two_colons', 'urn:Example-Namespace:TEST');
        Element('plain_control', 'name');
        Observer.Finish();
    end;

    [Test]
    procedure Element_Create_NeighborNames()
    begin
        Element('digit_first', '9abc');
        Element('one_prefix', 'p:name');
        Element('space_inside', 'name with space');
        Observer.Finish();
    end;

    [Test]
    procedure Element_Create_ColonAndDotNames()
    begin
        Element('dot_first', '.a');
        Element('colon_first', ':a');
        Element('colon_last', 'a:');
        Element('dots_dashes_control', 'a.b-c_1');
        Observer.Finish();
    end;

    [Test]
    procedure Element_Create_WithNamespace()
    begin
        ElementNs('empty_ns', '', 'urn:x');
        ElementNs('one_dot_zero_ns', '1.0', 'urn:x');
        ElementNs('two_colons_ns', 'urn:Example-Namespace:TEST', 'urn:x');
        Observer.Finish();
    end;

    [Test]
    procedure Element_Create_WithNamespace_Prefix()
    begin
        ElementNs('one_prefix_ns', 'p:name', 'urn:x');
        ElementNs('one_prefix_empty_ns', 'p:name', '');
        ElementNs('space_inside_ns', 'name with space', 'urn:x');
        ElementNs('plain_ns_control', 'name', 'urn:x');
        Observer.Finish();
    end;

    [Test]
    procedure Attribute_Create_Names()
    begin
        Attribute('empty', '');
        Attribute('one_dot_zero', '1.0');
        Attribute('two_colons', 'urn:Example-Namespace:TEST');
        Observer.Finish();
    end;

    [Test]
    procedure Attribute_Create_NeighborNames()
    begin
        Attribute('digit_first', '9abc');
        Attribute('one_prefix', 'p:name');
        Attribute('space_inside', 'name with space');
        Attribute('plain_control', 'name');
        Observer.Finish();
    end;

    [Test]
    procedure Attribute_Create_WithNamespace()
    begin
        AttributeNs('empty_ns', '', 'urn:x');
        AttributeNs('one_dot_zero_ns', '1.0', 'urn:x');
        AttributeNs('two_colons_ns', 'urn:Example-Namespace:TEST', 'urn:x');
        Observer.Finish();
    end;

    [Test]
    procedure Attribute_Create_WithNamespace_Prefix()
    begin
        AttributeNs('one_prefix_ns', 'p:name', 'urn:x');
        AttributeNs('space_inside_ns', 'name with space', 'urn:x');
        AttributeNs('plain_ns_control', 'name', 'urn:x');
        Observer.Finish();
    end;
}
