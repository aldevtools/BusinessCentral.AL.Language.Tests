// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlnamespacemanager/xmlnamespacemanager-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 73404
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 73404 "LT XmT XPath Namespaces"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Load(Src: Text; var Doc: XmlDocument)
    begin
        XmlDocument.ReadFrom(Src, Doc);
    end;

    local procedure Names(L: XmlNodeList): Text
    var
        N: XmlNode;
        Acc: Text;
    begin
        foreach N in L do
            if N.IsXmlElement() then
                Acc += N.AsXmlElement().Name() + ','
            else
                if N.IsXmlAttribute() then
                    Acc += '@' + N.AsXmlAttribute().Name() + '=' + N.AsXmlAttribute().Value() + ','
                else
                    Acc += '#,';
        exit(Acc);
    end;

    [Test]
    procedure SelectNodes_Doc_Basic()
    var
        Doc: XmlDocument;
        L: XmlNodeList;
    begin
        Load('<a><b>1</b><b>2</b><c><b>3</b></c></a>', Doc);
        Observer.Observe('abs', Format(Doc.SelectNodes('/a/b', L)));
        Observer.Observe('abs_count', Format(L.Count()));
        Observer.Observe('desc', Format(Doc.SelectNodes('//b', L)));
        Observer.Observe('desc_count', Format(L.Count()));
        Observer.Observe('none', Format(Doc.SelectNodes('/a/zz', L)));
        Observer.Observe('none_count', Format(L.Count()));
        Observer.Observe('star', Format(Doc.SelectNodes('/a/*', L)));
        Observer.Observe('star_names', Names(L));
        Observer.Observe('pos', Format(Doc.SelectNodes('/a/b[2]', L)));
        Observer.Observe('pos_text', Names(L) + Format(L.Count()));
        Observer.Observe('last', Format(Doc.SelectNodes('/a/b[last()]', L)));
        Observer.Observe('last_count', Format(L.Count()));
        Observer.Observe('text_nodes', Format(Doc.SelectNodes('//b/text()', L)));
        Observer.Observe('text_count', Format(L.Count()));
        Observer.Expect('abs', 'Yes');
        Observer.Expect('abs_count', '2');
        Observer.Expect('desc', 'Yes');
        Observer.Expect('desc_count', '3');
        Observer.Expect('none', 'Yes');
        Observer.Expect('none_count', '0');
        Observer.Expect('star', 'Yes');
        Observer.Expect('star_names', 'b,b,c,');
        Observer.Expect('pos', 'Yes');
        Observer.Expect('pos_text', 'b,1');
        Observer.Expect('last', 'Yes');
        Observer.Expect('last_count', '1');
        Observer.Expect('text_nodes', 'Yes');
        Observer.Expect('text_count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Predicates()
    var
        Doc: XmlDocument;
        L: XmlNodeList;
    begin
        Load('<a><i k="1" t="x"/><i k="2" t="y"/><i k="3" t="x"/></a>', Doc);
        Doc.SelectNodes('//i[@t=''x'']', L);
        Observer.Observe('attr_eq', Format(L.Count()));
        Doc.SelectNodes('//i[@k>1]', L);
        Observer.Observe('attr_gt', Format(L.Count()));
        Doc.SelectNodes('//i/@k', L);
        Observer.Observe('attr_nodes', Names(L));
        Doc.SelectNodes('//i[not(@t=''x'')]', L);
        Observer.Observe('not', Format(L.Count()));
        Doc.SelectNodes('//i[@k=1 or @k=3]', L);
        Observer.Observe('or', Format(L.Count()));
        Doc.SelectNodes('//i[position()<3]', L);
        Observer.Observe('position', Format(L.Count()));
        Doc.SelectNodes('//i[@zz]', L);
        Observer.Observe('missing_attr', Format(L.Count()));
        Observer.Expect('attr_eq', '2');
        Observer.Expect('attr_gt', '2');
        Observer.Expect('attr_nodes', '@k=1,@k=2,@k=3,');
        Observer.Expect('not', '1');
        Observer.Expect('or', '2');
        Observer.Expect('position', '2');
        Observer.Expect('missing_attr', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Axes_Functions()
    var
        Doc: XmlDocument;
        L: XmlNodeList;
        N: XmlNode;
    begin
        Load('<a><b id="1"><c/></b><b id="2"/>text</a>', Doc);
        Doc.SelectNodes('//c/parent::*', L);
        Observer.Observe('parent', Names(L));
        Doc.SelectNodes('//c/..', L);
        Observer.Observe('dotdot', Names(L));
        Doc.SelectNodes('//b[1]/following-sibling::*', L);
        Observer.Observe('following', Names(L));
        Doc.SelectNodes('//b[2]/preceding-sibling::*', L);
        Observer.Observe('preceding', Names(L));
        Doc.SelectNodes('//c/ancestor::*', L);
        Observer.Observe('ancestor', Names(L));
        Doc.SelectNodes('/a/node()', L);
        Observer.Observe('node_count', Format(L.Count()));
        Doc.SelectNodes('//b[name()=''b'']', L);
        Observer.Observe('name_fn', Format(L.Count()));
        Doc.SelectNodes('//*[local-name()=''c'']', L);
        Observer.Observe('local_name_fn', Format(L.Count()));
        Doc.SelectNodes('//b[count(*)=1]', L);
        Observer.Observe('count_fn', Format(L.Count()));
        Doc.SelectNodes('//b[contains(@id,''2'')]', L);
        Observer.Observe('contains_fn', Format(L.Count()));
        Doc.SelectNodes('//b | //c', L);
        Observer.Observe('union', Names(L));
        Observer.Expect('parent', 'b,');
        Observer.Expect('dotdot', 'b,');
        Observer.Expect('following', 'b,');
        Observer.Expect('preceding', 'b,');
        Observer.Expect('ancestor', 'a,b,');
        Observer.Expect('node_count', '3');
        Observer.Expect('name_fn', '2');
        Observer.Expect('local_name_fn', '1');
        Observer.Expect('count_fn', '1');
        Observer.Expect('contains_fn', '1');
        Observer.Expect('union', 'b,c,b,');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Invalid_XPath()
    var
        Doc: XmlDocument;
        L: XmlNodeList;
    begin
        Load('<a><b/></a>', Doc);
        asserterror Doc.SelectNodes('/a/[', L);
        Observer.ObserveError('bracket');
        asserterror Doc.SelectNodes('', L);
        Observer.ObserveError('empty');
        asserterror Doc.SelectNodes('///', L);
        Observer.ObserveError('slashes');
        asserterror Doc.SelectNodes('a b', L);
        Observer.ObserveError('two_names');
        asserterror Doc.SelectNodes('//p:b', L);
        Observer.ObserveError('unknown_prefix');
        asserterror Doc.SelectNodes('foo(', L);
        Observer.ObserveError('open_paren');
        asserterror Doc.SelectNodes('unknownfn()', L);
        Observer.ObserveError('unknown_function');
        Observer.Expect('bracket|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('bracket|code', 'Xml:XPath');
        Observer.Expect('empty|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('empty|code', 'Xml:XPath');
        Observer.Expect('slashes|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('slashes|code', 'Xml:XPath');
        Observer.Expect('two_names|text', '''a b'' has an invalid token.');
        Observer.Expect('two_names|code', 'Xml:XPath');
        Observer.Expect('unknown_prefix|text', 'Namespace Manager or XsltContext needed. This query has a prefix, variable, or user-defined function.');
        Observer.Expect('unknown_prefix|code', 'Xml:XPath');
        Observer.Expect('open_paren|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('open_paren|code', 'Xml:XPath');
        Observer.Expect('unknown_function|text', 'Namespace Manager or XsltContext needed. This query has a prefix, variable, or user-defined function.');
        Observer.Expect('unknown_function|code', 'Xml:XPath');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_NonNodeset_Result()
    var
        Doc: XmlDocument;
        L: XmlNodeList;
    begin
        Load('<a><b/></a>', Doc);
        Doc.SelectNodes('count(//b)', L);
        Observer.Observe('count', 'no error');
        Doc.SelectNodes('1 + 1', L);
        Observer.Observe('arith', 'no error');
        Doc.SelectNodes('''text''', L);
        Observer.Observe('string', 'no error');
        Observer.Expect('count', 'no error');
        Observer.Expect('arith', 'no error');
        Observer.Expect('string', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingleNode_Basic()
    var
        Doc: XmlDocument;
        N: XmlNode;
    begin
        Load('<a><b>1</b><b>2</b></a>', Doc);
        Observer.Observe('found', Format(Doc.SelectSingleNode('/a/b', N)));
        Observer.Observe('first', N.AsXmlElement().InnerText());
        Observer.Observe('second', Format(Doc.SelectSingleNode('/a/b[2]', N)));
        Observer.Observe('second_text', N.AsXmlElement().InnerText());
        Observer.Observe('missing', Format(Doc.SelectSingleNode('/a/zz', N)));
        Observer.Observe('attr_missing', Format(Doc.SelectSingleNode('/a/@x', N)));
        Observer.Observe('text', Format(Doc.SelectSingleNode('/a/b/text()', N)));
        Observer.Observe('text_kind', Format(N.IsXmlText()));
        asserterror Doc.SelectSingleNode('/a/[', N);
        Observer.ObserveError('invalid');
        Observer.Expect('found', 'Yes');
        Observer.Expect('first', '1');
        Observer.Expect('second', 'Yes');
        Observer.Expect('second_text', '2');
        Observer.Expect('missing', 'No');
        Observer.Expect('attr_missing', 'No');
        Observer.Expect('text', 'Yes');
        Observer.Expect('text_kind', 'Yes');
        Observer.Expect('invalid|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('invalid|code', 'Xml:XPath');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingleNode_Missing_KeepsPrevious()
    var
        Doc: XmlDocument;
        N: XmlNode;
        Txt: Text;
    begin
        Load('<a><b>1</b></a>', Doc);
        Doc.SelectSingleNode('/a/b', N);
        asserterror Doc.SelectSingleNode('/a/zz', N);
        Observer.ObserveError('af186');
        Observer.Observe('after_miss_is_element', Format(N.IsXmlElement()));
        N.WriteTo(Txt);
        Observer.Observe('after_miss', Txt);
        Observer.Expect('af186|text', 'The XPath query ''/a/zz'' does not match any nodes.');
        Observer.Expect('af186|code', 'InvalidXPathSelection');
        Observer.Expect('after_miss_is_element', 'Yes');
        Observer.Expect('after_miss', '<b>1</b>');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Element_Relative()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        L: XmlNodeList;
        N: XmlNode;
    begin
        Load('<a><b><c>1</c></b><b><c>2</c></b></a>', Doc);
        Doc.GetRoot(Root);
        Observer.Observe('rel', Format(Root.SelectNodes('b/c', L)));
        Observer.Observe('rel_count', Format(L.Count()));
        Root.SelectNodes('//c', L);
        Observer.Observe('abs_from_element', Format(L.Count()));
        Root.SelectNodes('.', L);
        Observer.Observe('self', Names(L));
        Root.SelectNodes('..', L);
        Observer.Observe('parent_of_root', Format(L.Count()));
        Root.SelectNodes('/a/b', L);
        Observer.Observe('doc_abs', Format(L.Count()));
        Root.SelectSingleNode('b/c', N);
        Observer.Observe('single', N.AsXmlElement().InnerText());
        Root.SelectNodes('descendant::c', L);
        Observer.Observe('descendant_axis', Format(L.Count()));
        Observer.Expect('rel', 'Yes');
        Observer.Expect('rel_count', '2');
        Observer.Expect('abs_from_element', '2');
        Observer.Expect('self', 'a,');
        Observer.Expect('parent_of_root', '1');
        Observer.Expect('doc_abs', '2');
        Observer.Expect('single', '1');
        Observer.Expect('descendant_axis', '2');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Detached_Element()
    var
        E: XmlElement;
        L: XmlNodeList;
    begin
        E := XmlElement.Create('a');
        E.Add(XmlElement.Create('b'));
        Observer.Observe('rel', Format(E.SelectNodes('b', L)));
        Observer.Observe('rel_count', Format(L.Count()));
        E.SelectNodes('/a/b', L);
        Observer.Observe('abs_count', Format(L.Count()));
        E.SelectNodes('//b', L);
        Observer.Observe('desc_count', Format(L.Count()));
        Observer.Expect('rel', 'Yes');
        Observer.Expect('rel_count', '1');
        Observer.Expect('abs_count', '0');
        Observer.Expect('desc_count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Namespaces_NoManager()
    var
        Doc: XmlDocument;
        L: XmlNodeList;
        N: XmlNode;
    begin
        Load('<a xmlns="urn:d" xmlns:p="urn:p"><b/><p:b/></a>', Doc);
        Observer.Observe('plain_b', Format(Doc.SelectNodes('//b', L)));
        Observer.Observe('plain_b_count', Format(L.Count()));
        Doc.SelectNodes('//*[local-name()=''b'']', L);
        Observer.Observe('local_name_b', Format(L.Count()));
        Doc.SelectNodes('//*[local-name()=''b'' and namespace-uri()=''urn:p'']', L);
        Observer.Observe('local_ns_b', Format(L.Count()));
        asserterror Doc.SelectNodes('//p:b', L);
        Observer.ObserveError('prefix_without_manager');
        Observer.Observe('single_plain', Format(Doc.SelectSingleNode('/a', N)));
        Doc.SelectNodes('/a', L);
        Observer.Observe('root_plain', Format(L.Count()));
        Observer.Expect('plain_b', 'Yes');
        Observer.Expect('plain_b_count', '0');
        Observer.Expect('local_name_b', '2');
        Observer.Expect('local_ns_b', '1');
        Observer.Expect('prefix_without_manager|text', 'Namespace Manager or XsltContext needed. This query has a prefix, variable, or user-defined function.');
        Observer.Expect('prefix_without_manager|code', 'Xml:XPath');
        Observer.Expect('single_plain', 'No');
        Observer.Expect('root_plain', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_WithNamespaceManager()
    var
        Doc: XmlDocument;
        NsMgr: XmlNamespaceManager;
        L: XmlNodeList;
        N: XmlNode;
    begin
        Load('<a xmlns="urn:d" xmlns:p="urn:p"><b/><p:b/><p:c/></a>', Doc);
        NsMgr.AddNamespace('d', 'urn:d');
        NsMgr.AddNamespace('x', 'urn:p');
        Observer.Observe('d_b', Format(Doc.SelectNodes('//d:b', NsMgr, L)));
        Observer.Observe('d_b_count', Format(L.Count()));
        Observer.Observe('x_b', Format(Doc.SelectNodes('//x:b', NsMgr, L)));
        Observer.Observe('x_b_count', Format(L.Count()));
        Doc.SelectNodes('//x:*', NsMgr, L);
        Observer.Observe('x_star', Format(L.Count()));
        Doc.SelectNodes('/d:a/*', NsMgr, L);
        Observer.Observe('children', Format(L.Count()));
        Doc.SelectNodes('//b', NsMgr, L);
        Observer.Observe('unprefixed', Format(L.Count()));
        asserterror Doc.SelectNodes('//q:b', NsMgr, L);
        Observer.ObserveError('unknown_prefix');
        Observer.Observe('single', Format(Doc.SelectSingleNode('//x:c', NsMgr, N)));
        Observer.Observe('single_name', N.AsXmlElement().Name());
        Observer.Observe('single_missing', Format(Doc.SelectSingleNode('//x:zz', NsMgr, N)));
        Observer.Expect('d_b', 'Yes');
        Observer.Expect('d_b_count', '1');
        Observer.Expect('x_b', 'Yes');
        Observer.Expect('x_b_count', '1');
        Observer.Expect('x_star', '2');
        Observer.Expect('children', '3');
        Observer.Expect('unprefixed', '0');
        Observer.Expect('unknown_prefix|text', 'Namespace prefix ''q'' is not defined.');
        Observer.Expect('unknown_prefix|code', 'Xml:XPath');
        Observer.Expect('single', 'Yes');
        Observer.Expect('single_name', 'p:c');
        Observer.Expect('single_missing', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Element_WithNamespaceManager()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        NsMgr: XmlNamespaceManager;
        L: XmlNodeList;
        N: XmlNode;
    begin
        Load('<a xmlns="urn:d"><b><c/></b></a>', Doc);
        Doc.GetRoot(Root);
        NsMgr.AddNamespace('d', 'urn:d');
        Observer.Observe('rel', Format(Root.SelectNodes('d:b/d:c', NsMgr, L)));
        Observer.Observe('rel_count', Format(L.Count()));
        Observer.Observe('single', Format(Root.SelectSingleNode('d:b', NsMgr, N)));
        Observer.Observe('single_name', N.AsXmlElement().Name());
        Observer.Expect('rel', 'Yes');
        Observer.Expect('rel_count', '1');
        Observer.Expect('single', 'Yes');
        Observer.Expect('single_name', ':b');
        Observer.Verify();
    end;

    [Test]
    procedure NamespaceManager_AddLookup()
    var
        NsMgr: XmlNamespaceManager;
        Uri: Text;
    begin
        Observer.Observe('has_p_before', Format(NsMgr.HasNamespace('p')));
        NsMgr.AddNamespace('p', 'urn:p');
        Observer.Observe('has_p_after', Format(NsMgr.HasNamespace('p')));
        Observer.Observe('lookup', Format(NsMgr.LookupNamespace('p', Uri)));
        Observer.Observe('lookup_value', Uri);
        Observer.Observe('lookup_missing', Format(NsMgr.LookupNamespace('zz', Uri)));
        Observer.Observe('lookup_missing_value', '[' + Uri + ']');
        Observer.Observe('has_xml', Format(NsMgr.HasNamespace('xml')));
        Observer.Observe('lookup_xml', Format(NsMgr.LookupNamespace('xml', Uri)));
        Observer.Observe('xml_value', Uri);
        Observer.Observe('has_xmlns', Format(NsMgr.HasNamespace('xmlns')));
        Observer.Observe('has_empty', Format(NsMgr.HasNamespace('')));
        Observer.Observe('lookup_empty', Format(NsMgr.LookupNamespace('', Uri)));
        Observer.Observe('empty_value', '[' + Uri + ']');
        Observer.Expect('has_p_before', 'No');
        Observer.Expect('has_p_after', 'Yes');
        Observer.Expect('lookup', 'Yes');
        Observer.Expect('lookup_value', 'urn:p');
        Observer.Expect('lookup_missing', 'No');
        Observer.Expect('lookup_missing_value', '[urn:p]');
        Observer.Expect('has_xml', 'No');
        Observer.Expect('lookup_xml', 'Yes');
        Observer.Expect('xml_value', 'http://www.w3.org/XML/1998/namespace');
        Observer.Expect('has_xmlns', 'No');
        Observer.Expect('has_empty', 'No');
        Observer.Expect('lookup_empty', 'Yes');
        Observer.Expect('empty_value', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure NamespaceManager_AddErrors()
    var
        NsMgr: XmlNamespaceManager;
        Uri: Text;
    begin
        NsMgr.AddNamespace('p', 'urn:p');
        NsMgr.AddNamespace('p', 'urn:other');
        NsMgr.LookupNamespace('p', Uri);
        Observer.Observe('redefine', Uri);
        NsMgr.AddNamespace('a b', 'urn:foo');
        Observer.Observe('bad_prefix', 'no error');
        NsMgr.AddNamespace('', 'urn:default');
        NsMgr.LookupNamespace('', Uri);
        Observer.Observe('add_empty_prefix', Uri);
        NsMgr.AddNamespace('q', '');
        NsMgr.LookupNamespace('q', Uri);
        Observer.Observe('empty_uri', '[' + Uri + ']');
        Observer.Expect('redefine', 'urn:other');
        Observer.Expect('bad_prefix', 'no error');
        Observer.Expect('add_empty_prefix', 'urn:default');
        Observer.Expect('empty_uri', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure NamespaceManager_Default_Prefix_XPath()
    var
        Doc: XmlDocument;
        NsMgr: XmlNamespaceManager;
        L: XmlNodeList;
    begin
        Load('<a xmlns="urn:d"><b/></a>', Doc);
        NsMgr.AddNamespace('', 'urn:d');
        Observer.Observe('empty_prefix_unprefixed_xpath', Format(Doc.SelectNodes('//b', NsMgr, L)));
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('empty_prefix_unprefixed_xpath', 'Yes');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NamespaceManager_Uninitialized_Use()
    var
        Doc: XmlDocument;
        NsMgr: XmlNamespaceManager;
        L: XmlNodeList;
    begin
        Load('<a><b/></a>', Doc);
        Observer.Observe('empty_manager', Format(Doc.SelectNodes('//b', NsMgr, L)));
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('empty_manager', 'Yes');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure NamespaceManager_NameTable()
    var
        Doc: XmlDocument;
        NsMgr: XmlNamespaceManager;
        NT: XmlNameTable;
        L: XmlNodeList;
    begin
        Load('<a xmlns:p="urn:p"><p:b/></a>', Doc);
        NsMgr.NameTable(NT);
        NsMgr.AddNamespace('p', 'urn:p');
        Observer.Observe('select', Format(Doc.SelectNodes('//p:b', NsMgr, L)));
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('select', 'Yes');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure NameTable_Basics()
    var
        NT: XmlNameTable;
        Txt: Text;
    begin
        Observer.Observe('get_missing', Format(NT.Get('abc', Txt)));
        Observer.Observe('get_missing_value', '[' + Txt + ']');
        Observer.Observe('add', NT.Add('abc'));
        Observer.Observe('get_present', Format(NT.Get('abc', Txt)));
        Observer.Observe('get_present_value', Txt);
        Observer.Observe('add_empty', '[' + NT.Add('') + ']');
        Observer.Observe('add_again', NT.Add('abc'));
        Observer.Expect('get_missing', 'No');
        Observer.Expect('get_missing_value', '[]');
        Observer.Expect('add', 'abc');
        Observer.Expect('get_present', 'Yes');
        Observer.Expect('get_present_value', 'abc');
        Observer.Expect('add_empty', '[]');
        Observer.Expect('add_again', 'abc');
        Observer.Verify();
    end;

    [Test]
    procedure Namespaces_Declaration_Output()
    var
        E: XmlElement;
        Txt: Text;
        Doc: XmlDocument;
    begin
        E := XmlElement.Create('a', 'urn:d');
        E.Add(XmlElement.Create('b', 'urn:d'));
        E.Add(XmlElement.Create('c', 'urn:e'));
        E.Add(XmlElement.Create('d'));
        E.WriteTo(Txt);
        Observer.Observe('out', Txt);
        Doc := XmlDocument.Create();
        Doc.Add(E);
        Doc.WriteTo(Txt);
        Observer.Observe('doc_out', Txt);
        Observer.Expect('out', '<a xmlns="urn:d">\r\n  <b />\r\n  <c xmlns="urn:e" />\r\n  <d xmlns="" />\r\n</a>');
        Observer.Expect('doc_out', '<?xml version="1.0" encoding="utf-16"?>\r\n<a xmlns="urn:d">\r\n  <b />\r\n  <c xmlns="urn:e" />\r\n  <d xmlns="" />\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure Namespaces_Prefix_Preserved()
    var
        Doc: XmlDocument;
        Txt: Text;
    begin
        Load('<p:a xmlns:p="urn:p"><p:b/><c xmlns="urn:q"/></p:a>', Doc);
        Doc.WriteTo(Txt);
        Observer.Observe('out', Txt);
        Observer.Expect('out', '<?xml version="1.0" encoding="utf-16"?>\r\n<p:a xmlns:p="urn:p">\r\n  <p:b />\r\n  <c xmlns="urn:q" />\r\n</p:a>');
        Observer.Verify();
    end;

    [Test]
    procedure Namespaces_XPath_GetNamespaceOfPrefix()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Uri: Text;
        Prefix: Text;
    begin
        Load('<p:a xmlns:p="urn:p" xmlns="urn:d"/>', Doc);
        Doc.GetRoot(Root);
        Observer.Observe('ns_of_p', Format(Root.GetNamespaceOfPrefix('p', Uri)));
        Observer.Observe('ns_of_p_value', Uri);
        Observer.Observe('ns_of_empty', Format(Root.GetNamespaceOfPrefix('', Uri)));
        Observer.Observe('ns_of_empty_value', Uri);
        Observer.Observe('ns_of_missing', Format(Root.GetNamespaceOfPrefix('zz', Uri)));
        Observer.Observe('prefix_of_p', Format(Root.GetPrefixOfNamespace('urn:p', Prefix)));
        Observer.Observe('prefix_of_p_value', Prefix);
        Observer.Observe('prefix_of_d', Format(Root.GetPrefixOfNamespace('urn:d', Prefix)));
        Observer.Observe('prefix_of_d_value', '[' + Prefix + ']');
        Observer.Observe('prefix_of_missing', Format(Root.GetPrefixOfNamespace('urn:zz', Prefix)));
        Observer.Expect('ns_of_p', 'Yes');
        Observer.Expect('ns_of_p_value', 'urn:p');
        Observer.Expect('ns_of_empty', 'No');
        Observer.Expect('ns_of_empty_value', 'urn:p');
        Observer.Expect('ns_of_missing', 'No');
        Observer.Expect('prefix_of_p', 'Yes');
        Observer.Expect('prefix_of_p_value', 'p');
        Observer.Expect('prefix_of_d', 'Yes');
        Observer.Expect('prefix_of_d_value', '[]');
        Observer.Expect('prefix_of_missing', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Namespaces_SetDefault_Via_Attribute()
    var
        E: XmlElement;
        Txt: Text;
    begin
        E := XmlElement.Create('a');
        E.Add(XmlAttribute.CreateNamespaceDeclaration('p', 'urn:p'));
        asserterror E.Add(XmlAttribute.CreateNamespaceDeclaration('', 'urn:d'));
        Observer.ObserveError('af476');
        E.WriteTo(Txt);
        Observer.Observe('out', Txt);
        Observer.Observe('ns', '[' + E.NamespaceUri() + ']');
        Observer.Expect('af476|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('af476|code', 'Argument');
        Observer.Expect('out', '<a xmlns:p="urn:p" />');
        Observer.Expect('ns', '[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryIsText(N: XmlNode; var Result: Boolean)
    begin
        Result := N.IsXmlText();
    end;

    [TryFunction]
    local procedure TryWriteNode(N: XmlNode; var Result: Text)
    begin
        N.WriteTo(Result);
    end;

    // Corpus issue 671 item 94 (microsoft/AL#5267): a backslash path is no valid XPath. The call with its result unused, and inside 'if'.
    [Test]
    procedure SelectNodes_Backslash_Path()
    var
        Doc: XmlDocument;
        L: XmlNodeList;
        N: XmlNode;
    begin
        Load('<root><contract>1</contract></root>', Doc);
        asserterror Doc.SelectNodes('\\contract', L);
        Observer.ObserveError('nodes_unused');
        ClearLastError();
        if Doc.SelectNodes('\\contract', L) then
            Observer.Observe('nodes_if', 'true')
        else
            Observer.Observe('nodes_if', 'false');
        Observer.ObserveError('nodes_if');
        Observer.Observe('nodes_if_count', Format(L.Count()));
        asserterror Doc.SelectSingleNode('\\contract', N);
        Observer.ObserveError('single_unused');
        ClearLastError();
        Observer.Observe('single_if', Format(Doc.SelectSingleNode('\\contract', N)));
        Observer.ObserveError('single_if');
        Observer.Observe('forward_slashes', Format(Doc.SelectNodes('//contract', L)) + '|' + Format(L.Count()));
        Observer.Expect('nodes_unused|text', '''\\contract'' has an invalid token.');
        Observer.Expect('nodes_unused|code', 'Xml:XPath');
        Observer.Expect('nodes_if', 'false');
        Observer.Expect('nodes_if|text', '''\\contract'' has an invalid token.');
        Observer.Expect('nodes_if|code', 'Xml:XPath');
        Observer.Expect('nodes_if_count', '0');
        Observer.Expect('single_unused|text', '''\\contract'' has an invalid token.');
        Observer.Expect('single_unused|code', 'Xml:XPath');
        Observer.Expect('single_if', 'No');
        Observer.Expect('single_if|text', '''\\contract'' has an invalid token.');
        Observer.Expect('single_if|code', 'Xml:XPath');
        Observer.Expect('forward_slashes', 'Yes|1');
        Observer.Verify();
    end;

    // Corpus issue 671 item 100 (microsoft/AL#554): SelectSingleNode that finds nothing, into a node variable that was never assigned.
    [Test]
    procedure SelectSingleNode_Missing_Into_Unassigned()
    var
        Doc: XmlDocument;
        N: XmlNode;
        IsText: Boolean;
        Txt: Text;
    begin
        Load('<a><b>1</b></a>', Doc);
        Observer.Observe('found', Format(Doc.SelectSingleNode('/a/zz', N)));
        Observer.Observe('is_text_ok', Format(TryIsText(N, IsText)));
        Observer.ObserveError('is_text');
        Observer.Observe('is_text', Format(IsText));
        Observer.Observe('write_ok', Format(TryWriteNode(N, Txt)));
        Observer.ObserveError('write');
        Observer.Observe('write', '[' + Txt + ']');
        Observer.Expect('found', 'No');
        Observer.Expect('is_text_ok', 'Yes');
        Observer.Expect('is_text|text', '');
        Observer.Expect('is_text|code', '');
        Observer.Expect('is_text', 'No');
        Observer.Expect('write_ok', 'No');
        Observer.Expect('write|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('write|code', 'NotInitialized');
        Observer.Expect('write', '[]');
        Observer.Verify();
    end;

    // Corpus issue 671 item 101 (microsoft/AL#7955): from a node that SelectNodes returned, a path with a leading slash starts at the
    // document root, not at the node.
    [Test]
    procedure SelectSingleNode_From_Node_Leading_Slash()
    var
        Doc: XmlDocument;
        L: XmlNodeList;
        Line: XmlNode;
        N: XmlNode;
    begin
        Load('<Header><Lines><Line><LineNumber>1</LineNumber></Line><Line><LineNumber>2</LineNumber></Line></Lines></Header>', Doc);
        Doc.SelectNodes('/Header/Lines/Line', L);
        Observer.Observe('lines', Format(L.Count()));
        L.Get(2, Line);
        Observer.Observe('abs_from_line', Format(Line.SelectSingleNode('/Line/LineNumber', N)));
        Observer.Observe('dot_rel', Format(Line.SelectSingleNode('./LineNumber', N)) + '|' + N.AsXmlElement().InnerText());
        Observer.Observe('plain_rel', Format(Line.SelectSingleNode('LineNumber', N)) + '|' + N.AsXmlElement().InnerText());
        Observer.Observe('abs_full', Format(Line.SelectSingleNode('/Header/Lines/Line/LineNumber', N)) + '|' + N.AsXmlElement().InnerText());
        Observer.Observe('descendant', Format(Line.SelectSingleNode('//LineNumber', N)) + '|' + N.AsXmlElement().InnerText());
        Observer.Observe('abs_nodes_from_line', Format(Line.SelectNodes('/Line/LineNumber', L)) + '|' + Format(L.Count()));
        Observer.Expect('lines', '2');
        Observer.Expect('abs_from_line', 'No');
        Observer.Expect('dot_rel', 'Yes|2');
        Observer.Expect('plain_rel', 'Yes|2');
        Observer.Expect('abs_full', 'Yes|1');
        Observer.Expect('descendant', 'Yes|1');
        Observer.Expect('abs_nodes_from_line', 'Yes|0');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryTextValue(N: XmlNode; var Result: Text)
    begin
        Result := N.AsXmlText().Value();
    end;

    // Corpus issue 671 item 92 (microsoft/AL#596): text() on an empty element (<value/> and <value></value>).
    [Test]
    procedure SelectSingleNode_Text_Of_Empty_Element()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        N: XmlNode;
        V: Text;
    begin
        Load('<keyvalueid><key>KEYNAME</key><value/></keyvalueid>', Doc);
        Doc.GetRoot(Root);
        Observer.Observe('key_text', Format(Root.SelectSingleNode('key/text()', N)) + '|' + Format(N.IsXmlText()) + '|' + N.AsXmlText().Value());
        Observer.Observe('self_closing', Format(Root.SelectSingleNode('value/text()', N)));
        Observer.Observe('self_closing_node_kind', Format(N.IsXmlText()) + '|' + Format(N.IsXmlElement()));
        Observer.Observe('self_closing_value_ok', Format(TryTextValue(N, V)) + '|[' + V + ']');
        Observer.ObserveError('self_closing_value');
        asserterror Root.SelectSingleNode('value/text()', N);
        Observer.ObserveError('self_closing_unused');
        Load('<keyvalueid><key>KEYNAME</key><value></value></keyvalueid>', Doc);
        Doc.GetRoot(Root);
        Observer.Observe('open_close', Format(Root.SelectSingleNode('value/text()', N)));
        Root.SelectSingleNode('value', N);
        Observer.Observe('element_inner', '[' + N.AsXmlElement().InnerText() + ']|' + Format(N.AsXmlElement().GetChildNodes().Count()));
        Observer.Expect('key_text', 'Yes|Yes|KEYNAME');
        Observer.Expect('self_closing', 'No');
        Observer.Expect('self_closing_node_kind', 'Yes|No');
        Observer.Expect('self_closing_value_ok', 'Yes|[KEYNAME]');
        Observer.Expect('self_closing_value|text', '');
        Observer.Expect('self_closing_value|code', '');
        Observer.Expect('self_closing_unused|text', 'The XPath query ''value/text()'' does not match any nodes.');
        Observer.Expect('self_closing_unused|code', 'InvalidXPathSelection');
        Observer.Expect('open_close', 'No');
        Observer.Expect('element_inner', '[]|0');
        Observer.Verify();
    end;

    // al-runner 6526 (writer Y29): the assignment form `Mgr.NameTable := Doc.NameTable` compiles (alc 18.1 with runtime 16.0
    // and alc 30 with runtime 18.0 alike) and is checked as the one-argument call `Mgr.NameTable(Doc.NameTable())`.
    // Getter-only members are refused: tests/must-not-compile/cases/2365-2372.
    [Test]
    procedure Y29_NameTable_AssignForm_SelectsLikeCallForm()
    var
        DocA: XmlDocument;
        DocC: XmlDocument;
        MgrA: XmlNamespaceManager;
        MgrC: XmlNamespaceManager;
        Node: XmlNode;
        L: XmlNodeList;
        Txt: Text;
    begin
        Load('<r xmlns="urn:repro"><docNo>PSI-1001</docNo><docNo>PSI-1002</docNo></r>', DocA);
        Load('<r xmlns="urn:repro"><docNo>PSI-1001</docNo><docNo>PSI-1002</docNo></r>', DocC);
        MgrA.NameTable := DocA.NameTable;
        MgrA.AddNamespace('urn', 'urn:repro');
        MgrC.NameTable(DocC.NameTable());
        MgrC.AddNamespace('urn', 'urn:repro');
        Txt := '';
        if DocA.SelectSingleNode('//urn:docNo', MgrA, Node) then
            Txt := Node.AsXmlElement().InnerText();
        Observer.Observe('assign_single', Txt);
        Txt := '';
        if DocC.SelectSingleNode('//urn:docNo', MgrC, Node) then
            Txt := Node.AsXmlElement().InnerText();
        Observer.Observe('call_single', Txt);
        Observer.Observe('assign_nodes', Format(DocA.SelectNodes('//urn:docNo', MgrA, L)) + '|' + Format(L.Count()));
        Observer.Observe('call_nodes', Format(DocC.SelectNodes('//urn:docNo', MgrC, L)) + '|' + Format(L.Count()));
        Txt := '';
        Observer.Observe('assign_lookup', Format(MgrA.LookupNamespace('urn', Txt)) + '|' + Txt);
        Txt := '';
        Observer.Observe('call_lookup', Format(MgrC.LookupNamespace('urn', Txt)) + '|' + Txt);
        Txt := '';
        Observer.Observe('assign_prefix', Format(MgrA.LookupPrefix('urn:repro', Txt)) + '|' + Txt);
        Observer.Observe('assign_unprefixed', Format(DocA.SelectNodes('//docNo', MgrA, L)) + '|' + Format(L.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Y29_NameTable_AssignForm_SharesTheTable()
    var
        Doc: XmlDocument;
        DocC: XmlDocument;
        DocN: XmlDocument;
        Mgr: XmlNamespaceManager;
        MgrC: XmlNamespaceManager;
        MgrN: XmlNamespaceManager;
        NT: XmlNameTable;
        NT2: XmlNameTable;
        Txt: Text;
    begin
        Load('<a/>', Doc);
        Load('<a/>', DocC);
        Load('<a/>', DocN);
        NT := Doc.NameTable();
        Mgr.NameTable := NT;
        Mgr.AddNamespace('qy29', 'urn:q-y29');
        Observer.Observe('assign_doc_table', Format(Doc.NameTable().Get('urn:q-y29', Txt)) + '|' + Txt);
        Txt := '';
        Observer.Observe('assign_var_table', Format(NT.Get('qy29', Txt)) + '|' + Txt);
        NT2 := Mgr.NameTable;
        Txt := '';
        Observer.Observe('assign_mgr_table', Format(NT2.Get('urn:q-y29', Txt)) + '|' + Txt);
        MgrC.NameTable(DocC.NameTable());
        MgrC.AddNamespace('qy29', 'urn:q-y29');
        Txt := '';
        Observer.Observe('call_doc_table', Format(DocC.NameTable().Get('urn:q-y29', Txt)) + '|' + Txt);
        MgrN.AddNamespace('qy29', 'urn:q-y29');
        Txt := '';
        Observer.Observe('none_doc_table', Format(DocN.NameTable().Get('urn:q-y29', Txt)) + '|' + Txt);
        Observer.Finish();
    end;

    [Test]
    procedure Y29_NameTable_AssignForm_AfterAddNamespace()
    var
        Doc: XmlDocument;
        MgrA: XmlNamespaceManager;
        MgrC: XmlNamespaceManager;
        L: XmlNodeList;
        Txt: Text;
    begin
        Load('<a xmlns:p="urn:p"><p:b/></a>', Doc);
        MgrA.AddNamespace('p', 'urn:p');
        MgrA.NameTable := Doc.NameTable;
        MgrC.AddNamespace('p', 'urn:p');
        MgrC.NameTable(Doc.NameTable());
        Observer.Observe('assign_lookup', Format(MgrA.LookupNamespace('p', Txt)) + '|' + Txt);
        Txt := '';
        Observer.Observe('call_lookup', Format(MgrC.LookupNamespace('p', Txt)) + '|' + Txt);
        Observer.Observe('assign_select', Format(Doc.SelectNodes('//p:b', MgrA, L)) + '|' + Format(L.Count()));
        Observer.Observe('call_select', Format(Doc.SelectNodes('//p:b', MgrC, L)) + '|' + Format(L.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Y29_NameTable_AssignForm_FromAnotherManager()
    var
        Doc: XmlDocument;
        MgrA: XmlNamespaceManager;
        MgrB: XmlNamespaceManager;
        L: XmlNodeList;
        Txt: Text;
    begin
        Load('<a xmlns:p="urn:p" xmlns:s="urn:s"><p:b/><s:c/><s:c/></a>', Doc);
        MgrA.NameTable := Doc.NameTable;
        MgrA.AddNamespace('p', 'urn:p');
        MgrB.NameTable := MgrA.NameTable;
        MgrB.AddNamespace('s', 'urn:s');
        Observer.Observe('b_lookup_own', Format(MgrB.LookupNamespace('s', Txt)) + '|' + Txt);
        Txt := '';
        Observer.Observe('b_lookup_of_a', Format(MgrB.LookupNamespace('p', Txt)) + '|' + Txt);
        Observer.Observe('b_select', Format(Doc.SelectNodes('//s:c', MgrB, L)) + '|' + Format(L.Count()));
        Txt := '';
        Observer.Observe('a_table_has_s', Format(MgrA.NameTable().Get('urn:s', Txt)) + '|' + Txt);
        Observer.Finish();
    end;
}
