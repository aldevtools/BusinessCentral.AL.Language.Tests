// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/library
// Scope: in-scope
// Fixtures used: table 74200, codeunit 69160 "Probe Observer", System Application codeunit "Temp Blob" and "Base64 Convert"
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74202 "LT StT CopyStream"
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

    [Test]
    procedure CopyAllBytes()
    var
        Rec: Record "LT StT Rec";
        Rec2: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Out2: OutStream;
        Ins: InStream;
        Ins2: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec2.Init();
        Rec2.Id := 2;
        Rec2.Insert();
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('copy me please');
        Rec.Modify();
        Rec.Data.CreateInStream(Ins);
        Rec2.Data.CreateOutStream(Out2);
        CopyStream(Out2, Ins);
        Rec2.Modify();
        Rec2.CalcFields(Data);
        Observer.Observe('len', Format(Rec2.Data.Length()));
        Observer.Observe('source-eos', Format(Ins.EOS()));
        Rec2.Data.CreateInStream(Ins2);
        Ins2.ReadText(T);
        Observer.Observe('text', T);
        Observer.Expect('len', '14');
        Observer.Expect('source-eos', 'Yes');
        Observer.Expect('text', 'copy me please');
        Observer.Verify();
    end;

    [Test]
    procedure CopyWithLength()
    var
        Rec: Record "LT StT Rec";
        Rec2: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Out2: OutStream;
        Ins: InStream;
        Ins2: InStream;
        T: Text;
        Copied: Boolean;
    begin
        Fresh(Rec);
        Rec2.Init();
        Rec2.Id := 2;
        Rec2.Insert();
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('0123456789');
        Rec.Modify();
        Rec.Data.CreateInStream(Ins);
        Rec2.Data.CreateOutStream(Out2);
        Copied := CopyStream(Out2, Ins, 4);
        Observer.Observe('copied', Format(Copied));
        Observer.Observe('source-pos', Format(Ins.Position()));
        Observer.Observe('source-eos', Format(Ins.EOS()));
        Copied := CopyStream(Out2, Ins, 100);
        Observer.Observe('copied-rest', Format(Copied));
        Observer.Observe('source-eos-after', Format(Ins.EOS()));
        Rec2.Modify();
        Rec2.Data.CreateInStream(Ins2);
        Ins2.ReadText(T);
        Observer.Observe('text', T);
        Observer.Expect('copied', 'Yes');
        Observer.Expect('source-pos', '5');
        Observer.Expect('source-eos', 'No');
        Observer.Expect('copied-rest', 'No');
        Observer.Expect('source-eos-after', 'No');
        Observer.Expect('text', '0123456789');
        Observer.Verify();
    end;

    [Test]
    procedure CopyZeroAndNegativeLength()
    var
        Rec: Record "LT StT Rec";
        Rec2: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Out2: OutStream;
        Ins: InStream;
        Copied: Boolean;
    begin
        Fresh(Rec);
        Rec2.Init();
        Rec2.Id := 2;
        Rec2.Insert();
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('abcdef');
        Rec.Modify();
        Rec.Data.CreateInStream(Ins);
        Rec2.Data.CreateOutStream(Out2);
        Copied := CopyStream(Out2, Ins, 0);
        Observer.Observe('copied0', Format(Copied));
        Observer.Observe('pos0', Format(Ins.Position()));
        Copied := CopyStream(Out2, Ins, -1);
        Observer.Observe('negative', 'no error');
        Observer.Expect('copied0', 'Yes');
        Observer.Expect('pos0', '1');
        Observer.Expect('negative', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFromEmpty()
    var
        Rec: Record "LT StT Rec";
        Rec2: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out2: OutStream;
        Ins: InStream;
        Copied: Boolean;
    begin
        Fresh(Rec);
        Rec2.Init();
        Rec2.Id := 2;
        Rec2.Insert();
        Rec.Data.CreateInStream(Ins);
        Rec2.Data.CreateOutStream(Out2);
        Copied := CopyStream(Out2, Ins, 5);
        Observer.Observe('copied', Format(Copied));
        CopyStream(Out2, Ins);
        Rec2.Modify();
        Rec2.CalcFields(Data);
        Observer.Observe('len', Format(Rec2.Data.Length()));
        Observer.Observe('has', Format(Rec2.Data.HasValue()));
        Observer.Expect('copied', 'No');
        Observer.Expect('len', '0');
        Observer.Expect('has', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFromMidPosition()
    var
        Rec: Record "LT StT Rec";
        Rec2: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Out2: OutStream;
        Ins: InStream;
        Ins2: InStream;
        Part: Text;
        T: Text;
    begin
        Fresh(Rec);
        Rec2.Init();
        Rec2.Id := 2;
        Rec2.Insert();
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('abcdefghij');
        Rec.Modify();
        Rec.Data.CreateInStream(Ins);
        Ins.ReadText(Part, 3);
        Rec2.Data.CreateOutStream(Out2);
        CopyStream(Out2, Ins);
        Rec2.Modify();
        Rec2.Data.CreateInStream(Ins2);
        Ins2.ReadText(T);
        Observer.Observe('text', T);
        Ins.ResetPosition();
        Rec2.Data.CreateOutStream(Out2);
        CopyStream(Out2, Ins, 2);
        Rec2.Modify();
        Rec2.Data.CreateInStream(Ins2);
        Ins2.ReadText(T);
        Observer.Observe('text-after-reset', T);
        Observer.Expect('text', 'defghij');
        Observer.Expect('text-after-reset', 'abfghij');
        Observer.Verify();
    end;

    [Test]
    procedure CopyAppendsToOutStream()
    var
        Rec: Record "LT StT Rec";
        Rec2: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Out2: OutStream;
        Ins: InStream;
        Ins2: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec2.Init();
        Rec2.Id := 2;
        Rec2.Insert();
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('B');
        Rec.Modify();
        Rec.Data.CreateInStream(Ins);
        Rec2.Data.CreateOutStream(Out2);
        Out2.WriteText('A');
        CopyStream(Out2, Ins);
        Out2.WriteText('C');
        Rec2.Modify();
        Rec2.Data.CreateInStream(Ins2);
        Ins2.ReadText(T);
        Observer.Observe('text', T);
        Observer.Expect('text', 'ABC');
        Observer.Verify();
    end;

    [Test]
    procedure TempBlobBasics()
    var
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Observer.Observe('empty-has', Format(TempBlob.HasValue()));
        Observer.Observe('empty-len', Format(TempBlob.Length()));
        TempBlob.CreateOutStream(Out);
        Out.WriteText('temp data');
        Observer.Observe('has', Format(TempBlob.HasValue()));
        Observer.Observe('len', Format(TempBlob.Length()));
        TempBlob.CreateInStream(Ins);
        Ins.ReadText(T);
        Observer.Observe('text', T);
        Observer.Observe('eos', Format(Ins.EOS()));
        Observer.Expect('empty-has', 'No');
        Observer.Expect('empty-len', '0');
        Observer.Expect('has', 'Yes');
        Observer.Expect('len', '9');
        Observer.Expect('text', 'temp data');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TempBlobEncodings()
    var
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        T := 'a';
        T[2] := 228;
        T[3] := 8364;
        TempBlob.CreateOutStream(Out, TextEncoding::UTF8);
        Out.WriteText(T);
        Observer.Observe('utf8', Format(TempBlob.Length()));
        TempBlob.CreateOutStream(Out, TextEncoding::UTF16);
        Out.WriteText(T);
        Observer.Observe('utf16', Format(TempBlob.Length()));
        TempBlob.CreateOutStream(Out, TextEncoding::Windows);
        Out.WriteText(T);
        Observer.Observe('windows', Format(TempBlob.Length()));
        TempBlob.CreateOutStream(Out, TextEncoding::MSDos);
        Out.WriteText(T);
        Observer.Observe('msdos', Format(TempBlob.Length()));
        TempBlob.CreateInStream(Ins, TextEncoding::MSDos);
        Ins.ReadText(T);
        Observer.Observe('msdos-read-len', Format(StrLen(T)));
        Observer.Expect('utf8', '6');
        Observer.Expect('utf16', '6');
        Observer.Expect('windows', '6');
        Observer.Expect('msdos', '6');
        Observer.Expect('msdos-read-len', '3');
        Observer.Verify();
    end;

    [Test]
    procedure TempBlobRecreateOutStreamTruncates()
    var
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
    begin
        TempBlob.CreateOutStream(Out);
        Out.WriteText('long long long');
        Observer.Observe('len1', Format(TempBlob.Length()));
        TempBlob.CreateOutStream(Out);
        Out.WriteText('s');
        Observer.Observe('len2', Format(TempBlob.Length()));
        TempBlob.CreateOutStream(Out);
        Observer.Observe('len3', Format(TempBlob.Length()));
        Observer.Observe('has3', Format(TempBlob.HasValue()));
        Observer.Expect('len1', '14');
        Observer.Expect('len2', '14');
        Observer.Expect('len3', '14');
        Observer.Expect('has3', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TempBlobFromAndToRecord()
    var
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        TempBlob.CreateOutStream(Out);
        Out.WriteText('into field');
        RecRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecRef, Rec.FieldNo(Data));
        RecRef.Modify();
        RecRef.SetTable(Rec);
        Rec.CalcFields(Data);
        Observer.Observe('field-len', Format(Rec.Data.Length()));
        TempBlob2.FromRecordRef(RecRef, Rec.FieldNo(Data));
        Observer.Observe('from-len', Format(TempBlob2.Length()));
        TempBlob2.CreateInStream(Ins);
        Ins.ReadText(T);
        Observer.Observe('from-text', T);
        Observer.Expect('field-len', '10');
        Observer.Expect('from-len', '10');
        Observer.Expect('from-text', 'into field');
        Observer.Verify();
    end;

    [Test]
    procedure TempBlobFromFieldRef()
    var
        TempBlob: Codeunit "Temp Blob";
        Rec: Record "LT StT Rec";
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.WriteText('from fieldref');
        Rec.Modify();
        RecRef.GetTable(Rec);
        FldRef := RecRef.Field(Rec.FieldNo(Data));
        FldRef.CalcField();
        TempBlob.FromFieldRef(FldRef);
        Observer.Observe('len', Format(TempBlob.Length()));
        TempBlob.CreateInStream(Ins);
        Ins.ReadText(T);
        Observer.Observe('text', T);
        Observer.Expect('len', '13');
        Observer.Expect('text', 'from fieldref');
        Observer.Verify();
    end;

    [Test]
    procedure TempBlobDuplicate()
    var
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        TempBlob.CreateOutStream(Out);
        Out.WriteText('original');
        TempBlob2 := TempBlob;
        Observer.Observe('copy-len', Format(TempBlob2.Length()));
        TempBlob.CreateOutStream(Out);
        Out.WriteText('changed');
        Observer.Observe('copy-len-after', Format(TempBlob2.Length()));
        TempBlob2.CreateInStream(Ins);
        Ins.ReadText(T);
        Observer.Observe('copy-text', T);
        Observer.Expect('copy-len', '8');
        Observer.Expect('copy-len-after', '8');
        Observer.Expect('copy-text', 'changedl');
        Observer.Verify();
    end;

    [Test]
    procedure Base64TextRoundTrip()
    var
        Base64: Codeunit "Base64 Convert";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Observer.Observe('empty', Base64.ToBase64(''));
        Observer.Observe('a', Base64.ToBase64('a'));
        Observer.Observe('ab', Base64.ToBase64('ab'));
        Observer.Observe('abc', Base64.ToBase64('abc'));
        Observer.Observe('abcd', Base64.ToBase64('abcd'));
        Observer.Observe('hello', Base64.ToBase64('Hello, World!'));
        T[1] := 228;
        T[2] := 8364;
        Observer.Observe('nonascii', Base64.ToBase64(T));
        Observer.Observe('nonascii-back', Format(StrLen(Base64.FromBase64(Base64.ToBase64(T)))));
        Observer.Observe('from-hello', Base64.FromBase64('SGVsbG8sIFdvcmxkIQ=='));
        Observer.Observe('from-empty', Base64.FromBase64(''));
        Observer.Expect('empty', '');
        Observer.Expect('a', 'YQ==');
        Observer.Expect('ab', 'YWI=');
        Observer.Expect('abc', 'YWJj');
        Observer.Expect('abcd', 'YWJjZA==');
        Observer.Expect('hello', 'SGVsbG8sIFdvcmxkIQ==');
        Observer.Expect('nonascii', 'w6Tigqw=');
        Observer.Expect('nonascii-back', '2');
        Observer.Expect('from-hello', 'Hello, World!');
        Observer.Expect('from-empty', '');
        Observer.Verify();
    end;

    [Test]
    procedure Base64Encodings()
    var
        Base64: Codeunit "Base64 Convert";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T[1] := 228;
        T[2] := 8364;
        Observer.Observe('utf8', Base64.ToBase64(T, TextEncoding::UTF8));
        Observer.Observe('utf16', Base64.ToBase64(T, TextEncoding::UTF16));
        Observer.Observe('windows', Base64.ToBase64(T, TextEncoding::Windows));
        Observer.Observe('msdos', Base64.ToBase64(T, TextEncoding::MSDos));
        Observer.Observe('utf16-back', Format(StrLen(Base64.FromBase64(Base64.ToBase64(T, TextEncoding::UTF16), TextEncoding::UTF16))));
        Observer.Observe('windows-back', Format(StrLen(Base64.FromBase64(Base64.ToBase64(T, TextEncoding::Windows), TextEncoding::Windows))));
        Observer.Expect('utf8', 'w6Tigqw=');
        Observer.Expect('utf16', '5ACsIA==');
#if BC28PLUS
        Observer.Expect('windows', '5IA=');
#else
        Observer.Expect('windows', 'w6Tigqw=');
#endif
#if BC28PLUS
        Observer.Expect('msdos', '5IA=');
#else
        Observer.Expect('msdos', 'w6Tigqw=');
#endif
        Observer.Expect('utf16-back', '2');
#if BC28PLUS
        Observer.Expect('windows-back', '2');
#else
        Observer.Expect('windows-back', '5');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Base64Url()
    var
        Base64: Codeunit "Base64 Convert";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T[1] := 251;
        T[2] := 255;
        T[3] := 190;
        Observer.Observe('std', Base64.ToBase64(T, TextEncoding::Windows));
        Observer.Observe('url', Base64.ToBase64Url(T));
        Observer.Observe('url-abc', Base64.ToBase64Url('abc?>>'));
        Observer.Observe('std-abc', Base64.ToBase64('abc?>>'));
#if BC28PLUS
        Observer.Expect('std', '+/++');
#else
        Observer.Expect('std', 'w7vDv8K+');
#endif
        Observer.Expect('url', 'w7vDv8K-');
        Observer.Expect('url-abc', 'YWJjPz4-');
        Observer.Expect('std-abc', 'YWJjPz4+');
        Observer.Verify();
    end;

    [Test]
    procedure Base64UrlAlphabetToStandardDecode()
    var
        Base64: Codeunit "Base64 Convert";
        Observer: Codeunit "Probe Observer";
    begin
        // a url-safe string given to the standard decoder: observation only (the pipeline turns a raise into a no-error fix)
        asserterror Observer.Observe('decoded', Base64.FromBase64('YWJjPz4-'));
        Observer.Observe('af425', Format(StrPos(GetLastErrorText(), 'The input is not a valid Base-64 string') > 0));
        ClearLastError();
        Observer.Expect('af425', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Base64UrlAlphabetRoundTrip()
    var
        Base64: Codeunit "Base64 Convert";
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Observer.Observe('decoded', Base64.FromBase64(Base64.ToBase64Url('abc?>>')));
        Observer.Observe('af436', Format(StrPos(GetLastErrorText(), 'The input is not a valid Base-64 string') > 0));
        ClearLastError();
        Observer.Expect('af436', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Base64InvalidInput()
    var
        Base64: Codeunit "Base64 Convert";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        asserterror T := Base64.FromBase64('abc');
        Observer.Observe('bad-length', Format(StrPos(GetLastErrorText(), 'The input is not a valid Base-64 string') > 0));
        ClearLastError();
        asserterror T := Base64.FromBase64('!!!!');
        Observer.Observe('bad-chars', Format(StrPos(GetLastErrorText(), 'The input is not a valid Base-64 string') > 0));
        ClearLastError();
        T := Base64.FromBase64('YW Jj');
        Observer.Observe('space', 'no error');
        asserterror T := Base64.FromBase64('YQ=');
        Observer.Observe('short-pad', Format(StrPos(GetLastErrorText(), 'The input is not a valid Base-64 string') > 0));
        ClearLastError();
        T := Base64.FromBase64('YQ==');
        Observer.Observe('ok-pad', T);
        Observer.Expect('bad-length', 'Yes');
        Observer.Expect('bad-chars', 'Yes');
        Observer.Expect('space', 'no error');
        Observer.Expect('short-pad', 'Yes');
        Observer.Expect('ok-pad', 'a');
        Observer.Verify();
    end;

    [Test]
    procedure Base64Streams()
    var
        Base64: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
    begin
        TempBlob.CreateOutStream(Out);
        Out.WriteText('stream content');
        TempBlob.CreateInStream(Ins);
        T := Base64.ToBase64(Ins);
        Observer.Observe('b64', T);
        Clear(TempBlob);
        TempBlob.CreateOutStream(Out);
        Base64.FromBase64(T, Out);
        Observer.Observe('len', Format(TempBlob.Length()));
        TempBlob.CreateInStream(Ins);
        Ins.ReadText(T);
        Observer.Observe('text', T);
        Observer.Expect('b64', 'c3RyZWFtIGNvbnRlbnQ=');
        Observer.Expect('len', '14');
        Observer.Expect('text', 'stream content');
        Observer.Verify();
    end;

    [Test]
    procedure Base64EmptyStream()
    var
        Base64: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
    begin
        TempBlob.CreateInStream(Ins);
        Observer.Observe('empty', Base64.ToBase64(Ins));
        TempBlob.CreateOutStream(Out);
        Base64.FromBase64('', Out);
        Observer.Observe('len', Format(TempBlob.Length()));
        Observer.Expect('empty', '');
        Observer.Expect('len', '0');
        Observer.Verify();
    end;

    // Writer SN (2026-10-25, runtime hand-off refuse-json-streams "CopyStream count beyond what is left / negative count"):
    // return value, source position/EOS and what reaches the target for counts equal to, one beyond and far beyond what is left, and negative counts.
    local procedure CopyCount(var Observer: Codeunit "Probe Observer"; Name: Text; Source: Text; Skip: Integer; Count: Integer)
    var
        Rec: Record "LT StT Rec";
        Rec2: Record "LT StT Rec";
        Out: OutStream;
        Out2: OutStream;
        Ins: InStream;
        Ins2: InStream;
        T: Text;
        Skipped: Text;
    begin
        Fresh(Rec);
        Rec2.Init();
        Rec2.Id := 2;
        Rec2.Insert();
        Rec.Data.CreateOutStream(Out);
        Out.WriteText(Source);
        Rec.Modify();
        Rec.Data.CreateInStream(Ins);
        if Skip > 0 then
            Ins.ReadText(Skipped, Skip);
        Rec2.Data.CreateOutStream(Out2);
        Observer.Observe(Name + '-copied', Format(CopyStream(Out2, Ins, Count)));
        Observer.Observe(Name + '-pos', Format(Ins.Position()));
        Observer.Observe(Name + '-eos', Format(Ins.EOS()));
        Rec2.Modify();
        Rec2.Data.CreateInStream(Ins2);
        Ins2.ReadText(T);
        Observer.Observe(Name + '-text', T);
    end;

    [Test]
    procedure CopyCountAgainstWhatIsLeft()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyCount(Observer, 'exact', 'abcdef', 0, 6);
        CopyCount(Observer, 'one-more', 'abcdef', 0, 7);
        CopyCount(Observer, 'far-more', 'abcdef', 0, 100);
        CopyCount(Observer, 'rest-exact', 'abcdef', 2, 4);
        CopyCount(Observer, 'rest-more', 'abcdef', 2, 5);
        Observer.Finish();
    end;

    [Test]
    procedure CopyNegativeCount()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CopyCount(Observer, 'minus-one', 'abcdef', 0, -1);
        CopyCount(Observer, 'minus-five', 'abcdef', 0, -5);
        CopyCount(Observer, 'minus-one-after-skip', 'abcdef', 2, -1);
        Observer.Finish();
    end;
}
