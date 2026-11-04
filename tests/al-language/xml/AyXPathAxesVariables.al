// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-selectnodes-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 80503
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: SelectNodes with every XPath axis (ancestor, ancestor-or-self, descendant, descendant-or-self, following, following-sibling, preceding,
// preceding-sibling, parent, self, attribute, child, namespace), with an XPath variable ($v alone, in a predicate, in a function), and with an
// unclosed function call (in a predicate, nested, at the end of a path): the result, the node names, GetLastErrorText and GetLastErrorCode.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 80503 "LT AY XPath Axes Variables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySelect(Context: XmlElement; Path: Text; var Nodes: XmlNodeList; var Ok: Boolean)
    begin
        Ok := Context.SelectNodes(Path, Nodes);
    end;

    local procedure NodeName(N: XmlNode): Text
    begin
        if N.IsXmlElement() then
            exit(N.AsXmlElement().Name());
        if N.IsXmlAttribute() then
            exit('@' + N.AsXmlAttribute().Name());
        if N.IsXmlText() then
            exit('#text');
        if N.IsXmlDocument() then
            exit('#doc');
        exit('#other');
    end;

    local procedure Q(var Observer: Codeunit "Probe Observer"; Context: XmlElement; ObsKey: Text; Path: Text)
    var
        Nodes: XmlNodeList;
        N: XmlNode;
        Ok: Boolean;
        T: Text;
    begin
        ClearLastError();
        if TrySelect(Context, Path, Nodes, Ok) then begin
            T := Format(Ok) + ' ' + Format(Nodes.Count()) + ':';
            foreach N in Nodes do
                T += NodeName(N) + ',';
            Observer.Observe(ObsKey, T);
        end else
            Observer.ObserveError(ObsKey);
    end;

    local procedure Load(var Root: XmlElement; var Mid: XmlElement)
    var
        Doc: XmlDocument;
        N: XmlNode;
    begin
        XmlDocument.ReadFrom('<r xmlns:p="urn:p"><a id="1"><b id="2"><c id="3"/><d id="4"/></b><e id="5"/></a><f id="6"><g id="7"/></f></r>', Doc);
        Doc.GetRoot(Root);
        Root.SelectSingleNode('//b', N);
        Mid := N.AsXmlElement();
    end;

    [Test]
    procedure XPath_Axes_1()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'ancestor', 'ancestor::*');
        Q(Observer, B, 'ancestor_or_self', 'ancestor-or-self::*');
        Observer.Expect('ancestor', 'Yes 2:r,a,');
        Observer.Expect('ancestor_or_self', 'Yes 3:r,a,b,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_2()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'descendant', 'descendant::*');
        Q(Observer, B, 'descendant_or_self', 'descendant-or-self::*');
        Observer.Expect('descendant', 'Yes 2:c,d,');
        Observer.Expect('descendant_or_self', 'Yes 3:b,c,d,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_3()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'following', 'following::*');
        Q(Observer, B, 'following_sibling', 'following-sibling::*');
        Observer.Expect('following', 'Yes 3:e,f,g,');
        Observer.Expect('following_sibling', 'Yes 1:e,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_4()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'preceding_of_g', '//g/preceding::*');
        Q(Observer, B, 'preceding_sibling_of_e', '//e/preceding-sibling::*');
        Observer.Expect('preceding_of_g', 'Yes 5:a,b,c,d,e,');
        Observer.Expect('preceding_sibling_of_e', 'Yes 1:b,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_5()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'parent', 'parent::*');
        Q(Observer, B, 'self', 'self::b');
        Observer.Expect('parent', 'Yes 1:a,');
        Observer.Expect('self', 'Yes 1:b,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_6()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'self_other', 'self::a');
        Q(Observer, B, 'attribute', 'attribute::*');
        Observer.Expect('self_other', 'Yes 0:');
        Observer.Expect('attribute', 'Yes 1:@id,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_7()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'child', 'child::*');
        Q(Observer, B, 'namespace', 'namespace::*');
        Observer.Expect('child', 'Yes 2:c,d,');
        Observer.Expect('namespace', 'Yes 2:@xmlns:p,@xmlns:xml,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_8()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'ancestor_pos', 'ancestor::*[1]');
        Q(Observer, B, 'preceding_pos', '//g/preceding::*[1]');
        Observer.Expect('ancestor_pos', 'Yes 1:a,');
        Observer.Expect('preceding_pos', 'Yes 1:e,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_9()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'unknown_axis', 'sideways::*');
        Observer.Expect('unknown_axis', 'No 0:');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Variables_1()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, Root, 'var_alone', '$v');
        Q(Observer, Root, 'var_in_predicate', '//*[@id=$v]');
        Observer.Expect('var_alone', 'No 0:');
        Observer.Expect('var_in_predicate', 'No 0:');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Variables_2()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, Root, 'var_in_function', '//*[contains(@id, $v)]');
        Q(Observer, Root, 'var_dollar_only', '//*[@id=$]');
        Observer.Expect('var_in_function', 'No 0:');
        Observer.Expect('var_dollar_only', 'No 0:');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_UnclosedCalls_1()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, Root, 'unclosed_in_predicate', '//*[contains(@id, ''1'']');
        Q(Observer, Root, 'unclosed_nested', '//*[not(contains(@id, ''1'')]');
        Observer.Expect('unclosed_in_predicate', 'No 0:');
        Observer.Expect('unclosed_nested', 'No 0:');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_UnclosedCalls_2()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, Root, 'unclosed_at_end', '//*[last(]');
        Q(Observer, Root, 'unclosed_path_end', '//a/text(');
        Observer.Expect('unclosed_at_end', 'No 0:');
        Observer.Expect('unclosed_path_end', 'No 0:');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_UnclosedCalls_3()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, Root, 'unclosed_name', '//*[local-name(=''a'']');
        Observer.Expect('unclosed_name', 'No 0:');
        Observer.Verify();
    end;

    // ---- writer PY-D (2026-10-20): the namespace axis in detail, and following/preceding from an attribute ----

    local procedure PydDescribe(N: XmlNode): Text
    var
        A: XmlAttribute;
        Owner: XmlElement;
        T: Text;
    begin
        if not N.IsXmlAttribute() then
            exit(NodeName(N));
        A := N.AsXmlAttribute();
        T := '[' + A.Name() + '|' + A.LocalName() + '|' + A.NamespacePrefix() + '|' + A.NamespaceUri() + '|' + A.Value() + '|' + Format(A.IsNamespaceDeclaration()) + '|';
        if N.GetParent(Owner) then
            T += Owner.Name()
        else
            T += '-';
        exit(T + ']');
    end;

    local procedure PydQ(var Observer: Codeunit "Probe Observer"; Context: XmlElement; ObsKey: Text; Path: Text)
    var
        Nodes: XmlNodeList;
        N: XmlNode;
        Ok: Boolean;
        T: Text;
    begin
        ClearLastError();
        if TrySelect(Context, Path, Nodes, Ok) then begin
            T := Format(Ok) + ' ' + Format(Nodes.Count()) + ':';
            foreach N in Nodes do
                T += PydDescribe(N);
            Observer.Observe(ObsKey, T);
        end else
            Observer.ObserveError(ObsKey);
    end;

    local procedure PydLoad(var Doc: XmlDocument; var Root: XmlElement; var B: XmlElement)
    var
        N: XmlNode;
    begin
        XmlDocument.ReadFrom('<r xmlns="urn:d" xmlns:p="urn:p"><a xmlns:q="urn:q" id="1"><b id="2"><c id="3"/></b><e id="5"/></a></r>', Doc);
        Doc.GetRoot(Root);
        Root.SelectSingleNode('//*[local-name()=''b'']', N);
        B := N.AsXmlElement();
    end;

    [Test]
    procedure PYD_NamespaceAxis_Members()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        B: XmlElement;
    begin
        PydLoad(Doc, Root, B);
        PydQ(Observer, B, 'all', 'namespace::*');
        PydQ(Observer, Root, 'root_all', 'namespace::*');
        Observer.Expect('all', 'Yes 4:[xmlns:q|q|xmlns|http://www.w3.org/2000/xmlns/|urn:q|Yes|:a][xmlns|xmlns|||urn:d|Yes|:r][xmlns:p|p|xmlns|http://www.w3.org/2000/xmlns/|urn:p|Yes|:r][xmlns:xml|xml|xmlns|http://www.w3.org/2000/xmlns/|http://www.w3.org/XML/1998/namespace|Yes|-]');
        Observer.Expect('root_all', 'Yes 3:[xmlns|xmlns|||urn:d|Yes|:r][xmlns:p|p|xmlns|http://www.w3.org/2000/xmlns/|urn:p|Yes|:r][xmlns:xml|xml|xmlns|http://www.w3.org/2000/xmlns/|http://www.w3.org/XML/1998/namespace|Yes|-]');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_NamespaceAxis_ByNameAndPredicate()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        B: XmlElement;
    begin
        PydLoad(Doc, Root, B);
        PydQ(Observer, B, 'by_name_p', 'namespace::p');
        PydQ(Observer, B, 'by_name_xml', 'namespace::xml');
        PydQ(Observer, B, 'first', 'namespace::*[1]');
        PydQ(Observer, B, 'last', 'namespace::*[last()]');
        PydQ(Observer, B, 'pred_name', 'namespace::*[name()=''q'']');
        PydQ(Observer, B, 'pred_value', 'namespace::*[.=''urn:d'']');
        Observer.Expect('by_name_p', 'Yes 1:[xmlns:p|p|xmlns|http://www.w3.org/2000/xmlns/|urn:p|Yes|:r]');
        Observer.Expect('by_name_xml', 'Yes 1:[xmlns:xml|xml|xmlns|http://www.w3.org/2000/xmlns/|http://www.w3.org/XML/1998/namespace|Yes|-]');
        Observer.Expect('first', 'Yes 1:[xmlns:q|q|xmlns|http://www.w3.org/2000/xmlns/|urn:q|Yes|:a]');
        Observer.Expect('last', 'Yes 1:[xmlns:xml|xml|xmlns|http://www.w3.org/2000/xmlns/|http://www.w3.org/XML/1998/namespace|Yes|-]');
        Observer.Expect('pred_name', 'Yes 1:[xmlns:q|q|xmlns|http://www.w3.org/2000/xmlns/|urn:q|Yes|:a]');
        Observer.Expect('pred_value', 'Yes 1:[xmlns|xmlns|||urn:d|Yes|:r]');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_NamespaceAxis_RemoveNode()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        B: XmlElement;
        Nodes: XmlNodeList;
        N: XmlNode;
        T: Text;
    begin
        PydLoad(Doc, Root, B);
        B.SelectNodes('namespace::p', Nodes);
        Observer.Observe('count', Format(Nodes.Count()));
        if Nodes.Get(1, N) then begin
            ClearLastError();
            if PydTryRemove(N) then
                Observer.Observe('remove', 'ok')
            else
                Observer.ObserveError('remove');
        end;
        Doc.WriteTo(T);
        Observer.Observe('doc', T);
        Observer.Observe('root_attrs', Format(Root.Attributes().Count()));
        Observer.Expect('count', '1');
        Observer.Expect('remove', 'ok');
        Observer.Expect('doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r xmlns="urn:d">\r\n  <a xmlns:q="urn:q" id="1">\r\n    <b id="2">\r\n      <c id="3" />\r\n    </b>\r\n    <e id="5" />\r\n  </a>\r\n</r>');
        Observer.Expect('root_attrs', '1');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure PydTryRemove(N: XmlNode)
    begin
        N.Remove();
    end;

    [Test]
    procedure PYD_FollowingPreceding_FromAttribute()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, Root, 'following', '//b/@id/following::*');
        Q(Observer, Root, 'preceding', '//b/@id/preceding::*');
        Q(Observer, Root, 'following_sibling', '//b/@id/following-sibling::*');
        Q(Observer, Root, 'preceding_sibling', '//b/@id/preceding-sibling::*');
        Q(Observer, Root, 'parent', '//b/@id/parent::*');
        Q(Observer, Root, 'ancestor', '//b/@id/ancestor::*');
        Q(Observer, Root, 'following_node', '//b/@id/following::node()');
        Observer.Expect('following', 'Yes 5:c,d,e,f,g,');
        Observer.Expect('preceding', 'Yes 0:');
        Observer.Expect('following_sibling', 'Yes 0:');
        Observer.Expect('preceding_sibling', 'Yes 0:');
        Observer.Expect('parent', 'Yes 1:b,');
        Observer.Expect('ancestor', 'Yes 3:r,a,b,');
        Observer.Expect('following_node', 'Yes 5:c,d,e,f,g,');
        Observer.Verify();
    end;
}
