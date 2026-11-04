// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/XmlCData/xmlcdata-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own table LT P90 Blob (table 70729)
// Probe: written against BC 29 (local service tier); the observed values become the assertions. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlCData AsXmlNode, GetDocument, GetParent, SelectNodes, SelectSingleNode, WriteTo (Text and OutStream), content edge cases, uninitialised variables
// BC versions: 29 (27 and 28 by CI)

codeunit 70731 "LT P90 CData Read"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Doc: XmlDocument;
        Root: XmlElement;
        X: XmlCData;
        U: XmlCData;
        UN: XmlNode;
        Res: Text;
        Lst: XmlNodeList;
        OutS: OutStream;

    local procedure MakeX(Tag: Text): XmlCData
    var
        R: XmlCData;
    begin
        R := XmlCData.Create(Tag);
        exit(R);
    end;

    // Pos: 0 = only child of r, 1 = first, 2 = middle (default), 3 = last child of r (siblings a and b)
    local procedure BuildAt(Attached: Boolean; Pos: Integer; Tag: Text)
    var
        N: XmlNode;
        Fresh: XmlCData;
        Idx: Integer;
    begin
        Fresh := MakeX(Tag);
        if not Attached then begin
            X := Fresh;
            exit;
        end;
        Doc := XmlDocument.Create();
        Root := XmlElement.Create('r');
        if Pos = 0 then
            Root.Add(Fresh)
        else begin
            if Pos = 1 then
                Root.Add(Fresh);
            Root.Add(XmlElement.Create('a'));
            if Pos = 2 then
                Root.Add(Fresh);
            Root.Add(XmlElement.Create('b'));
            if Pos = 3 then
                Root.Add(Fresh);
        end;
        Doc.Add(Root);
        Doc.GetRoot(Root);
        Idx := Pos;
        if Pos = 0 then
            Idx := 1;
        Root.GetChildNodes().Get(Idx, N);
        X := N.AsXmlCData();
    end;

    local procedure Build(Attached: Boolean; Tag: Text)
    begin
        BuildAt(Attached, 2, Tag);
    end;

    local procedure SerDoc(): Text
    var
        S: Text;
    begin
        Doc.WriteTo(S);
        exit(S);
    end;

    local procedure SerX(): Text
    var
        S: Text;
    begin
        X.WriteTo(S);
        exit(S);
    end;

    local procedure SerNode(N: XmlNode): Text
    var
        S: Text;
    begin
        N.WriteTo(S);
        exit(S);
    end;

    // Kinds: 1 element, 2 text, 3 comment, 4 cdata, 5 processing instruction, 6 attribute, 7 declaration, 8 document,
    // 9 document type, 10 sibling element a of X (has a parent), 11 X itself, 12 the root r (ancestor of X),
    // 13 root element of another document, 14 uninitialised XmlNode, 101..103 elements m1..m3
    local procedure MakeArg(Kind: Integer): XmlNode
    var
        E: XmlElement;
        T: XmlText;
        C: XmlComment;
        D: XmlCData;
        P: XmlProcessingInstruction;
        A: XmlAttribute;
        Decl: XmlDeclaration;
        Doc2: XmlDocument;
        DT: XmlDocumentType;
        N: XmlNode;
    begin
        case Kind of
            1:
                begin
                    E := XmlElement.Create('e1');
                    exit(E.AsXmlNode());
                end;
            2:
                begin
                    T := XmlText.Create('t2');
                    exit(T.AsXmlNode());
                end;
            3:
                begin
                    C := XmlComment.Create('c3');
                    exit(C.AsXmlNode());
                end;
            4:
                begin
                    D := XmlCData.Create('d4');
                    exit(D.AsXmlNode());
                end;
            5:
                begin
                    P := XmlProcessingInstruction.Create('p5', 'q5');
                    exit(P.AsXmlNode());
                end;
            6:
                begin
                    A := XmlAttribute.Create('a6', '1');
                    exit(A.AsXmlNode());
                end;
            7:
                begin
                    Decl := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
                    exit(Decl.AsXmlNode());
                end;
            8:
                begin
                    Doc2 := XmlDocument.Create();
                    exit(Doc2.AsXmlNode());
                end;
            9:
                begin
                    DT := XmlDocumentType.Create('dt9');
                    exit(DT.AsXmlNode());
                end;
            10:
                begin
                    Root.SelectSingleNode('a', N);
                    exit(N);
                end;
            11:
                exit(X.AsXmlNode());
            12:
                exit(Root.AsXmlNode());
            13:
                begin
                    Doc2 := XmlDocument.Create();
                    Doc2.Add(XmlElement.Create('f13'));
                    Doc2.GetRoot(E);
                    exit(E.AsXmlNode());
                end;
            14:
                exit(UN);
            101, 102, 103:
                begin
                    E := XmlElement.Create('m' + Format(Kind - 100));
                    exit(E.AsXmlNode());
                end;
        end;
    end;

    [TryFunction]
    local procedure TryAfter(Kind: Integer)
    begin
        X.AddAfterSelf(MakeArg(Kind));
    end;

    [TryFunction]
    local procedure TryBefore(Kind: Integer)
    begin
        X.AddBeforeSelf(MakeArg(Kind));
    end;

    [TryFunction]
    local procedure TryReplace(Kind: Integer)
    begin
        X.ReplaceWith(MakeArg(Kind));
    end;

    [TryFunction]
    local procedure TryRemove()
    begin
        X.Remove();
    end;

    [TryFunction]
    local procedure TryAfter3(A: Integer; B: Integer; C: Integer)
    begin
        X.AddAfterSelf(MakeArg(A), MakeArg(B), MakeArg(C));
    end;

    [TryFunction]
    local procedure TryBefore3(A: Integer; B: Integer; C: Integer)
    begin
        X.AddBeforeSelf(MakeArg(A), MakeArg(B), MakeArg(C));
    end;

    [TryFunction]
    local procedure TryReplace3(A: Integer; B: Integer; C: Integer)
    begin
        X.ReplaceWith(MakeArg(A), MakeArg(B), MakeArg(C));
    end;

    local procedure GetV(Node: XmlCData): Text
    begin
        exit(Node.Value());
    end;

    [TryFunction]
    local procedure TrySetV(NewValue: Text)
    begin
        X.Value(NewValue);
    end;

    [TryFunction]
    local procedure TrySelNodes(XPath: Text)
    begin
        X.SelectNodes(XPath, Lst);
    end;

    [TryFunction]
    local procedure TrySelSingle(XPath: Text; var Found: XmlNode)
    begin
        X.SelectSingleNode(XPath, Found);
    end;

    local procedure SelN(var Observer: Codeunit "Probe Observer"; Name: Text; XPath: Text)
    var
        Ok: Boolean;
        N: XmlNode;
    begin
        Ok := TrySelNodes(XPath);
        Observer.Observe(Name, Format(Ok));
        Observer.ObserveError(Name + '-err');
        if Ok then begin
            Observer.Observe(Name + '-n', Format(Lst.Count()));
            if Lst.Count() > 0 then begin
                Lst.Get(1, N);
                Observer.Observe(Name + '-first', SerNode(N));
            end
            else
                Observer.Observe(Name + '-first', '');
        end;
    end;

    local procedure SelS(var Observer: Codeunit "Probe Observer"; Name: Text; XPath: Text)
    var
        Ok: Boolean;
        N: XmlNode;
    begin
        Ok := TrySelSingle(XPath, N);
        Observer.Observe(Name, Format(Ok));
        Observer.ObserveError(Name + '-err');
        if Ok then
            Observer.Observe(Name + '-node', SerNode(N));
    end;

    local procedure ReadBlob(var Blob: Record "LT P90 Blob"): Text
    var
        InS: InStream;
        Line: Text;
        R: Text;
    begin
        Blob.CalcFields(Data);
        Blob.Data.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            R += Line + '|';
        end;
        exit(R);
    end;

    local procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    [TryFunction]
    local procedure TryMake(Tag: Text)
    begin
        X := MakeX(Tag);
    end;

    local procedure ProbeContent(var Observer: Codeunit "Probe Observer"; Name: Text; Tag: Text)
    var
        Ok: Boolean;
    begin
        Ok := TryMake(Tag);
        Observer.Observe(Name, Format(Ok));
        Observer.ObserveError(Name + '-err');
        if Ok then
            Observer.Observe(Name + '-x', SerX());
    end;

    [TryFunction]
    local procedure TryUninit(Op: Integer)
    var
        D: XmlDocument;
        P: XmlElement;
        N: XmlNode;
        L: XmlNodeList;
        S: Text;
        E: XmlElement;
    begin
        Res := '';
        case Op of
            1:
                U.Remove();
            2:
                begin
                    E := XmlElement.Create('e');
                    U.AddAfterSelf(E);
                end;
            3:
                begin
                    E := XmlElement.Create('e');
                    U.AddBeforeSelf(E);
                end;
            4:
                begin
                    N := U.AsXmlNode();
                    Res := SerNode(N);
                end;
            5:
                Res := Format(U.GetDocument(D));
            6:
                Res := Format(U.GetParent(P));
            7:
                begin
                    E := XmlElement.Create('e');
                    U.ReplaceWith(E);
                end;
            8:
                Res := Format(U.SelectNodes('.', L));
            9:
                Res := Format(U.SelectSingleNode('.', N));
            10:
                begin
                    U.WriteTo(S);
                    Res := S;
                end;
            11:
                U.WriteTo(OutS);
            12:
                Res := GetV(U);
            13:
                begin
                    X := U;
                    TrySetV('v');
                end;
        end;
    end;

    [Test]
    procedure AsXmlNode_Flags_Attached()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
    begin
        Build(true, 'x');
        N := X.AsXmlNode();
        Observer.Observe('is-element', Format(N.IsXmlElement()));
        Observer.Observe('is-text', Format(N.IsXmlText()));
        Observer.Observe('is-comment', Format(N.IsXmlComment()));
        Observer.Observe('is-cdata', Format(N.IsXmlCData()));
        Observer.Observe('is-pi', Format(N.IsXmlProcessingInstruction()));
        Observer.Observe('is-attribute', Format(N.IsXmlAttribute()));
        Observer.Observe('is-declaration', Format(N.IsXmlDeclaration()));
        Observer.Observe('is-document', Format(N.IsXmlDocument()));
        Observer.Observe('is-documenttype', Format(N.IsXmlDocumentType()));
        Observer.Observe('node-text', SerNode(N));
        Observer.Expect('is-element', 'No');
        Observer.Expect('is-text', 'No');
        Observer.Expect('is-comment', 'No');
        Observer.Expect('is-cdata', 'Yes');
        Observer.Expect('is-pi', 'No');
        Observer.Expect('is-attribute', 'No');
        Observer.Expect('is-declaration', 'No');
        Observer.Expect('is-document', 'No');
        Observer.Expect('is-documenttype', 'No');
        Observer.Expect('node-text', '<![CDATA[x]]>');
        Observer.Verify();
    end;

    [Test]
    procedure AsXmlNode_Flags_Detached()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
    begin
        Build(false, 'x');
        N := X.AsXmlNode();
        Observer.Observe('is-element', Format(N.IsXmlElement()));
        Observer.Observe('is-text', Format(N.IsXmlText()));
        Observer.Observe('is-comment', Format(N.IsXmlComment()));
        Observer.Observe('is-cdata', Format(N.IsXmlCData()));
        Observer.Observe('is-pi', Format(N.IsXmlProcessingInstruction()));
        Observer.Observe('is-attribute', Format(N.IsXmlAttribute()));
        Observer.Observe('is-declaration', Format(N.IsXmlDeclaration()));
        Observer.Observe('is-document', Format(N.IsXmlDocument()));
        Observer.Observe('is-documenttype', Format(N.IsXmlDocumentType()));
        Observer.Observe('node-text', SerNode(N));
        Observer.Expect('is-element', 'No');
        Observer.Expect('is-text', 'No');
        Observer.Expect('is-comment', 'No');
        Observer.Expect('is-cdata', 'Yes');
        Observer.Expect('is-pi', 'No');
        Observer.Expect('is-attribute', 'No');
        Observer.Expect('is-declaration', 'No');
        Observer.Expect('is-document', 'No');
        Observer.Expect('is-documenttype', 'No');
        Observer.Expect('node-text', '<![CDATA[x]]>');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCast(Op: Integer)
    var
        N: XmlNode;
    begin
        Res := '';
        N := X.AsXmlNode();
        case Op of
            1:
                Res := SerNode(N.AsXmlElement().AsXmlNode());
            2:
                Res := SerNode(N.AsXmlText().AsXmlNode());
            3:
                Res := SerNode(N.AsXmlComment().AsXmlNode());
            4:
                Res := SerNode(N.AsXmlCData().AsXmlNode());
            5:
                Res := SerNode(N.AsXmlProcessingInstruction().AsXmlNode());
            6:
                Res := SerNode(N.AsXmlAttribute().AsXmlNode());
            7:
                Res := SerNode(N.AsXmlDeclaration().AsXmlNode());
            8:
                Res := SerNode(N.AsXmlDocument().AsXmlNode());
            9:
                Res := SerNode(N.AsXmlDocumentType().AsXmlNode());
        end;
    end;

    local procedure CastRange(var Observer: Codeunit "Probe Observer"; Lo: Integer; Hi: Integer)
    var
        i: Integer;
        Ok: Boolean;
    begin
        for i := Lo to Hi do begin
            Ok := TryCast(i);
            Observer.Observe('cast' + Format(i), Format(Ok));
            Observer.ObserveError('cast' + Format(i) + '-err');
            Observer.Observe('cast' + Format(i) + '-res', Res);
        end;
    end;

    [Test]
    procedure AsXmlNode_CastBack_1To5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        CastRange(Observer, 1, 5);
        Observer.Expect('cast1', 'No');
        Observer.Expect('cast1-err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlCData to Microsoft.Dynamics.Nav.Runtime.NavXmlElement.');
        Observer.Expect('cast1-err|code', 'Conversion');
        Observer.Expect('cast1-res', '');
        Observer.Expect('cast2', 'No');
        Observer.Expect('cast2-err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlCData to Microsoft.Dynamics.Nav.Runtime.NavXmlText.');
        Observer.Expect('cast2-err|code', 'Conversion');
        Observer.Expect('cast2-res', '');
        Observer.Expect('cast3', 'No');
        Observer.Expect('cast3-err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlCData to Microsoft.Dynamics.Nav.Runtime.NavXmlComment.');
        Observer.Expect('cast3-err|code', 'Conversion');
        Observer.Expect('cast3-res', '');
        Observer.Expect('cast4', 'Yes');
        Observer.Expect('cast4-err|text', '');
        Observer.Expect('cast4-err|code', '');
        Observer.Expect('cast4-res', '<![CDATA[x]]>');
        Observer.Expect('cast5', 'No');
        Observer.Expect('cast5-err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlCData to Microsoft.Dynamics.Nav.Runtime.NavXmlProcessingInstruction.');
        Observer.Expect('cast5-err|code', 'Conversion');
        Observer.Expect('cast5-res', '');
        Observer.Verify();
    end;

    [Test]
    procedure AsXmlNode_CastBack_6To9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        CastRange(Observer, 6, 9);
        Observer.Expect('cast6', 'No');
        Observer.Expect('cast6-err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlCData to Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute.');
        Observer.Expect('cast6-err|code', 'Conversion');
        Observer.Expect('cast6-res', '');
        Observer.Expect('cast7', 'No');
        Observer.Expect('cast7-err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlCData to Microsoft.Dynamics.Nav.Runtime.NavXmlDeclaration.');
        Observer.Expect('cast7-err|code', 'Conversion');
        Observer.Expect('cast7-res', '');
        Observer.Expect('cast8', 'No');
        Observer.Expect('cast8-err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlCData to Microsoft.Dynamics.Nav.Runtime.NavXmlDocument.');
        Observer.Expect('cast8-err|code', 'Conversion');
        Observer.Expect('cast8-res', '');
        Observer.Expect('cast9', 'No');
        Observer.Expect('cast9-err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlCData to Microsoft.Dynamics.Nav.Runtime.NavXmlDocumentType.');
        Observer.Expect('cast9-err|code', 'Conversion');
        Observer.Expect('cast9-res', '');
        Observer.Verify();
    end;

    [Test]
    procedure AsXmlNode_CastBack_Detached()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(false, 'x');
        CastRange(Observer, 1, 5);
        Observer.Expect('cast1', 'No');
        Observer.Expect('cast1-err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlCData to Microsoft.Dynamics.Nav.Runtime.NavXmlElement.');
        Observer.Expect('cast1-err|code', 'Conversion');
        Observer.Expect('cast1-res', '');
        Observer.Expect('cast2', 'No');
        Observer.Expect('cast2-err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlCData to Microsoft.Dynamics.Nav.Runtime.NavXmlText.');
        Observer.Expect('cast2-err|code', 'Conversion');
        Observer.Expect('cast2-res', '');
        Observer.Expect('cast3', 'No');
        Observer.Expect('cast3-err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlCData to Microsoft.Dynamics.Nav.Runtime.NavXmlComment.');
        Observer.Expect('cast3-err|code', 'Conversion');
        Observer.Expect('cast3-res', '');
        Observer.Expect('cast4', 'Yes');
        Observer.Expect('cast4-err|text', '');
        Observer.Expect('cast4-err|code', '');
        Observer.Expect('cast4-res', '<![CDATA[x]]>');
        Observer.Expect('cast5', 'No');
        Observer.Expect('cast5-err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlCData to Microsoft.Dynamics.Nav.Runtime.NavXmlProcessingInstruction.');
        Observer.Expect('cast5-err|code', 'Conversion');
        Observer.Expect('cast5-res', '');
        Observer.Verify();
    end;

    [Test]
    procedure AsXmlNode_SharesIdentityWithTypedVariable()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
        N2: XmlNode;
        P: XmlElement;
        P2: XmlElement;
        Ok: Boolean;
    begin
        Build(true, 'x');
        N := X.AsXmlNode();
        N2 := X.AsXmlNode();
        Observer.Observe('same-text', Format(SerNode(N) = SerX()));
        Observer.Observe('node-parent-ok', Format(N.GetParent(P)));
        Observer.Observe('typed-parent-ok', Format(X.GetParent(P2)));
        Observer.Observe('parent-names-equal', Format(P.Name() = P2.Name()));
        N.AddAfterSelf(XmlElement.Create('viaNode'));
        Observer.Observe('doc-after-node-add', SerDoc());
        Ok := TrySetV('changed');
        Observer.Observe('set-value', Format(Ok));
        Observer.Observe('node-sees-change', SerNode(N));
        Observer.Observe('n2-sees-change', SerNode(N2));
        Observer.Observe('get-v', GetV(X));
        Observer.Expect('same-text', 'Yes');
        Observer.Expect('node-parent-ok', 'Yes');
        Observer.Expect('typed-parent-ok', 'Yes');
        Observer.Expect('parent-names-equal', 'Yes');
        Observer.Expect('doc-after-node-add', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[x]]><viaNode /><b /></r>');
        Observer.Expect('set-value', 'Yes');
        Observer.Expect('node-sees-change', '<![CDATA[changed]]>');
        Observer.Expect('n2-sees-change', '<![CDATA[changed]]>');
        Observer.Expect('get-v', 'changed');
        Observer.Verify();
    end;

    [Test]
    procedure GetDocument_Attached()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        E: XmlElement;
    begin
        Build(true, 'x');
        Observer.Observe('ok', Format(X.GetDocument(D)));
        Observer.Observe('doc', SerDocOf(D));
        D.GetRoot(E);
        E.SetAttribute('viaD', '1');
        Observer.Observe('original-sees-change', SerDoc());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('original-sees-change', '<?xml version="1.0" encoding="utf-16"?>\r\n<r viaD="1">\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Verify();
    end;

    local procedure SerDocOf(D: XmlDocument): Text
    var
        S: Text;
    begin
        D.WriteTo(S);
        exit(S);
    end;

    [Test]
    procedure GetDocument_Detached_OutputUntouched()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
    begin
        Build(false, 'x');
        Observer.Observe('uninitialised-ok', Format(X.GetDocument(D)));
        D := XmlDocument.Create();
        D.Add(XmlElement.Create('pre'));
        Observer.Observe('preset-ok', Format(X.GetDocument(D)));
        Observer.Observe('preset-doc', SerDocOf(D));
        Observer.Expect('uninitialised-ok', 'No');
        Observer.Expect('preset-ok', 'No');
        Observer.Expect('preset-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<pre />');
        Observer.Verify();
    end;

    [Test]
    procedure GetDocument_AfterRemove_FreeTree_ViaNode()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        N: XmlNode;
        R2: XmlElement;
        Fresh: XmlCData;
    begin
        Build(true, 'x');
        X.Remove();
        Observer.Observe('after-remove', Format(X.GetDocument(D)));
        Fresh := MakeX('y');
        R2 := XmlElement.Create('free');
        R2.Add(Fresh);
        Observer.Observe('in-free-tree', Format(Fresh.GetDocument(D)));
        D := XmlDocument.Create();
        D.Add(R2);
        Observer.Observe('free-tree-now-in-doc', Format(Fresh.GetDocument(D)));
        Observer.Observe('doc-then', SerDocOf(D));
        Build(true, 'x');
        N := X.AsXmlNode();
        Observer.Observe('via-node', Format(N.GetDocument(D)));
        Observer.Expect('after-remove', 'No');
        Observer.Expect('in-free-tree', 'No');
        Observer.Expect('free-tree-now-in-doc', 'Yes');
        Observer.Expect('doc-then', '<?xml version="1.0" encoding="utf-16"?>\r\n<free><![CDATA[y]]></free>');
        Observer.Expect('via-node', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAddToDoc()
    begin
        Doc.Add(X);
    end;

    [Test]
    procedure DocLevel_AddToDocument_ParentAndDocument()
    var
        Observer: Codeunit "Probe Observer";
        D: XmlDocument;
        P: XmlElement;
        Ok: Boolean;
    begin
        Build(false, 'x');
        Doc := XmlDocument.Create();
        Ok := TryAddToDoc();
        Observer.Observe('add-to-doc', Format(Ok));
        Observer.ObserveError('add-to-doc-err');
        asserterror Observer.Observe('doc', SerDoc());
        Observer.ObserveError('af603');
        if Ok then begin
            Observer.Observe('get-document', Format(X.GetDocument(D)));
            Observer.Observe('get-parent', Format(X.GetParent(P)));
            Ok := TryRemove();
            Observer.Observe('remove-at-doc-level', Format(Ok));
            Observer.ObserveError('remove-at-doc-level-err');
            Observer.Observe('doc-after-remove', SerDoc());
        end;
        Observer.Expect('add-to-doc', 'No');
        Observer.Expect('add-to-doc-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('add-to-doc-err|code', 'Argument');
        Observer.Expect('af603|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('af603|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure DocLevel_Siblings_AfterRootAdded()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        i: Integer;
    begin
        for i := 1 to 5 do begin
            Build(false, 'x');
            Doc := XmlDocument.Create();
            Ok := TryAddToDoc();
            if Ok then begin
                Doc.Add(XmlElement.Create('r'));
                Ok := TryAfter(i);
                Observer.Observe('k' + Format(i), Format(Ok));
                Observer.ObserveError('k' + Format(i) + '-err');
                Observer.Observe('k' + Format(i) + '-doc', SerDoc());
            end
            else
                Observer.Observe('k' + Format(i), 'x not addable to document');
        end;
        Observer.Expect('k1', 'x not addable to document');
        Observer.Expect('k2', 'x not addable to document');
        Observer.Expect('k3', 'x not addable to document');
        Observer.Expect('k4', 'x not addable to document');
        Observer.Expect('k5', 'x not addable to document');
        Observer.Verify();
    end;

    [Test]
    procedure DocLevel_BeforeSelf_AndReplace()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        i: Integer;
    begin
        for i := 1 to 5 do begin
            Build(false, 'x');
            Doc := XmlDocument.Create();
            Ok := TryAddToDoc();
            if Ok then begin
                Doc.Add(XmlElement.Create('r'));
                Ok := TryBefore(i);
                Observer.Observe('b' + Format(i), Format(Ok));
                Observer.ObserveError('b' + Format(i) + '-err');
                Observer.Observe('b' + Format(i) + '-doc', SerDoc());
                Ok := TryReplace(i);
                Observer.Observe('r' + Format(i), Format(Ok));
                Observer.ObserveError('r' + Format(i) + '-err');
                Observer.Observe('r' + Format(i) + '-doc', SerDoc());
            end
            else
                Observer.Observe('k' + Format(i), 'x not addable to document');
        end;
        Observer.Expect('k1', 'x not addable to document');
        Observer.Expect('k2', 'x not addable to document');
        Observer.Expect('k3', 'x not addable to document');
        Observer.Expect('k4', 'x not addable to document');
        Observer.Expect('k5', 'x not addable to document');
        Observer.Verify();
    end;

    [Test]
    procedure GetParent_Attached_Positions()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        N: XmlNode;
        Pos: Integer;
    begin
        for Pos := 0 to 3 do begin
            BuildAt(true, Pos, 'x');
            Observer.Observe('p' + Format(Pos), Format(X.GetParent(P)));
            Observer.Observe('p' + Format(Pos) + '-name', P.Name());
            Observer.Observe('p' + Format(Pos) + '-via-node', Format(X.AsXmlNode().GetParent(P)));
        end;
        BuildAt(true, 2, 'x');
        X.GetParent(P);
        Observer.Observe('parent-xml', SerNode(P.AsXmlNode()));
        P.SetAttribute('viaP', '1');
        Observer.Observe('doc-after-parent-change', SerDoc());
        Observer.Expect('p0', 'Yes');
        Observer.Expect('p0-name', 'r');
        Observer.Expect('p0-via-node', 'Yes');
        Observer.Expect('p1', 'Yes');
        Observer.Expect('p1-name', 'r');
        Observer.Expect('p1-via-node', 'Yes');
        Observer.Expect('p2', 'Yes');
        Observer.Expect('p2-name', 'r');
        Observer.Expect('p2-via-node', 'Yes');
        Observer.Expect('p3', 'Yes');
        Observer.Expect('p3-name', 'r');
        Observer.Expect('p3-via-node', 'Yes');
        Observer.Expect('parent-xml', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('doc-after-parent-change', '<?xml version="1.0" encoding="utf-16"?>\r\n<r viaP="1">\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Verify();
    end;

    [Test]
    procedure GetParent_Detached_OutputUntouched()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
    begin
        Build(false, 'x');
        Observer.Observe('uninitialised-ok', Format(X.GetParent(P)));
        P := XmlElement.Create('pre');
        Observer.Observe('preset-ok', Format(X.GetParent(P)));
        Observer.Observe('preset-name', P.Name());
        Observer.Observe('via-node', Format(X.AsXmlNode().GetParent(P)));
        Observer.Expect('uninitialised-ok', 'No');
        Observer.Expect('preset-ok', 'No');
        Observer.Expect('preset-name', 'pre');
        Observer.Expect('via-node', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GetParent_AfterRemove_FreeTree()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        R2: XmlElement;
        Fresh: XmlCData;
    begin
        Build(true, 'x');
        X.Remove();
        P := XmlElement.Create('pre');
        Observer.Observe('after-remove', Format(X.GetParent(P)));
        Observer.Observe('after-remove-name', P.Name());
        Fresh := MakeX('y');
        R2 := XmlElement.Create('free');
        R2.Add(Fresh);
        Observer.Observe('in-free-tree', Format(Fresh.GetParent(P)));
        Observer.Observe('in-free-tree-name', P.Name());
        R2.Add(Fresh);
        Observer.Observe('added-twice-child-count', Format(R2.GetChildNodes().Count()));
        Observer.Expect('after-remove', 'No');
        Observer.Expect('after-remove-name', 'pre');
        Observer.Expect('in-free-tree', 'Yes');
        Observer.Expect('in-free-tree-name', 'free');
        Observer.Expect('added-twice-child-count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Relative_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '.');
        SelN(Observer, 'x2', 'self::node()');
        SelN(Observer, 'x3', '..');
        SelN(Observer, 'x4', 'following-sibling::*');
        SelN(Observer, 'x5', 'preceding-sibling::*');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '1');
        Observer.Expect('x1-first', '<![CDATA[x]]>');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-n', '1');
        Observer.Expect('x2-first', '<![CDATA[x]]>');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-n', '1');
        Observer.Expect('x3-first', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-n', '1');
        Observer.Expect('x4-first', '<b />');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-n', '1');
        Observer.Expect('x5-first', '<a />');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Relative_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', 'following-sibling::node()');
        SelN(Observer, 'x2', '../*');
        SelN(Observer, 'x3', '../node()');
        SelN(Observer, 'x4', 'parent::r');
        SelN(Observer, 'x5', 'ancestor::*');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '1');
        Observer.Expect('x1-first', '<b />');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-n', '2');
        Observer.Expect('x2-first', '<a />');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-n', '3');
        Observer.Expect('x3-first', '<a />');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-n', '1');
        Observer.Expect('x4-first', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-n', '1');
        Observer.Expect('x5-first', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Relative_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', 'self::text()');
        SelN(Observer, 'x2', 'self::comment()');
        SelN(Observer, 'x3', 'self::processing-instruction()');
        SelN(Observer, 'x4', 'text()');
        SelN(Observer, 'x5', 'child::node()');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '1');
        Observer.Expect('x1-first', '<![CDATA[x]]>');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-n', '0');
        Observer.Expect('x2-first', '');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-n', '0');
        Observer.Expect('x3-first', '');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-n', '0');
        Observer.Expect('x4-first', '');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-n', '0');
        Observer.Expect('x5-first', '');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Relative_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '@*');
        SelN(Observer, 'x2', 'following-sibling::b');
        SelN(Observer, 'x3', 'preceding-sibling::a');
        SelN(Observer, 'x4', '../a');
        SelN(Observer, 'x5', 'descendant-or-self::node()');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '0');
        Observer.Expect('x1-first', '');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-n', '1');
        Observer.Expect('x2-first', '<b />');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-n', '1');
        Observer.Expect('x3-first', '<a />');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-n', '1');
        Observer.Expect('x4-first', '<a />');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-n', '1');
        Observer.Expect('x5-first', '<![CDATA[x]]>');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Absolute_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '/r');
        SelN(Observer, 'x2', '/r/a');
        SelN(Observer, 'x3', '/r/node()');
        SelN(Observer, 'x4', '//a');
        SelN(Observer, 'x5', '//node()');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '1');
        Observer.Expect('x1-first', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-n', '1');
        Observer.Expect('x2-first', '<a />');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-n', '3');
        Observer.Expect('x3-first', '<a />');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-n', '1');
        Observer.Expect('x4-first', '<a />');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-n', '4');
        Observer.Expect('x5-first', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Absolute_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '/r/text()');
        SelN(Observer, 'x2', '/r/comment()');
        SelN(Observer, 'x3', '/r/processing-instruction()');
        SelN(Observer, 'x4', '/');
        SelN(Observer, 'x5', '/r/node()[2]');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '1');
        Observer.Expect('x1-first', '<![CDATA[x]]>');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-n', '0');
        Observer.Expect('x2-first', '');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-n', '0');
        Observer.Expect('x3-first', '');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-n', '1');
        Observer.Expect('x4-first', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-n', '1');
        Observer.Expect('x5-first', '<![CDATA[x]]>');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Absolute_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '/*');
        SelN(Observer, 'x2', '/r/*');
        SelN(Observer, 'x3', '//*[1]');
        SelN(Observer, 'x4', '/r/a/following-sibling::node()');
        SelN(Observer, 'x5', '/r/b/preceding-sibling::node()');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '1');
        Observer.Expect('x1-first', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-n', '2');
        Observer.Expect('x2-first', '<a />');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-n', '2');
        Observer.Expect('x3-first', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-n', '2');
        Observer.Expect('x4-first', '<![CDATA[x]]>');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-n', '2');
        Observer.Expect('x5-first', '<a />');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_NoMatch_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', 'nomatch');
        SelN(Observer, 'x2', '/nomatch');
        SelN(Observer, 'x3', 'self::nomatch');
        SelN(Observer, 'x4', '../zzz');
        SelN(Observer, 'x5', '//zzz');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '0');
        Observer.Expect('x1-first', '');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-n', '0');
        Observer.Expect('x2-first', '');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-n', '0');
        Observer.Expect('x3-first', '');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-n', '0');
        Observer.Expect('x4-first', '');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-n', '0');
        Observer.Expect('x5-first', '');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_NoMatch_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '/r/a/b');
        SelN(Observer, 'x2', '/r/node()[9]');
        SelN(Observer, 'x3', 'text()[2]');
        SelN(Observer, 'x4', 'following-sibling::zzz');
        SelN(Observer, 'x5', 'ancestor::zzz');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '0');
        Observer.Expect('x1-first', '');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-n', '0');
        Observer.Expect('x2-first', '');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-n', '0');
        Observer.Expect('x3-first', '');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-n', '0');
        Observer.Expect('x4-first', '');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-n', '0');
        Observer.Expect('x5-first', '');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_InvalidXPath_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '');
        SelN(Observer, 'x2', ' ');
        SelN(Observer, 'x3', '[');
        SelN(Observer, 'x4', 'count(.)');
        SelN(Observer, 'x5', '$v');
        Observer.Expect('x1', 'No');
        Observer.Expect('x1-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x1-err|code', 'Xml:XPath');
        Observer.Expect('x2', 'No');
        Observer.Expect('x2-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x2-err|code', 'Xml:XPath');
        Observer.Expect('x3', 'No');
        Observer.Expect('x3-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x3-err|code', 'Xml:XPath');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-n', '0');
        Observer.Expect('x4-first', '');
        Observer.Expect('x5', 'No');
        Observer.Expect('x5-err|text', 'Namespace Manager or XsltContext needed. This query has a prefix, variable, or user-defined function.');
        Observer.Expect('x5-err|code', 'Xml:XPath');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_InvalidXPath_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', '1 + 1');
        SelN(Observer, 'x2', '"str"');
        SelN(Observer, 'x3', 'a b');
        SelN(Observer, 'x4', '/r/a[');
        SelN(Observer, 'x5', 'name()');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '0');
        Observer.Expect('x1-first', '');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-n', '0');
        Observer.Expect('x2-first', '');
        Observer.Expect('x3', 'No');
        Observer.Expect('x3-err|text', '''a b'' has an invalid token.');
        Observer.Expect('x3-err|code', 'Xml:XPath');
        Observer.Expect('x4', 'No');
        Observer.Expect('x4-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x4-err|code', 'Xml:XPath');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-n', '0');
        Observer.Expect('x5-first', '');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_InvalidXPath_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelN(Observer, 'x1', 'true()');
        SelN(Observer, 'x2', '//');
        SelN(Observer, 'x3', '@@');
        SelN(Observer, 'x4', 'x:y');
        SelN(Observer, 'x5', 'self::');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '0');
        Observer.Expect('x1-first', '');
        Observer.Expect('x2', 'No');
        Observer.Expect('x2-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x2-err|code', 'Xml:XPath');
        Observer.Expect('x3', 'No');
        Observer.Expect('x3-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x3-err|code', 'Xml:XPath');
        Observer.Expect('x4', 'No');
        Observer.Expect('x4-err|text', 'Namespace Manager or XsltContext needed. This query has a prefix, variable, or user-defined function.');
        Observer.Expect('x4-err|code', 'Xml:XPath');
        Observer.Expect('x5', 'No');
        Observer.Expect('x5-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x5-err|code', 'Xml:XPath');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Detached_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(false, 'x');
        SelN(Observer, 'x1', '.');
        SelN(Observer, 'x2', '..');
        SelN(Observer, 'x3', 'self::node()');
        SelN(Observer, 'x4', '/');
        SelN(Observer, 'x5', '/r');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '1');
        Observer.Expect('x1-first', '<![CDATA[x]]>');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-n', '0');
        Observer.Expect('x2-first', '');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-n', '1');
        Observer.Expect('x3-first', '<![CDATA[x]]>');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-n', '1');
        Observer.Expect('x4-first', '<![CDATA[x]]>');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-n', '0');
        Observer.Expect('x5-first', '');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_Detached_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(false, 'x');
        SelN(Observer, 'x1', 'following-sibling::*');
        SelN(Observer, 'x2', 'ancestor::node()');
        SelN(Observer, 'x3', 'parent::node()');
        SelN(Observer, 'x4', 'preceding-sibling::node()');
        SelN(Observer, 'x5', '//*');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-n', '0');
        Observer.Expect('x1-first', '');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-n', '0');
        Observer.Expect('x2-first', '');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-n', '0');
        Observer.Expect('x3-first', '');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-n', '0');
        Observer.Expect('x4-first', '');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-n', '0');
        Observer.Expect('x5-first', '');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_Relative_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '.');
        SelS(Observer, 'x2', 'self::node()');
        SelS(Observer, 'x3', '..');
        SelS(Observer, 'x4', 'following-sibling::*');
        SelS(Observer, 'x5', 'preceding-sibling::*');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-node', '<![CDATA[x]]>');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-node', '<![CDATA[x]]>');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-node', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-node', '<b />');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-node', '<a />');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_Relative_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', 'following-sibling::node()');
        SelS(Observer, 'x2', '../*');
        SelS(Observer, 'x3', '../node()');
        SelS(Observer, 'x4', 'parent::r');
        SelS(Observer, 'x5', 'ancestor::*');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-node', '<b />');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-node', '<a />');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-node', '<a />');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-node', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-node', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_Relative_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', 'self::text()');
        SelS(Observer, 'x2', 'self::comment()');
        SelS(Observer, 'x3', 'self::processing-instruction()');
        SelS(Observer, 'x4', 'text()');
        SelS(Observer, 'x5', 'child::node()');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-node', '<![CDATA[x]]>');
        Observer.Expect('x2', 'No');
        Observer.Expect('x2-err|text', 'The XPath query ''self::comment()'' does not match any nodes.');
        Observer.Expect('x2-err|code', 'InvalidXPathSelection');
        Observer.Expect('x3', 'No');
        Observer.Expect('x3-err|text', 'The XPath query ''self::processing-instruction()'' does not match any nodes.');
        Observer.Expect('x3-err|code', 'InvalidXPathSelection');
        Observer.Expect('x4', 'No');
        Observer.Expect('x4-err|text', 'The XPath query ''text()'' does not match any nodes.');
        Observer.Expect('x4-err|code', 'InvalidXPathSelection');
        Observer.Expect('x5', 'No');
        Observer.Expect('x5-err|text', 'The XPath query ''child::node()'' does not match any nodes.');
        Observer.Expect('x5-err|code', 'InvalidXPathSelection');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_Relative_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '@*');
        SelS(Observer, 'x2', 'following-sibling::b');
        SelS(Observer, 'x3', 'preceding-sibling::a');
        SelS(Observer, 'x4', '../a');
        SelS(Observer, 'x5', 'descendant-or-self::node()');
        Observer.Expect('x1', 'No');
        Observer.Expect('x1-err|text', 'The XPath query ''@*'' does not match any nodes.');
        Observer.Expect('x1-err|code', 'InvalidXPathSelection');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-node', '<b />');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-node', '<a />');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-node', '<a />');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-node', '<![CDATA[x]]>');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_Absolute_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '/r');
        SelS(Observer, 'x2', '/r/a');
        SelS(Observer, 'x3', '/r/node()');
        SelS(Observer, 'x4', '//a');
        SelS(Observer, 'x5', '//node()');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-node', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-node', '<a />');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-node', '<a />');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-node', '<a />');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-node', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_Absolute_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '/r/text()');
        SelS(Observer, 'x2', '/r/comment()');
        SelS(Observer, 'x3', '/r/processing-instruction()');
        SelS(Observer, 'x4', '/');
        SelS(Observer, 'x5', '/r/node()[2]');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-node', '<![CDATA[x]]>');
        Observer.Expect('x2', 'No');
        Observer.Expect('x2-err|text', 'The XPath query ''/r/comment()'' does not match any nodes.');
        Observer.Expect('x2-err|code', 'InvalidXPathSelection');
        Observer.Expect('x3', 'No');
        Observer.Expect('x3-err|text', 'The XPath query ''/r/processing-instruction()'' does not match any nodes.');
        Observer.Expect('x3-err|code', 'InvalidXPathSelection');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-node', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-node', '<![CDATA[x]]>');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_Absolute_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '/*');
        SelS(Observer, 'x2', '/r/*');
        SelS(Observer, 'x3', '//*[1]');
        SelS(Observer, 'x4', '/r/a/following-sibling::node()');
        SelS(Observer, 'x5', '/r/b/preceding-sibling::node()');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-node', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('x2', 'Yes');
        Observer.Expect('x2-err|text', '');
        Observer.Expect('x2-err|code', '');
        Observer.Expect('x2-node', '<a />');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-node', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-node', '<![CDATA[x]]>');
        Observer.Expect('x5', 'Yes');
        Observer.Expect('x5-err|text', '');
        Observer.Expect('x5-err|code', '');
        Observer.Expect('x5-node', '<a />');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_NoMatch_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', 'nomatch');
        SelS(Observer, 'x2', '/nomatch');
        SelS(Observer, 'x3', 'self::nomatch');
        SelS(Observer, 'x4', '../zzz');
        SelS(Observer, 'x5', '//zzz');
        Observer.Expect('x1', 'No');
        Observer.Expect('x1-err|text', 'The XPath query ''nomatch'' does not match any nodes.');
        Observer.Expect('x1-err|code', 'InvalidXPathSelection');
        Observer.Expect('x2', 'No');
        Observer.Expect('x2-err|text', 'The XPath query ''/nomatch'' does not match any nodes.');
        Observer.Expect('x2-err|code', 'InvalidXPathSelection');
        Observer.Expect('x3', 'No');
        Observer.Expect('x3-err|text', 'The XPath query ''self::nomatch'' does not match any nodes.');
        Observer.Expect('x3-err|code', 'InvalidXPathSelection');
        Observer.Expect('x4', 'No');
        Observer.Expect('x4-err|text', 'The XPath query ''../zzz'' does not match any nodes.');
        Observer.Expect('x4-err|code', 'InvalidXPathSelection');
        Observer.Expect('x5', 'No');
        Observer.Expect('x5-err|text', 'The XPath query ''//zzz'' does not match any nodes.');
        Observer.Expect('x5-err|code', 'InvalidXPathSelection');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_NoMatch_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '/r/a/b');
        SelS(Observer, 'x2', '/r/node()[9]');
        SelS(Observer, 'x3', 'text()[2]');
        SelS(Observer, 'x4', 'following-sibling::zzz');
        SelS(Observer, 'x5', 'ancestor::zzz');
        Observer.Expect('x1', 'No');
        Observer.Expect('x1-err|text', 'The XPath query ''/r/a/b'' does not match any nodes.');
        Observer.Expect('x1-err|code', 'InvalidXPathSelection');
        Observer.Expect('x2', 'No');
        Observer.Expect('x2-err|text', 'The XPath query ''/r/node()[9]'' does not match any nodes.');
        Observer.Expect('x2-err|code', 'InvalidXPathSelection');
        Observer.Expect('x3', 'No');
        Observer.Expect('x3-err|text', 'The XPath query ''text()[2]'' does not match any nodes.');
        Observer.Expect('x3-err|code', 'InvalidXPathSelection');
        Observer.Expect('x4', 'No');
        Observer.Expect('x4-err|text', 'The XPath query ''following-sibling::zzz'' does not match any nodes.');
        Observer.Expect('x4-err|code', 'InvalidXPathSelection');
        Observer.Expect('x5', 'No');
        Observer.Expect('x5-err|text', 'The XPath query ''ancestor::zzz'' does not match any nodes.');
        Observer.Expect('x5-err|code', 'InvalidXPathSelection');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_InvalidXPath_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '');
        SelS(Observer, 'x2', ' ');
        SelS(Observer, 'x3', '[');
        SelS(Observer, 'x4', 'count(.)');
        SelS(Observer, 'x5', '$v');
        Observer.Expect('x1', 'No');
        Observer.Expect('x1-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x1-err|code', 'Xml:XPath');
        Observer.Expect('x2', 'No');
        Observer.Expect('x2-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x2-err|code', 'Xml:XPath');
        Observer.Expect('x3', 'No');
        Observer.Expect('x3-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x3-err|code', 'Xml:XPath');
        Observer.Expect('x4', 'No');
        Observer.Expect('x4-err|text', 'The XPath query ''count(.)'' does not match any nodes.');
        Observer.Expect('x4-err|code', 'InvalidXPathSelection');
        Observer.Expect('x5', 'No');
        Observer.Expect('x5-err|text', 'Namespace Manager or XsltContext needed. This query has a prefix, variable, or user-defined function.');
        Observer.Expect('x5-err|code', 'Xml:XPath');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_InvalidXPath_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', '1 + 1');
        SelS(Observer, 'x2', '"str"');
        SelS(Observer, 'x3', 'a b');
        SelS(Observer, 'x4', '/r/a[');
        SelS(Observer, 'x5', 'name()');
        Observer.Expect('x1', 'No');
        Observer.Expect('x1-err|text', 'The XPath query ''1 + 1'' does not match any nodes.');
        Observer.Expect('x1-err|code', 'InvalidXPathSelection');
        Observer.Expect('x2', 'No');
        Observer.Expect('x2-err|text', 'The XPath query ''"str"'' does not match any nodes.');
        Observer.Expect('x2-err|code', 'InvalidXPathSelection');
        Observer.Expect('x3', 'No');
        Observer.Expect('x3-err|text', '''a b'' has an invalid token.');
        Observer.Expect('x3-err|code', 'Xml:XPath');
        Observer.Expect('x4', 'No');
        Observer.Expect('x4-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x4-err|code', 'Xml:XPath');
        Observer.Expect('x5', 'No');
        Observer.Expect('x5-err|text', 'The XPath query ''name()'' does not match any nodes.');
        Observer.Expect('x5-err|code', 'InvalidXPathSelection');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_InvalidXPath_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(true, 'x');
        SelS(Observer, 'x1', 'true()');
        SelS(Observer, 'x2', '//');
        SelS(Observer, 'x3', '@@');
        SelS(Observer, 'x4', 'x:y');
        SelS(Observer, 'x5', 'self::');
        Observer.Expect('x1', 'No');
        Observer.Expect('x1-err|text', 'The XPath query ''true()'' does not match any nodes.');
        Observer.Expect('x1-err|code', 'InvalidXPathSelection');
        Observer.Expect('x2', 'No');
        Observer.Expect('x2-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x2-err|code', 'Xml:XPath');
        Observer.Expect('x3', 'No');
        Observer.Expect('x3-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x3-err|code', 'Xml:XPath');
        Observer.Expect('x4', 'No');
        Observer.Expect('x4-err|text', 'Namespace Manager or XsltContext needed. This query has a prefix, variable, or user-defined function.');
        Observer.Expect('x4-err|code', 'Xml:XPath');
        Observer.Expect('x5', 'No');
        Observer.Expect('x5-err|text', 'Expression must evaluate to a node-set.');
        Observer.Expect('x5-err|code', 'Xml:XPath');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_Detached_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(false, 'x');
        SelS(Observer, 'x1', '.');
        SelS(Observer, 'x2', '..');
        SelS(Observer, 'x3', 'self::node()');
        SelS(Observer, 'x4', '/');
        SelS(Observer, 'x5', '/r');
        Observer.Expect('x1', 'Yes');
        Observer.Expect('x1-err|text', '');
        Observer.Expect('x1-err|code', '');
        Observer.Expect('x1-node', '<![CDATA[x]]>');
        Observer.Expect('x2', 'No');
        Observer.Expect('x2-err|text', 'The XPath query ''..'' does not match any nodes.');
        Observer.Expect('x2-err|code', 'InvalidXPathSelection');
        Observer.Expect('x3', 'Yes');
        Observer.Expect('x3-err|text', '');
        Observer.Expect('x3-err|code', '');
        Observer.Expect('x3-node', '<![CDATA[x]]>');
        Observer.Expect('x4', 'Yes');
        Observer.Expect('x4-err|text', '');
        Observer.Expect('x4-err|code', '');
        Observer.Expect('x4-node', '<![CDATA[x]]>');
        Observer.Expect('x5', 'No');
        Observer.Expect('x5-err|text', 'The XPath query ''/r'' does not match any nodes.');
        Observer.Expect('x5-err|code', 'InvalidXPathSelection');
        Observer.Verify();
    end;

    [Test]
    procedure SelectSingle_Detached_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Build(false, 'x');
        SelS(Observer, 'x1', 'following-sibling::*');
        SelS(Observer, 'x2', 'ancestor::node()');
        SelS(Observer, 'x3', 'parent::node()');
        SelS(Observer, 'x4', 'preceding-sibling::node()');
        SelS(Observer, 'x5', '//*');
        Observer.Expect('x1', 'No');
        Observer.Expect('x1-err|text', 'The XPath query ''following-sibling::*'' does not match any nodes.');
        Observer.Expect('x1-err|code', 'InvalidXPathSelection');
        Observer.Expect('x2', 'No');
        Observer.Expect('x2-err|text', 'The XPath query ''ancestor::node()'' does not match any nodes.');
        Observer.Expect('x2-err|code', 'InvalidXPathSelection');
        Observer.Expect('x3', 'No');
        Observer.Expect('x3-err|text', 'The XPath query ''parent::node()'' does not match any nodes.');
        Observer.Expect('x3-err|code', 'InvalidXPathSelection');
        Observer.Expect('x4', 'No');
        Observer.Expect('x4-err|text', 'The XPath query ''preceding-sibling::node()'' does not match any nodes.');
        Observer.Expect('x4-err|code', 'InvalidXPathSelection');
        Observer.Expect('x5', 'No');
        Observer.Expect('x5-err|text', 'The XPath query ''//*'' does not match any nodes.');
        Observer.Expect('x5-err|code', 'InvalidXPathSelection');
        Observer.Verify();
    end;

    [Test]
    procedure SelectNodes_ListAfterNoMatch_AndViaNode()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
        Ok: Boolean;
        Found: XmlNode;
    begin
        Build(true, 'x');
        Ok := TrySelNodes('../*');
        Observer.Observe('first', Format(Ok));
        Observer.Observe('first-count', Format(Lst.Count()));
        Ok := TrySelNodes('nomatch');
        Observer.Observe('second-nomatch', Format(Ok));
        Observer.Observe('count-after-nomatch', Format(Lst.Count()));
        N := X.AsXmlNode();
        Observer.Observe('via-node-nodes', Format(N.SelectNodes('../*', Lst)));
        Observer.Observe('via-node-count', Format(Lst.Count()));
        Observer.Observe('via-node-single', Format(N.SelectSingleNode('..', Found)));
        Observer.Observe('via-node-single-text', SerNode(Found));
        Observer.Observe('via-node-single-nomatch', Format(N.SelectSingleNode('nomatch', Found)));
        Observer.Observe('found-after-nomatch', SerNode(Found));
        Observer.Expect('first', 'Yes');
        Observer.Expect('first-count', '2');
        Observer.Expect('second-nomatch', 'Yes');
        Observer.Expect('count-after-nomatch', '0');
        Observer.Expect('via-node-nodes', 'Yes');
        Observer.Expect('via-node-count', '2');
        Observer.Expect('via-node-single', 'Yes');
        Observer.Expect('via-node-single-text', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('via-node-single-nomatch', 'No');
        Observer.Expect('found-after-nomatch', '<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_Contents_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeContent(Observer, 'empty', '');
        ProbeContent(Observer, 'space', ' ');
        ProbeContent(Observer, 'plain', 'a b');
        ProbeContent(Observer, 'markup', '<&>');
        ProbeContent(Observer, 'cdata-end', ']]>');
        ProbeContent(Observer, 'double-dash', '--');
        Observer.Expect('empty', 'Yes');
        Observer.Expect('empty-err|text', '');
        Observer.Expect('empty-err|code', '');
        Observer.Expect('empty-x', '<![CDATA[]]>');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-err|text', '');
        Observer.Expect('space-err|code', '');
        Observer.Expect('space-x', '<![CDATA[ ]]>');
        Observer.Expect('plain', 'Yes');
        Observer.Expect('plain-err|text', '');
        Observer.Expect('plain-err|code', '');
        Observer.Expect('plain-x', '<![CDATA[a b]]>');
        Observer.Expect('markup', 'Yes');
        Observer.Expect('markup-err|text', '');
        Observer.Expect('markup-err|code', '');
        Observer.Expect('markup-x', '<![CDATA[<&>]]>');
        Observer.Expect('cdata-end', 'Yes');
        Observer.Expect('cdata-end-err|text', '');
        Observer.Expect('cdata-end-err|code', '');
        Observer.Expect('cdata-end-x', '<![CDATA[]]]]><![CDATA[>]]>');
        Observer.Expect('double-dash', 'Yes');
        Observer.Expect('double-dash-err|text', '');
        Observer.Expect('double-dash-err|code', '');
        Observer.Expect('double-dash-x', '<![CDATA[--]]>');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_Contents_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ProbeContent(Observer, 'trailing-dash', 'a-');
        ProbeContent(Observer, 'leading-dash', '-a');
        ProbeContent(Observer, 'pi-end', '?>');
        ProbeContent(Observer, 'newline', 'x' + Lf() + 'y');
        ProbeContent(Observer, 'unicode', 'aü€');
        ProbeContent(Observer, 'padded', '  p  ');
        Observer.Expect('trailing-dash', 'Yes');
        Observer.Expect('trailing-dash-err|text', '');
        Observer.Expect('trailing-dash-err|code', '');
        Observer.Expect('trailing-dash-x', '<![CDATA[a-]]>');
        Observer.Expect('leading-dash', 'Yes');
        Observer.Expect('leading-dash-err|text', '');
        Observer.Expect('leading-dash-err|code', '');
        Observer.Expect('leading-dash-x', '<![CDATA[-a]]>');
        Observer.Expect('pi-end', 'Yes');
        Observer.Expect('pi-end-err|text', '');
        Observer.Expect('pi-end-err|code', '');
        Observer.Expect('pi-end-x', '<![CDATA[?>]]>');
        Observer.Expect('newline', 'Yes');
        Observer.Expect('newline-err|text', '');
        Observer.Expect('newline-err|code', '');
        Observer.Expect('newline-x', '<![CDATA[x\r\ny]]>');
        Observer.Expect('unicode', 'Yes');
        Observer.Expect('unicode-err|text', '');
        Observer.Expect('unicode-err|code', '');
        Observer.Expect('unicode-x', '<![CDATA[aü€]]>');
        Observer.Expect('padded', 'Yes');
        Observer.Expect('padded-err|text', '');
        Observer.Expect('padded-err|code', '');
        Observer.Expect('padded-x', '<![CDATA[  p  ]]>');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_Text_AttachedAndDetached_NoLeakage()
    var
        Observer: Codeunit "Probe Observer";
        S: Text;
        N: XmlNode;
    begin
        Build(true, 'x');
        S := 'preset';
        X.WriteTo(S);
        Observer.Observe('attached', S);
        N := X.AsXmlNode();
        N.WriteTo(S);
        Observer.Observe('attached-via-node', S);
        Observer.Observe('doc', SerDoc());
        Build(false, 'x');
        S := 'preset';
        X.WriteTo(S);
        Observer.Observe('detached', S);
        Observer.Observe('length', Format(StrLen(S)));
        Observer.Expect('attached', '<![CDATA[x]]>');
        Observer.Expect('attached-via-node', '<![CDATA[x]]>');
        Observer.Expect('doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('detached', '<![CDATA[x]]>');
        Observer.Expect('length', '13');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_Document_AfterEachChange()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Observer.Observe('initial', SerDoc());
        Ok := TrySetV('changed');
        Observer.Observe('after-set-value', SerDoc());
        Ok := TryAfter(1);
        Observer.Observe('after-add-after', SerDoc());
        Ok := TryBefore(3);
        Observer.Observe('after-add-before', SerDoc());
        Ok := TryReplace(2);
        Observer.Observe('after-replace', SerDoc());
        Build(true, 'x');
        Ok := TryRemove();
        Observer.Observe('after-remove', SerDoc());
        Observer.Expect('initial', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[x]]><b /></r>');
        Observer.Expect('after-set-value', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[changed]]><b /></r>');
        Observer.Expect('after-add-after', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[changed]]><e1 /><b /></r>');
        Observer.Expect('after-add-before', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--c3--><![CDATA[changed]]><e1 /><b /></r>');
        Observer.Expect('after-replace', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--c3-->t2<e1 /><b /></r>');
        Observer.Expect('after-remove', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_Special_1()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Observer.Observe('initial', GetV(X));
        Ok := TrySetV('');
        Observer.Observe('empty', Format(Ok));
        Observer.ObserveError('empty-err');
        Observer.Observe('empty-doc', SerDoc());
        Ok := TrySetV('<&>');
        Observer.Observe('markup', Format(Ok));
        Observer.ObserveError('markup-err');
        Observer.Observe('markup-doc', SerDoc());
        Observer.Observe('markup-get', GetV(X));
        Ok := TrySetV(']]>');
        Observer.Observe('cdata-end', Format(Ok));
        Observer.ObserveError('cdata-end-err');
        Observer.Observe('cdata-end-doc', SerDoc());
        Observer.Expect('initial', 'x');
        Observer.Expect('empty', 'Yes');
        Observer.Expect('empty-err|text', '');
        Observer.Expect('empty-err|code', '');
        Observer.Expect('empty-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[]]><b /></r>');
        Observer.Expect('markup', 'Yes');
        Observer.Expect('markup-err|text', '');
        Observer.Expect('markup-err|code', '');
        Observer.Expect('markup-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[<&>]]><b /></r>');
        Observer.Expect('markup-get', '<&>');
        Observer.Expect('cdata-end', 'Yes');
        Observer.Expect('cdata-end-err|text', '');
        Observer.Expect('cdata-end-err|code', '');
        Observer.Expect('cdata-end-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[]]]]><![CDATA[>]]><b /></r>');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_Special_2()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TrySetV('--');
        Observer.Observe('double-dash', Format(Ok));
        Observer.ObserveError('double-dash-err');
        Observer.Observe('double-dash-doc', SerDoc());
        Ok := TrySetV('?>');
        Observer.Observe('pi-end', Format(Ok));
        Observer.ObserveError('pi-end-err');
        Observer.Observe('pi-end-doc', SerDoc());
        Ok := TrySetV('x' + Lf() + 'y');
        Observer.Observe('newline', Format(Ok));
        Observer.ObserveError('newline-err');
        Observer.Observe('newline-doc', SerDoc());
        Observer.Observe('newline-get', GetV(X));
        Observer.Expect('double-dash', 'Yes');
        Observer.Expect('double-dash-err|text', '');
        Observer.Expect('double-dash-err|code', '');
        Observer.Expect('double-dash-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[--]]><b /></r>');
        Observer.Expect('pi-end', 'Yes');
        Observer.Expect('pi-end-err|text', '');
        Observer.Expect('pi-end-err|code', '');
        Observer.Expect('pi-end-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[?>]]><b /></r>');
        Observer.Expect('newline', 'Yes');
        Observer.Expect('newline-err|text', '');
        Observer.Expect('newline-err|code', '');
        Observer.Expect('newline-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[x\r\ny]]><b /></r>');
        Observer.Expect('newline-get', 'x\ny');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_Detached()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(false, 'x');
        Ok := TrySetV('new');
        Observer.Observe('set', Format(Ok));
        Observer.ObserveError('set-err');
        Observer.Observe('x', SerX());
        Observer.Observe('get', GetV(X));
        Observer.Expect('set', 'Yes');
        Observer.Expect('set-err|text', '');
        Observer.Expect('set-err|code', '');
        Observer.Expect('x', '<![CDATA[new]]>');
        Observer.Expect('get', 'new');
        Observer.Verify();
    end;

    local procedure Prepare(var Blob: Record "LT P90 Blob")
    begin
        Blob.DeleteAll();
        Blob.Init();
        Blob.Id := 1;
        Blob.Data.CreateOutStream(OutS);
    end;

    [Test]
    procedure WriteTo_OutStream_Attached_AndText()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P90 Blob";
        S: Text;
    begin
        Build(true, 'x');
        Prepare(Blob);
        X.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        X.WriteTo(S);
        Observer.Observe('blob', ReadBlob(Blob));
        Observer.Observe('blob-length', Format(Blob.Data.Length()));
        Observer.Observe('text', S);
        Observer.Observe('text-length', Format(StrLen(S)));
        Observer.Expect('blob', 'Ù‹<![CDATA[x]]>|');
        Observer.Expect('blob-length', '16');
        Observer.Expect('text', '<![CDATA[x]]>');
        Observer.Expect('text-length', '13');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_Detached()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P90 Blob";
    begin
        Build(false, 'x');
        Prepare(Blob);
        X.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        Observer.Observe('blob', ReadBlob(Blob));
        Observer.Observe('blob-length', Format(Blob.Data.Length()));
        Observer.Expect('blob', 'Ù‹<![CDATA[x]]>|');
        Observer.Expect('blob-length', '16');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_ViaXmlNode_AndDocument()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P90 Blob";
        N: XmlNode;
    begin
        Build(true, 'x');
        N := X.AsXmlNode();
        Prepare(Blob);
        N.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        Observer.Observe('node-blob', ReadBlob(Blob));
        Observer.Observe('node-blob-length', Format(Blob.Data.Length()));
        TryAfter(1);
        Prepare(Blob);
        Doc.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        Observer.Observe('doc-blob', ReadBlob(Blob));
        Observer.Observe('doc-blob-length', Format(Blob.Data.Length()));
        Observer.Expect('node-blob', 'Ù‹<![CDATA[x]]>|');
        Observer.Expect('node-blob-length', '16');
        Observer.Expect('doc-blob', 'Ù‹<?xml version="1.0" encoding="utf-8"?>|<r>|  <a /><![CDATA[x]]><e1 /><b /></r>|');
        Observer.Expect('doc-blob-length', '83');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_TwiceIntoSameStream()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P90 Blob";
    begin
        Build(true, 'x');
        Prepare(Blob);
        X.WriteTo(OutS);
        X.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        Observer.Observe('blob', ReadBlob(Blob));
        Observer.Observe('blob-length', Format(Blob.Data.Length()));
        Observer.Expect('blob', 'Ù‹<![CDATA[x]]>|');
        Observer.Expect('blob-length', '16');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_AfterReplaceAndRemove()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P90 Blob";
    begin
        Build(true, 'x');
        TryReplace(1);
        Prepare(Blob);
        X.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        Observer.Observe('replaced-x-blob', ReadBlob(Blob));
        Prepare(Blob);
        Doc.WriteTo(OutS);
        Blob.Insert();
        Blob.Get(1);
        Observer.Observe('replaced-doc-blob', ReadBlob(Blob));
        Observer.Expect('replaced-x-blob', 'Ù‹<![CDATA[x]]>|');
        Observer.Expect('replaced-doc-blob', 'Ù‹<?xml version="1.0" encoding="utf-8"?>|<r>|  <a />|  <e1 />|  <b />|</r>|');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryWriteUninitStream()
    var
        S2: OutStream;
    begin
        X.WriteTo(S2);
    end;

    [Test]
    procedure WriteTo_OutStream_UninitialisedStream()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TryWriteUninitStream();
        Observer.Observe('uninitialised-stream', Format(Ok));
        Observer.ObserveError('uninitialised-stream-err');
        Observer.Expect('uninitialised-stream', 'No');
        Observer.Expect('uninitialised-stream-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('uninitialised-stream-err|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure UninitialisedVariable_1()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        Ok: Boolean;
    begin
        for i := 1 to 5 do begin
            Ok := TryUninit(i);
            Observer.Observe('op' + Format(i), Format(Ok));
            Observer.ObserveError('op' + Format(i) + '-err');
            Observer.Observe('op' + Format(i) + '-res', Res);
        end;
        Observer.Expect('op1', 'No');
        Observer.Expect('op1-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('op1-err|code', 'NotInitialized');
        Observer.Expect('op1-res', '');
        Observer.Expect('op2', 'No');
        Observer.Expect('op2-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('op2-err|code', 'NotInitialized');
        Observer.Expect('op2-res', '');
        Observer.Expect('op3', 'No');
        Observer.Expect('op3-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('op3-err|code', 'NotInitialized');
        Observer.Expect('op3-res', '');
        Observer.Expect('op4', 'No');
        Observer.Expect('op4-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('op4-err|code', 'NotInitialized');
        Observer.Expect('op4-res', '');
        Observer.Expect('op5', 'No');
        Observer.Expect('op5-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('op5-err|code', 'NotInitialized');
        Observer.Expect('op5-res', '');
        Observer.Verify();
    end;

    [Test]
    procedure UninitialisedVariable_2()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        Ok: Boolean;
    begin
        for i := 6 to 10 do begin
            Ok := TryUninit(i);
            Observer.Observe('op' + Format(i), Format(Ok));
            Observer.ObserveError('op' + Format(i) + '-err');
            Observer.Observe('op' + Format(i) + '-res', Res);
        end;
        Observer.Expect('op6', 'No');
        Observer.Expect('op6-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('op6-err|code', 'NotInitialized');
        Observer.Expect('op6-res', '');
        Observer.Expect('op7', 'No');
        Observer.Expect('op7-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('op7-err|code', 'NotInitialized');
        Observer.Expect('op7-res', '');
        Observer.Expect('op8', 'No');
        Observer.Expect('op8-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('op8-err|code', 'NotInitialized');
        Observer.Expect('op8-res', '');
        Observer.Expect('op9', 'No');
        Observer.Expect('op9-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('op9-err|code', 'NotInitialized');
        Observer.Expect('op9-res', '');
        Observer.Expect('op10', 'No');
        Observer.Expect('op10-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('op10-err|code', 'NotInitialized');
        Observer.Expect('op10-res', '');
        Observer.Verify();
    end;

    [Test]
    procedure UninitialisedVariable_3()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        Ok: Boolean;
    begin
        for i := 11 to 13 do begin
            Ok := TryUninit(i);
            Observer.Observe('op' + Format(i), Format(Ok));
            Observer.ObserveError('op' + Format(i) + '-err');
            Observer.Observe('op' + Format(i) + '-res', Res);
        end;
        Observer.Expect('op11', 'No');
        Observer.Expect('op11-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('op11-err|code', 'NotInitialized');
        Observer.Expect('op11-res', '');
        Observer.Expect('op12', 'No');
        Observer.Expect('op12-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlCData variable not initialized.');
        Observer.Expect('op12-err|code', 'NotInitialized');
        Observer.Expect('op12-res', '');
        Observer.Expect('op13', 'No');
        Observer.Expect('op13-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlCData variable not initialized.');
        Observer.Expect('op13-err|code', 'NotInitialized');
        Observer.Expect('op13-res', '');
        Observer.Verify();
    end;

}
