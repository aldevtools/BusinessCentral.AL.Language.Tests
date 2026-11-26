// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-getresourceastext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); the resources session/res/y18/high-bytes.bin (the bytes 80..FF once each) and
//   session/res/y18/windows1252.txt ('Zürich' CR LF 'Größe 5 €' in Windows-1252)
// Probe: measured by the corpus CI matrix (BC 27.5, 28.5, 29.0, run 43072734044); the values are the same on all three.
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
        Observer.Expect('highbytes', 'ok:128:<8364><129><8218><402><8222><8230><8224><8225><710><8240><352><8249><338><141><381><143><144><8216><8217><8220><8221><8226><8211><8212><732><8482><353><8250><339><157><382><376><160><161><162><163><164><165><166><167><168><169><170><171><172><173><174><175><176><177><178><179><180><181><182><183><184><185><186><187><188><189><190><191><192><193><194><195><196><197><198><199><200><201><202><203><204><205><206><207><208><209><210><211><212><213><214><215><216><217><218><219><220><221><222><223><224><225><226><227><228><229><230><231><232><233><234><235><236><237><238><239><240><241><242><243><244><245><246><247><248><249><250><251><252><253><254><255>');
        Observer.Verify();
    end;

    [Test]
    procedure GetResourceAsText_NoEncoding_Windows1252Text()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAsText(Observer, 'windows1252', 'y18/windows1252.txt');
        ObserveAsText(Observer, 'utf8', 'y18/utf8-nobom.txt');
        Observer.Expect('windows1252', 'ok:17:Z<252>rich<13><10>Gr<246><223>e 5 <8364>');
        Observer.Expect('utf8', 'ok:22:Z<195><188>rich<13><10>Gr<195><182><195><376>e 5 <226><8218><172>');
        Observer.Verify();
    end;
}
