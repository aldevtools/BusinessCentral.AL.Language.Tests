// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfromyaml-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), YFN Yaml Support (codeunit 79894), own table 79893 "YFN Yaml Blob"
// Probe: AL Runner issue 8580, runner PR 8824. JsonObject.ReadFromYaml(InStream) with every combination of the
//   encoding the bytes were written with (OutStream) and the encoding of the InStream: MS-DOS (the default), UTF-8, UTF-16
//   and Windows; and the state of the stream before and after the read.
//   Written against local BC 27.5, 28.5 and 29.0 service tiers; every literal asserted below is what those tiers produced.
// Facts: observation 'o-i' is the result for bytes written with encoding o and read with encoding i (m MS-DOS, 8 UTF-8,
//   16 UTF-16, w Windows). ascii: the document 'q: abc' and 'n: 1'; text: a document with U+00E4 and U+20AC.
//   The notation of results is the one of JsonYamlFinalSupport.al.
// BC versions: 27, 28, 29

codeunit 79898 "YFN Yaml Streams"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Y: Codeunit "YFN Yaml Support";

    local procedure Enc(Code: Text): TextEncoding
    begin
        case Code of
            'm':
                exit(TextEncoding::MSDos);
            '8':
                exit(TextEncoding::UTF8);
            '16':
                exit(TextEncoding::UTF16);
            'w':
                exit(TextEncoding::Windows);
        end;
    end;

    local procedure Matrix(Prefix: Text; Src: Text; Expected: Text)
    var
        Codes: List of [Text];
        O: Text;
        I: Text;
    begin
        Codes.AddRange('m', '8', '16', 'w');
        foreach O in Codes do
            foreach I in Codes do
                Observer.Observe(Prefix + O + '-' + I, Y.Stream(Src, Enc(O), Enc(I), Expected));
    end;

    [Test]
    procedure ReadFromYaml_InStreamEncoding_Ascii()
    begin
        Matrix('ascii-', 'q: abc~n: 1', '{"q":"abc","n":"1"}');
        Observer.Expect('ascii-m-m', 'ok');
        Observer.Expect('ascii-m-8', 'ok');
        Observer.Expect('ascii-m-16', 'ok');
        Observer.Expect('ascii-m-w', 'ok');
        Observer.Expect('ascii-8-m', 'ok');
        Observer.Expect('ascii-8-8', 'ok');
        Observer.Expect('ascii-8-16', 'ok');
        Observer.Expect('ascii-8-w', 'ok');
        Observer.Expect('ascii-16-m', 'FYamlBadFormat');
        Observer.Expect('ascii-16-8', 'FYamlBadFormat');
        Observer.Expect('ascii-16-16', 'FYamlBadFormat');
        Observer.Expect('ascii-16-w', 'FYamlBadFormat');
        Observer.Expect('ascii-w-m', 'ok');
        Observer.Expect('ascii-w-8', 'ok');
        Observer.Expect('ascii-w-16', 'ok');
        Observer.Expect('ascii-w-w', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_InStreamEncoding_Text()
    begin
        Matrix('text-', 'q: a{u00E4}b{u20AC}c~n: 1', '{"q":"a{u00E4}b{u20AC}c","n":"1"}');
        Observer.Expect('text-m-m', '{"q":"a<U+FFFD>b<U+FFFD>c","n":"1"}');
        Observer.Expect('text-m-8', '{"q":"a<U+FFFD>b<U+FFFD>c","n":"1"}');
        Observer.Expect('text-m-16', '{"q":"a<U+FFFD>b<U+FFFD>c","n":"1"}');
        Observer.Expect('text-m-w', '{"q":"a<U+FFFD>b<U+FFFD>c","n":"1"}');
        Observer.Expect('text-8-m', 'ok');
        Observer.Expect('text-8-8', 'ok');
        Observer.Expect('text-8-16', 'ok');
        Observer.Expect('text-8-w', 'ok');
        Observer.Expect('text-16-m', 'FYamlBadFormat');
        Observer.Expect('text-16-8', 'FYamlBadFormat');
        Observer.Expect('text-16-16', 'FYamlBadFormat');
        Observer.Expect('text-16-w', 'FYamlBadFormat');
        Observer.Expect('text-w-m', '{"q":"a<U+FFFD>b<U+FFFD>c","n":"1"}');
        Observer.Expect('text-w-8', '{"q":"a<U+FFFD>b<U+FFFD>c","n":"1"}');
        Observer.Expect('text-w-16', '{"q":"a<U+FFFD>b<U+FFFD>c","n":"1"}');
        Observer.Expect('text-w-w', '{"q":"a<U+FFFD>b<U+FFFD>c","n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_InStreamEncoding_Sections()
    begin
        Matrix('sect-', 'q: {u00A7}{u00DF}{u00F1}~n: 1', '{"q":"{u00A7}{u00DF}{u00F1}","n":"1"}');
        Observer.Expect('sect-m-m', '{"q":"\u0015<U+FFFD>","n":"1"}');
        Observer.Expect('sect-m-8', '{"q":"\u0015<U+FFFD>","n":"1"}');
        Observer.Expect('sect-m-16', '{"q":"\u0015<U+FFFD>","n":"1"}');
        Observer.Expect('sect-m-w', '{"q":"\u0015<U+FFFD>","n":"1"}');
        Observer.Expect('sect-8-m', 'ok');
        Observer.Expect('sect-8-8', 'ok');
        Observer.Expect('sect-8-16', 'ok');
        Observer.Expect('sect-8-w', 'ok');
        Observer.Expect('sect-16-m', 'FYamlBadFormat');
        Observer.Expect('sect-16-8', 'FYamlBadFormat');
        Observer.Expect('sect-16-16', 'FYamlBadFormat');
        Observer.Expect('sect-16-w', 'FYamlBadFormat');
        Observer.Expect('sect-w-m', '{"q":"<U+FFFD><U+FFFD><U+FFFD>","n":"1"}');
        Observer.Expect('sect-w-8', '{"q":"<U+FFFD><U+FFFD><U+FFFD>","n":"1"}');
        Observer.Expect('sect-w-16', '{"q":"<U+FFFD><U+FFFD><U+FFFD>","n":"1"}');
        Observer.Expect('sect-w-w', '{"q":"<U+FFFD><U+FFFD><U+FFFD>","n":"1"}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_InStream_State()
    var
        Blob: Record "YFN Yaml Blob";
        OutS: OutStream;
        InS: InStream;
        JO: JsonObject;
        JO2: JsonObject;
        Line: Text;
        Ok: Boolean;
        Out: Text;
    begin
        Blob.DeleteAll();
        Blob.Id := 1;
        Blob.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('skip: me');
        OutS.WriteText();
        OutS.WriteText('q: abc');
        OutS.WriteText();
        OutS.WriteText('n: 1');
        Blob.Insert();
        Blob.CalcFields(Data);

        // a read of the whole stream, then the position
        Blob.Data.CreateInStream(InS, TextEncoding::UTF8);
        Ok := JO.ReadFromYaml(InS);
        JO.WriteTo(Out);
        Observer.Observe('whole-read', Format(Ok) + ' ' + Out);
        Observer.Observe('whole-eos', Format(InS.EOS()));
        Observer.Observe('whole-length', Format(InS.Length()));
        Observer.Observe('whole-pos', Format(InS.Position()));
        Clear(Line);
        InS.ReadText(Line);
        Observer.Observe('whole-readtext-after', Y.Esc(Line));
        Clear(JO2);
        ClearLastError();
        Ok := JO2.ReadFromYaml(InS);
        JO2.WriteTo(Out);
        Observer.Observe('whole-second-read', Format(Ok) + ' ' + Y.Esc(Out) + ' ' + Y.Esc(GetLastErrorText()));
        Observer.Observe('whole-second-pos', Format(InS.Position()));
        Observer.Observe('whole-second-eos', Format(InS.EOS()));
        InS.ResetPosition();
        Clear(JO2);
        ClearLastError();
        Ok := JO2.ReadFromYaml(InS);
        JO2.WriteTo(Out);
        Observer.Observe('whole-after-reset', Format(Ok) + ' ' + Y.Esc(Out) + ' ' + Y.Esc(GetLastErrorText()));

        // a stream read up to the second line first
        ClearLastError();
        Blob.Data.CreateInStream(InS, TextEncoding::UTF8);
        InS.ReadText(Line);
        Observer.Observe('partial-first-line', Y.Esc(Line));
        Clear(JO);
        Ok := JO.ReadFromYaml(InS);
        JO.WriteTo(Out);
        Observer.Observe('partial-read', Format(Ok) + ' ' + Y.Esc(Out));
        Observer.Observe('partial-eos', Format(InS.EOS()));
        Observer.Observe('partial-pos', Format(InS.Position()));

        // an empty stream (a fresh record: the variable no longer holds the old blob)
        Blob.DeleteAll();
        Clear(Blob);
        Blob.Id := 1;
        Blob.Insert();
        Blob.CalcFields(Data);
        Blob.Data.CreateInStream(InS, TextEncoding::UTF8);
        Clear(JO);
        ClearLastError();
        Ok := JO.ReadFromYaml(InS);
        JO.WriteTo(Out);
        Observer.Observe('empty-stream', Format(Ok) + ' ' + Y.Esc(Out) + ' ' + Y.Esc(GetLastErrorText()) + ' ' + GetLastErrorCode());
        Blob.DeleteAll();
        Observer.Expect('whole-read', 'Yes {"skip":"me","q":"abc","n":"1"}');
        Observer.Expect('whole-eos', 'No');
        Observer.Expect('whole-length', '22');
        Observer.Expect('whole-pos', '1');
        Observer.Expect('whole-readtext-after', 'skip: me');
        Observer.Expect('whole-second-read', 'Yes {"q":"abc","n":"1"} ');
        Observer.Expect('whole-second-pos', '11');
        Observer.Expect('whole-second-eos', 'No');
        Observer.Expect('whole-after-reset', 'Yes {"skip":"me","q":"abc","n":"1"} ');
        Observer.Expect('partial-first-line', 'skip: me');
        Observer.Expect('partial-read', 'Yes {"q":"abc","n":"1"}');
        Observer.Expect('partial-eos', 'No');
        Observer.Expect('partial-pos', '11');
        Observer.Expect('empty-stream', 'No {} JSON tokens of type ''Null'' are not supported by this implementation. InvalidJsonType');
        Observer.Verify();
    end;
}
