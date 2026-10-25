// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 89271 and codeunit 89270
// Probe: writer SN (2026-10-25), runtime hand-off refuse-errors "Flag texts kept refused". Values asserted are what the corpus CI legs produced.
// Facts: GetLastErrorText(true) (ExcludeCustomerContent) against GetLastErrorText(false) and GetLastErrorCode for Error of a global Text
//   variable, of a record field, of a procedure's return value and of a local Label; FieldError with an ErrorInfo; FieldError of a blank
//   DateTime; duplicate Insert into a temporary record; Find('<') and Find('>') on an empty table; FindFirst with a filter on an empty
//   table; Evaluate into Decimal, Date, Boolean, Guid, Time, DateTime and Duration of a text that does not convert.
//   Text-variable, Label, literal and other forms are pinned in the other files of this folder and in ../lt-last-error-text-exclude/.
// BC versions: 29 (27 and 28 by CI)

table 89271 "LT SN LET Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Moment; DateTime) { }
        field(4; Qty; Integer) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 89270 "LT SN LET More Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GlobalMsg: Text;

    local procedure Forms(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '_true', GetLastErrorText(true));
        Observer.Observe(Name + '_false', GetLastErrorText(false));
        Observer.Observe(Name + '_code', GetLastErrorCode());
        ClearLastError();
    end;

    local procedure MakeMsg(): Text
    begin
        exit('Message from a call');
    end;

    [TryFunction]
    local procedure TryGlobalText()
    begin
        GlobalMsg := 'Global text message';
        Error(GlobalMsg);
    end;

    [TryFunction]
    local procedure TryRecordField()
    var
        Row: Record "LT SN LET Row";
    begin
        Row.Name := 'Field message';
        Error(Row.Name);
    end;

    [TryFunction]
    local procedure TryCallResult()
    begin
        Error(MakeMsg());
    end;

    [TryFunction]
    local procedure TryLocalLabel()
    var
        Lbl: Label 'Local label message';
    begin
        Error(Lbl);
    end;

    [TryFunction]
    local procedure TryLocalLabelArg(Value: Text)
    var
        Lbl: Label 'Local label %1';
    begin
        Error(Lbl, Value);
    end;

    [Test]
    procedure ErrorOfGlobalFieldCallAndLocalLabel_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        if not TryGlobalText() then
            Forms('global', Observer);
        if not TryRecordField() then
            Forms('field', Observer);
        if not TryCallResult() then
            Forms('call', Observer);
        if not TryLocalLabel() then
            Forms('locallabel', Observer);
        if not TryLocalLabelArg('secret') then
            Forms('locallabel_arg', Observer);
        Observer.Expect('global_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('global_false', 'Global text message');
        Observer.Expect('global_code', 'Dialog');
        Observer.Expect('field_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('field_false', 'Field message');
        Observer.Expect('field_code', 'Dialog');
        Observer.Expect('call_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('call_false', 'Message from a call');
        Observer.Expect('call_code', 'Dialog');
        Observer.Expect('locallabel_true', 'Local label message');
        Observer.Expect('locallabel_false', 'Local label message');
        Observer.Expect('locallabel_code', 'Dialog');
        Observer.Expect('locallabel_arg_true', 'Local label %1');
        Observer.Expect('locallabel_arg_false', 'Local label secret');
        Observer.Expect('locallabel_arg_code', 'Dialog');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryFieldErrorInfo(WithMessage: Boolean)
    var
        Row: Record "LT SN LET Row";
        Info: ErrorInfo;
    begin
        Row.Code := 'R1';
        Row.Name := 'filled';
        if WithMessage then
            Info := ErrorInfo.Create('ErrorInfo message')
        else
            Info := ErrorInfo.Create();
        Row.FieldError(Name, Info);
    end;

    [TryFunction]
    local procedure TryFieldErrorBlankDateTime(WithText: Boolean)
    var
        Row: Record "LT SN LET Row";
    begin
        Row.Code := 'R1';
        if WithText then
            Row.FieldError(Moment, 'must be set')
        else
            Row.FieldError(Moment);
    end;

    [Test]
    procedure FieldErrorInfoAndBlankDateTime_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        if not TryFieldErrorInfo(true) then
            Forms('info_message', Observer);
        if not TryFieldErrorInfo(false) then
            Forms('info_empty', Observer);
        if not TryFieldErrorBlankDateTime(false) then
            Forms('blank_datetime', Observer);
        if not TryFieldErrorBlankDateTime(true) then
            Forms('blank_datetime_text', Observer);
        Observer.Expect('info_message_true', 'FieldError on field LT SN LET Row.Name');
        Observer.Expect('info_message_false', 'Name ErrorInfo message in LT SN LET Row Code=''R1''.');
        Observer.Expect('info_message_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('info_empty_true', 'FieldError for incorrect value of LT SN LET Row.Name');
        Observer.Expect('info_empty_false', 'Name must not be filled in LT SN LET Row Code=''R1''.');
        Observer.Expect('info_empty_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('blank_datetime_true', 'FieldError for unspecified value of LT SN LET Row.Moment');
        Observer.Expect('blank_datetime_false', 'You must specify Moment in LT SN LET Row Code=''R1''.');
        Observer.Expect('blank_datetime_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('blank_datetime_text_true', 'FieldError on field LT SN LET Row.Moment, message: Use FIELDERROR with a text constant to improve Telemetry details.');
        Observer.Expect('blank_datetime_text_false', 'Moment must be set in LT SN LET Row Code=''R1''.');
        Observer.Expect('blank_datetime_text_code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryInsertTemp(var Row: Record "LT SN LET Row" temporary)
    begin
        Row.Init();
        Row.Code := 'DUP';
        Row.Insert();
    end;

    [Test]
    procedure InsertDuplicateTemporary_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "LT SN LET Row" temporary;
    begin
        TempRow.Init();
        TempRow.Code := 'DUP';
        TempRow.Insert();
        ClearLastError();
        if not TryInsertTemp(TempRow) then
            Forms('temp_dup', Observer);
        Observer.Expect('temp_dup_true', 'The record in table LT SN LET Row already exists. Identification fields and values: <redacted>');
        Observer.Expect('temp_dup_false', 'The record in table LT SN LET Row already exists. Identification fields and values: Code=''DUP''');
        Observer.Expect('temp_dup_code', 'DB:RecordExists');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryFind(var Row: Record "LT SN LET Row"; Which: Text)
    begin
        Row.Find(Which);
    end;

    [TryFunction]
    local procedure TryFindFirst(var Row: Record "LT SN LET Row")
    begin
        Row.FindFirst();
    end;

    [Test]
    procedure FindNextPreviousAndFilterOnEmptyTable_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT SN LET Row";
    begin
        Row.DeleteAll();
        ClearLastError();
        if not TryFind(Row, '<') then
            Forms('find_lt', Observer);
        if not TryFind(Row, '>') then
            Forms('find_gt', Observer);
        Row.SetRange(Code, 'X');
        if not TryFindFirst(Row) then
            Forms('filter_empty', Observer);
        Row.Reset();
        Row.Code := 'K';
        if not TryFind(Row, '=<>') then
            Forms('find_eqltgt', Observer);
        Observer.Expect('find_lt_true', 'The LT SN LET Row does not exist. <\\Identification fields and values:\\<redacted>');
        Observer.Expect('find_lt_false', 'The LT SN LET Row does not exist. <\\Identification fields and values:\\Code=''''');
        Observer.Expect('find_lt_code', 'DB:RecordNotFound');
        Observer.Expect('find_gt_true', 'The LT SN LET Row does not exist. >\\Identification fields and values:\\<redacted>');
        Observer.Expect('find_gt_false', 'The LT SN LET Row does not exist. >\\Identification fields and values:\\Code=''''');
        Observer.Expect('find_gt_code', 'DB:RecordNotFound');
        Observer.Expect('filter_empty_true', 'There is no LT SN LET Row within the filter.\\Filters: <redacted>');
        Observer.Expect('filter_empty_false', 'There is no LT SN LET Row within the filter.\\Filters: Code: X');
        Observer.Expect('filter_empty_code', 'DB:NothingInsideFilter');
        Observer.Expect('find_eqltgt_true', 'The LT SN LET Row does not exist. =<>\\Identification fields and values:\\<redacted>');
        Observer.Expect('find_eqltgt_false', 'The LT SN LET Row does not exist. =<>\\Identification fields and values:\\Code=''K''');
        Observer.Expect('find_eqltgt_code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvaluate(Kind: Integer; Source: Text)
    var
        D: Decimal;
        Dt: Date;
        B: Boolean;
        G: Guid;
        T: Time;
        DT2: DateTime;
        Dur: Duration;
        BI: BigInteger;
    begin
        case Kind of
            1:
                Evaluate(D, Source);
            2:
                Evaluate(Dt, Source);
            3:
                Evaluate(B, Source);
            4:
                Evaluate(G, Source);
            5:
                Evaluate(T, Source);
            6:
                Evaluate(DT2, Source);
            7:
                Evaluate(Dur, Source);
            8:
                Evaluate(BI, Source);
        end;
    end;

    [Test]
    procedure EvaluateNonIntegerTypes_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        if not TryEvaluate(1, 'abc') then
            Forms('decimal', Observer);
        if not TryEvaluate(2, 'abc') then
            Forms('date', Observer);
        if not TryEvaluate(3, 'abc') then
            Forms('boolean', Observer);
        if not TryEvaluate(4, 'abc') then
            Forms('guid', Observer);
        if not TryEvaluate(5, 'abc') then
            Forms('time', Observer);
        Observer.Expect('decimal_true', 'The value "<redacted>" can''t be evaluated into type Decimal.');
        Observer.Expect('decimal_false', 'The value "abc" can''t be evaluated into type Decimal.');
        Observer.Expect('decimal_code', 'Evaluate');
        Observer.Expect('date_true', 'The format of the Date ''<redacted>'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('date_false', 'The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('date_code', 'Evaluate');
        Observer.Expect('boolean_true', 'The value "<redacted>" can''t be evaluated into type Boolean.');
        Observer.Expect('boolean_false', 'The value "abc" can''t be evaluated into type Boolean.');
        Observer.Expect('boolean_code', 'Evaluate');
        Observer.Expect('guid_true', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('guid_false', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('guid_code', 'InvalidGuidFormat');
        Observer.Expect('time_true', 'The value "<redacted>" can''t be evaluated into type Time.');
        Observer.Expect('time_false', 'The value "abc" can''t be evaluated into type Time.');
        Observer.Expect('time_code', 'Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure EvaluateNonIntegerTypes2_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        if not TryEvaluate(6, 'abc') then
            Forms('datetime', Observer);
        if not TryEvaluate(7, 'abc') then
            Forms('duration', Observer);
        if not TryEvaluate(8, 'abc') then
            Forms('biginteger', Observer);
        if not TryEvaluate(8, '99999999999999999999') then
            Forms('biginteger_overflow', Observer);
        if not TryEvaluate(1, '1e400') then
            Forms('decimal_overflow', Observer);
        Observer.Expect('datetime_true', 'The value "<redacted>" can''t be evaluated into type DateTime.');
        Observer.Expect('datetime_false', 'The value "abc" can''t be evaluated into type DateTime.');
        Observer.Expect('datetime_code', 'Evaluate');
        Observer.Expect('duration_true', 'The value "<redacted>" can''t be evaluated into type Duration.');
        Observer.Expect('duration_false', 'The value "abc" can''t be evaluated into type Duration.');
        Observer.Expect('duration_code', 'Evaluate');
        Observer.Expect('biginteger_true', 'The value "<redacted>" can''t be evaluated into type BigInteger.');
        Observer.Expect('biginteger_false', 'The value "abc" can''t be evaluated into type BigInteger.');
        Observer.Expect('biginteger_code', 'Evaluate');
        Observer.Expect('biginteger_overflow_true', 'The value "<redacted>" can''t be evaluated into type BigInteger.');
        Observer.Expect('biginteger_overflow_false', 'The value "99999999999999999999" can''t be evaluated into type BigInteger.');
        Observer.Expect('biginteger_overflow_code', 'Evaluate');
        Observer.Expect('decimal_overflow_true', 'The value "<redacted>" can''t be evaluated into type Decimal.');
        Observer.Expect('decimal_overflow_false', 'The value "1e400" can''t be evaluated into type Decimal.');
        Observer.Expect('decimal_overflow_code', 'Evaluate');
        Observer.Verify();
    end;
}
