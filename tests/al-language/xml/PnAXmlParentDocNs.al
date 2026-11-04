// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: XML: GetParent of a root element and GetDocument of a detached element are false when the result is used
// Facts: XmlNode.GetParent / GetDocument and XmlElement.GetNamespaceOfPrefix / GetPrefixOfNamespace, result used and result unused
// BC versions: 29 (27 and 28 by CI)

codeunit 70083 "LT PnA Xml ParentDocNs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Doc: XmlDocument;
        Root: XmlElement;
        Detached: XmlElement;
        ParentEl: XmlElement;
        DocOut: XmlDocument;
        Res: Text;

    local procedure Setup()
    begin
        XmlDocument.ReadFrom('<r xmlns:p="urn:p" xmlns="urn:d"><p:a><b/></p:a></r>', Doc);
        Doc.GetRoot(Root);
        Detached := XmlElement.Create('x');
    end;

    [TryFunction]
    local procedure TryOp(Op: Integer)
    var
        Ns: Text;
        Pf: Text;
    begin
        Res := '';
        case Op of
            1:
                Root.AsXmlNode().GetParent(ParentEl);
            2:
                Detached.AsXmlNode().GetParent(ParentEl);
            3:
                Root.AsXmlNode().GetDocument(DocOut);
            4:
                Detached.AsXmlNode().GetDocument(DocOut);
            5:
                Root.GetNamespaceOfPrefix('', Ns);
            6:
                Root.GetNamespaceOfPrefix('p', Ns);
            7:
                Root.GetNamespaceOfPrefix('zz', Ns);
            8:
                Root.GetPrefixOfNamespace('urn:p', Pf);
            9:
                Root.GetPrefixOfNamespace('urn:d', Pf);
            10:
                Root.GetPrefixOfNamespace('urn:zz', Pf);
            11:
                Detached.GetNamespaceOfPrefix('', Ns);
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Op: Integer)
    begin
        Observer.Observe(Name, Format(TryOp(Op)));
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure ResultUnused()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Setup();
        for i := 1 to 11 do
            Probe(Observer, 'op' + Format(i), i);
        Observer.Expect('op1', 'No');
        Observer.Expect('op1|text', 'The XML node is not set.');
        Observer.Expect('op1|code', 'XmlNodeNotFound');
        Observer.Expect('op2', 'No');
        Observer.Expect('op2|text', 'The XML node is not set.');
        Observer.Expect('op2|code', 'XmlNodeNotFound');
        Observer.Expect('op3', 'Yes');
        Observer.Expect('op3|text', '');
        Observer.Expect('op3|code', '');
        Observer.Expect('op4', 'No');
        Observer.Expect('op4|text', 'The XML node is not set.');
        Observer.Expect('op4|code', 'XmlNodeNotFound');
        Observer.Expect('op5', 'No');
        Observer.Expect('op5|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('op5|code', 'Argument');
        Observer.Expect('op6', 'Yes');
        Observer.Expect('op6|text', '');
        Observer.Expect('op6|code', '');
        Observer.Expect('op7', 'No');
        Observer.Expect('op7|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('op7|code', 'Argument');
        Observer.Expect('op8', 'Yes');
        Observer.Expect('op8|text', '');
        Observer.Expect('op8|code', '');
        Observer.Expect('op9', 'Yes');
        Observer.Expect('op9|text', '');
        Observer.Expect('op9|code', '');
        Observer.Expect('op10', 'Yes');
        Observer.Expect('op10|text', '');
        Observer.Expect('op10|code', '');
        Observer.Expect('op11', 'No');
        Observer.Expect('op11|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('op11|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure ResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        Ns: Text;
        Pf: Text;
    begin
        Setup();
        Observer.Observe('root-parent', Format(Root.AsXmlNode().GetParent(ParentEl)));
        Observer.Observe('detached-parent', Format(Detached.AsXmlNode().GetParent(ParentEl)));
        Observer.Observe('root-document', Format(Root.AsXmlNode().GetDocument(DocOut)));
        Observer.Observe('detached-document', Format(Detached.AsXmlNode().GetDocument(DocOut)));
        Observer.Observe('empty-prefix', Format(Root.GetNamespaceOfPrefix('', Ns)));
        Observer.Observe('empty-prefix-ns', Ns);
        Observer.Observe('p-prefix', Format(Root.GetNamespaceOfPrefix('p', Ns)));
        Observer.Observe('p-prefix-ns', Ns);
        Observer.Observe('unknown-prefix', Format(Root.GetNamespaceOfPrefix('zz', Ns)));
        Observer.Observe('unknown-prefix-ns', Ns);
        Observer.Observe('prefix-of-p', Format(Root.GetPrefixOfNamespace('urn:p', Pf)));
        Observer.Observe('prefix-of-p-value', Pf);
        Observer.Observe('prefix-of-default', Format(Root.GetPrefixOfNamespace('urn:d', Pf)));
        Observer.Observe('prefix-of-default-value', Pf);
        Observer.Observe('prefix-of-unknown', Format(Root.GetPrefixOfNamespace('urn:zz', Pf)));
        Observer.Observe('detached-empty-prefix', Format(Detached.GetNamespaceOfPrefix('', Ns)));
        Observer.Expect('root-parent', 'No');
        Observer.Expect('detached-parent', 'No');
        Observer.Expect('root-document', 'Yes');
        Observer.Expect('detached-document', 'No');
        Observer.Expect('empty-prefix', 'No');
        Observer.Expect('empty-prefix-ns', '');
        Observer.Expect('p-prefix', 'Yes');
        Observer.Expect('p-prefix-ns', 'urn:p');
        Observer.Expect('unknown-prefix', 'No');
        Observer.Expect('unknown-prefix-ns', 'urn:p');
        Observer.Expect('prefix-of-p', 'Yes');
        Observer.Expect('prefix-of-p-value', 'p');
        Observer.Expect('prefix-of-default', 'Yes');
        Observer.Expect('prefix-of-default-value', '');
        Observer.Expect('prefix-of-unknown', 'Yes');
        Observer.Expect('detached-empty-prefix', 'No');
        Observer.Verify();
    end;
}
