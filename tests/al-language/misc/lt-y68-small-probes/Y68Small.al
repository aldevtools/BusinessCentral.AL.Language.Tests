// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93654, codeunits 93657-93660.
// Probe (writer Y68, NP lane probes Q5 and two of Q6):
//   Q5  Evaluate(RecordId, 'Table: A,B') on a two-field key Code[20] + Text[50] (blanks, mixed case, quotes, empty parts), and Format(RecordId) of rows holding such values.
//   Q6  A guarded Codeunit.Run whose OnRun calls a TryFunction that writes (TryFunctionWrite): returned value, last error text and code, rows.
//   Q6  InStream.ReadText / Read on a UTF-8 stream over UTF-16 bytes.
// Facts: a guarded Codeunit.Run (Ok := Codeunit.Run, or if Codeunit.Run then) is itself a TryFunction scope: a write (Insert, Modify) or a Commit in the OnRun
//   raises TryFunctionWrite 'Call to the function 'INSERT' is not allowed inside the call to '<method that calls Run>' when it is used as a TryFunction.' and
//   the guard returns false; no row is written. Same on 27.5, 28.5, 29.0 (CI containers). BC 29 SaaS sandbox allows these writes (ok = Yes, rows written):
//   the SaaS server does not apply the rule, so the Q6 Codeunit.Run values are the CI ones. A Commit inside the run fails the same way. A temporary record write is allowed.
// Probe: other values recorded on the BC 29 SaaS sandbox; all BC versions are checked by the corpus CI matrix.

table 93654 "LT Y68 Two Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; A; Code[20]) { }
        field(2; B; Text[50]) { }
    }

    keys
    {
        key(PK; A, B) { Clustered = true; }
    }
}

table 93655 "LT Y68 Bytes"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 93657 "LT Y68 Small Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Eval(Value: Text): Text
    var
        Rid: RecordId;
        Ok: Boolean;
        Back: Text;
    begin
        Ok := Evaluate(Rid, Value);
        Back := '';
        if Ok then
            Back := Format(Rid);
        exit('eval=' + Format(Ok) + '|back=' + Back + '|table=' + Format(Rid.TableNo()));
    end;

    [Test]
    procedure Q5_Evaluate_RecordId_CodeAndText_Forms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('plain', Eval('LT Y68 Two Key: A1,Hello'));
        Observer.Observe('mixed case code', Eval('LT Y68 Two Key: aBc,Hello'));
        Observer.Observe('mixed case text', Eval('LT Y68 Two Key: ABC,hELLO World'));
        Observer.Observe('blank in text', Eval('LT Y68 Two Key: A1,Hello World'));
        Observer.Observe('blank in code', Eval('LT Y68 Two Key: A 1,Hello'));
        Observer.Observe('blanks around comma', Eval('LT Y68 Two Key: A1 , Hello'));
        Observer.Observe('leading blank first', Eval('LT Y68 Two Key:  A1,Hello'));
        Observer.Observe('trailing blank second', Eval('LT Y68 Two Key: A1,Hello '));
        Observer.Observe('empty text part', Eval('LT Y68 Two Key: A1,'));
        Observer.Observe('empty quoted text part', Eval('LT Y68 Two Key: A1,""'));
        Observer.Observe('empty code part', Eval('LT Y68 Two Key: ,Hello'));
        Observer.Observe('empty quoted code part', Eval('LT Y68 Two Key: "",Hello'));
        Observer.Observe('both empty', Eval('LT Y68 Two Key: ,'));
        Observer.Observe('comma in quoted text', Eval('LT Y68 Two Key: A1,"x,y"'));
        Observer.Observe('comma in quoted code', Eval('LT Y68 Two Key: "A,1",Hello'));
        Observer.Observe('quote inside text', Eval('LT Y68 Two Key: A1,say "hi"'));
        Observer.Observe('quoted text with quote', Eval('LT Y68 Two Key: A1,"say ""hi"""'));
        Observer.Observe('apostrophe', Eval('LT Y68 Two Key: A1,it''s'));
        Observer.Observe('quote inside code', Eval('LT Y68 Two Key: A"1,Hello'));
        Observer.Observe('quoted blank text', Eval('LT Y68 Two Key: A1," "'));
        Observer.Observe('only first', Eval('LT Y68 Two Key: A1'));
        Observer.Observe('three parts', Eval('LT Y68 Two Key: A1,x,y'));
        Observer.Observe('code too long', Eval('LT Y68 Two Key: ABCDEFGHIJKLMNOPQRSTU,Hello'));
        Observer.Observe('table id', Eval('Table 93654: A1,Hello'));
        Observer.Observe('semicolon', Eval('LT Y68 Two Key: A1;Hello'));
        Observer.Expect('plain', 'eval=Yes|back=LT Y68 Two Key: A1,Hello|table=93654');
        Observer.Expect('mixed case code', 'eval=Yes|back=LT Y68 Two Key: ABC,Hello|table=93654');
        Observer.Expect('mixed case text', 'eval=Yes|back=LT Y68 Two Key: ABC,hELLO World|table=93654');
        Observer.Expect('blank in text', 'eval=Yes|back=LT Y68 Two Key: A1,Hello World|table=93654');
        Observer.Expect('blank in code', 'eval=Yes|back=LT Y68 Two Key: A 1,Hello|table=93654');
        Observer.Expect('blanks around comma', 'eval=Yes|back=LT Y68 Two Key: A1,Hello|table=93654');
        Observer.Expect('leading blank first', 'eval=Yes|back=LT Y68 Two Key: A1,Hello|table=93654');
        Observer.Expect('trailing blank second', 'eval=Yes|back=LT Y68 Two Key: A1,Hello|table=93654');
        Observer.Expect('empty text part', 'eval=Yes|back=LT Y68 Two Key: A1|table=93654');
        Observer.Expect('empty quoted text part', 'eval=Yes|back=LT Y68 Two Key: A1,""|table=93654');
        Observer.Expect('empty code part', 'eval=Yes|back=LT Y68 Two Key: "",Hello|table=93654');
        Observer.Expect('empty quoted code part', 'eval=Yes|back=LT Y68 Two Key: "",Hello|table=93654');
        Observer.Expect('both empty', 'eval=Yes|back=LT Y68 Two Key: ""|table=93654');
        Observer.Expect('comma in quoted text', 'eval=Yes|back=LT Y68 Two Key: A1,"x,y"|table=93654');
        Observer.Expect('comma in quoted code', 'eval=Yes|back=LT Y68 Two Key: "A,1",Hello|table=93654');
        Observer.Expect('quote inside text', 'eval=Yes|back=LT Y68 Two Key: A1,say "hi"|table=93654');
        Observer.Expect('quoted text with quote', 'eval=Yes|back=LT Y68 Two Key: A1,say "hi"|table=93654');
        Observer.Expect('apostrophe', 'eval=Yes|back=LT Y68 Two Key: A1,it''s|table=93654');
        Observer.Expect('quote inside code', 'eval=Yes|back=LT Y68 Two Key: A"1,Hello|table=93654');
        Observer.Expect('quoted blank text', 'eval=Yes|back=LT Y68 Two Key: A1," "|table=93654');
        Observer.Expect('only first', 'eval=Yes|back=LT Y68 Two Key: A1|table=93654');
        Observer.Expect('three parts', 'eval=No|back=|table=0');
        Observer.Expect('code too long', 'eval=No|back=|table=0');
        Observer.Expect('table id', 'eval=Yes|back=LT Y68 Two Key: A1,Hello|table=93654');
        Observer.Expect('semicolon', 'eval=Yes|back=LT Y68 Two Key: A1;HELLO|table=93654');
        Observer.Verify();
    end;

    [Test]
    procedure Q5_Format_RecordId_CodeAndText_Rows()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT Y68 Two Key";
    begin
        K.DeleteAll();
        AddKey('A1', 'Hello');
        AddKey('a2', 'Hello World');
        AddKey('A 3', 'x');
        AddKey('A4', '');
        AddKey('A5', ' lead');
        AddKey('A6', 'x,y');
        AddKey('A7', 'say "hi"');
        AddKey('A8', 'it''s');
        AddKey('A,9', 'x');
        AddKey('', 'only text');
        K.FindSet();
        repeat
            Observer.Observe('format [' + K.A + '|' + K.B + ']', Format(K.RecordId));
        until K.Next() = 0;
        K.SetRange(A, 'A4');
        K.FindFirst();
        Observer.Observe('roundtrip A4', Eval(Format(K.RecordId)));
        K.SetRange(A, 'A6');
        K.FindFirst();
        Observer.Observe('roundtrip A6', Eval(Format(K.RecordId)));
        K.SetRange(A, 'A7');
        K.FindFirst();
        Observer.Observe('roundtrip A7', Eval(Format(K.RecordId)));
        K.DeleteAll();
        Observer.Expect('format [|only text]', 'LT Y68 Two Key: "",only text');
        Observer.Expect('format [A 3|x]', 'LT Y68 Two Key: A 3,x');
        Observer.Expect('format [A,9|x]', 'LT Y68 Two Key: "A,9",x');
        Observer.Expect('format [A1|Hello]', 'LT Y68 Two Key: A1,Hello');
        Observer.Expect('format [A2|Hello World]', 'LT Y68 Two Key: A2,Hello World');
        Observer.Expect('format [A4|]', 'LT Y68 Two Key: A4,""');
        Observer.Expect('format [A5| lead]', 'LT Y68 Two Key: A5," lead"');
        Observer.Expect('format [A6|x,y]', 'LT Y68 Two Key: A6,"x,y"');
        Observer.Expect('format [A7|say "hi"]', 'LT Y68 Two Key: A7,say "hi"');
        Observer.Expect('format [A8|it''s]', 'LT Y68 Two Key: A8,it''s');
        Observer.Expect('roundtrip A4', 'eval=Yes|back=LT Y68 Two Key: A4,""|table=93654');
        Observer.Expect('roundtrip A6', 'eval=Yes|back=LT Y68 Two Key: A6,"x,y"|table=93654');
        Observer.Expect('roundtrip A7', 'eval=Yes|back=LT Y68 Two Key: A7,say "hi"|table=93654');
        Observer.Verify();
    end;

    local procedure AddKey(A: Code[20]; B: Text[50])
    var
        K: Record "LT Y68 Two Key";
    begin
        K.A := A;
        K.B := B;
        K.Insert();
    end;

    // Q6: a guarded Codeunit.Run whose OnRun calls a TryFunction that writes.
    local procedure Rows(): Text
    var
        K: Record "LT Y68 Two Key";
        Result: Text;
    begin
        if K.FindSet() then
            repeat
                Result += '[' + K.A + '|' + K.B + ']';
            until K.Next() = 0;
        exit(Result);
    end;

    local procedure RunMode(Mode: Integer; Name: Text; var Observer: Codeunit "Probe Observer")
    var
        K: Record "LT Y68 Two Key";
        Runner: Codeunit "LT Y68 Try Runner";
        Ok: Boolean;
    begin
        K.DeleteAll();
        Commit();
        ClearLastError();
        Runner.SetMode(Mode);
        Ok := Runner.Run();
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.Observe(Name + ' text', GetLastErrorText());
        Observer.Observe(Name + ' code', GetLastErrorCode());
        Observer.Observe(Name + ' rows', Rows());
        Observer.Observe(Name + ' log', Runner.Log());
        ClearLastError();
        K.DeleteAll();
        Commit();
    end;

    [Test]
    procedure Q6_CodeunitRun_GuardedOnRunWrites_ExpressionStatementIfForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMode(1, 'expression form', Observer);
        RunMode(2, 'statement form', Observer);
        RunMode(3, 'if form', Observer);
        RunMode(4, 'if not form', Observer);
        Observer.Expect('expression form ok', 'No');
        Observer.Expect('expression form text', 'Call to the function ''INSERT'' is not allowed inside the call to ''RunMode'' when it is used as a TryFunction.');
        Observer.Expect('expression form code', 'TryFunctionWrite');
        Observer.Expect('expression form rows', '');
        Observer.Expect('expression form log', 'start;');
        Observer.Expect('statement form ok', 'Yes');
        Observer.Expect('statement form text', '');
        Observer.Expect('statement form code', '');
        Observer.Expect('statement form rows', '[2|]');
        Observer.Expect('statement form log', 'start;end ok=No;');
        Observer.Expect('if form ok', 'No');
        Observer.Expect('if form text', 'Call to the function ''INSERT'' is not allowed inside the call to ''RunMode'' when it is used as a TryFunction.');
        Observer.Expect('if form code', 'TryFunctionWrite');
        Observer.Expect('if form rows', '');
        Observer.Expect('if form log', 'start;');
        Observer.Expect('if not form ok', 'No');
        Observer.Expect('if not form text', 'Call to the function ''INSERT'' is not allowed inside the call to ''RunMode'' when it is used as a TryFunction.');
        Observer.Expect('if not form code', 'TryFunctionWrite');
        Observer.Expect('if not form rows', '');
        Observer.Expect('if not form log', 'start;');
        Observer.Verify();
    end;

    [Test]
    procedure Q6_CodeunitRun_GuardedOnRunWrites_ErrorCommitModifyTemporary()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMode(5, 'insert then error', Observer);
        RunMode(6, 'commit inside', Observer);
        RunMode(7, 'modify only', Observer);
        RunMode(8, 'temporary record', Observer);
        Observer.Expect('insert then error ok', 'No');
        Observer.Expect('insert then error text', 'Call to the function ''INSERT'' is not allowed inside the call to ''RunMode'' when it is used as a TryFunction.');
        Observer.Expect('insert then error code', 'TryFunctionWrite');
        Observer.Expect('insert then error rows', '');
        Observer.Expect('insert then error log', 'start;');
        Observer.Expect('commit inside ok', 'No');
        Observer.Expect('commit inside text', 'Call to the function ''INSERT'' is not allowed inside the call to ''RunMode'' when it is used as a TryFunction.');
        Observer.Expect('commit inside code', 'TryFunctionWrite');
        Observer.Expect('commit inside rows', '');
        Observer.Expect('commit inside log', 'start;');
        Observer.Expect('modify only ok', 'No');
        Observer.Expect('modify only text', 'Call to the function ''MODIFY'' is not allowed inside the call to ''RunMode'' when it is used as a TryFunction.');
        Observer.Expect('modify only code', 'TryFunctionWrite');
        Observer.Expect('modify only rows', '');
        Observer.Expect('modify only log', 'start;');
        Observer.Expect('temporary record ok', 'Yes');
        Observer.Expect('temporary record text', '');
        Observer.Expect('temporary record code', '');
        Observer.Expect('temporary record rows', '');
        Observer.Expect('temporary record log', 'start;end ok=Yes;');
        Observer.Verify();
    end;

    // Q6: UTF-16 bytes read through a UTF-8 stream.
    local procedure HexVal(c: Char): Integer
    begin
        exit(StrPos('0123456789ABCDEF', UpperCase(Format(c))) - 1);
    end;

    local procedure PutBytes(var Rec: Record "LT Y68 Bytes"; Hex: Text)
    var
        Out: OutStream;
        B: Byte;
        i: Integer;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Data.CreateOutStream(Out);
        i := 1;
        while i < StrLen(Hex) do begin
            B := HexVal(Hex[i]) * 16 + HexVal(Hex[i + 1]);
            Out.Write(B);
            i += 2;
        end;
        Rec.Insert();
        Rec.CalcFields(Data);
    end;

    local procedure Dump(Txt: Text): Text
    var
        i: Integer;
        Ord: Integer;
        R: Text;
    begin
        for i := 1 to StrLen(Txt) do begin
            Ord := Txt[i];
            R += Format(Ord) + ' ';
        end;
        exit(Format(StrLen(Txt)) + ':' + R);
    end;

    local procedure ReadAll(var Rec: Record "LT Y68 Bytes"; Enc: TextEncoding): Text
    var
        Result: Text;
    begin
        if TryReadAll(Rec, Enc, Result) then
            exit(Result);
        Result := 'ERROR ' + GetLastErrorCode() + ': ' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryReadAll(var Rec: Record "LT Y68 Bytes"; Enc: TextEncoding; var Result: Text)
    var
        Ins: InStream;
        T: Text;
        R: Text;
        N: Integer;
        Guard: Integer;
    begin
        Rec.Data.CreateInStream(Ins, Enc);
        while (not Ins.EOS()) and (Guard < 10) do begin
            Guard += 1;
            N := Ins.ReadText(T);
            R += '[' + Format(N) + '/' + Dump(T) + ']';
            Result := R;
        end;
        Result := R;
    end;

    local procedure ReadOne(var Rec: Record "LT Y68 Bytes"; Enc: TextEncoding; MaxLen: Integer): Text
    var
        Result: Text;
    begin
        if TryReadOne(Rec, Enc, MaxLen, Result) then
            exit(Result);
        Result := 'ERROR ' + GetLastErrorCode() + ': ' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryReadOne(var Rec: Record "LT Y68 Bytes"; Enc: TextEncoding; MaxLen: Integer; var Result: Text)
    var
        Ins: InStream;
        T: Text;
        N: Integer;
    begin
        Rec.Data.CreateInStream(Ins, Enc);
        N := Ins.ReadText(T, MaxLen);
        Result := Format(N) + '/' + Dump(T) + '/eos=' + Format(Ins.EOS());
    end;

    local procedure ReadRead(var Rec: Record "LT Y68 Bytes"; Enc: TextEncoding): Text
    var
        Result: Text;
    begin
        if TryReadRead(Rec, Enc, Result) then
            exit(Result);
        Result := 'ERROR ' + GetLastErrorCode() + ': ' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryReadRead(var Rec: Record "LT Y68 Bytes"; Enc: TextEncoding; var Result: Text)
    var
        Ins: InStream;
        T: Text;
        N: Integer;
    begin
        Rec.Data.CreateInStream(Ins, Enc);
        N := Ins.Read(T);
        Result := Format(N) + '/' + Dump(T) + '/eos=' + Format(Ins.EOS());
    end;

    [Test]
    procedure Q6_ReadText_Utf8_OfUtf16Bytes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT Y68 Bytes";
    begin
        PutBytes(Rec, '6100620063000000');
        Observer.Observe('abc nul-padded ReadText', ReadAll(Rec, TextEncoding::UTF8));
        Observer.Observe('abc ReadText 2', ReadOne(Rec, TextEncoding::UTF8, 2));
        Observer.Observe('abc ReadText 100', ReadOne(Rec, TextEncoding::UTF8, 100));
        Observer.Observe('abc Read', ReadRead(Rec, TextEncoding::UTF8));
        Observer.Observe('abc as utf16', ReadAll(Rec, TextEncoding::UTF16));
        PutBytes(Rec, 'FFFE6100620063000D000A006400');
        Observer.Observe('bom crlf ReadText', ReadAll(Rec, TextEncoding::UTF8));
        Observer.Observe('bom crlf utf16', ReadAll(Rec, TextEncoding::UTF16));
        PutBytes(Rec, '61000A006200');
        Observer.Observe('lf utf8', ReadAll(Rec, TextEncoding::UTF8));
        PutBytes(Rec, 'E9006800');
        Observer.Observe('e-acute utf8', ReadAll(Rec, TextEncoding::UTF8));
        Observer.Observe('e-acute utf16', ReadAll(Rec, TextEncoding::UTF16));
        PutBytes(Rec, '3DD800DE');
        Observer.Observe('surrogate utf8', ReadAll(Rec, TextEncoding::UTF8));
        Observer.Observe('surrogate utf16', ReadAll(Rec, TextEncoding::UTF16));
        PutBytes(Rec, '610062');
        Observer.Observe('odd length utf16', ReadAll(Rec, TextEncoding::UTF16));
        PutBytes(Rec, '00000000');
        Observer.Observe('only nuls utf8', ReadAll(Rec, TextEncoding::UTF8));
        Rec.DeleteAll();
        Observer.Expect('abc nul-padded ReadText', '[1/1:97 ][1/1:98 ][1/1:99 ][0/0:][0/0:]');
        Observer.Expect('abc ReadText 2', '1/1:97 /eos=No');
        Observer.Expect('abc ReadText 100', '1/1:97 /eos=No');
        Observer.Expect('abc Read', '2/1:97 /eos=No');
        Observer.Expect('abc as utf16', '[6/3:97 98 99 ]');
        Observer.Expect('bom crlf ReadText', 'ERROR InvalidStreamData: Invalid data encountered in stream, unable to read text.');
        Observer.Expect('bom crlf utf16', '[6/3:97 98 99 ][2/1:100 ]');
        Observer.Expect('lf utf8', '[1/1:97 ][0/0:][0/0:][1/1:98 ]');
        Observer.Expect('e-acute utf8', 'ERROR InvalidStreamData: Invalid data encountered in stream, unable to read text.');
        Observer.Expect('e-acute utf16', '[4/2:233 104 ]');
        Observer.Expect('surrogate utf8', 'ERROR InvalidStreamData: Invalid data encountered in stream, unable to read text.');
        Observer.Expect('surrogate utf16', '[4/2:55357 56832 ]');
        Observer.Expect('odd length utf16', '[2/1:97 ]');
        Observer.Expect('only nuls utf8', '[0/0:][0/0:][0/0:][0/0:]');
        Observer.Verify();
    end;
}

codeunit 93658 "LT Y68 Try Runner"
{
    SingleInstance = false;

    var
        Mode: Integer;
        LogText: Text;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
        LogText := '';
    end;

    procedure Log(): Text
    begin
        exit(LogText);
    end;

    trigger OnRun()
    var
        Ok: Boolean;
    begin
        LogText += 'start;';
        case Mode of
            1:
                Ok := TryInsert('1');
            2:
                TryInsert('2');
            3:
                if TryInsert('3') then
                    LogText += 'then;'
                else
                    LogText += 'else;';
            4:
                if not TryInsert('4') then
                    LogText += 'not-branch;';
            5:
                Ok := TryInsertThenError('5');
            6:
                Ok := TryInsertCommit('6');
            7:
                Ok := TryModifyOnly('7');
            8:
                Ok := TryTemp('8');
        end;
        LogText += 'end ok=' + Format(Ok) + ';';
    end;

    [TryFunction]
    local procedure TryInsert(KeyA: Code[20])
    var
        K: Record "LT Y68 Two Key";
    begin
        K.A := KeyA;
        K.Insert();
    end;

    [TryFunction]
    local procedure TryInsertThenError(KeyA: Code[20])
    var
        K: Record "LT Y68 Two Key";
    begin
        K.A := KeyA;
        K.Insert();
        Error('after insert');
    end;

    [TryFunction]
    local procedure TryInsertCommit(KeyA: Code[20])
    var
        K: Record "LT Y68 Two Key";
    begin
        K.A := KeyA;
        K.Insert();
        Commit();
    end;

    [TryFunction]
    local procedure TryModifyOnly(KeyA: Code[20])
    var
        K: Record "LT Y68 Two Key";
    begin
        K.A := KeyA;
        K.Modify();
    end;

    [TryFunction]
    local procedure TryTemp(KeyA: Code[20])
    var
        K: Record "LT Y68 Two Key" temporary;
    begin
        K.A := KeyA;
        K.Insert();
    end;
}
