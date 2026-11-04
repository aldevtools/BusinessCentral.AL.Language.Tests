// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 70087
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Streams: Write(Date) writes 2 * day number + 731 (+1 for a closing date, 0 for 0D)
// Facts: bytes written by OutStream.Write(Date) for plain dates, closing dates, 0D, the first and last date
// BC versions: 29 (27 and 28 by CI)

codeunit 70088 "LT PnA Stream DateBytes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure HexByte(B: Byte): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1));
    end;

    local procedure Dump(var Rec: Record "LT PnA Blob" temporary): Text
    var
        InS: InStream;
        B: Byte;
        R: Text;
    begin
        Rec.Data.CreateInStream(InS);
        while not InS.EOS do begin
            InS.Read(B);
            R += HexByte(B) + ' ';
        end;
        exit(DelChr(R, '>', ' '));
    end;

    local procedure Dt(var Observer: Codeunit "Probe Observer"; Name: Text; D: Date)
    var
        Rec: Record "LT PnA Blob" temporary;
        OutS: OutStream;
    begin
        Rec.Data.CreateOutStream(OutS);
        OutS.Write(D);
        Observer.Observe(Name, Dump(Rec));
    end;

    [Test]
    procedure Write_Date()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt(Observer, 'no-date', 0D);
        Dt(Observer, '1753-01-01', DMY2Date(1, 1, 1753));
        Dt(Observer, '1753-01-02', DMY2Date(2, 1, 1753));
        Dt(Observer, '2000-01-01', DMY2Date(1, 1, 2000));
        Dt(Observer, '2023-12-31', DMY2Date(31, 12, 2023));
        Dt(Observer, '2024-01-01', DMY2Date(1, 1, 2024));
        Dt(Observer, '2024-02-29', DMY2Date(29, 2, 2024));
        Dt(Observer, '2025-01-01', DMY2Date(1, 1, 2025));
        Dt(Observer, '9999-12-31', DMY2Date(31, 12, 9999));
        Observer.Expect('no-date', '00 00 00 00');
        Observer.Expect('1753-01-01', '1F 8A 13 00');
        Observer.Expect('1753-01-02', '21 8A 13 00');
        Observer.Expect('2000-01-01', 'EB 4A 16 00');
        Observer.Expect('2023-12-31', '65 8F 16 00');
        Observer.Expect('2024-01-01', '67 8F 16 00');
        Observer.Expect('2024-02-29', 'DD 8F 16 00');
        Observer.Expect('2025-01-01', '43 92 16 00');
        Observer.Expect('9999-12-31', '91 76 6F 00');
        Observer.Verify();
    end;

    [Test]
    procedure Write_ClosingDate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt(Observer, 'closing-2023-12-31', ClosingDate(DMY2Date(31, 12, 2023)));
        Dt(Observer, 'closing-2024-12-31', ClosingDate(DMY2Date(31, 12, 2024)));
        Dt(Observer, 'closing-2024-06-30', ClosingDate(DMY2Date(30, 6, 2024)));
        Dt(Observer, 'closing-2024-01-01', ClosingDate(DMY2Date(1, 1, 2024)));
        Dt(Observer, 'closing-1753-01-01', ClosingDate(DMY2Date(1, 1, 1753)));
        Dt(Observer, 'closing-9999-12-31', ClosingDate(DMY2Date(31, 12, 9999)));
        asserterror Dt(Observer, 'closing-no-date', ClosingDate(0D));
        Observer.ObserveError('af74');
        Dt(Observer, 'normal-after-closing', NormalDate(ClosingDate(DMY2Date(31, 12, 2024))));
        Observer.Expect('closing-2023-12-31', '66 8F 16 00');
        Observer.Expect('closing-2024-12-31', '42 92 16 00');
        Observer.Expect('closing-2024-06-30', 'D2 90 16 00');
        Observer.Expect('closing-2024-01-01', '68 8F 16 00');
        Observer.Expect('closing-1753-01-01', '20 8A 13 00');
        Observer.Expect('closing-9999-12-31', '92 76 6F 00');
        Observer.Expect('af74|text', 'The date is not valid.');
        Observer.Expect('af74|code', 'DateInvalid');
        Observer.Expect('normal-after-closing', '41 92 16 00');
        Observer.Verify();
    end;
}
