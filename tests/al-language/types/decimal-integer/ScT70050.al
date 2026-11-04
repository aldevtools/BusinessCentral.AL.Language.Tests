// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70050
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format of Decimals with format numbers 0 to 9
// BC versions: 29 (27 and 28 by CI)

codeunit 70050 "LT ScT Fmt Decimal Nums"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryF(V: Variant; N: Integer; var R: Text)
    begin
        R := Format(V, 0, N);
    end;

    local procedure F(V: Variant; N: Integer): Text
    var
        R: Text;
    begin
        if TryF(V, N, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure FormatNumbers_Positive()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        i: Integer;
    begin
        D := 1234567.891;
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(D, i));
        Observer.Observe('default', Format(D));
        Observer.Expect('n0', '1,234,567.891');
        Observer.Expect('n1', '1234567.891');
        Observer.Expect('n2', '1234567.891');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '1234567.891');
        Observer.Expect('default', '1,234,567.891');
        Observer.Verify();
    end;

    [Test]
    procedure FormatNumbers_Negative()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        i: Integer;
    begin
        D := -1234567.891;
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(D, i));
        Observer.Observe('default', Format(D));
        Observer.Expect('n0', '-1,234,567.891');
        Observer.Expect('n1', '-1234567.891');
        Observer.Expect('n2', '-1234567.891');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '-1234567.891');
        Observer.Expect('default', '-1,234,567.891');
        Observer.Verify();
    end;

    [Test]
    procedure FormatNumbers_Zero()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        i: Integer;
    begin
        D := 0;
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(D, i));
        Observer.Expect('n0', '0');
        Observer.Expect('n1', '0');
        Observer.Expect('n2', '0');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '0');
        Observer.Verify();
    end;

    [Test]
    procedure FormatNumbers_Small()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        i: Integer;
    begin
        D := 0.00001;
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(D, i));
        Observer.Observe('default', Format(D));
        Observer.Expect('n0', '0.00001');
        Observer.Expect('n1', '0.00001');
        Observer.Expect('n2', '0.00001');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '0.00001');
        Observer.Expect('default', '0.00001');
        Observer.Verify();
    end;

    [Test]
    procedure FormatNumbers_Fraction()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        i: Integer;
    begin
        D := 0.5;
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(D, i));
        Observer.Expect('n0', '0.5');
        Observer.Expect('n1', '0.5');
        Observer.Expect('n2', '0.5');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '0.5');
        Observer.Verify();
    end;

    [Test]
    procedure FormatNumbers_Large()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        i: Integer;
    begin
        D := 123456789012345.123456;
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(D, i));
        Observer.Observe('default', Format(D));
        Observer.Expect('n0', '123,456,789,012,345.123');
        Observer.Expect('n1', '123456789012345.123');
        Observer.Expect('n2', '123456789012345.123');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '123456789012345.123');
        Observer.Expect('default', '123,456,789,012,345.123');
        Observer.Verify();
    end;

    [Test]
    procedure FormatNumbers_Length()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 1234.5;
        Observer.Observe('len5', Format(D, 5, 0));
        Observer.Observe('len10', Format(D, 10, 0));
        Observer.Observe('len-10', Format(D, -10, 0));
        Observer.Observe('len3', Format(D, 3, 0));
        Observer.Observe('len1', Format(D, 1, 0));
        Observer.Observe('len10n1', Format(D, 10, 1));
        Observer.Observe('len10n2', Format(D, 10, 2));
        Observer.Observe('len10n9', Format(D, 10, 9));
        Observer.Expect('len5', '1,234');
        Observer.Expect('len10', '   1,234.5');
        Observer.Expect('len-10', '1,234.5');
        Observer.Expect('len3', '1,2');
        Observer.Expect('len1', '1');
        Observer.Expect('len10n1', '    1234.5');
        Observer.Expect('len10n2', '    1234.5');
        Observer.Expect('len10n9', '    1234.5');
        Observer.Verify();
    end;
}
