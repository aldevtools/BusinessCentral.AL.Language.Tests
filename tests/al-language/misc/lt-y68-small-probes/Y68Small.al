// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93654, codeunits 93657-93660.
// Probe (writer Y68, NP lane probes Q5 and two of Q6):
//   Q5  Evaluate(RecordId, 'Table: A,B') on a two-field key Code[20] + Text[50] (blanks, mixed case, quotes, empty parts), and Format(RecordId) of rows holding such values.
//   Q6  A guarded Codeunit.Run whose OnRun calls a TryFunction that writes (TryFunctionWrite): returned value, last error text and code, rows.
//   Q6  InStream.ReadText / Read on a UTF-8 stream over UTF-16 bytes.
// Probe: values recorded on the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix.

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
    procedure Q6_CodeunitRun_IfOnRunCallsWritingTryFunction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunMode(1, 'expression form', Observer);
        RunMode(2, 'statement form', Observer);
        RunMode(3, 'if form', Observer);
        RunMode(4, 'if not form', Observer);
        RunMode(5, 'insert then error', Observer);
        RunMode(6, 'commit inside', Observer);
        RunMode(7, 'modify only', Observer);
        RunMode(8, 'temporary record', Observer);
        RunMode(9, 'nested codeunit run', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Q6_CodeunitRun_StatementAsserterror_OnRunCallsWritingTryFunction()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT Y68 Two Key";
        Runner: Codeunit "LT Y68 Try Runner";
    begin
        K.DeleteAll();
        Commit();
        Runner.SetMode(1);
        asserterror Runner.Run();
        Observer.ObserveError('statement');
        Observer.Observe('statement rows', Rows());
        Runner.SetMode(1);
        asserterror if Runner.Run() then;
        Observer.ObserveError('if wrapped');
        Observer.Observe('if wrapped rows', Rows());
        K.DeleteAll();
        Commit();
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
        end;
        exit(R);
    end;

    local procedure ReadOne(var Rec: Record "LT Y68 Bytes"; Enc: TextEncoding; MaxLen: Integer): Text
    var
        Ins: InStream;
        T: Text;
        N: Integer;
    begin
        Rec.Data.CreateInStream(Ins, Enc);
        N := Ins.ReadText(T, MaxLen);
        exit(Format(N) + '/' + Dump(T) + '/eos=' + Format(Ins.EOS()));
    end;

    local procedure ReadRead(var Rec: Record "LT Y68 Bytes"; Enc: TextEncoding): Text
    var
        Ins: InStream;
        T: Text;
        N: Integer;
    begin
        Rec.Data.CreateInStream(Ins, Enc);
        N := Ins.Read(T);
        exit(Format(N) + '/' + Dump(T) + '/eos=' + Format(Ins.EOS()));
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
        Nested: Codeunit "LT Y68 Try Runner";
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
            9:
                begin
                    Nested.SetMode(1);
                    Ok := Nested.Run();
                    LogText += 'nested=' + Format(Ok) + ';';
                end;
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
