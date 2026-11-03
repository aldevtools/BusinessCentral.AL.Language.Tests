// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlattribute/xmlattribute-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 74800
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlAttribute WriteTo(Text), WriteTo(WriteOptions, Text), WriteTo(OutStream), WriteTo(WriteOptions, OutStream) for plain, escaped, namespaced, empty and unicode values
// BC versions: 29 (27 and 28 by CI)

codeunit 74805 "LT P97 Attr WriteTo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Attr(Kind: Integer): XmlAttribute
    var
        A: XmlAttribute;
        Q: Text[1];
    begin
        Q[1] := 39;
        case Kind of
            1:
                A := XmlAttribute.Create('a', 'plain');
            2:
                A := XmlAttribute.Create('a', '');
            3:
                A := XmlAttribute.Create('a', '<&>"' + Q);
            4:
                A := XmlAttribute.Create('a', 'x' + Q + 'y' + Q + Q);
            5:
                A := XmlAttribute.Create('a', 'urn:n', 'v');
            6:
                A := XmlAttribute.Create('a', 'urn:other', 'w');
            7:
                A := XmlAttribute.CreateNamespaceDeclaration('n', 'urn:n');
            8:
                A := XmlAttribute.Create('a', 'urn:n', '');
            9:
                A := XmlAttribute.Create('a', ' lead and  double  space ');
            10:
                A := XmlAttribute.Create('a', 'caf' + 'é' + ' ' + '日本');
        end;
        exit(A);
    end;

    local procedure NlAttr(): XmlAttribute
    var
        Lf: Text[1];
        Tb: Text[1];
    begin
        Lf[1] := 10;
        Tb[1] := 9;
        exit(XmlAttribute.Create('a', 'l1' + Lf + 'l2' + Tb + 'l3'));
    end;

    local procedure ReadBack(var Rec: Record "LT P97 Blob"; var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        InS: InStream;
        T: Text;
    begin
        Rec.CalcFields(Data);
        Observer.Observe(Name + '_len', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(InS);
        if Rec.Data.Length() > 0 then
            InS.ReadText(T);
        Observer.Observe(Name + '_text', T);
        if StrLen(T) > 0 then
            Observer.Observe(Name + '_first', Format(T[1]));
    end;

    [Test]
    procedure WriteTo_Text_Kinds()
    var
        Observer: Codeunit "Probe Observer";
        A: XmlAttribute;
        S: Text;
        Kind: Integer;
    begin
        for Kind := 1 to 10 do begin
            A := Attr(Kind);
            S := 'untouched';
            Observer.Observe('r' + Format(Kind), Format(A.WriteTo(S)));
            Observer.Observe('t' + Format(Kind), S);
        end;
        A := NlAttr();
        A.WriteTo(S);
        Observer.Observe('newline_tab', S);
        Observer.Expect('r1', 'Yes');
        Observer.Expect('t1', 'a="plain"');
        Observer.Expect('r2', 'Yes');
        Observer.Expect('t2', 'a=""');
        Observer.Expect('r3', 'Yes');
        Observer.Expect('t3', 'a="&lt;&amp;&gt;&quot;''"');
        Observer.Expect('r4', 'Yes');
        Observer.Expect('t4', 'a="x''y''''"');
        Observer.Expect('r5', 'Yes');
        Observer.Expect('t5', 'p0:a="v"');
        Observer.Expect('r6', 'Yes');
        Observer.Expect('t6', 'p0:a="w"');
        Observer.Expect('r7', 'Yes');
        Observer.Expect('t7', 'xmlns:n="urn:n"');
        Observer.Expect('r8', 'Yes');
        Observer.Expect('t8', 'p0:a=""');
        Observer.Expect('r9', 'Yes');
        Observer.Expect('t9', 'a=" lead and  double  space "');
        Observer.Expect('r10', 'Yes');
        Observer.Expect('t10', 'a="café 日本"');
        Observer.Expect('newline_tab', 'a="l1&#xA;l2&#x9;l3"');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_TextOptions()
    var
        Observer: Codeunit "Probe Observer";
        A: XmlAttribute;
        Opt: XmlWriteOptions;
        S: Text;
        Kind: Integer;
    begin
        for Kind := 1 to 10 do begin
            A := Attr(Kind);
            S := 'untouched';
            Opt.PreserveWhitespace(true);
            A.WriteTo(Opt, S);
            Observer.Observe('keep' + Format(Kind), S);
            Opt.PreserveWhitespace(false);
            A.WriteTo(Opt, S);
            Observer.Observe('drop' + Format(Kind), S);
        end;
        Observer.Expect('keep1', 'a="plain"');
        Observer.Expect('drop1', 'a="plain"');
        Observer.Expect('keep2', 'a=""');
        Observer.Expect('drop2', 'a=""');
        Observer.Expect('keep3', 'a="&lt;&amp;&gt;&quot;''"');
        Observer.Expect('drop3', 'a="&lt;&amp;&gt;&quot;''"');
        Observer.Expect('keep4', 'a="x''y''''"');
        Observer.Expect('drop4', 'a="x''y''''"');
        Observer.Expect('keep5', 'p0:a="v"');
        Observer.Expect('drop5', 'p0:a="v"');
        Observer.Expect('keep6', 'p0:a="w"');
        Observer.Expect('drop6', 'p0:a="w"');
        Observer.Expect('keep7', 'xmlns:n="urn:n"');
        Observer.Expect('drop7', 'xmlns:n="urn:n"');
        Observer.Expect('keep8', 'p0:a=""');
        Observer.Expect('drop8', 'p0:a=""');
        Observer.Expect('keep9', 'a=" lead and  double  space "');
        Observer.Expect('drop9', 'a=" lead and  double  space "');
        Observer.Expect('keep10', 'a="café 日本"');
        Observer.Expect('drop10', 'a="café 日本"');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P97 Blob";
        A: XmlAttribute;
        OutS: OutStream;
        Kind: Integer;
    begin
        Rec.DeleteAll();
        for Kind := 1 to 6 do begin
            Rec.Init();
            Rec.Id := Kind;
            Rec.Insert();
            A := Attr(Kind);
            Rec.Data.CreateOutStream(OutS);
            Observer.Observe('r' + Format(Kind), Format(A.WriteTo(OutS)));
            Rec.Modify();
            ReadBack(Rec, Observer, 'k' + Format(Kind));
        end;
        Observer.Expect('r1', 'Yes');
        Observer.Expect('k1_len', '9');
        Observer.Expect('k1_text', 'a="plain"');
        Observer.Expect('k1_first', 'a');
        Observer.Expect('r2', 'Yes');
        Observer.Expect('k2_len', '4');
        Observer.Expect('k2_text', 'a=""');
        Observer.Expect('k2_first', 'a');
        Observer.Expect('r3', 'Yes');
        Observer.Expect('k3_len', '24');
        Observer.Expect('k3_text', 'a="&lt;&amp;&gt;&quot;''"');
        Observer.Expect('k3_first', 'a');
        Observer.Expect('r4', 'Yes');
        Observer.Expect('k4_len', '9');
        Observer.Expect('k4_text', 'a="x''y''''"');
        Observer.Expect('k4_first', 'a');
        Observer.Expect('r5', 'Yes');
        Observer.Expect('k5_len', '8');
        Observer.Expect('k5_text', 'p0:a="v"');
        Observer.Expect('k5_first', 'p');
        Observer.Expect('r6', 'Yes');
        Observer.Expect('k6_len', '8');
        Observer.Expect('k6_text', 'p0:a="w"');
        Observer.Expect('k6_first', 'p');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStreamOptions()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P97 Blob";
        A: XmlAttribute;
        Opt: XmlWriteOptions;
        OutS: OutStream;
    begin
        Rec.DeleteAll();
        A := XmlAttribute.Create('a', ' two  spaces ');
        Rec.Id := 1;
        Rec.Insert();
        Opt.PreserveWhitespace(true);
        Rec.Data.CreateOutStream(OutS);
        Observer.Observe('keep', Format(A.WriteTo(Opt, OutS)));
        Rec.Modify();
        ReadBack(Rec, Observer, 'keep');
        Rec.Id := 2;
        Rec.Insert();
        Opt.PreserveWhitespace(false);
        Rec.Data.CreateOutStream(OutS);
        Observer.Observe('drop', Format(A.WriteTo(Opt, OutS)));
        Rec.Modify();
        ReadBack(Rec, Observer, 'drop');
        Observer.Expect('keep', 'Yes');
        Observer.Expect('keep_len', '17');
        Observer.Expect('keep_text', 'a=" two  spaces "');
        Observer.Expect('keep_first', 'a');
        Observer.Expect('drop', 'Yes');
        Observer.Expect('drop_len', '17');
        Observer.Expect('drop_text', 'a=" two  spaces "');
        Observer.Expect('drop_first', 'a');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OutStream_AppendsToStream()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P97 Blob";
        A: XmlAttribute;
        B: XmlAttribute;
        OutS: OutStream;
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        A := XmlAttribute.Create('a', '1');
        B := XmlAttribute.Create('b', '2');
        Rec.Data.CreateOutStream(OutS);
        A.WriteTo(OutS);
        B.WriteTo(OutS);
        Rec.Modify();
        ReadBack(Rec, Observer, 'two');
        Observer.Expect('two_len', '10');
        Observer.Expect('two_text', 'a="1"b="2"');
        Observer.Expect('two_first', 'a');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_Detached_And_Removed()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        X: XmlAttribute;
        S: Text;
    begin
        Root := XmlElement.Create('r');
        Root.SetAttribute('x', 'v');
        Root.Attributes().Get('x', X);
        X.WriteTo(S);
        Observer.Observe('attached', S);
        X.Remove();
        X.WriteTo(S);
        Observer.Observe('removed', S);
        Observer.Expect('attached', 'x="v"');
        Observer.Expect('removed', 'x="v"');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_AsXmlNode_Equivalence()
    var
        Observer: Codeunit "Probe Observer";
        A: XmlAttribute;
        N: XmlNode;
        S1: Text;
        S2: Text;
        Kind: Integer;
    begin
        for Kind := 1 to 10 do begin
            A := Attr(Kind);
            A.WriteTo(S1);
            N := A.AsXmlNode();
            N.WriteTo(S2);
            Observer.Observe('same' + Format(Kind), Format(S1 = S2));
        end;
        Observer.Expect('same1', 'Yes');
        Observer.Expect('same2', 'Yes');
        Observer.Expect('same3', 'Yes');
        Observer.Expect('same4', 'Yes');
        Observer.Expect('same5', 'Yes');
        Observer.Expect('same6', 'Yes');
        Observer.Expect('same7', 'Yes');
        Observer.Expect('same8', 'Yes');
        Observer.Expect('same9', 'Yes');
        Observer.Expect('same10', 'Yes');
        Observer.Verify();
    end;
}
