// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/XmlProcessingInstruction/xmlprocessinginstruction-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against BC 29 (local service tier); the observed values become the assertions. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlProcessingInstruction AddAfterSelf, AddBeforeSelf, ReplaceWith, Remove with every node kind, attached and detached, and the serialized document after each change
// BC versions: 29 (27 and 28 by CI)

codeunit 70734 "LT P90 PI Edit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Doc: XmlDocument;
        Root: XmlElement;
        X: XmlProcessingInstruction;
        U: XmlProcessingInstruction;
        UN: XmlNode;
        Res: Text;
        Lst: XmlNodeList;
        OutS: OutStream;

    local procedure MakeX(Tag: Text): XmlProcessingInstruction
    var
        R: XmlProcessingInstruction;
    begin
        R := XmlProcessingInstruction.Create('t', Tag);
        exit(R);
    end;

    // Pos: 0 = only child of r, 1 = first, 2 = middle (default), 3 = last child of r (siblings a and b)
    local procedure BuildAt(Attached: Boolean; Pos: Integer; Tag: Text)
    var
        N: XmlNode;
        Fresh: XmlProcessingInstruction;
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
        X := N.AsXmlProcessingInstruction();
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

    [Test]
    procedure AfterSelf_Attached_ValidKinds()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 1 to 5 do begin
            Build(true, 'x');
            Ok := TryAfter(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-doc', SerDoc());
        end;
        Observer.Expect('k1', 'Yes');
        Observer.Expect('k1-err|text', '');
        Observer.Expect('k1-err|code', '');
        Observer.Expect('k1-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <e1 />\r\n  <b />\r\n</r>');
        Observer.Expect('k2', 'Yes');
        Observer.Expect('k2-err|text', '');
        Observer.Expect('k2-err|code', '');
        Observer.Expect('k2-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>t2<b /></r>');
        Observer.Expect('k3', 'Yes');
        Observer.Expect('k3-err|text', '');
        Observer.Expect('k3-err|code', '');
        Observer.Expect('k3-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <!--c3-->\r\n  <b />\r\n</r>');
        Observer.Expect('k4', 'Yes');
        Observer.Expect('k4-err|text', '');
        Observer.Expect('k4-err|code', '');
        Observer.Expect('k4-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?><![CDATA[d4]]><b /></r>');
        Observer.Expect('k5', 'Yes');
        Observer.Expect('k5-err|text', '');
        Observer.Expect('k5-err|code', '');
        Observer.Expect('k5-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <?p5 q5?>\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure AfterSelf_Attached_InvalidKinds()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 6 to 9 do begin
            Build(true, 'x');
            Ok := TryAfter(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-doc', SerDoc());
        end;
        Observer.Expect('k6', 'No');
        Observer.Expect('k6-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k6-err|code', 'Argument');
        Observer.Expect('k6-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('k7', 'Yes');
        Observer.Expect('k7-err|text', '');
        Observer.Expect('k7-err|code', '');
        Observer.Expect('k7-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>&lt;?xml version="1.0" encoding="utf-8" standalone="yes"?&gt;<b /></r>');
        Observer.Expect('k8', 'No');
        Observer.Expect('k8-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k8-err|code', 'Argument');
        Observer.Expect('k8-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('k9', 'No');
        Observer.Expect('k9-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k9-err|code', 'Argument');
        Observer.Expect('k9-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure AfterSelf_Attached_ExistingNodes()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 10 to 13 do begin
            Build(true, 'x');
            Ok := TryAfter(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-doc', SerDoc());
        end;
        Observer.Expect('k10', 'Yes');
        Observer.Expect('k10-err|text', '');
        Observer.Expect('k10-err|code', '');
        Observer.Expect('k10-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('k11', 'Yes');
        Observer.Expect('k11-err|text', '');
        Observer.Expect('k11-err|code', '');
        Observer.Expect('k11-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('k12', 'Yes');
        Observer.Expect('k12-err|text', '');
        Observer.Expect('k12-err|code', '');
        Observer.Expect('k12-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <r>\r\n    <a />\r\n    <?t x?>\r\n    <b />\r\n  </r>\r\n  <b />\r\n</r>');
        Observer.Expect('k13', 'Yes');
        Observer.Expect('k13-err|text', '');
        Observer.Expect('k13-err|code', '');
        Observer.Expect('k13-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <f13 />\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure AfterSelf_Detached_ValidKinds()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 1 to 5 do begin
            Build(false, 'x');
            Ok := TryAfter(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-x', SerX());
        end;
        Observer.Expect('k1', 'No');
        Observer.Expect('k1-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k1-err|code', 'InvalidOperation');
        Observer.Expect('k1-x', '<?t x?>');
        Observer.Expect('k2', 'No');
        Observer.Expect('k2-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k2-err|code', 'InvalidOperation');
        Observer.Expect('k2-x', '<?t x?>');
        Observer.Expect('k3', 'No');
        Observer.Expect('k3-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k3-err|code', 'InvalidOperation');
        Observer.Expect('k3-x', '<?t x?>');
        Observer.Expect('k4', 'No');
        Observer.Expect('k4-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k4-err|code', 'InvalidOperation');
        Observer.Expect('k4-x', '<?t x?>');
        Observer.Expect('k5', 'No');
        Observer.Expect('k5-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k5-err|code', 'InvalidOperation');
        Observer.Expect('k5-x', '<?t x?>');
        Observer.Verify();
    end;

    [Test]
    procedure AfterSelf_Detached_InvalidKinds()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 6 to 9 do begin
            Build(false, 'x');
            Ok := TryAfter(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-x', SerX());
        end;
        Observer.Expect('k6', 'No');
        Observer.Expect('k6-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k6-err|code', 'InvalidOperation');
        Observer.Expect('k6-x', '<?t x?>');
        Observer.Expect('k7', 'No');
        Observer.Expect('k7-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k7-err|code', 'InvalidOperation');
        Observer.Expect('k7-x', '<?t x?>');
        Observer.Expect('k8', 'No');
        Observer.Expect('k8-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k8-err|code', 'InvalidOperation');
        Observer.Expect('k8-x', '<?t x?>');
        Observer.Expect('k9', 'No');
        Observer.Expect('k9-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k9-err|code', 'InvalidOperation');
        Observer.Expect('k9-x', '<?t x?>');
        Observer.Verify();
    end;

    [Test]
    procedure AfterSelf_UninitialisedArgument()
    var
        Observer: Codeunit "Probe Observer";
        j: Integer;
        Ok: Boolean;
    begin
        for j := 0 to 1 do begin
            Build(j = 0, 'x');
            Ok := TryAfter(14);
            Observer.Observe('j' + Format(j), Format(Ok));
            Observer.ObserveError('j' + Format(j) + '-err');
            if j = 0 then
                Observer.Observe('j0-doc', SerDoc())
            else
                Observer.Observe('j1-x', SerX());
        end;
        Observer.Expect('j0', 'No');
        Observer.Expect('j0-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('j0-err|code', 'NotInitialized');
        Observer.Expect('j0-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('j1', 'No');
        Observer.Expect('j1-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('j1-err|code', 'NotInitialized');
        Observer.Expect('j1-x', '<?t x?>');
        Observer.Verify();
    end;

    [Test]
    procedure BeforeSelf_Attached_ValidKinds()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 1 to 5 do begin
            Build(true, 'x');
            Ok := TryBefore(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-doc', SerDoc());
        end;
        Observer.Expect('k1', 'Yes');
        Observer.Expect('k1-err|text', '');
        Observer.Expect('k1-err|code', '');
        Observer.Expect('k1-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <e1 />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('k2', 'Yes');
        Observer.Expect('k2-err|text', '');
        Observer.Expect('k2-err|code', '');
        Observer.Expect('k2-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />t2<?t x?><b /></r>');
        Observer.Expect('k3', 'Yes');
        Observer.Expect('k3-err|text', '');
        Observer.Expect('k3-err|code', '');
        Observer.Expect('k3-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--c3-->\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('k4', 'Yes');
        Observer.Expect('k4-err|text', '');
        Observer.Expect('k4-err|code', '');
        Observer.Expect('k4-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[d4]]><?t x?><b /></r>');
        Observer.Expect('k5', 'Yes');
        Observer.Expect('k5-err|text', '');
        Observer.Expect('k5-err|code', '');
        Observer.Expect('k5-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?p5 q5?>\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure BeforeSelf_Attached_InvalidKinds()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 6 to 9 do begin
            Build(true, 'x');
            Ok := TryBefore(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-doc', SerDoc());
        end;
        Observer.Expect('k6', 'No');
        Observer.Expect('k6-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k6-err|code', 'Argument');
        Observer.Expect('k6-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('k7', 'Yes');
        Observer.Expect('k7-err|text', '');
        Observer.Expect('k7-err|code', '');
        Observer.Expect('k7-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />&lt;?xml version="1.0" encoding="utf-8" standalone="yes"?&gt;<?t x?><b /></r>');
        Observer.Expect('k8', 'No');
        Observer.Expect('k8-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k8-err|code', 'Argument');
        Observer.Expect('k8-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('k9', 'No');
        Observer.Expect('k9-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k9-err|code', 'Argument');
        Observer.Expect('k9-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure BeforeSelf_Attached_ExistingNodes()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 10 to 13 do begin
            Build(true, 'x');
            Ok := TryBefore(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-doc', SerDoc());
        end;
        Observer.Expect('k10', 'Yes');
        Observer.Expect('k10-err|text', '');
        Observer.Expect('k10-err|code', '');
        Observer.Expect('k10-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('k11', 'Yes');
        Observer.Expect('k11-err|text', '');
        Observer.Expect('k11-err|code', '');
        Observer.Expect('k11-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('k12', 'Yes');
        Observer.Expect('k12-err|text', '');
        Observer.Expect('k12-err|code', '');
        Observer.Expect('k12-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <r>\r\n    <a />\r\n    <?t x?>\r\n    <b />\r\n  </r>\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('k13', 'Yes');
        Observer.Expect('k13-err|text', '');
        Observer.Expect('k13-err|code', '');
        Observer.Expect('k13-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <f13 />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure BeforeSelf_Detached_ValidKinds()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 1 to 5 do begin
            Build(false, 'x');
            Ok := TryBefore(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-x', SerX());
        end;
        Observer.Expect('k1', 'No');
        Observer.Expect('k1-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k1-err|code', 'InvalidOperation');
        Observer.Expect('k1-x', '<?t x?>');
        Observer.Expect('k2', 'No');
        Observer.Expect('k2-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k2-err|code', 'InvalidOperation');
        Observer.Expect('k2-x', '<?t x?>');
        Observer.Expect('k3', 'No');
        Observer.Expect('k3-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k3-err|code', 'InvalidOperation');
        Observer.Expect('k3-x', '<?t x?>');
        Observer.Expect('k4', 'No');
        Observer.Expect('k4-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k4-err|code', 'InvalidOperation');
        Observer.Expect('k4-x', '<?t x?>');
        Observer.Expect('k5', 'No');
        Observer.Expect('k5-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k5-err|code', 'InvalidOperation');
        Observer.Expect('k5-x', '<?t x?>');
        Observer.Verify();
    end;

    [Test]
    procedure BeforeSelf_Detached_InvalidKinds()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 6 to 9 do begin
            Build(false, 'x');
            Ok := TryBefore(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-x', SerX());
        end;
        Observer.Expect('k6', 'No');
        Observer.Expect('k6-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k6-err|code', 'InvalidOperation');
        Observer.Expect('k6-x', '<?t x?>');
        Observer.Expect('k7', 'No');
        Observer.Expect('k7-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k7-err|code', 'InvalidOperation');
        Observer.Expect('k7-x', '<?t x?>');
        Observer.Expect('k8', 'No');
        Observer.Expect('k8-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k8-err|code', 'InvalidOperation');
        Observer.Expect('k8-x', '<?t x?>');
        Observer.Expect('k9', 'No');
        Observer.Expect('k9-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k9-err|code', 'InvalidOperation');
        Observer.Expect('k9-x', '<?t x?>');
        Observer.Verify();
    end;

    [Test]
    procedure BeforeSelf_UninitialisedArgument()
    var
        Observer: Codeunit "Probe Observer";
        j: Integer;
        Ok: Boolean;
    begin
        for j := 0 to 1 do begin
            Build(j = 0, 'x');
            Ok := TryBefore(14);
            Observer.Observe('j' + Format(j), Format(Ok));
            Observer.ObserveError('j' + Format(j) + '-err');
            if j = 0 then
                Observer.Observe('j0-doc', SerDoc())
            else
                Observer.Observe('j1-x', SerX());
        end;
        Observer.Expect('j0', 'No');
        Observer.Expect('j0-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('j0-err|code', 'NotInitialized');
        Observer.Expect('j0-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('j1', 'No');
        Observer.Expect('j1-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('j1-err|code', 'NotInitialized');
        Observer.Expect('j1-x', '<?t x?>');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_Attached_ValidKinds()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 1 to 5 do begin
            Build(true, 'x');
            Ok := TryReplace(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-doc', SerDoc());
            Observer.Observe('k' + Format(i) + '-x-has-parent', Format(X.GetParent(P)));
        end;
        Observer.Expect('k1', 'Yes');
        Observer.Expect('k1-err|text', '');
        Observer.Expect('k1-err|code', '');
        Observer.Expect('k1-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <e1 />\r\n  <b />\r\n</r>');
        Observer.Expect('k1-x-has-parent', 'No');
        Observer.Expect('k2', 'Yes');
        Observer.Expect('k2-err|text', '');
        Observer.Expect('k2-err|code', '');
        Observer.Expect('k2-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />t2<b /></r>');
        Observer.Expect('k2-x-has-parent', 'No');
        Observer.Expect('k3', 'Yes');
        Observer.Expect('k3-err|text', '');
        Observer.Expect('k3-err|code', '');
        Observer.Expect('k3-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--c3-->\r\n  <b />\r\n</r>');
        Observer.Expect('k3-x-has-parent', 'No');
        Observer.Expect('k4', 'Yes');
        Observer.Expect('k4-err|text', '');
        Observer.Expect('k4-err|code', '');
        Observer.Expect('k4-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[d4]]><b /></r>');
        Observer.Expect('k4-x-has-parent', 'No');
        Observer.Expect('k5', 'Yes');
        Observer.Expect('k5-err|text', '');
        Observer.Expect('k5-err|code', '');
        Observer.Expect('k5-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?p5 q5?>\r\n  <b />\r\n</r>');
        Observer.Expect('k5-x-has-parent', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_Attached_InvalidKinds()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 6 to 9 do begin
            Build(true, 'x');
            Ok := TryReplace(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-doc', SerDoc());
            Observer.Observe('k' + Format(i) + '-x-has-parent', Format(X.GetParent(P)));
        end;
        Observer.Expect('k6', 'No');
        Observer.Expect('k6-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k6-err|code', 'Argument');
        Observer.Expect('k6-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('k6-x-has-parent', 'No');
        Observer.Expect('k7', 'Yes');
        Observer.Expect('k7-err|text', '');
        Observer.Expect('k7-err|code', '');
        Observer.Expect('k7-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />&lt;?xml version="1.0" encoding="utf-8" standalone="yes"?&gt;<b /></r>');
        Observer.Expect('k7-x-has-parent', 'No');
        Observer.Expect('k8', 'No');
        Observer.Expect('k8-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k8-err|code', 'Argument');
        Observer.Expect('k8-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('k8-x-has-parent', 'No');
        Observer.Expect('k9', 'No');
        Observer.Expect('k9-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k9-err|code', 'Argument');
        Observer.Expect('k9-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('k9-x-has-parent', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_Attached_ExistingNodes()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 10 to 13 do begin
            Build(true, 'x');
            Ok := TryReplace(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-doc', SerDoc());
            Observer.Observe('k' + Format(i) + '-x-has-parent', Format(X.GetParent(P)));
        end;
        Observer.Expect('k10', 'Yes');
        Observer.Expect('k10-err|text', '');
        Observer.Expect('k10-err|code', '');
        Observer.Expect('k10-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('k10-x-has-parent', 'No');
        Observer.Expect('k11', 'Yes');
        Observer.Expect('k11-err|text', '');
        Observer.Expect('k11-err|code', '');
        Observer.Expect('k11-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('k11-x-has-parent', 'Yes');
        Observer.Expect('k12', 'Yes');
        Observer.Expect('k12-err|text', '');
        Observer.Expect('k12-err|code', '');
        Observer.Expect('k12-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <r>\r\n    <a />\r\n    <b />\r\n  </r>\r\n  <b />\r\n</r>');
        Observer.Expect('k12-x-has-parent', 'No');
        Observer.Expect('k13', 'Yes');
        Observer.Expect('k13-err|text', '');
        Observer.Expect('k13-err|code', '');
        Observer.Expect('k13-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <f13 />\r\n  <b />\r\n</r>');
        Observer.Expect('k13-x-has-parent', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_Detached_ValidKinds()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 1 to 5 do begin
            Build(false, 'x');
            Ok := TryReplace(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-x', SerX());
        end;
        Observer.Expect('k1', 'No');
        Observer.Expect('k1-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k1-err|code', 'InvalidOperation');
        Observer.Expect('k1-x', '<?t x?>');
        Observer.Expect('k2', 'No');
        Observer.Expect('k2-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k2-err|code', 'InvalidOperation');
        Observer.Expect('k2-x', '<?t x?>');
        Observer.Expect('k3', 'No');
        Observer.Expect('k3-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k3-err|code', 'InvalidOperation');
        Observer.Expect('k3-x', '<?t x?>');
        Observer.Expect('k4', 'No');
        Observer.Expect('k4-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k4-err|code', 'InvalidOperation');
        Observer.Expect('k4-x', '<?t x?>');
        Observer.Expect('k5', 'No');
        Observer.Expect('k5-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k5-err|code', 'InvalidOperation');
        Observer.Expect('k5-x', '<?t x?>');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_Detached_InvalidKinds()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        i: Integer;
        Ok: Boolean;
    begin
        for i := 6 to 9 do begin
            Build(false, 'x');
            Ok := TryReplace(i);
            Observer.Observe('k' + Format(i), Format(Ok));
            Observer.ObserveError('k' + Format(i) + '-err');
            Observer.Observe('k' + Format(i) + '-x', SerX());
        end;
        Observer.Expect('k6', 'No');
        Observer.Expect('k6-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k6-err|code', 'InvalidOperation');
        Observer.Expect('k6-x', '<?t x?>');
        Observer.Expect('k7', 'No');
        Observer.Expect('k7-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k7-err|code', 'InvalidOperation');
        Observer.Expect('k7-x', '<?t x?>');
        Observer.Expect('k8', 'No');
        Observer.Expect('k8-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k8-err|code', 'InvalidOperation');
        Observer.Expect('k8-x', '<?t x?>');
        Observer.Expect('k9', 'No');
        Observer.Expect('k9-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k9-err|code', 'InvalidOperation');
        Observer.Expect('k9-x', '<?t x?>');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_UninitialisedArgument()
    var
        Observer: Codeunit "Probe Observer";
        j: Integer;
        Ok: Boolean;
    begin
        for j := 0 to 1 do begin
            Build(j = 0, 'x');
            Ok := TryReplace(14);
            Observer.Observe('j' + Format(j), Format(Ok));
            Observer.ObserveError('j' + Format(j) + '-err');
            if j = 0 then
                Observer.Observe('j0-doc', SerDoc())
            else
                Observer.Observe('j1-x', SerX());
        end;
        Observer.Expect('j0', 'No');
        Observer.Expect('j0-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('j0-err|code', 'NotInitialized');
        Observer.Expect('j0-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('j1', 'No');
        Observer.Expect('j1-err|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('j1-err|code', 'NotInitialized');
        Observer.Expect('j1-x', '<?t x?>');
        Observer.Verify();
    end;

    [Test]
    procedure AfterSelf_ThreeNodesOrder()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TryAfter3(101, 102, 103);
        Observer.Observe('t101_102_103', Format(Ok));
        Observer.ObserveError('t101_102_103-err');
        Observer.Observe('t101_102_103-doc', SerDoc());
        Build(true, 'x');
        Ok := TryAfter3(103, 101, 102);
        Observer.Observe('t103_101_102', Format(Ok));
        Observer.ObserveError('t103_101_102-err');
        Observer.Observe('t103_101_102-doc', SerDoc());
        Observer.Expect('t101_102_103', 'Yes');
        Observer.Expect('t101_102_103-err|text', '');
        Observer.Expect('t101_102_103-err|code', '');
        Observer.Expect('t101_102_103-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <m1 />\r\n  <m2 />\r\n  <m3 />\r\n  <b />\r\n</r>');
        Observer.Expect('t103_101_102', 'Yes');
        Observer.Expect('t103_101_102-err|text', '');
        Observer.Expect('t103_101_102-err|code', '');
        Observer.Expect('t103_101_102-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <m3 />\r\n  <m1 />\r\n  <m2 />\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure AfterSelf_ThreeNodes_OneInvalid()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TryAfter3(1, 6, 3);
        Observer.Observe('t1_6_3', Format(Ok));
        Observer.ObserveError('t1_6_3-err');
        Observer.Observe('t1_6_3-doc', SerDoc());
        Build(true, 'x');
        Ok := TryAfter3(6, 1, 3);
        Observer.Observe('t6_1_3', Format(Ok));
        Observer.ObserveError('t6_1_3-err');
        Observer.Observe('t6_1_3-doc', SerDoc());
        Build(true, 'x');
        Ok := TryAfter3(1, 3, 6);
        Observer.Observe('t1_3_6', Format(Ok));
        Observer.ObserveError('t1_3_6-err');
        Observer.Observe('t1_3_6-doc', SerDoc());
        Build(true, 'x');
        Ok := TryAfter3(2, 2, 2);
        Observer.Observe('t2_2_2', Format(Ok));
        Observer.ObserveError('t2_2_2-err');
        Observer.Observe('t2_2_2-doc', SerDoc());
        Observer.Expect('t1_6_3', 'No');
        Observer.Expect('t1_6_3-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t1_6_3-err|code', 'Argument');
        Observer.Expect('t1_6_3-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <e1 />\r\n  <b />\r\n</r>');
        Observer.Expect('t6_1_3', 'No');
        Observer.Expect('t6_1_3-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t6_1_3-err|code', 'Argument');
        Observer.Expect('t6_1_3-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('t1_3_6', 'No');
        Observer.Expect('t1_3_6-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t1_3_6-err|code', 'Argument');
        Observer.Expect('t1_3_6-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <e1 />\r\n  <!--c3-->\r\n  <b />\r\n</r>');
        Observer.Expect('t2_2_2', 'Yes');
        Observer.Expect('t2_2_2-err|text', '');
        Observer.Expect('t2_2_2-err|code', '');
        Observer.Expect('t2_2_2-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>t2t2t2<b /></r>');
        Observer.Verify();
    end;

    [Test]
    procedure BeforeSelf_ThreeNodesOrder()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TryBefore3(101, 102, 103);
        Observer.Observe('t101_102_103', Format(Ok));
        Observer.ObserveError('t101_102_103-err');
        Observer.Observe('t101_102_103-doc', SerDoc());
        Build(true, 'x');
        Ok := TryBefore3(103, 101, 102);
        Observer.Observe('t103_101_102', Format(Ok));
        Observer.ObserveError('t103_101_102-err');
        Observer.Observe('t103_101_102-doc', SerDoc());
        Observer.Expect('t101_102_103', 'Yes');
        Observer.Expect('t101_102_103-err|text', '');
        Observer.Expect('t101_102_103-err|code', '');
        Observer.Expect('t101_102_103-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <m1 />\r\n  <m2 />\r\n  <m3 />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('t103_101_102', 'Yes');
        Observer.Expect('t103_101_102-err|text', '');
        Observer.Expect('t103_101_102-err|code', '');
        Observer.Expect('t103_101_102-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <m3 />\r\n  <m1 />\r\n  <m2 />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure BeforeSelf_ThreeNodes_OneInvalid()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TryBefore3(1, 6, 3);
        Observer.Observe('t1_6_3', Format(Ok));
        Observer.ObserveError('t1_6_3-err');
        Observer.Observe('t1_6_3-doc', SerDoc());
        Build(true, 'x');
        Ok := TryBefore3(6, 1, 3);
        Observer.Observe('t6_1_3', Format(Ok));
        Observer.ObserveError('t6_1_3-err');
        Observer.Observe('t6_1_3-doc', SerDoc());
        Build(true, 'x');
        Ok := TryBefore3(1, 3, 6);
        Observer.Observe('t1_3_6', Format(Ok));
        Observer.ObserveError('t1_3_6-err');
        Observer.Observe('t1_3_6-doc', SerDoc());
        Build(true, 'x');
        Ok := TryBefore3(2, 2, 2);
        Observer.Observe('t2_2_2', Format(Ok));
        Observer.ObserveError('t2_2_2-err');
        Observer.Observe('t2_2_2-doc', SerDoc());
        Observer.Expect('t1_6_3', 'No');
        Observer.Expect('t1_6_3-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t1_6_3-err|code', 'Argument');
        Observer.Expect('t1_6_3-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <e1 />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('t6_1_3', 'No');
        Observer.Expect('t6_1_3-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t6_1_3-err|code', 'Argument');
        Observer.Expect('t6_1_3-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('t1_3_6', 'No');
        Observer.Expect('t1_3_6-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t1_3_6-err|code', 'Argument');
        Observer.Expect('t1_3_6-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <e1 />\r\n  <!--c3-->\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('t2_2_2', 'Yes');
        Observer.Expect('t2_2_2-err|text', '');
        Observer.Expect('t2_2_2-err|code', '');
        Observer.Expect('t2_2_2-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />t2t2t2<?t x?><b /></r>');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_ThreeNodesOrder()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TryReplace3(101, 102, 103);
        Observer.Observe('t101_102_103', Format(Ok));
        Observer.ObserveError('t101_102_103-err');
        Observer.Observe('t101_102_103-doc', SerDoc());
        Build(true, 'x');
        Ok := TryReplace3(103, 101, 102);
        Observer.Observe('t103_101_102', Format(Ok));
        Observer.ObserveError('t103_101_102-err');
        Observer.Observe('t103_101_102-doc', SerDoc());
        Observer.Expect('t101_102_103', 'Yes');
        Observer.Expect('t101_102_103-err|text', '');
        Observer.Expect('t101_102_103-err|code', '');
        Observer.Expect('t101_102_103-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <m1 />\r\n  <m2 />\r\n  <m3 />\r\n  <b />\r\n</r>');
        Observer.Expect('t103_101_102', 'Yes');
        Observer.Expect('t103_101_102-err|text', '');
        Observer.Expect('t103_101_102-err|code', '');
        Observer.Expect('t103_101_102-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <m3 />\r\n  <m1 />\r\n  <m2 />\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_ThreeNodes_OneInvalid()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TryReplace3(1, 6, 3);
        Observer.Observe('t1_6_3', Format(Ok));
        Observer.ObserveError('t1_6_3-err');
        Observer.Observe('t1_6_3-doc', SerDoc());
        Build(true, 'x');
        Ok := TryReplace3(6, 1, 3);
        Observer.Observe('t6_1_3', Format(Ok));
        Observer.ObserveError('t6_1_3-err');
        Observer.Observe('t6_1_3-doc', SerDoc());
        Build(true, 'x');
        Ok := TryReplace3(1, 3, 6);
        Observer.Observe('t1_3_6', Format(Ok));
        Observer.ObserveError('t1_3_6-err');
        Observer.Observe('t1_3_6-doc', SerDoc());
        Build(true, 'x');
        Ok := TryReplace3(2, 2, 2);
        Observer.Observe('t2_2_2', Format(Ok));
        Observer.ObserveError('t2_2_2-err');
        Observer.Observe('t2_2_2-doc', SerDoc());
        Observer.Expect('t1_6_3', 'No');
        Observer.Expect('t1_6_3-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t1_6_3-err|code', 'Argument');
        Observer.Expect('t1_6_3-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <e1 />\r\n  <b />\r\n</r>');
        Observer.Expect('t6_1_3', 'No');
        Observer.Expect('t6_1_3-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t6_1_3-err|code', 'Argument');
        Observer.Expect('t6_1_3-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('t1_3_6', 'No');
        Observer.Expect('t1_3_6-err|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t1_3_6-err|code', 'Argument');
        Observer.Expect('t1_3_6-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <e1 />\r\n  <!--c3-->\r\n  <b />\r\n</r>');
        Observer.Expect('t2_2_2', 'Yes');
        Observer.Expect('t2_2_2-err|text', '');
        Observer.Expect('t2_2_2-err|code', '');
        Observer.Expect('t2_2_2-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />t2t2t2<b /></r>');
        Observer.Verify();
    end;

    [Test]
    procedure AfterSelf_ThreeNodes_Detached()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(false, 'x');
        Ok := TryAfter3(101, 102, 103);
        Observer.Observe('t101_102_103', Format(Ok));
        Observer.ObserveError('t101_102_103-err');
        Observer.Observe('t101_102_103-x', SerX());
        Observer.Expect('t101_102_103', 'No');
        Observer.Expect('t101_102_103-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t101_102_103-err|code', 'InvalidOperation');
        Observer.Expect('t101_102_103-x', '<?t x?>');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_ThreeNodes_Detached()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(false, 'x');
        Ok := TryReplace3(101, 102, 103);
        Observer.Observe('t101_102_103', Format(Ok));
        Observer.ObserveError('t101_102_103-err');
        Observer.Observe('t101_102_103-x', SerX());
        Observer.Expect('t101_102_103', 'No');
        Observer.Expect('t101_102_103-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t101_102_103-err|code', 'InvalidOperation');
        Observer.Expect('t101_102_103-x', '<?t x?>');
        Observer.Verify();
    end;

    [Test]
    procedure Positions_AfterBeforeReplaceRemove()
    var
        Observer: Codeunit "Probe Observer";
        Pos: Integer;
        Ok: Boolean;
    begin
        for Pos := 0 to 3 do begin
            BuildAt(true, Pos, 'x');
            Ok := TryAfter(1);
            Observer.Observe('p' + Format(Pos) + '-after', Format(Ok) + ' ' + SerDoc());
            BuildAt(true, Pos, 'x');
            Ok := TryBefore(1);
            Observer.Observe('p' + Format(Pos) + '-before', Format(Ok) + ' ' + SerDoc());
            BuildAt(true, Pos, 'x');
            Ok := TryReplace(1);
            Observer.Observe('p' + Format(Pos) + '-replace', Format(Ok) + ' ' + SerDoc());
            BuildAt(true, Pos, 'x');
            Ok := TryRemove();
            Observer.Observe('p' + Format(Pos) + '-remove', Format(Ok) + ' ' + SerDoc());
        end;
        Observer.Expect('p0-after', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <?t x?>\r\n  <e1 />\r\n</r>');
        Observer.Expect('p0-before', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <e1 />\r\n  <?t x?>\r\n</r>');
        Observer.Expect('p0-replace', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <e1 />\r\n</r>');
        Observer.Expect('p0-remove', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r />');
        Observer.Expect('p1-after', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <?t x?>\r\n  <e1 />\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('p1-before', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <e1 />\r\n  <?t x?>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('p1-replace', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <e1 />\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('p1-remove', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('p2-after', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <e1 />\r\n  <b />\r\n</r>');
        Observer.Expect('p2-before', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <e1 />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('p2-replace', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <e1 />\r\n  <b />\r\n</r>');
        Observer.Expect('p2-remove', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('p3-after', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n  <?t x?>\r\n  <e1 />\r\n</r>');
        Observer.Expect('p3-before', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n  <e1 />\r\n  <?t x?>\r\n</r>');
        Observer.Expect('p3-replace', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n  <e1 />\r\n</r>');
        Observer.Expect('p3-remove', 'Yes <?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure AfterBeforeSelf_NoCrossTalk_TextNeighbours()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        // text and cdata added next to the node: do they merge or stay separate nodes
        Build(true, 'x');
        Ok := TryAfter(2);
        Ok := TryBefore(2);
        Observer.Observe('doc-text-both-sides', SerDoc());
        Observer.Observe('root-child-count', Format(Root.GetChildNodes().Count()));
        Build(true, 'x');
        Ok := TryAfter(4);
        Ok := TryBefore(4);
        Observer.Observe('doc-cdata-both-sides', SerDoc());
        Observer.Observe('root-child-count-cdata', Format(Root.GetChildNodes().Count()));
        Build(true, 'x');
        Ok := TryAfter(3);
        Ok := TryAfter(5);
        Ok := TryBefore(3);
        Ok := TryBefore(5);
        Observer.Observe('doc-comment-pi-both-sides', SerDoc());
        Observer.Observe('root-child-count-mixed', Format(Root.GetChildNodes().Count()));
        Observer.Expect('doc-text-both-sides', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />t2<?t x?>t2<b /></r>');
        Observer.Expect('root-child-count', '5');
        Observer.Expect('doc-cdata-both-sides', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[d4]]><?t x?><![CDATA[d4]]><b /></r>');
        Observer.Expect('root-child-count-cdata', '5');
        Observer.Expect('doc-comment-pi-both-sides', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--c3-->\r\n  <?p5 q5?>\r\n  <?t x?>\r\n  <?p5 q5?>\r\n  <!--c3-->\r\n  <b />\r\n</r>');
        Observer.Expect('root-child-count-mixed', '7');
        Observer.Verify();
    end;

    [Test]
    procedure AfterSelf_ExistingNode_CopiedOrMoved()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
        E: XmlElement;
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TryAfter(10);
        Observer.Observe('add-sibling-a-after-x', SerDoc());
        Observer.Observe('child-count', Format(Root.GetChildNodes().Count()));
        Root.SelectSingleNode('a', N);
        E := N.AsXmlElement();
        E.SetAttribute('changed', '1');
        Observer.Observe('after-changing-first-a', SerDoc());
        Build(true, 'x');
        Ok := TryBefore(10);
        Observer.Observe('add-sibling-a-before-x', SerDoc());
        Observer.Observe('child-count-before', Format(Root.GetChildNodes().Count()));
        Build(true, 'x');
        Ok := TryAfter(13);
        Observer.Observe('add-foreign-root-after-x', SerDoc());
        Observer.Observe('child-count-foreign', Format(Root.GetChildNodes().Count()));
        Observer.Expect('add-sibling-a-after-x', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('child-count', '4');
        Observer.Expect('after-changing-first-a', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a changed="1" />\r\n  <?t x?>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('add-sibling-a-before-x', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <a />\r\n  <?t x?>\r\n  <b />\r\n</r>');
        Observer.Expect('child-count-before', '4');
        Observer.Expect('add-foreign-root-after-x', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?t x?>\r\n  <f13 />\r\n  <b />\r\n</r>');
        Observer.Expect('child-count-foreign', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_Attached_Twice()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        D: XmlDocument;
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TryRemove();
        Observer.Observe('remove1', Format(Ok));
        Observer.ObserveError('remove1-err');
        Observer.Observe('remove1-doc', SerDoc());
        Observer.Observe('remove1-has-parent', Format(X.GetParent(P)));
        Observer.Observe('remove1-has-document', Format(X.GetDocument(D)));
        Observer.Observe('remove1-x', SerX());
        Ok := TryRemove();
        Observer.Observe('remove2', Format(Ok));
        Observer.ObserveError('remove2-err');
        Observer.Observe('remove2-doc', SerDoc());
        Observer.Expect('remove1', 'Yes');
        Observer.Expect('remove1-err|text', '');
        Observer.Expect('remove1-err|code', '');
        Observer.Expect('remove1-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('remove1-has-parent', 'No');
        Observer.Expect('remove1-has-document', 'No');
        Observer.Expect('remove1-x', '<?t x?>');
        Observer.Expect('remove2', 'No');
        Observer.Expect('remove2-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('remove2-err|code', 'InvalidOperation');
        Observer.Expect('remove2-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_Detached_Twice()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Build(false, 'x');
        Ok := TryRemove();
        Observer.Observe('remove1', Format(Ok));
        Observer.ObserveError('remove1-err');
        Observer.Observe('remove1-x', SerX());
        Ok := TryRemove();
        Observer.Observe('remove2', Format(Ok));
        Observer.ObserveError('remove2-err');
        Observer.Observe('remove2-x', SerX());
        Observer.Expect('remove1', 'No');
        Observer.Expect('remove1-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('remove1-err|code', 'InvalidOperation');
        Observer.Expect('remove1-x', '<?t x?>');
        Observer.Expect('remove2', 'No');
        Observer.Expect('remove2-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('remove2-err|code', 'InvalidOperation');
        Observer.Expect('remove2-x', '<?t x?>');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_ViaXmlNode_AndCopiedVariable()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
        Y: XmlProcessingInstruction;
        P: XmlElement;
        Ok: Boolean;
    begin
        Build(true, 'x');
        N := X.AsXmlNode();
        Y := X;
        N.Remove();
        Observer.Observe('doc-after-node-remove', SerDoc());
        Observer.Observe('x-has-parent', Format(X.GetParent(P)));
        Observer.Observe('y-has-parent', Format(Y.GetParent(P)));
        Ok := TryRemove();
        Observer.Observe('remove-via-typed-again', Format(Ok));
        Observer.ObserveError('remove-via-typed-again-err');
        Observer.Observe('y-x-same-text', Format(SerNode(Y.AsXmlNode()) = SerX()));
        Observer.Expect('doc-after-node-remove', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('x-has-parent', 'No');
        Observer.Expect('y-has-parent', 'No');
        Observer.Expect('remove-via-typed-again', 'No');
        Observer.Expect('remove-via-typed-again-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('remove-via-typed-again-err|code', 'InvalidOperation');
        Observer.Expect('y-x-same-text', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_ThenAddAgain()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        Ok: Boolean;
    begin
        Build(true, 'x');
        X.Remove();
        Root.Add(X);
        Observer.Observe('readded-doc', SerDoc());
        Observer.Observe('readded-has-parent', Format(X.GetParent(P)));
        Root.Add(X);
        Observer.Observe('added-twice-doc', SerDoc());
        Observer.Observe('added-twice-count', Format(Root.GetChildNodes().Count()));
        Build(true, 'x');
        X.Remove();
        Ok := TryAfter(1);
        Observer.Observe('after-self-on-removed', Format(Ok));
        Observer.ObserveError('after-self-on-removed-err');
        Ok := TryReplace(1);
        Observer.Observe('replace-on-removed', Format(Ok));
        Observer.ObserveError('replace-on-removed-err');
        Observer.Expect('readded-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n  <?t x?>\r\n</r>');
        Observer.Expect('readded-has-parent', 'Yes');
        Observer.Expect('added-twice-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n  <?t x?>\r\n  <?t x?>\r\n</r>');
        Observer.Expect('added-twice-count', '4');
        Observer.Expect('after-self-on-removed', 'No');
        Observer.Expect('after-self-on-removed-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('after-self-on-removed-err|code', 'InvalidOperation');
        Observer.Expect('replace-on-removed', 'No');
        Observer.Expect('replace-on-removed-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('replace-on-removed-err|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_Twice_And_ReplacementChain()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
        N: XmlNode;
        Ok: Boolean;
    begin
        Build(true, 'x');
        Ok := TryReplace(1);
        Observer.Observe('replace1', Format(Ok));
        Observer.Observe('replace1-doc', SerDoc());
        Ok := TryReplace(3);
        Observer.Observe('replace2-on-replaced', Format(Ok));
        Observer.ObserveError('replace2-err');
        Observer.Observe('replace2-doc', SerDoc());
        Build(true, 'x');
        E := XmlElement.Create('rep');
        X.ReplaceWith(E);
        Observer.Observe('free-element-replace-doc', SerDoc());
        E.SetAttribute('later', '1');
        Observer.Observe('after-changing-e', SerDoc());
        Root.GetChildNodes().Get(2, N);
        Observer.Observe('node-at-2', SerNode(N));
        Observer.Expect('replace1', 'Yes');
        Observer.Expect('replace1-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <e1 />\r\n  <b />\r\n</r>');
        Observer.Expect('replace2-on-replaced', 'No');
        Observer.Expect('replace2-err|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('replace2-err|code', 'InvalidOperation');
        Observer.Expect('replace2-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <e1 />\r\n  <b />\r\n</r>');
        Observer.Expect('free-element-replace-doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <rep />\r\n  <b />\r\n</r>');
        Observer.Expect('after-changing-e', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <rep later="1" />\r\n  <b />\r\n</r>');
        Observer.Expect('node-at-2', '<rep later="1" />');
        Observer.Verify();
    end;

}
