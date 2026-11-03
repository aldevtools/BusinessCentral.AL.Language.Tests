// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73978
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: GetUrl for client type NAS with company, without, with empty company
// BC versions: 29
// Tag: P95

codeunit 73978 "LT P95 GetUrl CT NAS"
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
    local procedure Try_NAS(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::NAS, Cn);
    end;

    [TryFunction]
    local procedure Try_NAS_NoCompany(var R: Text)
    begin
        R := GetUrl(ClientType::NAS);
    end;

    [Test]
    procedure GetUrl_NAS()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if Try_NAS(CompanyName(), R) then begin
            Observer.Observe('NAS_shape', Shape(R));
            Observer.Observe('NAS_tail', Tail(R));
        end else
            Observer.Observe('NAS_err', Err());
        Clear(R);
        if Try_NAS_NoCompany(R) then begin
            Observer.Observe('NAS_nocompany_shape', Shape(R));
            Observer.Observe('NAS_nocompany_tail', Tail(R));
        end else
            Observer.Observe('NAS_nocompany_err', Err());
        Clear(R);
        if Try_NAS('', R) then
            Observer.Observe('NAS_emptycompany_shape', Shape(R) + '|' + Tail(R))
        else
            Observer.Observe('NAS_emptycompany_err', Err());
        Observer.Expect('NAS_shape', 'No|No|No|No|No|No|No');
        Observer.Expect('NAS_tail', 'noquery');
        Observer.Expect('NAS_nocompany_shape', 'No|No|No|No|No|No|No');
        Observer.Expect('NAS_nocompany_tail', 'noquery');
        Observer.Expect('NAS_emptycompany_shape', 'No|No|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

}
