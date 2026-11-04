// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-readtext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), System Application codeunit "Temp Blob"
// Probe: observed on the corpus CI (BC on Linux, legs 27.5, 28.5 and 29.0); every literal asserted below is what BC produced.
// Topic: which character each byte 128 to 255 reads as from a stream created without an encoding (and with TextEncoding::MSDos):
//   InStream.ReadText and BigText.Read of 32 bytes at a time, observed as the character codes. The UTF-8 bytes of a character
//   (C3 BC, 'ü') read without an encoding, between ASCII text.
//   (AL Runner issue 6968: a dependency app reads a UTF-8 XSD from a Blob without an encoding and searches each line.)
// Facts (29.0): no read is refused. ReadText without an encoding, ReadText with TextEncoding::MSDos and BigText.Read give the same character
//   for every byte; the full table of the 128 bytes is asserted below (for example 80 is 199, 9E is 15, B1 is 8364, C3 is 8220, FF is 160).
//   C3 BC between ASCII text reads as 8220 338 and the line still contains 'urn:'.
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
        Observer.Expect('ReadText no encoding', '199 252 233 226 228 224 229 231 234 235 232 239 238 236 196 197 201 230 198 244 246 242 251 249 255 214 220 162 163 165 15 402');
        Observer.Expect('ReadText MSDos', '199 252 233 226 228 224 229 231 234 235 232 239 238 236 196 197 201 230 198 244 246 242 251 249 255 214 220 162 163 165 15 402');
        Observer.Expect('BigText.Read no encoding', '199 252 233 226 228 224 229 231 234 235 232 239 238 236 196 197 201 230 198 244 246 242 251 249 255 214 220 162 163 165 15 402');
        Observer.Verify();
    end;

    [Test]
    procedure ReadText_NoEncoding_Bytes160To191()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRange(Observer, 160, 191);
        Observer.Expect('ReadText no encoding', '225 237 243 250 241 209 170 186 191 20 172 189 188 161 171 187 21 8364 129 8218 8222 8230 8224 8225 710 8240 352 8249 338 141 381 143');
        Observer.Expect('ReadText MSDos', '225 237 243 250 241 209 170 186 191 20 172 189 188 161 171 187 21 8364 129 8218 8222 8230 8224 8225 710 8240 352 8249 338 141 381 143');
        Observer.Expect('BigText.Read no encoding', '225 237 243 250 241 209 170 186 191 20 172 189 188 161 171 187 21 8364 129 8218 8222 8230 8224 8225 710 8240 352 8249 338 141 381 143');
        Observer.Verify();
    end;

    [Test]
    procedure ReadText_NoEncoding_Bytes192To223()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRange(Observer, 192, 223);
        Observer.Expect('ReadText no encoding', '144 8216 8217 8220 8221 8226 8211 8212 732 8482 353 8250 339 157 382 376 168 169 173 174 175 179 180 184 185 190 192 193 194 166 195 200');
        Observer.Expect('ReadText MSDos', '144 8216 8217 8220 8221 8226 8211 8212 732 8482 353 8250 339 157 382 376 168 169 173 174 175 179 180 184 185 190 192 193 194 166 195 200');
        Observer.Expect('BigText.Read no encoding', '144 8216 8217 8220 8221 8226 8211 8212 732 8482 353 8250 339 157 382 376 168 169 173 174 175 179 180 184 185 190 192 193 194 166 195 200');
        Observer.Verify();
    end;

    [Test]
    procedure ReadText_NoEncoding_Bytes224To255()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRange(Observer, 224, 255);
        Observer.Expect('ReadText no encoding', '202 223 203 204 205 206 181 207 208 210 211 212 213 215 216 217 218 177 219 221 222 227 247 240 176 245 183 248 253 178 254 160');
        Observer.Expect('ReadText MSDos', '202 223 203 204 205 206 181 207 208 210 211 212 213 215 216 217 218 177 219 221 222 227 247 240 176 245 183 248 253 178 254 160');
        Observer.Expect('BigText.Read no encoding', '202 223 203 204 205 206 181 207 208 210 211 212 213 215 216 217 218 177 219 221 222 227 247 240 176 245 183 248 253 178 254 160');
        Observer.Verify();
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
        Observer.Expect('line 1', '117 114 110 58 97');
        Observer.Expect('line 1 contains urn:', 'Yes');
        Observer.Expect('line 2', '8220 338 32 117 114 110 58 98');
        Observer.Expect('line 2 contains urn:', 'Yes');
        Observer.Verify();
    end;
}
