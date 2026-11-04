// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlprocessinginstruction/xmlprocessinginstruction-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table LT P104 Blob where an OutStream is written
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlProcessingInstruction.AddAfterSelf and AddBeforeSelf with every kind of content
// BC versions: 29 (27 and 28 by CI)

codeunit 71811 "LT P104 Tree1 PI"
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

    local procedure Ser(var Doc: XmlDocument): Text
    var
        S: Text;
    begin
        Doc.WriteTo(S);
        exit(S);
    end;

    [TryFunction]
    local procedure TryAddAfterSelf(var Nd: XmlProcessingInstruction; V: Integer)
    begin
        case V of
            1:
                Nd.AddAfterSelf(XmlComment.Create('new'));
            2:
                Nd.AddAfterSelf(XmlText.Create('txt'));
            3:
                Nd.AddAfterSelf(XmlElement.Create('n'));
            4:
                Nd.AddAfterSelf(XmlCData.Create('cd'));
            5:
                Nd.AddAfterSelf(XmlProcessingInstruction.Create('pi', 'dat'));
            6:
                Nd.AddAfterSelf(XmlElement.Create('n1'), XmlElement.Create('n2'));
            7:
                Nd.AddAfterSelf('plain text');
            8:
                Nd.AddAfterSelf(42);
            9:
                Nd.AddAfterSelf(XmlAttribute.Create('at', 'v'));
            10:
                Nd.AddAfterSelf(XmlDocument.Create());
            11:
                Nd.AddAfterSelf(Nd);
            12:
                Nd.AddAfterSelf(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
            13:
                Nd.AddAfterSelf(XmlDocumentType.Create('d'));
            14:
                Nd.AddAfterSelf(XmlComment.Create('c1'), XmlText.Create('t2'), XmlElement.Create('e3'));
            15:
                Nd.AddAfterSelf('');
        end;
    end;

    local procedure RunAddAfterSelf(var Observer: Codeunit "Probe Observer"; Name: Text; Variant: Integer; Content: Integer)
    var
        Doc: XmlDocument;
        Nd: XmlProcessingInstruction;
    begin
        BuildDoc(Doc, Nd, Variant);
        if TryAddAfterSelf(Nd, Content) then
            Observer.Observe(Name, Ser(Doc))
        else
            Observer.ObserveError(Name);
    end;

    local procedure RunDetachedAddAfterSelf(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Integer)
    var
        Nd: XmlProcessingInstruction;
        S: Text;
    begin
        MakeNode(Nd, 1);
        if TryAddAfterSelf(Nd, Content) then begin
            Nd.WriteTo(S);
            Observer.Observe(Name, 'ok:' + S);
        end else
            Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure TryAddBeforeSelf(var Nd: XmlProcessingInstruction; V: Integer)
    begin
        case V of
            1:
                Nd.AddBeforeSelf(XmlComment.Create('new'));
            2:
                Nd.AddBeforeSelf(XmlText.Create('txt'));
            3:
                Nd.AddBeforeSelf(XmlElement.Create('n'));
            4:
                Nd.AddBeforeSelf(XmlCData.Create('cd'));
            5:
                Nd.AddBeforeSelf(XmlProcessingInstruction.Create('pi', 'dat'));
            6:
                Nd.AddBeforeSelf(XmlElement.Create('n1'), XmlElement.Create('n2'));
            7:
                Nd.AddBeforeSelf('plain text');
            8:
                Nd.AddBeforeSelf(42);
            9:
                Nd.AddBeforeSelf(XmlAttribute.Create('at', 'v'));
            10:
                Nd.AddBeforeSelf(XmlDocument.Create());
            11:
                Nd.AddBeforeSelf(Nd);
            12:
                Nd.AddBeforeSelf(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
            13:
                Nd.AddBeforeSelf(XmlDocumentType.Create('d'));
            14:
                Nd.AddBeforeSelf(XmlComment.Create('c1'), XmlText.Create('t2'), XmlElement.Create('e3'));
            15:
                Nd.AddBeforeSelf('');
        end;
    end;

    local procedure RunAddBeforeSelf(var Observer: Codeunit "Probe Observer"; Name: Text; Variant: Integer; Content: Integer)
    var
        Doc: XmlDocument;
        Nd: XmlProcessingInstruction;
    begin
        BuildDoc(Doc, Nd, Variant);
        if TryAddBeforeSelf(Nd, Content) then
            Observer.Observe(Name, Ser(Doc))
        else
            Observer.ObserveError(Name);
    end;

    local procedure RunDetachedAddBeforeSelf(var Observer: Codeunit "Probe Observer"; Name: Text; Content: Integer)
    var
        Nd: XmlProcessingInstruction;
        S: Text;
    begin
        MakeNode(Nd, 1);
        if TryAddBeforeSelf(Nd, Content) then begin
            Nd.WriteTo(S);
            Observer.Observe(Name, 'ok:' + S);
        end else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure P104_AddAfterSelf_Contents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAddAfterSelf(Observer, 'c1', 1, 1);
        RunAddAfterSelf(Observer, 'c2', 1, 2);
        RunAddAfterSelf(Observer, 'c3', 1, 3);
        RunAddAfterSelf(Observer, 'c4', 1, 4);
        RunAddAfterSelf(Observer, 'c5', 1, 5);
        RunAddAfterSelf(Observer, 'c6', 1, 6);
        RunAddAfterSelf(Observer, 'c7', 1, 7);
        RunAddAfterSelf(Observer, 'c8', 1, 8);
        RunAddAfterSelf(Observer, 'c9', 1, 9);
        RunAddAfterSelf(Observer, 'c10', 1, 10);
        RunAddAfterSelf(Observer, 'c11', 1, 11);
        RunAddAfterSelf(Observer, 'c12', 1, 12);
        RunAddAfterSelf(Observer, 'c13', 1, 13);
        RunAddAfterSelf(Observer, 'c14', 1, 14);
        RunAddAfterSelf(Observer, 'c15', 1, 15);
        Observer.Expect('c1', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <!--new-->\r\n  <b />\r\n</r>');
        Observer.Expect('c2', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>txt<b /></r>');
        Observer.Expect('c3', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <n />\r\n  <b />\r\n</r>');
        Observer.Expect('c4', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?><![CDATA[cd]]><b /></r>');
        Observer.Expect('c5', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <?pi dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('c6', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <n1 />\r\n  <n2 />\r\n  <b />\r\n</r>');
        Observer.Expect('c7', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>plain text<b /></r>');
        Observer.Expect('c8', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>42<b /></r>');
        Observer.Expect('c9|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('c9|code', 'Argument');
        Observer.Expect('c10|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('c10|code', 'Argument');
        Observer.Expect('c11', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('c12', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>&lt;?xml version="1.0" encoding="utf-8" standalone="yes"?&gt;<b /></r>');
        Observer.Expect('c13|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('c13|code', 'Argument');
        Observer.Expect('c14', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <!--c1-->t2<e3 /><b /></r>');
        Observer.Expect('c15', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure P104_AddAfterSelf_OtherValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAddAfterSelf(Observer, 'v2c1', 2, 1);
        RunAddAfterSelf(Observer, 'v2c2', 2, 2);
        RunAddAfterSelf(Observer, 'v2c3', 2, 3);
        RunAddAfterSelf(Observer, 'v2c6', 2, 6);
        RunAddAfterSelf(Observer, 'v2c7', 2, 7);
        RunAddAfterSelf(Observer, 'v2c11', 2, 11);
        RunAddAfterSelf(Observer, 'v3c1', 3, 1);
        RunAddAfterSelf(Observer, 'v3c2', 3, 2);
        RunAddAfterSelf(Observer, 'v3c3', 3, 3);
        RunAddAfterSelf(Observer, 'v3c6', 3, 6);
        RunAddAfterSelf(Observer, 'v3c7', 3, 7);
        RunAddAfterSelf(Observer, 'v3c11', 3, 11);
        Observer.Expect('v2c1', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <!--new-->\r\n  <b />\r\n</r>');
        Observer.Expect('v2c2', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>txt<b /></r>');
        Observer.Expect('v2c3', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <n />\r\n  <b />\r\n</r>');
        Observer.Expect('v2c6', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <n1 />\r\n  <n2 />\r\n  <b />\r\n</r>');
        Observer.Expect('v2c7', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>plain text<b /></r>');
        Observer.Expect('v2c11', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>');
        Observer.Expect('v3c1', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt?>\r\n  <!--new-->\r\n  <b />\r\n</r>');
        Observer.Expect('v3c2', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt?>txt<b /></r>');
        Observer.Expect('v3c3', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt?>\r\n  <n />\r\n  <b />\r\n</r>');
        Observer.Expect('v3c6', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt?>\r\n  <n1 />\r\n  <n2 />\r\n  <b />\r\n</r>');
        Observer.Expect('v3c7', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt?>plain text<b /></r>');
        Observer.Expect('v3c11', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt?>\r\n  <?tgt?>\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure P104_AddAfterSelf_Detached()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDetachedAddAfterSelf(Observer, 'd1', 1);
        RunDetachedAddAfterSelf(Observer, 'd2', 2);
        RunDetachedAddAfterSelf(Observer, 'd3', 3);
        RunDetachedAddAfterSelf(Observer, 'd4', 4);
        RunDetachedAddAfterSelf(Observer, 'd6', 6);
        RunDetachedAddAfterSelf(Observer, 'd7', 7);
        RunDetachedAddAfterSelf(Observer, 'd8', 8);
        RunDetachedAddAfterSelf(Observer, 'd11', 11);
        RunDetachedAddAfterSelf(Observer, 'd12', 12);
        RunDetachedAddAfterSelf(Observer, 'd13', 13);
        Observer.Expect('d1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d1|code', 'InvalidOperation');
        Observer.Expect('d2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d2|code', 'InvalidOperation');
        Observer.Expect('d3|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d3|code', 'InvalidOperation');
        Observer.Expect('d4|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d4|code', 'InvalidOperation');
        Observer.Expect('d6|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d6|code', 'InvalidOperation');
        Observer.Expect('d7|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d7|code', 'InvalidOperation');
        Observer.Expect('d8|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d8|code', 'InvalidOperation');
        Observer.Expect('d11|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d11|code', 'InvalidOperation');
        Observer.Expect('d12|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d12|code', 'InvalidOperation');
        Observer.Expect('d13|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d13|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure P104_AddBeforeSelf_Contents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAddBeforeSelf(Observer, 'c1', 1, 1);
        RunAddBeforeSelf(Observer, 'c2', 1, 2);
        RunAddBeforeSelf(Observer, 'c3', 1, 3);
        RunAddBeforeSelf(Observer, 'c4', 1, 4);
        RunAddBeforeSelf(Observer, 'c5', 1, 5);
        RunAddBeforeSelf(Observer, 'c6', 1, 6);
        RunAddBeforeSelf(Observer, 'c7', 1, 7);
        RunAddBeforeSelf(Observer, 'c8', 1, 8);
        RunAddBeforeSelf(Observer, 'c9', 1, 9);
        RunAddBeforeSelf(Observer, 'c10', 1, 10);
        RunAddBeforeSelf(Observer, 'c11', 1, 11);
        RunAddBeforeSelf(Observer, 'c12', 1, 12);
        RunAddBeforeSelf(Observer, 'c13', 1, 13);
        RunAddBeforeSelf(Observer, 'c14', 1, 14);
        RunAddBeforeSelf(Observer, 'c15', 1, 15);
        Observer.Expect('c1', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--new-->\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('c2', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />txt<?tgt dat?><b /></r>');
        Observer.Expect('c3', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <n />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('c4', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a /><![CDATA[cd]]><?tgt dat?><b /></r>');
        Observer.Expect('c5', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?pi dat?>\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('c6', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <n1 />\r\n  <n2 />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('c7', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />plain text<?tgt dat?><b /></r>');
        Observer.Expect('c8', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />42<?tgt dat?><b /></r>');
        Observer.Expect('c9|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('c9|code', 'Argument');
        Observer.Expect('c10|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('c10|code', 'Argument');
        Observer.Expect('c11', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Expect('c12', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />&lt;?xml version="1.0" encoding="utf-8" standalone="yes"?&gt;<?tgt dat?><b /></r>');
        Observer.Expect('c13|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('c13|code', 'Argument');
        Observer.Expect('c14', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--c1-->t2<e3 /><?tgt dat?><b /></r>');
        Observer.Expect('c15', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt dat?>\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure P104_AddBeforeSelf_OtherValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAddBeforeSelf(Observer, 'v2c1', 2, 1);
        RunAddBeforeSelf(Observer, 'v2c2', 2, 2);
        RunAddBeforeSelf(Observer, 'v2c3', 2, 3);
        RunAddBeforeSelf(Observer, 'v2c6', 2, 6);
        RunAddBeforeSelf(Observer, 'v2c7', 2, 7);
        RunAddBeforeSelf(Observer, 'v2c11', 2, 11);
        RunAddBeforeSelf(Observer, 'v3c1', 3, 1);
        RunAddBeforeSelf(Observer, 'v3c2', 3, 2);
        RunAddBeforeSelf(Observer, 'v3c3', 3, 3);
        RunAddBeforeSelf(Observer, 'v3c6', 3, 6);
        RunAddBeforeSelf(Observer, 'v3c7', 3, 7);
        RunAddBeforeSelf(Observer, 'v3c11', 3, 11);
        Observer.Expect('v2c1', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--new-->\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>');
        Observer.Expect('v2c2', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />txt<?tgt a<b>&"q"?><b /></r>');
        Observer.Expect('v2c3', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <n />\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>');
        Observer.Expect('v2c6', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <n1 />\r\n  <n2 />\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>');
        Observer.Expect('v2c7', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />plain text<?tgt a<b>&"q"?><b /></r>');
        Observer.Expect('v2c11', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt a<b>&"q"?>\r\n  <?tgt a<b>&"q"?>\r\n  <b />\r\n</r>');
        Observer.Expect('v3c1', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <!--new-->\r\n  <?tgt?>\r\n  <b />\r\n</r>');
        Observer.Expect('v3c2', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />txt<?tgt?><b /></r>');
        Observer.Expect('v3c3', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <n />\r\n  <?tgt?>\r\n  <b />\r\n</r>');
        Observer.Expect('v3c6', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <n1 />\r\n  <n2 />\r\n  <?tgt?>\r\n  <b />\r\n</r>');
        Observer.Expect('v3c7', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />plain text<?tgt?><b /></r>');
        Observer.Expect('v3c11', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <?tgt?>\r\n  <?tgt?>\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure P104_AddBeforeSelf_Detached()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDetachedAddBeforeSelf(Observer, 'd1', 1);
        RunDetachedAddBeforeSelf(Observer, 'd2', 2);
        RunDetachedAddBeforeSelf(Observer, 'd3', 3);
        RunDetachedAddBeforeSelf(Observer, 'd4', 4);
        RunDetachedAddBeforeSelf(Observer, 'd6', 6);
        RunDetachedAddBeforeSelf(Observer, 'd7', 7);
        RunDetachedAddBeforeSelf(Observer, 'd8', 8);
        RunDetachedAddBeforeSelf(Observer, 'd11', 11);
        RunDetachedAddBeforeSelf(Observer, 'd12', 12);
        RunDetachedAddBeforeSelf(Observer, 'd13', 13);
        Observer.Expect('d1|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d1|code', 'InvalidOperation');
        Observer.Expect('d2|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d2|code', 'InvalidOperation');
        Observer.Expect('d3|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d3|code', 'InvalidOperation');
        Observer.Expect('d4|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d4|code', 'InvalidOperation');
        Observer.Expect('d6|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d6|code', 'InvalidOperation');
        Observer.Expect('d7|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d7|code', 'InvalidOperation');
        Observer.Expect('d8|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d8|code', 'InvalidOperation');
        Observer.Expect('d11|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d11|code', 'InvalidOperation');
        Observer.Expect('d12|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d12|code', 'InvalidOperation');
        Observer.Expect('d13|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('d13|code', 'InvalidOperation');
        Observer.Verify();
    end;

}
