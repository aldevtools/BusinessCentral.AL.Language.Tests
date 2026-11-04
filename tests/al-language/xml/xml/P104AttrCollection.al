// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlattributecollection/xmlattributecollection-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table LT P104 Blob where an OutStream is written
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlAttributeCollection.Remove(XmlAttribute) and RemoveAll, next to the Remove by name overloads
// BC versions: 29 (27 and 28 by CI)

codeunit 71829 "LT P104 AttrCollection"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Three(var E: XmlElement)
    begin
        E := XmlElement.Create('e');
        E.SetAttribute('a', '1');
        E.SetAttribute('b', '2');
        E.SetAttribute('c', 'urn:x', '3');
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; var E: XmlElement; var C: XmlAttributeCollection)
    var
        S: Text;
    begin
        E.WriteTo(S);
        Observer.Observe(Name + '_element', S);
        Observer.Observe(Name + '_count', Format(C.Count()));
    end;

    [Test]
    procedure P104_Remove_Attribute()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
        C: XmlAttributeCollection;
        At: XmlAttribute;
    begin
        Three(E);
        C := E.Attributes();
        C.Get('b', At);
        C.Remove(At);
        Show(Observer, 'removed_b', E, C);
        Observer.Observe('removed_value', At.Value());
        C.Get('c', 'urn:x', At);
        C.Remove(At);
        Show(Observer, 'removed_c', E, C);
        C.Get(1, At);
        C.Remove(At);
        Show(Observer, 'removed_last', E, C);
        Observer.Expect('removed_b_element', '<e a="1" p1:c="3" xmlns:p1="urn:x" />');
        Observer.Expect('removed_b_count', '2');
        Observer.Expect('removed_value', '2');
        Observer.Expect('removed_c_element', '<e a="1" />');
        Observer.Expect('removed_c_count', '1');
        Observer.Expect('removed_last_element', '<e />');
        Observer.Expect('removed_last_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P104_RemoveAll()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
        C: XmlAttributeCollection;
        At: XmlAttribute;
    begin
        Three(E);
        C := E.Attributes();
        C.RemoveAll();
        Show(Observer, 'all', E, C);
        C.RemoveAll();
        Show(Observer, 'again', E, C);
        C.Set('n', 'new');
        Show(Observer, 'set_after', E, C);
        Observer.Observe('get_after', Format(C.Get('n', At)));
        Observer.Observe('get_removed', Format(C.Get('a', At)));
        E := XmlElement.Create('empty');
        C := E.Attributes();
        C.RemoveAll();
        Show(Observer, 'empty', E, C);
        Observer.Expect('all_element', '<e />');
        Observer.Expect('all_count', '0');
        Observer.Expect('again_element', '<e />');
        Observer.Expect('again_count', '0');
        Observer.Expect('set_after_element', '<e n="new" />');
        Observer.Expect('set_after_count', '1');
        Observer.Expect('get_after', 'Yes');
        Observer.Expect('get_removed', 'No');
        Observer.Expect('empty_element', '<empty />');
        Observer.Expect('empty_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P104_RemoveAll_KeepsChildren()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
        C: XmlAttributeCollection;
        Doc: XmlDocument;
        S: Text;
    begin
        E := XmlElement.Create('e', XmlElement.Create('c'), XmlText.Create('t'));
        E.SetAttribute('a', '1');
        asserterror E.SetAttribute('xmlns:p', 'urn:p');
        Observer.ObserveError('af121');
        Doc := XmlDocument.Create();
        Doc.Add(E);
        C := E.Attributes();
        Observer.Observe('before_count', Format(C.Count()));
        C.RemoveAll();
        Doc.WriteTo(S);
        Observer.Observe('doc', S);
        Observer.Observe('after_count', Format(C.Count()));
        Observer.Expect('af121|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 6.');
        Observer.Expect('af121|code', 'Xml:Xml');
        Observer.Expect('before_count', '1');
        Observer.Expect('doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<e>\r\n  <c />t</e>');
        Observer.Expect('after_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Remove_ByName_Overloads()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
        C: XmlAttributeCollection;
    begin
        Three(E);
        C := E.Attributes();
        C.Remove('a');
        Show(Observer, 'by_name', E, C);
        C.Remove('c', 'urn:x');
        Show(Observer, 'by_local_ns', E, C);
        C.Remove('missing');
        Show(Observer, 'missing_name', E, C);
        C.Remove('missing', 'urn:y');
        Show(Observer, 'missing_ns', E, C);
        C.Remove('b', 'urn:x');
        Show(Observer, 'b_with_wrong_ns', E, C);
        Observer.Expect('by_name_element', '<e b="2" p1:c="3" xmlns:p1="urn:x" />');
        Observer.Expect('by_name_count', '2');
        Observer.Expect('by_local_ns_element', '<e b="2" />');
        Observer.Expect('by_local_ns_count', '1');
        Observer.Expect('missing_name_element', '<e b="2" />');
        Observer.Expect('missing_name_count', '1');
        Observer.Expect('missing_ns_element', '<e b="2" />');
        Observer.Expect('missing_ns_count', '1');
        Observer.Expect('b_with_wrong_ns_element', '<e b="2" />');
        Observer.Expect('b_with_wrong_ns_count', '1');
        Observer.Verify();
    end;
}
