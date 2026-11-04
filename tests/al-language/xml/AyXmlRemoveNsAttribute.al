// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlelement/xmlelement-removeattribute-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 80501
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: XmlElement.RemoveAttribute by name, by local name and namespace, and by XmlAttribute object on prefixed (namespaced) attributes: whether the
// prefixed name, the bare local name, the right and the wrong namespace match; which attribute goes when two share a local name; the element text after.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 80501 "LT AY Xml Remove Ns Attribute"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure NewElement(var E: XmlElement)
    var
        Doc: XmlDocument;
    begin
        XmlDocument.ReadFrom('<r xmlns:p="urn:p" xmlns:q="urn:q" p:a="1" q:a="2" a="3" p:b="4"/>', Doc);
        Doc.GetRoot(E);
    end;

    local procedure Show(E: XmlElement): Text
    var
        T: Text;
    begin
        E.WriteTo(T);
        exit(T);
    end;

    [TryFunction]
    local procedure TryRemoveName(var E: XmlElement; Name: Text)
    begin
        E.RemoveAttribute(Name);
    end;

    [TryFunction]
    local procedure TryRemoveNs(var E: XmlElement; LocalName: Text; Ns: Text)
    begin
        E.RemoveAttribute(LocalName, Ns);
    end;

    [TryFunction]
    local procedure TryRemoveObj(var E: XmlElement; A: XmlAttribute)
    begin
        E.RemoveAttribute(A);
    end;

    local procedure ByName(var Observer: Codeunit "Probe Observer"; ObsKey: Text; Name: Text)
    var
        E: XmlElement;
    begin
        NewElement(E);
        if TryRemoveName(E, Name) then
            Observer.Observe(ObsKey, Show(E))
        else
            Observer.ObserveError(ObsKey);
    end;

    local procedure ByNs(var Observer: Codeunit "Probe Observer"; ObsKey: Text; LocalName: Text; Ns: Text)
    var
        E: XmlElement;
    begin
        NewElement(E);
        if TryRemoveNs(E, LocalName, Ns) then
            Observer.Observe(ObsKey, Show(E))
        else
            Observer.ObserveError(ObsKey);
    end;

    [Test]
    procedure RemoveAttribute_ByName_PrefixedPA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByName(Observer, 'name_prefixed_pa', 'p:a');
        Observer.Expect('name_prefixed_pa|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('name_prefixed_pa|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAttribute_ByName_PrefixedQA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByName(Observer, 'name_prefixed_qa', 'q:a');
        Observer.Expect('name_prefixed_qa|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('name_prefixed_qa|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAttribute_ByName_LocalA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByName(Observer, 'name_local_a', 'a');
        Observer.Expect('name_local_a', '<r xmlns:p="urn:p" xmlns:q="urn:q" p:a="1" q:a="2" p:b="4" />');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAttribute_ByName_LocalB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByName(Observer, 'name_local_b', 'b');
        Observer.Expect('name_local_b', '<r xmlns:p="urn:p" xmlns:q="urn:q" p:a="1" q:a="2" a="3" p:b="4" />');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAttribute_ByName_PrefixedPB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByName(Observer, 'name_prefixed_pb', 'p:b');
        Observer.Expect('name_prefixed_pb|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('name_prefixed_pb|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAttribute_ByName_UnknownPrefix()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByName(Observer, 'name_unknown_prefix', 'z:a');
        Observer.Expect('name_unknown_prefix|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('name_unknown_prefix|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAttribute_ByName_Prefixed_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByName(Observer, 'name_case', 'P:A');
        Observer.Expect('name_case|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('name_case|code', 'Xml:Xml');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAttribute_ByLocalNameAndNamespace_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByNs(Observer, 'ns_a_p', 'a', 'urn:p');
        ByNs(Observer, 'ns_a_q', 'a', 'urn:q');
        ByNs(Observer, 'ns_a_empty', 'a', '');
        Observer.Expect('ns_a_p', '<r xmlns:p="urn:p" xmlns:q="urn:q" q:a="2" a="3" p:b="4" />');
        Observer.Expect('ns_a_q', '<r xmlns:p="urn:p" xmlns:q="urn:q" p:a="1" a="3" p:b="4" />');
        Observer.Expect('ns_a_empty', '<r xmlns:p="urn:p" xmlns:q="urn:q" p:a="1" q:a="2" p:b="4" />');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAttribute_ByLocalNameAndNamespace_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByNs(Observer, 'ns_b_p', 'b', 'urn:p');
        ByNs(Observer, 'ns_b_q', 'b', 'urn:q');
        ByNs(Observer, 'ns_b_empty', 'b', '');
        Observer.Expect('ns_b_p', '<r xmlns:p="urn:p" xmlns:q="urn:q" p:a="1" q:a="2" a="3" />');
        Observer.Expect('ns_b_q', '<r xmlns:p="urn:p" xmlns:q="urn:q" p:a="1" q:a="2" a="3" p:b="4" />');
        Observer.Expect('ns_b_empty', '<r xmlns:p="urn:p" xmlns:q="urn:q" p:a="1" q:a="2" a="3" p:b="4" />');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAttribute_ByLocalNameAndNamespace_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ByNs(Observer, 'ns_prefixed_local', 'p:a', 'urn:p');
        ByNs(Observer, 'ns_unknown', 'a', 'urn:z');
        Observer.Expect('ns_prefixed_local|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('ns_prefixed_local|code', 'Xml:Xml');
        Observer.Expect('ns_unknown', '<r xmlns:p="urn:p" xmlns:q="urn:q" p:a="1" q:a="2" a="3" p:b="4" />');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAttribute_ByObject_Prefixed()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
        Other: XmlElement;
        A: XmlAttribute;
        Free: XmlAttribute;
    begin
        NewElement(E);
        E.Attributes().Get('a', 'urn:q', A);
        Observer.Observe('obj_found', A.Name() + '|' + A.LocalName() + '|' + A.NamespaceUri() + '|' + A.Value());
        if TryRemoveObj(E, A) then
            Observer.Observe('obj_qa', Show(E))
        else
            Observer.ObserveError('obj_qa');
        if TryRemoveObj(E, A) then
            Observer.Observe('obj_qa_again', Show(E))
        else
            Observer.ObserveError('obj_qa_again');
        // an attribute with the same name and namespace that belongs to another element
        NewElement(Other);
        Other.Attributes().Get('a', 'urn:p', A);
        if TryRemoveObj(E, A) then
            Observer.Observe('obj_other_pa', Show(E) + ' other=' + Show(Other))
        else
            Observer.ObserveError('obj_other_pa');
        // a detached attribute created with the same namespace and local name
        Free := XmlAttribute.Create('a', 'urn:p', '1');
        if TryRemoveObj(E, Free) then
            Observer.Observe('obj_free_pa', Show(E))
        else
            Observer.ObserveError('obj_free_pa');
        Observer.Expect('obj_found', 'q:a|a|urn:q|2');
        Observer.Expect('obj_qa', '<r xmlns:p="urn:p" xmlns:q="urn:q" p:a="1" a="3" p:b="4" />');
        Observer.Expect('obj_qa_again', '<r xmlns:p="urn:p" xmlns:q="urn:q" p:a="1" a="3" p:b="4" />');
        Observer.Expect('obj_other_pa', '<r xmlns:p="urn:p" xmlns:q="urn:q" a="3" p:b="4" /> other=<r xmlns:p="urn:p" xmlns:q="urn:q" p:a="1" q:a="2" a="3" p:b="4" />');
        Observer.Expect('obj_free_pa', '<r xmlns:p="urn:p" xmlns:q="urn:q" a="3" p:b="4" />');
        Observer.Verify();
    end;
}
