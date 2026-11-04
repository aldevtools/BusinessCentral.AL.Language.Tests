// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-write-read-methods-line-break-behavior
// Scope: in-scope
// Fixtures used: codeunit 69160 "Probe Observer", codeunit 85909 "LT DE Helper", System Application codeunit "Temp Blob"
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Lead: corpus issue 671, item "Documented Write/WriteText/Read/ReadText line-break sequences". Pins the bytes, each ReadText and each
// Read(Text) result (value, return value, EOS) for the documented sequences: WriteText('A'); WriteText; WriteText('B'); WriteText; WriteText('C'),
// and Write('A' + CR LF + 'B'); Write('C'), plus a mix of Write and WriteText.

codeunit 85901 "LT DE Stream Line Breaks"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ReadTextAll(var Observer: Codeunit "Probe Observer"; Prefix: Text; var TempBlob: Codeunit "Temp Blob")
    var
        InS: InStream;
        T: Text;
        Ret: Integer;
        I: Integer;
    begin
        TempBlob.CreateInStream(InS);
        Observer.Observe(Prefix + ' eos before', Format(InS.EOS()));
        for I := 1 to 4 do
            if not InS.EOS() then begin
                Ret := InS.ReadText(T);
                Observer.Observe(Prefix + ' readtext ' + Format(I), Format(Ret) + '|' + T + '|' + Format(InS.EOS()));
            end;
    end;

    local procedure ReadAll(var Observer: Codeunit "Probe Observer"; Prefix: Text; var TempBlob: Codeunit "Temp Blob")
    var
        InS: InStream;
        T: Text;
        Ret: Integer;
        I: Integer;
    begin
        TempBlob.CreateInStream(InS);
        for I := 1 to 4 do
            if not InS.EOS() then begin
                Ret := InS.Read(T);
                Observer.Observe(Prefix + ' read ' + Format(I), Format(Ret) + '|' + T + '|' + Format(InS.EOS()));
            end;
    end;

    [Test]
    procedure WriteTextLines_ReadTextAndRead()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT DE Helper";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('A');
        OutS.WriteText();
        OutS.WriteText('B');
        OutS.WriteText();
        OutS.WriteText('C');
        Observer.Observe('bytes', Helper.HexOf(TempBlob));
        ReadTextAll(Observer, 'wt', TempBlob);
        ReadAll(Observer, 'wt', TempBlob);
        Observer.Expect('bytes', '41 0D 0A 42 0D 0A 43');
        Observer.Expect('wt eos before', 'No');
        Observer.Expect('wt readtext 1', '1|A|No');
        Observer.Expect('wt readtext 2', '1|B|No');
        Observer.Expect('wt readtext 3', '1|C|Yes');
        Observer.Expect('wt read 1', '7|A\r\nB\r\nC|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WriteWithLineBreak_ReadTextAndRead()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT DE Helper";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.Write('A' + Helper.CrLf() + 'B');
        OutS.Write('C');
        Observer.Observe('bytes', Helper.HexOf(TempBlob));
        ReadTextAll(Observer, 'w', TempBlob);
        ReadAll(Observer, 'w', TempBlob);
        Observer.Expect('bytes', '41 0D 0A 42 00 43 00');
        Observer.Expect('w eos before', 'No');
        Observer.Expect('w readtext 1', '1|A|No');
        Observer.Expect('w readtext 2', '1|B|No');
        Observer.Expect('w readtext 3', '1|C|Yes');
        Observer.Expect('w read 1', '5|A\r\nB|No');
        Observer.Expect('w read 2', '2|C|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WriteThenWriteText_ReadTextAndRead()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT DE Helper";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.Write('A');
        OutS.WriteText('B');
        OutS.WriteText();
        OutS.WriteText('C');
        OutS.Write('D');
        Observer.Observe('bytes', Helper.HexOf(TempBlob));
        ReadTextAll(Observer, 'mix', TempBlob);
        ReadAll(Observer, 'mix', TempBlob);
        Observer.Expect('bytes', '41 00 42 0D 0A 43 44 00');
        Observer.Expect('mix eos before', 'No');
        Observer.Expect('mix readtext 1', '1|A|No');
        Observer.Expect('mix readtext 2', '1|B|No');
        Observer.Expect('mix readtext 3', '2|CD|Yes');
        Observer.Expect('mix read 1', '2|A|No');
        Observer.Expect('mix read 2', '6|B\r\nCD|Yes');
        Observer.Verify();
    end;
}
