// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-getresourceastext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); the resources session/res/y18/high-bytes.bin (the bytes 80..FF once each) and
//   session/res/y18/windows1252.txt ('Zürich' CR LF 'Größe 5 €' in Windows-1252)
// Probe: observe form, measured by the corpus CI matrix (BC 27.5, 28.5, 29.0).
// Facts: which character each byte from 128 up becomes in NavApp.GetResourceAsText(Name) without a text encoding (the encoding
//   reads are pinned in Y18NavAppResourceEncodings.al and W5NavAppResources.al). A character outside 32..126 is shown as <code>.
//   Repro of aldevtools/BusinessCentral.AL.Runner#7775 (Part A, item 7).
// BC versions: 27.5, 28.5, 29.0

codeunit 77140 "SES ResText High Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Shown(Value: Text): Text
    var
        i: Integer;
        Code: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            Code := Value[i];
            if (Code < 32) or (Code > 126) then
                Result += '<' + Format(Code, 0, 9) + '>'
            else
                Result += CopyStr(Value, i, 1);
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryAsText(Name: Text; var Result: Text)
    var
        T: Text;
    begin
        T := NavApp.GetResourceAsText(Name);
        Result := Format(StrLen(T)) + ':' + Shown(T);
    end;

    local procedure ObserveAsText(var Observer: Codeunit "Probe Observer"; KeyName: Text; Name: Text)
    var
        Result: Text;
    begin
        ClearLastError();
        if TryAsText(Name, Result) then
            Observer.Observe(KeyName, 'ok:' + Result)
        else
            Observer.Observe(KeyName, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure GetResourceAsText_NoEncoding_HighBytes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAsText(Observer, 'highbytes', 'y18/high-bytes.bin');
        Observer.Finish();
    end;

    [Test]
    procedure GetResourceAsText_NoEncoding_Windows1252Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAsText(Observer, 'windows1252', 'y18/windows1252.txt');
        ObserveAsText(Observer, 'utf8', 'y18/utf8-nobom.txt');
        Observer.Finish();
    end;
}
