// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlelement/xmlelement-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table LT P104 Blob where an OutStream is written
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlElement.Create(Name, Content) (the open overload) next to Create(Name), RemoveAttribute(XmlAttribute) and every WriteTo overload
// BC versions: 29 (27 and 28 by CI)

codeunit 71828 "LT P104 Element"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCreateContent(V: Integer; var Result: Text)
    var
        E: XmlElement;
        Nd: XmlText;
    begin
        Nd := XmlText.Create('nodetext');
        case V of
            1:
                E := XmlElement.Create('e', XmlText.Create('t'));
            2:
                E := XmlElement.Create('e', XmlElement.Create('c'));
            3:
                E := XmlElement.Create('e', XmlAttribute.Create('a', 'v'));
            4:
                E := XmlElement.Create('e', XmlComment.Create('c'));
            5:
                E := XmlElement.Create('e', XmlCData.Create('d'));
            6:
                E := XmlElement.Create('e', XmlProcessingInstruction.Create('p', 'd'));
            7:
                E := XmlElement.Create('e', XmlElement.Create('c1'), XmlElement.Create('c2'));
            8:
                E := XmlElement.Create('e', XmlText.Create('t'), XmlElement.Create('c'), XmlComment.Create('x'));
            9:
                E := XmlElement.Create('e', XmlAttribute.Create('a', 'v'), XmlElement.Create('c'));
            10:
                E := XmlElement.Create('e', 42);
            11:
                E := XmlElement.Create('e', XmlDocument.Create());
            12:
                E := XmlElement.Create('e', XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
            13:
                E := XmlElement.Create('e', XmlDocumentType.Create('d'));
            14:
                E := XmlElement.Create('e', Nd);
            15:
                E := XmlElement.Create('e', Nd, Nd);
            16:
                E := XmlElement.Create('e', XmlAttribute.Create('a', 'v'), XmlAttribute.Create('a', 'w'));
        end;
        E.WriteTo(Result);
    end;

    local procedure RunCreate(var Observer: Codeunit "Probe Observer"; Name: Text; V: Integer)
    var
        R: Text;
    begin
        if TryCreateContent(V, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure P104_Create_Content()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        for V := 1 to 16 do
            RunCreate(Observer, 'c' + Format(V), V);
        Observer.Expect('c1', '<e>t</e>');
        Observer.Expect('c2', '<e>\r\n  <c />\r\n</e>');
        Observer.Expect('c3', '<e a="v" />');
        Observer.Expect('c4', '<e>\r\n  <!--c-->\r\n</e>');
        Observer.Expect('c5', '<e><![CDATA[d]]></e>');
        Observer.Expect('c6', '<e>\r\n  <?p d?>\r\n</e>');
        Observer.Expect('c7', '<e>\r\n  <c1 />\r\n  <c2 />\r\n</e>');
        Observer.Expect('c8', '<e>t<c /><!--x--></e>');
        Observer.Expect('c9', '<e a="v">\r\n  <c />\r\n</e>');
        Observer.Expect('c10', '<e>42</e>');
        Observer.Expect('c11|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('c11|code', 'Argument');
        Observer.Expect('c12', '<e>&lt;?xml version="1.0" encoding="utf-8" standalone="yes"?&gt;</e>');
        Observer.Expect('c13|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('c13|code', 'Argument');
        Observer.Expect('c14', '<e>nodetext</e>');
        Observer.Expect('c15', '<e>nodetextnodetext</e>');
        Observer.Expect('c16|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('c16|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Create_Name_Only_And_Invalid()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
        S: Text;
    begin
        E := XmlElement.Create('plain');
        E.WriteTo(S);
        Observer.Observe('name_only', S);
        asserterror E := XmlElement.Create('p:q');
        Observer.ObserveError('af88');
        E.WriteTo(S);
        Observer.Observe('prefixed_name_only', S);
        asserterror E := XmlElement.Create('', XmlText.Create('t'));
        Observer.ObserveError('empty_name_content');
        asserterror E := XmlElement.Create('a b', XmlText.Create('t'));
        Observer.ObserveError('blank_name_content');
        asserterror E := XmlElement.Create('1a', XmlText.Create('t'));
        Observer.ObserveError('digit_name_content');
        asserterror E := XmlElement.Create('');
        Observer.ObserveError('empty_name_only');
        asserterror E := XmlElement.Create('a b');
        Observer.ObserveError('blank_name_only');
        E := XmlElement.Create('e', XmlText.Create(''));
        E.WriteTo(S);
        Observer.Observe('empty_text_content', S);
        Observer.Expect('name_only', '<plain />');
        Observer.Expect('af88|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('af88|code', 'Xml:Xml');
        Observer.Expect('prefixed_name_only', '<plain />');
        Observer.Expect('empty_name_content|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty_name_content|code', 'Argument');
        Observer.Expect('blank_name_content|text', 'The following exception was encountered when processing XML data: ''The '' '' character, hexadecimal value 0x20, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('blank_name_content|code', 'Xml:Xml');
        Observer.Expect('digit_name_content|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''1'' character, hexadecimal value 0x31.'' at line 0 and position 1.');
        Observer.Expect('digit_name_content|code', 'Xml:Xml');
        Observer.Expect('empty_name_only|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty_name_only|code', 'Argument');
        Observer.Expect('blank_name_only|text', 'The following exception was encountered when processing XML data: ''The '' '' character, hexadecimal value 0x20, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('blank_name_only|code', 'Xml:Xml');
        Observer.Expect('empty_text_content', '<e></e>');
        Observer.Verify();
    end;

    [Test]
    procedure P104_Create_SameNodeTwice()
    var
        Observer: Codeunit "Probe Observer";
        E1: XmlElement;
        E2: XmlElement;
        C: XmlElement;
        S: Text;
    begin
        C := XmlElement.Create('c');
        E1 := XmlElement.Create('e1', C);
        E2 := XmlElement.Create('e2', C);
        E1.WriteTo(S);
        Observer.Observe('first_owner', S);
        E2.WriteTo(S);
        Observer.Observe('second_owner', S);
        C.WriteTo(S);
        Observer.Observe('child', S);
        Observer.Expect('first_owner', '<e1>\r\n  <c />\r\n</e1>');
        Observer.Expect('second_owner', '<e2>\r\n  <c />\r\n</e2>');
        Observer.Expect('child', '<c />');
        Observer.Verify();
    end;

    [Test]
    procedure P104_WriteTo_AllOverloads()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P104 Blob";
        E: XmlElement;
        Opt: XmlWriteOptions;
        OutS: OutStream;
        InS: InStream;
        S: Text;
        L: Text;
        T: Text;
    begin
        Rec.DeleteAll();
        E := XmlElement.Create('r', XmlElement.Create('a', XmlText.Create('1')), XmlText.Create(' '), XmlElement.Create('b', XmlText.Create('x')));
        E.SetAttribute('k', 'v');
        E.WriteTo(S);
        Observer.Observe('text', S);
        Opt.PreserveWhitespace(true);
        E.WriteTo(Opt, S);
        Observer.Observe('opt_true', S);
        Opt.PreserveWhitespace(false);
        E.WriteTo(Opt, S);
        Observer.Observe('opt_false', S);
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
        Rec.Data.CreateOutStream(OutS);
        E.WriteTo(OutS);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(L);
            T += L + '|';
        end;
        Observer.Observe('stream_len', Format(Rec.Data.Length()));
        Observer.Observe('stream_text', T);
        Rec.Id := 2;
        Rec.Insert();
        Rec.Data.CreateOutStream(OutS);
        Opt.PreserveWhitespace(true);
        E.WriteTo(Opt, OutS);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        T := '';
        while not InS.EOS() do begin
            InS.ReadText(L);
            T += L + '|';
        end;
        Observer.Observe('opt_true_len', Format(Rec.Data.Length()));
        Observer.Observe('opt_true_text', T);
        Rec.Id := 3;
        Rec.Insert();
        Rec.Data.CreateOutStream(OutS);
        Opt.PreserveWhitespace(false);
        E.WriteTo(Opt, OutS);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        T := '';
        while not InS.EOS() do begin
            InS.ReadText(L);
            T += L + '|';
        end;
        Observer.Observe('opt_false_len', Format(Rec.Data.Length()));
        Observer.Observe('opt_false_text', T);
        Observer.Expect('text', '<r k="v">\r\n  <a>1</a> <b>x</b></r>');
        Observer.Expect('opt_true', '<r k="v"><a>1</a> <b>x</b></r>');
        Observer.Expect('opt_false', '<r k="v">\r\n  <a>1</a> <b>x</b></r>');
        Observer.Expect('stream_len', '37');
        Observer.Expect('stream_text', 'Ù‹<r k="v">|  <a>1</a> <b>x</b></r>|');
        Observer.Expect('opt_true_len', '37');
        Observer.Expect('opt_true_text', 'Ù‹<r k="v"><a>1</a> <b>x</b></r></r>|');
        Observer.Expect('opt_false_len', '37');
        Observer.Expect('opt_false_text', 'Ù‹<r k="v">|  <a>1</a> <b>x</b></r>|');
        Observer.Verify();
    end;

    [Test]
    procedure P104_WriteTo_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P104 Blob";
        E: XmlElement;
        Doc: XmlDocument;
        Opt: XmlWriteOptions;
        OutS: OutStream;
        InS: InStream;
        S: Text;
        L: Text;
        T: Text;
        V: Integer;
    begin
        Rec.DeleteAll();
        for V := 1 to 4 do begin
            E := XmlElement.Create('r');
            case V of
                2:
                    E.Add(XmlText.Create('a<b>&"c"'));
                3:
                    begin
                        E.Add(XmlElement.Create('a'));
                        E.Add(XmlElement.Create('b', 'urn:b'));
                    end;
                4:
                    begin
                        Doc := XmlDocument.Create();
                        Doc.Add(E);
                        asserterror E.SetAttribute('xmlns:p', 'urn:p');
                        Observer.ObserveError('af309');
                        E.Add(XmlElement.Create('q', 'urn:p'));
                    end;
            end;
            Rec.Init();
            Rec.Id := V;
            Rec.Insert();
            Rec.Data.CreateOutStream(OutS);
            Opt.PreserveWhitespace(true);
            E.WriteTo(Opt, OutS);
            Rec.Modify();
            Rec.CalcFields(Data);
            Clear(InS);
            Rec.Data.CreateInStream(InS);
            T := '';
            while not InS.EOS() do begin
                InS.ReadText(L);
                T += L + '|';
            end;
            Observer.Observe('stream' + Format(V), T);
            E.WriteTo(S);
            Observer.Observe('text' + Format(V), S);
        end;
        Observer.Expect('stream1', 'Ù‹<r />|');
        Observer.Expect('text1', '<r />');
        Observer.Expect('stream2', 'Ù‹<r>a&lt;b&gt;&amp;"c"</r>|');
        Observer.Expect('text2', '<r>a&lt;b&gt;&amp;"c"</r>');
        Observer.Expect('stream3', 'Ù‹<r><a /><b xmlns="urn:b" /></r>|');
        Observer.Expect('text3', '<r>\r\n  <a />\r\n  <b xmlns="urn:b" />\r\n</r>');
        Observer.Expect('af309|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 6.');
        Observer.Expect('af309|code', 'Xml:Xml');
        Observer.Expect('stream4', 'Ù‹<r><q xmlns="urn:p" /></r>|');
        Observer.Expect('text4', '<r>\r\n  <q xmlns="urn:p" />\r\n</r>');
        Observer.Verify();
    end;
}
