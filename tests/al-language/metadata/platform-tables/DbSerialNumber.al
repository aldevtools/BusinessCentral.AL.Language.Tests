// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74031
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: Database.SerialNumber: stable, length relations, or the error
// BC versions: 29
// Tag: P95

codeunit 74031 "LT P95 Db SerialNumber"
{
    Subtype = Test;
    TestPermissions = Disabled;


    local procedure Err(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TrySn(var S: Text)
    begin
        S := Database.SerialNumber();
    end;

    [Test]
    procedure DbSerialNumber()
    var
        Observer: Codeunit "Probe Observer";
        S1: Text;
    begin
        if TrySn(S1) then begin
            Observer.Observe('twice_equal', Format(Database.SerialNumber() = S1));
            Observer.Observe('is_blank', Format(S1 = ''));
            Observer.Observe('length_le_250', Format(StrLen(S1) <= 250));
        end else
            Observer.Observe('serialnumber', Err());

        Observer.Expect('twice_equal', 'Yes');
        Observer.Expect('is_blank', 'No');
        Observer.Expect('length_le_250', 'Yes');
        Observer.Verify();
    end;

}
