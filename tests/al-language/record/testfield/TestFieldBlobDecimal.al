// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67181 "LT TF Row"
// Probe: (1) TestField on a Blob field: with no content, with content, after Get without CalcFields, after Get with CalcFields, after the content is cleared, and with
// a value argument; the error text and code; (2) TestField on a Decimal field against a value that has more decimals than the stored value
// (20.63667 stored, 20.6366666666666667 compared), against a value that differs in the sixth decimal, and for a field with DecimalPlaces.
// Settles: test-field-blob-with-stored-content. Object ids 67181 - 67182.

table 67181 "LT TF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
        field(3; Cost; Decimal) { DecimalPlaces = 2 : 5; }
        field(4; Plain; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67182 "LT TF Blob Decimal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Put(var Row: Record "LT TF Row"; Value: Text)
    var
        OutS: OutStream;
    begin
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText(Value);
    end;

    [TryFunction]
    local procedure TryTestFieldBlob(var Row: Record "LT TF Row")
    begin
        Row.TestField(Data);
    end;

    local procedure BlobOutcome(var Row: Record "LT TF Row"): Text
    begin
        ClearLastError();
        if TryTestFieldBlob(Row) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure TestField_Blob_StoredContent()
    var
        Row: Record "LT TF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
        Observer.Observe('empty_in_memory', BlobOutcome(Row));
        Put(Row, 'content');
        Observer.Observe('content_in_memory', BlobOutcome(Row));
        Row.Modify();
        Row.Get(1);
        Observer.Observe('after_get_without_calcfields', BlobOutcome(Row));
        Row.CalcFields(Data);
        Observer.Observe('after_calcfields', BlobOutcome(Row));
        Clear(Row.Data);
        Observer.Observe('after_clear_in_memory', BlobOutcome(Row));
        Row.Modify();
        Row.Get(1);
        Row.CalcFields(Data);
        Observer.Observe('after_clear_saved_and_calcfields', BlobOutcome(Row));
        Observer.Expect('empty_in_memory', 'error:Data must have a value in LT TF Row: Id=1. It cannot be zero or empty.|TestField');
        Observer.Expect('content_in_memory', 'ok');
        Observer.Expect('after_get_without_calcfields', 'ok');
        Observer.Expect('after_calcfields', 'ok');
        Observer.Expect('after_clear_in_memory', 'error:Data must have a value in LT TF Row: Id=1. It cannot be zero or empty.|TestField');
        Observer.Expect('after_clear_saved_and_calcfields', 'error:Data must have a value in LT TF Row: Id=1. It cannot be zero or empty.|TestField');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_Blob_AutoCalcAndSetLoadFields()
    var
        Row: Record "LT TF Row";
        Fresh: Record "LT TF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Put(Row, 'content');
        Row.Insert();
        Fresh.SetAutoCalcFields(Data);
        Fresh.Get(1);
        Observer.Observe('setautocalcfields_then_get', BlobOutcome(Fresh));
        Clear(Fresh);
        Fresh.SetRange(Id, 1);
        Fresh.FindFirst();
        Observer.Observe('findfirst_without_calcfields', BlobOutcome(Fresh));
        Observer.Expect('setautocalcfields_then_get', 'ok');
        Observer.Expect('findfirst_without_calcfields', 'ok');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryTestFieldDecimal(var Row: Record "LT TF Row"; FieldNo: Integer; Value: Decimal)
    begin
        case FieldNo of
            3:
                Row.TestField(Cost, Value);
            4:
                Row.TestField(Plain, Value);
        end;
    end;

    local procedure DecimalOutcome(var Row: Record "LT TF Row"; FieldNo: Integer; Value: Decimal): Text
    begin
        ClearLastError();
        if TryTestFieldDecimal(Row, FieldNo, Value) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure TestField_Decimal_Rounding()
    var
        Row: Record "LT TF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Cost := 20.6366666666666667;
        Row.Plain := 20.6366666666666667;
        Observer.Observe('stored_cost_in_memory', Format(Row.Cost, 0, 9));
        Observer.Observe('stored_plain_in_memory', Format(Row.Plain, 0, 9));
        Row.Insert();
        Row.Get(1);
        Observer.Observe('stored_cost_after_get', Format(Row.Cost, 0, 9));
        Observer.Observe('stored_plain_after_get', Format(Row.Plain, 0, 9));
        Observer.Observe('cost_same_long_value', DecimalOutcome(Row, 3, 20.6366666666666667));
        Observer.Observe('cost_rounded_5', DecimalOutcome(Row, 3, 20.63667));
        Observer.Observe('cost_rounded_4', DecimalOutcome(Row, 3, 20.6367));
        Observer.Observe('cost_sixth_decimal', DecimalOutcome(Row, 3, 20.636671));
        Observer.Observe('cost_sixth_decimal_below', DecimalOutcome(Row, 3, 20.636669));
        Observer.Observe('plain_same_long_value', DecimalOutcome(Row, 4, 20.6366666666666667));
        Observer.Observe('plain_rounded_5', DecimalOutcome(Row, 4, 20.63667));
        Observer.Observe('plain_sixth_decimal', DecimalOutcome(Row, 4, 20.636671));
        Observer.Observe('plain_tiny_difference', DecimalOutcome(Row, 4, 20.63666666666668));
        Observer.Expect('stored_cost_in_memory', '20.63667');
        Observer.Expect('stored_plain_in_memory', '20.6366666666666667');
        Observer.Expect('stored_cost_after_get', '20.63667');
        Observer.Expect('stored_plain_after_get', '20.6366666666666667');
        Observer.Expect('cost_same_long_value', 'ok');
        Observer.Expect('cost_rounded_5', 'error:Cost must be equal to ''20.63667''  in LT TF Row: Id=1. Current value is ''20.6366666666666667''.|TestField');
        Observer.Expect('cost_rounded_4', 'error:Cost must be equal to ''20.6367''  in LT TF Row: Id=1. Current value is ''20.6366666666666667''.|TestField');
        Observer.Expect('cost_sixth_decimal', 'error:Cost must be equal to ''20.636671''  in LT TF Row: Id=1. Current value is ''20.6366666666666667''.|TestField');
        Observer.Expect('cost_sixth_decimal_below', 'error:Cost must be equal to ''20.636669''  in LT TF Row: Id=1. Current value is ''20.6366666666666667''.|TestField');
        Observer.Expect('plain_same_long_value', 'ok');
        Observer.Expect('plain_rounded_5', 'error:Plain must be equal to ''20.63667''  in LT TF Row: Id=1. Current value is ''20.6366666666666667''.|TestField');
        Observer.Expect('plain_sixth_decimal', 'error:Plain must be equal to ''20.636671''  in LT TF Row: Id=1. Current value is ''20.6366666666666667''.|TestField');
        Observer.Expect('plain_tiny_difference', 'error:Plain must be equal to ''20.63666666666668''  in LT TF Row: Id=1. Current value is ''20.6366666666666667''.|TestField');
        Observer.Verify();
    end;
}
