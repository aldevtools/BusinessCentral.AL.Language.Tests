// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDocument GetChildElements and GetDescendantElements with (LocalName, NamespaceUri), compared with the Name overload; SelectNodes and SelectSingleNode with and without a namespace manager
// BC versions: 29 (27 and 28 by CI)

codeunit 74807 "LT P97 Doc Query"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Load(var Doc: XmlDocument)
    var
        Ok: Boolean;
    begin
        Ok := XmlDocument.ReadFrom('<?xml version="1.0"?><!--lead--><r xmlns="urn:a" xmlns:b="urn:b" id="7"><a/><b:a/><a xmlns="urn:c"/><x><a/><b:a><a/></b:a></x>text<?pi data?></r>', Doc);
    end;

    local procedure Names(L: XmlNodeList): Text
    var
        N: XmlNode;
        E: XmlElement;
        S: Text;
    begin
        S := Format(L.Count()) + ':';
        foreach N in L do begin
            E := N.AsXmlElement();
            S += E.LocalName() + '@' + E.NamespaceUri() + ';';
        end;
        exit(S);
    end;

    [TryFunction]
    local procedure TryChildren(var Doc: XmlDocument; LocalName: Text; Ns: Text; var Result: Text)
    begin
        Result := Names(Doc.GetChildElements(LocalName, Ns));
    end;

    [TryFunction]
    local procedure TryDescendants(var Doc: XmlDocument; LocalName: Text; Ns: Text; var Result: Text)
    begin
        Result := Names(Doc.GetDescendantElements(LocalName, Ns));
    end;

    local procedure Kids(var Observer: Codeunit "Probe Observer"; Name: Text; var Doc: XmlDocument; LocalName: Text; Ns: Text)
    var
        R: Text;
    begin
        if TryChildren(Doc, LocalName, Ns, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    local procedure Desc(var Observer: Codeunit "Probe Observer"; Name: Text; var Doc: XmlDocument; LocalName: Text; Ns: Text)
    var
        R: Text;
    begin
        if TryDescendants(Doc, LocalName, Ns, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure GetChildElements_LocalNameAndNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
    begin
        Load(Doc);
        Observer.Observe('no_args', Names(Doc.GetChildElements()));
        Observer.Observe('by_name_r', Names(Doc.GetChildElements('r')));
        Observer.Observe('by_name_a', Names(Doc.GetChildElements('a')));
        Kids(Observer, 'r_urn_a', Doc, 'r', 'urn:a');
        Kids(Observer, 'r_urn_b', Doc, 'r', 'urn:b');
        Kids(Observer, 'r_empty_ns', Doc, 'r', '');
        Kids(Observer, 'a_urn_a', Doc, 'a', 'urn:a');
        Kids(Observer, 'empty_urn_a', Doc, '', 'urn:a');
        Kids(Observer, 'both_empty', Doc, '', '');
        Kids(Observer, 'star', Doc, '*', 'urn:a');
        Kids(Observer, 'upper_case', Doc, 'R', 'urn:a');
        Kids(Observer, 'prefixed_name', Doc, 'b:r', 'urn:a');
        Observer.Expect('no_args', '1:r@urn:a;');
        Observer.Expect('by_name_r', '0:');
        Observer.Expect('by_name_a', '0:');
        Observer.Expect('r_urn_a', '1:r@urn:a;');
        Observer.Expect('r_urn_b', '0:');
        Observer.Expect('r_empty_ns', '0:');
        Observer.Expect('a_urn_a', '0:');
        Observer.Expect('empty_urn_a|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty_urn_a|code', 'Argument');
        Observer.Expect('both_empty|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('both_empty|code', 'Argument');
        Observer.Expect('star|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''*'' character, hexadecimal value 0x2A.'' at line 0 and position 1.');
        Observer.Expect('star|code', 'Xml:Xml');
        Observer.Expect('upper_case', '0:');
        Observer.Expect('prefixed_name|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('prefixed_name|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure GetDescendantElements_LocalNameAndNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
    begin
        Load(Doc);
        Observer.Observe('no_args', Names(Doc.GetDescendantElements()));
        Observer.Observe('by_name_a', Names(Doc.GetDescendantElements('a')));
        Observer.Observe('by_name_x', Names(Doc.GetDescendantElements('x')));
        Desc(Observer, 'a_urn_a', Doc, 'a', 'urn:a');
        Desc(Observer, 'a_urn_b', Doc, 'a', 'urn:b');
        Desc(Observer, 'a_urn_c', Doc, 'a', 'urn:c');
        Desc(Observer, 'a_empty_ns', Doc, 'a', '');
        Desc(Observer, 'x_urn_a', Doc, 'x', 'urn:a');
        Desc(Observer, 'r_urn_a', Doc, 'r', 'urn:a');
        Desc(Observer, 'empty_urn_a', Doc, '', 'urn:a');
        Desc(Observer, 'both_empty', Doc, '', '');
        Desc(Observer, 'star', Doc, '*', 'urn:a');
        Desc(Observer, 'missing', Doc, 'zzz', 'urn:a');
        Observer.Expect('no_args', '8:r@urn:a;a@urn:a;a@urn:b;a@urn:c;x@urn:a;a@urn:a;a@urn:b;a@urn:a;');
        Observer.Expect('by_name_a', '0:');
        Observer.Expect('by_name_x', '0:');
        Observer.Expect('a_urn_a', '3:a@urn:a;a@urn:a;a@urn:a;');
        Observer.Expect('a_urn_b', '2:a@urn:b;a@urn:b;');
        Observer.Expect('a_urn_c', '1:a@urn:c;');
        Observer.Expect('a_empty_ns', '0:');
        Observer.Expect('x_urn_a', '1:x@urn:a;');
        Observer.Expect('r_urn_a', '1:r@urn:a;');
        Observer.Expect('empty_urn_a|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty_urn_a|code', 'Argument');
        Observer.Expect('both_empty|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('both_empty|code', 'Argument');
        Observer.Expect('star|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''*'' character, hexadecimal value 0x2A.'' at line 0 and position 1.');
        Observer.Expect('star|code', 'Xml:Xml');
        Observer.Expect('missing', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure Elements_EmptyAndUninitialised()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Empty: XmlDocument;
        Uninit: XmlDocument;
    begin
        Empty := XmlDocument.Create();
        Kids(Observer, 'empty_children', Empty, 'r', 'urn:a');
        Desc(Observer, 'empty_descendants', Empty, 'r', 'urn:a');
        Kids(Observer, 'uninit_children', Uninit, 'r', 'urn:a');
        Desc(Observer, 'uninit_descendants', Uninit, 'r', 'urn:a');
        Load(Doc);
        Observer.Observe('none_by_name', Names(Doc.GetDescendantElements('nothing')));
        Observer.Expect('empty_children', '0:');
        Observer.Expect('empty_descendants', '0:');
        Observer.Expect('uninit_children', '0:');
        Observer.Expect('uninit_descendants', '0:');
        Observer.Expect('none_by_name', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure Elements_ResultIsSnapshotOrLive()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        L: XmlNodeList;
        Root: XmlElement;
    begin
        Load(Doc);
        L := Doc.GetDescendantElements('a', 'urn:a');
        Observer.Observe('before', Names(L));
        Doc.GetRoot(Root);
        Root.Add(XmlElement.Create('a', 'urn:a'));
        Observer.Observe('after_add_same_list', Names(L));
        Observer.Observe('after_add_fresh', Names(Doc.GetDescendantElements('a', 'urn:a')));
        Observer.Expect('before', '3:a@urn:a;a@urn:a;a@urn:a;');
        Observer.Expect('after_add_same_list', '3:a@urn:a;a@urn:a;a@urn:a;');
        Observer.Expect('after_add_fresh', '4:a@urn:a;a@urn:a;a@urn:a;a@urn:a;');
        Observer.Verify();
    end;

    local procedure Sel(var Observer: Codeunit "Probe Observer"; Name: Text; var Doc: XmlDocument; XPath: Text)
    var
        L: XmlNodeList;
        N: XmlNode;
        Found: Boolean;
        S: Text;
        T: Text;
    begin
        if TrySel(Doc, XPath, Found, S) then
            Observer.Observe(Name, S)
        else
            Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure TrySel(var Doc: XmlDocument; XPath: Text; var Found: Boolean; var Result: Text)
    var
        L: XmlNodeList;
        N: XmlNode;
        T: Text;
        First: Text;
    begin
        Found := Doc.SelectNodes(XPath, L);
        if Found and (L.Count() > 0) then begin
            L.Get(1, N);
            N.WriteTo(First);
        end;
        Result := Format(Found) + '|' + Format(L.Count()) + '|' + First;
        Found := Doc.SelectSingleNode(XPath, N);
        T := '';
        if Found then
            N.WriteTo(T);
        Result += '|single=' + Format(Found) + ':' + T;
    end;

    [TryFunction]
    local procedure TrySelNs(var Doc: XmlDocument; XPath: Text; var Mgr: XmlNamespaceManager; var Result: Text)
    var
        L: XmlNodeList;
        N: XmlNode;
        T: Text;
        Found: Boolean;
    begin
        Found := Doc.SelectNodes(XPath, Mgr, L);
        Result := Format(Found) + '|' + Format(L.Count());
        Found := Doc.SelectSingleNode(XPath, Mgr, N);
        T := '';
        if Found then
            N.WriteTo(T);
        Result += '|single=' + Format(Found) + ':' + T;
    end;

    [Test]
    procedure Select_WithoutNamespaceManager()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
    begin
        Load(Doc);
        Sel(Observer, 'root_star', Doc, '/*');
        Sel(Observer, 'root_local', Doc, '/*[local-name()=''r'']');
        Sel(Observer, 'root_named', Doc, '/r');
        Sel(Observer, 'dot', Doc, '.');
        Sel(Observer, 'slash', Doc, '/');
        Sel(Observer, 'dotdot', Doc, '..');
        Sel(Observer, 'comment', Doc, 'comment()');
        Sel(Observer, 'comment_abs', Doc, '/comment()');
        Sel(Observer, 'pi', Doc, '//processing-instruction()');
        Sel(Observer, 'text_nodes', Doc, '/*/text()');
        Sel(Observer, 'attr', Doc, '/*/@id');
        Sel(Observer, 'descendant_local', Doc, '//*[local-name()=''a'']');
        Sel(Observer, 'count_fn', Doc, 'count(//*)');
        Sel(Observer, 'empty', Doc, '');
        Sel(Observer, 'bad', Doc, '[[');
        Sel(Observer, 'prefix_unknown', Doc, '/b:r');
        Observer.Expect('root_star', 'Yes|1|<r xmlns="urn:a" xmlns:b="urn:b" id="7">\r\n  <a />\r\n  <b:a />\r\n  <a xmlns="urn:c" />\r\n  <x>\r\n    <a />\r\n    <b:a>\r\n      <a />\r\n    </b:a>\r\n  </x>text<?pi data?></r>|single=Yes:<r xmlns="urn:a" xmlns:b="urn:b" id="7">\r\n  <a />\r\n  <b:a />\r\n  <a xmlns="urn:c" />\r\n  <x>\r\n    <a />\r\n    <b:a>\r\n      <a />\r\n    </b:a>\r\n  </x>text<?pi data?></r>');
        Observer.Expect('root_local', 'Yes|1|<r xmlns="urn:a" xmlns:b="urn:b" id="7">\r\n  <a />\r\n  <b:a />\r\n  <a xmlns="urn:c" />\r\n  <x>\r\n    <a />\r\n    <b:a>\r\n      <a />\r\n    </b:a>\r\n  </x>text<?pi data?></r>|single=Yes:<r xmlns="urn:a" xmlns:b="urn:b" id="7">\r\n  <a />\r\n  <b:a />\r\n  <a xmlns="urn:c" />\r\n  <x>\r\n    <a />\r\n    <b:a>\r\n      <a />\r\n    </b:a>\r\n  </x>text<?pi data?></r>');
        Observer.Expect('root_named', 'Yes|0||single=No:');
        Observer.Expect('dot', 'Yes|1|<?xml version="1.0" encoding="utf-16"?>\r\n<!--lead-->\r\n<r xmlns="urn:a" xmlns:b="urn:b" id="7">\r\n  <a />\r\n  <b:a />\r\n  <a xmlns="urn:c" />\r\n  <x>\r\n    <a />\r\n    <b:a>\r\n      <a />\r\n    </b:a>\r\n  </x>text<?pi data?></r>|single=Yes:<?xml version="1.0" encoding="utf-16"?>\r\n<!--lead-->\r\n<r xmlns="urn:a" xmlns:b="urn:b" id="7">\r\n  <a />\r\n  <b:a />\r\n  <a xmlns="urn:c" />\r\n  <x>\r\n    <a />\r\n    <b:a>\r\n      <a />\r\n    </b:a>\r\n  </x>text<?pi data?></r>');
        Observer.Expect('slash', 'Yes|1|<?xml version="1.0" encoding="utf-16"?>\r\n<!--lead-->\r\n<r xmlns="urn:a" xmlns:b="urn:b" id="7">\r\n  <a />\r\n  <b:a />\r\n  <a xmlns="urn:c" />\r\n  <x>\r\n    <a />\r\n    <b:a>\r\n      <a />\r\n    </b:a>\r\n  </x>text<?pi data?></r>|single=Yes:<?xml version="1.0" encoding="utf-16"?>\r\n<!--lead-->\r\n<r xmlns="urn:a" xmlns:b="urn:b" id="7">\r\n  <a />\r\n  <b:a />\r\n  <a xmlns="urn:c" />\r\n  <x>\r\n    <a />\r\n    <b:a>\r\n      <a />\r\n    </b:a>\r\n  </x>text<?pi data?></r>');
        Observer.Expect('dotdot', 'Yes|0||single=No:');
        Observer.Expect('comment', 'Yes|1|<!--lead-->|single=Yes:<!--lead-->');
        Observer.Expect('comment_abs', 'Yes|1|<!--lead-->|single=Yes:<!--lead-->');
        Observer.Expect('pi', 'Yes|1|<?pi data?>|single=Yes:<?pi data?>');
        Observer.Expect('text_nodes', 'Yes|1|text|single=Yes:text');
        Observer.Expect('attr', 'Yes|1|id="7"|single=Yes:id="7"');
        Observer.Expect('descendant_local', 'Yes|6|<a xmlns="urn:a" />|single=Yes:<a xmlns="urn:a" />');
        Observer.Expect('count_fn', 'Yes|0||single=No:');
        Observer.Expect('empty', 'No|0||single=No:');
        Observer.Expect('bad', 'No|0||single=No:');
        Observer.Expect('prefix_unknown', 'No|0||single=No:');
        Observer.Verify();
    end;





    [Test]
    procedure Select_WithNamespaceManager()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Mgr: XmlNamespaceManager;
        R: Text;
    begin
        Load(Doc);
        Mgr.AddNamespace('a', 'urn:a');
        Mgr.AddNamespace('b', 'urn:b');
        Mgr.AddNamespace('c', 'urn:c');
        if TrySelNs(Doc, '/a:r', Mgr, R) then
            Observer.Observe('root', R)
        else
            Observer.ObserveError('root');
        if TrySelNs(Doc, '//a:a', Mgr, R) then
            Observer.Observe('a_a', R)
        else
            Observer.ObserveError('a_a');
        if TrySelNs(Doc, '//b:a', Mgr, R) then
            Observer.Observe('b_a', R)
        else
            Observer.ObserveError('b_a');
        if TrySelNs(Doc, '//c:a', Mgr, R) then
            Observer.Observe('c_a', R)
        else
            Observer.ObserveError('c_a');
        if TrySelNs(Doc, '//a', Mgr, R) then
            Observer.Observe('unprefixed', R)
        else
            Observer.ObserveError('unprefixed');
        if TrySelNs(Doc, '//z:a', Mgr, R) then
            Observer.Observe('unregistered', R)
        else
            Observer.ObserveError('unregistered');
        if TrySelNs(Doc, '/a:r/a:x/b:a/a:a', Mgr, R) then
            Observer.Observe('deep', R)
        else
            Observer.ObserveError('deep');
        if TrySelNs(Doc, '', Mgr, R) then
            Observer.Observe('empty', R)
        else
            Observer.ObserveError('empty');
        Observer.Expect('root', 'Yes|1|single=Yes:<r xmlns="urn:a" xmlns:b="urn:b" id="7">\r\n  <a />\r\n  <b:a />\r\n  <a xmlns="urn:c" />\r\n  <x>\r\n    <a />\r\n    <b:a>\r\n      <a />\r\n    </b:a>\r\n  </x>text<?pi data?></r>');
        Observer.Expect('a_a', 'Yes|3|single=Yes:<a xmlns="urn:a" />');
        Observer.Expect('b_a', 'Yes|2|single=Yes:<b:a xmlns:b="urn:b" />');
        Observer.Expect('c_a', 'Yes|1|single=Yes:<a xmlns="urn:c" />');
        Observer.Expect('unprefixed', 'Yes|0|single=No:');
        Observer.Expect('unregistered', 'No|0|single=No:');
        Observer.Expect('deep', 'Yes|1|single=Yes:<a xmlns="urn:a" />');
        Observer.Expect('empty', 'No|0|single=No:');
        Observer.Verify();
    end;

    [Test]
    procedure Select_EmptyAndUninitialised()
    var
        Observer: Codeunit "Probe Observer";
        Empty: XmlDocument;
        Uninit: XmlDocument;
    begin
        Empty := XmlDocument.Create();
        Sel(Observer, 'empty_root', Empty, '/*');
        Sel(Observer, 'empty_dot', Empty, '.');
        Sel(Observer, 'uninit_root', Uninit, '/*');
        Sel(Observer, 'uninit_empty_path', Uninit, '');
        Observer.Expect('empty_root', 'Yes|0||single=No:');
        Observer.Expect('empty_dot|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('empty_dot|code', 'InvalidOperation');
        Observer.Expect('uninit_root', 'Yes|0||single=No:');
        Observer.Expect('uninit_empty_path', 'No|0||single=No:');
        Observer.Verify();
    end;
}
