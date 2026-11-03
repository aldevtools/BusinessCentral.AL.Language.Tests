// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Format: Milliseconds print as .fff (Time formats 2 and 9 and Time format 1 with zero milliseconds)
// Facts: Format(Time, 0, N) for N 0 to 9 with and without milliseconds
// BC versions: 29 (27 and 28 by CI)

codeunit 70094 "LT PnA Fmt Time"
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
    procedure Time_ZeroMilliseconds()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        i: Integer;
    begin
        T := 123456T;
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(T, i));
        Observer.Observe('default', Format(T));
        Observer.Expect('n0', '12:34:56 PM');
        Observer.Expect('n1', '12:34:56 PM');
        Observer.Expect('n2', '123456T');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '12:34:56');
        Observer.Expect('default', '12:34:56 PM');
        Observer.Verify();
    end;

    [Test]
    procedure Time_WithMilliseconds()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        i: Integer;
    begin
        T := 123456T + 7;
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(T, i));
        Observer.Observe('default', Format(T));
        Observer.Expect('n0', '12:34:56 PM');
        Observer.Expect('n1', '12:34:56.007 PM');
        Observer.Expect('n2', '123456.007T');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '12:34:56.007');
        Observer.Expect('default', '12:34:56 PM');
        Observer.Verify();
    end;

    [Test]
    procedure Time_MillisecondValues()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 123456T + 500;
        Observer.Observe('500-n2', F(T, 2));
        Observer.Observe('500-n9', F(T, 9));
        T := 123456T + 120;
        Observer.Observe('120-n2', F(T, 2));
        Observer.Observe('120-n9', F(T, 9));
        T := 123456T + 999;
        Observer.Observe('999-n2', F(T, 2));
        Observer.Observe('999-n9', F(T, 9));
        T := 000000T;
        Observer.Observe('midnight-n0', F(T, 0));
        Observer.Observe('midnight-n1', F(T, 1));
        Observer.Observe('midnight-n2', F(T, 2));
        Observer.Observe('midnight-n9', F(T, 9));
        T := 235959T + 999;
        Observer.Observe('last-ms-n9', F(T, 9));
        T := 090000T + 5;
        Observer.Observe('am-5ms-n1', F(T, 1));
        Observer.Observe('am-5ms-n9', F(T, 9));
        Observer.Expect('500-n2', '123456.5T');
        Observer.Expect('500-n9', '12:34:56.5');
        Observer.Expect('120-n2', '123456.12T');
        Observer.Expect('120-n9', '12:34:56.12');
        Observer.Expect('999-n2', '123456.999T');
        Observer.Expect('999-n9', '12:34:56.999');
        Observer.Expect('midnight-n0', '12:00:00 AM');
        Observer.Expect('midnight-n1', '12:00:00 AM');
        Observer.Expect('midnight-n2', '000000T');
        Observer.Expect('midnight-n9', '00:00:00');
        Observer.Expect('last-ms-n9', '23:59:59.999');
        Observer.Expect('am-5ms-n1', ' 9:00:00.005 AM');
        Observer.Expect('am-5ms-n9', '09:00:00.005');
        Observer.Verify();
    end;
}
