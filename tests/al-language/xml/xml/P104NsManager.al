// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlnamespacemanager/xmlnamespacemanager-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table LT P104 Blob where an OutStream is written
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlNamespaceManager.LookupPrefix, PushScope, PopScope and RemoveNamespace
// BC versions: 29 (27 and 28 by CI)

codeunit 71830 "LT P104 NsManager"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryLookup(var Mgr: XmlNamespaceManager; Uri: Text; var Found: Boolean; var Result: Text)
    begin
        Found := Mgr.LookupPrefix(Uri, Result);
    end;

    local procedure Lk(var Observer: Codeunit "Probe Observer"; var Mgr: XmlNamespaceManager; Name: Text; Uri: Text)
    var
        Found: Boolean;
        R: Text;
    begin
        R := 'unset';
        if TryLookup(Mgr, Uri, Found, R) then
            Observer.Observe(Name, Format(Found) + ':[' + R + ']')
        else
            Observer.ObserveError(Name);
    end;

    local procedure Has(var Observer: Codeunit "Probe Observer"; var Mgr: XmlNamespaceManager; Name: Text; Prefix: Text)
    var
        Uri: Text;
        Found: Boolean;
    begin
        Found := Mgr.LookupNamespace(Prefix, Uri);
        Observer.Observe(Name, Format(Mgr.HasNamespace(Prefix)) + ':' + Format(Found) + ':[' + Uri + ']');
    end;

    [TryFunction]
    local procedure TryPop(var Mgr: XmlNamespaceManager)
    begin
        Mgr.PopScope();
    end;

    [TryFunction]
    local procedure TryRemove(var Mgr: XmlNamespaceManager; Prefix: Text; Uri: Text)
    begin
        Mgr.RemoveNamespace(Prefix, Uri);
    end;

    [Test]
    procedure P104_LookupPrefix()
    var
        Observer: Codeunit "Probe Observer";
        Mgr: XmlNamespaceManager;
    begin
        Lk(Observer, Mgr, 'empty_manager', 'urn:p');
        Mgr.AddNamespace('p', 'urn:p');
        Lk(Observer, Mgr, 'found', 'urn:p');
        Lk(Observer, Mgr, 'missing', 'urn:zz');
        Lk(Observer, Mgr, 'empty_uri', '');
        Lk(Observer, Mgr, 'case_differs', 'URN:P');
        Lk(Observer, Mgr, 'xml_uri', 'http://www.w3.org/XML/1998/namespace');
        Lk(Observer, Mgr, 'xmlns_uri', 'http://www.w3.org/2000/xmlns/');
        Mgr.AddNamespace('q', 'urn:p');
        Lk(Observer, Mgr, 'two_prefixes_same_uri', 'urn:p');
        Mgr.AddNamespace('', 'urn:default');
        Lk(Observer, Mgr, 'default_prefix', 'urn:default');
        Mgr.AddNamespace('r', '');
        Lk(Observer, Mgr, 'empty_uri_added', '');
        Mgr.AddNamespace('p', 'urn:other');
        Lk(Observer, Mgr, 'redefined_old', 'urn:p');
        Lk(Observer, Mgr, 'redefined_new', 'urn:other');
        Observer.Expect('empty_manager', 'No:[unset]');
        Observer.Expect('found', 'Yes:[p]');
        Observer.Expect('missing', 'No:[unset]');
        Observer.Expect('empty_uri', 'Yes:[]');
        Observer.Expect('case_differs', 'No:[unset]');
        Observer.Expect('xml_uri', 'Yes:[xml]');
        Observer.Expect('xmlns_uri', 'Yes:[xmlns]');
        Observer.Expect('two_prefixes_same_uri', 'Yes:[q]');
        Observer.Expect('default_prefix', 'Yes:[]');
        Observer.Expect('empty_uri_added', 'Yes:[r]');
        Observer.Expect('redefined_old', 'Yes:[q]');
        Observer.Expect('redefined_new', 'Yes:[p]');
        Observer.Verify();
    end;

    [Test]
    procedure P104_PushScope_PopScope()
    var
        Observer: Codeunit "Probe Observer";
        Mgr: XmlNamespaceManager;
    begin
        Mgr.AddNamespace('p', 'urn:outer');
        Mgr.PushScope();
        Has(Observer, Mgr, 'inner_sees_outer', 'p');
        Mgr.AddNamespace('q', 'urn:inner');
        Has(Observer, Mgr, 'inner_q', 'q');
        Mgr.AddNamespace('p', 'urn:shadow');
        Has(Observer, Mgr, 'inner_p_shadow', 'p');
        Lk(Observer, Mgr, 'inner_lookup_outer_uri', 'urn:outer');
        Lk(Observer, Mgr, 'inner_lookup_shadow_uri', 'urn:shadow');
        Mgr.PopScope();
        Has(Observer, Mgr, 'popped_q', 'q');
        Has(Observer, Mgr, 'popped_p', 'p');
        Lk(Observer, Mgr, 'popped_lookup_inner', 'urn:inner');
        Lk(Observer, Mgr, 'popped_lookup_outer', 'urn:outer');
        Observer.Expect('inner_sees_outer', 'No:Yes:[urn:outer]');
        Observer.Expect('inner_q', 'Yes:Yes:[urn:inner]');
        Observer.Expect('inner_p_shadow', 'Yes:Yes:[urn:shadow]');
        Observer.Expect('inner_lookup_outer_uri', 'No:[unset]');
        Observer.Expect('inner_lookup_shadow_uri', 'Yes:[p]');
        Observer.Expect('popped_q', 'No:No:[]');
        Observer.Expect('popped_p', 'Yes:Yes:[urn:outer]');
        Observer.Expect('popped_lookup_inner', 'No:[unset]');
        Observer.Expect('popped_lookup_outer', 'Yes:[p]');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Scopes_Nested()
    var
        Observer: Codeunit "Probe Observer";
        Mgr: XmlNamespaceManager;
    begin
        Mgr.PushScope();
        Mgr.AddNamespace('a', 'urn:1');
        Mgr.PushScope();
        Mgr.AddNamespace('b', 'urn:2');
        Mgr.PushScope();
        Mgr.AddNamespace('c', 'urn:3');
        Has(Observer, Mgr, 'level3_a', 'a');
        Has(Observer, Mgr, 'level3_b', 'b');
        Has(Observer, Mgr, 'level3_c', 'c');
        Mgr.PopScope();
        Has(Observer, Mgr, 'level2_b', 'b');
        Has(Observer, Mgr, 'level2_c', 'c');
        Mgr.PopScope();
        Has(Observer, Mgr, 'level1_a', 'a');
        Has(Observer, Mgr, 'level1_b', 'b');
        Mgr.PopScope();
        Has(Observer, Mgr, 'level0_a', 'a');
        Observer.Expect('level3_a', 'No:Yes:[urn:1]');
        Observer.Expect('level3_b', 'No:Yes:[urn:2]');
        Observer.Expect('level3_c', 'Yes:Yes:[urn:3]');
        Observer.Expect('level2_b', 'Yes:Yes:[urn:2]');
        Observer.Expect('level2_c', 'No:No:[]');
        Observer.Expect('level1_a', 'Yes:Yes:[urn:1]');
        Observer.Expect('level1_b', 'No:No:[]');
        Observer.Expect('level0_a', 'No:No:[]');
        Observer.Verify();
    end;

    [Test]
    procedure P104_PopScope_Unbalanced()
    var
        Observer: Codeunit "Probe Observer";
        Mgr: XmlNamespaceManager;
    begin
        if TryPop(Mgr) then
            Observer.Observe('pop_fresh', 'ok')
        else
            Observer.ObserveError('pop_fresh');
        Mgr.AddNamespace('p', 'urn:p');
        if TryPop(Mgr) then
            Observer.Observe('pop_without_push', 'ok')
        else
            Observer.ObserveError('pop_without_push');
        Has(Observer, Mgr, 'p_after_unbalanced_pop', 'p');
        Mgr.PushScope();
        Mgr.PopScope();
        if TryPop(Mgr) then
            Observer.Observe('pop_second', 'ok')
        else
            Observer.ObserveError('pop_second');
        Mgr.PushScope();
        Mgr.PushScope();
        Mgr.PopScope();
        Mgr.PopScope();
        Has(Observer, Mgr, 'balanced_p', 'p');
        Observer.Expect('pop_fresh', 'ok');
        Observer.Expect('pop_without_push', 'ok');
        Observer.Expect('p_after_unbalanced_pop', 'Yes:Yes:[urn:p]');
        Observer.Expect('pop_second', 'ok');
        Observer.Expect('balanced_p', 'Yes:Yes:[urn:p]');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Scope_With_XPath()
    var
        Observer: Codeunit "Probe Observer";
        Mgr: XmlNamespaceManager;
        Doc: XmlDocument;
        R: XmlElement;
        NL: XmlNodeList;
    begin
        R := XmlElement.Create('r', 'urn:a');
        R.Add(XmlElement.Create('c', 'urn:a'));
        R.Add(XmlElement.Create('c', 'urn:b'));
        Doc := XmlDocument.Create();
        Doc.Add(R);
        Mgr.AddNamespace('p', 'urn:a');
        Observer.Observe('outer', Format(Doc.SelectNodes('/p:r/p:c', Mgr, NL)) + ':' + Format(NL.Count()));
        Mgr.PushScope();
        Mgr.AddNamespace('p', 'urn:b');
        Observer.Observe('shadowed', Format(Doc.SelectNodes('/p:r/p:c', Mgr, NL)) + ':' + Format(NL.Count()));
        Observer.Observe('shadowed_c', Format(Doc.SelectNodes('/*/p:c', Mgr, NL)) + ':' + Format(NL.Count()));
        Mgr.PopScope();
        Observer.Observe('restored', Format(Doc.SelectNodes('/p:r/p:c', Mgr, NL)) + ':' + Format(NL.Count()));
        Mgr.RemoveNamespace('p', 'urn:a');
        asserterror Doc.SelectNodes('/p:r/p:c', Mgr, NL);
        Observer.ObserveError('after_remove');
        Observer.Expect('outer', 'Yes:1');
        Observer.Expect('shadowed', 'Yes:0');
        Observer.Expect('shadowed_c', 'Yes:1');
        Observer.Expect('restored', 'Yes:1');
        Observer.Expect('after_remove|text', 'Namespace prefix ''p'' is not defined.');
        Observer.Expect('after_remove|code', 'Xml:XPath');
        Observer.Verify();
    end;

    [Test]
    procedure P104_RemoveNamespace()
    var
        Observer: Codeunit "Probe Observer";
        Mgr: XmlNamespaceManager;
    begin
        Mgr.AddNamespace('p', 'urn:p');
        Mgr.AddNamespace('q', 'urn:q');
        Mgr.RemoveNamespace('p', 'urn:p');
        Has(Observer, Mgr, 'p_removed', 'p');
        Has(Observer, Mgr, 'q_kept', 'q');
        Lk(Observer, Mgr, 'p_uri_gone', 'urn:p');
        if TryRemove(Mgr, 'p', 'urn:p') then
            Observer.Observe('remove_again', 'ok')
        else
            Observer.ObserveError('remove_again');
        if TryRemove(Mgr, 'zz', 'urn:zz') then
            Observer.Observe('remove_unknown', 'ok')
        else
            Observer.ObserveError('remove_unknown');
        if TryRemove(Mgr, 'q', 'urn:wrong') then
            Observer.Observe('remove_wrong_uri', 'ok')
        else
            Observer.ObserveError('remove_wrong_uri');
        Has(Observer, Mgr, 'q_after_wrong_uri', 'q');
        if TryRemove(Mgr, '', '') then
            Observer.Observe('remove_empty', 'ok')
        else
            Observer.ObserveError('remove_empty');
        if TryRemove(Mgr, 'xml', 'http://www.w3.org/XML/1998/namespace') then
            Observer.Observe('remove_xml', 'ok')
        else
            Observer.ObserveError('remove_xml');
        Has(Observer, Mgr, 'xml_after', 'xml');
        Observer.Expect('p_removed', 'No:No:[]');
        Observer.Expect('q_kept', 'Yes:Yes:[urn:q]');
        Observer.Expect('p_uri_gone', 'No:[unset]');
        Observer.Expect('remove_again', 'ok');
        Observer.Expect('remove_unknown', 'ok');
        Observer.Expect('remove_wrong_uri', 'ok');
        Observer.Expect('q_after_wrong_uri', 'Yes:Yes:[urn:q]');
        Observer.Expect('remove_empty', 'ok');
        Observer.Expect('remove_xml', 'ok');
        Observer.Expect('xml_after', 'No:Yes:[http://www.w3.org/XML/1998/namespace]');
        Observer.Verify();
    end;

    [Test]
    procedure P104_RemoveNamespace_InScope()
    var
        Observer: Codeunit "Probe Observer";
        Mgr: XmlNamespaceManager;
    begin
        Mgr.AddNamespace('p', 'urn:outer');
        Mgr.PushScope();
        Mgr.AddNamespace('q', 'urn:inner');
        Mgr.RemoveNamespace('p', 'urn:outer');
        Has(Observer, Mgr, 'inner_p_removed', 'p');
        Mgr.RemoveNamespace('q', 'urn:inner');
        Has(Observer, Mgr, 'inner_q_removed', 'q');
        Mgr.PopScope();
        Has(Observer, Mgr, 'outer_p_after_pop', 'p');
        Has(Observer, Mgr, 'outer_q_after_pop', 'q');
        Mgr.AddNamespace('p', 'urn:one');
        Mgr.AddNamespace('p', 'urn:two');
        Mgr.RemoveNamespace('p', 'urn:one');
        Has(Observer, Mgr, 'p_redefined_remove_old', 'p');
        Mgr.RemoveNamespace('p', 'urn:two');
        Has(Observer, Mgr, 'p_redefined_remove_new', 'p');
        Observer.Expect('inner_p_removed', 'No:Yes:[urn:outer]');
        Observer.Expect('inner_q_removed', 'No:No:[]');
        Observer.Expect('outer_p_after_pop', 'Yes:Yes:[urn:outer]');
        Observer.Expect('outer_q_after_pop', 'No:No:[]');
        Observer.Expect('p_redefined_remove_old', 'Yes:Yes:[urn:two]');
        Observer.Expect('p_redefined_remove_new', 'No:No:[]');
        Observer.Verify();
    end;
}
