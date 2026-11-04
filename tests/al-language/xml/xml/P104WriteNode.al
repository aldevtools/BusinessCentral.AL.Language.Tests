// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlnode/xmlnode-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table LT P104 Blob where an OutStream is written
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlNode.WriteTo, each overload (Text, XmlWriteOptions + Text, OutStream, XmlWriteOptions + OutStream), detached and inside a document
// BC versions: 29 (27 and 28 by CI)

codeunit 71826 "LT P104 Write Node"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure MakeNode(var Nd: XmlNode; V: Integer)
    begin
        case V of
            1:
                Nd := XmlText.Create('plain').AsXmlNode();
            2:
                Nd := XmlElement.Create('e', XmlText.Create('t')).AsXmlNode();
            3:
                Nd := XmlComment.Create('c').AsXmlNode();
        end;
    end;

    local procedure BuildDoc(var Doc: XmlDocument; var Nd: XmlNode; V: Integer)
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

    [TryFunction]
    local procedure TryText(var Nd: XmlNode; Mode: Integer; var Result: Text)
    var
        Opt: XmlWriteOptions;
    begin
        case Mode of
            1:
                Nd.WriteTo(Result);
            2:
                begin
                    Opt.PreserveWhitespace(true);
                    Nd.WriteTo(Opt, Result);
                end;
            3:
                begin
                    Opt.PreserveWhitespace(false);
                    Nd.WriteTo(Opt, Result);
                end;
            4:
                begin
                    Nd.WriteTo(Opt, Result);
                end;
        end;
    end;

    local procedure RunText(var Observer: Codeunit "Probe Observer"; var Nd: XmlNode; Name: Text; Mode: Integer)
    var
        R: Text;
    begin
        R := 'unset';
        if TryText(Nd, Mode, R) then
            Observer.Observe(Name, '[' + R + ']')
        else
            Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure TryStream(var Nd: XmlNode; Mode: Integer; var Rec: Record "LT P104 Blob")
    var
        OutS: OutStream;
        Opt: XmlWriteOptions;
    begin
        Rec.Data.CreateOutStream(OutS);
        case Mode of
            1:
                Nd.WriteTo(OutS);
            2:
                begin
                    Opt.PreserveWhitespace(true);
                    Nd.WriteTo(Opt, OutS);
                end;
            3:
                begin
                    Opt.PreserveWhitespace(false);
                    Nd.WriteTo(Opt, OutS);
                end;
            4:
                Nd.WriteTo(Opt, OutS);
        end;
    end;

    local procedure RunStream(var Observer: Codeunit "Probe Observer"; var Nd: XmlNode; Name: Text; Mode: Integer)
    var
        Rec: Record "LT P104 Blob";
        InS: InStream;
        L: Text;
        T: Text;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
        if TryStream(Nd, Mode, Rec) then begin
            Rec.Modify();
            Rec.CalcFields(Data);
            Rec.Data.CreateInStream(InS);
            while not InS.EOS() do begin
                InS.ReadText(L);
                T += L + '|';
            end;
            Observer.Observe(Name + '_len', Format(Rec.Data.Length()));
            Observer.Observe(Name + '_text', T);
        end else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure P104_Text_Detached()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlNode;
    begin
        MakeNode(Nd, 1);
        RunText(Observer, Nd, 'v1_m1', 1);
        RunText(Observer, Nd, 'v1_m2', 2);
        RunText(Observer, Nd, 'v1_m3', 3);
        RunText(Observer, Nd, 'v1_m4', 4);
        MakeNode(Nd, 2);
        RunText(Observer, Nd, 'v2_m1', 1);
        RunText(Observer, Nd, 'v2_m2', 2);
        RunText(Observer, Nd, 'v2_m3', 3);
        RunText(Observer, Nd, 'v2_m4', 4);
        MakeNode(Nd, 3);
        RunText(Observer, Nd, 'v3_m1', 1);
        RunText(Observer, Nd, 'v3_m2', 2);
        RunText(Observer, Nd, 'v3_m3', 3);
        RunText(Observer, Nd, 'v3_m4', 4);
        Observer.Expect('v1_m1', '[plain]');
        Observer.Expect('v1_m2', '[plain]');
        Observer.Expect('v1_m3', '[plain]');
        Observer.Expect('v1_m4', '[plain]');
        Observer.Expect('v2_m1', '[<e>t</e>]');
        Observer.Expect('v2_m2', '[<e>t</e>]');
        Observer.Expect('v2_m3', '[<e>t</e>]');
        Observer.Expect('v2_m4', '[<e>t</e>]');
        Observer.Expect('v3_m1', '[<!--c-->]');
        Observer.Expect('v3_m2', '[<!--c-->]');
        Observer.Expect('v3_m3', '[<!--c-->]');
        Observer.Expect('v3_m4', '[<!--c-->]');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Text_InDoc()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlNode;
        Doc: XmlDocument;
    begin
        BuildDoc(Doc, Nd, 1);
        RunText(Observer, Nd, 'v1_m1', 1);
        RunText(Observer, Nd, 'v1_m2', 2);
        RunText(Observer, Nd, 'v1_m3', 3);
        RunText(Observer, Nd, 'v1_m4', 4);
        BuildDoc(Doc, Nd, 2);
        RunText(Observer, Nd, 'v2_m1', 1);
        RunText(Observer, Nd, 'v2_m2', 2);
        RunText(Observer, Nd, 'v2_m3', 3);
        RunText(Observer, Nd, 'v2_m4', 4);
        BuildDoc(Doc, Nd, 3);
        RunText(Observer, Nd, 'v3_m1', 1);
        RunText(Observer, Nd, 'v3_m2', 2);
        RunText(Observer, Nd, 'v3_m3', 3);
        RunText(Observer, Nd, 'v3_m4', 4);
        Observer.Expect('v1_m1', '[plain]');
        Observer.Expect('v1_m2', '[plain]');
        Observer.Expect('v1_m3', '[plain]');
        Observer.Expect('v1_m4', '[plain]');
        Observer.Expect('v2_m1', '[<e>t</e>]');
        Observer.Expect('v2_m2', '[<e>t</e>]');
        Observer.Expect('v2_m3', '[<e>t</e>]');
        Observer.Expect('v2_m4', '[<e>t</e>]');
        Observer.Expect('v3_m1', '[<!--c-->]');
        Observer.Expect('v3_m2', '[<!--c-->]');
        Observer.Expect('v3_m3', '[<!--c-->]');
        Observer.Expect('v3_m4', '[<!--c-->]');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Stream_Detached()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlNode;
    begin
        MakeNode(Nd, 1);
        RunStream(Observer, Nd, 'v1_m1', 1);
        RunStream(Observer, Nd, 'v1_m2', 2);
        RunStream(Observer, Nd, 'v1_m3', 3);
        RunStream(Observer, Nd, 'v1_m4', 4);
        MakeNode(Nd, 2);
        RunStream(Observer, Nd, 'v2_m1', 1);
        RunStream(Observer, Nd, 'v2_m2', 2);
        RunStream(Observer, Nd, 'v2_m3', 3);
        RunStream(Observer, Nd, 'v2_m4', 4);
        MakeNode(Nd, 3);
        RunStream(Observer, Nd, 'v3_m1', 1);
        RunStream(Observer, Nd, 'v3_m2', 2);
        RunStream(Observer, Nd, 'v3_m3', 3);
        RunStream(Observer, Nd, 'v3_m4', 4);
        Observer.Expect('v1_m1_len', '8');
        Observer.Expect('v1_m1_text', 'Ù‹plain|');
        Observer.Expect('v1_m2_len', '8');
        Observer.Expect('v1_m2_text', 'Ù‹plain|');
        Observer.Expect('v1_m3_len', '8');
        Observer.Expect('v1_m3_text', 'Ù‹plain|');
        Observer.Expect('v1_m4_len', '8');
        Observer.Expect('v1_m4_text', 'Ù‹plain|');
        Observer.Expect('v2_m1_len', '11');
        Observer.Expect('v2_m1_text', 'Ù‹<e>t</e>|');
        Observer.Expect('v2_m2_len', '11');
        Observer.Expect('v2_m2_text', 'Ù‹<e>t</e>|');
        Observer.Expect('v2_m3_len', '11');
        Observer.Expect('v2_m3_text', 'Ù‹<e>t</e>|');
        Observer.Expect('v2_m4_len', '11');
        Observer.Expect('v2_m4_text', 'Ù‹<e>t</e>|');
        Observer.Expect('v3_m1_len', '11');
        Observer.Expect('v3_m1_text', 'Ù‹<!--c-->|');
        Observer.Expect('v3_m2_len', '11');
        Observer.Expect('v3_m2_text', 'Ù‹<!--c-->|');
        Observer.Expect('v3_m3_len', '11');
        Observer.Expect('v3_m3_text', 'Ù‹<!--c-->|');
        Observer.Expect('v3_m4_len', '11');
        Observer.Expect('v3_m4_text', 'Ù‹<!--c-->|');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Stream_InDoc()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlNode;
        Doc: XmlDocument;
    begin
        BuildDoc(Doc, Nd, 1);
        RunStream(Observer, Nd, 'v1_m1', 1);
        RunStream(Observer, Nd, 'v1_m2', 2);
        RunStream(Observer, Nd, 'v1_m3', 3);
        RunStream(Observer, Nd, 'v1_m4', 4);
        BuildDoc(Doc, Nd, 2);
        RunStream(Observer, Nd, 'v2_m1', 1);
        RunStream(Observer, Nd, 'v2_m2', 2);
        RunStream(Observer, Nd, 'v2_m3', 3);
        RunStream(Observer, Nd, 'v2_m4', 4);
        Observer.Expect('v1_m1_len', '8');
        Observer.Expect('v1_m1_text', 'Ù‹plain|');
        Observer.Expect('v1_m2_len', '8');
        Observer.Expect('v1_m2_text', 'Ù‹plain|');
        Observer.Expect('v1_m3_len', '8');
        Observer.Expect('v1_m3_text', 'Ù‹plain|');
        Observer.Expect('v1_m4_len', '8');
        Observer.Expect('v1_m4_text', 'Ù‹plain|');
        Observer.Expect('v2_m1_len', '11');
        Observer.Expect('v2_m1_text', 'Ù‹<e>t</e>|');
        Observer.Expect('v2_m2_len', '11');
        Observer.Expect('v2_m2_text', 'Ù‹<e>t</e>|');
        Observer.Expect('v2_m3_len', '11');
        Observer.Expect('v2_m3_text', 'Ù‹<e>t</e>|');
        Observer.Expect('v2_m4_len', '11');
        Observer.Expect('v2_m4_text', 'Ù‹<e>t</e>|');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Text_AfterRemove()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlNode;
        Doc: XmlDocument;
        Before: Text;
    begin
        BuildDoc(Doc, Nd, 1);
        Doc.WriteTo(Before);
        Observer.Observe('doc_before', Before);
        RunText(Observer, Nd, 'node_before', 1);
        Nd.Remove();
        RunText(Observer, Nd, 'removed', 1);
        RunText(Observer, Nd, 'removed_opt', 2);
        Doc.WriteTo(Before);
        Observer.Observe('doc_after', Before);
        Observer.Expect('doc_before', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />plain<b /></r>');
        Observer.Expect('node_before', '[plain]');
        Observer.Expect('removed', '[plain]');
        Observer.Expect('removed_opt', '[plain]');
        Observer.Expect('doc_after', '<?xml version="1.0" encoding="utf-16"?>\r\n<r>\r\n  <a />\r\n  <b />\r\n</r>');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Text_Overwrite()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlNode;
        S: Text;
        T2: Text;
        Opt: XmlWriteOptions;
    begin
        MakeNode(Nd, 1);
        S := 'prefilled';
        Nd.WriteTo(S);
        Observer.Observe('overwrite', S);
        Opt.PreserveWhitespace(true);
        S := 'prefilled';
        Nd.WriteTo(Opt, S);
        Observer.Observe('overwrite_opt', S);
        Opt.PreserveWhitespace(false);
        Nd.WriteTo(Opt, S);
        Observer.Observe('twice', S);
        Nd.WriteTo(T2);
        Observer.Observe('same_as_first', Format(S = T2));
        Observer.Expect('overwrite', 'plain');
        Observer.Expect('overwrite_opt', 'plain');
        Observer.Expect('twice', 'plain');
        Observer.Expect('same_as_first', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P104_WriteTo_Uninitialised()
    var
        Observer: Codeunit "Probe Observer";
        Nd: XmlNode;
    begin
        RunText(Observer, Nd, 'uninit1', 1);
        RunText(Observer, Nd, 'uninit2', 2);
        RunStream(Observer, Nd, 'uninit3', 1);
        RunStream(Observer, Nd, 'uninit4', 2);
        Observer.Expect('uninit1|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('uninit1|code', 'NotInitialized');
        Observer.Expect('uninit2|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('uninit2|code', 'NotInitialized');
        Observer.Expect('uninit3|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('uninit3|code', 'NotInitialized');
        Observer.Expect('uninit4|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('uninit4|code', 'NotInitialized');
        Observer.Verify();
    end;

}
