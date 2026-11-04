// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72522
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows (Probe round 6, types and JSON): "RoundDateTime - Only one case pins where the multiples of a precision start",
// "DateTime + Decimal - The conversion error has an empty code", "Encrypt - The text is 256 pseudo-random bytes" (Decrypt('') part)
// Facts: RoundDateTime origin for 1100000 ms, DateTime plus decimal, overflow error code, Decrypt of empty text
// BC versions: 29 (27 and 28 by CI)

codeunit 72522 "LT PnE DateTime Round"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RoundDateTime_Precision1100000()
    var
        Observer: Codeunit "Probe Observer";
        Dt: DateTime;
        i: Integer;
    begin
        for i := 0 to 5 do begin
            Dt := CreateDateTime(DMY2Date(1 + i * 3, 3, 2021), 000000T);
            Observer.Observe('down' + Format(i), Format(RoundDateTime(Dt, 1100000, '<'), 0, 9));
            Observer.Observe('up' + Format(i), Format(RoundDateTime(Dt, 1100000, '>'), 0, 9));
            Observer.Observe('nearest' + Format(i), Format(RoundDateTime(Dt, 1100000), 0, 9));
        end;
        Observer.Expect('down0', '2021-02-28T23:46:40Z');
        Observer.Expect('up0', '2021-03-01T00:05:00Z');
        Observer.Expect('nearest0', '2021-03-01T00:05:00Z');
        Observer.Expect('down1', '2021-03-03T23:53:20Z');
        Observer.Expect('up1', '2021-03-04T00:11:40Z');
        Observer.Expect('nearest1', '2021-03-03T23:53:20Z');
        Observer.Expect('down2', '2021-03-07T00:00:00Z');
        Observer.Expect('up2', '2021-03-07T00:00:00Z');
        Observer.Expect('nearest2', '2021-03-07T00:00:00Z');
        Observer.Expect('down3', '2021-03-09T23:48:20Z');
        Observer.Expect('up3', '2021-03-10T00:06:40Z');
        Observer.Expect('nearest3', '2021-03-10T00:06:40Z');
        Observer.Expect('down4', '2021-03-12T23:55:00Z');
        Observer.Expect('up4', '2021-03-13T00:13:20Z');
        Observer.Expect('nearest4', '2021-03-12T23:55:00Z');
        Observer.Expect('down5', '2021-03-15T23:43:20Z');
        Observer.Expect('up5', '2021-03-16T00:01:40Z');
        Observer.Expect('nearest5', '2021-03-16T00:01:40Z');
        Observer.Verify();
    end;

    [Test]
    procedure RoundDateTime_OtherPrecisions()
    var
        Observer: Codeunit "Probe Observer";
        Dt: DateTime;
    begin
        Dt := CreateDateTime(DMY2Date(17, 6, 2022), 123456T);
        Observer.Observe('p1100000', Format(RoundDateTime(Dt, 1100000, '<'), 0, 9));
        Observer.Observe('p7000', Format(RoundDateTime(Dt, 7000, '<'), 0, 9));
        Observer.Observe('p13000', Format(RoundDateTime(Dt, 13000, '<'), 0, 9));
        Observer.Observe('p100000000', Format(RoundDateTime(Dt, 100000000, '<'), 0, 9));
        Observer.Observe('p700000', Format(RoundDateTime(Dt, 700000, '<'), 0, 9));
        Observer.Expect('p1100000', '2022-06-17T12:18:20Z');
        Observer.Expect('p7000', '2022-06-17T12:34:56Z');
        Observer.Expect('p13000', '2022-06-17T12:34:48Z');
        Observer.Expect('p100000000', '2022-06-16T12:00:00Z');
        Observer.Expect('p700000', '2022-06-17T12:31:40Z');
        Observer.Verify();
    end;

    [Test]
    procedure DateTimePlusDecimal_Overflow()
    var
        Observer: Codeunit "Probe Observer";
        Dt: DateTime;
        D: Decimal;
        R: DateTime;
    begin
        Dt := CreateDateTime(DMY2Date(1, 1, 2022), 120000T);
        D := 999999999999999999.0;
        asserterror R := Dt + D;
        Observer.ObserveError('plusHuge');
        D := -999999999999999999.0;
        asserterror R := Dt + D;
        Observer.ObserveError('minusHuge');
        Observer.Expect('plusHuge|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('plusHuge|code', 'AL:Overflow');
        Observer.Expect('minusHuge|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('minusHuge|code', 'AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure Decrypt_EmptyText()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        R := Decrypt('');
        Observer.Observe('decryptEmpty', 'no error');
        asserterror R := Decrypt('not encrypted text');
        Observer.ObserveError('decryptPlain');
        Observer.Expect('decryptEmpty', 'no error');
        Observer.Expect('decryptPlain|text', 'Unable to decrypt data. The data was encrypted using a different key.');
        Observer.Expect('decryptPlain|code', 'Encryption:Cryptographic');
        Observer.Verify();
    end;
}
