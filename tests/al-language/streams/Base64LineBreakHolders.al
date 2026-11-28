// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.text.base64-convert
// Scope: in-scope
// Fixtures used: codeunit 69160 "Probe Observer", table 60008 "ALT Blob", System Application codeunits "Base64 Convert" and "Temp Blob"
// Probe: written against local BC on Linux tiers; every literal asserted below is what those tiers produced. Other BC versions are checked by the corpus CI matrix.
// Measured on: 27.5.54899.59044, 28.5.54976.59048, 29.0.54011.59052 (W1 sandbox artifacts; tests through the TestRunnerHub on every leg)
// BC versions: 27.5, 28.5, 29.0
// Lead: al-runner issue 9322 (ToBase64(InStream, true) on the Blob field of a TableType = Temporary table). Extends
// Base64LineBreaks.al, which pins the same call on a Temp Blob stream only.
//
// Area: Base64 Convert ToBase64(InStream, true) and ToBase64(InStream, true, OutStream) on streams of every Blob holder
// (TableType = Temporary table, temporary record variable, normal record not inserted, inserted, modified, Temp Blob
// FromRecord), every write history (one or two WriteText, UTF8 OutStream, Write(Text), WriteText with a length,
// CopyStream, non-ASCII content) and every stream use before the call (ReadText, Read, EOS, UTF8 InStream, a second
// CreateInStream, an assigned InStream).
//
// What BC did (28.5 and 29.0 gave the same results everywhere; 27.5 differs only where a #if BC28PLUS block says so):
// - The holder does not change the result. 100 bytes give 138 characters with CR LF (13 10) at 77 and 78, the same string
//   as the Text form, for every holder: TableType = Temporary record (local, global, inserted and read back with Get and
//   CalcFields), a temporary record variable of a normal table (inserted or not), a normal record (not inserted; inserted
//   and read back in a second variable; modified), a Temp Blob filled with FromRecord, a record of the test passed by var
//   to another codeunit.
// - A stream opened on a record that is a local of another codeunit's procedure is empty once that procedure returns:
//   EOS is true and ToBase64 returns an empty text.
// - Write history: two WriteText calls equal one; a UTF8 OutStream gives the same bytes for 'A'; WriteText(Text, 60)
//   writes 60 bytes (82 characters, CR LF at 77). OutS.Write(Text) writes a trailing 0 byte: still 138 characters, the
//   first line equals the Text form, the end is 'QQA='. A default OutStream writes ÄÖÜ as one byte each in the MSDos
//   code page (8E 99 9A, 'jpma'), so the result differs from the Text form (UTF-8, 'w4TDlsOc') but keeps 138 characters.
// - Stream use before the call: EOS, a UTF8 InStream, a second CreateInStream and InS2 := InS do not change the result.
//   ReadText(T, 10) or Read(T, 10) first: 28.5 and 29.0 still convert all 100 bytes (138), 27.5 converts the 90 bytes
//   left (122). Reading the whole stream first (Read(T) or ReadText(T)) leaves nothing on every version: ToBase64
//   returns an empty text; the same holds for a Temp Blob stream.
// - ToBase64(InStream, true, OutStream) (System Application 28 and later, so not on 27.5) with this source writes 138
//   bytes with CR LF at 77 and 78 into a Temp Blob or into a TableType = Temporary record's Blob; one ReadText of the
//   target returns the first line (76).

table 75482 "STR B64 Holder Temp"
{
    // local object: TableType = Temporary is under test (a table whose every record variable is temporary)
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(2; Data; Blob)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}

codeunit 75483 "STR B64 Holder Helper"
{
    procedure Codes(Value: Text): Text
    var
        i: Integer;
        C: Char;
        V: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            C := Value[i];
            V := C;
            Result += Format(V) + ' ';
        end;
        exit(Result);
    end;

    procedure CrLf(): Text
    var
        Cr: Char;
        Lf: Char;
    begin
        Cr := 13;
        Lf := 10;
        exit(Format(Cr) + Format(Lf));
    end;

    procedure HundredA(): Text
    begin
        exit(PadStr('', 100, 'A'));
    end;

    // Observes one ToBase64(..., true) result: where the first CR LF is, the length, the codes at 76 to 78,
    // and whether it equals the Text form of the content that was written.
    procedure ObserveResult(var Observer: Codeunit "Probe Observer"; Result: Text; Content: Text)
    var
        Base64: Codeunit "Base64 Convert";
    begin
        Observer.Observe('crlf_at', Format(StrPos(Result, CrLf())));
        Observer.Observe('length', Format(StrLen(Result)));
        Observer.Observe('codes_76_to_78', Codes(CopyStr(Result, 76, 3)));
        Observer.Observe('equals_text_form', Format(Result = Base64.ToBase64(Content, true)));
    end;

    procedure EdgeCodes(Value: Text): Text
    begin
        if StrLen(Value) <= 4 then
            exit(Codes(Value));
        exit(Codes(CopyStr(Value, 1, 4)) + '... ' + Codes(CopyStr(Value, StrLen(Value) - 3, 4)));
    end;

    // A3b: the record is the caller's (by var); this procedure writes it and opens the stream.
    procedure FillCallerHolder(var Holder: Record "STR B64 Holder Temp"; var InS: InStream)
    var
        OutS: OutStream;
    begin
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(HundredA());
        Holder.Data.CreateInStream(InS);
    end;

    // A3: the record lives only in this procedure of a non-test codeunit; the stream is handed back.
    procedure FillTempHolder(var InS: InStream)
    var
        Holder: Record "STR B64 Holder Temp";
        OutS: OutStream;
    begin
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(HundredA());
        Holder.Data.CreateInStream(InS);
    end;
}

codeunit 75484 "STR B64 Blob Holders"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GlobalHolder: Record "STR B64 Holder Temp";
        H: Codeunit "STR B64 Holder Helper";
        Base64: Codeunit "Base64 Convert";

    [Test]
    procedure ToBase64_TempTableLocalNotInserted_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // A1: TableType = Temporary, local record, never inserted (the reporter's repro)
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_TempTableGlobalNotInserted_LineBreaks()
    var
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // A2: the same table, the record is a global of the test codeunit
        Clear(GlobalHolder);
        GlobalHolder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        GlobalHolder.Data.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_TempTableInOtherCodeunit_LineBreaks()
    var
        Observer: Codeunit "Probe Observer";
        InS: InStream;
    begin
        // A3: written and opened in a procedure of a non-test codeunit, the stream handed back
        H.FillTempHolder(InS);
        Observer.Observe('eos_before_call', Format(InS.EOS()));
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('eos_before_call', 'Yes');
        Observer.Expect('crlf_at', '0');
        Observer.Expect('length', '0');
        Observer.Expect('codes_76_to_78', '');
        Observer.Expect('equals_text_form', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_TempTableCallerRecordOtherCodeunit_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        InS: InStream;
    begin
        // A3b (neighbor of A3): the record is a local of the test, passed by var to a non-test codeunit that writes it and opens the stream
        H.FillCallerHolder(Holder, InS);
        Observer.Observe('eos_before_call', Format(InS.EOS()));
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('eos_before_call', 'No');
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_TemporaryVariableNotInserted_LineBreaks()
    var
        TempHolder: Record "ALT Blob" temporary;
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // A4: normal table, local record declared temporary, never inserted
        TempHolder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        TempHolder.Data.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_TemporaryVariableInserted_LineBreaks()
    var
        TempHolder: Record "ALT Blob" temporary;
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // A5: normal table, temporary variable, Insert after the write, then CalcFields and CreateInStream
        TempHolder.Code := 'A5';
        TempHolder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        TempHolder.Insert();
        TempHolder.CalcFields(Data);
        TempHolder.Data.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_NormalRecordNotInserted_LineBreaks()
    var
        Holder: Record "ALT Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // A6: normal table, normal record, never inserted
        Holder.DeleteAll();
        Holder.Code := 'A6';
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_NormalRecordInsertedGetCalcFields_LineBreaks()
    var
        Holder: Record "ALT Blob";
        Reread: Record "ALT Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // A7: normal record, Insert after the write, Get into a second variable, CalcFields, CreateInStream
        Holder.DeleteAll();
        Holder.Code := 'A7';
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Insert();
        Reread.Get('A7');
        Reread.CalcFields(Data);
        Reread.Data.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_NormalRecordModified_LineBreaks()
    var
        Holder: Record "ALT Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // A8: normal record inserted empty, Modify after the write, then CalcFields and CreateInStream
        Holder.DeleteAll();
        Holder.Code := 'A8';
        Holder.Insert();
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Modify();
        Holder.CalcFields(Data);
        Holder.Data.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_TempBlobFromRecord_LineBreaks()
    var
        Holder: Record "ALT Blob";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // A9: Temp Blob filled by FromRecord from a normal record that was written and never inserted
        Holder.DeleteAll();
        Holder.Code := 'A9';
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        TempBlob.FromRecord(Holder, Holder.FieldNo(Data));
        TempBlob.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_TempTableInsertedGetCalcFields_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // A10: TableType = Temporary, Insert after the write, then Get, CalcFields and CreateInStream
        Holder.Code := 'A10';
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Insert();
        Holder.Get('A10');
        Holder.CalcFields(Data);
        Holder.Data.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;
}

codeunit 75485 "STR B64 Blob Stream History"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        H: Codeunit "STR B64 Holder Helper";
        Base64: Codeunit "Base64 Convert";

    [Test]
    procedure ToBase64_TwoWriteTexts_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // B1: two WriteText calls of 50 'A' each
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(PadStr('', 50, 'A'));
        OutS.WriteText(PadStr('', 50, 'A'));
        Holder.Data.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_Utf8OutStream_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // B2: CreateOutStream with TextEncoding::UTF8
        Holder.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_OutStreamWriteText_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        Content: Text;
        Result: Text;
    begin
        // B3: OutS.Write(Text) instead of WriteText
        Content := H.HundredA();
        Holder.Data.CreateOutStream(OutS);
        OutS.Write(Content);
        Holder.Data.CreateInStream(InS);
        Result := Base64.ToBase64(InS, true);
        Observer.Observe('edge_codes', H.EdgeCodes(Result));
        Observer.Observe('without_last_line_equals_text_form', Format(CopyStr(Result, 1, 76) = CopyStr(Base64.ToBase64(H.HundredA(), true), 1, 76)));
        H.ObserveResult(Observer, Result, H.HundredA());
        Observer.Expect('edge_codes', '81 85 70 66 ... 81 81 65 61 ');
        Observer.Expect('without_last_line_equals_text_form', 'Yes');
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_WriteTextWithLength_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // B4: WriteText(Text, 60) of 100 'A'
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA(), 60);
        Holder.Data.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), PadStr('', 60, 'A'));
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '82');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_CopyStreamFromTempBlob_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        SourceOutS: OutStream;
        SourceInS: InStream;
        OutS: OutStream;
        InS: InStream;
    begin
        // B5: CopyStream from a Temp Blob's InStream into the field's OutStream
        TempBlob.CreateOutStream(SourceOutS);
        SourceOutS.WriteText(H.HundredA());
        TempBlob.CreateInStream(SourceInS);
        Holder.Data.CreateOutStream(OutS);
        CopyStream(OutS, SourceInS);
        Holder.Data.CreateInStream(InS);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_NonAsciiContent_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        Content: Text;
        Result: Text;
    begin
        // B6: three non-ASCII letters then 97 'A', default encoding
        Content := 'ÄÖÜ' + PadStr('', 97, 'A');
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(Content);
        Holder.Data.CreateInStream(InS);
        Result := Base64.ToBase64(InS, true);
        Observer.Observe('edge_codes', H.EdgeCodes(Result));
        Observer.Observe('first_8', CopyStr(Result, 1, 8));
        Observer.Observe('text_form_first_8', CopyStr(Base64.ToBase64(Content, true), 1, 8));
        H.ObserveResult(Observer, Result, Content);
        Observer.Expect('edge_codes', '106 112 109 97 ... 81 81 61 61 ');
        Observer.Expect('first_8', 'jpmaQUFB');
        Observer.Expect('text_form_first_8', 'w4TDlsOc');
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_ReadTextBeforeCall_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        Skipped: Text;
    begin
        // C1: ReadText(T, 10) before the call
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS);
        InS.ReadText(Skipped, 10);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
#if BC28PLUS // 27.5 converts from the read position (Base64LineBreaks.al, ToBase64_InStream_EmptyPartReadAndSecondCall)
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
#else
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '122');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'No');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_ReadBeforeCall_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        Skipped: Text;
    begin
        // C2: InS.Read(T) without a length before the call
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS);
        InS.Read(Skipped);
        Observer.Observe('read_strlen', Format(StrLen(Skipped)));
        Observer.Observe('eos_after_read', Format(InS.EOS()));
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('read_strlen', '100');
        Observer.Expect('eos_after_read', 'Yes');
        Observer.Expect('crlf_at', '0');
        Observer.Expect('length', '0');
        Observer.Expect('codes_76_to_78', '');
        Observer.Expect('equals_text_form', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_EosBeforeCall_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // C3: InS.EOS() before the call
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS);
        Observer.Observe('eos', Format(InS.EOS()));
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('eos', 'No');
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_Utf8InStream_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
    begin
        // C4: CreateInStream with TextEncoding::UTF8
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS, TextEncoding::UTF8);
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_SecondCreateInStream_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        InS2: InStream;
    begin
        // C5: a second CreateInStream on the field; the second stream is converted
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS);
        Holder.Data.CreateInStream(InS2);
        H.ObserveResult(Observer, Base64.ToBase64(InS2, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_AssignedInStream_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        InS2: InStream;
    begin
        // C6: InS2 := InS; InS2 is converted
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS);
        InS2 := InS;
        H.ObserveResult(Observer, Base64.ToBase64(InS2, true), H.HundredA());
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_ReadTextWholeBeforeCall_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        Skipped: Text;
    begin
        // C7 (neighbor of C1 and C2): ReadText(T) without a length before the call
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS);
        InS.ReadText(Skipped);
        Observer.Observe('read_strlen', Format(StrLen(Skipped)));
        Observer.Observe('eos_after_read', Format(InS.EOS()));
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('read_strlen', '100');
        Observer.Expect('eos_after_read', 'Yes');
        Observer.Expect('crlf_at', '0');
        Observer.Expect('length', '0');
        Observer.Expect('codes_76_to_78', '');
        Observer.Expect('equals_text_form', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_ReadWithLengthBeforeCall_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        Skipped: Text;
    begin
        // C8 (neighbor of C1 and C2): InS.Read(T, 10) before the call
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS);
        InS.Read(Skipped, 10);
        Observer.Observe('read_strlen', Format(StrLen(Skipped)));
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('read_strlen', '10');
#if BC28PLUS // 27.5 converts from the read position (Base64LineBreaks.al, ToBase64_InStream_EmptyPartReadAndSecondCall)
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '138');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'Yes');
#else
        Observer.Expect('crlf_at', '77');
        Observer.Expect('length', '122');
        Observer.Expect('codes_76_to_78', '66 13 10 ');
        Observer.Expect('equals_text_form', 'No');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_TempBlobReadBeforeCall_LineBreaks()
    var
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        Skipped: Text;
    begin
        // C9 (control for C2): the same Read(T) before the call on a Temp Blob stream
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        TempBlob.CreateInStream(InS);
        InS.Read(Skipped);
        Observer.Observe('read_strlen', Format(StrLen(Skipped)));
        H.ObserveResult(Observer, Base64.ToBase64(InS, true), H.HundredA());
        Observer.Expect('read_strlen', '100');
        Observer.Expect('crlf_at', '0');
        Observer.Expect('length', '0');
        Observer.Expect('codes_76_to_78', '');
        Observer.Expect('equals_text_form', 'No');
        Observer.Verify();
    end;

#if BC28PLUS // ToBase64(InStream, Boolean, OutStream) exists in System Application 28 and later
    local procedure ObserveTarget(var Observer: Codeunit "Probe Observer"; var TargetInS: InStream; var FirstLineInS: InStream)
    var
        B: Byte;
        V: Integer;
        Pos: Integer;
        Around: Text;
        FirstLine: Text;
        FirstLineLength: Integer;
    begin
        while not TargetInS.EOS() do begin
            TargetInS.Read(B);
            Pos += 1;
            V := B;
            if (Pos >= 76) and (Pos <= 78) then
                Around += Format(V) + ' ';
        end;
        Observer.Observe('written_length', Format(Pos));
        Observer.Observe('written_codes_76_to_78', Around);
        FirstLineLength := FirstLineInS.ReadText(FirstLine);
        Observer.Observe('first_readtext_return', Format(FirstLineLength));
        Observer.Observe('first_readtext_strlen', Format(StrLen(FirstLine)));
    end;

    [Test]
    procedure ToBase64_OutStreamFormToTempBlob_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        Target: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        TargetOutS: OutStream;
        TargetInS: InStream;
        FirstLineInS: InStream;
    begin
        // D1: the A1 holder as source, a Temp Blob's empty OutStream as target
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS);
        Target.CreateOutStream(TargetOutS);
        Base64.ToBase64(InS, true, TargetOutS);
        Target.CreateInStream(TargetInS);
        Target.CreateInStream(FirstLineInS);
        ObserveTarget(Observer, TargetInS, FirstLineInS);
        Observer.Expect('written_length', '138');
        Observer.Expect('written_codes_76_to_78', '66 13 10 ');
        Observer.Expect('first_readtext_return', '76');
        Observer.Expect('first_readtext_strlen', '76');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_OutStreamFormToTempTableBlob_LineBreaks()
    var
        Holder: Record "STR B64 Holder Temp";
        TargetHolder: Record "STR B64 Holder Temp";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        TargetOutS: OutStream;
        TargetInS: InStream;
        FirstLineInS: InStream;
    begin
        // D2: the A1 holder as source, a second TableType = Temporary record's empty Blob field as target
        Holder.Data.CreateOutStream(OutS);
        OutS.WriteText(H.HundredA());
        Holder.Data.CreateInStream(InS);
        TargetHolder.Data.CreateOutStream(TargetOutS);
        Base64.ToBase64(InS, true, TargetOutS);
        TargetHolder.Data.CreateInStream(TargetInS);
        TargetHolder.Data.CreateInStream(FirstLineInS);
        ObserveTarget(Observer, TargetInS, FirstLineInS);
        Observer.Expect('written_length', '138');
        Observer.Expect('written_codes_76_to_78', '66 13 10 ');
        Observer.Expect('first_readtext_return', '76');
        Observer.Expect('first_readtext_strlen', '76');
        Observer.Verify();
    end;
#endif
}
