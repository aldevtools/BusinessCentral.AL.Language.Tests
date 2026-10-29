// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-importstream-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-exportstream-method
// Scope: in-scope
// Fixtures used: ALT Media (60980)
//   and table "LT QE Media Other" (86580, end of file; writer QE 2026-10-20, QE_* tests: a media held by a row of ANOTHER
//   table or by another field is removed from Tenant Media when one holder lets it go by Modify or Delete; the other holder
//   keeps the MediaId, HasValue is false, ExportStream returns false and writes nothing)
//
// Companion of StefanMaron/BusinessCentral.AL.Runner#2570, which reports that AL Runner
// refuses to import ANY recognized image format into a Media field (it needs
// System.Drawing to decode, which has no support on the runner's Linux host), and proposes
// narrowing that refusal for PNG.
//
// MEASURED, not assumed: this file went through two rounds of corpus CI (27.0-28.4, all 8
// legs both times) correcting assumptions a decompiled exception mapper could not settle.
// Round 1 asserted a corrupt IHDR-chunk-CRC PNG is rejected; BC accepted it. Round 2 tried
// to separate "BC skips CRC checks" from "BC validates structure at all" with three more
// negative cases (signature-only, truncated mid-chunk, IHDR width=0) — BC accepted every
// one of those too, identically across all 8 legs both times. The conclusion this file now
// encodes: BC's PNG acceptance for a Media field is the 8-byte signature match and nothing
// more — no chunk CRC check, no IHDR structural validation, not even "is there a single
// byte of chunk data after the signature". A PNG-signature-prefixed stream of ANY content
// is accepted. This is the actual answer, not a hedge — see each test's CLAIM for the
// specific round-2 case it pins.
//
// All PNG payloads are byte-verified independently with Python (struct + zlib.crc32) and
// base64-encoded so the AL source stays plain text.
//
// ROUND 3 (issue #247) corrected the one test in this file that did NOT rest on CI: the
// export test asserted ExportStream() returns the same byte COUNT that was imported. BC
// re-encodes the image on import, so it does not -- 68 bytes in gives 99 out on two
// independent real-BC-on-Windows tiers. That test's own comment now records the mechanism
// and the three different output lengths three encoders produce; it asserts the imported
// PNG's DIMENSIONS survive the round-trip instead, which is the part a conforming encoder
// must preserve. Do not re-add a byte-length assertion here.
codeunit 60130 "Test Media Png Import"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        // Minimum valid 1x1-pixel PNG (68 bytes): signature + IHDR(13, width=1, height=1)
        // + IDAT(11) + IEND(0), every chunk CRC verified correct independently.
        ValidPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;
        // Base64 of bytes 0-14 of any PNG whose first chunk is a spec-conformant IHDR:
        // the 8-byte signature, the 4-byte chunk length 13, and "IHD". 20 characters is
        // exactly 5 Base64 groups, so this span pins bytes 0-14 and nothing beyond them.
        PngSignatureAndIhdrHeaderBase64: Label 'iVBORw0KGgoAAAANSUhE', Locked = true;
        // Base64 of bytes 15-23: the "R" of "IHDR", then width=1 and height=1 as big-endian
        // uint32s. Bytes 15 and 24 are both group boundaries (15 = 3*5, 24 = 3*8), so this
        // span pins the two dimension fields exactly and carries nothing from byte 24 (bit
        // depth) or byte 25 (colour type), which a re-encoder is entitled to change.
        IhdrOneByOneDimensionsBase64: Label 'UgAAAAEAAAAB', Locked = true;
        // Same 68 bytes with one byte of the IHDR chunk's CRC field flipped — every other
        // byte, including the IHDR data itself (width=1, height=1), is unchanged.
        CorruptIhdrCrcPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAADFfptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;
        // Just the 8-byte PNG signature, nothing else — no IHDR, no pixel data at all.
        SignatureOnlyPngBase64: Label 'iVBORw0KGgo=', Locked = true;
        // Signature + IHDR chunk header (length=13, type="IHDR") + only the first 4 of
        // IHDR's 13 data bytes, then nothing — cut off mid-chunk, no CRC, no IDAT/IEND.
        TruncatedMidIhdrPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAE=', Locked = true;
        // Structurally complete otherwise (correct CRCs throughout, real IDAT/IEND), but
        // IHDR's width field is 0.
        ZeroWidthIhdrPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAAAAAABCAAAAADVvPBrAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;
        // Plain text with no PNG signature at all — the pre-existing "not an image, falls
        // back to octet-stream" path this PR must NOT change.
        NonPngBase64: Label 'dGhpcyBpcyBub3QgYSBwbmcgYXQgYWxsLCBqdXN0IHBsYWluIHRleHQgYnl0ZXM=', Locked = true;

    [Test]
    procedure Media_ImportStream_ValidPng_HasValueTrue()
    // CLAIM: a structurally valid PNG imports into a Media field successfully, and the
    // field reports HasValue() = true afterwards.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();
        ImportBase64(Rec, 'PNG1', ValidPngBase64);
        Rec.Get('PNG1');
        Assert.IsTrue(Rec.Picture.HasValue(), 'Media field must have a value after importing a valid PNG');
    end;

    [Test]
    procedure Media_ExportStream_ValidPng_RoundTripsPreservingDimensions()
    // CLAIM: what ExportStream() returns is a PNG whose IHDR declares the SAME DIMENSIONS
    // (1x1) as the PNG that was imported. The image survives the round-trip; its byte
    // layout need not.
    //
    // WHY NOT BYTE LENGTH. This test previously asserted ExportStream() returns the same
    // byte COUNT that ImportStream() was given. That is not BC behaviour, and it must not
    // be re-added. BC does not store the incoming stream: NavMediaImport's
    // ImportMediaObjectCoreAsync calls NavMediaFactory.ProcessMediaObject(mediaStream,
    // saveStream: false, ...) and stores navMedia.Bytes(). With saveStream false the
    // NavMediaImage holds a decoded Image and no imageStream, so BytesAsync falls past its
    // stream-copy branch to image.Save(...) -- a re-encode. The output is whatever that
    // encoder emits: its own colour type, bit depth, filtering, zlib settings and ancillary
    // chunks. Measured, from the same 68-byte import:
    //
    //     68 bytes in  ->  99 bytes out   real BC on Windows (MS SaaS sandbox BC 28.4, and
    //                                     an official MS Windows container BC 28.4 onprem
    //                                     w1 -- two independent tiers, identical number)
    //     68 bytes in  ->  93 bytes out   BC-on-Linux once it re-encodes through SkiaSharp
    //     68 bytes in  ->  68 bytes out   BC-on-Linux today, where libgdiplus is stubbed so
    //                                     Image.FromStream cannot succeed and the import
    //                                     falls into the byte-preserving NavMediaBinaryFile
    //                                     path instead
    //
    // Three encoders, three lengths, none of them equal to the import. A byte-length claim
    // can only ever pin one encoder build. The old green on Linux measured the ABSENCE of an
    // image decoder, not BC.
    //
    // Dimensions are the part every conforming PNG encoder must preserve -- re-encoding a
    // 1x1 image yields a 1x1 image whatever it does to the pixel representation -- so that
    // is what this pins. It holds on all three paths above, including the byte-preserving
    // one, because a 1x1 PNG passed through verbatim still declares 1x1 in its IHDR.
    //
    // HOW THE BYTES ARE READ. Media exposes no Width/Height in AL, so the dimensions are
    // read out of the exported PNG itself. ReadText would be wrong for binary -- it is line-
    // and encoding-oriented and a PNG is full of NUL and 0x0A/0x0D -- so the blob goes
    // through Base64Convert.ToBase64, which is lossless over arbitrary bytes. This is the
    // pattern established by TestReportSaveAsPdfContent.al (cu 60774).
    //
    // WHICH BYTES EACH ASSERTION CONSTRAINS. Base64 packs 3 input bytes into 4 output
    // characters on a fixed grid, so a character span pins a byte span exactly when both
    // ends fall on a group boundary. Both spans below do, and Base64 is injective on a
    // 3-byte group, so character equality IS byte equality -- there is no bleed from any
    // byte outside the stated range:
    //
    //   chars 1-20  <-> bytes 0-14  : the 8-byte PNG signature, IHDR's length field (13),
    //                                 and the first three bytes of the type "IHD".
    //   chars 21-32 <-> bytes 15-23 : the "R" completing "IHDR", then WIDTH as a big-endian
    //                                 uint32 (bytes 16-19) and HEIGHT as a big-endian
    //                                 uint32 (bytes 20-23).
    //
    // Byte 24 (bit depth) and byte 25 (colour type) are deliberately OUTSIDE both spans.
    // Those are exactly the fields a re-encoder is free to change -- the fixture is
    // greyscale colour type 0, and GDI+ re-emits as RGB or RGBA -- so pinning them would
    // re-introduce the encoder dependence this test exists to remove.
    //
    // The second assertion is falsifiable in each dimension independently: width 2 gives
    // 'UgAAAAIAAAAB', height 2 gives 'UgAAAAEAAAAC', width 0 gives 'UgAAAAAAAAAB', and
    // 16x16 gives 'UgAAABAAAAAQ'. Only 1x1 gives the expected value.
    var
        Rec: Record "ALT Media";
        ExportBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        ExportOutStr: OutStream;
        ExportInStr: InStream;
        Encoded: Text;
        ExportedLength: Integer;
    begin
        Initialize();
        ImportBase64(Rec, 'PNG2', ValidPngBase64);

        Rec.Get('PNG2');
        ExportBlob.CreateOutStream(ExportOutStr);
        Rec.Picture.ExportStream(ExportOutStr);
        ExportedLength := ExportBlob.Length();

        // A zero-length export would make every prefix comparison below vacuous, so fail it
        // as itself first.
        Assert.IsTrue(ExportedLength > 0, 'ExportStream() must write bytes for a Media field that HasValue()');

        ExportBlob.CreateInStream(ExportInStr);
        Encoded := Base64Convert.ToBase64(ExportInStr);

        // Guard the CopyStr calls: a payload too short to carry an IHDR must fail saying so,
        // not as a confusing prefix mismatch.
        Assert.IsTrue(StrLen(Encoded) >= 32,
            StrSubstNo('ExportStream() wrote only %1 bytes -- too short to carry a PNG signature and IHDR header.', ExportedLength));

        // Bytes 0-14: it is a PNG, and the first chunk is an IHDR of the spec-mandated
        // length 13. Separates a PNG from an error payload, a zero-fill, or a non-image
        // blob.
        Assert.AreEqual(PngSignatureAndIhdrHeaderBase64, CopyStr(Encoded, 1, 20),
            StrSubstNo('ExportStream() wrote %1 bytes that do not begin with a PNG signature and IHDR chunk header.', ExportedLength));

        // Bytes 15-23: width = 1 and height = 1, big-endian, exactly as the imported PNG
        // declared them. This is the round-trip claim.
        Assert.AreEqual(IhdrOneByOneDimensionsBase64, CopyStr(Encoded, 21, 12),
            StrSubstNo('ExportStream() returned a PNG whose IHDR does not declare 1x1 -- the imported image''s dimensions did not survive the round-trip (%1 bytes exported).', ExportedLength));
    end;

    [Test]
    procedure Media_ImportStream_PngWithCorruptIhdrCrc_Succeeds()
    // CLAIM: a PNG whose signature and IHDR data are valid but whose IHDR chunk CRC is
    // wrong still imports successfully. MEASURED: the first version of this test asserted
    // the opposite (rejection) and real BC (27.0-28.4, all 8 legs) falsified it.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();
        ImportBase64(Rec, 'PNG3', CorruptIhdrCrcPngBase64);
        Rec.Get('PNG3');
        Assert.IsTrue(Rec.Picture.HasValue(),
            'A PNG with a wrong IHDR CRC (but otherwise valid structure) must still import — BC does not check chunk CRCs');
    end;

    [Test]
    procedure Media_ImportStream_SignatureOnly_Succeeds()
    // CLAIM: a stream that is just the 8-byte PNG signature, with no IHDR and no pixel
    // data at all, still imports successfully. MEASURED (27.0-28.4, all 8 legs, twice):
    // the original version of this test asserted rejection and BC accepted it both times.
    // BC's PNG acceptance for a Media field really is the signature match alone.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();
        ImportBase64(Rec, 'PNG4', SignatureOnlyPngBase64);
        Rec.Get('PNG4');
        Assert.IsTrue(Rec.Picture.HasValue(), 'A signature-only stream (no IHDR at all) must still import');
    end;

    [Test]
    procedure Media_ImportStream_TruncatedMidIhdr_Succeeds()
    // CLAIM: a stream cut off in the middle of the IHDR chunk (no CRC, no IDAT/IEND at
    // all) still imports successfully. MEASURED, same as the signature-only case above.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();
        ImportBase64(Rec, 'PNG5', TruncatedMidIhdrPngBase64);
        Rec.Get('PNG5');
        Assert.IsTrue(Rec.Picture.HasValue(), 'A stream truncated mid-IHDR-chunk must still import');
    end;

    [Test]
    procedure Media_ImportStream_ZeroWidthIhdr_Succeeds()
    // CLAIM: a structurally complete PNG (correct CRCs, real IDAT/IEND) whose IHDR
    // declares width=0 still imports successfully. MEASURED, same as the two cases above —
    // BC does not sanity-check IHDR's declared dimensions either.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();
        ImportBase64(Rec, 'PNG6', ZeroWidthIhdrPngBase64);
        Rec.Get('PNG6');
        Assert.IsTrue(Rec.Picture.HasValue(), 'A PNG with IHDR width=0 must still import');
    end;

    [Test]
    procedure Media_ImportStream_NonPngContent_StillFallsBackToOctetStream()
    // CLAIM: content with no PNG (or other image) signature at all still imports via the
    // pre-existing "not an image, fall back to application/octet-stream" path — this PR
    // must not change that.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();
        ImportBase64(Rec, 'PNG7', NonPngBase64);
        Rec.Get('PNG7');
        Assert.IsTrue(Rec.Picture.HasValue(), 'Non-image content must still import via the octet-stream fallback');
    end;

    // Returns nothing on purpose. It used to return the imported byte length, which existed
    // only for the byte-length equality assertion issue #247 removed. BC re-encodes on
    // import, so the imported length says nothing about what ExportStream() gives back --
    // leaving the value here would invite exactly the comparison that was wrong.
    local procedure ImportBase64(var Rec: Record "ALT Media"; Code: Code[20]; Base64Content: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        OutStr: OutStream;
    begin
        Rec.Init();
        Rec.Code := Code;
        Rec.Insert();

        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(Base64Content, OutStr);
        TempBlob.CreateInStream(InStr);

        Rec.Picture.ImportStream(InStr, 'test content');
        Rec.Modify();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    // ── Added by writer bs (corpus issue #668, item 75): orphan deletion when media is replaced, MediaSet.Remove ──
    // record/lt-ar-records/ArRecordProbes.al (writer ar, Media_ImportStream_OnFilledField) pins that a replaced Media is deleted from Tenant Media on Modify.

    local procedure BsPngIn(var TempBlob: Codeunit "Temp Blob"; var InStr: InStream)
    var
        Base64Convert: Codeunit "Base64 Convert";
        OutStr: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(ValidPngBase64, OutStr);
        TempBlob.CreateInStream(InStr);
    end;

    [Test]
    procedure Media_Replace_WhileAnotherRowSharesTheMedia()
    // CLAIM (issue #668 item 75): row 2 gets row 1's Media by assignment (same MediaId). Row 1 then imports a new picture and is modified:
    // is the old media object kept in Tenant Media because row 2 still references it, and what does row 2 read?
    var
        Observer: Codeunit "Probe Observer";
        Row1: Record "ALT Media";
        Row2: Record "ALT Media";
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        First: Guid;
    begin
        Initialize();
        ImportBase64(Row1, 'BS1', ValidPngBase64);
        Row1.Get('BS1');
        First := Row1.Picture.MediaId();
        Row2.Init();
        Row2.Code := 'BS2';
        Row2.Picture := Row1.Picture;
        Row2.Insert();
        Row2.Get('BS2');
        Observer.Observe('row2_shares_id', Format(Row2.Picture.MediaId() = First));
        BsPngIn(TempBlob, InStr);
        Row1.Picture.ImportStream(InStr, 'replacement');
        Row1.Modify();
        Observer.Observe('old_media_after_replace', Format(TenantMedia.Get(First)));
        Row2.Get('BS2');
        Observer.Observe('row2_still_same_id', Format(Row2.Picture.MediaId() = First));
        Observer.Observe('row2_has_value', Format(Row2.Picture.HasValue()));
        Row2.Delete();
        Observer.Observe('old_media_after_row2_delete', Format(TenantMedia.Get(First)));
        Observer.Expect('row2_shares_id', 'Yes');
        Observer.Expect('old_media_after_replace', 'Yes');
        Observer.Expect('row2_still_same_id', 'Yes');
        Observer.Expect('row2_has_value', 'Yes');
        Observer.Expect('old_media_after_row2_delete', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSet_Remove_KeepsTheTenantMediaRow()
    // CLAIM (issue #668 item 75): the docs say MediaSet.Remove only removes the association. After Remove and Modify, is the removed item's
    // row still in Tenant Media? And after the record is deleted?
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Media";
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        Item1: Guid;
        Item2: Guid;
    begin
        Initialize();
        Row.Init();
        Row.Code := 'BS3';
        Row.Insert();
        BsPngIn(TempBlob, InStr);
        Row.Images.ImportStream(InStr, 'one');
        BsPngIn(TempBlob, InStr);
        Row.Images.ImportStream(InStr, 'two');
        Row.Modify();
        Row.Get('BS3');
        Item1 := Row.Images.Item(1);
        Item2 := Row.Images.Item(2);
        Observer.Observe('remove_result', Format(Row.Images.Remove(Item1)));
        Row.Modify();
        Row.Get('BS3');
        Observer.Observe('count_after_remove', Format(Row.Images.Count()));
        Observer.Observe('removed_item_in_tenant_media', Format(TenantMedia.Get(Item1)));
        Observer.Observe('kept_item_in_tenant_media', Format(TenantMedia.Get(Item2)));
        Row.Delete();
        Observer.Observe('removed_item_after_delete', Format(TenantMedia.Get(Item1)));
        Observer.Observe('kept_item_after_delete', Format(TenantMedia.Get(Item2)));
        Observer.Expect('remove_result', 'Yes');
        Observer.Expect('count_after_remove', '1');
        Observer.Expect('removed_item_in_tenant_media', 'Yes');
        Observer.Expect('kept_item_in_tenant_media', 'Yes');
        Observer.Expect('removed_item_after_delete', 'Yes');
        Observer.Expect('kept_item_after_delete', 'No');
        Observer.Verify();
    end;

    // ── Added by writer QE (2026-10-20): one media held by rows of TWO tables (or two fields), copied by assignment or by
    // TransferFields. After a Modify that replaces it, or a Delete, in one holder: what does the other holder still read,
    // and is the media still in Tenant Media? Table "LT QE Media Other" (86580) is at the end of this file.

    local procedure QeInitialize()
    var
        Other: Record "LT QE Media Other";
    begin
        Initialize();
        Other.DeleteAll();
    end;

    local procedure QeObserveOther(var Observer: Codeunit "Probe Observer"; Prefix: Text; Code: Code[20]; Id: Guid)
    var
        Other: Record "LT QE Media Other";
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Other.Get(Code);
        Observer.Observe(Prefix + ' has_value', Format(Other.Picture.HasValue()));
        Observer.Observe(Prefix + ' same_id', Format(Other.Picture.MediaId() = Id));
        Observer.Observe(Prefix + ' null_id', Format(IsNullGuid(Other.Picture.MediaId())));
        Observer.Observe(Prefix + ' in_tenant_media', Format(TenantMedia.Get(Id)));
        TempBlob.CreateOutStream(OutStr);
        Observer.Observe(Prefix + ' export_result', Format(Other.Picture.ExportStream(OutStr)));
        Observer.Observe(Prefix + ' export_nonempty', Format(TempBlob.Length() > 0));
    end;

    local procedure QeObserveAlt(var Observer: Codeunit "Probe Observer"; Prefix: Text; Code: Code[20]; Id: Guid)
    var
        Row: Record "ALT Media";
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Row.Get(Code);
        Observer.Observe(Prefix + ' has_value', Format(Row.Picture.HasValue()));
        Observer.Observe(Prefix + ' same_id', Format(Row.Picture.MediaId() = Id));
        Observer.Observe(Prefix + ' in_tenant_media', Format(TenantMedia.Get(Id)));
        TempBlob.CreateOutStream(OutStr);
        Observer.Observe(Prefix + ' export_result', Format(Row.Picture.ExportStream(OutStr)));
        Observer.Observe(Prefix + ' export_nonempty', Format(TempBlob.Length() > 0));
    end;

    local procedure QeSharedByAssignment(Code: Code[20]) Id: Guid
    var
        Row: Record "ALT Media";
        Other: Record "LT QE Media Other";
    begin
        ImportBase64(Row, Code, ValidPngBase64);
        Row.Get(Code);
        Id := Row.Picture.MediaId();
        Other.Init();
        Other.Code := Code;
        Other.Picture := Row.Picture;
        Other.Insert();
    end;

    [Test]
    procedure QE_Media_OtherTable_Assigned_SourceRowDeleted()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Media";
        TenantMedia: Record "Tenant Media";
        Id: Guid;
    begin
        QeInitialize();
        Id := QeSharedByAssignment('QE1');
        QeObserveOther(Observer, 'before', 'QE1', Id);
        Row.Get('QE1');
        Row.Delete();
        QeObserveOther(Observer, 'after delete', 'QE1', Id);
        Observer.Observe('tenant media still there', Format(TenantMedia.Get(Id)));
        Observer.Expect('before has_value', 'Yes');
        Observer.Expect('before same_id', 'Yes');
        Observer.Expect('before null_id', 'No');
        Observer.Expect('before in_tenant_media', 'Yes');
        Observer.Expect('before export_result', 'Yes');
        Observer.Expect('before export_nonempty', 'Yes');
        Observer.Expect('after delete has_value', 'No');
        Observer.Expect('after delete same_id', 'Yes');
        Observer.Expect('after delete null_id', 'No');
        Observer.Expect('after delete in_tenant_media', 'No');
        Observer.Expect('after delete export_result', 'No');
        Observer.Expect('after delete export_nonempty', 'No');
        Observer.Expect('tenant media still there', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QE_Media_OtherTable_Assigned_SourceRowReplaced()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        Id: Guid;
    begin
        QeInitialize();
        Id := QeSharedByAssignment('QE2');
        Row.Get('QE2');
        BsPngIn(TempBlob, InStr);
        Row.Picture.ImportStream(InStr, 'replacement');
        Row.Modify();
        Row.Get('QE2');
        Observer.Observe('source has new id', Format(Row.Picture.MediaId() <> Id));
        QeObserveOther(Observer, 'after replace', 'QE2', Id);
        Observer.Expect('source has new id', 'Yes');
        Observer.Expect('after replace has_value', 'No');
        Observer.Expect('after replace same_id', 'Yes');
        Observer.Expect('after replace null_id', 'No');
        Observer.Expect('after replace in_tenant_media', 'No');
        Observer.Expect('after replace export_result', 'No');
        Observer.Expect('after replace export_nonempty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QE_Media_OtherTable_TransferFields_SourceRowDeleted()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Media";
        Other: Record "LT QE Media Other";
        Id: Guid;
    begin
        QeInitialize();
        ImportBase64(Row, 'QE3', ValidPngBase64);
        Row.Get('QE3');
        Id := Row.Picture.MediaId();
        Other.Init();
        Other.TransferFields(Row);
        Observer.Observe('transferred same id', Format(Other.Picture.MediaId() = Id));
        Other.Insert();
        Row.Delete();
        QeObserveOther(Observer, 'after delete', 'QE3', Id);
        Observer.Expect('transferred same id', 'Yes');
        Observer.Expect('after delete has_value', 'No');
        Observer.Expect('after delete same_id', 'Yes');
        Observer.Expect('after delete null_id', 'No');
        Observer.Expect('after delete in_tenant_media', 'No');
        Observer.Expect('after delete export_result', 'No');
        Observer.Expect('after delete export_nonempty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QE_Media_OtherTable_TransferFields_SourceRowReplaced()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Media";
        Other: Record "LT QE Media Other";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        Id: Guid;
    begin
        QeInitialize();
        ImportBase64(Row, 'QE4', ValidPngBase64);
        Row.Get('QE4');
        Id := Row.Picture.MediaId();
        Other.Init();
        Other.TransferFields(Row);
        Other.Insert();
        BsPngIn(TempBlob, InStr);
        Row.Picture.ImportStream(InStr, 'replacement');
        Row.Modify();
        QeObserveOther(Observer, 'after replace', 'QE4', Id);
        Observer.Expect('after replace has_value', 'No');
        Observer.Expect('after replace same_id', 'Yes');
        Observer.Expect('after replace null_id', 'No');
        Observer.Expect('after replace in_tenant_media', 'No');
        Observer.Expect('after replace export_result', 'No');
        Observer.Expect('after replace export_nonempty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QE_Media_OtherTable_HolderDeleted_ThenSourceDeleted()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Media";
        Other: Record "LT QE Media Other";
        TenantMedia: Record "Tenant Media";
        Id: Guid;
    begin
        QeInitialize();
        Id := QeSharedByAssignment('QE5');
        Other.Get('QE5');
        Other.Delete();
        QeObserveAlt(Observer, 'after other delete', 'QE5', Id);
        Row.Get('QE5');
        Row.Delete();
        Observer.Observe('after both deleted in_tenant_media', Format(TenantMedia.Get(Id)));
        Observer.Expect('after other delete has_value', 'No');
        Observer.Expect('after other delete same_id', 'Yes');
        Observer.Expect('after other delete in_tenant_media', 'No');
        Observer.Expect('after other delete export_result', 'No');
        Observer.Expect('after other delete export_nonempty', 'No');
        Observer.Expect('after both deleted in_tenant_media', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QE_Media_OtherTable_HolderReplaced()
    var
        Observer: Codeunit "Probe Observer";
        Other: Record "LT QE Media Other";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        Id: Guid;
    begin
        QeInitialize();
        Id := QeSharedByAssignment('QE6');
        Other.Get('QE6');
        BsPngIn(TempBlob, InStr);
        Other.Picture.ImportStream(InStr, 'replacement');
        Other.Modify();
        Other.Get('QE6');
        Observer.Observe('other has new id', Format(Other.Picture.MediaId() <> Id));
        QeObserveAlt(Observer, 'after other replace', 'QE6', Id);
        Observer.Expect('other has new id', 'Yes');
        Observer.Expect('after other replace has_value', 'No');
        Observer.Expect('after other replace same_id', 'Yes');
        Observer.Expect('after other replace in_tenant_media', 'No');
        Observer.Expect('after other replace export_result', 'No');
        Observer.Expect('after other replace export_nonempty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QE_Media_SameRow_OtherField_Replaced()
    var
        Observer: Codeunit "Probe Observer";
        Other: Record "LT QE Media Other";
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        Id: Guid;
    begin
        QeInitialize();
        Other.Init();
        Other.Code := 'QE7';
        Other.Insert();
        BsPngIn(TempBlob, InStr);
        Other.Picture.ImportStream(InStr, 'first');
        Other.Modify();
        Other.Get('QE7');
        Id := Other.Picture.MediaId();
        Other.Picture2 := Other.Picture;
        Other.Modify();
        BsPngIn(TempBlob, InStr);
        Other.Picture.ImportStream(InStr, 'second');
        Other.Modify();
        Other.Get('QE7');
        Observer.Observe('picture new id', Format(Other.Picture.MediaId() <> Id));
        Observer.Observe('picture2 same id', Format(Other.Picture2.MediaId() = Id));
        Observer.Observe('picture2 has_value', Format(Other.Picture2.HasValue()));
        Observer.Observe('old in_tenant_media', Format(TenantMedia.Get(Id)));
        Other.Delete();
        Observer.Observe('after delete old in_tenant_media', Format(TenantMedia.Get(Id)));
        Observer.Expect('picture new id', 'Yes');
        Observer.Expect('picture2 same id', 'Yes');
        Observer.Expect('picture2 has_value', 'No');
        Observer.Expect('old in_tenant_media', 'No');
        Observer.Expect('after delete old in_tenant_media', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QE_Media_OtherTable_Assigned_SourceRowDeleted_Committed()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Media";
        Id: Guid;
    begin
        QeInitialize();
        Id := QeSharedByAssignment('QE8');
        Commit();
        Row.Get('QE8');
        Row.Delete();
        Commit();
        QeObserveOther(Observer, 'after committed delete', 'QE8', Id);
        Observer.Expect('after committed delete has_value', 'No');
        Observer.Expect('after committed delete same_id', 'Yes');
        Observer.Expect('after committed delete null_id', 'No');
        Observer.Expect('after committed delete in_tenant_media', 'No');
        Observer.Expect('after committed delete export_result', 'No');
        Observer.Expect('after committed delete export_nonempty', 'No');
        Observer.Verify();
    end;

    // Writer TP (NP lane, 2026-10-28): Delete on a "Tenant Media" record (the row of a Media field), then the holder row. Values from the corpus CI
    // containers (27.5, 28.5): Delete returns true, the row is gone, the holder keeps the MediaId with HasValue false; Delete of a missing id
    // returns false with no error. On the BC 29 SaaS sandbox the same Delete fails: 'Your license does not grant you the following permissions
    // on TableData 2000000184 Tenant Media: Delete.' (a license difference, not asserted).
    [Test]
    procedure TP_TenantMedia_Delete()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Media";
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        Id: Guid;
        Ok: Boolean;
    begin
        QeInitialize();
        ImportBase64(Row, 'TP1', ValidPngBase64);
        Row.Get('TP1');
        Id := Row.Picture.MediaId();
        Observer.Observe('get', Format(TenantMedia.Get(Id)));
        ClearLastError();
        Ok := TenantMedia.Delete();
        Observer.Observe('delete', Format(Ok) + ' ' + GetLastErrorText());
        ClearLastError();
        Observer.Observe('get after delete', Format(TenantMedia.Get(Id)));
        Row.Get('TP1');
        Observer.Observe('has_value', Format(Row.Picture.HasValue()));
        Observer.Observe('same_id', Format(Row.Picture.MediaId() = Id));
        TempBlob.CreateOutStream(OutStr);
        Observer.Observe('export_result', Format(Row.Picture.ExportStream(OutStr)));
        Observer.Observe('export_nonempty', Format(TempBlob.Length() > 0));
        TenantMedia.Init();
        TenantMedia.ID := CreateGuid();
        ClearLastError();
        Ok := TenantMedia.Delete();
        Observer.Observe('delete missing', Format(Ok) + ' ' + GetLastErrorText());
        Observer.Expect('get', 'Yes');
        Observer.Expect('delete', 'Yes ');
        Observer.Expect('get after delete', 'No');
        Observer.Expect('has_value', 'No');
        Observer.Expect('same_id', 'Yes');
        Observer.Expect('export_result', 'No');
        Observer.Expect('export_nonempty', 'No');
        Observer.Expect('delete missing', 'No ');
        Observer.Verify();
    end;

    // ── Added by writer TQ (NP lane, 2026-10-29): Tenant Media Delete(true) after a successful Get, result ignored (statement form) or
    // used, on a media one row holds and on one two rows hold; Delete(true) in statement form on a missing row. Then Media.ExportStream of
    // a PNG BC re-encoded on import: what lands in a Blob field and in the Tenant Media row.
    // Facts: Delete(true) on a Tenant Media row found by Get deletes it and returns true (statement form: no error); a second Delete(true)
    // returns false; every row that held the media (also a row of another table) keeps the MediaId, HasValue false, ExportStream false and
    // writes nothing. Delete(true) in statement form on a missing row: DB:RecordNotFound. On the BC SaaS sandbox every Tenant Media Delete
    // fails with a license error (DB:ClientDeleteDenied); the values asserted are those of the containers (CI, BC 27.5, 28.5, 29.0).
    // ExportStream of an imported PNG: true, the Blob has a value, Format gives `*`, the bytes are a PNG with the imported width and height
    // and the length of the stored Tenant Media content; Tenant Media has Mime Type image/png and the image's Width and Height. The bytes
    // themselves are the encoder's (3x2 RGB: 103 bytes on the SaaS sandbox, 111 on the CI containers; 1x1 gray: 99 on both): not asserted.

    local procedure TqObserveRow(var Observer: Codeunit "Probe Observer"; Prefix: Text; Code: Code[20]; Id: Guid)
    var
        Row: Record "ALT Media";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Row.Get(Code);
        Observer.Observe(Prefix + ' has_value', Format(Row.Picture.HasValue()));
        Observer.Observe(Prefix + ' same_id', Format(Row.Picture.MediaId() = Id));
        TempBlob.CreateOutStream(OutStr);
        Observer.Observe(Prefix + ' export_result', Format(Row.Picture.ExportStream(OutStr)));
        Observer.Observe(Prefix + ' export_length', Format(TempBlob.Length()));
    end;

    [Test]
    procedure TQ_TenantMedia_DeleteTrue_Statement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Media";
        TenantMedia: Record "Tenant Media";
        Id: Guid;
    begin
        QeInitialize();
        ImportBase64(Row, 'TQ1', ValidPngBase64);
        Row.Get('TQ1');
        Id := Row.Picture.MediaId();
        ClearLastError();
        if TenantMedia.Get(Id) then
            TenantMedia.Delete(true);
        Observer.Observe('last error', GetLastErrorText());
        Observer.Observe('get after delete', Format(TenantMedia.Get(Id)));
        TqObserveRow(Observer, 'row', 'TQ1', Id);
        Observer.Expect('last error', '');
        Observer.Expect('get after delete', 'No');
        Observer.Expect('row has_value', 'No');
        Observer.Expect('row same_id', 'Yes');
        Observer.Expect('row export_result', 'No');
        Observer.Expect('row export_length', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_TenantMedia_DeleteTrue_Used()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Media";
        TenantMedia: Record "Tenant Media";
        Id: Guid;
    begin
        QeInitialize();
        ImportBase64(Row, 'TQ2', ValidPngBase64);
        Row.Get('TQ2');
        Id := Row.Picture.MediaId();
        Observer.Observe('get', Format(TenantMedia.Get(Id)));
        Observer.Observe('delete(true)', Format(TenantMedia.Delete(true)));
        Observer.Observe('get after delete', Format(TenantMedia.Get(Id)));
        Observer.Observe('delete(true) again', Format(TenantMedia.Delete(true)));
        TqObserveRow(Observer, 'row', 'TQ2', Id);
        Observer.Expect('get', 'Yes');
        Observer.Expect('delete(true)', 'Yes');
        Observer.Expect('get after delete', 'No');
        Observer.Expect('delete(true) again', 'No');
        Observer.Expect('row has_value', 'No');
        Observer.Expect('row same_id', 'Yes');
        Observer.Expect('row export_result', 'No');
        Observer.Expect('row export_length', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_TenantMedia_DeleteTrue_SharedMedia()
    var
        Observer: Codeunit "Probe Observer";
        TenantMedia: Record "Tenant Media";
        Id: Guid;
    begin
        QeInitialize();
        Id := QeSharedByAssignment('TQ3');
        if TenantMedia.Get(Id) then
            TenantMedia.Delete(true);
        Observer.Observe('get after delete', Format(TenantMedia.Get(Id)));
        QeObserveAlt(Observer, 'alt', 'TQ3', Id);
        QeObserveOther(Observer, 'other', 'TQ3', Id);
        Observer.Expect('get after delete', 'No');
        Observer.Expect('alt has_value', 'No');
        Observer.Expect('alt same_id', 'Yes');
        Observer.Expect('alt in_tenant_media', 'No');
        Observer.Expect('alt export_result', 'No');
        Observer.Expect('alt export_nonempty', 'No');
        Observer.Expect('other has_value', 'No');
        Observer.Expect('other same_id', 'Yes');
        Observer.Expect('other null_id', 'No');
        Observer.Expect('other in_tenant_media', 'No');
        Observer.Expect('other export_result', 'No');
        Observer.Expect('other export_nonempty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_TenantMedia_DeleteTrue_Missing_Statement()
    var
        Observer: Codeunit "Probe Observer";
        TenantMedia: Record "Tenant Media";
    begin
        QeInitialize();
        TenantMedia.Init();
        Evaluate(TenantMedia.ID, '{6B1D3E1A-0C2B-4F7E-9A51-3D2C1B0A9F87}');
        asserterror TenantMedia.Delete(true);
        Observer.ObserveError('statement');
        Observer.Expect('statement|text', 'The Tenant Media does not exist. Identification fields and values: ID=''{6B1D3E1A-0C2B-4F7E-9A51-3D2C1B0A9F87}''');
        Observer.Expect('statement|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    local procedure TqObserveExport(var Observer: Codeunit "Probe Observer"; Prefix: Text; Code: Code[20]; Base64Png: Text)
    var
        Row: Record "ALT Media";
        TempTenantMedia: Record "Tenant Media" temporary;
        TenantMedia: Record "Tenant Media";
        Base64Convert: Codeunit "Base64 Convert";
        OutStr: OutStream;
        InStr: InStream;
        Encoded: Text;
    begin
        ImportBase64(Row, Code, Base64Png);
        Row.Get(Code);
        TempTenantMedia.ID := CreateGuid();
        TempTenantMedia.Content.CreateOutStream(OutStr);
        Observer.Observe(Prefix + ' export_result', Format(Row.Picture.ExportStream(OutStr)));
        TempTenantMedia.Insert();
        TempTenantMedia.CalcFields(Content);
        Observer.Observe(Prefix + ' blob has_value', Format(TempTenantMedia.Content.HasValue()));
        Observer.Observe(Prefix + ' blob format', Format(TempTenantMedia.Content));
        TempTenantMedia.Content.CreateInStream(InStr);
        Encoded := Base64Convert.ToBase64(InStr);
        Observer.Observe(Prefix + ' blob head', CopyStr(Encoded, 1, 32));
        TenantMedia.Get(Row.Picture.MediaId());
        TenantMedia.CalcFields(Content);
        Observer.Observe(Prefix + ' tm mime', TenantMedia."Mime Type");
        Observer.Observe(Prefix + ' tm width', Format(TenantMedia.Width));
        Observer.Observe(Prefix + ' tm height', Format(TenantMedia.Height));
        Observer.Observe(Prefix + ' tm format', Format(TenantMedia.Content));
        Observer.Observe(Prefix + ' tm length = blob length', Format(TenantMedia.Content.Length() = TempTenantMedia.Content.Length()));
    end;

    [Test]
    procedure TQ_Media_ExportStream_ReEncodedPng_Gray1x1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QeInitialize();
        TqObserveExport(Observer, 'gray1x1', 'TQ5', ValidPngBase64);
        Observer.Expect('gray1x1 export_result', 'Yes');
        Observer.Expect('gray1x1 blob has_value', 'Yes');
        Observer.Expect('gray1x1 blob format', '*');
        Observer.Expect('gray1x1 blob head', 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAAB');
        Observer.Expect('gray1x1 tm mime', 'image/png');
        Observer.Expect('gray1x1 tm width', '1');
        Observer.Expect('gray1x1 tm height', '1');
        Observer.Expect('gray1x1 tm format', '*');
        Observer.Expect('gray1x1 tm length = blob length', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TQ_Media_ExportStream_ReEncodedPng_Rgb3x2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        QeInitialize();
        // A 73-byte 3x2 RGB PNG (8-bit, colour type 2; red, green, blue on both rows), every chunk CRC computed with Python zlib.crc32.
        TqObserveExport(Observer, 'rgb3x2', 'TQ6', 'iVBORw0KGgoAAAANSUhEUgAAAAMAAAACCAIAAAASFvFNAAAAEElEQVR4nGP4z8DAAMFwFgA72AX73hA3ZQAAAABJRU5ErkJggg==');
        Observer.Expect('rgb3x2 export_result', 'Yes');
        Observer.Expect('rgb3x2 blob has_value', 'Yes');
        Observer.Expect('rgb3x2 blob format', '*');
        Observer.Expect('rgb3x2 blob head', 'iVBORw0KGgoAAAANSUhEUgAAAAMAAAAC');
        Observer.Expect('rgb3x2 tm mime', 'image/png');
        Observer.Expect('rgb3x2 tm width', '3');
        Observer.Expect('rgb3x2 tm height', '2');
        Observer.Expect('rgb3x2 tm format', '*');
        Observer.Expect('rgb3x2 tm length = blob length', 'Yes');
        Observer.Verify();
    end;

}

table 86580 "LT QE Media Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Description"; Text[100]) { }
        field(3; "Picture"; Media) { }
        field(5; "Picture2"; Media) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
