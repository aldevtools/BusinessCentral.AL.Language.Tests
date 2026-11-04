// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67167 "LT GT Int Key"
// Probe: Record.Get with a text argument on a table with an Integer primary key: Get(''), Get('2'), Get('abc'), Get(' 2'); and the same through a Variant holding a
// Text, and a RecordRef field set from text. GetBySystemId with a Variant holding a Text and one holding a Guid.
// Object ids 67167 - 67168.

table 67167 "LT GT Int Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67168 "LT GT Get Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT GT Int Key";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 0;
        Row.Name := 'zero';
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryGetVariant(Arg: Variant; var Found: Boolean; var Name: Text)
    var
        Row: Record "LT GT Int Key";
    begin
        Found := Row.Get(Arg);
        Name := Row.Name;
    end;

    [TryFunction]
    local procedure TryGetBySystemIdVariant(Arg: Variant; var Found: Boolean; var Name: Text)
    var
        Row: Record "LT GT Int Key";
    begin
        Found := Row.GetBySystemId(Arg);
        Name := Row.Name;
    end;

    local procedure ViaVariant(Arg: Variant): Text
    var
        Found: Boolean;
        Name: Text;
    begin
        ClearLastError();
        if TryGetVariant(Arg, Found, Name) then
            exit('found=' + Format(Found) + '|name=' + Name);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ViaSystemId(Arg: Variant): Text
    var
        Found: Boolean;
        Name: Text;
    begin
        ClearLastError();
        if TryGetBySystemIdVariant(Arg, Found, Name) then
            exit('found=' + Format(Found) + '|name=' + Name);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Get_TextForIntegerKey()
    var
        Observer: Codeunit "Probe Observer";
        Text1: Text;
    begin
        Seed();
        Text1 := '';
        Observer.Observe('empty_text', ViaVariant(Text1));
        Text1 := '2';
        Observer.Observe('text_2', ViaVariant(Text1));
        Text1 := 'abc';
        Observer.Observe('text_abc', ViaVariant(Text1));
        Text1 := ' 2';
        Observer.Observe('text_space_2', ViaVariant(Text1));
        Text1 := '2.0';
        Observer.Observe('text_2_0', ViaVariant(Text1));
        Observer.Observe('integer_0', ViaVariant(0));
        Observer.Observe('integer_2', ViaVariant(2));
#if BC28PLUS
        Observer.Expect('empty_text', 'error:The value "" can''t be evaluated into type Integer.|Evaluate:Format');
#else
        Observer.Expect('empty_text', 'error:The type NavInteger is unknown.|NotSupportedType');
#endif
        Observer.Expect('text_2', 'found=Yes|name=two');
#if BC28PLUS
        Observer.Expect('text_abc', 'error:The value "abc" can''t be evaluated into type Integer.|Evaluate:Format');
#else
        Observer.Expect('text_abc', 'error:The type NavInteger is unknown.|NotSupportedType');
#endif
        Observer.Expect('text_space_2', 'found=Yes|name=two');
#if BC28PLUS
        Observer.Expect('text_2_0', 'error:The value "2.0" can''t be evaluated into type Integer.|Evaluate:Format');
#else
        Observer.Expect('text_2_0', 'error:The type NavInteger is unknown.|NotSupportedType');
#endif
        Observer.Expect('integer_0', 'found=Yes|name=zero');
        Observer.Expect('integer_2', 'found=Yes|name=two');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryGetDirect(Text1: Text; var Found: Boolean; var Name: Text)
    var
        Row: Record "LT GT Int Key";
    begin
        Found := Row.Get(Text1);
        Name := Row.Name;
    end;

    [Test]
    procedure Get_TextVariableDirect()
    var
        Observer: Codeunit "Probe Observer";
        Found: Boolean;
        Name: Text;
    begin
        Seed();
        ClearLastError();
        Observer.Observe('empty_text_returned', Format(TryGetDirect('', Found, Name)));
        Observer.Observe('empty_text_found', Format(Found));
        Observer.ObserveError('empty_text');
        Observer.Observe('text_2_returned', Format(TryGetDirect('2', Found, Name)));
        Observer.Observe('text_2_found', Format(Found) + '|' + Name);
        Observer.Expect('empty_text_returned', 'No');
        Observer.Expect('empty_text_found', 'No');
#if BC28PLUS
        Observer.Expect('empty_text|text', 'The value "" can''t be evaluated into type Integer.');
#else
        Observer.Expect('empty_text|text', 'The type NavInteger is unknown.');
#endif
#if BC28PLUS
        Observer.Expect('empty_text|code', 'Evaluate:Format');
#else
        Observer.Expect('empty_text|code', 'NotSupportedType');
#endif
        Observer.Expect('text_2_returned', 'Yes');
        Observer.Expect('text_2_found', 'Yes|two');
        Observer.Verify();
    end;

    [Test]
    procedure GetBySystemId_TextAndGuid()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT GT Int Key";
        Text1: Text;
    begin
        Seed();
        Row.Get(2);
        Text1 := Format(Row.SystemId);
        Observer.Observe('guid', ViaSystemId(Row.SystemId));
        Observer.Observe('text_of_the_guid', ViaSystemId(Text1));
        Text1 := '';
        Observer.Observe('empty_text', ViaSystemId(Text1));
        Text1 := 'not a guid';
        Observer.Observe('text_not_a_guid', ViaSystemId(Text1));
        Observer.Observe('integer', ViaSystemId(2));
        Observer.Expect('guid', 'found=Yes|name=two');
        Observer.Expect('text_of_the_guid', 'found=Yes|name=two');
        Observer.Expect('empty_text', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Expect('text_not_a_guid', 'error:Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.|InvalidGuidFormat');
        Observer.Expect('integer', 'error:The expression Variant cannot be type-converted to a GUID value.|TypeConversion');
        Observer.Verify();
    end;
}
