// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDocument AddAfterSelf, AddBeforeSelf, ReplaceWith with every node kind as argument on documents with and without a root, and the serialized document after each change
// BC versions: 29 (27 and 28 by CI)

codeunit 74802 "LT P97 Doc Edit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Doc: XmlDocument;
        Root: XmlElement;

    // Variant: 1 <r /> only, 2 empty document, 3 declaration + comment + root r with a child
    local procedure Build(Variant: Integer)
    begin
        Doc := XmlDocument.Create();
        Root := XmlElement.Create('r');
        case Variant of
            1:
                Doc.Add(Root);
            3:
                begin
                    Doc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
                    Doc.Add(XmlComment.Create('lead'));
                    Root.Add(XmlElement.Create('c'));
                    Doc.Add(Root);
                end;
        end;
        if Variant <> 2 then
            Doc.GetRoot(Root);
    end;

    local procedure State(): Text
    var
        S: Text;
    begin
        Doc.WriteTo(S);
        exit(S);
    end;

    // Kinds: 1 element, 2 text, 3 comment, 4 cdata, 5 processing instruction, 6 new attribute, 7 declaration, 8 empty document,
    // 9 document type, 10 the subject itself, 11 the root element of the subject (when it has one), 12 the root r (same as 11 for variants 1 and 3), 13 node attached to another document,
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
                exit(Doc.AsXmlNode());
            11:
                begin
                    if Doc.GetRoot(E) then;
                    exit(E.AsXmlNode());
                end;
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
                Doc.AddAfterSelf(MakeArg(Kind));
            2:
                Doc.AddBeforeSelf(MakeArg(Kind));
            3:
                Doc.ReplaceWith(MakeArg(Kind));
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
        case Kind of
            1:
                case Op of
                    1:
                        Doc.AddAfterSelf(E);
                    2:
                        Doc.AddBeforeSelf(E);
                    3:
                        Doc.ReplaceWith(E);
                end;
            2:
                case Op of
                    1:
                        Doc.AddAfterSelf(T);
                    2:
                        Doc.AddBeforeSelf(T);
                    3:
                        Doc.ReplaceWith(T);
                end;
            3:
                case Op of
                    1:
                        Doc.AddAfterSelf(C);
                    2:
                        Doc.AddBeforeSelf(C);
                    3:
                        Doc.ReplaceWith(C);
                end;
            4:
                case Op of
                    1:
                        Doc.AddAfterSelf(D);
                    2:
                        Doc.AddBeforeSelf(D);
                    3:
                        Doc.ReplaceWith(D);
                end;
            5:
                case Op of
                    1:
                        Doc.AddAfterSelf(P);
                    2:
                        Doc.AddBeforeSelf(P);
                    3:
                        Doc.ReplaceWith(P);
                end;
            6:
                case Op of
                    1:
                        Doc.AddAfterSelf(A);
                    2:
                        Doc.AddBeforeSelf(A);
                    3:
                        Doc.ReplaceWith(A);
                end;
            7:
                case Op of
                    1:
                        Doc.AddAfterSelf(Decl);
                    2:
                        Doc.AddBeforeSelf(Decl);
                    3:
                        Doc.ReplaceWith(Decl);
                end;
            8:
                case Op of
                    1:
                        Doc.AddAfterSelf(Doc2);
                    2:
                        Doc.AddBeforeSelf(Doc2);
                    3:
                        Doc.ReplaceWith(Doc2);
                end;
            9:
                case Op of
                    1:
                        Doc.AddAfterSelf('plain text');
                    2:
                        Doc.AddBeforeSelf('plain text');
                    3:
                        Doc.ReplaceWith('plain text');
                end;
            10:
                case Op of
                    1:
                        Doc.AddAfterSelf(Num);
                    2:
                        Doc.AddBeforeSelf(Num);
                    3:
                        Doc.ReplaceWith(Num);
                end;
            11:
                case Op of
                    1:
                        Doc.AddAfterSelf(E, T);
                    2:
                        Doc.AddBeforeSelf(E, T);
                    3:
                        Doc.ReplaceWith(E, T);
                end;
        end;
    end;

    local procedure RunKinds(var Observer: Codeunit "Probe Observer"; Op: Integer; Variant: Integer)
    var
        Kind: Integer;
        S: Text;
    begin
        for Kind := 1 to 18 do begin
            Build(Variant);
            S := '';
            if TryRun(Op, Kind, S) then
                Observer.Observe('k' + Format(Kind), S)
            else
                Observer.ObserveError('k' + Format(Kind));
        end;
    end;

    local procedure RunTyped(var Observer: Codeunit "Probe Observer"; Op: Integer; Variant: Integer)
    var
        Kind: Integer;
        S: Text;
    begin
        for Kind := 1 to 11 do begin
            Build(Variant);
            S := '';
            if TryTyped(Op, Kind, S) then
                Observer.Observe('t' + Format(Kind), S)
            else
                Observer.ObserveError('t' + Format(Kind));
        end;
    end;

    [Test]
    procedure AddAfterSelf_RootOnly_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 1, 1);
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
        Observer.Expect('k14|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('k14|code', 'NotInitialized');
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
    procedure AddAfterSelf_Empty_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 1, 2);
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
        Observer.Expect('k11|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.');
        Observer.Expect('k11|code', 'NotInitialized');
        Observer.Expect('k12|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k12|code', 'InvalidOperation');
        Observer.Expect('k13|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k13|code', 'InvalidOperation');
        Observer.Expect('k14|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('k14|code', 'NotInitialized');
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
    procedure AddAfterSelf_Full_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 1, 3);
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
        Observer.Expect('k14|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('k14|code', 'NotInitialized');
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
    procedure AddAfterSelf_RootOnly_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTyped(Observer, 1, 1);
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
        Observer.Verify();
    end;

    [Test]
    procedure AddBeforeSelf_RootOnly_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 2, 1);
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
        Observer.Expect('k14|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('k14|code', 'NotInitialized');
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
    procedure AddBeforeSelf_Empty_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 2, 2);
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
        Observer.Expect('k11|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.');
        Observer.Expect('k11|code', 'NotInitialized');
        Observer.Expect('k12|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k12|code', 'InvalidOperation');
        Observer.Expect('k13|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k13|code', 'InvalidOperation');
        Observer.Expect('k14|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('k14|code', 'NotInitialized');
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
    procedure AddBeforeSelf_Full_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 2, 3);
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
        Observer.Expect('k14|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('k14|code', 'NotInitialized');
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
    procedure AddBeforeSelf_RootOnly_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTyped(Observer, 2, 1);
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
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_RootOnly_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 3, 1);
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
        Observer.Expect('k14|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('k14|code', 'NotInitialized');
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
    procedure ReplaceWith_Empty_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 3, 2);
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
        Observer.Expect('k11|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.');
        Observer.Expect('k11|code', 'NotInitialized');
        Observer.Expect('k12|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k12|code', 'InvalidOperation');
        Observer.Expect('k13|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('k13|code', 'InvalidOperation');
        Observer.Expect('k14|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('k14|code', 'NotInitialized');
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
    procedure ReplaceWith_Full_Kinds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunKinds(Observer, 3, 3);
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
        Observer.Expect('k14|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('k14|code', 'NotInitialized');
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
    procedure ReplaceWith_RootOnly_Typed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunTyped(Observer, 3, 1);
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
        Observer.Verify();
    end;
}
