// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlattribute/xmlattribute-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlAttribute AddAfterSelf, AddBeforeSelf, ReplaceWith with every node kind as argument, attached and detached, and the serialized result after each change; typed arguments
// BC versions: 29 (27 and 28 by CI)

codeunit 74801 "LT P97 Attr Edit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Doc: XmlDocument;
        Root: XmlElement;
        X: XmlAttribute;
        Attached: Boolean;

    local procedure Build(IsAttached: Boolean)
    begin
        Attached := IsAttached;
        if not IsAttached then begin
            X := XmlAttribute.Create('x', '2');
            exit;
        end;
        Doc := XmlDocument.Create();
        Root := XmlElement.Create('r');
        Root.SetAttribute('p', '1');
        Root.SetAttribute('x', '2');
        Root.SetAttribute('q', '3');
        Root.Add(XmlElement.Create('c'));
        Doc.Add(Root);
        Doc.GetRoot(Root);
        Root.Attributes().Get('x', X);
    end;

    local procedure State(): Text
    var
        S: Text;
    begin
        if Attached then
            Root.WriteTo(S)
        else
            X.WriteTo(S);
        exit(S);
    end;

    // Kinds: 1 element, 2 text, 3 comment, 4 cdata, 5 processing instruction, 6 new attribute, 7 declaration, 8 empty document,
    // 9 document type, 10 sibling of the subject (has a parent), 11 the subject itself, 12 the root r, 13 node attached to another document,
    // 14 uninitialised XmlNode, 15 attribute with the same name x, 16 namespace declaration attribute, 17 attribute with a namespace, 18 empty attribute
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
                    if Attached then
                        Root.Attributes().Get('p', A);
                    exit(A.AsXmlNode());
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
                exit(N);
            15:
                begin
                    A := XmlAttribute.Create('x', 'dup');
                    exit(A.AsXmlNode());
                end;
            16:
                begin
                    A := XmlAttribute.CreateNamespaceDeclaration('n16', 'urn:n16');
                    exit(A.AsXmlNode());
                end;
            17:
                begin
                    A := XmlAttribute.Create('a17', 'urn:a17', 'v');
                    exit(A.AsXmlNode());
                end;
            18:
                begin
                    A := XmlAttribute.Create('a18', '');
                    exit(A.AsXmlNode());
                end;
        end;
    end;

    [TryFunction]
    local procedure TryRun(Op: Integer; Kind: Integer; var S: Text)
    begin
        case Op of
            1:
                X.AddAfterSelf(MakeArg(Kind));
            2:
                X.AddBeforeSelf(MakeArg(Kind));
            3:
                X.ReplaceWith(MakeArg(Kind));
        end;
        S := State();
    end;

    [TryFunction]
    local procedure TryTyped(Op: Integer; Kind: Integer; var S: Text)
    begin
        ApplyTyped(Op, Kind);
        S := State();
    end;

    local procedure ApplyTyped(Op: Integer; Kind: Integer)
    var
        E: XmlElement;
        T: XmlText;
        C: XmlComment;
        D: XmlCData;
        P: XmlProcessingInstruction;
        A: XmlAttribute;
        Decl: XmlDeclaration;
        Doc2: XmlDocument;
        Num: Integer;
        A2: XmlAttribute;
    begin
        E := XmlElement.Create('te');
        T := XmlText.Create('tt');
        C := XmlComment.Create('tc');
        D := XmlCData.Create('td');
        P := XmlProcessingInstruction.Create('tp', 'tq');
        A := XmlAttribute.Create('ta', '1');
        Decl := XmlDeclaration.Create('1.0', 'utf-8', 'no');
        Doc2 := XmlDocument.Create();
        Num := 42;
        A2 := XmlAttribute.Create('tb', '2');
        case Kind of
            1:
                case Op of
                    1:
                        X.AddAfterSelf(E);
                    2:
                        X.AddBeforeSelf(E);
                    3:
                        X.ReplaceWith(E);
                end;
            2:
                case Op of
                    1:
                        X.AddAfterSelf(T);
                    2:
                        X.AddBeforeSelf(T);
                    3:
                        X.ReplaceWith(T);
                end;
            3:
                case Op of
                    1:
                        X.AddAfterSelf(C);
                    2:
                        X.AddBeforeSelf(C);
                    3:
                        X.ReplaceWith(C);
                end;
            4:
                case Op of
                    1:
                        X.AddAfterSelf(D);
                    2:
                        X.AddBeforeSelf(D);
                    3:
                        X.ReplaceWith(D);
                end;
            5:
                case Op of
                    1:
                        X.AddAfterSelf(P);
                    2:
                        X.AddBeforeSelf(P);
                    3:
                        X.ReplaceWith(P);
                end;
            6:
                case Op of
                    1:
                        X.AddAfterSelf(A);
                    2:
                        X.AddBeforeSelf(A);
                    3:
                        X.ReplaceWith(A);
                end;
            7:
                case Op of
                    1:
                        X.AddAfterSelf(Decl);
                    2:
                        X.AddBeforeSelf(Decl);
                    3:
                        X.ReplaceWith(Decl);
                end;
            8:
                case Op of
                    1:
                        X.AddAfterSelf(Doc2);
                    2:
                        X.AddBeforeSelf(Doc2);
                    3:
                        X.ReplaceWith(Doc2);
                end;
            9:
                case Op of
                    1:
                        X.AddAfterSelf('plain text');
                    2:
                        X.AddBeforeSelf('plain text');
                    3:
                        X.ReplaceWith('plain text');
                end;
            10:
                case Op of
                    1:
                        X.AddAfterSelf(Num);
                    2:
                        X.AddBeforeSelf(Num);
                    3:
                        X.ReplaceWith(Num);
                end;
            11:
                case Op of
                    1:
                        X.AddAfterSelf(A, A2);
                    2:
                        X.AddBeforeSelf(A, A2);
                    3:
                        X.ReplaceWith(A, A2);
                end;
            12:
                case Op of
                    1:
                        X.AddAfterSelf(E, T);
                    2:
                        X.AddBeforeSelf(E, T);
                    3:
                        X.ReplaceWith(E, T);
                end;
        end;
    end;

    local procedure RunKinds(var Observer: Codeunit "Probe Observer"; Op: Integer; IsAttached: Boolean)
    var
        Kind: Integer;
        S: Text;
    begin
        for Kind := 1 to 18 do begin
            Build(IsAttached);
            S := '';
            if TryRun(Op, Kind, S) then
                Observer.Observe('k' + Format(Kind), S)
            else
                Observer.ObserveError('k' + Format(Kind));
        end;
    end;

    local procedure RunTyped(var Observer: Codeunit "Probe Observer"; Op: Integer; IsAttached: Boolean)
    var
        Kind: Integer;
        S: Text;
    begin
        for Kind := 1 to 12 do begin
            Build(IsAttached);
            S := '';
            if TryTyped(Op, Kind, S) then
                Observer.Observe('t' + Format(Kind), S)
            else
                Observer.ObserveError('t' + Format(Kind));
        end;
    end;

    [Test]
    procedure AddAfterSelf_Attached_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 1, true);
        Observer.Expect('k1|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k1|code', 'Argument');
        Observer.Expect('k2|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k2|code', 'Argument');
        Observer.Expect('k3|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k3|code', 'Argument');
        Observer.Expect('k4|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k4|code', 'Argument');
        Observer.Expect('k5|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k5|code', 'Argument');
        Observer.Expect('k6', '<r p="1" x="2" a6="1" q="3">\r\n  <c />\r\n</r>');
        Observer.Expect('k7|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k7|code', 'Argument');
        Observer.Expect('k8|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k8|code', 'Argument');
        Observer.Expect('k9|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k9|code', 'Argument');
        Observer.Expect('k10|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k10|code', 'InvalidOperation');
        Observer.Expect('k11|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k11|code', 'InvalidOperation');
        Observer.Expect('k12|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k12|code', 'Argument');
        Observer.Expect('k13|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k13|code', 'Argument');
        Observer.Expect('k14|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('k14|code', 'NotInitialized');
        Observer.Expect('k15|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k15|code', 'InvalidOperation');
        Observer.Expect('k16', '<r p="1" x="2" xmlns:n16="urn:n16" q="3">\r\n  <c />\r\n</r>');
        Observer.Expect('k17', '<r p="1" x="2" p1:a17="v" q="3" xmlns:p1="urn:a17">\r\n  <c />\r\n</r>');
        Observer.Expect('k18', '<r p="1" x="2" a18="" q="3">\r\n  <c />\r\n</r>');
        Observer.Verify();
    end;





    [Test]
    procedure AddAfterSelf_Attached_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTyped(Observer, 1, true);
        Observer.Expect('t1|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t1|code', 'Argument');
        Observer.Expect('t2|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t2|code', 'Argument');
        Observer.Expect('t3|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t3|code', 'Argument');
        Observer.Expect('t4|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t4|code', 'Argument');
        Observer.Expect('t5|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t5|code', 'Argument');
        Observer.Expect('t6', '<r p="1" x="2" ta="1" q="3">\r\n  <c />\r\n</r>');
        Observer.Expect('t7|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t7|code', 'Argument');
        Observer.Expect('t8|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t8|code', 'Argument');
        Observer.Expect('t9|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t9|code', 'Argument');
        Observer.Expect('t10|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t10|code', 'Argument');
        Observer.Expect('t11', '<r p="1" x="2" ta="1" tb="2" q="3">\r\n  <c />\r\n</r>');
        Observer.Expect('t12|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t12|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure AddAfterSelf_Detached_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 1, false);
        Observer.Expect('k1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k1|code', 'InvalidOperation');
        Observer.Expect('k2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k2|code', 'InvalidOperation');
        Observer.Expect('k3|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k3|code', 'InvalidOperation');
        Observer.Expect('k4|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k4|code', 'InvalidOperation');
        Observer.Expect('k5|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k5|code', 'InvalidOperation');
        Observer.Expect('k6|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k6|code', 'InvalidOperation');
        Observer.Expect('k7|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k7|code', 'InvalidOperation');
        Observer.Expect('k8|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k8|code', 'InvalidOperation');
        Observer.Expect('k9|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k9|code', 'InvalidOperation');
        Observer.Expect('k10|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k10|code', 'InvalidOperation');
        Observer.Expect('k11|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k11|code', 'InvalidOperation');
        Observer.Expect('k12|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k12|code', 'InvalidOperation');
        Observer.Expect('k13|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k13|code', 'InvalidOperation');
        Observer.Expect('k14|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k14|code', 'InvalidOperation');
        Observer.Expect('k15|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k15|code', 'InvalidOperation');
        Observer.Expect('k16|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k16|code', 'InvalidOperation');
        Observer.Expect('k17|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k17|code', 'InvalidOperation');
        Observer.Expect('k18|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k18|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure AddAfterSelf_Detached_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTyped(Observer, 1, false);
        Observer.Expect('t1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t1|code', 'InvalidOperation');
        Observer.Expect('t2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t2|code', 'InvalidOperation');
        Observer.Expect('t3|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t3|code', 'InvalidOperation');
        Observer.Expect('t4|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t4|code', 'InvalidOperation');
        Observer.Expect('t5|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t5|code', 'InvalidOperation');
        Observer.Expect('t6|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t6|code', 'InvalidOperation');
        Observer.Expect('t7|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t7|code', 'InvalidOperation');
        Observer.Expect('t8|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t8|code', 'InvalidOperation');
        Observer.Expect('t9|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t9|code', 'InvalidOperation');
        Observer.Expect('t10|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t10|code', 'InvalidOperation');
        Observer.Expect('t11|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t11|code', 'InvalidOperation');
        Observer.Expect('t12|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t12|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure AddBeforeSelf_Attached_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 2, true);
        Observer.Expect('k1|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k1|code', 'Argument');
        Observer.Expect('k2|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k2|code', 'Argument');
        Observer.Expect('k3|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k3|code', 'Argument');
        Observer.Expect('k4|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k4|code', 'Argument');
        Observer.Expect('k5|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k5|code', 'Argument');
        Observer.Expect('k6', '<r p="1" a6="1" x="2" q="3">\r\n  <c />\r\n</r>');
        Observer.Expect('k7|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k7|code', 'Argument');
        Observer.Expect('k8|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k8|code', 'Argument');
        Observer.Expect('k9|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k9|code', 'Argument');
        Observer.Expect('k10|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k10|code', 'InvalidOperation');
        Observer.Expect('k11|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k11|code', 'InvalidOperation');
        Observer.Expect('k12|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k12|code', 'Argument');
        Observer.Expect('k13|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k13|code', 'Argument');
        Observer.Expect('k14|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('k14|code', 'NotInitialized');
        Observer.Expect('k15|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k15|code', 'InvalidOperation');
        Observer.Expect('k16', '<r p="1" xmlns:n16="urn:n16" x="2" q="3">\r\n  <c />\r\n</r>');
        Observer.Expect('k17', '<r p="1" p1:a17="v" x="2" q="3" xmlns:p1="urn:a17">\r\n  <c />\r\n</r>');
        Observer.Expect('k18', '<r p="1" a18="" x="2" q="3">\r\n  <c />\r\n</r>');
        Observer.Verify();
    end;





    [Test]
    procedure AddBeforeSelf_Attached_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTyped(Observer, 2, true);
        Observer.Expect('t1|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t1|code', 'Argument');
        Observer.Expect('t2|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t2|code', 'Argument');
        Observer.Expect('t3|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t3|code', 'Argument');
        Observer.Expect('t4|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t4|code', 'Argument');
        Observer.Expect('t5|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t5|code', 'Argument');
        Observer.Expect('t6', '<r p="1" ta="1" x="2" q="3">\r\n  <c />\r\n</r>');
        Observer.Expect('t7|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t7|code', 'Argument');
        Observer.Expect('t8|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t8|code', 'Argument');
        Observer.Expect('t9|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t9|code', 'Argument');
        Observer.Expect('t10|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t10|code', 'Argument');
        Observer.Expect('t11', '<r p="1" ta="1" tb="2" x="2" q="3">\r\n  <c />\r\n</r>');
        Observer.Expect('t12|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t12|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure AddBeforeSelf_Detached_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 2, false);
        Observer.Expect('k1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k1|code', 'InvalidOperation');
        Observer.Expect('k2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k2|code', 'InvalidOperation');
        Observer.Expect('k3|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k3|code', 'InvalidOperation');
        Observer.Expect('k4|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k4|code', 'InvalidOperation');
        Observer.Expect('k5|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k5|code', 'InvalidOperation');
        Observer.Expect('k6|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k6|code', 'InvalidOperation');
        Observer.Expect('k7|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k7|code', 'InvalidOperation');
        Observer.Expect('k8|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k8|code', 'InvalidOperation');
        Observer.Expect('k9|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k9|code', 'InvalidOperation');
        Observer.Expect('k10|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k10|code', 'InvalidOperation');
        Observer.Expect('k11|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k11|code', 'InvalidOperation');
        Observer.Expect('k12|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k12|code', 'InvalidOperation');
        Observer.Expect('k13|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k13|code', 'InvalidOperation');
        Observer.Expect('k14|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k14|code', 'InvalidOperation');
        Observer.Expect('k15|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k15|code', 'InvalidOperation');
        Observer.Expect('k16|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k16|code', 'InvalidOperation');
        Observer.Expect('k17|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k17|code', 'InvalidOperation');
        Observer.Expect('k18|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k18|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure AddBeforeSelf_Detached_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTyped(Observer, 2, false);
        Observer.Expect('t1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t1|code', 'InvalidOperation');
        Observer.Expect('t2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t2|code', 'InvalidOperation');
        Observer.Expect('t3|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t3|code', 'InvalidOperation');
        Observer.Expect('t4|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t4|code', 'InvalidOperation');
        Observer.Expect('t5|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t5|code', 'InvalidOperation');
        Observer.Expect('t6|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t6|code', 'InvalidOperation');
        Observer.Expect('t7|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t7|code', 'InvalidOperation');
        Observer.Expect('t8|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t8|code', 'InvalidOperation');
        Observer.Expect('t9|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t9|code', 'InvalidOperation');
        Observer.Expect('t10|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t10|code', 'InvalidOperation');
        Observer.Expect('t11|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t11|code', 'InvalidOperation');
        Observer.Expect('t12|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t12|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_Attached_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 3, true);
        Observer.Expect('k1|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k1|code', 'Argument');
        Observer.Expect('k2|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k2|code', 'Argument');
        Observer.Expect('k3|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k3|code', 'Argument');
        Observer.Expect('k4|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k4|code', 'Argument');
        Observer.Expect('k5|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k5|code', 'Argument');
        Observer.Expect('k6', '<r p="1" a6="1" q="3">\r\n  <c />\r\n</r>');
        Observer.Expect('k7|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k7|code', 'Argument');
        Observer.Expect('k8|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k8|code', 'Argument');
        Observer.Expect('k9|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k9|code', 'Argument');
        Observer.Expect('k10|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k10|code', 'InvalidOperation');
        Observer.Expect('k11|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k11|code', 'InvalidOperation');
        Observer.Expect('k12|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k12|code', 'Argument');
        Observer.Expect('k13|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('k13|code', 'Argument');
        Observer.Expect('k14|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('k14|code', 'NotInitialized');
        Observer.Expect('k15|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k15|code', 'InvalidOperation');
        Observer.Expect('k16', '<r p="1" xmlns:n16="urn:n16" q="3">\r\n  <c />\r\n</r>');
        Observer.Expect('k17', '<r p="1" p1:a17="v" q="3" xmlns:p1="urn:a17">\r\n  <c />\r\n</r>');
        Observer.Expect('k18', '<r p="1" a18="" q="3">\r\n  <c />\r\n</r>');
        Observer.Verify();
    end;





    [Test]
    procedure ReplaceWith_Attached_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTyped(Observer, 3, true);
        Observer.Expect('t1|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t1|code', 'Argument');
        Observer.Expect('t2|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t2|code', 'Argument');
        Observer.Expect('t3|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t3|code', 'Argument');
        Observer.Expect('t4|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t4|code', 'Argument');
        Observer.Expect('t5|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t5|code', 'Argument');
        Observer.Expect('t6', '<r p="1" ta="1" q="3">\r\n  <c />\r\n</r>');
        Observer.Expect('t7|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t7|code', 'Argument');
        Observer.Expect('t8|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t8|code', 'Argument');
        Observer.Expect('t9|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t9|code', 'Argument');
        Observer.Expect('t10|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t10|code', 'Argument');
        Observer.Expect('t11', '<r p="1" ta="1" tb="2" q="3">\r\n  <c />\r\n</r>');
        Observer.Expect('t12|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('t12|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_Detached_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 3, false);
        Observer.Expect('k1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k1|code', 'InvalidOperation');
        Observer.Expect('k2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k2|code', 'InvalidOperation');
        Observer.Expect('k3|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k3|code', 'InvalidOperation');
        Observer.Expect('k4|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k4|code', 'InvalidOperation');
        Observer.Expect('k5|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k5|code', 'InvalidOperation');
        Observer.Expect('k6|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k6|code', 'InvalidOperation');
        Observer.Expect('k7|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k7|code', 'InvalidOperation');
        Observer.Expect('k8|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k8|code', 'InvalidOperation');
        Observer.Expect('k9|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k9|code', 'InvalidOperation');
        Observer.Expect('k10|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k10|code', 'InvalidOperation');
        Observer.Expect('k11|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k11|code', 'InvalidOperation');
        Observer.Expect('k12|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k12|code', 'InvalidOperation');
        Observer.Expect('k13|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k13|code', 'InvalidOperation');
        Observer.Expect('k14|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k14|code', 'InvalidOperation');
        Observer.Expect('k15|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k15|code', 'InvalidOperation');
        Observer.Expect('k16|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k16|code', 'InvalidOperation');
        Observer.Expect('k17|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k17|code', 'InvalidOperation');
        Observer.Expect('k18|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k18|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_Detached_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTyped(Observer, 3, false);
        Observer.Expect('t1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t1|code', 'InvalidOperation');
        Observer.Expect('t2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t2|code', 'InvalidOperation');
        Observer.Expect('t3|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t3|code', 'InvalidOperation');
        Observer.Expect('t4|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t4|code', 'InvalidOperation');
        Observer.Expect('t5|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t5|code', 'InvalidOperation');
        Observer.Expect('t6|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t6|code', 'InvalidOperation');
        Observer.Expect('t7|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t7|code', 'InvalidOperation');
        Observer.Expect('t8|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t8|code', 'InvalidOperation');
        Observer.Expect('t9|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t9|code', 'InvalidOperation');
        Observer.Expect('t10|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t10|code', 'InvalidOperation');
        Observer.Expect('t11|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t11|code', 'InvalidOperation');
        Observer.Expect('t12|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('t12|code', 'InvalidOperation');
        Observer.Verify();
    end;
}
