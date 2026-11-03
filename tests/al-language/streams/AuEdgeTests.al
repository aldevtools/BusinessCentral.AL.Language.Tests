// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-arrays
//   and .../methods-auto/variant/variant-data-type, .../methods-auto/dictionary/dictionary-data-type, .../methods-auto/bigtext/bigtext-data-type,
//   .../developer/devenv-control-addin-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 80100-80103 (AuObjects.al)
// Probe: every literal asserted below is what BC produced in the corpus CI (Linux container); BC 27, 28 and 29 are checked by the CI legs.
// Settles corpus issue 645 (language edges), items 9 (add-in events on a test page, Business Chart Buffer Initialize), 10 (BigInteger into Option
//   and Enum), 14 (Variant into a var Text parameter), 15 (Dictionary order after two removes and two adds), 17 (BigText.Write of other characters),
//   18 (Clear of rows of other element types, CopyArray into a row, four-dimensional rows), 19 (case on a Variant: error code; case with only else).
// Items 16 and the CopyArray part of 18 do not compile: must-not-compile cases 1160, 1161 (AL0196) and 1162 (AL0193).
// BC versions: 27, 28, 29

codeunit 80150 "LT AU Edge Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // ---------------- helpers ----------------

    local procedure Outcome(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit('ok ' + Value);
        exit('error ' + GetLastErrorText() + ' code=' + GetLastErrorCode());
    end;

    local procedure HexOf(B: Byte): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1));
    end;

    local procedure BlobHex(var TempBlob: Codeunit "Temp Blob"): Text
    var
        Ins: InStream;
        B: Byte;
        Hex: Text;
    begin
        TempBlob.CreateInStream(Ins);
        while not Ins.EOS() do begin
            Ins.Read(B);
            Hex += HexOf(B);
        end;
        exit(Hex);
    end;

    local procedure LogText(): Text
    var
        Log: Record "LT AU Log";
        T: Text;
    begin
        if Log.FindSet() then
            repeat
                T += Log.What + ';';
            until Log.Next() = 0;
        exit(T);
    end;

    // ---------------- item 10: BigInteger into an Option and an Enum ----------------

    [TryFunction]
    local procedure TryBigToOption(B: BigInteger; var R: Text)
    var
        O: Option A,B,C;
    begin
        O := B;
        R := Format(O) + '|' + Format(O, 0, 2);
    end;

#if BC29PLUS
    // BigInteger into an Enum compiles only on BC 29: the BC 27.5 and 28.5 servers refuse the publish with
    // "error AL0122: Cannot implicitly convert type 'BigInteger' to 'Enum "LT AU Kind"'" (corpus CI, 2026-10-19).
    [TryFunction]
    local procedure TryBigToEnum(B: BigInteger; var R: Text)
    var
        K: Enum "LT AU Kind";
    begin
        K := B;
        R := Format(K) + '|' + Format(K.AsInteger());
    end;

    [Test]
    procedure BigInteger_IntoOption_LackingOrdinal()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Observer.Observe('one', Outcome(TryBigToOption(1, R), R));
        Observer.Observe('seven', Outcome(TryBigToOption(7, R), R));
        Observer.Observe('minus1', Outcome(TryBigToOption(-1, R), R));
        Observer.Expect('one', 'ok B|1');
        Observer.Expect('seven', 'ok 7|7');
        Observer.Expect('minus1', 'ok -1|-1');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_IntoOption_BeyondInteger()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Observer.Observe('max', Outcome(TryBigToOption(2147483647L, R), R));
        Observer.Observe('max_plus_1', Outcome(TryBigToOption(2147483648L, R), R));
        Observer.Observe('min_minus_1', Outcome(TryBigToOption(-2147483649L, R), R));
        Observer.Expect('max', 'ok 2147483647|2147483647');
        Observer.Expect('max_plus_1', 'error Overflow under conversion of System.Int64 value 2147483648 to System.Int32. code=ConversionCast');
        Observer.Expect('min_minus_1', 'error Overflow under conversion of System.Int64 value -2147483649 to System.Int32. code=ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_IntoEnum_BeyondInteger()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        Observer.Observe('lacking', Outcome(TryBigToEnum(7, R), R));
        Observer.Observe('max_plus_1', Outcome(TryBigToEnum(2147483648L, R), R));
        Observer.Observe('min_minus_1', Outcome(TryBigToEnum(-2147483649L, R), R));
        Observer.Expect('lacking', 'ok 7|7');
        Observer.Expect('max_plus_1', 'error Overflow under conversion of System.Int64 value 2147483648 to System.Int32. code=ConversionCast');
        Observer.Expect('min_minus_1', 'error Overflow under conversion of System.Int64 value -2147483649 to System.Int32. code=ConversionCast');
        Observer.Verify();
    end;
#endif

    // ---------------- item 14: a Variant into a var Text parameter ----------------

    local procedure AppendX(var T: Text): Text
    begin
        T := T + 'x';
        exit('[' + T + ']');
    end;

    [TryFunction]
    local procedure TryVarText(var V: Variant; var R: Text)
    begin
        R := AppendX(V);
    end;

    local procedure VariantKind(V: Variant): Text
    begin
        if V.IsText() then
            exit('Text');
        if V.IsBigInteger() then
            exit('BigInteger');
        if V.IsDecimal() then
            exit('Decimal');
        if V.IsInteger() then
            exit('Integer');
        exit('other');
    end;

    [Test]
    procedure Variant_BigInteger_ToVarTextParameter()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        B: BigInteger;
        R: Text;
    begin
        B := 3000000000L;
        V := B;
        Observer.Observe('call', Outcome(TryVarText(V, R), R));
        Observer.Observe('after', VariantKind(V) + ' ' + Format(V));
        Observer.Expect('call', 'error The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value. code=TypeConversion');
        Observer.Expect('after', 'BigInteger 3000000000');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_Decimal_ToVarTextParameter()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        D: Decimal;
        R: Text;
    begin
        D := 1.5;
        V := D;
        Observer.Observe('call', Outcome(TryVarText(V, R), R));
        Observer.Observe('after', VariantKind(V) + ' ' + Format(V));
        Observer.Expect('call', 'error The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value. code=TypeConversion');
        Observer.Expect('after', 'Decimal 1.5');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_Text_ToVarTextParameter()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        T: Text;
        R: Text;
    begin
        T := 'ab';
        V := T;
        Observer.Observe('call', Outcome(TryVarText(V, R), R));
        Observer.Observe('after', VariantKind(V) + ' ' + Format(V));
        Observer.Expect('call', 'ok [abx]');
        Observer.Expect('after', 'Text abx');
        Observer.Verify();
    end;

    // ---------------- item 15: Dictionary keys after two removes and two adds ----------------

    local procedure JoinKeys(D: Dictionary of [Text, Integer]): Text
    var
        K: Text;
        T: Text;
    begin
        foreach K in D.Keys() do
            T += K + ',';
        exit(T);
    end;

    [Test]
    procedure Dictionary_TwoRemovesTwoAdds_KeyOrder()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
        E: Dictionary of [Text, Integer];
        i: Integer;
    begin
        for i := 1 to 5 do begin
            D.Add('k' + Format(i), i);
            E.Add('k' + Format(i), i);
        end;
        D.Remove('k2');
        D.Remove('k4');
        D.Add('x', 6);
        D.Add('y', 7);
        Observer.Observe('remove_k2_k4', JoinKeys(D));
        E.Remove('k4');
        E.Remove('k2');
        E.Add('x', 6);
        E.Add('y', 7);
        E.Add('z', 8);
        Observer.Observe('remove_k4_k2_add3', JoinKeys(E));
        Observer.Expect('remove_k2_k4', 'k1,y,k3,x,k5,');
        Observer.Expect('remove_k4_k2_add3', 'k1,x,k3,y,k5,z,');
        Observer.Verify();
    end;

    // ---------------- item 17: BigText.Write of other characters ----------------

    local procedure OtherChars(): Text
    var
        T: Text;
    begin
        T[1] := 233;    // e acute
        T[2] := 223;    // sharp s
        T[3] := 8220;   // left double quotation mark (0x93 in Windows-1252)
        T[4] := 937;    // Greek capital omega (not in Windows-1252)
        T[5] := 20013;  // CJK U+4E2D
        T[6] := 55357;  // U+1F600 as a surrogate pair
        T[7] := 56832;
        T[8] := 160;    // no-break space
        exit(T);
    end;

    [Test]
    procedure BigText_Write_OtherChars_DefaultStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        BT: BigText;
        Outs: OutStream;
    begin
        BT.AddText(OtherChars());
        TempBlob.CreateOutStream(Outs);
        BT.Write(Outs);
        Observer.Observe('len', Format(BT.Length()));
        Observer.Observe('bytes', BlobHex(TempBlob));
        Observer.Expect('len', '8');
        Observer.Expect('bytes', '82E1C34F3F3F3FFF');
        Observer.Verify();
    end;

    [Test]
    procedure BigText_Write_OtherChars_WindowsStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        BT: BigText;
        Outs: OutStream;
    begin
        BT.AddText(OtherChars());
        TempBlob.CreateOutStream(Outs, TextEncoding::Windows);
        BT.Write(Outs);
        Observer.Observe('bytes', BlobHex(TempBlob));
        Observer.Expect('bytes', 'E9DF934F3F3F3FA0');
        Observer.Verify();
    end;

    [Test]
    procedure BigText_Write_OtherChars_MSDosAndUtf16Stream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        BT: BigText;
        Outs: OutStream;
    begin
        BT.AddText(OtherChars());
        TempBlob.CreateOutStream(Outs, TextEncoding::MSDos);
        BT.Write(Outs);
        Observer.Observe('msdos', BlobHex(TempBlob));
        TempBlob2.CreateOutStream(Outs, TextEncoding::UTF16);
        BT.Write(Outs);
        Observer.Observe('utf16', BlobHex(TempBlob2));
        Observer.Expect('msdos', '82E1C34F3F3F3FFF');
        Observer.Expect('utf16', 'E900DF001C20A9032D4E3DD800DEA000');
        Observer.Verify();
    end;

    // ---------------- item 18: rows of arrays ----------------

    [Test]
    procedure Array_ClearRow_BooleanDateCode()
    var
        Observer: Codeunit "Probe Observer";
        Bo: array[2, 2] of Boolean;
        Da: array[2, 2] of Date;
        Co: array[2, 2] of Code[10];
        i: Integer;
        j: Integer;
        T: Text;
    begin
        for i := 1 to 2 do
            for j := 1 to 2 do begin
                Bo[i, j] := true;
                Da[i, j] := DMY2Date(i, j, 2020);
                Co[i, j] := 'C' + Format(i) + Format(j);
            end;
        Clear(Bo[1]);
        Clear(Da[2]);
        Clear(Co[1]);
        for i := 1 to 2 do
            for j := 1 to 2 do
                T += Format(Bo[i, j]) + '/' + Format(Da[i, j], 0, 9) + '/' + Co[i, j] + ',';
        Observer.Observe('cells', T);
        Observer.Expect('cells', 'No/2020-01-01/,No/2020-02-01/,Yes//C21,Yes//C22,');
        Observer.Verify();
    end;

    [Test]
    procedure Array_ClearRow_GuidCharOptionBigInteger()
    var
        Observer: Codeunit "Probe Observer";
        Gu: array[2, 2] of Guid;
        Ch: array[2, 2] of Char;
        Op: array[2, 2] of Option A,B,C;
        Bi: array[2, 2] of BigInteger;
        i: Integer;
        j: Integer;
        CharCode: Integer;
        T: Text;
    begin
        for i := 1 to 2 do
            for j := 1 to 2 do begin
                Gu[i, j] := CreateGuid();
                Ch[i, j] := 65 + i;
                Op[i, j] := Op[i, j]::C;
                Bi[i, j] := 10000000000L + i;
            end;
        Clear(Gu[2]);
        Clear(Ch[1]);
        Clear(Op[2]);
        Clear(Bi[1]);
        for i := 1 to 2 do
            for j := 1 to 2 do begin
                // The Char as its code: a cleared Char is character 0, which the CI's JUnit file showed as \u0000.
                CharCode := Ch[i, j];
                T += Format(IsNullGuid(Gu[i, j])) + '/' + Format(CharCode) + '/' + Format(Op[i, j]) + '/' + Format(Bi[i, j]) + ',';
            end;
        Observer.Observe('cells', T);
        Observer.Expect('cells', 'No/0/C/0,No/0/C/0,Yes/67/A/10000000002,Yes/67/A/10000000002,');
        Observer.Verify();
    end;

    [Test]
    procedure Array_CopyArray_OneDimIntoRow()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2, 3] of Integer;
        S: array[3] of Integer;
        Short: array[2] of Integer;
        i: Integer;
        j: Integer;
        T: Text;
    begin
        S[1] := 1;
        S[2] := 2;
        S[3] := 3;
        Short[1] := 8;
        Short[2] := 9;
        CopyArray(A[2], S, 1);
        for i := 1 to 2 do
            for j := 1 to 3 do
                T += Format(A[i, j]) + ',';
        Observer.Observe('cells', T);
        Observer.Observe('short_into_row', Outcome(TryCopyShortIntoRow(A, Short), ''));
        T := '';
        for i := 1 to 2 do
            for j := 1 to 3 do
                T += Format(A[i, j]) + ',';
        Observer.Observe('cells_after_short', T);
        // A row tail (2 cells from position 2) into the 3-element S: BC 27.5, 28.5 and 29.0 raise
        // "CopyArray: The length parameter 2 does not match the length of the destination array 3." (corpus CI, 2026-10-19).
        asserterror CopyArray(S, A[2], 2);
        Observer.ObserveError('row_tail_into_1d');
        Observer.Observe('s_after', Format(S[1]) + ',' + Format(S[2]) + ',' + Format(S[3]));
        Observer.Expect('cells', '0,0,0,1,2,3,');
        Observer.Expect('short_into_row', 'error CopyArray: The length parameter 2 does not match the length of the destination array 3. code=ArrayLengthMismatch');
        Observer.Expect('cells_after_short', '0,0,0,1,2,3,');
        Observer.Expect('row_tail_into_1d|text', 'CopyArray: The length parameter 2 does not match the length of the destination array 3.');
        Observer.Expect('row_tail_into_1d|code', 'ArrayLengthMismatch');
        Observer.Expect('s_after', '1,2,3');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCopyShortIntoRow(var A: array[2, 3] of Integer; Short: array[2] of Integer)
    begin
        CopyArray(A[1], Short, 1);
    end;

    local procedure Dump4(A: array[2, 2, 2, 3] of Integer): Text
    var
        i: Integer;
        j: Integer;
        k: Integer;
        l: Integer;
        T: Text;
    begin
        for i := 1 to 2 do
            for j := 1 to 2 do
                for k := 1 to 2 do begin
                    for l := 1 to 3 do
                        T += Format(A[i, j, k, l]);
                    T += '|';
                end;
        exit(T);
    end;

    [Test]
    procedure Array_FourDimensions_Rows()
    var
        Observer: Codeunit "Probe Observer";
        A: array[2, 2, 2, 3] of Integer;
        i: Integer;
        j: Integer;
        k: Integer;
        l: Integer;
    begin
        for i := 1 to 2 do
            for j := 1 to 2 do
                for k := 1 to 2 do
                    for l := 1 to 3 do
                        A[i, j, k, l] := l;
        Observer.Observe('len', Format(ArrayLen(A)) + ',' + Format(ArrayLen(A[1])) + ',' + Format(ArrayLen(A[1, 2])) + ',' + Format(ArrayLen(A[1, 2, 1])));
        Clear(A[1, 2, 1]);
        Observer.Observe('clear_1_2_1', Dump4(A));
        Clear(A[2, 1]);
        Observer.Observe('clear_2_1', Dump4(A));
        Clear(A[1]);
        Observer.Observe('clear_1', Dump4(A));
        Observer.Expect('len', '24,12,6,3');
        Observer.Expect('clear_1_2_1', '123|123|000|123|123|123|123|123|');
        Observer.Expect('clear_2_1', '123|123|000|123|000|000|123|123|');
        Observer.Expect('clear_1', '000|000|000|000|000|000|123|123|');
        Observer.Verify();
    end;

    // ---------------- item 19: case on a Variant, case with only else ----------------

    [TryFunction]
    local procedure TryCaseVariant(V: Variant; var R: Text)
    begin
        R := 'none';
        case V of
            1:
                R := 'one';
            'a':
                R := 'a';
            else
                R := 'else';
        end;
    end;

    [Test]
    procedure Case_AssignedVariant_ErrorTextAndCode()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        R: Text;
    begin
        V := 1;
        Observer.Observe('integer', Outcome(TryCaseVariant(V, R), R));
        V := 'a';
        Observer.Observe('text', Outcome(TryCaseVariant(V, R), R));
        Observer.Expect('integer', 'error Unable to compare operands of type NavVariant with NavVariant. code=InvalidComparison');
        Observer.Expect('text', 'error Unable to compare operands of type NavVariant with NavVariant. code=InvalidComparison');
        Observer.Verify();
    end;

    local procedure ElseOnly(X: Integer): Text
    begin
        case X of
            else
                exit('else ' + Format(X));
        end;
        exit('after');
    end;

    [TryFunction]
    local procedure TryElseOnlyVariant(V: Variant; var R: Text)
    begin
        R := 'none';
        case V of
            else
                R := 'else';
        end;
    end;

    [Test]
    procedure Case_OnlyElseBranch()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        R: Text;
    begin
        Observer.Observe('integer', ElseOnly(3));
        Observer.Observe('variant_unassigned', Outcome(TryElseOnlyVariant(V, R), R));
        V := 1;
        Observer.Observe('variant_integer', Outcome(TryElseOnlyVariant(V, R), R));
        Observer.Expect('integer', 'else 3');
        Observer.Expect('variant_unassigned', 'ok else');
        Observer.Expect('variant_integer', 'ok else');
        Observer.Verify();
    end;

    // ---------------- item 9: control add-in events and calls without a client; Business Chart Buffer ----------------

    local procedure SeedRow()
    var
        Row: Record "LT AU Row";
        Log: Record "LT AU Log";
    begin
        Row.DeleteAll();
        Log.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
    end;

    [Test]
    procedure ControlAddIn_Events_OnTestPage()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT AU Addin Card";
    begin
        SeedRow();
        TP.OpenEdit();
        Observer.Observe('opened', LogText());
        TP.NameF.SetValue('two');
        TP.Close();
        Observer.Observe('closed', LogText());
        Observer.Expect('opened', 'OnOpenPage;');
        Observer.Expect('closed', 'OnOpenPage;');
        Observer.Verify();
    end;

    // Not a test: on a test page (BC 29, Linux container) invoking the action that calls CurrPage.Ctl.Ping('hello') gave "A call to Ping failed with this message: Object reference not set to an instance of an object.",
    // code TestWrapped:DotNetInvoke. A NullReference is a Linux suspect: listed in the hand-off note until the Windows nightly confirms it.
    procedure ControlAddIn_CallFromAction()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT AU Addin Card";
    begin
        SeedRow();
        TP.OpenEdit();
        asserterror TP.CallPing.Invoke();
        Observer.ObserveError('invoke');
        Observer.Finish();
    end;

    // Not a test: on a test page (BC 29, Linux container) invoking the action that calls Buffer.UpdateChart(CurrPage.Chart) gave "A call to Update failed with this message: Object reference not set to an instance of an object.",
    // code TestWrapped:DotNetInvoke. A NullReference is a Linux suspect: listed in the hand-off note until the Windows nightly confirms it.
    procedure BusinessChartBuffer_UpdateChart_OnTestPage()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT AU Chart Card";
    begin
        SeedRow();
        TP.OpenEdit();
        Observer.Observe('opened', LogText());
        asserterror TP.Draw.Invoke();
        Observer.ObserveError('draw');
        Observer.Finish();
    end;

    [Test]
    procedure BusinessChartBuffer_Initialize_InTest()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "Business Chart Buffer";
        Map: Record "Business Chart Map";
        V: Variant;
    begin
        Buffer.Initialize();
        Observer.Observe('measure', Format(Buffer.FindFirstMeasure(Map)));
        Observer.Observe('column', Format(Buffer.FindFirstColumn(Map)));
        Buffer.AddIntegerMeasure('Count', 1, Enum::"Business Chart Type"::Column);
        Buffer.SetXAxis('Month', Buffer."Data Type"::String);
        Buffer.AddColumn('Jan');
        Buffer.SetValueByIndex(0, 0, 7);
        Buffer.GetValue('Count', 0, V);
        Observer.Observe('value', Format(V));
        Observer.Observe('xcaption', Buffer.GetXCaption());
        Observer.Observe('measure_after', Format(Buffer.FindFirstMeasure(Map)) + ' ' + Format(Map.Index) + ' ' + Map.Name);
        Observer.Observe('column_after', Format(Buffer.FindFirstColumn(Map)) + ' ' + Format(Map.Index) + ' ' + Map.Name + ' ' + Map."Value String");
        Observer.Expect('measure', 'No');
        Observer.Expect('column', 'No');
        Observer.Expect('value', '7');
        Observer.Expect('xcaption', 'Month');
        Observer.Expect('measure_after', 'Yes 0 Count');
        Observer.Expect('column_after', 'Yes 0 Jan Jan');
        Observer.Verify();
    end;
}

enum 80104 "LT AU Kind"
{
    Extensible = false;

    value(0; Zero) { }
    value(1; One) { }
    value(5; Five) { }
}
