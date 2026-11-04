// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: a format string with <Filler Char,0> (short form) next to <Filler Character,0> for an Integer, a Decimal and a Text;
//   TextBuilder.EnsureCapacity(-1) on an empty builder with capacity 16 and 50 and on 'abc' with capacity 16 and 50;
//   Format(Rec.Field) of Decimal fields with AutoFormatType 1, 2, 4 and 5 and AutoFormatExpression 'GBP'.
// BC versions: 27.5+

table 80403 "LT AX AutoFormat"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Integer) { }
        field(2; Dec0; Decimal) { }
        field(3; Dec1; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = 'GBP';
        }
        field(4; Dec2; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = 'GBP';
        }
        field(5; Dec4; Decimal)
        {
            AutoFormatType = 4;
            AutoFormatExpression = 'GBP';
        }
        field(6; Dec5; Decimal)
        {
            AutoFormatType = 5;
            AutoFormatExpression = 'GBP';
        }
    }

    keys
    {
        key(PK; PK) { Clustered = true; }
    }
}

codeunit 80423 "LT AX Filler Builder AutoFmt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFormat(Value: Variant; FormatString: Text; var Result: Text)
    begin
        Result := Format(Value, 0, FormatString);
    end;

    local procedure Fmt(Value: Variant; FormatString: Text): Text
    var
        Result: Text;
    begin
        if TryFormat(Value, FormatString, Result) then
            exit('[' + Result + ']');
        exit('error: ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure FillerChar_Integer()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        I := 5;
        Observer.Observe('Char', Fmt(I, '<Integer,4><Filler Char,0>'));
        Observer.Observe('Character', Fmt(I, '<Integer,4><Filler Character,0>'));
        Observer.Observe('Char*', Fmt(I, '<Integer,4><Filler Char,*>'));
        Observer.Observe('none', Fmt(I, '<Integer,4>'));
        Observer.Expect('Char', '[0005]');
        Observer.Expect('Character', '[0005]');
        Observer.Expect('Char*', '[***5]');
        Observer.Expect('none', '[   5]');
        Observer.Verify();
    end;

    [Test]
    procedure FillerChar_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 5.25;
        Observer.Observe('Char', Fmt(D, '<Integer,4><Filler Char,0><Decimals>'));
        Observer.Observe('Character', Fmt(D, '<Integer,4><Filler Character,0><Decimals>'));
        Observer.Observe('Char*', Fmt(D, '<Integer,4><Filler Char,*><Decimals>'));
        Observer.Observe('none', Fmt(D, '<Integer,4><Decimals>'));
        Observer.Expect('Char', '[0005.25]');
        Observer.Expect('Character', '[0005.25]');
        Observer.Expect('Char*', '[***5.25]');
        Observer.Expect('none', '[   5.25]');
        Observer.Verify();
    end;

    [Test]
    procedure FillerChar_Text()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := 'ab';
        Observer.Observe('Char', Fmt(T, '<Text,5><Filler Char,0>'));
        Observer.Observe('Character', Fmt(T, '<Text,5><Filler Character,0>'));
        Observer.Observe('Char*', Fmt(T, '<Text,5><Filler Char,*>'));
        Observer.Observe('none', Fmt(T, '<Text,5>'));
        Observer.Observe('plain', Fmt(T, '<Text>'));
        Observer.Expect('Char', '[ab000]');
        Observer.Expect('Character', '[ab000]');
        Observer.Expect('Char*', '[ab***]');
        Observer.Expect('none', '[ab   ]');
        Observer.Expect('plain', '[ab]');
        Observer.Verify();
    end;

    [Test]
    procedure FillerChar_DirectFormatCalls()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := 'ab';
        Observer.Observe('int', '[' + Format(5, 0, '<Integer,4><Filler Char,0>') + ']');
        Observer.Observe('dec', '[' + Format(5.25, 0, '<Integer,4><Filler Char,0><Decimals>') + ']');
        Observer.Observe('text', '[' + Format(T, 0, '<Text,5><Filler Char,0>') + ']');
        Observer.Expect('int', '[0005]');
        Observer.Expect('dec', '[0005.25]');
        Observer.Expect('text', '[ab000]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEnsure(var TB: TextBuilder; Cap: Integer; var Ret: Boolean)
    begin
        Ret := TB.EnsureCapacity(Cap);
    end;

    local procedure Ensure(var TB: TextBuilder): Text
    var
        Ret: Boolean;
        Before: Integer;
    begin
        Before := TB.Capacity();
        ClearLastError();
        if TryEnsure(TB, -1, Ret) then
            exit('cap ' + Format(Before) + ' ok ' + Format(Ret) + ' cap ' + Format(TB.Capacity()) + ' len ' + Format(TB.Length()));
        exit('cap ' + Format(Before) + ' error ' + GetLastErrorText() + '|' + GetLastErrorCode() + ' cap ' + Format(TB.Capacity()));
    end;

    [Test]
    procedure EnsureCapacityMinus1_EmptyBuilders()
    var
        Observer: Codeunit "Probe Observer";
        TB16: TextBuilder;
        TB50: TextBuilder;
    begin
        TB50.Capacity(50);
        Observer.Observe('empty16', Ensure(TB16));
        Observer.Observe('empty50', Ensure(TB50));
        Observer.Expect('empty16', 'cap 16 ok No cap 16 len 0');
        Observer.Expect('empty50', 'cap 50 ok No cap 50 len 0');
        Observer.Verify();
    end;

    [Test]
    procedure EnsureCapacityMinus1_AbcBuilders()
    var
        Observer: Codeunit "Probe Observer";
        TB16: TextBuilder;
        TB50: TextBuilder;
    begin
        TB16.Append('abc');
        TB50.Capacity(50);
        TB50.Append('abc');
        Observer.Observe('abc16', Ensure(TB16));
        Observer.Observe('abc50', Ensure(TB50));
        Observer.Expect('abc16', 'cap 16 ok No cap 16 len 3');
        Observer.Expect('abc50', 'cap 50 ok No cap 50 len 3');
        Observer.Verify();
    end;

    local procedure AllFields(var R: Record "LT AX AutoFormat"): Text
    begin
        exit(Format(R.Dec0) + '|' + Format(R.Dec1) + '|' + Format(R.Dec2) + '|' + Format(R.Dec4) + '|' + Format(R.Dec5));
    end;

    [Test]
    procedure AutoFormatField_FormatRecField()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT AX AutoFormat";
    begin
        R.Dec0 := 1234.56789;
        R.Dec1 := 1234.56789;
        R.Dec2 := 1234.56789;
        R.Dec4 := 1234.56789;
        R.Dec5 := 1234.56789;
        Observer.Observe('1234.56789', AllFields(R));
        R.Dec0 := 0.5;
        R.Dec1 := 0.5;
        R.Dec2 := 0.5;
        R.Dec4 := 0.5;
        R.Dec5 := 0.5;
        Observer.Observe('0.5', AllFields(R));
        R.Dec0 := -7;
        R.Dec1 := -7;
        R.Dec2 := -7;
        R.Dec4 := -7;
        R.Dec5 := -7;
        Observer.Observe('-7', AllFields(R));
        Observer.Expect('1234.56789', '1,234.56789|1,234.57|1,234.56789|1,234.57|1,234.56789');
        Observer.Expect('0.5', '0.5|0.50|0.50|0.50|0.50');
        Observer.Expect('-7', '-7|-7.00|-7.00|-7.00|-7.00');
        Observer.Verify();
    end;

    [Test]
    procedure AutoFormatField_FieldRefAndFormat9()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT AX AutoFormat";
        RR: RecordRef;
        S: Text;
        i: Integer;
    begin
        R.Dec0 := 1234.56789;
        R.Dec1 := 1234.56789;
        R.Dec2 := 1234.56789;
        R.Dec4 := 1234.56789;
        R.Dec5 := 1234.56789;
        RR.GetTable(R);
        for i := 2 to 6 do
            S += Format(RR.Field(i).Value) + '|';
        Observer.Observe('fieldref', S);
        Observer.Observe('format9', Format(R.Dec1, 0, 9) + '|' + Format(R.Dec2, 0, 9) + '|' + Format(R.Dec4, 0, 9) + '|' + Format(R.Dec5, 0, 9));
        Observer.Observe('format1', Format(R.Dec1, 0, 1) + '|' + Format(R.Dec2, 0, 1) + '|' + Format(R.Dec5, 0, 1));
        Observer.Expect('fieldref', '1,234.56789|1,234.56789|1,234.56789|1,234.56789|1,234.56789|');
        Observer.Expect('format9', '1234.57|1234.56789|1234.57|1234.56789');
        Observer.Expect('format1', '1234.57|1234.56789|1234.56789');
        Observer.Verify();
    end;
}
