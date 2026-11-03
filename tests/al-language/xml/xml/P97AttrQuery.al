// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlattribute/xmlattribute-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlAttribute SelectNodes and SelectSingleNode with and without a namespace manager, relative XPath from an attribute, attached and detached, and invalid paths
// BC versions: 29 (27 and 28 by CI)

codeunit 74804 "LT P97 Attr Query"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Build(var Doc: XmlDocument; var X: XmlAttribute)
    var
        Root: XmlElement;
        Ok: Boolean;
    begin
        Ok := XmlDocument.ReadFrom('<r xmlns:n="urn:n" p="1" x="2" n:q="3"><c k="a"/><c k="b"><d/></c><n:c k="ns"/></r>', Doc);
        Doc.GetRoot(Root);
        Root.Attributes().Get('x', X);
    end;

    local procedure Describe(L: XmlNodeList): Text
    var
        N: XmlNode;
        S: Text;
        T: Text;
    begin
        S := 'count=' + Format(L.Count()) + ':';
        foreach N in L do begin
            T := '';
            N.WriteTo(T);
            S += T + ';';
        end;
        exit(S);
    end;

    [TryFunction]
    local procedure TrySelectNodes(var X: XmlAttribute; XPath: Text; var Result: Text)
    var
        L: XmlNodeList;
        Found: Boolean;
    begin
        Found := X.SelectNodes(XPath, L);
        Result := Format(Found) + '|' + Describe(L);
    end;

    [TryFunction]
    local procedure TrySelectNodesNs(var X: XmlAttribute; XPath: Text; var Mgr: XmlNamespaceManager; var Result: Text)
    var
        L: XmlNodeList;
        Found: Boolean;
    begin
        Found := X.SelectNodes(XPath, Mgr, L);
        Result := Format(Found) + '|' + Describe(L);
    end;

    [TryFunction]
    local procedure TrySingle(var X: XmlAttribute; XPath: Text; var Result: Text)
    var
        N: XmlNode;
        Found: Boolean;
        S: Text;
    begin
        Found := X.SelectSingleNode(XPath, N);
        if Found then
            N.WriteTo(S);
        Result := Format(Found) + '|' + S;
    end;

    [TryFunction]
    local procedure TrySingleNs(var X: XmlAttribute; XPath: Text; var Mgr: XmlNamespaceManager; var Result: Text)
    var
        N: XmlNode;
        Found: Boolean;
        S: Text;
    begin
        Found := X.SelectSingleNode(XPath, Mgr, N);
        if Found then
            N.WriteTo(S);
        Result := Format(Found) + '|' + S;
    end;

    local procedure NodesObs(var Observer: Codeunit "Probe Observer"; Name: Text; var X: XmlAttribute; XPath: Text)
    var
        R: Text;
    begin
        if TrySelectNodes(X, XPath, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    local procedure SingleObs(var Observer: Codeunit "Probe Observer"; Name: Text; var X: XmlAttribute; XPath: Text)
    var
        R: Text;
    begin
        if TrySingle(X, XPath, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure SelectNodes_Attached()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        X: XmlAttribute;
    begin
        Build(Doc, X);
        NodesObs(Observer, 'self', X, '.');
        NodesObs(Observer, 'parent', X, '..');
        NodesObs(Observer, 'siblings', X, '../@*');
        NodesObs(Observer, 'attrs_star', X, '@*');
        NodesObs(Observer, 'root_abs', X, '/r');
        NodesObs(Observer, 'children_of_parent', X, '../c');
        NodesObs(Observer, 'descendant_any', X, '//d');
        NodesObs(Observer, 'parent_axis', X, 'parent::r');
        NodesObs(Observer, 'ancestor_axis', X, 'ancestor::*');
        NodesObs(Observer, 'text_fn', X, 'text()');
        NodesObs(Observer, 'preceding_attr', X, 'preceding-sibling::*');
        NodesObs(Observer, 'none', X, '../zzz');
        NodesObs(Observer, 'predicate', X, '../c[@k=''b'']');
        NodesObs(Observer, 'union', X, '../c[1] | ../c[2]');
        Observer.Expect('self', 'No|count=0:');
        Observer.Expect('parent', 'No|count=0:');
        Observer.Expect('siblings', 'No|count=0:');
        Observer.Expect('attrs_star', 'No|count=0:');
        Observer.Expect('root_abs', 'No|count=0:');
        Observer.Expect('children_of_parent', 'No|count=0:');
        Observer.Expect('descendant_any', 'No|count=0:');
        Observer.Expect('parent_axis', 'No|count=0:');
        Observer.Expect('ancestor_axis', 'No|count=0:');
        Observer.Expect('text_fn', 'No|count=0:');
        Observer.Expect('preceding_attr', 'No|count=0:');
        Observer.Expect('none', 'No|count=0:');
        Observer.Expect('predicate', 'No|count=0:');
        Observer.Expect('union', 'No|count=0:');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingleNode_Attached()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        X: XmlAttribute;
    begin
        Build(Doc, X);
        SingleObs(Observer, 'self', X, '.');
        SingleObs(Observer, 'parent', X, '..');
        SingleObs(Observer, 'first_sibling_attr', X, '../@*');
        SingleObs(Observer, 'root_abs', X, '/r');
        SingleObs(Observer, 'first_child_c', X, '../c');
        SingleObs(Observer, 'deep', X, '//d');
        SingleObs(Observer, 'none', X, '../zzz');
        SingleObs(Observer, 'doc_root', X, '/');
        SingleObs(Observer, 'ancestor', X, 'ancestor::r');
        SingleObs(Observer, 'attr_value_pred', X, '../c[@k=''b'']/d');
        Observer.Expect('self', 'No|');
        Observer.Expect('parent', 'No|');
        Observer.Expect('first_sibling_attr', 'No|');
        Observer.Expect('root_abs', 'No|');
        Observer.Expect('first_child_c', 'No|');
        Observer.Expect('deep', 'No|');
        Observer.Expect('none', 'No|');
        Observer.Expect('doc_root', 'No|');
        Observer.Expect('ancestor', 'No|');
        Observer.Expect('attr_value_pred', 'No|');
        Observer.Verify();
    end;

    [Test]
    procedure Select_Detached()
    var
        Observer: Codeunit "Probe Observer";
        X: XmlAttribute;
    begin
        X := XmlAttribute.Create('x', '2');
        NodesObs(Observer, 'n_self', X, '.');
        NodesObs(Observer, 'n_parent', X, '..');
        NodesObs(Observer, 'n_root', X, '/');
        NodesObs(Observer, 'n_ancestor', X, 'ancestor::*');
        NodesObs(Observer, 'n_attrs', X, '@*');
        SingleObs(Observer, 's_self', X, '.');
        SingleObs(Observer, 's_parent', X, '..');
        SingleObs(Observer, 's_root', X, '/');
        SingleObs(Observer, 's_none', X, 'zzz');
        Observer.Expect('n_self', 'No|count=0:');
        Observer.Expect('n_parent', 'No|count=0:');
        Observer.Expect('n_root', 'No|count=0:');
        Observer.Expect('n_ancestor', 'No|count=0:');
        Observer.Expect('n_attrs', 'No|count=0:');
        Observer.Expect('s_self', 'No|');
        Observer.Expect('s_parent', 'No|');
        Observer.Expect('s_root', 'No|');
        Observer.Expect('s_none', 'No|');
        Observer.Verify();
    end;

    [Test]
    procedure Select_InvalidPaths()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        X: XmlAttribute;
    begin
        Build(Doc, X);
        NodesObs(Observer, 'n_empty', X, '');
        NodesObs(Observer, 'n_bracket', X, '[[');
        NodesObs(Observer, 'n_slashes', X, '///');
        NodesObs(Observer, 'n_count_fn', X, 'count(../c)');
        NodesObs(Observer, 'n_string_fn', X, 'string(.)');
        NodesObs(Observer, 'n_unknown_prefix', X, '../zz:c');
        NodesObs(Observer, 'n_unknown_fn', X, 'nofunction()');
        SingleObs(Observer, 's_empty', X, '');
        SingleObs(Observer, 's_bracket', X, '[[');
        SingleObs(Observer, 's_count_fn', X, 'count(../c)');
        SingleObs(Observer, 's_unknown_prefix', X, '../zz:c');
        SingleObs(Observer, 's_blank', X, ' ');
        Observer.Expect('n_empty', 'No|count=0:');
        Observer.Expect('n_bracket', 'No|count=0:');
        Observer.Expect('n_slashes', 'No|count=0:');
        Observer.Expect('n_count_fn', 'No|count=0:');
        Observer.Expect('n_string_fn', 'No|count=0:');
        Observer.Expect('n_unknown_prefix', 'No|count=0:');
        Observer.Expect('n_unknown_fn', 'No|count=0:');
        Observer.Expect('s_empty', 'No|');
        Observer.Expect('s_bracket', 'No|');
        Observer.Expect('s_count_fn', 'No|');
        Observer.Expect('s_unknown_prefix', 'No|');
        Observer.Expect('s_blank', 'No|');
        Observer.Verify();
    end;

    [Test]
    procedure Select_WithNamespaceManager()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        X: XmlAttribute;
        Mgr: XmlNamespaceManager;
        Empty: XmlNamespaceManager;
        R: Text;
    begin
        Build(Doc, X);
        Mgr.AddNamespace('m', 'urn:n');
        if TrySelectNodesNs(X, '../m:c', Mgr, R) then
            Observer.Observe('nodes_prefixed', R)
        else
            Observer.ObserveError('nodes_prefixed');
        if TrySelectNodesNs(X, '../n:c', Mgr, R) then
            Observer.Observe('nodes_document_prefix', R)
        else
            Observer.ObserveError('nodes_document_prefix');
        if TrySelectNodesNs(X, '../@m:q', Mgr, R) then
            Observer.Observe('nodes_prefixed_attr', R)
        else
            Observer.ObserveError('nodes_prefixed_attr');
        if TrySingleNs(X, '../m:c', Mgr, R) then
            Observer.Observe('single_prefixed', R)
        else
            Observer.ObserveError('single_prefixed');
        if TrySingleNs(X, '../c', Mgr, R) then
            Observer.Observe('single_unprefixed', R)
        else
            Observer.ObserveError('single_unprefixed');
        if TrySingleNs(X, '../zz:c', Mgr, R) then
            Observer.Observe('single_unknown', R)
        else
            Observer.ObserveError('single_unknown');
        if TrySelectNodesNs(X, '../m:c', Empty, R) then
            Observer.Observe('nodes_uninit_mgr', R)
        else
            Observer.ObserveError('nodes_uninit_mgr');
        if TrySingleNs(X, '../m:c', Empty, R) then
            Observer.Observe('single_uninit_mgr', R)
        else
            Observer.ObserveError('single_uninit_mgr');
        SingleObs(Observer, 'single_noprefix_mgr', X, '../m:c');
        Observer.Expect('nodes_prefixed', 'No|count=0:');
        Observer.Expect('nodes_document_prefix', 'No|count=0:');
        Observer.Expect('nodes_prefixed_attr', 'No|count=0:');
        Observer.Expect('single_prefixed', 'No|');
        Observer.Expect('single_unprefixed', 'No|');
        Observer.Expect('single_unknown', 'No|');
        Observer.Expect('nodes_uninit_mgr', 'No|count=0:');
        Observer.Expect('single_uninit_mgr', 'No|');
        Observer.Expect('single_noprefix_mgr', 'No|');
        Observer.Verify();
    end;

    [Test]
    procedure Select_Uninitialised()
    var
        Observer: Codeunit "Probe Observer";
        X: XmlAttribute;
    begin
        NodesObs(Observer, 'nodes', X, '.');
        SingleObs(Observer, 'single', X, '.');
        NodesObs(Observer, 'nodes_empty', X, '');
        Observer.Expect('nodes|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('nodes|code', 'NotInitialized');
        Observer.Expect('single|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('single|code', 'NotInitialized');
        Observer.Expect('nodes_empty|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('nodes_empty|code', 'NotInitialized');
        Observer.Verify();
    end;
}
