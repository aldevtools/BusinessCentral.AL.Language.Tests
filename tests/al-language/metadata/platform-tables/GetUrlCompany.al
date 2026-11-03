// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73980
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: GetUrl company argument variants (blank, unknown, case, special chars, long)
// BC versions: 29
// Tag: P95

codeunit 73980 "LT P95 GetUrl Company"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Shape(Url: Text): Text
    begin
        exit(Format(Url <> '') + '|' + Format(Url.StartsWith('http')) + '|' + Format(Url.Contains('company=')) + '|' + Format(Url.Contains('page=')) + '|' + Format(Url.Contains('report=')) + '|' + Format(Url.Contains('codeunit=')) + '|' + Format(Url.Contains('table=')));
    end;

    local procedure Tail(Url: Text): Text
    var
        P: Integer;
    begin
        P := StrPos(Url, '?');
        if P = 0 then
            exit('noquery');
        exit(CopyStr(Url, P));
    end;

    local procedure Err(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;


    [TryFunction]
    local procedure TryU(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::Web, Cn);
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; Name: Text; Cn: Text)
    var
        R: Text;
    begin
        if TryU(Cn, R) then
            Observer.Observe(Name, Shape(R) + '|' + Tail(R))
        else
            Observer.Observe(Name, Err());
    end;

    [Test]
    procedure GetUrl_Company_Variants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, 'blank', ' ');
        One(Observer, 'nonexistent', 'No Such Company P95');
        One(Observer, 'lower_current', LowerCase(CompanyName()));
        One(Observer, 'upper_current', UpperCase(CompanyName()));
        One(Observer, 'ampersand', 'A&B');
        One(Observer, 'space_slash', 'A B/C');
        One(Observer, 'percent', '100%');
        One(Observer, 'unicode', 'Gesch' + 'ae' + 'ft Ü€');
        One(Observer, 'quote', 'It''s');
        One(Observer, 'hash_question', 'A#B?C');
        One(Observer, 'long', PadStr('', 120, 'x'));
        Observer.Expect('blank', 'Yes|Yes|Yes|No|No|No|No|?company=%20');
        Observer.Expect('nonexistent', 'Yes|Yes|Yes|No|No|No|No|?company=No%20Such%20Company%20P95');
        Observer.Expect('lower_current', 'Yes|Yes|Yes|No|No|No|No|?company=cronus%20international%20ltd.');
        Observer.Expect('upper_current', 'Yes|Yes|Yes|No|No|No|No|?company=CRONUS%20INTERNATIONAL%20LTD.');
        Observer.Expect('ampersand', 'Yes|Yes|Yes|No|No|No|No|?company=A%26B');
        Observer.Expect('space_slash', 'Yes|Yes|Yes|No|No|No|No|?company=A%20B%2FC');
        Observer.Expect('percent', 'Yes|Yes|Yes|No|No|No|No|?company=100%25');
        Observer.Expect('unicode', 'Yes|Yes|Yes|No|No|No|No|?company=Geschaeft%20%C3%9C%E2%82%AC');
        Observer.Expect('quote', 'Yes|Yes|Yes|No|No|No|No|?company=It%27s');
        Observer.Expect('hash_question', 'Yes|Yes|Yes|No|No|No|No|?company=A%23B%3FC');
        Observer.Expect('long', 'Yes|Yes|Yes|No|No|No|No|?company=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
        Observer.Verify();
    end;

}
