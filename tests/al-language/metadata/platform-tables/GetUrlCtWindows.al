// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73979
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: GetUrl for client type Windows with company, without, with empty company
// BC versions: 29
// Tag: P95

codeunit 73979 "LT P95 GetUrl CT Windows"
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
    local procedure Try_Windows(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::Windows, Cn);
    end;

    [TryFunction]
    local procedure Try_Windows_NoCompany(var R: Text)
    begin
        R := GetUrl(ClientType::Windows);
    end;

    [Test]
    procedure GetUrl_Windows()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if Try_Windows(CompanyName(), R) then begin
            Observer.Observe('Windows_shape', Shape(R));
            Observer.Observe('Windows_tail', Tail(R));
        end else
            Observer.Observe('Windows_err', Err());
        Clear(R);
        if Try_Windows_NoCompany(R) then begin
            Observer.Observe('Windows_nocompany_shape', Shape(R));
            Observer.Observe('Windows_nocompany_tail', Tail(R));
        end else
            Observer.Observe('Windows_nocompany_err', Err());
        Clear(R);
        if Try_Windows('', R) then
            Observer.Observe('Windows_emptycompany_shape', Shape(R) + '|' + Tail(R))
        else
            Observer.Observe('Windows_emptycompany_err', Err());
        Observer.Expect('Windows_shape', 'Yes|No|No|No|No|No|No');
        Observer.Expect('Windows_tail', 'noquery');
        Observer.Expect('Windows_nocompany_shape', 'Yes|No|No|No|No|No|No');
        Observer.Expect('Windows_nocompany_tail', 'noquery');
        Observer.Expect('Windows_emptycompany_shape', 'Yes|No|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

}
