// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlcdata/xmlcdata-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table LT P104 Blob where an OutStream is written
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlCData.Remove, GetParent, GetDocument and ReplaceWith
// BC versions: 29 (27 and 28 by CI)

codeunit 71804 "LT P104 Tree2 CData"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure MakeNode(var Nd: XmlCData; V: Integer)
    begin
        case V of
            1:
                Nd := XmlCData.Create('plain');
            2:
                Nd := XmlCData.Create('a<b>&"q" ]] x');
            3:
                Nd := XmlCData.Create('');
        end;
    end;

    local procedure BuildDoc(var Doc: XmlDocument; var Nd: XmlCData; V: Integer)
    var
        R: XmlElement;
    begin
        MakeNode(Nd, V);
        Doc := XmlDocument.Create();
        R := XmlElement.Create('r');
        R.Add(XmlElement.Create('a'));
        R.Add(Nd);
        R.Add(XmlElement.Create('b'));
        
        Doc.Add(R);
    end;

    local procedure Ser(var Doc: XmlDocument): Text
    var
        S: Text;
    begin
        Doc.WriteTo(S);
        exit(S);
    end;

    [TryFunction]
    local procedure TryReplace(var Nd: XmlCData; V: Integer)
    begin
        case V of
            1:
                Nd.ReplaceWith(XmlComment.Create('new'));
            2:
                Nd.ReplaceWith(XmlText.Create('txt'));
            3:
                Nd.ReplaceWith(XmlElement.Create('n'));
            4:
                Nd.ReplaceWith(XmlCData.Create('cd'));
            5:
                Nd.ReplaceWith(XmlProcessingInstruction.Create('pi', 'dat'));
            6:
                Nd.ReplaceWith(XmlElement.Create('n1'), XmlElement.Create('n2'));
            7:
                Nd.ReplaceWith('plain text');
            8:
                Nd.ReplaceWith(42);
            9:
                Nd.ReplaceWith(XmlAttribute.Create('at', 'v'));
            10:
                Nd.ReplaceWith(XmlDocument.Create());
            11:
                Nd.ReplaceWith(Nd);
            12:
                Nd.ReplaceWith(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
            13:
                Nd.ReplaceWith(XmlDocumentType.Create('d'));
            14:
                Nd.ReplaceWith(XmlComment.Create('c1'), XmlText.Create('t2'), XmlElement.Create('e3'));
            15:
                Nd.ReplaceWith('');
        end;
    end;

    [TryFunction]
    local procedure TryRemove(var Nd: XmlCData)
    begin
        Nd.Remove();
    end;

    [TryFunction]
    local procedure TryParent(var Nd: XmlCData; var Found: Boolean; var Name: Text)
    var
        P: XmlElement;
    begin
        Found := Nd.GetParent(P);
        if Found then
            Name := P.Name();
    end;

    [TryFunction]
    local procedure TryDocument(var Nd: XmlCData; var Found: Boolean; var Result: Text)
    var
        D: XmlDocument;
    begin
        Found := Nd.GetDocument(D);
        if Found then
            Result := Ser(D);
    end;

    local procedure Parent(var Observer: Codeunit "Probe Observer"; var Nd: XmlCData; Name: Text)
    var
        Found: Boolean;
        PName: Text;
    begin
        if TryParent(Nd, Found, PName) then
            Observer.Observe(Name, Format(Found) + ':' + PName)
        else
            Observer.ObserveError(Name);
    end;

    local procedure DocOf(var Observer: Codeunit "Probe Observer"; var Nd: XmlCData; Name: Text)
    var
        Found: Boolean;
        S: Text;
    begin
        if TryDocument(Nd, Found, S) then
            Observer.Observe(Name, Format(Found) + ':' + S)
        else
            Observer.ObserveError(Name);
    end;

    local procedure RemoveIt(var Observer: Codeunit "Probe Observer"; var Nd: XmlCData; Name: Text)
    begin
        if TryRemove(Nd) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure P104_Remove_InDoc()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Nd: XmlCData;
        S: Text;
        V: Integer;
    begin
        for V := 1 to 3 do begin
            BuildDoc(Doc, Nd, V);
            RemoveIt(Observer, Nd, 'rm' + Format(V));
            Observer.Observe('doc' + Format(V), Ser(Doc));
            Parent(Observer, Nd, 'parent' + Format(V));
            DocOf(Observer, Nd, 'document' + Format(V));
            Nd.WriteTo(S);
            Observer.Observe('node' + Format(V), S);
        end;
        Observer.Expect('rm1', 'ok');
        Observer.Expect('doc1', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('parent1', 'No:');
        Observer.Expect('document1', 'No:');
        Observer.Expect('node1', '<![CDATA[plain]]>');
        Observer.Expect('rm2', 'ok');
        Observer.Expect('doc2', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('parent2', 'No:');
        Observer.Expect('document2', 'No:');
        Observer.Expect('node2', '<![CDATA[a<b>&"q" ]] x]]>');
        Observer.Expect('rm3', 'ok');
        Observer.Expect('doc3', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('parent3', 'No:');
        Observer.Expect('document3', 'No:');
        Observer.Expect('node3', '<![CDATA[]]>');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Remove_Twice_And_Detached()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Nd: XmlCData;
    begin
        BuildDoc(Doc, Nd, 1);
        RemoveIt(Observer, Nd, 'first');
        RemoveIt(Observer, Nd, 'second');
        Observer.Observe('doc', Ser(Doc));
        MakeNode(Nd, 1);
        RemoveIt(Observer, Nd, 'detached');
        Parent(Observer, Nd, 'detached_parent');
        DocOf(Observer, Nd, 'detached_doc');
        Observer.Expect('first', 'ok');
        Observer.Expect('second|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('second|code', 'InvalidOperation');
        Observer.Expect('doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Expect('detached|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('detached|code', 'InvalidOperation');
        Observer.Expect('detached_parent', 'No:');
        Observer.Expect('detached_doc', 'No:');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Remove_Uninitialised()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlCData;
    begin
        RemoveIt(Observer, Nd, 'rm');
        Parent(Observer, Nd, 'parent');
        DocOf(Observer, Nd, 'doc');
        Observer.Expect('rm|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('rm|code', 'NotInitialized');
        Observer.Expect('parent|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('parent|code', 'NotInitialized');
        Observer.Expect('doc|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('doc|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure P104_GetParent_GetDocument()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Nd: XmlCData;
        V: Integer;
    begin
        MakeNode(Nd, 1);
        Parent(Observer, Nd, 'detached_parent');
        DocOf(Observer, Nd, 'detached_doc');
        for V := 1 to 3 do begin
            BuildDoc(Doc, Nd, V);
            Parent(Observer, Nd, 'parent' + Format(V));
            DocOf(Observer, Nd, 'doc' + Format(V));
        end;
        Observer.Expect('detached_parent', 'No:');
        Observer.Expect('detached_doc', 'No:');
        Observer.Expect('parent1', 'Yes:r');
        Observer.Expect('doc1', 'Yes:<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[plain]]><b /></r>');
        Observer.Expect('parent2', 'Yes:r');
        Observer.Expect('doc2', 'Yes:<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[a<b>&"q" ]] x]]><b /></r>');
        Observer.Expect('parent3', 'Yes:r');
        Observer.Expect('doc3', 'Yes:<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[]]><b /></r>');
        Observer.Verify();
    end;

    [Test]
    procedure P104_GetParent_DocumentLevel()
    var
        Observer: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Nd: XmlCData;
        Same: Boolean;
        S1: Text;
        S2: Text;
        D: XmlDocument;
    begin
        BuildDoc(Doc, Nd, 1);
        if Nd.GetDocument(D) then begin
            D.WriteTo(S2);
            Doc.WriteTo(S1);
            Same := S1 = S2;
        end;
        Observer.Observe('same_doc', Format(Same));
        Observer.Expect('same_doc', 'Yes');
        Observer.Verify();
    end;

    local procedure RunReplace(var Observer: Codeunit "Probe Observer"; Name: Text; Variant: Integer; Content: Integer)
    var
        Doc: XmlDocument;
        Nd: XmlCData;
    begin
        BuildDoc(Doc, Nd, Variant);
        if TryReplace(Nd, Content) then
            Observer.Observe(Name, Ser(Doc))
        else
            Observer.ObserveError(Name);
    end;

    local procedure RunReplaceDetached(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Integer)
    var
        Nd: XmlCData;
        S: Text;
    begin
        MakeNode(Nd, 1);
        if TryReplace(Nd, Content) then begin
            Nd.WriteTo(S);
            Observer.Observe(Name, 'ok:' + S);
        end else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure P104_ReplaceWith_Contents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunReplace(Observer, 'c1', 1, 1);
        RunReplace(Observer, 'c2', 1, 2);
        RunReplace(Observer, 'c3', 1, 3);
        RunReplace(Observer, 'c4', 1, 4);
        RunReplace(Observer, 'c5', 1, 5);
        RunReplace(Observer, 'c6', 1, 6);
        RunReplace(Observer, 'c7', 1, 7);
        RunReplace(Observer, 'c8', 1, 8);
        RunReplace(Observer, 'c9', 1, 9);
        RunReplace(Observer, 'c10', 1, 10);
        RunReplace(Observer, 'c11', 1, 11);
        RunReplace(Observer, 'c12', 1, 12);
        RunReplace(Observer, 'c13', 1, 13);
        RunReplace(Observer, 'c14', 1, 14);
        RunReplace(Observer, 'c15', 1, 15);
        Observer.Expect('c1', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--new-->\r\n  <b />\r\n</r>');
        Observer.Expect('c2', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />txt<b /></r>');
        Observer.Expect('c3', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <n />\r\n  <b />\r\n</r>');
        Observer.Expect('c4', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[cd]]><b /></r>');
        Observer.Expect('c5', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?pi dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('c6', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <n1 />\r\n  <n2 />\r\n  <b />\r\n</r>');
        Observer.Expect('c7', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />plain text<b /></r>');
        Observer.Expect('c8', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />42<b /></r>');
        Observer.Expect('c9|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('c9|code', 'Argument');
        Observer.Expect('c10|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('c10|code', 'Argument');
        Observer.Expect('c11', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[plain]]><b /></r>');
        Observer.Expect('c12', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />&lt;?xml version="1.0" encoding="utf-8" standalone="yes"?&gt;<b /></r>');
        Observer.Expect('c13|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('c13|code', 'Argument');
        Observer.Expect('c14', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--c1-->t2<e3 /><b /></r>');
        Observer.Expect('c15', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure P104_ReplaceWith_OtherValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunReplace(Observer, 'v2c1', 2, 1);
        RunReplace(Observer, 'v3c1', 3, 1);
        RunReplace(Observer, 'v2c2', 2, 2);
        RunReplace(Observer, 'v3c2', 3, 2);
        RunReplace(Observer, 'v2c6', 2, 6);
        RunReplace(Observer, 'v3c6', 3, 6);
        RunReplace(Observer, 'v2c7', 2, 7);
        RunReplace(Observer, 'v3c7', 3, 7);
        RunReplace(Observer, 'v2c11', 2, 11);
        RunReplace(Observer, 'v3c11', 3, 11);
        Observer.Expect('v2c1', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--new-->\r\n  <b />\r\n</r>');
        Observer.Expect('v3c1', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--new-->\r\n  <b />\r\n</r>');
        Observer.Expect('v2c2', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />txt<b /></r>');
        Observer.Expect('v3c2', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />txt<b /></r>');
        Observer.Expect('v2c6', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <n1 />\r\n  <n2 />\r\n  <b />\r\n</r>');
        Observer.Expect('v3c6', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <n1 />\r\n  <n2 />\r\n  <b />\r\n</r>');
        Observer.Expect('v2c7', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />plain text<b /></r>');
        Observer.Expect('v3c7', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />plain text<b /></r>');
        Observer.Expect('v2c11', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[a<b>&"q" ]] x]]><b /></r>');
        Observer.Expect('v3c11', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[]]><b /></r>');
        Observer.Verify();
    end;

    [Test]
    procedure P104_ReplaceWith_Detached()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunReplaceDetached(Observer, 'd1', 1);
        RunReplaceDetached(Observer, 'd2', 2);
        RunReplaceDetached(Observer, 'd3', 3);
        RunReplaceDetached(Observer, 'd6', 6);
        RunReplaceDetached(Observer, 'd7', 7);
        RunReplaceDetached(Observer, 'd11', 11);
        RunReplaceDetached(Observer, 'd12', 12);
        RunReplaceDetached(Observer, 'd13', 13);
        Observer.Expect('d1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d1|code', 'InvalidOperation');
        Observer.Expect('d2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d2|code', 'InvalidOperation');
        Observer.Expect('d3|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d3|code', 'InvalidOperation');
        Observer.Expect('d6|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d6|code', 'InvalidOperation');
        Observer.Expect('d7|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d7|code', 'InvalidOperation');
        Observer.Expect('d11|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d11|code', 'InvalidOperation');
        Observer.Expect('d12|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d12|code', 'InvalidOperation');
        Observer.Expect('d13|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d13|code', 'InvalidOperation');
        Observer.Verify();
    end;
}
