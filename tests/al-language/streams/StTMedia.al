// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-data-type
// Scope: in-scope
// Fixtures used: table 74200, codeunit 69160 "Probe Observer", System Application "Base64 Convert" and "Temp Blob"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74204 "LT StT Media"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fresh(var Rec: Record "LT StT Rec")
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
    end;

    // a valid 1x1 png
    local procedure PngIn(var TempBlob: Codeunit "Temp Blob"; var Ins: InStream)
    var
        Base64: Codeunit "Base64 Convert";
        Out: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(Out);
        Base64.FromBase64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', Out);
        TempBlob.CreateInStream(Ins);
    end;

    [Test]
    procedure MediaEmpty()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        Fresh(Rec);
        Observer.Observe('hasvalue', Format(Rec.Pic.HasValue()));
        Id := Rec.Pic.MediaId();
        Observer.Observe('mediaid-null', Format(IsNullGuid(Id)));
        Observer.Expect('hasvalue', 'No');
        Observer.Expect('mediaid-null', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MediaImportStreamTwoArgs()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        Id: Guid;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        Id := Rec.Pic.ImportStream(Ins, 'desc');
        Observer.Observe('returned-null', Format(IsNullGuid(Id)));
        Observer.Observe('hasvalue-before-modify', Format(Rec.Pic.HasValue()));
        Rec.Modify();
        Observer.Observe('hasvalue-after-modify', Format(Rec.Pic.HasValue()));
        Observer.Observe('mediaid-equals-returned', Format(Rec.Pic.MediaId() = Id));
        Observer.Expect('returned-null', 'No');
        Observer.Expect('hasvalue-before-modify', 'Yes');
        Observer.Expect('hasvalue-after-modify', 'Yes');
        Observer.Expect('mediaid-equals-returned', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MediaImportStreamThreeArgs()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        Id: Guid;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        Id := Rec.Pic.ImportStream(Ins, 'desc', 'image/png');
        Observer.Observe('returned-null', Format(IsNullGuid(Id)));
        Rec.Modify();
        Observer.Observe('hasvalue', Format(Rec.Pic.HasValue()));
        Observer.Observe('mediaid-equals-returned', Format(Rec.Pic.MediaId() = Id));
        Observer.Expect('returned-null', 'No');
        Observer.Expect('hasvalue', 'Yes');
        Observer.Expect('mediaid-equals-returned', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MediaImportEmptyDescription()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        Id: Guid;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        Id := Rec.Pic.ImportStream(Ins, '');
        Rec.Modify();
        Observer.Observe('hasvalue', Format(Rec.Pic.HasValue()));
        Observer.Observe('null', Format(IsNullGuid(Id)));
        Observer.Expect('hasvalue', 'Yes');
        Observer.Expect('null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure MediaImportEmptyStream()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        Id: Guid;
    begin
        Fresh(Rec);
        TempBlob.CreateInStream(Ins);
        Id := Rec.Pic.ImportStream(Ins, 'empty');
        Observer.Observe('import-empty', 'no error');
        Observer.Observe('hasvalue', Format(Rec.Pic.HasValue()));
        Observer.Expect('import-empty', 'no error');
        Observer.Expect('hasvalue', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure MediaImportNonImageStream()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        Id: Guid;
    begin
        Fresh(Rec);
        TempBlob.CreateOutStream(Out);
        Out.WriteText('this is not an image');
        TempBlob.CreateInStream(Ins);
        Id := Rec.Pic.ImportStream(Ins, 'text');
        Rec.Modify();
        Observer.Observe('hasvalue', Format(Rec.Pic.HasValue()));
        Observer.Expect('hasvalue', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MediaExportStream()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        Out: OutStream;
        Ok: Boolean;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        Rec.Pic.ImportStream(Ins, 'desc', 'image/png');
        Rec.Modify();
        TempBlob2.CreateOutStream(Out);
        Rec.Pic.ExportStream(Out);
        Observer.Observe('original-len', Format(TempBlob.Length()));
        Observer.Expect('original-len', '70');
        Observer.Verify();
    end;

    [Test]
    procedure MediaExportStreamEmpty()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
    begin
        Fresh(Rec);
        TempBlob.CreateOutStream(Out);
        Rec.Pic.ExportStream(Out);
        Observer.Observe('export-empty', 'no error');
        Observer.Observe('len', Format(TempBlob.Length()));
        Observer.Expect('export-empty', 'no error');
        Observer.Expect('len', '0');
        Observer.Verify();
    end;

    [Test]
    procedure MediaExportAfterReload()
    var
        Rec: Record "LT StT Rec";
        Rec2: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        Out: OutStream;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        Rec.Pic.ImportStream(Ins, 'desc', 'image/png');
        Rec.Modify();
        Rec2.Get(1);
        Observer.Observe('hasvalue', Format(Rec2.Pic.HasValue()));
        Observer.Observe('mediaid-equal', Format(Rec2.Pic.MediaId() = Rec.Pic.MediaId()));
        TempBlob2.CreateOutStream(Out);
        Rec2.Pic.ExportStream(Out);
        Observer.Expect('hasvalue', 'Yes');
        Observer.Expect('mediaid-equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MediaReimportReplaces()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        First: Guid;
        Second: Guid;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        First := Rec.Pic.ImportStream(Ins, 'one');
        Rec.Modify();
        PngIn(TempBlob, Ins);
        Second := Rec.Pic.ImportStream(Ins, 'two');
        Rec.Modify();
        Observer.Observe('ids-differ', Format(First <> Second));
        Observer.Observe('current-is-second', Format(Rec.Pic.MediaId() = Second));
        Observer.Expect('ids-differ', 'Yes');
        Observer.Expect('current-is-second', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure MediaClearFieldAndTwoFields()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        Rec.Pic.ImportStream(Ins, 'one');
        Rec.Modify();
        Observer.Observe('pic', Format(Rec.Pic.HasValue()));
        Observer.Observe('pic2', Format(Rec.Pic2.HasValue()));
        Observer.Observe('ids-differ', Format(Rec.Pic.MediaId() <> Rec.Pic2.MediaId()));
        Clear(Rec.Pic);
        Observer.Observe('pic-after-clear', Format(Rec.Pic.HasValue()));
        Rec.Modify();
        Observer.Observe('pic-after-modify', Format(Rec.Pic.HasValue()));
        Observer.Expect('pic', 'Yes');
        Observer.Expect('pic2', 'No');
        Observer.Expect('ids-differ', 'Yes');
        Observer.Expect('pic-after-clear', 'No');
        Observer.Expect('pic-after-modify', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure MediaOnTemporaryRecord()
    var
        Temp: Record "LT StT Rec" temporary;
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        Id: Guid;
    begin
        Temp.Init();
        Temp.Id := 1;
        Temp.Insert();
        PngIn(TempBlob, Ins);
        Id := Temp.Pic.ImportStream(Ins, 'tmp');
        Observer.Observe('temp-import', 'no error');
        Observer.Expect('temp-import', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSetEmpty()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
    begin
        Fresh(Rec);
        Observer.Observe('count', Format(Rec.Pics.Count()));
        asserterror Observer.Observe('item1', Format(IsNullGuid(Rec.Pics.Item(1))));
        Observer.ObserveError('item1');
        asserterror Observer.Observe('item0', Format(IsNullGuid(Rec.Pics.Item(0))));
        Observer.ObserveError('item0');
        Observer.Expect('count', '0');
        Observer.Expect('item1|text', 'Argument was out of range: index.');
        Observer.Expect('item1|code', 'ArgumentOutOfRange');
        Observer.Expect('item0|text', 'The parameter index must have a value greater than zero.');
        Observer.Expect('item0|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSetImportStream()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        Id: Guid;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        Id := Rec.Pics.ImportStream(Ins, 'one');
        Observer.Observe('returned-null', Format(IsNullGuid(Id)));
        Observer.Observe('count-before-modify', Format(Rec.Pics.Count()));
        Rec.Modify();
        Observer.Observe('count', Format(Rec.Pics.Count()));
        Observer.Observe('item1-is-returned', Format(Rec.Pics.Item(1) = Id));
        Observer.Observe('mediasetid-null', Format(IsNullGuid(Rec.Pics.MediaId())));
        Observer.Expect('returned-null', 'No');
        Observer.Expect('count-before-modify', '1');
        Observer.Expect('count', '1');
        Observer.Expect('item1-is-returned', 'No');
        Observer.Expect('mediasetid-null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSetImportThreeArgs()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        Id: Guid;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        Id := Rec.Pics.ImportStream(Ins, 'one', 'image/png');
        Rec.Modify();
        Observer.Observe('count', Format(Rec.Pics.Count()));
        PngIn(TempBlob, Ins);
        Id := Rec.Pics.ImportStream(Ins, 'two', 'image/png');
        Rec.Modify();
        Observer.Observe('count2', Format(Rec.Pics.Count()));
        Observer.Expect('count', '1');
        Observer.Expect('count2', '2');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSetImportTwiceAdds()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        A: Guid;
        B: Guid;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        A := Rec.Pics.ImportStream(Ins, 'one');
        PngIn(TempBlob, Ins);
        B := Rec.Pics.ImportStream(Ins, 'two');
        Rec.Modify();
        Observer.Observe('count', Format(Rec.Pics.Count()));
        Observer.Observe('ids-differ', Format(A <> B));
        Observer.Observe('item1-is-a', Format(Rec.Pics.Item(1) = A));
        Observer.Observe('item2-is-b', Format(Rec.Pics.Item(2) = B));
        asserterror Observer.Observe('item3', Format(Rec.Pics.Item(3) = A));
        Observer.ObserveError('item3');
        asserterror Observer.Observe('item0', Format(Rec.Pics.Item(0) = A));
        Observer.ObserveError('item0');
        Observer.Expect('count', '2');
        Observer.Expect('ids-differ', 'No');
        Observer.Expect('item1-is-a', 'No');
        Observer.Expect('item2-is-b', 'No');
        Observer.Expect('item3|text', 'Argument was out of range: index.');
        Observer.Expect('item3|code', 'ArgumentOutOfRange');
        Observer.Expect('item0|text', 'The parameter index must have a value greater than zero.');
        Observer.Expect('item0|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSetInsertRemove()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        A: Guid;
        B: Guid;
        Removed: Boolean;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        A := Rec.Pic.ImportStream(Ins, 'media');
        Rec.Modify();
        Rec.Pics.Insert(A);
        Observer.Observe('count-after-insert', Format(Rec.Pics.Count()));
        Rec.Modify();
        Observer.Observe('count-after-modify', Format(Rec.Pics.Count()));
        Observer.Observe('item1-is-a', Format(Rec.Pics.Item(1) = A));
        Removed := Rec.Pics.Remove(A);
        Observer.Observe('removed', Format(Removed));
        Observer.Observe('count-after-remove', Format(Rec.Pics.Count()));
        Removed := Rec.Pics.Remove(A);
        Observer.Observe('removed-again', Format(Removed));
        Removed := Rec.Pics.Remove(B);
        Observer.Observe('removed-null', Format(Removed));
        Observer.Expect('count-after-insert', '1');
        Observer.Expect('count-after-modify', '1');
        Observer.Expect('item1-is-a', 'Yes');
        Observer.Expect('removed', 'Yes');
        Observer.Expect('count-after-remove', '0');
        Observer.Expect('removed-again', 'No');
        Observer.Expect('removed-null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSetInsertNullAndUnknown()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Null: Guid;
        Unknown: Guid;
        Ok: Boolean;
    begin
        Fresh(Rec);
        Evaluate(Unknown, '{11111111-2222-3333-4444-555555555555}');
        Ok := Rec.Pics.Insert(Null);
        Observer.Observe('insert-null', 'no error');
        Ok := Rec.Pics.Insert(Unknown);
        Observer.Observe('insert-unknown', 'no error');
        Observer.Observe('count', Format(Rec.Pics.Count()));
        Observer.Expect('insert-null', 'no error');
        Observer.Expect('insert-unknown', 'no error');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSetInsertSameTwice()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        A: Guid;
        Ok: Boolean;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        A := Rec.Pic.ImportStream(Ins, 'media');
        Rec.Modify();
        Ok := Rec.Pics.Insert(A);
        Observer.Observe('first', Format(Ok));
        Ok := Rec.Pics.Insert(A);
        Observer.Observe('second', Format(Ok));
        Observer.Observe('count', Format(Rec.Pics.Count()));
        Observer.Expect('first', 'Yes');
        Observer.Expect('second', 'No');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSetRemoveMiddle()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        A: Guid;
        B: Guid;
        C: Guid;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        A := Rec.Pics.ImportStream(Ins, 'a');
        PngIn(TempBlob, Ins);
        B := Rec.Pics.ImportStream(Ins, 'b');
        PngIn(TempBlob, Ins);
        C := Rec.Pics.ImportStream(Ins, 'c');
        Rec.Modify();
        Observer.Observe('count', Format(Rec.Pics.Count()));
        Rec.Pics.Remove(B);
        Rec.Modify();
        Observer.Observe('count-after', Format(Rec.Pics.Count()));
        Observer.Observe('item1-a', Format(Rec.Pics.Item(1) = A));
        Observer.Observe('item2-c', Format(Rec.Pics.Item(2) = C));
        Observer.Expect('count', '3');
        Observer.Expect('count-after', '3');
        Observer.Expect('item1-a', 'No');
        Observer.Expect('item2-c', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSetPersistsAcrossGet()
    var
        Rec: Record "LT StT Rec";
        Rec2: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        A: Guid;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        A := Rec.Pics.ImportStream(Ins, 'a');
        Rec.Modify();
        Rec2.Get(1);
        Observer.Observe('count', Format(Rec2.Pics.Count()));
        Observer.Observe('item1', Format(Rec2.Pics.Item(1) = A));
        Observer.Expect('count', '1');
        Observer.Expect('item1', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure MediaIdIsGuidType()
    var
        Rec: Record "LT StT Rec";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Ins: InStream;
        Id: Guid;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        Rec.Pic.ImportStream(Ins, 'x');
        Rec.Modify();
        Id := Rec.Pic.MediaId();
        Observer.Observe('not-null', Format(not IsNullGuid(Id)));
        Observer.Observe('format-len', Format(StrLen(Format(Id))));
        Observer.Observe('format-braces', Format(CopyStr(Format(Id), 1, 1) + CopyStr(Format(Id), StrLen(Format(Id)), 1)));
        Observer.Expect('not-null', 'Yes');
        Observer.Expect('format-len', '38');
        Observer.Expect('format-braces', '{}');
        Observer.Verify();
    end;

    // Corpus issue 668 item 74 (writer br): Media.ImportStream with a MIME type that is not a MIME type ('foo'), an empty one and ones
    // that do not match the png bytes; HasValue and the Tenant Media "Mime Type" afterwards. ImportStream writes Tenant Media, so it is not
    // called in a TryFunction: an import that fails ends its test with the error.
    local procedure BrImportOutcome(MimeType: Text): Text
    var
        Rec: Record "LT StT Rec";
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        Ins: InStream;
        Id: Guid;
        Result: Text;
    begin
        Fresh(Rec);
        PngIn(TempBlob, Ins);
        Id := Rec.Pic.ImportStream(Ins, 'desc', MimeType);
        Result := 'ok|hasvalue=' + Format(Rec.Pic.HasValue()) + '|returned=mediaid:' + Format(Id = Rec.Pic.MediaId());
        if TenantMedia.Get(Rec.Pic.MediaId()) then
            Result += '|mime=' + TenantMedia."Mime Type"
        else
            Result += '|no tenant media row';
        exit(Result);
    end;

    [Test]
    procedure MediaImportStreamMime_Foo()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('foo', BrImportOutcome('foo'));
        Observer.Expect('foo', 'ok|hasvalue=Yes|returned=mediaid:Yes|mime=foo');
        Observer.Verify();
    end;

    [Test]
    procedure MediaImportStreamMime_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('empty', BrImportOutcome(''));
        Observer.Expect('empty', 'ok|hasvalue=Yes|returned=mediaid:Yes|mime=image/png');
        Observer.Verify();
    end;

    [Test]
    procedure MediaImportStreamMime_JpegForPngBytes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('image/jpeg', BrImportOutcome('image/jpeg'));
        Observer.Expect('image/jpeg', 'ok|hasvalue=Yes|returned=mediaid:Yes|mime=image/jpeg');
        Observer.Verify();
    end;

    [Test]
    procedure MediaImportStreamMime_TextPlainForPngBytes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('text/plain', BrImportOutcome('text/plain'));
        Observer.Expect('text/plain', 'ok|hasvalue=Yes|returned=mediaid:Yes|mime=text/plain');
        Observer.Verify();
    end;

    // ---- Writer SO (2026-10-28), aldevtools/BusinessCentral.AL.Runner#5993: ExportStream of a Media field that holds no media ----
    // what ExportStream answers, what the stream holds and HasValue before and after, for a record that is only Init'ed, an inserted
    // empty row, and the reporter's shape (Document Attachment."Document Reference ID" of an Init'ed record).

    [TryFunction]
    local procedure SoTryExport(var Pic: Media; var Out: OutStream; var Answer: Boolean)
    begin
        Answer := Pic.ExportStream(Out);
    end;

    local procedure SoExportOutcome(var Pic: Media) Result: Text
    var
        TempBlob: Codeunit "Temp Blob";
        Out: OutStream;
        Answer: Boolean;
    begin
        Result := 'hasvalue=' + Format(Pic.HasValue()) + ' nullid=' + Format(IsNullGuid(Pic.MediaId()));
        TempBlob.CreateOutStream(Out);
        ClearLastError();
        if SoTryExport(Pic, Out, Answer) then
            Result += ' returned=' + Format(Answer)
        else
            Result += ' error=[' + GetLastErrorText() + '] code=' + GetLastErrorCode();
        Result += ' len=' + Format(TempBlob.Length()) + ' hasvalue after=' + Format(Pic.HasValue());
    end;

    [Test]
    procedure SO_MediaExportStream_InitNotInserted()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 9;
        Observer.Observe('init only', SoExportOutcome(Rec.Pic));
        Observer.Finish();
    end;

    [Test]
    procedure SO_MediaExportStream_InsertedEmpty()
    var
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
    begin
        Fresh(Rec);
        Observer.Observe('inserted', SoExportOutcome(Rec.Pic));
        Rec.Get(1);
        Observer.Observe('read back', SoExportOutcome(Rec.Pic));
        Observer.Finish();
    end;

    [Test]
    procedure SO_MediaExportStream_DocumentAttachmentShape()
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        OutStream: OutStream;
    begin
        DocumentAttachment.Init();
        Observer.Observe('outcome', SoExportOutcome(DocumentAttachment."Document Reference ID"));
        // the reporter's exact statement form, the answer not read
        TempBlob.CreateOutStream(OutStream);
        DocumentAttachment."Document Reference ID".ExportStream(OutStream);
        Observer.Observe('statement form len', Format(TempBlob.Length()));
        Observer.Observe('statement form hasvalue', Format(DocumentAttachment."Document Reference ID".HasValue()));
        Observer.Finish();
    end;
}
