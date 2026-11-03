// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 74932 "LT VarNum FR Row"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; "Int Value"; Integer) { }
        field(3; "Big Value"; BigInteger) { }
        field(4; "Dec Value"; Decimal) { }
        field(5; "Text Value"; Text[250]) { }
        field(6; "Code Value"; Code[50]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 74933 "LT VarNum FieldRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAssignText(var Row: Record "LT VarNum FR Row"; FR: FieldRef)
    begin
        Row."Text Value" := FR.Value();
    end;

    [TryFunction]
    local procedure TryAssignCode(var Row: Record "LT VarNum FR Row"; FR: FieldRef)
    begin
        Row."Code Value" := FR.Value();
    end;

    local procedure Seed(var Row: Record "LT VarNum FR Row")
    var
        B: BigInteger;
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 1;
        Row."Int Value" := 1234567;
        Evaluate(B, '5000000000');
        Row."Big Value" := B;
        Row."Dec Value" := 1234567.891;
    end;

    local procedure Run(var Row: Record "LT VarNum FR Row"; FieldNo: Integer; ToCode: Boolean): Text
    var
        RR: RecordRef;
        Ok: Boolean;
    begin
        RR.GetTable(Row);
        if ToCode then
            Ok := TryAssignCode(Row, RR.Field(FieldNo))
        else
            Ok := TryAssignText(Row, RR.Field(FieldNo));
        if Ok then begin
            if ToCode then
                exit('ok:' + Row."Code Value");
            exit('ok:' + Row."Text Value");
        end;
        exit('error:' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    [Test]
    procedure TextField_FromFieldRefValue_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT VarNum FR Row";
    begin
        Seed(Row);
        Observer.Observe('integer', Run(Row, 2, false));
        Observer.Observe('integer_format', Format(Row."Int Value"));
        Observer.Observe('biginteger', Run(Row, 3, false));
        Observer.Observe('biginteger_format', Format(Row."Big Value"));
        Observer.Observe('decimal', Run(Row, 4, false));
        Observer.Observe('decimal_format', Format(Row."Dec Value"));
        Observer.Expect('integer', 'ok:1234567');
        Observer.Expect('integer_format', '1234567');
        Observer.Expect('biginteger', 'ok:5000000000');
        Observer.Expect('biginteger_format', '5000000000');
        Observer.Expect('decimal', 'ok:1,234,567.891');
        Observer.Expect('decimal_format', '1,234,567.891');
        Observer.Verify();
    end;

    [Test]
    procedure CodeField_FromFieldRefValue_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT VarNum FR Row";
    begin
        Seed(Row);
        Observer.Observe('integer', Run(Row, 2, true));
        Observer.Observe('biginteger', Run(Row, 3, true));
        Observer.Observe('decimal', Run(Row, 4, true));
        Observer.Expect('integer', 'ok:1234567');
        Observer.Expect('biginteger', 'ok:5000000000');
        Observer.Expect('decimal', 'ok:1,234,567.891');
        Observer.Verify();
    end;

    [Test]
    procedure TextField_FromFieldRefValue_InsertedRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT VarNum FR Row";
        Target: Record "LT VarNum FR Row";
        RR: RecordRef;
    begin
        Seed(Row);
        Row.Insert();
        RR.GetTable(Row);
        Target.Init();
        Target."No." := 2;
        if TryAssignText(Target, RR.Field(3)) then
            Target.Insert()
        else
            Observer.Observe('assign error', GetLastErrorCode() + ':' + GetLastErrorText());
        if Target.Get(2) then
            Observer.Observe('stored text', Target."Text Value")
        else
            Observer.Observe('stored text', 'no row');
        Row.DeleteAll();
        Observer.Expect('stored text', '5000000000');
        Observer.Verify();
    end;
}
