// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlelement/xmlelement-create-method
// Scope: in-scope. XmlElement.Create and XmlAttribute.Create with names that are not plain XML names (al-runner issue 7964, item 1):
//   an empty name, '1.0', '9abc', a name with two colons ('urn:Example-Namespace:TEST'), one prefix ('p:name'), a leading or trailing
//   colon, a space inside the name ('name with space'), a leading dot, and valid plain names as control; with and without a namespace URI.
// Fixtures used: Probe Observer (69160); self-contained codeunit 71896.
// Probe: written for al-runner issue 7964, observed on BC 27.5, 28.5 and 29.0. Every literal asserted below is what BC produced.
// Facts: <case> is either 'ok name=<Name> local=<LocalName> ns=<NamespaceUri> xml=<WriteTo>' after a call that did not fail,
//   or <case>|text and <case>|code (GetLastErrorText and GetLastErrorCode) after the [TryFunction] around the call returned false.
// Result (same on 27.5, 28.5, 29.0): an empty name fails with code Argument and the text of a NavNCLArgumentException; every other
//   invalid name fails with code Xml:Xml and the XmlException text quoted with position ('1.0', '9abc', '.x', ':x': 'Name cannot begin
//   with ...'; 'urn:Example-Namespace:TEST', 'p:name', 'x:', 'name with space': 'The ... character ... cannot be included in a name.').
//   A prefix ('p:name') is refused even with a namespace URI. Valid names succeed; Element.Create(name, ns).Name() is ':name';
//   Attribute.Create(name, ns, v) gets the generated prefix p0. XmlElement and XmlAttribute behave the same.
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
        Observer.Expect('empty|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty|code', 'Argument');
        Observer.Expect('one_dot_zero|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''1'' character, hexadecimal value 0x31.'' at line 0 and position 1.');
        Observer.Expect('one_dot_zero|code', 'Xml:Xml');
        Observer.Expect('two_colons|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 4.');
        Observer.Expect('two_colons|code', 'Xml:Xml');
        Observer.Expect('plain_control', 'ok name=name local=name ns= xml=<name />');
        Observer.Verify();
    end;

    [Test]
    procedure Element_Create_NeighborNames()
    begin
        Element('digit_first', '9abc');
        Element('one_prefix', 'p:name');
        Element('space_inside', 'name with space');
        Observer.Expect('digit_first|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''9'' character, hexadecimal value 0x39.'' at line 0 and position 1.');
        Observer.Expect('digit_first|code', 'Xml:Xml');
        Observer.Expect('one_prefix|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('one_prefix|code', 'Xml:Xml');
        Observer.Expect('space_inside|text', 'The following exception was encountered when processing XML data: ''The '' '' character, hexadecimal value 0x20, cannot be included in a name.'' at line 0 and position 5.');
        Observer.Expect('space_inside|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Element_Create_ColonAndDotNames()
    begin
        Element('dot_first', '.a');
        Element('colon_first', ':a');
        Element('colon_last', 'a:');
        Element('dots_dashes_control', 'a.b-c_1');
        Observer.Expect('dot_first|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''.'' character, hexadecimal value 0x2E.'' at line 0 and position 1.');
        Observer.Expect('dot_first|code', 'Xml:Xml');
        Observer.Expect('colon_first|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the '':'' character, hexadecimal value 0x3A.'' at line 0 and position 1.');
        Observer.Expect('colon_first|code', 'Xml:Xml');
        Observer.Expect('colon_last|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('colon_last|code', 'Xml:Xml');
        Observer.Expect('dots_dashes_control', 'ok name=a.b-c_1 local=a.b-c_1 ns= xml=<a.b-c_1 />');
        Observer.Verify();
    end;

    [Test]
    procedure Element_Create_WithNamespace()
    begin
        ElementNs('empty_ns', '', 'urn:x');
        ElementNs('one_dot_zero_ns', '1.0', 'urn:x');
        ElementNs('two_colons_ns', 'urn:Example-Namespace:TEST', 'urn:x');
        Observer.Expect('empty_ns|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty_ns|code', 'Argument');
        Observer.Expect('one_dot_zero_ns|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''1'' character, hexadecimal value 0x31.'' at line 0 and position 1.');
        Observer.Expect('one_dot_zero_ns|code', 'Xml:Xml');
        Observer.Expect('two_colons_ns|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 4.');
        Observer.Expect('two_colons_ns|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Element_Create_WithNamespace_Prefix()
    begin
        ElementNs('one_prefix_ns', 'p:name', 'urn:x');
        ElementNs('one_prefix_empty_ns', 'p:name', '');
        ElementNs('space_inside_ns', 'name with space', 'urn:x');
        ElementNs('plain_ns_control', 'name', 'urn:x');
        Observer.Expect('one_prefix_ns|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('one_prefix_ns|code', 'Xml:Xml');
        Observer.Expect('one_prefix_empty_ns|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('one_prefix_empty_ns|code', 'Xml:Xml');
        Observer.Expect('space_inside_ns|text', 'The following exception was encountered when processing XML data: ''The '' '' character, hexadecimal value 0x20, cannot be included in a name.'' at line 0 and position 5.');
        Observer.Expect('space_inside_ns|code', 'Xml:Xml');
        Observer.Expect('plain_ns_control', 'ok name=:name local=name ns=urn:x xml=<name xmlns="urn:x" />');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Create_Names()
    begin
        Attribute('empty', '');
        Attribute('one_dot_zero', '1.0');
        Attribute('two_colons', 'urn:Example-Namespace:TEST');
        Observer.Expect('empty|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty|code', 'Argument');
        Observer.Expect('one_dot_zero|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''1'' character, hexadecimal value 0x31.'' at line 0 and position 1.');
        Observer.Expect('one_dot_zero|code', 'Xml:Xml');
        Observer.Expect('two_colons|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 4.');
        Observer.Expect('two_colons|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Create_NeighborNames()
    begin
        Attribute('digit_first', '9abc');
        Attribute('one_prefix', 'p:name');
        Attribute('space_inside', 'name with space');
        Attribute('plain_control', 'name');
        Observer.Expect('digit_first|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''9'' character, hexadecimal value 0x39.'' at line 0 and position 1.');
        Observer.Expect('digit_first|code', 'Xml:Xml');
        Observer.Expect('one_prefix|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('one_prefix|code', 'Xml:Xml');
        Observer.Expect('space_inside|text', 'The following exception was encountered when processing XML data: ''The '' '' character, hexadecimal value 0x20, cannot be included in a name.'' at line 0 and position 5.');
        Observer.Expect('space_inside|code', 'Xml:Xml');
        Observer.Expect('plain_control', 'ok name=name local=name ns= xml=name="v"');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Create_WithNamespace()
    begin
        AttributeNs('empty_ns', '', 'urn:x');
        AttributeNs('one_dot_zero_ns', '1.0', 'urn:x');
        AttributeNs('two_colons_ns', 'urn:Example-Namespace:TEST', 'urn:x');
        Observer.Expect('empty_ns|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty_ns|code', 'Argument');
        Observer.Expect('one_dot_zero_ns|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''1'' character, hexadecimal value 0x31.'' at line 0 and position 1.');
        Observer.Expect('one_dot_zero_ns|code', 'Xml:Xml');
        Observer.Expect('two_colons_ns|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 4.');
        Observer.Expect('two_colons_ns|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Create_WithNamespace_Prefix()
    begin
        AttributeNs('one_prefix_ns', 'p:name', 'urn:x');
        AttributeNs('space_inside_ns', 'name with space', 'urn:x');
        AttributeNs('plain_ns_control', 'name', 'urn:x');
        Observer.Expect('one_prefix_ns|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('one_prefix_ns|code', 'Xml:Xml');
        Observer.Expect('space_inside_ns|text', 'The following exception was encountered when processing XML data: ''The '' '' character, hexadecimal value 0x20, cannot be included in a name.'' at line 0 and position 5.');
        Observer.Expect('space_inside_ns|code', 'Xml:Xml');
        Observer.Expect('plain_ns_control', 'ok name=p0:name local=name ns=urn:x xml=p0:name="v"');
        Observer.Verify();
    end;
}
