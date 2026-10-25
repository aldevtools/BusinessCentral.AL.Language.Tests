// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlattribute/xmlattribute-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 73402
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 73402 "LT XmT Attributes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Load(Src: Text; var Root: XmlElement)
    var
        Doc: XmlDocument;
    begin
        XmlDocument.ReadFrom(Src, Doc);
        Doc.GetRoot(Root);
    end;

    local procedure GA(E: XmlElement; Name: Text; var V: Text): Boolean
    var
        A: XmlAttribute;
    begin
        V := '';
        if E.Attributes().Get(Name, A) then begin
            V := A.Value();
            exit(true);
        end;
        exit(false);
    end;

    local procedure GA(E: XmlElement; Name: Text; Ns: Text; var V: Text): Boolean
    var
        A: XmlAttribute;
    begin
        V := '';
        if E.Attributes().Get(Name, Ns, A) then begin
            V := A.Value();
            exit(true);
        end;
        exit(false);
    end;

    local procedure Str(E: XmlElement): Text
    var
        Txt: Text;
    begin
        E.WriteTo(Txt);
        exit(Txt);
    end;

    [Test]
    procedure Attribute_Create()
    var
        A: XmlAttribute;
        Txt: Text;
    begin
        A := XmlAttribute.Create('k', 'v');
        Observer.Observe('name', A.Name());
        Observer.Observe('value', A.Value());
        Observer.Observe('local', A.LocalName());
        Observer.Observe('ns', '[' + A.NamespaceUri() + ']');
        A.WriteTo(Txt);
        Observer.Observe('writeto', Txt);
        A := XmlAttribute.Create('k', '');
        Observer.Observe('empty_value', '[' + A.Value() + ']');
        A.WriteTo(Txt);
        Observer.Observe('empty_writeto', Txt);
        Observer.Expect('name', 'k');
        Observer.Expect('value', 'v');
        Observer.Expect('local', 'k');
        Observer.Expect('ns', '[]');
        Observer.Expect('writeto', 'k="v"');
        Observer.Expect('empty_value', '[]');
        Observer.Expect('empty_writeto', 'k=""');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Create_Namespace()
    var
        A: XmlAttribute;
        E: XmlElement;
        Txt: Text;
    begin
        A := XmlAttribute.Create('k', 'urn:x', 'v');
        Observer.Observe('name', A.Name());
        Observer.Observe('local', A.LocalName());
        Observer.Observe('ns', A.NamespaceUri());
        E := XmlElement.Create('e');
        E.Add(A);
        Observer.Observe('on_element', Str(E));
        Observer.Expect('name', 'p0:k');
        Observer.Expect('local', 'k');
        Observer.Expect('ns', 'urn:x');
        Observer.Expect('on_element', '<e p1:k="v" xmlns:p1="urn:x" />');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Create_InvalidName()
    var
        A: XmlAttribute;
    begin
        asserterror A := XmlAttribute.Create('', 'v');
        Observer.ObserveError('empty');
        asserterror A := XmlAttribute.Create('a b', 'v');
        Observer.ObserveError('space');
        asserterror A := XmlAttribute.Create('1a', 'v');
        Observer.ObserveError('digit');
        asserterror A := XmlAttribute.Create('a=b', 'v');
        Observer.ObserveError('equals');
        A := XmlAttribute.Create('xmlns', 'urn:x');
        Observer.Observe('xmlns_name', A.Name());
        asserterror A := XmlAttribute.Create('xml:lang', 'en');
        Observer.ObserveError('af107');
        Observer.Observe('xml_lang', A.Name());
        Observer.Expect('empty|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty|code', 'Argument');
        Observer.Expect('space|text', 'The following exception was encountered when processing XML data: ''The '' '' character, hexadecimal value 0x20, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('space|code', 'Xml:Xml');
        Observer.Expect('digit|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''1'' character, hexadecimal value 0x31.'' at line 0 and position 1.');
        Observer.Expect('digit|code', 'Xml:Xml');
        Observer.Expect('equals|text', 'The following exception was encountered when processing XML data: ''The ''='' character, hexadecimal value 0x3D, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('equals|code', 'Xml:Xml');
        Observer.Expect('xmlns_name', 'xmlns');
        Observer.Expect('af107|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 4.');
        Observer.Expect('af107|code', 'Xml:Xml');
        Observer.Expect('xml_lang', 'xmlns');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Value_Escaping()
    var
        E: XmlElement;
        A: XmlAttribute;
    begin
        E := XmlElement.Create('e');
        E.SetAttribute('k', '<&>"''' + 'x');
        Observer.Observe('out', Str(E));
        E.Attributes().Get('k', A);
        Observer.Observe('value', A.Value());
        Observer.Expect('out', '<e k="&lt;&amp;&gt;&quot;''x" />');
        Observer.Expect('value', '<&>"''x');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Value_Newlines()
    var
        E: XmlElement;
        A: XmlAttribute;
        Lf: Text[1];
        Tab: Text[1];
    begin
        Lf[1] := 10;
        Tab[1] := 9;
        E := XmlElement.Create('e');
        E.SetAttribute('k', 'a' + Lf + 'b' + Tab + 'c');
        Observer.Observe('out', Str(E));
        Load(Str(E), E);
        E.Attributes().Get('k', A);
        Observer.Observe('value', A.Value());
        Load('<e k="a' + Lf + 'b' + Tab + 'c"/>', E);
        E.Attributes().Get('k', A);
        Observer.Observe('normalized', A.Value());
        Observer.Expect('out', '<e k="a&#xA;b&#x9;c" />');
        Observer.Expect('value', 'a\nb\tc');
        Observer.Expect('normalized', 'a b c');
        Observer.Verify();
    end;

    [Test]
    procedure SetGet_Attribute()
    var
        E: XmlElement;
        V: Text;
    begin
        E := XmlElement.Create('e');
        E.SetAttribute('a', '1');
        Observer.Observe('get_a', Format(GA(E, 'a', V)));
        Observer.Observe('value', V);
        Observer.Observe('get_missing', Format(GA(E, 'zz', V)));
        Observer.Observe('value_missing', '[' + V + ']');
        E.SetAttribute('a', '2');
        GA(E, 'a', V);
        Observer.Observe('overwritten', V);
        Observer.Observe('out', Str(E));
        E.SetAttribute('b', '');
        Observer.Observe('empty', Str(E));
        Observer.Observe('hasattrs', Format(E.HasAttributes()));
        Observer.Observe('count', Format(E.Attributes().Count()));
        Observer.Expect('get_a', 'Yes');
        Observer.Expect('value', '1');
        Observer.Expect('get_missing', 'No');
        Observer.Expect('value_missing', '[]');
        Observer.Expect('overwritten', '2');
        Observer.Expect('out', '<e a="2" />');
        Observer.Expect('empty', '<e a="2" b="" />');
        Observer.Expect('hasattrs', 'Yes');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure SetGet_Attribute_Namespace()
    var
        E: XmlElement;
        V: Text;
    begin
        E := XmlElement.Create('e');
        E.SetAttribute('a', 'urn:x', '1');
        Observer.Observe('set_ns', Str(E));
        Observer.Observe('get_ns', Format(GA(E, 'a', 'urn:x', V)));
        Observer.Observe('value', V);
        Observer.Observe('get_no_ns', Format(GA(E, 'a', V)));
        Observer.Observe('get_wrong_ns', Format(GA(E, 'a', 'urn:y', V)));
        E.SetAttribute('a', '2');
        Observer.Observe('both', Str(E));
        Observer.Observe('count', Format(E.Attributes().Count()));
        E.SetAttribute('a', 'urn:y', '3');
        Observer.Observe('two_ns', Str(E));
        Observer.Expect('set_ns', '<e p1:a="1" xmlns:p1="urn:x" />');
        Observer.Expect('get_ns', 'Yes');
        Observer.Expect('value', '1');
        Observer.Expect('get_no_ns', 'No');
        Observer.Expect('get_wrong_ns', 'No');
        Observer.Expect('both', '<e p1:a="1" a="2" xmlns:p1="urn:x" />');
        Observer.Expect('count', '2');
        Observer.Expect('two_ns', '<e p1:a="1" a="2" p2:a="3" xmlns:p2="urn:y" xmlns:p1="urn:x" />');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Prefixed_Read()
    var
        E: XmlElement;
        V: Text;
    begin
        Load('<e xmlns:p="urn:p" p:a="1" b="2"/>', E);
        Observer.Observe('get_p_a', Format(GA(E, 'a', 'urn:p', V)));
        Observer.Observe('v', V);
        Observer.Observe('v2', V);
        Observer.Observe('get_local_only', Format(GA(E, 'a', V)));
        Observer.Observe('count', Format(E.Attributes().Count()));
        Observer.Expect('get_p_a', 'Yes');
        Observer.Expect('v', '1');
        Observer.Expect('v2', '1');
        Observer.Expect('get_local_only', 'No');
        Observer.Expect('count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAttribute()
    var
        E: XmlElement;
        V: Text;
    begin
        Load('<e a="1" b="2" c="3"/>', E);
        E.Attributes().Remove('a');
        Observer.Observe('remove_a', 'done');
        Observer.Observe('out', Str(E));
        E.Attributes().Remove('a');
        Observer.Observe('remove_a_again', 'done');
        E.RemoveAttribute('b');
        Observer.Observe('removeattribute', Str(E));
        E.RemoveAttribute('zz');
        Observer.Observe('remove_missing', Str(E));
        E.RemoveAllAttributes();
        Observer.Observe('removeall', Str(E));
        Observer.Observe('hasattrs', Format(E.HasAttributes()));
        Observer.Expect('remove_a', 'done');
        Observer.Expect('out', '<e b="2" c="3" />');
        Observer.Expect('remove_a_again', 'done');
        Observer.Expect('removeattribute', '<e c="3" />');
        Observer.Expect('remove_missing', '<e c="3" />');
        Observer.Expect('removeall', '<e />');
        Observer.Expect('hasattrs', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAttribute_Namespace()
    var
        E: XmlElement;
    begin
        Load('<e xmlns:p="urn:p" p:a="1" a="2"/>', E);
        E.Attributes().Remove('a', 'urn:p');
        Observer.Observe('remove_ns', 'done');
        Observer.Observe('out', Str(E));
        E.Attributes().Remove('a', 'urn:p');
        Observer.Observe('remove_ns_missing', 'done');
        E.RemoveAttribute('a', 'urn:p');
        Observer.Observe('removeattribute_ns', Str(E));
        Observer.Expect('remove_ns', 'done');
        Observer.Expect('out', '<e xmlns:p="urn:p" a="2" />');
        Observer.Expect('remove_ns_missing', 'done');
        Observer.Expect('removeattribute_ns', '<e xmlns:p="urn:p" a="2" />');
        Observer.Verify();
    end;

    [Test]
    procedure Collection_Count_Get()
    var
        E: XmlElement;
        Coll: XmlAttributeCollection;
        A: XmlAttribute;
    begin
        Load('<e a="1" b="2" c="3"/>', E);
        Coll := E.Attributes();
        Observer.Observe('count', Format(Coll.Count()));
        Observer.Observe('get_b', Format(Coll.Get('b', A)));
        Observer.Observe('b_value', A.Value());
        Observer.Observe('get_missing', Format(Coll.Get('zz', A)));
        Observer.Observe('get_idx1', Format(Coll.Get(1, A)));
        Observer.Observe('idx1_name', A.Name());
        Observer.Observe('get_idx3', Format(Coll.Get(3, A)));
        Observer.Observe('idx3_name', A.Name());
        Observer.Observe('get_idx0', Format(Coll.Get(0, A)));
        Observer.Observe('get_idx4', Format(Coll.Get(4, A)));
        Observer.Observe('get_idxneg', Format(Coll.Get(-1, A)));
        Observer.Expect('count', '3');
        Observer.Expect('get_b', 'Yes');
        Observer.Expect('b_value', '2');
        Observer.Expect('get_missing', 'No');
        Observer.Expect('get_idx1', 'Yes');
        Observer.Expect('idx1_name', 'a');
        Observer.Expect('get_idx3', 'Yes');
        Observer.Expect('idx3_name', 'c');
        Observer.Expect('get_idx0', 'No');
        Observer.Expect('get_idx4', 'No');
        Observer.Expect('get_idxneg', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Collection_Set()
    var
        E: XmlElement;
        Coll: XmlAttributeCollection;
    begin
        E := XmlElement.Create('e');
        Coll := E.Attributes();
        Coll.Set('a', '1');
        Observer.Observe('set', Str(E));
        Coll.Set('a', '2');
        Observer.Observe('reset', Str(E));
        Coll.Set('a', 'urn:x', '3');
        Observer.Observe('set_ns', Str(E));
        Observer.Observe('count', Format(Coll.Count()));
        Observer.Expect('set', '<e a="1" />');
        Observer.Expect('reset', '<e a="2" />');
        Observer.Expect('set_ns', '<e a="2" p1:a="3" xmlns:p1="urn:x" />');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Collection_Iteration_Order()
    var
        E: XmlElement;
        Coll: XmlAttributeCollection;
        A: XmlAttribute;
        i: Integer;
        Names: Text;
    begin
        Load('<e z="1" a="2" m="3"/>', E);
        Coll := E.Attributes();
        foreach A in Coll do
            Names += A.Name() + ',';
        Observer.Observe('foreach', Names);
        Names := '';
        for i := 1 to Coll.Count() do begin
            Coll.Get(i, A);
            Names += A.Name() + '=' + A.Value() + ',';
        end;
        Observer.Observe('for', Names);
        Observer.Expect('foreach', 'z,a,m,');
        Observer.Expect('for', 'z=1,a=2,m=3,');
        Observer.Verify();
    end;

    [Test]
    procedure Collection_Live_View()
    var
        E: XmlElement;
        Coll: XmlAttributeCollection;
    begin
        Load('<e a="1"/>', E);
        Coll := E.Attributes();
        E.SetAttribute('b', '2');
        Observer.Observe('count_after_set', Format(Coll.Count()));
        Coll.Remove('a');
        Observer.Observe('out', Str(E));
        Observer.Expect('count_after_set', '2');
        Observer.Expect('out', '<e b="2" />');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Parent_Remove()
    var
        E: XmlElement;
        A: XmlAttribute;
        Par: XmlElement;
    begin
        Load('<e a="1" b="2"/>', E);
        E.Attributes().Get('a', A);
        Observer.Observe('parent', Format(A.GetParent(Par)));
        Observer.Observe('parent_name', Par.Name());
        A.Remove();
        Observer.Observe('out', Str(E));
        Observer.Observe('parent_after', Format(A.GetParent(Par)));
        Observer.Observe('value_after', A.Value());
        A := XmlAttribute.Create('x', 'y');
        Observer.Observe('lone_parent', Format(A.GetParent(Par)));
        asserterror A.Remove();
        Observer.ObserveError('lone_remove');
        Observer.Expect('parent', 'Yes');
        Observer.Expect('parent_name', 'e');
        Observer.Expect('out', '<e b="2" />');
        Observer.Expect('parent_after', 'No');
        Observer.Expect('value_after', '1');
        Observer.Expect('lone_parent', 'No');
        Observer.Expect('lone_remove|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('lone_remove|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Value_Set()
    var
        E: XmlElement;
        A: XmlAttribute;
    begin
        Load('<e a="1"/>', E);
        E.Attributes().Get('a', A);
        A.Value('changed');
        Observer.Observe('out', Str(E));
        A.Value('');
        Observer.Observe('empty', Str(E));
        A.Value('<&>');
        Observer.Observe('escaped', Str(E));
        Observer.Expect('out', '<e a="changed" />');
        Observer.Expect('empty', '<e a="" />');
        Observer.Expect('escaped', '<e a="&lt;&amp;&gt;" />');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_ReplaceWith()
    var
        E: XmlElement;
        A: XmlAttribute;
    begin
        Load('<e a="1" b="2"/>', E);
        E.Attributes().Get('a', A);
        A.ReplaceWith(XmlAttribute.Create('c', '3'));
        Observer.Observe('out', Str(E));
        Observer.Expect('out', '<e c="3" b="2" />');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Order_And_Duplicates()
    var
        E: XmlElement;
    begin
        E := XmlElement.Create('e');
        E.SetAttribute('z', '1');
        E.SetAttribute('a', '2');
        E.SetAttribute('m', '3');
        Observer.Observe('order', Str(E));
        E.SetAttribute('a', '9');
        Observer.Observe('reset_keeps_position', Str(E));
        Observer.Expect('order', '<e z="1" a="2" m="3" />');
        Observer.Expect('reset_keeps_position', '<e z="1" a="9" m="3" />');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Xmlns_Handling()
    var
        E: XmlElement;
        V: Text;
    begin
        Load('<e xmlns="urn:d" xmlns:p="urn:p" a="1"/>', E);
        Observer.Observe('count', Format(E.Attributes().Count()));
        Observer.Observe('get_xmlns', Format(GA(E, 'xmlns', V)));
        Observer.Observe('xmlns_value', V);
        Observer.Observe('get_a_default_ns', Format(GA(E, 'a', 'urn:d', V)));
        E := XmlElement.Create('x');
        asserterror E.SetAttribute('xmlns:q', 'urn:q');
        Observer.ObserveError('af404');
        Observer.Observe('set_xmlns_q', Str(E));
        Observer.Expect('count', '3');
        Observer.Expect('get_xmlns', 'Yes');
        Observer.Expect('xmlns_value', 'urn:d');
        Observer.Expect('get_a_default_ns', 'No');
        Observer.Expect('af404|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 6.');
        Observer.Expect('af404|code', 'Xml:Xml');
        Observer.Expect('set_xmlns_q', '<x />');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Uninitialized()
    var
        A: XmlAttribute;
        Txt: Text;
    begin
        asserterror Txt := A.Name();
        Observer.ObserveError('name');
        asserterror Txt := A.Value();
        Observer.ObserveError('value');
        Observer.Expect('name|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute variable not initialized.');
        Observer.Expect('name|code', 'NotInitialized');
        Observer.Expect('value|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute variable not initialized.');
        Observer.Expect('value|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Attribute_Unicode()
    var
        E: XmlElement;
        V: Text;
    begin
        E := XmlElement.Create('e');
        E.SetAttribute('k', 'äö€');
        Observer.Observe('out', Str(E));
        GA(E, 'k', V);
        Observer.Observe('value', V);
        Observer.Observe('len', Format(StrLen(V)));
        Observer.Expect('out', '<e k="äö€" />');
        Observer.Expect('value', 'äö€');
        Observer.Expect('len', '3');
        Observer.Verify();
    end;

    // Writer QZ: the assignment form Attr.Value := x (next to the method form Attr.Value(x)) on an attribute read from an element,
    // on a created attribute before and after it is added, and on an attribute with a namespace.
    [Test]
    procedure QZ_Attribute_ValueAssignment()
    var
        E: XmlElement;
        A: XmlAttribute;
        B: XmlAttribute;
        Fresh: XmlAttribute;
        V: Text;
    begin
        E := XmlElement.Create('e');
        E.SetAttribute('k', '1');
        E.Attributes().Get('k', A);
        A.Value := '3';
        Observer.Observe('own var', A.Value());
        GA(E, 'k', V);
        Observer.Observe('element after assign', V + '|' + Str(E));
        E.Attributes().Get('k', B);
        B.Value('4');
        Observer.Observe('first var after method form', A.Value());
        Observer.Observe('element after method form', Str(E));
        Fresh := XmlAttribute.Create('f', 'a');
        Fresh.Value := 'b';
        Observer.Observe('created', Fresh.Value());
        E.Add(Fresh);
        Fresh.Value := 'c';
        Observer.Observe('created after add', Fresh.Value() + '|' + Str(E));
        A.Value := '';
        Observer.Observe('assign empty', '[' + A.Value() + ']|' + Str(E));
        E.SetAttribute('n', 'urn:q', 'x');
        E.Attributes().Get('n', 'urn:q', A);
        A.Value := 'y';
        GA(E, 'n', 'urn:q', V);
        Observer.Observe('namespaced', V + '|' + A.Value());
        Observer.Expect('own var', '3');
        Observer.Expect('element after assign', '3|<e k="3" />');
        Observer.Expect('first var after method form', '4');
        Observer.Expect('element after method form', '<e k="4" />');
        Observer.Expect('created', 'b');
        Observer.Expect('created after add', 'c|<e k="4" f="c" />');
        Observer.Expect('assign empty', '[]|<e k="" f="c" />');
        Observer.Expect('namespaced', 'y|y');
        Observer.Verify();
    end;

    // Writer SL (2026-10-25): XmlAttribute.Create(Name, NamespaceUri, Value) beyond Attribute_Create_Namespace: the prefix of the detached attribute,
    // and the prefix it gets on an element that already declares the namespace, is in it, or gets several such attributes.
    [Test]
    procedure Attribute_Create_Namespace_Prefixes()
    var
        A: XmlAttribute;
        A2: XmlAttribute;
        A3: XmlAttribute;
        E: XmlElement;
        Got: XmlAttribute;
        Child: XmlNode;
        S: Text;
    begin
        A := XmlAttribute.Create('k', 'urn:x', 'v');
        A2 := XmlAttribute.Create('m', 'urn:y', 'w');
        Observer.Observe('detached', A.Name() + '|' + A.NamespacePrefix() + '|' + A2.Name() + '|' + A2.NamespacePrefix());
        A.WriteTo(S);
        Observer.Observe('detached_write', S);
        // two attributes in two namespaces on one element
        E := XmlElement.Create('e');
        E.Add(A);
        E.Add(A2);
        Observer.Observe('two_ns', Str(E));
        Observer.Observe('two_ns_names', A.Name() + '|' + A.NamespacePrefix() + '|' + A2.Name() + '|' + A2.NamespacePrefix());
        // two attributes in one namespace
        E := XmlElement.Create('e');
        E.Add(XmlAttribute.Create('k', 'urn:x', '1'));
        E.Add(XmlAttribute.Create('m', 'urn:x', '2'));
        Observer.Observe('same_ns', Str(E));
        // the element declares the namespace with prefix n first
        E := XmlElement.Create('e');
        E.Add(XmlAttribute.CreateNamespaceDeclaration('n', 'urn:x'));
        A3 := XmlAttribute.Create('k', 'urn:x', 'v');
        E.Add(A3);
        Observer.Observe('declared', Str(E));
        Observer.Observe('declared_name', A3.Name() + '|' + A3.NamespacePrefix());
        if E.Attributes().Get('k', 'urn:x', Got) then
            Observer.Observe('declared_get', Got.Name() + '|' + Got.NamespacePrefix());
        // the element itself is in the namespace (default namespace)
        E := XmlElement.Create('e', 'urn:x');
        E.Add(XmlAttribute.Create('k', 'urn:x', 'v'));
        Observer.Observe('element_in_ns', Str(E));
        // the element is in the namespace through a prefix
        E := XmlElement.Create('e', 'urn:x');
        E.Add(XmlAttribute.CreateNamespaceDeclaration('q', 'urn:x'));
        E.Add(XmlAttribute.Create('k', 'urn:x', 'v'));
        Observer.Observe('element_prefixed', Str(E));
        // a child of an element that declares the namespace
        E := XmlElement.Create('r');
        E.Add(XmlAttribute.CreateNamespaceDeclaration('n', 'urn:x'));
        E.Add(XmlElement.Create('c'));
        E.GetChildElements().Get(1, Child);
        Child.AsXmlElement().Add(XmlAttribute.Create('k', 'urn:x', 'v'));
        Observer.Observe('child_of_declared', Str(E));
        Observer.Finish();
    end;
}
