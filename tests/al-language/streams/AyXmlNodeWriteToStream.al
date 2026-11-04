// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmltext/xmltext-writeto-outstream-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 80502
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: XmlText, XmlCData, XmlComment (and for comparison XmlElement and XmlDocument) WriteTo(OutStream) on a stream that already holds text from
// OutStream.WriteText, followed by another WriteText: the bytes of the stream (base64) and the text read back; UTF-8 and UTF-16 streams.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 80502 "LT AY Xml Node WriteTo Stream"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Bytes(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Base64: Codeunit "Base64 Convert";
    begin
        TempBlob.CreateInStream(InS);
        exit(Format(TempBlob.Length()) + ':' + Base64.ToBase64(InS));
    end;

    local procedure Content(var TempBlob: Codeunit "Temp Blob"; Enc: TextEncoding): Text
    var
        InS: InStream;
        Line: Text;
        All: Text;
    begin
        TempBlob.CreateInStream(InS, Enc);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            All += Line + '|';
        end;
        exit(All);
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Integer; Enc: TextEncoding)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Doc: XmlDocument;
        TextNode: XmlText;
        CDataNode: XmlCData;
        CommentNode: XmlComment;
        Element: XmlElement;
    begin
        TempBlob.CreateOutStream(OutS, Enc);
        OutS.WriteText('pre<');
        case Kind of
            1:
                begin
                    TextNode := XmlText.Create('a<b&c');
                    TextNode.WriteTo(OutS);
                end;
            2:
                begin
                    CDataNode := XmlCData.Create('a<b&c');
                    CDataNode.WriteTo(OutS);
                end;
            3:
                begin
                    CommentNode := XmlComment.Create(' note ');
                    CommentNode.WriteTo(OutS);
                end;
            4:
                begin
                    Element := XmlElement.Create('e');
                    Element.Add(XmlText.Create('x'));
                    Element.WriteTo(OutS);
                end;
            5:
                begin
                    XmlDocument.ReadFrom('<r>x</r>', Doc);
                    Doc.WriteTo(OutS);
                end;
        end;
        OutS.WriteText('>post');
        Observer.Observe(Name + '_bytes', Bytes(TempBlob));
        Observer.Observe(Name + '_text', Content(TempBlob, Enc));
    end;

    [Test]
    procedure NodeWriteTo_AfterWriteText_Utf8_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'text', 1, TextEncoding::UTF8);
        Run(Observer, 'cdata', 2, TextEncoding::UTF8);
        Observer.Expect('text_bytes', '16:cHJlPD5wb3N0YiZhbXA7Yw==');
        Observer.Expect('text_text', 'pre<>postb&amp;c|');
        Observer.Expect('cdata_bytes', '21:cHJlPD5wb3N0QVRBW2E8YiZjXV0+');
        Observer.Expect('cdata_text', 'pre<>postATA[a<b&c]]>|');
        Observer.Verify();
    end;

    [Test]
    procedure NodeWriteTo_AfterWriteText_Utf8_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'comment', 3, TextEncoding::UTF8);
        Run(Observer, 'element', 4, TextEncoding::UTF8);
        Observer.Expect('comment_bytes', '17:cHJlPD5wb3N0bm90ZSAtLT4=');
        Observer.Expect('comment_text', 'pre<>postnote -->|');
        Observer.Expect('element_bytes', '12:cHJlPD5wb3N0L2U+');
        Observer.Expect('element_text', 'pre<>post/e>|');
        Observer.Verify();
    end;

    [Test]
    procedure NodeWriteTo_AfterWriteText_Utf8_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'document', 5, TextEncoding::UTF8);
        Observer.Expect('document_bytes', '52:cHJlPD5wb3N0IHZlcnNpb249IjEuMCIgZW5jb2Rpbmc9InV0Zi04Ij8+DQo8cj54PC9yPg==');
        Observer.Expect('document_text', 'pre<>post version="1.0" encoding="utf-8"?>|<r>x</r>|');
        Observer.Verify();
    end;

    [Test]
    procedure NodeWriteTo_AfterWriteText_Utf16_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'text16', 1, TextEncoding::UTF16);
        Run(Observer, 'cdata16', 2, TextEncoding::UTF16);
        Observer.Expect('text16_bytes', '20:cAByAGUAPAA+AHAAbwBzAHQAO2M=');
        Observer.Expect('text16_text', 'pre<>post挻|');
        Observer.Expect('cdata16_bytes', '25:cAByAGUAPAA+AHAAbwBzAHQAPGImY11dPg==');
        Observer.Expect('cdata16_text', 'pre<>post戼挦嵝|');
        Observer.Verify();
    end;

    [Test]
    procedure NodeWriteTo_AfterWriteText_Utf16_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 'comment16', 3, TextEncoding::UTF16);
        Observer.Expect('comment16_bytes', '21:cAByAGUAPAA+AHAAbwBzAHQALS0+');
        Observer.Expect('comment16_text', 'pre<>postⴭ|');
        Observer.Verify();
    end;
}
