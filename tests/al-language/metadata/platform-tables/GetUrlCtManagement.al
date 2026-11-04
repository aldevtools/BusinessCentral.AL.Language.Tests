// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73977
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: GetUrl for client type Management with company, without, with empty company
// BC versions: 29
// Tag: P95

codeunit 73977 "LT P95 GetUrl CT Management"
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
    local procedure Try_Management(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::Management, Cn);
    end;

    [TryFunction]
    local procedure Try_Management_NoCompany(var R: Text)
    begin
        R := GetUrl(ClientType::Management);
    end;

    [Test]
    procedure GetUrl_Management()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if Try_Management(CompanyName(), R) then begin
            Observer.Observe('Management_shape', Shape(R));
            Observer.Observe('Management_tail', Tail(R));
        end else
            Observer.Observe('Management_err', Err());
        Clear(R);
        if Try_Management_NoCompany(R) then begin
            Observer.Observe('Management_nocompany_shape', Shape(R));
            Observer.Observe('Management_nocompany_tail', Tail(R));
        end else
            Observer.Observe('Management_nocompany_err', Err());
        Clear(R);
        if Try_Management('', R) then
            Observer.Observe('Management_emptycompany_shape', Shape(R) + '|' + Tail(R))
        else
            Observer.Observe('Management_emptycompany_err', Err());
        Observer.Expect('Management_shape', 'No|No|No|No|No|No|No');
        Observer.Expect('Management_tail', 'noquery');
        Observer.Expect('Management_nocompany_shape', 'No|No|No|No|No|No|No');
        Observer.Expect('Management_nocompany_tail', 'noquery');
        Observer.Expect('Management_emptycompany_shape', 'No|No|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

}
