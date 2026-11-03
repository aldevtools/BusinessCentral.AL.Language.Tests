// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 70087
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Streams: Write(Decimal) the 12-byte form (a Decimal of 19 or more digits, below 1E-28)
// Facts: bytes written by OutStream.Write(Decimal) for many magnitudes, precisions and signs
// BC versions: 29 (27 and 28 by CI)

codeunit 70089 "LT PnA Stream DecBytes"
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

    local procedure Dc(var Observer: Codeunit "Probe Observer"; Name: Text; Src: Text)
    var
        Rec: Record "LT PnA Blob" temporary;
        OutS: OutStream;
        D: Decimal;
    begin
        Evaluate(D, Src, 9);
        Rec.Data.CreateOutStream(OutS);
        OutS.Write(D);
        Observer.Observe(Name, Format(D, 0, 9) + '|' + Dump(Rec));
    end;

    [Test]
    procedure Write_Decimal_Small()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dc(Observer, 'zero', '0');
        Dc(Observer, 'one', '1');
        Dc(Observer, 'minus-one', '-1');
        Dc(Observer, 'half', '0.5');
        Dc(Observer, 'ten', '10');
        Dc(Observer, 'hundred', '100');
        Dc(Observer, 'thousand-and-a-half', '1000.5');
        Dc(Observer, 'five-decimals', '123.45678');
        Dc(Observer, 'minus-five-decimals', '-123.45678');
        Dc(Observer, 'ten-to-minus-8', '0.00000001');
        Dc(Observer, 'trailing-zeros', '1.50000');
        Observer.Expect('zero', '0|00 00 00 00 00 00 00 00 00 00 00 00');
        Observer.Expect('one', '1|40 00 00 00 00 00 00 00 00 10 00 00');
        Observer.Expect('minus-one', '-1|C0 00 00 00 00 00 00 00 00 10 00 00');
        Observer.Expect('half', '0.5|3F 00 00 00 00 00 00 00 00 50 00 00');
        Observer.Expect('ten', '10|41 00 00 00 00 00 00 00 00 10 00 00');
        Observer.Expect('hundred', '100|42 00 00 00 00 00 00 00 00 10 00 00');
        Observer.Expect('thousand-and-a-half', '1000.5|43 00 00 00 00 00 00 50 00 10 00 00');
        Observer.Expect('five-decimals', '123.45678|42 00 00 00 00 00 78 56 34 12 00 00');
        Observer.Expect('minus-five-decimals', '-123.45678|C2 00 00 00 00 00 78 56 34 12 00 00');
        Observer.Expect('ten-to-minus-8', '0.00000001|38 00 00 00 00 00 00 00 00 10 00 00');
        Observer.Expect('trailing-zeros', '1.5|40 00 00 00 00 00 00 00 00 15 00 00');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Decimal_Tiny()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dc(Observer, '1E-16', '0.0000000000000001');
        Dc(Observer, '1E-18', '0.000000000000000001');
        Dc(Observer, '1E-20', '0.00000000000000000001');
        Dc(Observer, '1E-27', '0.000000000000000000000000001');
        Dc(Observer, '1E-28', '0.0000000000000000000000000001');
        Dc(Observer, '1E-29', '0.00000000000000000000000000001');
        Dc(Observer, '1.5E-28', '0.00000000000000000000000000015');
        Dc(Observer, 'minus-1E-28', '-0.0000000000000000000000000001');
        Dc(Observer, '3-over-3-places', '0.333');
        Dc(Observer, 'thirds-18-places', '0.333333333333333333');
        Dc(Observer, 'thirds-28-places', '0.3333333333333333333333333333');
        Observer.Expect('1E-16', '0.0000000000000001|30 00 00 00 00 00 00 00 00 10 00 00');
        Observer.Expect('1E-18', '0.000000000000000001|2E 00 00 00 00 00 00 00 00 10 00 00');
        Observer.Expect('1E-20', '0|2C 00 00 00 00 00 00 00 00 10 00 00');
        Observer.Expect('1E-27', '0|25 00 00 00 00 00 00 00 00 10 00 00');
        Observer.Expect('1E-28', '0|24 00 00 00 00 00 00 00 00 10 00 00');
        Observer.Expect('1E-29', '0|00 00 00 00 00 00 00 00 00 00 00 00');
        Observer.Expect('1.5E-28', '0|24 00 00 00 00 00 00 00 00 20 00 00');
        Observer.Expect('minus-1E-28', '-0|A4 00 00 00 00 00 00 00 00 10 00 00');
        Observer.Expect('3-over-3-places', '0.333|3F 00 00 00 00 00 00 00 30 33 00 00');
        Observer.Expect('thirds-18-places', '0.333333333333333333|3F 33 33 33 33 33 33 33 33 33 00 00');
        Observer.Expect('thirds-28-places', '0.333333333333333333|3F 33 33 33 33 33 33 33 33 33 00 00');
        Observer.Verify();
    end;
}
