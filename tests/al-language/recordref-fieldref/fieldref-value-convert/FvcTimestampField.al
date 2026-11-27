// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-field-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73498, helper codeunit 73498, test codeunit 73499
// Probe (AL Runner issue 9285): the value of RecordRef.Field(0), the record's timestamp field, converted into a Code and a Text
//   (exit from a Code[20] or Text procedure, and a direct assignment), into a BigInteger and through a Variant, and Format of it; the
//   FieldRef's Number, Name, Type and Class; the value of a row that is not inserted, of a temporary row, and before and after a
//   Modify.
//   The timestamp is the SQL rowversion of the row and changes from run to run, so no number is asserted: the cells record
//   relations (whether a text is a whole number, whether two readings are equal, whether the value grows after a Modify) and the
//   texts that do not depend on the row (errors, the Variant's kind, the FieldRef metadata).
//   Each cell runs in a TryFunction and records "ok: <reading>" or "E: <GetLastErrorText> | <GetLastErrorCode>".
//   Measured on BC 29.0 (Linux, W1, en-US session) with an invented app holding these objects, through the dev endpoint's
//   TestRunnerHub; the values are that run's readings, turned into Expect and Verify by convert.py verbatim, and asserted on
//   BC 28 and later (#if BC28PLUS). On BC 27.5 (#else) every test is an observe round: it ends with Finish() and asserts nothing.
//   Facts (BC 29.0): field 0 of an inserted row is a whole number in every reading: exit from a Code[20] and a Text procedure,
//   assignment to a Code[20], a Text and a BigInteger, Format and Format(.., 0, 9), and all of them give the same text. Through
//   a Variant (V := FR.Value) the Variant holds a BigInteger, and assigning that Variant to a Code[20] fails with 'The expression
//   Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value.'
//   (TypeConversion). The FieldRef: Number 0, Name timestamp, Type BigInteger, Class Normal. A row that is not inserted and a
//   temporary row read 0. Rows differ from each other, and a Modify gives the row a greater value.
// BC versions: 27, 28, 29 by CI
table 73498 "LT FTS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 73498 "LT FTS Probe"
{
    procedure CodeOfField(var RecRef: RecordRef; FieldNo: Integer): Code[20]
    var
        FRef: FieldRef;
    begin
        FRef := RecRef.Field(FieldNo);
        exit(FRef.Value);
    end;

    procedure TextOfField(var RecRef: RecordRef; FieldNo: Integer): Text
    var
        FRef: FieldRef;
    begin
        FRef := RecRef.Field(FieldNo);
        exit(FRef.Value);
    end;

    // 'number' when T is a whole number of digits (at least one), 'zero' for '0', else 'text <T>'.
    procedure Kind(T: Text): Text
    var
        B: BigInteger;
    begin
        if T = '0' then
            exit('zero');
        if (T <> '') and (DelChr(T, '=', '0123456789') = '') and Evaluate(B, T) then
            exit('number');
        exit('text ' + T);
    end;

    local procedure Outcome(Ok: Boolean; Result: Text): Text
    var
        T: Text;
    begin
        if Ok then
            exit('ok: ' + Result);
        T := 'E: ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(T);
    end;

    [TryFunction]
    local procedure TryCell(var RecRef: RecordRef; Cell: Text; var Result: Text)
    var
        FR: FieldRef;
        C: Code[20];
        T: Text;
        B: BigInteger;
        V: Variant;
    begin
        FR := RecRef.Field(0);
        case Cell of
            'code_exit':
                Result := Kind(CodeOfField(RecRef, 0));
            'text_exit':
                Result := Kind(TextOfField(RecRef, 0));
            'code_assign':
                begin
                    C := FR.Value();
                    Result := Kind(C);
                end;
            'text_assign':
                begin
                    T := FR.Value();
                    Result := Kind(T);
                end;
            'biginteger_assign':
                begin
                    B := FR.Value();
                    Result := Kind(Format(B, 0, 9));
                end;
            'format':
                Result := Kind(Format(FR.Value()));
            'format_9':
                Result := Kind(Format(FR.Value(), 0, 9));
            'variant_kind':
                begin
                    V := FR.Value();
                    Result := StrSubstNo('IsBigInteger %1 IsInteger %2 IsCode %3 IsText %4', V.IsBigInteger(), V.IsInteger(), V.IsCode(), V.IsText());
                end;
            'variant_to_code':
                begin
                    V := FR.Value();
                    C := V;
                    Result := Kind(C);
                end;
            'code_equals_text':
                Result := Format(CodeOfField(RecRef, 0) = TextOfField(RecRef, 0));
            'code_equals_format_biginteger':
                begin
                    B := FR.Value();
                    Result := Format(CodeOfField(RecRef, 0) = Format(B, 0, 9));
                end;
            'code_equals_format':
                Result := Format(CodeOfField(RecRef, 0) = Format(FR.Value()));
            'number':
                Result := Format(FR.Number());
            'name':
                Result := FR.Name();
            'type':
                Result := Format(FR.Type());
            'class':
                Result := Format(FR.Class());
            'code_field1':
                Result := CodeOfField(RecRef, 1);
        end;
    end;

    procedure Cell(var Observer: Codeunit "Probe Observer"; var RecRef: RecordRef; Name: Text)
    begin
        CellAs(Observer, RecRef, Name, Name);
    end;

    // The cell Name, observed under the name Label.
    procedure CellAs(var Observer: Codeunit "Probe Observer"; var RecRef: RecordRef; Name: Text; Label: Text)
    var
        Result: Text;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryCell(RecRef, Name, Result);
        Observer.Observe(Label, Outcome(Ok, Result));
    end;

    [TryFunction]
    local procedure TryBig(var RecRef: RecordRef; var B: BigInteger)
    var
        FR: FieldRef;
    begin
        FR := RecRef.Field(0);
        B := FR.Value();
    end;

    // The timestamp of the row as a BigInteger, or -1 when reading it raises.
    procedure Stamp(var RecRef: RecordRef): BigInteger
    var
        B: BigInteger;
    begin
        if TryBig(RecRef, B) then
            exit(B);
        ClearLastError();
        exit(-1);
    end;

    // Rows PZ-A and PZ-B in the row table.
    procedure Seed()
    var
        Row: Record "LT FTS Row";
    begin
        Row.DeleteAll();
        Row."No." := 'PZ-A';
        Row.Insert();
        Row."No." := 'PZ-B';
        Row.Insert();
    end;
}

codeunit 73499 "LT FTS Timestamp Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Field 0 of an inserted row (PZ-A), read through a RecordRef after FindFirst.
    [Test]
    procedure Field0_InsertedRow()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTS Probe";
        RecRef: RecordRef;
    begin
        Probe.Seed();
        RecRef.Open(Database::"LT FTS Row");
        RecRef.FindFirst();
        Probe.Cell(Observer, RecRef, 'code_exit');
        Probe.Cell(Observer, RecRef, 'text_exit');
        Probe.Cell(Observer, RecRef, 'code_assign');
        Probe.Cell(Observer, RecRef, 'text_assign');
        Probe.Cell(Observer, RecRef, 'biginteger_assign');
        Probe.Cell(Observer, RecRef, 'format');
        Probe.Cell(Observer, RecRef, 'format_9');
        Probe.Cell(Observer, RecRef, 'variant_kind');
        Probe.Cell(Observer, RecRef, 'variant_to_code');
        Probe.Cell(Observer, RecRef, 'code_equals_text');
        Probe.Cell(Observer, RecRef, 'code_equals_format_biginteger');
        Probe.Cell(Observer, RecRef, 'code_equals_format');
        Probe.Cell(Observer, RecRef, 'number');
        Probe.Cell(Observer, RecRef, 'name');
        Probe.Cell(Observer, RecRef, 'type');
        Probe.Cell(Observer, RecRef, 'class');
        Probe.Cell(Observer, RecRef, 'code_field1');
#if BC28PLUS
        Observer.Expect('code_exit', 'ok: number');
        Observer.Expect('text_exit', 'ok: number');
        Observer.Expect('code_assign', 'ok: number');
        Observer.Expect('text_assign', 'ok: number');
        Observer.Expect('biginteger_assign', 'ok: number');
        Observer.Expect('format', 'ok: number');
        Observer.Expect('format_9', 'ok: number');
        Observer.Expect('variant_kind', 'ok: IsBigInteger Yes IsInteger No IsCode No IsText No');
        Observer.Expect('variant_to_code', 'E: The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavCode value. | TypeConversion');
        Observer.Expect('code_equals_text', 'ok: Yes');
        Observer.Expect('code_equals_format_biginteger', 'ok: Yes');
        Observer.Expect('code_equals_format', 'ok: Yes');
        Observer.Expect('number', 'ok: 0');
        Observer.Expect('name', 'ok: timestamp');
        Observer.Expect('type', 'ok: BigInteger');
        Observer.Expect('class', 'ok: Normal');
        Observer.Expect('code_field1', 'ok: PZ-A');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    // Field 0 of a row that is not inserted (RecordRef.Init), and of a row inserted into a temporary RecordRef.
    [Test]
    procedure Field0_NotInsertedAndTemporary()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTS Probe";
        RecRef: RecordRef;
        TempRef: RecordRef;
        FR: FieldRef;
    begin
        Probe.Seed();
        RecRef.Open(Database::"LT FTS Row");
        RecRef.Init();
        Probe.CellAs(Observer, RecRef, 'code_exit', 'not_inserted_code_exit');
        Probe.CellAs(Observer, RecRef, 'text_assign', 'not_inserted_text_assign');
        TempRef.Open(Database::"LT FTS Row", true);
        FR := TempRef.Field(1);
        FR.Value := 'PZ-T';
        TempRef.Insert();
        TempRef.FindFirst();
        Probe.CellAs(Observer, TempRef, 'code_exit', 'temporary_code_exit');
        Probe.CellAs(Observer, TempRef, 'text_assign', 'temporary_text_assign');
        Probe.CellAs(Observer, TempRef, 'biginteger_assign', 'temporary_biginteger_assign');
#if BC28PLUS
        Observer.Expect('not_inserted_code_exit', 'ok: zero');
        Observer.Expect('not_inserted_text_assign', 'ok: zero');
        Observer.Expect('temporary_code_exit', 'ok: zero');
        Observer.Expect('temporary_text_assign', 'ok: zero');
        Observer.Expect('temporary_biginteger_assign', 'ok: zero');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;

    // The timestamp before and after a Modify of the row, and of another row.
    [Test]
    procedure Field0_AroundModify()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT FTS Probe";
        Row: Record "LT FTS Row";
        RecRef: RecordRef;
        Before: BigInteger;
        After: BigInteger;
        Other: BigInteger;
    begin
        Probe.Seed();
        RecRef.Open(Database::"LT FTS Row");
        RecRef.FindFirst();
        Before := Probe.Stamp(RecRef);
        RecRef.FindLast();
        Other := Probe.Stamp(RecRef);
        Row.Get('PZ-A');
        Row.Name := 'Changed';
        Row.Modify();
        RecRef.FindFirst();
        After := Probe.Stamp(RecRef);
        Observer.Observe('before_positive', Format(Before > 0));
        Observer.Observe('other_differs', Format(Other <> Before));
        Observer.Observe('after_differs', Format(After <> Before));
        Observer.Observe('after_greater', Format(After > Before));
        Observer.Observe('after_greater_than_other', Format(After > Other));
#if BC28PLUS
        Observer.Expect('before_positive', 'Yes');
        Observer.Expect('other_differs', 'Yes');
        Observer.Expect('after_differs', 'Yes');
        Observer.Expect('after_greater', 'Yes');
        Observer.Expect('after_greater_than_other', 'Yes');
        Observer.Verify();
#else // BC 27.5: observe round, red on purpose; not measured on 27.5 yet
        Observer.Finish();
#endif
    end;
}
