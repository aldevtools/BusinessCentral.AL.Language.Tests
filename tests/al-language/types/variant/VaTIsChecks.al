// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT VaT Helper (71026), table LT VaT Rec (71027)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71031 "LT VaT Is Scalars"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Is_Integer_Decimal_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        I: Integer;
        D: Decimal;
        B: BigInteger;
        V: Variant;
    begin
        V := I; Observer.Observe('integer0', Helper.Flags(V));
        I := -5; V := I; Observer.Observe('integer_neg', Helper.Flags(V));
        V := 7; Observer.Observe('literal_7', Helper.Flags(V));
        Evaluate(B, '3000000000'); V := B; Observer.Observe('literal_3e9', Helper.Flags(V));
        V := D; Observer.Observe('decimal0', Helper.Flags(V));
        V := 1.5; Observer.Observe('literal_1_5', Helper.Flags(V));
        V := 2.0; Observer.Observe('literal_2_0', Helper.Flags(V));
        V := B; Observer.Observe('bigint0', Helper.Flags(V));
        B := 5; V := B; Observer.Observe('bigint5', Helper.Flags(V));
        Observer.Expect('integer0', 'Integer,');
        Observer.Expect('integer_neg', 'Integer,');
        Observer.Expect('literal_7', 'Integer,');
        Observer.Expect('literal_3e9', 'BigInteger,');
        Observer.Expect('decimal0', 'Decimal,');
        Observer.Expect('literal_1_5', 'Decimal,');
        Observer.Expect('literal_2_0', 'Decimal,');
        Observer.Expect('bigint0', 'BigInteger,');
        Observer.Expect('bigint5', 'BigInteger,');
        Observer.Verify();
    end;

    [Test]
    procedure Is_Text_Code_Char_Byte()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        T: Text;
        T10: Text[10];
        C: Code[10];
        Ch: Char;
        By: Byte;
        V: Variant;
    begin
        V := T; Observer.Observe('text_empty', Helper.Flags(V));
        T := 'abc'; V := T; Observer.Observe('text_abc', Helper.Flags(V));
        V := T10; Observer.Observe('text10', Helper.Flags(V));
        V := C; Observer.Observe('code_empty', Helper.Flags(V));
        C := 'abc'; V := C; Observer.Observe('code_abc', Helper.Flags(V));
        V := 'literal'; Observer.Observe('literal_text', Helper.Flags(V));
        V := ''; Observer.Observe('literal_empty', Helper.Flags(V));
        V := 'a'; Observer.Observe('literal_single_char_text', Helper.Flags(V));
        V := Ch; Observer.Observe('char0', Helper.Flags(V));
        Ch := 65; V := Ch; Observer.Observe('char65', Helper.Flags(V));
        V := By; Observer.Observe('byte0', Helper.Flags(V));
        By := 200; V := By; Observer.Observe('byte200', Helper.Flags(V));
        Observer.Expect('text_empty', 'Text,');
        Observer.Expect('text_abc', 'Text,');
        Observer.Expect('text10', 'Text,');
        Observer.Expect('code_empty', 'Code,');
        Observer.Expect('code_abc', 'Code,');
        Observer.Expect('literal_text', 'Text,');
        Observer.Expect('literal_empty', 'Text,');
        Observer.Expect('literal_single_char_text', 'Char,');
        Observer.Expect('char0', 'Char,');
        Observer.Expect('char65', 'Char,');
        Observer.Expect('byte0', 'Byte,');
        Observer.Expect('byte200', 'Byte,');
        Observer.Verify();
    end;

    [Test]
    procedure Is_Boolean_Guid_Option()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        Bo: Boolean;
        G: Guid;
        O: Option A,B,C;
        V: Variant;
    begin
        V := Bo; Observer.Observe('boolean_false', Helper.Flags(V));
        V := true; Observer.Observe('boolean_true', Helper.Flags(V));
        V := G; Observer.Observe('guid_null', Helper.Flags(V));
        G := CreateGuid(); V := G; Observer.Observe('guid_new', Helper.Flags(V));
        V := O; Observer.Observe('option_default', Helper.Flags(V));
        O := O::C; V := O; Observer.Observe('option_c', Helper.Flags(V));
        Observer.Expect('boolean_false', 'Boolean,');
        Observer.Expect('boolean_true', 'Boolean,');
        Observer.Expect('guid_null', 'Guid,');
        Observer.Expect('guid_new', 'Guid,');
        Observer.Expect('option_default', 'Option,');
        Observer.Expect('option_c', 'Option,');
        Observer.Verify();
    end;

    [Test]
    procedure Is_Date_Time_DateTime_Duration()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        Dt: Date;
        Tm: Time;
        DtTm: DateTime;
        Du: Duration;
        V: Variant;
    begin
        V := Dt; Observer.Observe('date_0', Helper.Flags(V));
        V := DMY2Date(1, 2, 2020); Observer.Observe('date_value', Helper.Flags(V));
        V := 0D; Observer.Observe('date_literal_0D', Helper.Flags(V));
        V := Tm; Observer.Observe('time_0', Helper.Flags(V));
        V := 120000T; Observer.Observe('time_literal', Helper.Flags(V));
        V := DtTm; Observer.Observe('datetime_0', Helper.Flags(V));
        V := CreateDateTime(DMY2Date(1, 2, 2020), 120000T); Observer.Observe('datetime_value', Helper.Flags(V));
        V := Du; Observer.Observe('duration_0', Helper.Flags(V));
        Du := 1000; V := Du; Observer.Observe('duration_1000', Helper.Flags(V));
        Observer.Expect('date_0', 'Date,');
        Observer.Expect('date_value', 'Date,');
        Observer.Expect('date_literal_0D', 'Date,');
        Observer.Expect('time_0', 'Time,');
        Observer.Expect('time_literal', 'Time,');
        Observer.Expect('datetime_0', 'DateTime,');
        Observer.Expect('datetime_value', 'DateTime,');
        Observer.Expect('duration_0', 'Duration,');
        Observer.Expect('duration_1000', 'Duration,');
        Observer.Verify();
    end;

    [Test]
    procedure Is_Enum_And_Option_Variant()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        E: Enum "LT VaT Enum";
        V: Variant;
    begin
        V := E; Observer.Observe('enum_default', Helper.Flags(V));
        V := E::Five; Observer.Observe('enum_five', Helper.Flags(V));
        Observer.Observe('enum_format', Format(V));
        Observer.Expect('enum_default', 'Option,');
        Observer.Expect('enum_five', 'Option,');
        Observer.Expect('enum_format', 'Five');
        Observer.Verify();
    end;
}

codeunit 71032 "LT VaT Is Objects"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Is_Record_RecordRef_FieldRef()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        Rec: Record "LT VaT Rec";
        RecRef: RecordRef;
        FldRef: FieldRef;
        V: Variant;
    begin
        Rec.DeleteAll();
        V := Rec; Observer.Observe('record', Helper.Flags(V));
        RecRef.GetTable(Rec); V := RecRef; Observer.Observe('recordref', Helper.Flags(V));
        FldRef := RecRef.Field(1); V := FldRef; Observer.Observe('fieldref', Helper.Flags(V));
        asserterror RecRef.Open(Database::"LT VaT Rec"); V := RecRef; Observer.Observe('recordref_open', Helper.Flags(V));
        Observer.ObserveError('af137');
        Observer.Expect('record', 'Record,');
        Observer.Expect('recordref', 'RecordRef,');
        Observer.Expect('fieldref', 'FieldRef,');
        Observer.Expect('recordref_open', 'RecordRef,');
        Observer.Expect('af137|text', 'The record is already open.');
        Observer.Expect('af137|code', 'RecordAlreadyOpened');
        Observer.Verify();
    end;

    [Test]
    procedure Is_Codeunit_List_Dictionary()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        Cu: Codeunit "LT VaT Helper";
        L: List of [Integer];
        Di: Dictionary of [Text, Integer];
        V: Variant;
    begin
        V := Cu; Observer.Observe('codeunit', Helper.Flags(V));
        V := L; Observer.Observe('list', Helper.Flags(V));
        V := Di; Observer.Observe('dictionary', Helper.Flags(V));
        Observer.Expect('codeunit', 'Codeunit,');
        Observer.Expect('list', 'List,');
        Observer.Expect('dictionary', 'Dictionary,');
        Observer.Verify();
    end;

    [Test]
    procedure Is_Streams_Notification()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        N: Notification;
        V: Variant;
    begin
        TempBlob.CreateOutStream(OutS);
        TempBlob.CreateInStream(InS);
        V := InS; Observer.Observe('instream', Helper.Flags(V));
        V := OutS; Observer.Observe('outstream', Helper.Flags(V));
        V := N; Observer.Observe('notification', Helper.Flags(V));
        Observer.Expect('instream', 'InStream,');
        Observer.Expect('outstream', 'OutStream,');
        Observer.Expect('notification', 'Notification,');
        Observer.Verify();
    end;

    [Test]
    procedure Is_Empty_Variant()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT VaT Helper";
        V: Variant;
    begin
        Observer.Observe('empty_flags', Helper.Flags(V));
        Observer.Observe('empty_format', Format(V));
        Observer.Observe('empty_format_len', Format(StrLen(Format(V))));
        Clear(V); Observer.Observe('cleared_empty_flags', Helper.Flags(V));
        V := 5; Clear(V); Observer.Observe('cleared_after_int', Helper.Flags(V));
        Observer.Observe('cleared_after_int_format', Format(V));
        V := 5; V := 'x'; Observer.Observe('reassigned', Helper.Flags(V));
        Observer.Expect('empty_flags', '');
        Observer.Expect('empty_format', '');
        Observer.Expect('empty_format_len', '0');
        Observer.Expect('cleared_empty_flags', '');
        Observer.Expect('cleared_after_int', '');
        Observer.Expect('cleared_after_int_format', '');
        Observer.Expect('reassigned', 'Char,');
        Observer.Verify();
    end;
}
