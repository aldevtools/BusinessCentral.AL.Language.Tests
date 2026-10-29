// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: XML: adding a node that already has a parent copies it, a free node is shared
// Facts: XmlElement.Add / XmlDocument.Add: copy vs share, second root, duplicate attribute, node into a wrong container
// BC versions: 29 (27 and 28 by CI)

codeunit 70082 "LT PnA Xml NodeAdds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Doc: XmlDocument;
        Doc2: XmlDocument;
        E1: XmlElement;
        E2: XmlElement;
        C: XmlElement;
        Res: Text;

    [TryFunction]
    local procedure TryOp(Op: Integer)
    begin
        Res := '';
        case Op of
            1:
                Doc.Add(E1);
            2:
                Doc.Add(E2);
            3:
                E1.Add(XmlAttribute.Create('a', '1'));
            4:
                E1.Add(XmlAttribute.Create('a', '2'));
            5:
                Doc.Add(XmlAttribute.Create('a', '1'));
            6:
                Doc.Add(XmlText.Create('x'));
            7:
                Doc.Add(XmlComment.Create('c'));
            8:
                Doc.Add(XmlCData.Create('c'));
            9:
                E1.Add(Doc2.AsXmlNode());
            10:
                E1.Add(E1);
            11:
                E1.Add(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
            12:
                Doc.Add(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
            13:
                Doc.Add(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
            14:
                E1.Add(E2);
            15:
                Doc.Add(C);
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Op: Integer)
    begin
        Observer.Observe(Name, Format(TryOp(Op)));
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure AddNodeWithParent_Copies_FreeNode_Shared()
    var
        Observer: Codeunit "Probe Observer";
        Probe1: XmlElement;
        N: XmlNode;
        P: XmlElement;
        T: Text;
    begin
        E1 := XmlElement.Create('e1');
        E2 := XmlElement.Create('e2');
        C := XmlElement.Create('c');
        E1.Add(C);
        C.SetAttribute('after-first-add', '1');
        E1.WriteTo(T);
        Observer.Observe('e1-after-attr-on-free-child', T);
        E2.Add(C);
        Observer.Observe('child-parent-is-e1-or-e2', Format(C.AsXmlNode().GetParent(P)));
        Observer.Observe('child-parent-name', P.Name());
        C.SetAttribute('after-second-add', '1');
        E1.WriteTo(T);
        Observer.Observe('e1-after-second-attr', T);
        E2.WriteTo(T);
        Observer.Observe('e2-after-second-attr', T);
        Observer.Observe('e1-children', Format(E1.GetChildNodes().Count()));
        Observer.Observe('e2-children', Format(E2.GetChildNodes().Count()));
        Observer.Observe('same-node', Format(E1.GetChildNodes().Get(1, N)));
        N.AsXmlElement().SetAttribute('via-e1', 'x');
        E2.WriteTo(T);
        Observer.Observe('e2-after-change-through-e1', T);
        C.WriteTo(T);
        Observer.Observe('c-itself', T);
        Observer.Expect('e1-after-attr-on-free-child', '<e1>\r\n  <c after-first-add="1" />\r\n</e1>');
        Observer.Expect('child-parent-is-e1-or-e2', 'Yes');
        Observer.Expect('child-parent-name', 'e1');
        Observer.Expect('e1-after-second-attr', '<e1>\r\n  <c after-first-add="1" after-second-add="1" />\r\n</e1>');
        Observer.Expect('e2-after-second-attr', '<e2>\r\n  <c after-first-add="1" />\r\n</e2>');
        Observer.Expect('e1-children', '1');
        Observer.Expect('e2-children', '1');
        Observer.Expect('same-node', 'Yes');
        Observer.Expect('e2-after-change-through-e1', '<e2>\r\n  <c after-first-add="1" />\r\n</e2>');
        Observer.Expect('c-itself', '<c after-first-add="1" after-second-add="1" via-e1="x" />');
        Observer.Verify();
    end;

    [Test]
    procedure InvalidAdds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc := XmlDocument.Create();
        Doc2 := XmlDocument.Create();
        E1 := XmlElement.Create('e1');
        E2 := XmlElement.Create('e2');
        C := XmlElement.Create('c');
        Probe(Observer, 'doc-first-root', 1);
        Probe(Observer, 'doc-second-root', 2);
        Probe(Observer, 'attribute-first', 3);
        Probe(Observer, 'attribute-twice', 4);
        Probe(Observer, 'attribute-into-document', 5);
        Probe(Observer, 'text-into-document', 6);
        Probe(Observer, 'comment-into-document', 7);
        Probe(Observer, 'cdata-into-document', 8);
        Probe(Observer, 'document-into-element', 9);
        Probe(Observer, 'element-into-itself', 10);
        Probe(Observer, 'declaration-into-element', 11);
        Probe(Observer, 'declaration-into-document', 12);
        Probe(Observer, 'declaration-into-document-again', 13);
        Probe(Observer, 'element-into-element', 14);
        Probe(Observer, 'free-element-into-document-with-root', 15);
        Observer.Expect('doc-first-root', 'Yes');
        Observer.Expect('doc-first-root|text', '');
        Observer.Expect('doc-first-root|code', '');
        Observer.Expect('doc-second-root', 'No');
        Observer.Expect('doc-second-root|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('doc-second-root|code', 'InvalidOperation');
        Observer.Expect('attribute-first', 'Yes');
        Observer.Expect('attribute-first|text', '');
        Observer.Expect('attribute-first|code', '');
        Observer.Expect('attribute-twice', 'No');
        Observer.Expect('attribute-twice|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('attribute-twice|code', 'InvalidOperation');
        Observer.Expect('attribute-into-document', 'No');
        Observer.Expect('attribute-into-document|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('attribute-into-document|code', 'Argument');
        Observer.Expect('text-into-document', 'No');
        Observer.Expect('text-into-document|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('text-into-document|code', 'Argument');
        Observer.Expect('comment-into-document', 'Yes');
        Observer.Expect('comment-into-document|text', '');
        Observer.Expect('comment-into-document|code', '');
        Observer.Expect('cdata-into-document', 'No');
        Observer.Expect('cdata-into-document|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('cdata-into-document|code', 'Argument');
        Observer.Expect('document-into-element', 'No');
        Observer.Expect('document-into-element|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('document-into-element|code', 'Argument');
        Observer.Expect('element-into-itself', 'Yes');
        Observer.Expect('element-into-itself|text', '');
        Observer.Expect('element-into-itself|code', '');
        Observer.Expect('declaration-into-element', 'Yes');
        Observer.Expect('declaration-into-element|text', '');
        Observer.Expect('declaration-into-element|code', '');
        Observer.Expect('declaration-into-document', 'No');
        Observer.Expect('declaration-into-document|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('declaration-into-document|code', 'Argument');
        Observer.Expect('declaration-into-document-again', 'No');
        Observer.Expect('declaration-into-document-again|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('declaration-into-document-again|code', 'Argument');
        Observer.Expect('element-into-element', 'Yes');
        Observer.Expect('element-into-element|text', '');
        Observer.Expect('element-into-element|code', '');
        Observer.Expect('free-element-into-document-with-root', 'No');
        Observer.Expect('free-element-into-document-with-root|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('free-element-into-document-with-root|code', 'InvalidOperation');
        Observer.Verify();
    end;

    // Writer TT: empty and blank texts added to an XmlDocument (XmlDocument.Create with text arguments, XmlDocument.Add of an XmlText or a
    // Text): does the add fail, what does WriteTo give, how many child nodes does the document hold, and can a root still be added?
    [TryFunction]
    local procedure TtTryDocText(Kind: Integer; var Result: Text)
    var
        D: XmlDocument;
        Lf: Text[1];
        Out: Text;
    begin
        Lf[1] := 10;
        case Kind of
            1:
                D := XmlDocument.Create('', '');
            2:
                D := XmlDocument.Create(' ');
            3:
                begin
                    D := XmlDocument.Create();
                    D.Add(XmlText.Create(''));
                end;
            4:
                begin
                    D := XmlDocument.Create();
                    D.Add(XmlText.Create('  '));
                end;
            5:
                begin
                    D := XmlDocument.Create();
                    D.Add(XmlElement.Create('r'));
                    D.Add(XmlText.Create(''));
                end;
            6:
                begin
                    D := XmlDocument.Create();
                    D.Add('');
                end;
            7:
                begin
                    D := XmlDocument.Create();
                    D.Add(XmlText.Create(Lf + '  '));
                end;
            8:
                begin
                    D := XmlDocument.Create();
                    D.Add(XmlElement.Create('r'));
                    D.Add(XmlText.Create(' '));
                end;
        end;
        Result := 'created nodes=' + Format(D.GetChildNodes().Count());
        D.WriteTo(Out);
        Result += ' xml=' + Out;
        D.Add(XmlElement.Create('root'));
        D.WriteTo(Out);
        Result += ' with root nodes=' + Format(D.GetChildNodes().Count()) + ' xml=' + Out;
    end;

    local procedure TtDocText(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Integer)
    var
        Result: Text;
    begin
        ClearLastError();
        if TtTryDocText(Kind, Result) then
            Observer.Observe(Name, 'ok ' + Result)
        else begin
            Observer.Observe(Name, 'failed after: ' + Result);
            Observer.ObserveError(Name);
        end;
    end;

    [Test]
    procedure TT_EmptyOrBlankTextIntoXmlDocument()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        Out: Text;
    begin
        Observer.Discard();
        TtDocText(Observer, 'create two empty texts', 1);
        TtDocText(Observer, 'create one blank text', 2);
        TtDocText(Observer, 'add empty XmlText', 3);
        TtDocText(Observer, 'add blank XmlText', 4);
        TtDocText(Observer, 'add empty XmlText after root', 5);
        TtDocText(Observer, 'add empty Text', 6);
        TtDocText(Observer, 'add line feed and blanks', 7);
        TtDocText(Observer, 'add blank XmlText after root', 8);
        // the shape of a document built for a web service request: two empty texts, a declaration, then the root
        D := XmlDocument.Create('', '');
        D.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'yes'));
        D.Add(XmlElement.Create('request', '', XmlElement.Create('id', '', '42')));
        D.WriteTo(Out);
        Observer.Observe('request', Out);
        Observer.Observe('request nodes', Format(D.GetChildNodes().Count()));
        Observer.Finish();
        Observer.Verify();
    end;
}
