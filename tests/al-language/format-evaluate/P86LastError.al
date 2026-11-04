// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects
// Probe: written against BC 29 (P86); the final facts are measured on a local BC 29 tier and added later.
// Facts: GetLastErrorText(true) / GetLastErrorText(false), GetLastErrorCode and the start of GetLastErrorCallStack after Error with ErrorInfo, TestField, FieldError and a record-not-found runtime error
// BC versions: 29

table 73530 "LT P86 Err Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Name; Text[30]) { DataClassification = CustomerContent; }
        field(3; Amount; Decimal) { DataClassification = CustomerContent; }
        field(4; Info; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 73531 "LT P86 Last Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RaiseInfo(Msg: Text; DC: DataClassification)
    var
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := Msg;
        ErrInfo.DataClassification := DC;
        Error(ErrInfo);
    end;

    [Test]
    procedure ErrorInfo_CustomerContent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror RaiseInfo('secret customer text', DataClassification::CustomerContent);
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.Observe('code', GetLastErrorCode());
        Observer.Observe('hasError', Format(GetLastErrorText() <> ''));
        Observer.ObserveError('after');
        Observer.Observe('cleared_full', GetLastErrorText(false));
        Observer.Observe('cleared_excl', GetLastErrorText(true));
        Observer.Expect('full', 'secret customer text');
        Observer.Expect('excl', 'This message had personal data removed. The original may still be in transient telemetry. Find it using the transientTelemetryId.');
        Observer.Expect('code', 'Dialog');
        Observer.Expect('hasError', 'Yes');
        Observer.Expect('after|text', 'secret customer text');
        Observer.Expect('after|code', 'Dialog');
        Observer.Expect('cleared_full', '');
        Observer.Expect('cleared_excl', '');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_OtherClassifications()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror RaiseInfo('system text', DataClassification::SystemMetadata);
        Observer.Observe('sys_excl', GetLastErrorText(true));
        Observer.Observe('sys_full', GetLastErrorText(false));
        Observer.ObserveError('sys');
        asserterror RaiseInfo('org text', DataClassification::OrganizationIdentifiableInformation);
        Observer.Observe('oii_excl', GetLastErrorText(true));
        Observer.ObserveError('oii');
        asserterror RaiseInfo('eui text', DataClassification::EndUserIdentifiableInformation);
        Observer.Observe('eui_excl', GetLastErrorText(true));
        Observer.ObserveError('eui');
        asserterror RaiseInfo('pseudo text', DataClassification::EndUserPseudonymousIdentifiers);
        Observer.Observe('eup_excl', GetLastErrorText(true));
        Observer.ObserveError('eup');
        asserterror RaiseInfo('acc text', DataClassification::AccountData);
        Observer.Observe('acc_excl', GetLastErrorText(true));
        Observer.ObserveError('acc');
        asserterror RaiseInfo('tobe text', DataClassification::ToBeClassified);
        Observer.Observe('tbc_excl', GetLastErrorText(true));
        Observer.ObserveError('tbc');
        Observer.Expect('sys_excl', 'This message had personal data removed. The original may still be in transient telemetry. Find it using the transientTelemetryId.');
        Observer.Expect('sys_full', 'system text');
        Observer.Expect('sys|text', 'system text');
        Observer.Expect('sys|code', 'Dialog');
        Observer.Expect('oii_excl', 'This message had personal data removed. The original may still be in transient telemetry. Find it using the transientTelemetryId.');
        Observer.Expect('oii|text', 'org text');
        Observer.Expect('oii|code', 'Dialog');
        Observer.Expect('eui_excl', 'This message had personal data removed. The original may still be in transient telemetry. Find it using the transientTelemetryId.');
        Observer.Expect('eui|text', 'eui text');
        Observer.Expect('eui|code', 'Dialog');
        Observer.Expect('eup_excl', 'This message had personal data removed. The original may still be in transient telemetry. Find it using the transientTelemetryId.');
        Observer.Expect('eup|text', 'pseudo text');
        Observer.Expect('eup|code', 'Dialog');
        Observer.Expect('acc_excl', 'This message had personal data removed. The original may still be in transient telemetry. Find it using the transientTelemetryId.');
        Observer.Expect('acc|text', 'acc text');
        Observer.Expect('acc|code', 'Dialog');
        Observer.Expect('tbc_excl', 'This message had personal data removed. The original may still be in transient telemetry. Find it using the transientTelemetryId.');
        Observer.Expect('tbc|text', 'tobe text');
        Observer.Expect('tbc|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_DefaultClassification()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := 'no classification set';
        asserterror Error(ErrInfo);
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.ObserveError('default');
        Observer.Observe('dc', Format(ErrInfo.DataClassification));
        Observer.Expect('excl', 'This message had personal data removed. The original may still be in transient telemetry. Find it using the transientTelemetryId.');
        Observer.Expect('default|text', 'no classification set');
        Observer.Expect('default|code', 'Dialog');
        Observer.Expect('dc', 'CustomerContent');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_CustomDimensions()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
        Dims: Dictionary of [Text, Text];
    begin
        Dims.Add('key1', 'value1');
        Dims.Add('key2', 'value2');
        ErrInfo.Message := 'with dimensions';
        ErrInfo.CustomDimensions := Dims;
        asserterror Error(ErrInfo);
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.ObserveError('dims');
        Observer.Observe('count', Format(ErrInfo.CustomDimensions.Count()));
        Observer.Expect('full', 'with dimensions');
        Observer.Expect('excl', 'This message had personal data removed. The original may still be in transient telemetry. Find it using the transientTelemetryId.');
        Observer.Expect('dims|text', 'with dimensions');
        Observer.Expect('dims|code', 'Dialog');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorInfo_DimensionsAndCustomerContent()
    var
        Observer: Codeunit "Probe Observer";
        ErrInfo: ErrorInfo;
        Dims: Dictionary of [Text, Text];
    begin
        Dims.Add('k', 'v');
        ErrInfo.Message := 'dims and customer content';
        ErrInfo.CustomDimensions := Dims;
        ErrInfo.DataClassification := DataClassification::CustomerContent;
        asserterror Error(ErrInfo);
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.Observe('default_arg', GetLastErrorText());
        Observer.ObserveError('both');
        Observer.Expect('full', 'dims and customer content');
        Observer.Expect('excl', 'This message had personal data removed. The original may still be in transient telemetry. Find it using the transientTelemetryId.');
        Observer.Expect('default_arg', 'dims and customer content');
        Observer.Expect('both|text', 'dims and customer content');
        Observer.Expect('both|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure PlainError_Exclude()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error('plain %1', 'argument');
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.ObserveError('plain');
        asserterror Error('');
        Observer.Observe('empty_excl', GetLastErrorText(true));
        Observer.ObserveError('empty');
        Observer.Expect('full', 'plain argument');
        Observer.Expect('excl', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('plain|text', 'plain argument');
        Observer.Expect('plain|code', 'Dialog');
        Observer.Expect('empty_excl', '');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_Exclude()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P86 Err Rec";
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec."Entry No." := 1;
        Rec.Info := 'x';
        asserterror Rec.TestField(Name);
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.ObserveError('empty_cc');
        asserterror Rec.TestField(Info, 'y');
        Observer.Observe('full2', GetLastErrorText(false));
        Observer.Observe('excl2', GetLastErrorText(true));
        Observer.ObserveError('value_sys');
        Rec.Name := 'Jane';
        asserterror Rec.TestField(Name, 'John');
        Observer.Observe('full3', GetLastErrorText(false));
        Observer.Observe('excl3', GetLastErrorText(true));
        Observer.ObserveError('value_cc');
        asserterror Rec.TestField(Amount);
        Observer.Observe('excl4', GetLastErrorText(true));
        Observer.ObserveError('amount');
        Observer.Expect('full', 'Name must have a value in LT P86 Err Rec: Entry No.=1. It cannot be zero or empty.');
        Observer.Expect('excl', 'Name must have a value in LT P86 Err Rec: <redacted>. It cannot be zero or empty.');
        Observer.Expect('empty_cc|text', 'Name must have a value in LT P86 Err Rec: Entry No.=1. It cannot be zero or empty.');
        Observer.Expect('empty_cc|code', 'TestField');
        Observer.Expect('full2', 'Info must be equal to ''y''  in LT P86 Err Rec: Entry No.=1. Current value is ''x''.');
        Observer.Expect('excl2', 'Info must be equal to ''<redacted>''  in LT P86 Err Rec: <redacted>. Current value is ''<redacted>''.');
        Observer.Expect('value_sys|text', 'Info must be equal to ''y''  in LT P86 Err Rec: Entry No.=1. Current value is ''x''.');
        Observer.Expect('value_sys|code', 'TestField');
        Observer.Expect('full3', 'Name must be equal to ''John''  in LT P86 Err Rec: Entry No.=1. Current value is ''Jane''.');
        Observer.Expect('excl3', 'Name must be equal to ''<redacted>''  in LT P86 Err Rec: <redacted>. Current value is ''<redacted>''.');
        Observer.Expect('value_cc|text', 'Name must be equal to ''John''  in LT P86 Err Rec: Entry No.=1. Current value is ''Jane''.');
        Observer.Expect('value_cc|code', 'TestField');
        Observer.Expect('excl4', 'Amount must have a value in LT P86 Err Rec: <redacted>. It cannot be zero or empty.');
        Observer.Expect('amount|text', 'Amount must have a value in LT P86 Err Rec: Entry No.=1. It cannot be zero or empty.');
        Observer.Expect('amount|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure FieldError_Exclude()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P86 Err Rec";
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec."Entry No." := 1;
        Rec.Name := 'Jane';
        Rec.Info := 'x';
        asserterror Rec.FieldError(Name);
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.ObserveError('plain_cc');
        asserterror Rec.FieldError(Name, 'custom message');
        Observer.Observe('excl2', GetLastErrorText(true));
        Observer.ObserveError('custom_cc');
        asserterror Rec.FieldError(Info);
        Observer.Observe('excl3', GetLastErrorText(true));
        Observer.ObserveError('plain_sys');
        asserterror Rec.FieldError(Info, 'custom sys');
        Observer.Observe('excl4', GetLastErrorText(true));
        Observer.ObserveError('custom_sys');
        asserterror Rec.FieldError(Amount);
        Observer.Observe('excl5', GetLastErrorText(true));
        Observer.ObserveError('amount');
        Observer.Expect('full', 'Name must not be Jane in LT P86 Err Rec Entry No.=''1''.');
        Observer.Expect('excl', 'FieldError for incorrect value of LT P86 Err Rec.Name');
        Observer.Expect('plain_cc|text', 'Name must not be Jane in LT P86 Err Rec Entry No.=''1''.');
        Observer.Expect('plain_cc|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('excl2', 'FieldError on field LT P86 Err Rec.Name, message: Use FIELDERROR with a text constant to improve Telemetry details.');
        Observer.Expect('custom_cc|text', 'Name custom message in LT P86 Err Rec Entry No.=''1''.');
        Observer.Expect('custom_cc|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('excl3', 'FieldError for incorrect value of LT P86 Err Rec.Info');
        Observer.Expect('plain_sys|text', 'Info must not be x in LT P86 Err Rec Entry No.=''1''.');
        Observer.Expect('plain_sys|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('excl4', 'FieldError on field LT P86 Err Rec.Info, message: Use FIELDERROR with a text constant to improve Telemetry details.');
        Observer.Expect('custom_sys|text', 'Info custom sys in LT P86 Err Rec Entry No.=''1''.');
        Observer.Expect('custom_sys|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('excl5', 'FieldError for incorrect value of LT P86 Err Rec.Amount');
        Observer.Expect('amount|text', 'Amount must not be 0 in LT P86 Err Rec Entry No.=''1''.');
        Observer.Expect('amount|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure RuntimeError_NotFound()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P86 Err Rec";
    begin
        Rec.DeleteAll();
        asserterror Rec.Get(99);
        Observer.Observe('full', GetLastErrorText(false));
        Observer.Observe('excl', GetLastErrorText(true));
        Observer.ObserveError('get');
        asserterror Rec.Get(99);
        Observer.Observe('same_excl', Format(GetLastErrorText(true) = GetLastErrorText(false)));
        Observer.ObserveError('get2');
        Rec."Entry No." := 5;
        asserterror Rec.Delete(true);
        Observer.Observe('delete_excl', GetLastErrorText(true));
        Observer.ObserveError('delete');
        asserterror Rec.Modify(true);
        Observer.Observe('modify_excl', GetLastErrorText(true));
        Observer.ObserveError('modify');
        Observer.Expect('full', 'The LT P86 Err Rec does not exist. Identification fields and values: Entry No.=''99''');
        Observer.Expect('excl', 'The LT P86 Err Rec does not exist. Identification fields and values: <redacted>');
        Observer.Expect('get|text', 'The LT P86 Err Rec does not exist. Identification fields and values: Entry No.=''99''');
        Observer.Expect('get|code', 'DB:RecordNotFound');
        Observer.Expect('same_excl', 'No');
        Observer.Expect('get2|text', 'The LT P86 Err Rec does not exist. Identification fields and values: Entry No.=''99''');
        Observer.Expect('get2|code', 'DB:RecordNotFound');
        Observer.Expect('delete_excl', 'The LT P86 Err Rec does not exist. Identification fields and values: <redacted>');
        Observer.Expect('delete|text', 'The LT P86 Err Rec does not exist. Identification fields and values: Entry No.=''5''');
        Observer.Expect('delete|code', 'DB:RecordNotFound');
        Observer.Expect('modify_excl', 'The LT P86 Err Rec does not exist. Identification fields and values: <redacted>');
        Observer.Expect('modify|text', 'The LT P86 Err Rec does not exist. Identification fields and values: Entry No.=''5''');
        Observer.Expect('modify|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure RuntimeError_Other()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P86 Err Rec";
        A: Integer;
        Zero: Integer;
    begin
        Rec.DeleteAll();
        A := 1;
        asserterror A := A div Zero;
        Observer.Observe('div_excl', GetLastErrorText(true));
        Observer.ObserveError('div');
        asserterror Rec.FindFirst();
        Observer.Observe('find_excl', GetLastErrorText(true));
        Observer.ObserveError('find');
        asserterror Rec.FindLast();
        Observer.Observe('findlast_excl', GetLastErrorText(true));
        Observer.ObserveError('findlast');
        Rec."Entry No." := 1;
        Observer.Expect('div_excl', 'Attempted to divide by zero.');
        Observer.Expect('div|text', 'Attempted to divide by zero.');
        Observer.Expect('div|code', 'AL:DivideByZero');
        Observer.Expect('find_excl', 'The LT P86 Err Rec table is empty.');
        Observer.Expect('find|text', 'The LT P86 Err Rec table is empty.');
        Observer.Expect('find|code', 'DB:TableIsEmpty');
        Observer.Expect('findlast_excl', 'The LT P86 Err Rec table is empty.');
        Observer.Expect('findlast|text', 'The LT P86 Err Rec table is empty.');
        Observer.Expect('findlast|code', 'DB:TableIsEmpty');
        Observer.Verify();
    end;

    [Test]
    procedure CallStack_Start()
    var
        Observer: Codeunit "Probe Observer";
        Stack: Text;
    begin
        asserterror Error('stack probe');
        Stack := GetLastErrorCallStack();
        Observer.Observe('has_stack', Format(Stack <> ''));
        Observer.Observe('start', CopyStr(Stack, 1, 20));
        Observer.Observe('mentions_proc', Format(StrPos(Stack, 'CallStack_Start') > 0));
        Observer.Observe('mentions_codeunit', Format(StrPos(Stack, 'LT P86 Last Error') > 0));
        Observer.ObserveError('err');
        Observer.Observe('stack_after_clear', GetLastErrorCallStack());
        Observer.Expect('has_stack', 'Yes');
        Observer.Expect('start', '"LT P86 Last Error"(');
        Observer.Expect('mentions_proc', 'Yes');
        Observer.Expect('mentions_codeunit', 'Yes');
        Observer.Expect('err|text', 'stack probe');
        Observer.Expect('err|code', 'Dialog');
        Observer.Expect('stack_after_clear', '');
        Observer.Verify();
    end;

    [Test]
    procedure CallStack_RaisedDeeper()
    var
        Observer: Codeunit "Probe Observer";
        Stack: Text;
    begin
        asserterror RaiseInfo('deeper', DataClassification::SystemMetadata);
        Stack := GetLastErrorCallStack();
        Observer.Observe('start', CopyStr(Stack, 1, 20));
        Observer.Observe('mentions_raise', Format(StrPos(Stack, 'RaiseInfo') > 0));
        Observer.Observe('mentions_test', Format(StrPos(Stack, 'CallStack_RaisedDeeper') > 0));
        Observer.Observe('raise_before_test', Format(StrPos(Stack, 'RaiseInfo') < StrPos(Stack, 'CallStack_RaisedDeeper')));
        Observer.ObserveError('err');
        Observer.Expect('start', '"LT P86 Last Error"(');
        Observer.Expect('mentions_raise', 'Yes');
        Observer.Expect('mentions_test', 'Yes');
        Observer.Expect('raise_before_test', 'Yes');
        Observer.Expect('err|text', 'deeper');
        Observer.Expect('err|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure CallStack_NoError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('text', GetLastErrorText(false));
        Observer.Observe('text_excl', GetLastErrorText(true));
        Observer.Observe('code', GetLastErrorCode());
        Observer.Observe('stack', GetLastErrorCallStack());
        Observer.Expect('text', '');
        Observer.Expect('text_excl', '');
        Observer.Expect('code', '');
        Observer.Expect('stack', '');
        Observer.Verify();
    end;
}

