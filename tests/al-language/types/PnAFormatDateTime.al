// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Format: DateTime format 9 pinned; Time and DateTime format 1 with zero milliseconds; standard numbers of DateTime
// Facts: Format(DateTime, 0, N) for N 0 to 9 with and without milliseconds, and Date format numbers above 9
// BC versions: 29 (27 and 28 by CI)

codeunit 70095 "LT PnA Fmt DateTime"
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
    procedure DateTime_ZeroMilliseconds()
    var
        Observer: Codeunit "Probe Observer";
        Dt: DateTime;
        i: Integer;
    begin
        Dt := CreateDateTime(DMY2Date(15, 3, 2024), 123456T);
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(Dt, i));
        Observer.Expect('n0', '03/15/24 12:34 PM');
        Observer.Expect('n1', '03/15/24 12:34:56 PM');
        Observer.Expect('n2', '03/15/24 12:34 PM');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '2024-03-15T12:34:56Z');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_WithMilliseconds()
    var
        Observer: Codeunit "Probe Observer";
        Dt: DateTime;
        i: Integer;
    begin
        Dt := CreateDateTime(DMY2Date(15, 3, 2024), 123456T + 7);
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(Dt, i));
        Observer.Expect('n0', '03/15/24 12:34 PM');
        Observer.Expect('n1', '03/15/24 12:34:56.007 PM');
        Observer.Expect('n2', '03/15/24 12:34 PM');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '2024-03-15T12:34:56.007Z');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_MillisecondValues()
    var
        Observer: Codeunit "Probe Observer";
        Dt: DateTime;
    begin
        Dt := CreateDateTime(DMY2Date(15, 3, 2024), 123456T + 500);
        Observer.Observe('500-n1', F(Dt, 1));
        Observer.Observe('500-n9', F(Dt, 9));
        Dt := CreateDateTime(DMY2Date(15, 3, 2024), 123456T + 120);
        Observer.Observe('120-n1', F(Dt, 1));
        Observer.Observe('120-n9', F(Dt, 9));
        Dt := CreateDateTime(DMY2Date(15, 3, 2024), 123456T + 999);
        Observer.Observe('999-n9', F(Dt, 9));
        Dt := CreateDateTime(DMY2Date(1, 1, 2024), 000000T);
        Observer.Observe('midnight-n0', F(Dt, 0));
        Observer.Observe('midnight-n1', F(Dt, 1));
        Observer.Observe('midnight-n9', F(Dt, 9));
        Dt := CreateDateTime(0D, 0T);
        Observer.Observe('undefined-n0', F(Dt, 0));
        Observer.Observe('undefined-n9', F(Dt, 9));
        Dt := CreateDateTime(DMY2Date(15, 3, 2024), 0T);
        Observer.Observe('date-only-n9', F(Dt, 9));
        Observer.Expect('500-n1', '03/15/24 12:34:56.5 PM');
        Observer.Expect('500-n9', '2024-03-15T12:34:56.5Z');
        Observer.Expect('120-n1', '03/15/24 12:34:56.12 PM');
        Observer.Expect('120-n9', '2024-03-15T12:34:56.12Z');
        Observer.Expect('999-n9', '2024-03-15T12:34:56.999Z');
        Observer.Expect('midnight-n0', '01/01/24 12:00 AM');
        Observer.Expect('midnight-n1', '01/01/24 12:00:00 AM');
        Observer.Expect('midnight-n9', '2024-01-01T00:00:00Z');
        Observer.Expect('undefined-n0', '');
        Observer.Expect('undefined-n9', '');
        Observer.Expect('date-only-n9', '2024-03-15T00:00:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure Date_NumbersAbove9()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        i: Integer;
    begin
        D := DMY2Date(5, 3, 2024);
        for i := 0 to 12 do
            Observer.Observe('n' + Format(i), F(D, i));
        Observer.Observe('n20', F(D, 20));
        Observer.Observe('n99', F(D, 99));
        Observer.Observe('negative', F(D, -1));
        Observer.Expect('n0', '03/05/24');
        Observer.Expect('n1', '03/05/24');
        Observer.Expect('n2', '030524D');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', '2024-03-05');
        Observer.Expect('n10', 'error:Standard format number 10 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n11', 'error:Standard format number 11 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n12', 'error:Standard format number 12 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n20', 'error:Standard format number 20 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n99', 'error:Standard format number 99 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('negative', 'error:Standard format number -1 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Verify();
    end;
}
