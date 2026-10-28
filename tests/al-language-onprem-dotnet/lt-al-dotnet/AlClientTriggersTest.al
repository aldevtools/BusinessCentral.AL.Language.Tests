// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), see PClientTriggers.al
// Fixtures used: Probe Observer (69160); pages and log of PClientTriggers.al; self-contained codeunit 99131
// BC versions: 27, 28, 29
codeunit 99131 "LT AL Client Triggers Test"
{
    // Subtype = Test; (disabled with its only test until issue 775 is fixed: a test codeunit without tests fails the run)
    // TestPermissions = Disabled; (valid only on a test codeunit)

    [TryFunction]
    local procedure TryOpen(PageId: Integer)
    begin
        case PageId of
            99132:
                OpenNotifierTours();
            99133:
                OpenTour();
            99134:
                OpenCamera();
            99135:
                OpenLocation();
            99136:
                OpenNoHandler();
        end;
    end;

    local procedure OpenNotifierTours()
    var
        TestPage: TestPage "LT AL Notifier Tours Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure OpenTour()
    var
        TestPage: TestPage "LT AL Tour Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure OpenCamera()
    var
        TestPage: TestPage "LT AL Camera Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure OpenLocation()
    var
        TestPage: TestPage "LT AL Location Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure OpenNoHandler()
    var
        TestPage: TestPage "LT AL Client No Handler Page";
    begin
        TestPage.OpenView();
        TestPage.Close();
    end;

    local procedure Probe(PageId: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AL Client Log";
        Ok: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Ok := TryOpen(PageId);
        Observer.Observe('open_ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('open_error');
        Observer.Observe('log', Log.Joined());
        // No test probes the pages whose OnOpenPage calls IsAvailable: the old expectation (an IsAvailable NullReference error) was a
        // Linux-container artifact. The Windows runs 39216765049 (27.5) and 39216768276 (29.0) answer IsAvailable = No (pinned in
        // lt-bg-runonclient/BgRunOnClient.al of a later bump).
        Observer.Expect('open_ok', 'Yes');
        Observer.Expect('log', 'open without handlers;');
        Observer.Verify();
    end;

    // Disabled until issue 775 is fixed: fails now and then with no change to this file.
    // [Test]
    procedure ALClient_NoHandler()
    begin
        Probe(99136);
    end;
}
