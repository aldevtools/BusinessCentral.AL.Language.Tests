// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-readtext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), System Application codeunit "Temp Blob"
// Probe: observed on the corpus CI (BC on Linux, legs 27.5, 28.5 and 29.0); every literal asserted below is what BC produced.
// Topic: which character each byte 128 to 255 reads as from a stream created without an encoding (and with TextEncoding::MSDos):
//   InStream.ReadText and BigText.Read of 32 bytes at a time, observed as the character codes. The UTF-8 bytes of a character
//   (C3 BC, 'ü') read without an encoding, between ASCII text.
//   (AL Runner issue 6968: a dependency app reads a UTF-8 XSD from a Blob without an encoding and searches each line.)
// BC versions: 27.5, 28.5, 29.0

codeunit 95481 "STR ReadText MsDos High Bytes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure WriteBytes(var TempBlob: Codeunit "Temp Blob"; First: Integer; Last: Integer)
    var
        OutS: OutStream;
        B: Byte;
        Value: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        for Value := First to Last do begin
            B := Value;
            OutS.Write(B);
        end;
    end;

    local procedure Codes(Value: Text): Text
    var
        i: Integer;
        Code: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            Code := Value[i];
            if Result <> '' then
                Result += ' ';
            Result += Format(Code);
        end;
        exit(Result);
    end;

    local procedure ObserveRange(var Observer: Codeunit "Probe Observer"; First: Integer; Last: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Line: Text;
        Big: BigText;
        Part: Text;
    begin
        WriteBytes(TempBlob, First, Last);
        TempBlob.CreateInStream(InS);
        InS.ReadText(Line);
        Observer.Observe('ReadText no encoding', Codes(Line));
        TempBlob.CreateInStream(InS, TextEncoding::MSDos);
        InS.ReadText(Line);
        Observer.Observe('ReadText MSDos', Codes(Line));
        TempBlob.CreateInStream(InS);
        Big.Read(InS);
        Big.GetSubText(Part, 1, Big.Length());
        Observer.Observe('BigText.Read no encoding', Codes(Part));
    end;

    [Test]
    procedure ReadText_NoEncoding_Bytes128To159()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRange(Observer, 128, 159);
        Observer.Finish();
    end;

    [Test]
    procedure ReadText_NoEncoding_Bytes160To191()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRange(Observer, 160, 191);
        Observer.Finish();
    end;

    [Test]
    procedure ReadText_NoEncoding_Bytes192To223()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRange(Observer, 192, 223);
        Observer.Finish();
    end;

    [Test]
    procedure ReadText_NoEncoding_Bytes224To255()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRange(Observer, 224, 255);
        Observer.Finish();
    end;

    [Test]
    procedure ReadText_NoEncoding_Utf8BytesBetweenLines()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        B: Byte;
        LineNo: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('urn:a');
        OutS.WriteText();
        B := 195;
        OutS.Write(B);
        B := 188;
        OutS.Write(B);
        OutS.WriteText(' urn:b');
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            LineNo += 1;
            InS.ReadText(Line);
            Observer.Observe('line ' + Format(LineNo), Codes(Line));
            Observer.Observe('line ' + Format(LineNo) + ' contains urn:', Format(Line.Contains('urn:')));
        end;
        Observer.Finish();
    end;
}
