// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getdocumenturl-method
// Scope: in-scope (OnPrem app only: System.GetDocumentUrl)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61233
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: none
//
// GetDocumentUrl with a random and an empty Guid; nothing is stored, only outcome and error text.
// BC versions: 29 (27 and 28 by CI)
codeunit 61233 "LT P109 GetDocumentUrl"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryUrl(Id: Guid; var Url: Text)
    begin
        Url := GetDocumentUrl(Id);
    end;

    local procedure Outcome(Id: Guid): Text
    var
        Url: Text;
    begin
        if TryUrl(Id, Url) then
            exit('ok len>0=' + Format(StrLen(Url) > 0));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_GetDocumentUrl_Unknown()
    var
        Observer: Codeunit "Probe Observer";
        Url: Text;
    begin
        Observer.Observe('random_guid', Outcome(CreateGuid()));
        Observer.Observe('null_guid', Outcome('{00000000-0000-0000-0000-000000000000}'));
        asserterror Url := GetDocumentUrl(CreateGuid());
        Observer.ObserveError('asserterror_random');
        asserterror Url := GetDocumentUrl('{00000000-0000-0000-0000-000000000000}');
        Observer.ObserveError('asserterror_null');
        Observer.Expect('random_guid', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavMediaNotFoundException'' was thrown.|MediaNotFound');
        Observer.Expect('null_guid', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavMediaNotFoundException'' was thrown.|MediaNotFound');
        Observer.Expect('asserterror_random|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavMediaNotFoundException'' was thrown.');
        Observer.Expect('asserterror_random|code', 'MediaNotFound');
        Observer.Expect('asserterror_null|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavMediaNotFoundException'' was thrown.');
        Observer.Expect('asserterror_null|code', 'MediaNotFound');
        Observer.Verify();
    end;
}
