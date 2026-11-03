// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-geturl-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73974
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: GetUrl for client type Web, Phone, Tablet, Desktop, Default with company, without, with empty company
// BC versions: 29
// Tag: P95

codeunit 73974 "LT P95 GetUrl CT Main"
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
    local procedure Try_Web(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::Web, Cn);
    end;

    [TryFunction]
    local procedure Try_Web_NoCompany(var R: Text)
    begin
        R := GetUrl(ClientType::Web);
    end;

    [Test]
    procedure GetUrl_Web()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if Try_Web(CompanyName(), R) then begin
            Observer.Observe('Web_shape', Shape(R));
            Observer.Observe('Web_tail', Tail(R));
        end else
            Observer.Observe('Web_err', Err());
        Clear(R);
        if Try_Web_NoCompany(R) then begin
            Observer.Observe('Web_nocompany_shape', Shape(R));
            Observer.Observe('Web_nocompany_tail', Tail(R));
        end else
            Observer.Observe('Web_nocompany_err', Err());
        Clear(R);
        if Try_Web('', R) then
            Observer.Observe('Web_emptycompany_shape', Shape(R) + '|' + Tail(R))
        else
            Observer.Observe('Web_emptycompany_err', Err());
        Observer.Expect('Web_shape', 'Yes|Yes|Yes|No|No|No|No');
        Observer.Expect('Web_tail', '?company=<Company>');
        Observer.Expect('Web_nocompany_shape', 'Yes|Yes|No|No|No|No|No');
        Observer.Expect('Web_nocompany_tail', 'noquery');
        Observer.Expect('Web_emptycompany_shape', 'Yes|Yes|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Try_Phone(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::Phone, Cn);
    end;

    [TryFunction]
    local procedure Try_Phone_NoCompany(var R: Text)
    begin
        R := GetUrl(ClientType::Phone);
    end;

    [Test]
    procedure GetUrl_Phone()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if Try_Phone(CompanyName(), R) then begin
            Observer.Observe('Phone_shape', Shape(R));
            Observer.Observe('Phone_tail', Tail(R));
        end else
            Observer.Observe('Phone_err', Err());
        Clear(R);
        if Try_Phone_NoCompany(R) then begin
            Observer.Observe('Phone_nocompany_shape', Shape(R));
            Observer.Observe('Phone_nocompany_tail', Tail(R));
        end else
            Observer.Observe('Phone_nocompany_err', Err());
        Clear(R);
        if Try_Phone('', R) then
            Observer.Observe('Phone_emptycompany_shape', Shape(R) + '|' + Tail(R))
        else
            Observer.Observe('Phone_emptycompany_err', Err());
        Observer.Expect('Phone_shape', 'Yes|No|Yes|No|No|No|No');
        Observer.Expect('Phone_tail', '?company=<Company>');
        Observer.Expect('Phone_nocompany_shape', 'Yes|No|No|No|No|No|No');
        Observer.Expect('Phone_nocompany_tail', 'noquery');
        Observer.Expect('Phone_emptycompany_shape', 'Yes|No|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Try_Tablet(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::Tablet, Cn);
    end;

    [TryFunction]
    local procedure Try_Tablet_NoCompany(var R: Text)
    begin
        R := GetUrl(ClientType::Tablet);
    end;

    [Test]
    procedure GetUrl_Tablet()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if Try_Tablet(CompanyName(), R) then begin
            Observer.Observe('Tablet_shape', Shape(R));
            Observer.Observe('Tablet_tail', Tail(R));
        end else
            Observer.Observe('Tablet_err', Err());
        Clear(R);
        if Try_Tablet_NoCompany(R) then begin
            Observer.Observe('Tablet_nocompany_shape', Shape(R));
            Observer.Observe('Tablet_nocompany_tail', Tail(R));
        end else
            Observer.Observe('Tablet_nocompany_err', Err());
        Clear(R);
        if Try_Tablet('', R) then
            Observer.Observe('Tablet_emptycompany_shape', Shape(R) + '|' + Tail(R))
        else
            Observer.Observe('Tablet_emptycompany_err', Err());
        Observer.Expect('Tablet_shape', 'Yes|No|Yes|No|No|No|No');
        Observer.Expect('Tablet_tail', '?company=<Company>');
        Observer.Expect('Tablet_nocompany_shape', 'Yes|No|No|No|No|No|No');
        Observer.Expect('Tablet_nocompany_tail', 'noquery');
        Observer.Expect('Tablet_emptycompany_shape', 'Yes|No|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Try_Desktop(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::Desktop, Cn);
    end;

    [TryFunction]
    local procedure Try_Desktop_NoCompany(var R: Text)
    begin
        R := GetUrl(ClientType::Desktop);
    end;

    [Test]
    procedure GetUrl_Desktop()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if Try_Desktop(CompanyName(), R) then begin
            Observer.Observe('Desktop_shape', Shape(R));
            Observer.Observe('Desktop_tail', Tail(R));
        end else
            Observer.Observe('Desktop_err', Err());
        Clear(R);
        if Try_Desktop_NoCompany(R) then begin
            Observer.Observe('Desktop_nocompany_shape', Shape(R));
            Observer.Observe('Desktop_nocompany_tail', Tail(R));
        end else
            Observer.Observe('Desktop_nocompany_err', Err());
        Clear(R);
        if Try_Desktop('', R) then
            Observer.Observe('Desktop_emptycompany_shape', Shape(R) + '|' + Tail(R))
        else
            Observer.Observe('Desktop_emptycompany_err', Err());
        Observer.Expect('Desktop_shape', 'Yes|No|Yes|No|No|No|No');
        Observer.Expect('Desktop_tail', '?company=<Company>');
        Observer.Expect('Desktop_nocompany_shape', 'Yes|No|No|No|No|No|No');
        Observer.Expect('Desktop_nocompany_tail', 'noquery');
        Observer.Expect('Desktop_emptycompany_shape', 'Yes|No|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure Try_Default(Cn: Text; var R: Text)
    begin
        R := GetUrl(ClientType::Default, Cn);
    end;

    [TryFunction]
    local procedure Try_Default_NoCompany(var R: Text)
    begin
        R := GetUrl(ClientType::Default);
    end;

    [Test]
    procedure GetUrl_Default()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if Try_Default(CompanyName(), R) then begin
            Observer.Observe('Default_shape', Shape(R));
            Observer.Observe('Default_tail', Tail(R));
        end else
            Observer.Observe('Default_err', Err());
        Clear(R);
        if Try_Default_NoCompany(R) then begin
            Observer.Observe('Default_nocompany_shape', Shape(R));
            Observer.Observe('Default_nocompany_tail', Tail(R));
        end else
            Observer.Observe('Default_nocompany_err', Err());
        Clear(R);
        if Try_Default('', R) then
            Observer.Observe('Default_emptycompany_shape', Shape(R) + '|' + Tail(R))
        else
            Observer.Observe('Default_emptycompany_err', Err());
        Observer.Expect('Default_shape', 'Yes|No|No|No|No|No|No');
        Observer.Expect('Default_tail', 'noquery');
        Observer.Expect('Default_nocompany_shape', 'Yes|No|No|No|No|No|No');
        Observer.Expect('Default_nocompany_tail', 'noquery');
        Observer.Expect('Default_emptycompany_shape', 'Yes|No|No|No|No|No|No|noquery');
        Observer.Verify();
    end;

}
