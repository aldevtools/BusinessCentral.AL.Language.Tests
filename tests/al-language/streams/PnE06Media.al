// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-importstream-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72551, table 72552
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row (the four-argument form does not exist in the compiler, only the three-argument form is probed): "BigText.Read, Media.ImportStream with a file name, XmlReadOptions (issue 22)" - `Media.ImportStream(InStream, Description, MimeType, FileName)`
// Facts: four-argument ImportStream, the Tenant Media row it creates (File Name, Description, Mime Type), export of the media
// BC versions: 29 (27 and 28 by CI)

table 72552 "LT PnE Media Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Pic; Media) { }
        field(3; Blob; Blob) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

#if BC29PLUS
codeunit 72551 "LT PnE Media Import"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure HexVal(c: Char): Integer
    begin
        exit(StrPos('0123456789ABCDEF', UpperCase(Format(c))) - 1);
    end;

    local procedure PngIn(var Rec: Record "LT PnE Media Rec"; var Ins: InStream)
    var
        Out: OutStream;
        Hex: Text;
        B: Byte;
        i: Integer;
    begin
        Hex := '89504E470D0A1A0A0000000D4948445200000001000000010806000000' +
               '1F15C4890000000D49444154789C63F8FFFF3F0005FE02FEA7358184' +
               '0000000049454E44AE426082';
        Rec.Blob.CreateOutStream(Out);
        i := 1;
        while i < StrLen(Hex) do begin
            B := HexVal(Hex[i]) * 16 + HexVal(Hex[i + 1]);
            Out.Write(B);
            i += 2;
        end;
        Rec.Insert();
        Rec.CalcFields(Blob);
        Rec.Blob.CreateInStream(Ins);
    end;

    local procedure TenantMediaText(Id: Guid): Text
    var
        TM: Record "Tenant Media";
    begin
        if not TM.Get(Id) then
            exit('no row');
        exit('FileName=' + TM."File Name" + '|Description=' + TM.Description + '|Mime=' + TM."Mime Type");
    end;

#if BC28PLUS
    [Test]
    procedure ImportStream_ThreeArguments_ForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Media Rec";
        Ins: InStream;
        Id: Guid;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        PngIn(Rec, Ins);
        Id := Rec.Pic.ImportStream(Ins, 'desc', 'image/png');
        Observer.Observe('hasValue', Format(Rec.Pic.HasValue()));
        Observer.Observe('tenantMedia', TenantMediaText(Rec.Pic.MediaId));
        Rec.DeleteAll();
        // Windows BC 29.0 check 2026-10-20 (bump 34 queue): a TenantMedia row exists and HasValue is Yes. The Linux image at dbee8022 gives
        // the same; the image before the bc-linux #135/#161 fixes gave hasValue = No and no row.
        Observer.Expect('hasValue', 'Yes');
        Observer.Expect('tenantMedia', 'FileName=|Description=desc|Mime=image/png');
        Observer.Verify();
    end;
#endif
}
#endif

// Writer PW: docs/probes-needed.md "Values and builtins": Media.ImportStream on a field of a record from a stream on a Blob field of that
// same record whose content an Insert stored. ImportStream_ThreeArguments_ForComparison (above, BC 29 only) used a PNG one byte short (the
// IDAT checksum has 3 bytes); these use a valid 1x1 PNG (70 bytes, all chunk checksums right) and the short one, on every major.
codeunit 86144 "LT PW Media Own Blob"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure HexVal(c: Char): Integer
    begin
        exit(StrPos('0123456789ABCDEF', UpperCase(Format(c))) - 1);
    end;

    local procedure ValidPng(): Text
    begin
        exit('89504E470D0A1A0A0000000D49484452000000010000000108060000001F15C489' +
             '0000000D4944415478DA636460F85F0F0002870180EB47BA920000000049454E44AE426082');
    end;

    local procedure ShortPng(): Text
    begin
        exit('89504E470D0A1A0A0000000D4948445200000001000000010806000000' +
             '1F15C4890000000D49444154789C63F8FFFF3F0005FE02FEA7358184' +
             '0000000049454E44AE426082');
    end;

    local procedure WriteHex(var Out: OutStream; Hex: Text)
    var
        B: Byte;
        i: Integer;
    begin
        i := 1;
        while i < StrLen(Hex) do begin
            B := HexVal(Hex[i]) * 16 + HexVal(Hex[i + 1]);
            Out.Write(B);
            i += 2;
        end;
    end;

    local procedure TenantMediaText(Id: Guid): Text
    var
        TM: Record "Tenant Media";
    begin
        if IsNullGuid(Id) then
            exit('null id');
        if not TM.Get(Id) then
            exit('no row');
        TM.CalcFields(Content);
        exit('row|Description=' + TM.Description + '|Mime=' + TM."Mime Type" + '|Length=' + Format(TM.Content.Length()));
    end;

    // Insert stores the Blob, CalcFields (optionally after a Get), then ImportStream from the record's own Blob.
    local procedure OwnBlob(Hex: Text; GetFirst: Boolean; ModifyAfter: Boolean): Text
    var
        Rec: Record "LT PnE Media Rec";
        Again: Record "LT PnE Media Rec";
        Out: OutStream;
        Ins: InStream;
        Id: Guid;
        Result: Text;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Blob.CreateOutStream(Out);
        WriteHex(Out, Hex);
        Rec.Insert();
        if GetFirst then
            Rec.Get(1);
        Rec.CalcFields(Blob);
        Result := 'blobLength=' + Format(Rec.Blob.Length());
        Rec.Blob.CreateInStream(Ins);
        Id := Rec.Pic.ImportStream(Ins, 'desc', 'image/png');
        Result += ' hasValue=' + Format(Rec.Pic.HasValue()) + ' returned=' + TenantMediaText(Id) + ' field=' + TenantMediaText(Rec.Pic.MediaId());
        if ModifyAfter then begin
            Rec.Modify();
            Again.Get(1);
            Result += ' afterModify hasValue=' + Format(Again.Pic.HasValue());
        end;
        Rec.DeleteAll();
        exit(Result);
    end;

    // ImportStream from a stream on a Blob of another record (the control shape).
    local procedure OtherBlob(Hex: Text): Text
    var
        Rec: Record "LT PnE Media Rec";
        Src: Record "LT PnE Media Rec";
        Out: OutStream;
        Ins: InStream;
        Id: Guid;
        Result: Text;
    begin
        Rec.DeleteAll();
        Src.Init();
        Src.Id := 2;
        Src.Blob.CreateOutStream(Out);
        WriteHex(Out, Hex);
        Src.Insert();
        Src.CalcFields(Blob);
        Src.Blob.CreateInStream(Ins);
        Rec.Init();
        Rec.Id := 1;
        Rec.Insert();
        Id := Rec.Pic.ImportStream(Ins, 'desc', 'image/png');
        Result := 'hasValue=' + Format(Rec.Pic.HasValue()) + ' returned=' + TenantMediaText(Id) + ' field=' + TenantMediaText(Rec.Pic.MediaId());
        Rec.DeleteAll();
        exit(Result);
    end;

    [Test]
    procedure PW_OwnBlob_ValidPng()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('valid', OwnBlob(ValidPng(), false, false));
        Observer.Observe('validGetFirst', OwnBlob(ValidPng(), true, false));
        Observer.Observe('validModify', OwnBlob(ValidPng(), false, true));
#if BC29PLUS
        // Windows BC 29.0 (Windows BC 29.0 check 2026-10-20, all keys in the bump 34 queue) re-encodes the PNG to 99 bytes and accepts the
        // short one, as 27.5/28.5 do. Before the bc-linux #161 fix the Linux image (BC 29.0) kept 70 bytes and refused the short PNG.
        Observer.Expect('valid', 'blobLength=70 hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99');
        Observer.Expect('validGetFirst', 'blobLength=70 hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99');
        Observer.Expect('validModify', 'blobLength=70 hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99 afterModify hasValue=Yes');
        Observer.Verify();
#else
        Observer.Expect('valid', 'blobLength=70 hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99');
        Observer.Expect('validGetFirst', 'blobLength=70 hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99');
        Observer.Expect('validModify', 'blobLength=70 hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99 afterModify hasValue=Yes');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure PW_OwnBlob_ShortPng()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('short', OwnBlob(ShortPng(), false, false));
        Observer.Observe('shortGetFirst', OwnBlob(ShortPng(), true, false));
#if BC29PLUS
        // Windows BC 29.0 (Windows BC 29.0 check 2026-10-20, all keys in the bump 34 queue) re-encodes the PNG to 99 bytes and accepts the
        // short one, as 27.5/28.5 do. Before the bc-linux #161 fix the Linux image (BC 29.0) kept 70 bytes and refused the short PNG.
        Observer.Expect('short', 'blobLength=69 hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99');
        Observer.Expect('shortGetFirst', 'blobLength=69 hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99');
        Observer.Verify();
#else
        // Windows BC 27.5/28.5 (Windows check 2026-10-20) re-encode the short PNG to 99 bytes, like the valid one. Only the first difference
        // was reported, so shortGetFirst is not measured there. Before the bc-linux #135 fix the Linux image kept 69 bytes.
        Observer.Expect('short', 'blobLength=69 hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99');
        Observer.Ignore('shortGetFirst');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure PW_OtherBlob_ValidAndShortPng()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('valid', OtherBlob(ValidPng()));
        Observer.Observe('short', OtherBlob(ShortPng()));
#if BC29PLUS
        // Windows BC 29.0 (Windows BC 29.0 check 2026-10-20, all keys in the bump 34 queue) re-encodes the PNG to 99 bytes and accepts the
        // short one, as 27.5/28.5 do. Before the bc-linux #161 fix the Linux image (BC 29.0) kept 70 bytes and refused the short PNG.
        Observer.Expect('valid', 'hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99');
        Observer.Expect('short', 'hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99');
        Observer.Verify();
#else
        // Windows BC 27.5/28.5 (Windows check 2026-10-20) re-encode the short PNG to 99 bytes; before the bc-linux #135 fix the Linux image kept 69.
        Observer.Expect('valid', 'hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99');
        Observer.Expect('short', 'hasValue=Yes returned=row|Description=desc|Mime=image/png|Length=99 field=row|Description=desc|Mime=image/png|Length=99');
        Observer.Verify();
#endif
    end;
}
