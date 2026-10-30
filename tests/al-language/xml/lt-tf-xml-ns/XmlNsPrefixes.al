// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlelement/xmlelement-getprefixofnamespace-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 67080
// Corpus issue (al-runner, XML namespace prefixes): XmlElement.GetPrefixOfNamespace / GetNamespaceOfPrefix for namespaces that are not declared,
// where XmlAttribute.CreateNamespaceDeclaration raises for an empty prefix or namespace (in the Create call itself, before any Add), and
// how XmlAttribute.Create with a namespace numbers the prefix (p0 detached, p1... on the element).
// Probe: observed on the BC 29 SaaS sandbox through the test runner hub (2026-10-30); every literal asserted below is what it produced. Other majors are checked by the CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 67080 "LT TF Xml Ns Prefixes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Load(Xml: Text; var Doc: XmlDocument)
    begin
        XmlDocument.ReadFrom(Xml, Doc);
    end;

    [TryFunction]
    local procedure TryCreateDecl(PrefixText: Text; Ns: Text; var Attr: XmlAttribute)
    begin
        Attr := XmlAttribute.CreateNamespaceDeclaration(PrefixText, Ns);
    end;

    [TryFunction]
    local procedure TryAdd(var E: XmlElement; Attr: XmlAttribute)
    begin
        E.Add(Attr);
    end;

    local procedure ObservePrefix(Name: Text; E: XmlElement; Ns: Text)
    var
        P: Text;
        R: Boolean;
    begin
        P := 'unset';
        R := E.GetPrefixOfNamespace(Ns, P);
        Observer.Observe(Name, Format(R) + '[' + P + ']');
    end;

    local procedure ObserveNs(Name: Text; E: XmlElement; Prefix: Text)
    var
        N: Text;
        R: Boolean;
    begin
        N := 'unset';
        R := E.GetNamespaceOfPrefix(Prefix, N);
        Observer.Observe(Name, Format(R) + '[' + N + ']');
    end;

    [Test]
    procedure Prefix_OfUndeclaredNamespace()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Child: XmlElement;
        ChildNode: XmlNode;
        Doc2: XmlDocument;
        Root2: XmlElement;
    begin
        Load('<a xmlns:p="urn:p"><b/></a>', Doc);
        Doc.GetRoot(Root);
        Root.SelectSingleNode('b', ChildNode);
        Child := ChildNode.AsXmlElement();
        ObservePrefix('root_declared', Root, 'urn:p');
        ObservePrefix('root_undeclared', Root, 'urn:zz');
        ObservePrefix('root_empty_ns', Root, '');
        ObservePrefix('root_xml_ns', Root, 'http://www.w3.org/XML/1998/namespace');
        ObservePrefix('root_xmlns_ns', Root, 'http://www.w3.org/2000/xmlns/');
        ObservePrefix('child_declared_on_parent', Child, 'urn:p');
        ObservePrefix('child_undeclared', Child, 'urn:zz');
        ObserveNs('root_p', Root, 'p');
        ObserveNs('root_zz', Root, 'zz');
        ObserveNs('root_empty', Root, '');
        ObserveNs('root_xml', Root, 'xml');
        ObserveNs('root_xmlns', Root, 'xmlns');
        ObserveNs('child_p', Child, 'p');
        Load('<a xmlns="urn:d"><b/></a>', Doc2);
        Doc2.GetRoot(Root2);
        ObservePrefix('dflt_declared', Root2, 'urn:d');
        ObservePrefix('dflt_undeclared', Root2, 'urn:zz');
        ObserveNs('dflt_empty', Root2, '');
        Root := XmlElement.Create('r');
        ObservePrefix('detached_undeclared', Root, 'urn:zz');
        ObserveNs('detached_p', Root, 'p');
        Observer.Expect('root_declared', 'Yes[p]');
        Observer.Expect('root_undeclared', 'Yes[]');
        Observer.Expect('root_empty_ns', 'Yes[]');
        Observer.Expect('root_xml_ns', 'Yes[xml]');
        Observer.Expect('root_xmlns_ns', 'Yes[xmlns]');
        Observer.Expect('child_declared_on_parent', 'Yes[p]');
        Observer.Expect('child_undeclared', 'Yes[]');
        Observer.Expect('root_p', 'Yes[urn:p]');
        Observer.Expect('root_zz', 'No[unset]');
        Observer.Expect('root_empty', 'No[unset]');
        Observer.Expect('root_xml', 'Yes[http://www.w3.org/XML/1998/namespace]');
        Observer.Expect('root_xmlns', 'Yes[http://www.w3.org/2000/xmlns/]');
        Observer.Expect('child_p', 'Yes[urn:p]');
        Observer.Expect('dflt_declared', 'Yes[]');
        Observer.Expect('dflt_undeclared', 'Yes[]');
        Observer.Expect('dflt_empty', 'No[unset]');
        Observer.Expect('detached_undeclared', 'Yes[]');
        Observer.Expect('detached_p', 'No[unset]');
        Observer.Verify();
    end;

    [Test]
    procedure Decl_EmptyPrefixOrNamespace()
    var
        Created: Boolean;
        Attr: XmlAttribute;
        E: XmlElement;
        Txt: Text;
    begin
        E := XmlElement.Create('a');
        Created := TryCreateDecl('', 'urn:d', Attr);
        Observer.Observe('create_empty_prefix', Format(Created));
        Observer.ObserveError('create_empty_prefix');
        if Created then begin
            Observer.Observe('add_empty_prefix', Format(TryAdd(E, Attr)));
            Observer.ObserveError('add_empty_prefix');
        end;
        E.WriteTo(Txt);
        Observer.Observe('out_empty_prefix', Txt);
        Clear(Attr);
        Created := TryCreateDecl('p', '', Attr);
        Observer.Observe('create_empty_ns', Format(Created));
        Observer.ObserveError('create_empty_ns');
        if Created then begin
            Observer.Observe('add_empty_ns', Format(TryAdd(E, Attr)));
            Observer.ObserveError('add_empty_ns');
        end;
        E.WriteTo(Txt);
        Observer.Observe('out_empty_ns', Txt);
        Clear(Attr);
        Created := TryCreateDecl('', '', Attr);
        Observer.Observe('create_both_empty', Format(Created));
        Observer.ObserveError('create_both_empty');
        if Created then begin
            Observer.Observe('add_both_empty', Format(TryAdd(E, Attr)));
            Observer.ObserveError('add_both_empty');
        end;
        Clear(Attr);
        Observer.Observe('create_xmlns', Format(TryCreateDecl('xmlns', 'urn:x', Attr)));
        Observer.ObserveError('create_xmlns');
        Clear(Attr);
        Observer.Observe('create_xml', Format(TryCreateDecl('xml', 'urn:x', Attr)));
        Observer.ObserveError('create_xml');
        Clear(Attr);
        Created := TryCreateDecl('p:q', 'urn:x', Attr);
        Observer.Observe('create_colon', Format(Created));
        Observer.ObserveError('create_colon');
        if Created then
            Observer.Observe('create_colon_name', Attr.Name());
        Observer.Expect('create_empty_prefix', 'No');
        Observer.Expect('create_empty_prefix|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('create_empty_prefix|code', 'Argument');
        Observer.Expect('out_empty_prefix', '<a />');
        Observer.Expect('create_empty_ns', 'No');
        Observer.Expect('create_empty_ns|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('create_empty_ns|code', 'Argument');
        Observer.Expect('out_empty_ns', '<a />');
        Observer.Expect('create_both_empty', 'No');
        Observer.Expect('create_both_empty|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('create_both_empty|code', 'Argument');
        Observer.Expect('create_xmlns', 'No');
        Observer.Expect('create_xmlns|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('create_xmlns|code', 'Argument');
        Observer.Expect('create_xml', 'No');
        Observer.Expect('create_xml|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('create_xml|code', 'Argument');
        Observer.Expect('create_colon', 'No');
        Observer.Expect('create_colon|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('create_colon|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_PrefixNumbering()
    var
        A1: XmlAttribute;
        A2: XmlAttribute;
        A3: XmlAttribute;
        A4: XmlAttribute;
        E: XmlElement;
        Child: XmlElement;
        Txt: Text;
        Doc: XmlDocument;
        Root: XmlElement;
    begin
        A1 := XmlAttribute.Create('k', 'urn:x', 'v1');
        A2 := XmlAttribute.Create('m', 'urn:y', 'v2');
        A3 := XmlAttribute.Create('n', 'urn:x', 'v3');
        A4 := XmlAttribute.Create('o', 'urn:z', 'v4');
        Observer.Observe('detached', A1.Name() + '|' + A2.Name() + '|' + A3.Name() + '|' + A4.Name());
        Observer.Observe('detached_prefix', A1.NamespacePrefix() + '|' + A2.NamespacePrefix() + '|' + A3.NamespacePrefix() + '|' + A4.NamespacePrefix());
        Observer.Observe('detached_ns', A1.NamespaceUri() + '|' + A2.NamespaceUri());
        E := XmlElement.Create('e');
        E.Add(A2);
        E.Add(A1);
        E.Add(A3);
        E.Add(A4);
        E.WriteTo(Txt);
        Observer.Observe('four_on_element', Txt);
        Observer.Observe('names_after_add', A1.Name() + '|' + A2.Name() + '|' + A3.Name() + '|' + A4.Name());
        // child of an element that already has the namespace prefix declared by an attribute
        E := XmlElement.Create('e');
        E.Add(XmlAttribute.CreateNamespaceDeclaration('q', 'urn:x'));
        E.Add(XmlAttribute.Create('k', 'urn:x', 'v'));
        E.WriteTo(Txt);
        Observer.Observe('declared_q_then_attr', Txt);
        // child element added to a parent that uses the prefix
        E := XmlElement.Create('e');
        E.Add(XmlAttribute.Create('k', 'urn:x', 'v'));
        Child := XmlElement.Create('c');
        Child.Add(XmlAttribute.Create('k', 'urn:x', 'w'));
        E.Add(Child);
        E.WriteTo(Txt);
        Observer.Observe('child_after_parent', Txt);
        // child gets its attribute after being added to the parent
        E := XmlElement.Create('e');
        E.Add(XmlAttribute.Create('k', 'urn:x', 'v'));
        Child := XmlElement.Create('c');
        E.Add(Child);
        Child.Add(XmlAttribute.Create('k', 'urn:x', 'w'));
        E.WriteTo(Txt);
        Observer.Observe('child_attr_after_add', Txt);
        // loaded document with a declared prefix, then Create + Add
        XmlDocument.ReadFrom('<e xmlns:q="urn:x"><c/></e>', Doc);
        Doc.GetRoot(Root);
        Root.Add(XmlAttribute.Create('k', 'urn:x', 'v'));
        Root.WriteTo(Txt);
        Observer.Observe('loaded_prefix_q', Txt);
        // loaded document with the namespace as the default namespace of the element
        XmlDocument.ReadFrom('<e xmlns="urn:x"/>', Doc);
        Doc.GetRoot(Root);
        Root.Add(XmlAttribute.Create('k', 'urn:x', 'v'));
        Root.WriteTo(Txt);
        Observer.Observe('loaded_default_x', Txt);
        // loaded document with a prefix p1 already declared for another namespace
        XmlDocument.ReadFrom('<e xmlns:p1="urn:other"/>', Doc);
        Doc.GetRoot(Root);
        Root.Add(XmlAttribute.Create('k', 'urn:x', 'v'));
        Root.WriteTo(Txt);
        Observer.Observe('loaded_p1_taken', Txt);
        // the attribute namespace is the namespace of an element created with Create(name, ns)
        E := XmlElement.Create('e', 'urn:x');
        E.Add(XmlAttribute.Create('k', 'urn:x', 'v'));
        E.WriteTo(Txt);
        Observer.Observe('element_ns_same', Txt);
        // set the same attribute again: replaces
        E := XmlElement.Create('e');
        E.SetAttribute('k', 'urn:x', '1');
        E.SetAttribute('k', 'urn:y', '2');
        E.SetAttribute('m', 'urn:x', '3');
        E.WriteTo(Txt);
        Observer.Observe('setattribute_ns', Txt);
        Observer.Expect('detached', 'p0:k|p0:m|p0:n|p0:o');
        Observer.Expect('detached_prefix', 'p0|p0|p0|p0');
        Observer.Expect('detached_ns', 'urn:x|urn:y');
        Observer.Expect('four_on_element', '<e p1:m="v2" p2:k="v1" p2:n="v3" p3:o="v4" xmlns:p3="urn:z" xmlns:p2="urn:x" xmlns:p1="urn:y" />');
        Observer.Expect('names_after_add', ':k|:m|:n|:o');
        Observer.Expect('declared_q_then_attr', '<e xmlns:q="urn:x" q:k="v" />');
        Observer.Expect('child_after_parent', '<e p1:k="v" xmlns:p1="urn:x">\r\n  <c p1:k="w" />\r\n</e>');
        Observer.Expect('child_attr_after_add', '<e p1:k="v" xmlns:p1="urn:x">\r\n  <c p1:k="w" />\r\n</e>');
        Observer.Expect('loaded_prefix_q', '<e xmlns:q="urn:x" q:k="v">\r\n  <c />\r\n</e>');
        Observer.Expect('loaded_default_x', '<e xmlns="urn:x" p1:k="v" xmlns:p1="urn:x" />');
        Observer.Expect('loaded_p1_taken', '<e xmlns:p1="urn:other" p2:k="v" xmlns:p2="urn:x" />');
        Observer.Expect('element_ns_same', '<e p1:k="v" xmlns:p1="urn:x" xmlns="urn:x" />');
        Observer.Expect('setattribute_ns', '<e p1:k="1" p2:k="2" p1:m="3" xmlns:p2="urn:y" xmlns:p1="urn:x" />');
        Observer.Verify();
    end;
}
