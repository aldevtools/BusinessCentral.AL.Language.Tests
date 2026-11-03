// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73975
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: GetUrl for client type SOAP, OData, ODataV4, Api with company, without, with empty company
// BC versions: 29
// Tag: P95

codeunit 73975 "LT P95 GetUrl CT Service"
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
    local procedure Try_SOAP(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::SOAP, Cn);
    end;

    [TryFunction]
    local procedure Try_SOAP_NoCompany(var R: Text)
    begin
        R := GetUrl(ClientType::SOAP);
    end;

    [Test]
    procedure GetUrl_SOAP()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if Try_SOAP(CompanyName(), R) then begin
            Observer.Observe('SOAP_shape', Shape(R));
            Observer.Observe('SOAP_tail', Tail(R));
        end else
            Observer.Observe('SOAP_err', Err());
        Clear(R);
        if Try_SOAP_NoCompany(R) then begin
            Observer.Observe('SOAP_nocompany_shape', Shape(R));
            Observer.Observe('SOAP_nocompany_tail', Tail(R));
        end else
            Observer.Observe('SOAP_nocompany_err', Err());
        Clear(R);
        if Try_SOAP('', R) then
            Observer.Observe('SOAP_emptycompany_shape', Shape(R) + '|' + Tail(R))
        else
            Observer.Observe('SOAP_emptycompany_err', Err());
        Observer.Expect('SOAP_shape', 'Yes|Yes|No|No|No|No|No');
        Observer.Expect('SOAP_tail', 'noquery');
        Observer.Expect('SOAP_nocompany_shape', 'Yes|Yes|No|No|No|No|No');
        Observer.Expect('SOAP_nocompany_tail', 'noquery');
        Observer.Expect('SOAP_emptycompany_shape', 'Yes|Yes|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Try_OData(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::OData, Cn);
    end;

    [TryFunction]
    local procedure Try_OData_NoCompany(var R: Text)
    begin
        R := GetUrl(ClientType::OData);
    end;

    [Test]
    procedure GetUrl_OData()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if Try_OData(CompanyName(), R) then begin
            Observer.Observe('OData_shape', Shape(R));
            Observer.Observe('OData_tail', Tail(R));
        end else
            Observer.Observe('OData_err', Err());
        Clear(R);
        if Try_OData_NoCompany(R) then begin
            Observer.Observe('OData_nocompany_shape', Shape(R));
            Observer.Observe('OData_nocompany_tail', Tail(R));
        end else
            Observer.Observe('OData_nocompany_err', Err());
        Clear(R);
        if Try_OData('', R) then
            Observer.Observe('OData_emptycompany_shape', Shape(R) + '|' + Tail(R))
        else
            Observer.Observe('OData_emptycompany_err', Err());
        Observer.Expect('OData_shape', 'Yes|Yes|No|No|No|No|No');
        Observer.Expect('OData_tail', 'noquery');
        Observer.Expect('OData_nocompany_shape', 'Yes|Yes|No|No|No|No|No');
        Observer.Expect('OData_nocompany_tail', 'noquery');
        Observer.Expect('OData_emptycompany_shape', 'Yes|Yes|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Try_ODataV4(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::ODataV4, Cn);
    end;

    [TryFunction]
    local procedure Try_ODataV4_NoCompany(var R: Text)
    begin
        R := GetUrl(ClientType::ODataV4);
    end;

    [Test]
    procedure GetUrl_ODataV4()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if Try_ODataV4(CompanyName(), R) then begin
            Observer.Observe('ODataV4_shape', Shape(R));
            Observer.Observe('ODataV4_tail', Tail(R));
        end else
            Observer.Observe('ODataV4_err', Err());
        Clear(R);
        if Try_ODataV4_NoCompany(R) then begin
            Observer.Observe('ODataV4_nocompany_shape', Shape(R));
            Observer.Observe('ODataV4_nocompany_tail', Tail(R));
        end else
            Observer.Observe('ODataV4_nocompany_err', Err());
        Clear(R);
        if Try_ODataV4('', R) then
            Observer.Observe('ODataV4_emptycompany_shape', Shape(R) + '|' + Tail(R))
        else
            Observer.Observe('ODataV4_emptycompany_err', Err());
        Observer.Expect('ODataV4_shape', 'Yes|Yes|No|No|No|No|No');
        Observer.Expect('ODataV4_tail', 'noquery');
        Observer.Expect('ODataV4_nocompany_shape', 'Yes|Yes|No|No|No|No|No');
        Observer.Expect('ODataV4_nocompany_tail', 'noquery');
        Observer.Expect('ODataV4_emptycompany_shape', 'Yes|Yes|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Try_Api(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::Api, Cn);
    end;

    [TryFunction]
    local procedure Try_Api_NoCompany(var R: Text)
    begin
        R := GetUrl(ClientType::Api);
    end;

    [Test]
    procedure GetUrl_Api()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if Try_Api(CompanyName(), R) then begin
            Observer.Observe('Api_shape', Shape(R));
            Observer.Observe('Api_tail', Tail(R));
        end else
            Observer.Observe('Api_err', Err());
        Clear(R);
        if Try_Api_NoCompany(R) then begin
            Observer.Observe('Api_nocompany_shape', Shape(R));
            Observer.Observe('Api_nocompany_tail', Tail(R));
        end else
            Observer.Observe('Api_nocompany_err', Err());
        Clear(R);
        if Try_Api('', R) then
            Observer.Observe('Api_emptycompany_shape', Shape(R) + '|' + Tail(R))
        else
            Observer.Observe('Api_emptycompany_err', Err());
        Observer.Expect('Api_shape', 'Yes|Yes|No|No|No|No|No');
        Observer.Expect('Api_tail', 'noquery');
        Observer.Expect('Api_nocompany_shape', 'Yes|Yes|No|No|No|No|No');
        Observer.Expect('Api_nocompany_tail', 'noquery');
        Observer.Expect('Api_emptycompany_shape', 'Yes|Yes|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

}
