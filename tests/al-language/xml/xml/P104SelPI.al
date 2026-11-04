// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlprocessinginstruction/xmlprocessinginstruction-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table LT P104 Blob where an OutStream is written
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlProcessingInstruction.SelectNodes and SelectSingleNode, each overload, with and without XmlNamespaceManager, detached and inside a document
// BC versions: 29 (27 and 28 by CI)

codeunit 71809 "LT P104 Sel PI"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure MakeNode(var Nd: XmlProcessingInstruction; V: Integer)
    begin
        case V of
            1:
                Nd := XmlProcessingInstruction.Create('tgt', 'dat');
            2:
                Nd := XmlProcessingInstruction.Create('tgt', 'a<b>&"q"');
            3:
                Nd := XmlProcessingInstruction.Create('tgt', '');
        end;
    end;

    local procedure BuildDoc(var Doc: XmlDocument; var Nd: XmlProcessingInstruction; V: Integer)
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

    local procedure BuildDocNs(var Doc: XmlDocument; var Nd: XmlProcessingInstruction)
    var
        R: XmlElement;
    begin
        MakeNode(Nd, 1);
        Doc := XmlDocument.Create();
        R := XmlElement.Create('r', 'urn:a');
        R.Add(XmlElement.Create('c', 'urn:a'));
        R.Add(Nd);
        R.Add(XmlElement.Create('x', 'urn:b'));
        
        Doc.Add(R);
    end;

    local procedure Dump(var NL: XmlNodeList): Text
    var
        N: XmlNode;
        One: Text;
        S: Text;
    begin
        foreach N in NL do begin
            N.WriteTo(One);
            S += '[' + One + ']';
        end;
        exit(Format(NL.Count()) + S);
    end;

    [TryFunction]
    local procedure TryNodes(var Nd: XmlProcessingInstruction; XPath: Text; var Result: Text)
    var
        NL: XmlNodeList;
        Found: Boolean;
    begin
        Found := Nd.SelectNodes(XPath, NL);
        Result := Format(Found) + ':' + Dump(NL);
    end;

    [TryFunction]
    local procedure TrySingle(var Nd: XmlProcessingInstruction; XPath: Text; var Result: Text)
    var
        N: XmlNode;
        One: Text;
        Found: Boolean;
    begin
        Found := Nd.SelectSingleNode(XPath, N);
        if Found then
            N.WriteTo(One);
        Result := Format(Found) + ':' + One;
    end;

    [TryFunction]
    local procedure TryNodesNs(var Nd: XmlProcessingInstruction; XPath: Text; var Mgr: XmlNamespaceManager; var Result: Text)
    var
        NL: XmlNodeList;
        Found: Boolean;
    begin
        Found := Nd.SelectNodes(XPath, Mgr, NL);
        Result := Format(Found) + ':' + Dump(NL);
    end;

    [TryFunction]
    local procedure TrySingleNs(var Nd: XmlProcessingInstruction; XPath: Text; var Mgr: XmlNamespaceManager; var Result: Text)
    var
        N: XmlNode;
        One: Text;
        Found: Boolean;
    begin
        Found := Nd.SelectSingleNode(XPath, Mgr, N);
        if Found then
            N.WriteTo(One);
        Result := Format(Found) + ':' + One;
    end;

    local procedure RunNodes(var Observer: Codeunit "Probe Observer"; var Nd: XmlProcessingInstruction; Name: Text; XPath: Text)
    var
        R: Text;
    begin
        if TryNodes(Nd, XPath, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    local procedure RunSingle(var Observer: Codeunit "Probe Observer"; var Nd: XmlProcessingInstruction; Name: Text; XPath: Text)
    var
        R: Text;
    begin
        if TrySingle(Nd, XPath, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    local procedure RunNodesNs(var Observer: Codeunit "Probe Observer"; var Nd: XmlProcessingInstruction; var Mgr: XmlNamespaceManager; Name: Text; XPath: Text)
    var
        R: Text;
    begin
        if TryNodesNs(Nd, XPath, Mgr, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    local procedure RunSingleNs(var Observer: Codeunit "Probe Observer"; var Nd: XmlProcessingInstruction; var Mgr: XmlNamespaceManager; Name: Text; XPath: Text)
    var
        R: Text;
    begin
        if TrySingleNs(Nd, XPath, Mgr, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure P104_Nodes_Detached()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
    begin
        MakeNode(Nd, 1);
        RunNodes(Observer, Nd, 'x1', '.');
        RunNodes(Observer, Nd, 'x2', '..');
        RunNodes(Observer, Nd, 'x3', '/');
        RunNodes(Observer, Nd, 'x4', '//*');
        RunNodes(Observer, Nd, 'x5', 'node()');
        RunNodes(Observer, Nd, 'x6', 'text()');
        RunNodes(Observer, Nd, 'x7', 'self::node()');
        RunNodes(Observer, Nd, 'x8', 'parent::*');
        RunNodes(Observer, Nd, 'x9', 'ancestor::*');
        RunNodes(Observer, Nd, 'x10', 'following-sibling::*');
        RunNodes(Observer, Nd, 'x11', 'count(.)');
        RunNodes(Observer, Nd, 'x12', '');
        RunNodes(Observer, Nd, 'x13', '[');
        RunNodes(Observer, Nd, 'x14', 'a b');
        RunNodes(Observer, Nd, 'x15', '@x');
        Observer.Expect('x1', 'Yes:1[<?tgt dat?>]');
        Observer.Expect('x2', 'Yes:0');
        Observer.Expect('x3', 'Yes:1[<?tgt dat?>]');
        Observer.Expect('x4', 'Yes:0');
        Observer.Expect('x5', 'Yes:0');
        Observer.Expect('x6', 'Yes:0');
        Observer.Expect('x7', 'Yes:1[<?tgt dat?>]');
        Observer.Expect('x8', 'Yes:0');
        Observer.Expect('x9', 'Yes:0');
        Observer.Expect('x10', 'Yes:0');
        Observer.Expect('x11', 'Yes:0');
        Observer.Expect('x12', 'No:0');
        Observer.Expect('x13', 'No:0');
        Observer.Expect('x14', 'No:0');
        Observer.Expect('x15', 'Yes:0');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Nodes_Detached_Variant2()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
    begin
        MakeNode(Nd, 2);
        RunNodes(Observer, Nd, 'x1', '.');
        RunNodes(Observer, Nd, 'x2', '..');
        RunNodes(Observer, Nd, 'x3', '/');
        RunNodes(Observer, Nd, 'x4', '//*');
        RunNodes(Observer, Nd, 'x5', 'node()');
        RunNodes(Observer, Nd, 'x6', 'text()');
        RunNodes(Observer, Nd, 'x7', 'self::node()');
        RunNodes(Observer, Nd, 'x8', 'parent::*');
        RunNodes(Observer, Nd, 'x9', 'count(.)');
        Observer.Expect('x1', 'Yes:1[<?tgt a<b>&"q"?>]');
        Observer.Expect('x2', 'Yes:0');
        Observer.Expect('x3', 'Yes:1[<?tgt a<b>&"q"?>]');
        Observer.Expect('x4', 'Yes:0');
        Observer.Expect('x5', 'Yes:0');
        Observer.Expect('x6', 'Yes:0');
        Observer.Expect('x7', 'Yes:1[<?tgt a<b>&"q"?>]');
        Observer.Expect('x8', 'Yes:0');
        Observer.Expect('x9', 'Yes:0');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Nodes_Detached_Variant3()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
    begin
        MakeNode(Nd, 3);
        RunNodes(Observer, Nd, 'x1', '.');
        RunNodes(Observer, Nd, 'x2', '..');
        RunNodes(Observer, Nd, 'x3', '/');
        RunNodes(Observer, Nd, 'x4', '//*');
        RunNodes(Observer, Nd, 'x5', 'node()');
        RunNodes(Observer, Nd, 'x6', 'text()');
        RunNodes(Observer, Nd, 'x7', 'self::node()');
        RunNodes(Observer, Nd, 'x8', 'parent::*');
        RunNodes(Observer, Nd, 'x9', 'count(.)');
        Observer.Expect('x1', 'Yes:1[<?tgt?>]');
        Observer.Expect('x2', 'Yes:0');
        Observer.Expect('x3', 'Yes:1[<?tgt?>]');
        Observer.Expect('x4', 'Yes:0');
        Observer.Expect('x5', 'Yes:0');
        Observer.Expect('x6', 'Yes:0');
        Observer.Expect('x7', 'Yes:1[<?tgt?>]');
        Observer.Expect('x8', 'Yes:0');
        Observer.Expect('x9', 'Yes:0');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Nodes_InDoc()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
        Doc: XmlDocument;
    begin
        BuildDoc(Doc, Nd, 1);
        RunNodes(Observer, Nd, 'x1', '.');
        RunNodes(Observer, Nd, 'x2', '..');
        RunNodes(Observer, Nd, 'x3', 'preceding-sibling::*');
        RunNodes(Observer, Nd, 'x4', 'following-sibling::*');
        RunNodes(Observer, Nd, 'x5', '/r/*');
        RunNodes(Observer, Nd, 'x6', '/r');
        RunNodes(Observer, Nd, 'x7', '//*');
        RunNodes(Observer, Nd, 'x8', 'self::node()');
        RunNodes(Observer, Nd, 'x9', 'ancestor::*');
        RunNodes(Observer, Nd, 'x10', 'parent::r');
        RunNodes(Observer, Nd, 'x11', '/r/a/following-sibling::node()');
        RunNodes(Observer, Nd, 'x12', 'text()');
        RunNodes(Observer, Nd, 'x13', 'comment()');
        RunNodes(Observer, Nd, 'x14', 'processing-instruction()');
        RunNodes(Observer, Nd, 'x15', 'node()');
        Observer.Expect('x1', 'Yes:1[<?tgt dat?>]');
        Observer.Expect('x2', 'Yes:1[<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>]');
        Observer.Expect('x3', 'Yes:1[<a />]');
        Observer.Expect('x4', 'Yes:1[<b />]');
        Observer.Expect('x5', 'Yes:2[<a />][<b />]');
        Observer.Expect('x6', 'Yes:1[<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>]');
        Observer.Expect('x7', 'Yes:3[<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>][<a />][<b />]');
        Observer.Expect('x8', 'Yes:1[<?tgt dat?>]');
        Observer.Expect('x9', 'Yes:1[<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>]');
        Observer.Expect('x10', 'Yes:1[<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>]');
        Observer.Expect('x11', 'Yes:2[<?tgt dat?>][<b />]');
        Observer.Expect('x12', 'Yes:0');
        Observer.Expect('x13', 'Yes:0');
        Observer.Expect('x14', 'Yes:0');
        Observer.Expect('x15', 'Yes:0');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Nodes_InDoc_Variant2()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
        Doc: XmlDocument;
    begin
        BuildDoc(Doc, Nd, 2);
        RunNodes(Observer, Nd, 'x1', '.');
        RunNodes(Observer, Nd, 'x2', '..');
        RunNodes(Observer, Nd, 'x3', 'preceding-sibling::*');
        RunNodes(Observer, Nd, 'x4', 'following-sibling::*');
        RunNodes(Observer, Nd, 'x5', '/r/*');
        RunNodes(Observer, Nd, 'x6', '/r');
        RunNodes(Observer, Nd, 'x7', '//*');
        RunNodes(Observer, Nd, 'x8', 'self::node()');
        RunNodes(Observer, Nd, 'x9', 'ancestor::*');
        Observer.Expect('x1', 'Yes:1[<?tgt a<b>&"q"?>]');
        Observer.Expect('x2', 'Yes:1[<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>]');
        Observer.Expect('x3', 'Yes:1[<a />]');
        Observer.Expect('x4', 'Yes:1[<b />]');
        Observer.Expect('x5', 'Yes:2[<a />][<b />]');
        Observer.Expect('x6', 'Yes:1[<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>]');
        Observer.Expect('x7', 'Yes:3[<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>][<a />][<b />]');
        Observer.Expect('x8', 'Yes:1[<?tgt a<b>&"q"?>]');
        Observer.Expect('x9', 'Yes:1[<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>]');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Single_Detached()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
    begin
        MakeNode(Nd, 1);
        RunSingle(Observer, Nd, 'x1', '.');
        RunSingle(Observer, Nd, 'x2', '..');
        RunSingle(Observer, Nd, 'x3', '/');
        RunSingle(Observer, Nd, 'x4', '//*');
        RunSingle(Observer, Nd, 'x5', 'node()');
        RunSingle(Observer, Nd, 'x6', 'text()');
        RunSingle(Observer, Nd, 'x7', 'self::node()');
        RunSingle(Observer, Nd, 'x8', 'parent::*');
        RunSingle(Observer, Nd, 'x9', 'ancestor::*');
        RunSingle(Observer, Nd, 'x10', 'following-sibling::*');
        RunSingle(Observer, Nd, 'x11', 'count(.)');
        RunSingle(Observer, Nd, 'x12', '');
        RunSingle(Observer, Nd, 'x13', '[');
        RunSingle(Observer, Nd, 'x14', 'a b');
        RunSingle(Observer, Nd, 'x15', '@x');
        Observer.Expect('x1', 'Yes:<?tgt dat?>');
        Observer.Expect('x2', 'No:');
        Observer.Expect('x3', 'Yes:<?tgt dat?>');
        Observer.Expect('x4', 'No:');
        Observer.Expect('x5', 'No:');
        Observer.Expect('x6', 'No:');
        Observer.Expect('x7', 'Yes:<?tgt dat?>');
        Observer.Expect('x8', 'No:');
        Observer.Expect('x9', 'No:');
        Observer.Expect('x10', 'No:');
        Observer.Expect('x11', 'No:');
        Observer.Expect('x12', 'No:');
        Observer.Expect('x13', 'No:');
        Observer.Expect('x14', 'No:');
        Observer.Expect('x15', 'No:');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Single_Detached_Variant2()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
    begin
        MakeNode(Nd, 2);
        RunSingle(Observer, Nd, 'x1', '.');
        RunSingle(Observer, Nd, 'x2', '..');
        RunSingle(Observer, Nd, 'x3', '/');
        RunSingle(Observer, Nd, 'x4', '//*');
        RunSingle(Observer, Nd, 'x5', 'node()');
        RunSingle(Observer, Nd, 'x6', 'text()');
        RunSingle(Observer, Nd, 'x7', 'self::node()');
        RunSingle(Observer, Nd, 'x8', 'parent::*');
        RunSingle(Observer, Nd, 'x9', 'count(.)');
        Observer.Expect('x1', 'Yes:<?tgt a<b>&"q"?>');
        Observer.Expect('x2', 'No:');
        Observer.Expect('x3', 'Yes:<?tgt a<b>&"q"?>');
        Observer.Expect('x4', 'No:');
        Observer.Expect('x5', 'No:');
        Observer.Expect('x6', 'No:');
        Observer.Expect('x7', 'Yes:<?tgt a<b>&"q"?>');
        Observer.Expect('x8', 'No:');
        Observer.Expect('x9', 'No:');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Single_Detached_Variant3()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
    begin
        MakeNode(Nd, 3);
        RunSingle(Observer, Nd, 'x1', '.');
        RunSingle(Observer, Nd, 'x2', '..');
        RunSingle(Observer, Nd, 'x3', '/');
        RunSingle(Observer, Nd, 'x4', '//*');
        RunSingle(Observer, Nd, 'x5', 'node()');
        RunSingle(Observer, Nd, 'x6', 'text()');
        RunSingle(Observer, Nd, 'x7', 'self::node()');
        RunSingle(Observer, Nd, 'x8', 'parent::*');
        RunSingle(Observer, Nd, 'x9', 'count(.)');
        Observer.Expect('x1', 'Yes:<?tgt?>');
        Observer.Expect('x2', 'No:');
        Observer.Expect('x3', 'Yes:<?tgt?>');
        Observer.Expect('x4', 'No:');
        Observer.Expect('x5', 'No:');
        Observer.Expect('x6', 'No:');
        Observer.Expect('x7', 'Yes:<?tgt?>');
        Observer.Expect('x8', 'No:');
        Observer.Expect('x9', 'No:');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Single_InDoc()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
        Doc: XmlDocument;
    begin
        BuildDoc(Doc, Nd, 1);
        RunSingle(Observer, Nd, 'x1', '.');
        RunSingle(Observer, Nd, 'x2', '..');
        RunSingle(Observer, Nd, 'x3', 'preceding-sibling::*');
        RunSingle(Observer, Nd, 'x4', 'following-sibling::*');
        RunSingle(Observer, Nd, 'x5', '/r/*');
        RunSingle(Observer, Nd, 'x6', '/r');
        RunSingle(Observer, Nd, 'x7', '//*');
        RunSingle(Observer, Nd, 'x8', 'self::node()');
        RunSingle(Observer, Nd, 'x9', 'ancestor::*');
        RunSingle(Observer, Nd, 'x10', 'parent::r');
        RunSingle(Observer, Nd, 'x11', '/r/a/following-sibling::node()');
        RunSingle(Observer, Nd, 'x12', 'text()');
        RunSingle(Observer, Nd, 'x13', 'comment()');
        RunSingle(Observer, Nd, 'x14', 'processing-instruction()');
        RunSingle(Observer, Nd, 'x15', 'node()');
        Observer.Expect('x1', 'Yes:<?tgt dat?>');
        Observer.Expect('x2', 'Yes:<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('x3', 'Yes:<a />');
        Observer.Expect('x4', 'Yes:<b />');
        Observer.Expect('x5', 'Yes:<a />');
        Observer.Expect('x6', 'Yes:<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('x7', 'Yes:<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('x8', 'Yes:<?tgt dat?>');
        Observer.Expect('x9', 'Yes:<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('x10', 'Yes:<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('x11', 'Yes:<?tgt dat?>');
        Observer.Expect('x12', 'No:');
        Observer.Expect('x13', 'No:');
        Observer.Expect('x14', 'No:');
        Observer.Expect('x15', 'No:');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Single_InDoc_Variant2()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
        Doc: XmlDocument;
    begin
        BuildDoc(Doc, Nd, 2);
        RunSingle(Observer, Nd, 'x1', '.');
        RunSingle(Observer, Nd, 'x2', '..');
        RunSingle(Observer, Nd, 'x3', 'preceding-sibling::*');
        RunSingle(Observer, Nd, 'x4', 'following-sibling::*');
        RunSingle(Observer, Nd, 'x5', '/r/*');
        RunSingle(Observer, Nd, 'x6', '/r');
        RunSingle(Observer, Nd, 'x7', '//*');
        RunSingle(Observer, Nd, 'x8', 'self::node()');
        RunSingle(Observer, Nd, 'x9', 'ancestor::*');
        Observer.Expect('x1', 'Yes:<?tgt a<b>&"q"?>');
        Observer.Expect('x2', 'Yes:<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>');
        Observer.Expect('x3', 'Yes:<a />');
        Observer.Expect('x4', 'Yes:<b />');
        Observer.Expect('x5', 'Yes:<a />');
        Observer.Expect('x6', 'Yes:<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>');
        Observer.Expect('x7', 'Yes:<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>');
        Observer.Expect('x8', 'Yes:<?tgt a<b>&"q"?>');
        Observer.Expect('x9', 'Yes:<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Nodes_WithManager()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
        Doc: XmlDocument;
        Mgr: XmlNamespaceManager;
    begin
        BuildDocNs(Doc, Nd);
        Mgr.AddNamespace('a', 'urn:a');
        Mgr.AddNamespace('b', 'urn:b');
        RunNodesNs(Observer, Nd, Mgr, 'x1', '/a:r');
        RunNodesNs(Observer, Nd, Mgr, 'x2', '/a:r/a:c');
        RunNodesNs(Observer, Nd, Mgr, 'x3', '//b:x');
        RunNodesNs(Observer, Nd, Mgr, 'x4', 'preceding-sibling::a:c');
        RunNodesNs(Observer, Nd, Mgr, 'x5', '../a:c');
        RunNodesNs(Observer, Nd, Mgr, 'x6', '/a:r/*');
        RunNodesNs(Observer, Nd, Mgr, 'x7', 'following-sibling::b:x');
        RunNodesNs(Observer, Nd, Mgr, 'x8', 'a:c');
        RunNodesNs(Observer, Nd, Mgr, 'x9', 'zz:r');
        RunNodesNs(Observer, Nd, Mgr, 'x10', '/r');
        RunNodesNs(Observer, Nd, Mgr, 'x11', '/*[local-name()="r"]');
        RunNodesNs(Observer, Nd, Mgr, 'x12', '..');
        RunNodesNs(Observer, Nd, Mgr, 'x13', '.');
        Observer.Expect('x1', 'Yes:1[<r xmlns="urn:a">\r\n  <c />\r\n  <?tgt dat?>\r\n  <x xmlns="urn:b" />\r\n</r>]');
        Observer.Expect('x2', 'Yes:1[<c xmlns="urn:a" />]');
        Observer.Expect('x3', 'Yes:1[<x xmlns="urn:b" />]');
        Observer.Expect('x4', 'Yes:1[<c xmlns="urn:a" />]');
        Observer.Expect('x5', 'Yes:1[<c xmlns="urn:a" />]');
        Observer.Expect('x6', 'Yes:2[<c xmlns="urn:a" />][<x xmlns="urn:b" />]');
        Observer.Expect('x7', 'Yes:1[<x xmlns="urn:b" />]');
        Observer.Expect('x8', 'Yes:0');
        Observer.Expect('x9', 'No:0');
        Observer.Expect('x10', 'Yes:0');
        Observer.Expect('x11', 'Yes:1[<r xmlns="urn:a">\r\n  <c />\r\n  <?tgt dat?>\r\n  <x xmlns="urn:b" />\r\n</r>]');
        Observer.Expect('x12', 'Yes:1[<r xmlns="urn:a">\r\n  <c />\r\n  <?tgt dat?>\r\n  <x xmlns="urn:b" />\r\n</r>]');
        Observer.Expect('x13', 'Yes:1[<?tgt dat?>]');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Nodes_ManagerPartial()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
        Doc: XmlDocument;
        Mgr: XmlNamespaceManager;
    begin
        BuildDocNs(Doc, Nd);
        RunNodesNs(Observer, Nd, Mgr, 'empty1', '/a:r');
        RunNodesNs(Observer, Nd, Mgr, 'empty2', '/a:r/a:c');
        RunNodesNs(Observer, Nd, Mgr, 'empty3', '//b:x');
        RunNodesNs(Observer, Nd, Mgr, 'empty4', 'preceding-sibling::a:c');
        RunNodesNs(Observer, Nd, Mgr, 'empty5', '../a:c');
        Mgr.AddNamespace('a', 'urn:a');
        RunNodesNs(Observer, Nd, Mgr, 'partial1', '/a:r');
        RunNodesNs(Observer, Nd, Mgr, 'partial2', '/a:r/a:c');
        RunNodesNs(Observer, Nd, Mgr, 'partial3', '//b:x');
        Observer.Expect('empty1', 'No:0');
        Observer.Expect('empty2', 'No:0');
        Observer.Expect('empty3', 'No:0');
        Observer.Expect('empty4', 'No:0');
        Observer.Expect('empty5', 'No:0');
        Observer.Expect('partial1', 'Yes:1[<r xmlns="urn:a">\r\n  <c />\r\n  <?tgt dat?>\r\n  <x xmlns="urn:b" />\r\n</r>]');
        Observer.Expect('partial2', 'Yes:1[<c xmlns="urn:a" />]');
        Observer.Expect('partial3', 'No:0');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Single_WithManager()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
        Doc: XmlDocument;
        Mgr: XmlNamespaceManager;
    begin
        BuildDocNs(Doc, Nd);
        Mgr.AddNamespace('a', 'urn:a');
        Mgr.AddNamespace('b', 'urn:b');
        RunSingleNs(Observer, Nd, Mgr, 'x1', '/a:r');
        RunSingleNs(Observer, Nd, Mgr, 'x2', '/a:r/a:c');
        RunSingleNs(Observer, Nd, Mgr, 'x3', '//b:x');
        RunSingleNs(Observer, Nd, Mgr, 'x4', 'preceding-sibling::a:c');
        RunSingleNs(Observer, Nd, Mgr, 'x5', '../a:c');
        RunSingleNs(Observer, Nd, Mgr, 'x6', '/a:r/*');
        RunSingleNs(Observer, Nd, Mgr, 'x7', 'following-sibling::b:x');
        RunSingleNs(Observer, Nd, Mgr, 'x8', 'a:c');
        RunSingleNs(Observer, Nd, Mgr, 'x9', 'zz:r');
        RunSingleNs(Observer, Nd, Mgr, 'x10', '/r');
        RunSingleNs(Observer, Nd, Mgr, 'x11', '/*[local-name()="r"]');
        RunSingleNs(Observer, Nd, Mgr, 'x12', '..');
        RunSingleNs(Observer, Nd, Mgr, 'x13', '.');
        Observer.Expect('x1', 'Yes:<r xmlns="urn:a">\r\n  <c />\r\n  <?tgt dat?>\r\n  <x xmlns="urn:b" />\r\n</r>');
        Observer.Expect('x2', 'Yes:<c xmlns="urn:a" />');
        Observer.Expect('x3', 'Yes:<x xmlns="urn:b" />');
        Observer.Expect('x4', 'Yes:<c xmlns="urn:a" />');
        Observer.Expect('x5', 'Yes:<c xmlns="urn:a" />');
        Observer.Expect('x6', 'Yes:<c xmlns="urn:a" />');
        Observer.Expect('x7', 'Yes:<x xmlns="urn:b" />');
        Observer.Expect('x8', 'No:');
        Observer.Expect('x9', 'No:');
        Observer.Expect('x10', 'No:');
        Observer.Expect('x11', 'Yes:<r xmlns="urn:a">\r\n  <c />\r\n  <?tgt dat?>\r\n  <x xmlns="urn:b" />\r\n</r>');
        Observer.Expect('x12', 'Yes:<r xmlns="urn:a">\r\n  <c />\r\n  <?tgt dat?>\r\n  <x xmlns="urn:b" />\r\n</r>');
        Observer.Expect('x13', 'Yes:<?tgt dat?>');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Single_ManagerPartial()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
        Doc: XmlDocument;
        Mgr: XmlNamespaceManager;
    begin
        BuildDocNs(Doc, Nd);
        RunSingleNs(Observer, Nd, Mgr, 'empty1', '/a:r');
        RunSingleNs(Observer, Nd, Mgr, 'empty2', '/a:r/a:c');
        RunSingleNs(Observer, Nd, Mgr, 'empty3', '//b:x');
        RunSingleNs(Observer, Nd, Mgr, 'empty4', 'preceding-sibling::a:c');
        RunSingleNs(Observer, Nd, Mgr, 'empty5', '../a:c');
        Mgr.AddNamespace('a', 'urn:a');
        RunSingleNs(Observer, Nd, Mgr, 'partial1', '/a:r');
        RunSingleNs(Observer, Nd, Mgr, 'partial2', '/a:r/a:c');
        RunSingleNs(Observer, Nd, Mgr, 'partial3', '//b:x');
        Observer.Expect('empty1', 'No:');
        Observer.Expect('empty2', 'No:');
        Observer.Expect('empty3', 'No:');
        Observer.Expect('empty4', 'No:');
        Observer.Expect('empty5', 'No:');
        Observer.Expect('partial1', 'Yes:<r xmlns="urn:a">\r\n  <c />\r\n  <?tgt dat?>\r\n  <x xmlns="urn:b" />\r\n</r>');
        Observer.Expect('partial2', 'Yes:<c xmlns="urn:a" />');
        Observer.Expect('partial3', 'No:');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Nodes_NsDocWithoutManager()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
        Doc: XmlDocument;
    begin
        BuildDocNs(Doc, Nd);
        RunNodes(Observer, Nd, 'x1', '/a:r');
        RunNodes(Observer, Nd, 'x2', '//b:x');
        RunNodes(Observer, Nd, 'x3', '/r');
        RunNodes(Observer, Nd, 'x4', '/*[local-name()="r"]');
        RunNodes(Observer, Nd, 'x5', '/*[namespace-uri()="urn:a"]');
        RunNodes(Observer, Nd, 'x6', '../*');
        RunNodes(Observer, Nd, 'x7', 'following-sibling::*');
        RunNodes(Observer, Nd, 'x8', 'preceding-sibling::*');
        Observer.Expect('x1', 'No:0');
        Observer.Expect('x2', 'No:0');
        Observer.Expect('x3', 'Yes:0');
        Observer.Expect('x4', 'Yes:1[<r xmlns="urn:a">\r\n  <c />\r\n  <?tgt dat?>\r\n  <x xmlns="urn:b" />\r\n</r>]');
        Observer.Expect('x5', 'Yes:1[<r xmlns="urn:a">\r\n  <c />\r\n  <?tgt dat?>\r\n  <x xmlns="urn:b" />\r\n</r>]');
        Observer.Expect('x6', 'Yes:2[<c xmlns="urn:a" />][<x xmlns="urn:b" />]');
        Observer.Expect('x7', 'Yes:1[<x xmlns="urn:b" />]');
        Observer.Expect('x8', 'Yes:1[<c xmlns="urn:a" />]');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Single_NsDocWithoutManager()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
        Doc: XmlDocument;
    begin
        BuildDocNs(Doc, Nd);
        RunSingle(Observer, Nd, 'x1', '/a:r');
        RunSingle(Observer, Nd, 'x2', '//b:x');
        RunSingle(Observer, Nd, 'x3', '/r');
        RunSingle(Observer, Nd, 'x4', '/*[local-name()="r"]');
        RunSingle(Observer, Nd, 'x5', '/*[namespace-uri()="urn:a"]');
        RunSingle(Observer, Nd, 'x6', '../*');
        RunSingle(Observer, Nd, 'x7', 'following-sibling::*');
        RunSingle(Observer, Nd, 'x8', 'preceding-sibling::*');
        Observer.Expect('x1', 'No:');
        Observer.Expect('x2', 'No:');
        Observer.Expect('x3', 'No:');
        Observer.Expect('x4', 'Yes:<r xmlns="urn:a">\r\n  <c />\r\n  <?tgt dat?>\r\n  <x xmlns="urn:b" />\r\n</r>');
        Observer.Expect('x5', 'Yes:<r xmlns="urn:a">\r\n  <c />\r\n  <?tgt dat?>\r\n  <x xmlns="urn:b" />\r\n</r>');
        Observer.Expect('x6', 'Yes:<c xmlns="urn:a" />');
        Observer.Expect('x7', 'Yes:<x xmlns="urn:b" />');
        Observer.Expect('x8', 'Yes:<c xmlns="urn:a" />');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Manager_Detached()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlProcessingInstruction;
        Mgr: XmlNamespaceManager;
    begin
        MakeNode(Nd, 1);
        Mgr.AddNamespace('a', 'urn:a');
        RunNodesNs(Observer, Nd, Mgr, 'n1', '.');
        RunSingleNs(Observer, Nd, Mgr, 's1', '.');
        RunNodesNs(Observer, Nd, Mgr, 'n2', '..');
        RunSingleNs(Observer, Nd, Mgr, 's2', '..');
        RunNodesNs(Observer, Nd, Mgr, 'n3', 'a:r');
        RunSingleNs(Observer, Nd, Mgr, 's3', 'a:r');
        RunNodesNs(Observer, Nd, Mgr, 'n4', '//a:r');
        RunSingleNs(Observer, Nd, Mgr, 's4', '//a:r');
        RunNodesNs(Observer, Nd, Mgr, 'n5', 'a:zz');
        RunSingleNs(Observer, Nd, Mgr, 's5', 'a:zz');
        Observer.Expect('n1', 'Yes:1[<?tgt dat?>]');
        Observer.Expect('s1', 'Yes:<?tgt dat?>');
        Observer.Expect('n2', 'Yes:0');
        Observer.Expect('s2', 'No:');
        Observer.Expect('n3', 'Yes:0');
        Observer.Expect('s3', 'No:');
        Observer.Expect('n4', 'Yes:0');
        Observer.Expect('s4', 'No:');
        Observer.Expect('n5', 'Yes:0');
        Observer.Expect('s5', 'No:');
        Observer.Verify();
    end;

}
