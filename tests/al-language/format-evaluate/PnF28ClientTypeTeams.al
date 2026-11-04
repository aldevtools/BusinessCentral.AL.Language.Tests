// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/clienttype-option
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73928
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "ClientType::Teams" (Media.ImportFile, MediaSet.ImportFile, RecordRef.Copy, ClientType::Teams)
// Facts: Format(ClientType::Teams, 0, 2) and Format(ClientType::Teams), and the same for the members that are known
// BC versions: 29 (27 and 28 by CI)
// Note for the lead: if ClientType::Teams does not compile on BC 29, drop the file (the failure to compile is the observation).

codeunit 73928 "LT PnF ClientType Teams"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ClientType_Teams_Format()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('teams_ordinal', Format(ClientType::Teams, 0, 2));
        Observer.Observe('teams_default', Format(ClientType::Teams));
        Observer.Observe('teams_text', Format(ClientType::Teams, 0, 0));
        Observer.Observe('teams_as_integer', Format(ClientType::Teams, 0, 2));
        Observer.Expect('teams_ordinal', '12');
        Observer.Expect('teams_default', 'Teams');
        Observer.Expect('teams_text', 'Teams');
        Observer.Expect('teams_as_integer', '12');
        Observer.Verify();
    end;

    [Test]
    procedure ClientType_Members_Ordinals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Web', Format(ClientType::Web, 0, 2));
        Observer.Observe('Phone', Format(ClientType::Phone, 0, 2));
        Observer.Observe('Tablet', Format(ClientType::Tablet, 0, 2));
        Observer.Observe('Desktop', Format(ClientType::Desktop, 0, 2));
        Observer.Observe('Background', Format(ClientType::Background, 0, 2));
        Observer.Observe('Api', Format(ClientType::Api, 0, 2));
        Observer.Observe('Management', Format(ClientType::Management, 0, 2));
        Observer.Observe('ODataV4', Format(ClientType::ODataV4, 0, 2));
        Observer.Observe('Default', Format(ClientType::Default, 0, 2));
        Observer.Expect('Web', '3');
        Observer.Expect('Phone', '10');
        Observer.Expect('Tablet', '9');
        Observer.Expect('Desktop', '11');
        Observer.Expect('Background', '7');
        Observer.Expect('Api', '14');
        Observer.Expect('Management', '8');
        Observer.Expect('ODataV4', '13');
        Observer.Expect('Default', '1');
        Observer.Verify();
    end;
}
