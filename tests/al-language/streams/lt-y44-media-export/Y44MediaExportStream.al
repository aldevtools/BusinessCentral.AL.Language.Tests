// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-exportstream-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Base App table "Document Attachment" (1173) and its ImportAttachment / ExportToStream (the
//        four-argument Media.ImportStream with a file name compiles only inside Microsoft's apps); self-contained objects 92865-92866
// Probe: gap cycle 4, spec G4-18. The bytes Media.ExportStream gives for UTF-8 text imported with a file name (.txt, no extension,
//        .pdf), non-ASCII text, a re-import of the export, text imported with a MIME type, a PNG picture and binary non-picture bytes.
//        Already pinned nearby: streams/StTMedia.al TR_MediaImportStream_TextContent_ExportStream (two-argument import of text),
//        types/W7Media.al ExportStream_OfAnImportedPicture (PNG length 99, first bytes on BC 29).
// BC versions: 27, 28, 29

table 92866 "LT Y44 Media Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Pic; Media) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 92865 "LT Y44 Media ExportStream"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        AsciiTxt: Label 'Test content for attachment ABC123xyz0', Locked = true;
        PngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;

    local procedure TextStream(Content: Text; var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
    end;

    local procedure PngStream(var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64(PngBase64, OutS);
        TempBlob.CreateInStream(InS);
    end;

    local procedure BinaryStream(var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        OutS: OutStream;
        B: Byte;
        I: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        for I := 0 to 15 do begin
            B := I;
            OutS.Write(B);
        end;
        TempBlob.CreateInStream(InS);
    end;

    local procedure ObserveBytes(Name: Text; var Exported: Codeunit "Temp Blob"; WithText: Boolean)
    var
        Base64: Codeunit "Base64 Convert";
        InS: InStream;
        T: Text;
    begin
        Observer.Observe('len_' + Name, Format(Exported.Length()));
        Exported.CreateInStream(InS);
        Observer.Observe('b64_' + Name, Base64.ToBase64(InS));
        if WithText then begin
            Exported.CreateInStream(InS, TextEncoding::UTF8);
            InS.ReadText(T);
            Observer.Observe('readtext_' + Name, T);
        end;
    end;

    local procedure NewAttachment(var DocumentAttachment: Record "Document Attachment"; No: Code[20]; FileName: Text; var InS: InStream)
    begin
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::"Document Attachment";
        DocumentAttachment."No." := No;
        DocumentAttachment."File Name" := CopyStr(FileName, 1, 250);
        DocumentAttachment.Insert(false);
        DocumentAttachment.ImportAttachment(InS, FileName);
        DocumentAttachment.Modify(false);
    end;

    [TryFunction]
    local procedure TryAttachAndExport(No: Code[20]; FileName: Text; var InS: InStream; var Exported: Codeunit "Temp Blob")
    var
        DocumentAttachment: Record "Document Attachment";
        OutS: OutStream;
    begin
        NewAttachment(DocumentAttachment, No, FileName, InS);
        Exported.CreateOutStream(OutS);
        DocumentAttachment.ExportToStream(OutS);
    end;

    local procedure AttachCase(Name: Text; No: Code[20]; FileName: Text; var InS: InStream; WithText: Boolean)
    var
        Exported: Codeunit "Temp Blob";
    begin
        ClearLastError();
        if TryAttachAndExport(No, FileName, InS, Exported) then
            ObserveBytes(Name, Exported, WithText)
        else
            Observer.ObserveError('err_' + Name);
    end;

    local procedure CleanAttachments()
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", Database::"Document Attachment");
        DocumentAttachment.SetFilter("No.", 'LTY44*');
        DocumentAttachment.DeleteAll(false);
    end;

    [Test]
    procedure DocAttach_TextTxt_ExportStream()
    var
        Source: Codeunit "Temp Blob";
        InS: InStream;
    begin
        CleanAttachments();
        TextStream(AsciiTxt, Source, InS);
        AttachCase('txt', 'LTY44A', 'TestFile_A.txt', InS, true);
        CleanAttachments();
        Observer.Finish();
    end;

    [Test]
    procedure DocAttach_TextTxt_RoundTrip()
    var
        Source: Codeunit "Temp Blob";
        First: Codeunit "Temp Blob";
        Second: Codeunit "Temp Blob";
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachment2: Record "Document Attachment";
        InS: InStream;
        OutS: OutStream;
    begin
        CleanAttachments();
        TextStream(AsciiTxt, Source, InS);
        NewAttachment(DocumentAttachment, 'LTY44A', 'TestFile_A.txt', InS);
        First.CreateOutStream(OutS);
        DocumentAttachment.ExportToStream(OutS);
        ObserveBytes('first', First, false);
        First.CreateInStream(InS);
        NewAttachment(DocumentAttachment2, 'LTY44B', 'TestFile_B.txt', InS);
        Second.CreateOutStream(OutS);
        DocumentAttachment2.ExportToStream(OutS);
        ObserveBytes('second', Second, true);
        CleanAttachments();
        Observer.Finish();
    end;

    local procedure OwnCase(Name: Text; var InS: InStream; Mime: Text; UseMime: Boolean; WithText: Boolean)
    var
        Row: Record "LT Y44 Media Row";
        Exported: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        if UseMime then
            Row.Pic.ImportStream(InS, 'd', Mime)
        else
            Row.Pic.ImportStream(InS, 'd');
        Row.Insert();
        Row.Get(1);
        Exported.CreateOutStream(OutS);
        Observer.Observe('answer_' + Name, Format(Row.Pic.ExportStream(OutS)));
        ObserveBytes(Name, Exported, WithText);
    end;

    [Test]
    procedure Media_TextWithMime_ExportStream()
    var
        Source: Codeunit "Temp Blob";
        InS: InStream;
    begin
        TextStream(AsciiTxt, Source, InS);
        OwnCase('mime_textplain', InS, 'text/plain', true, true);
        TextStream(AsciiTxt, Source, InS);
        OwnCase('mime_empty', InS, '', true, true);
        Observer.Finish();
    end;

    [Test]
    procedure DocAttach_NonAscii_And_NoExtension()
    var
        Source: Codeunit "Temp Blob";
        InS: InStream;
    begin
        CleanAttachments();
        TextStream('Ä€ line', Source, InS);
        AttachCase('nonascii_txt', 'LTY44C', 'X.txt', InS, true);
        TextStream(AsciiTxt, Source, InS);
        AttachCase('noext', 'LTY44D', 'X', InS, true);
        TextStream(AsciiTxt, Source, InS);
        AttachCase('pdf', 'LTY44E', 'X.pdf', InS, true);
        CleanAttachments();
        Observer.Finish();
    end;

    [Test]
    procedure DocAttach_Png_ExportStream()
    var
        Source: Codeunit "Temp Blob";
        InS: InStream;
    begin
        CleanAttachments();
        PngStream(Source, InS);
        AttachCase('png_attach', 'LTY44F', 'pic.png', InS, false);
        PngStream(Source, InS);
        OwnCase('png_own', InS, '', false, false);
        CleanAttachments();
        Observer.Finish();
    end;

    [Test]
    procedure Media_Binary_ExportStream()
    var
        Source: Codeunit "Temp Blob";
        InS: InStream;
    begin
        BinaryStream(Source, InS);
        OwnCase('binary', InS, '', false, false);
        Observer.Finish();
    end;
}
