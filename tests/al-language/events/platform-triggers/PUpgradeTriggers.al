// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-upgrade-codeunits
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunits 67280-67283
// The triggers of a codeunit with Subtype = Upgrade (OnCheckPreconditionsPerCompany, OnCheckPreconditionsPerDatabase, OnUpgradePerCompany, OnUpgradePerDatabase, OnValidateUpgradePerCompany, OnValidateUpgradePerDatabase):
// what a test sees when it runs the codeunit with Codeunit.Run (an upgrade that really runs happens only at app upgrade, not in a test), and an upgrade codeunit without any of them.
// The fixtures write nothing to the database: an upgrade that runs while the app is published has no effect.
// BC versions: 27, 28, 29
codeunit 67280 "LT P Trig Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Joined(): Text
    var
        E: Text;
        R: Text;
    begin
        foreach E in Entries do
            R += E + ';';
        exit(R);
    end;
}

codeunit 67281 "LT P Upgrade Full"
{
    Subtype = Upgrade;

    trigger OnRun()
    var
        Log: Codeunit "LT P Trig Log";
    begin
        Log.Add('OnRun');
    end;

    trigger OnCheckPreconditionsPerCompany()
    var
        Log: Codeunit "LT P Trig Log";
    begin
        Log.Add('CheckPerCompany');
    end;

    trigger OnCheckPreconditionsPerDatabase()
    var
        Log: Codeunit "LT P Trig Log";
    begin
        Log.Add('CheckPerDatabase');
    end;

    trigger OnUpgradePerCompany()
    var
        Log: Codeunit "LT P Trig Log";
    begin
        Log.Add('UpgradePerCompany');
    end;

    trigger OnUpgradePerDatabase()
    var
        Log: Codeunit "LT P Trig Log";
    begin
        Log.Add('UpgradePerDatabase');
    end;

    trigger OnValidateUpgradePerCompany()
    var
        Log: Codeunit "LT P Trig Log";
    begin
        Log.Add('ValidatePerCompany');
    end;

    trigger OnValidateUpgradePerDatabase()
    var
        Log: Codeunit "LT P Trig Log";
    begin
        Log.Add('ValidatePerDatabase');
    end;
}

codeunit 67282 "LT P Upgrade Empty"
{
    Subtype = Upgrade;
}

codeunit 67283 "LT P Upgrade Triggers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRun(CodeunitId: Integer)
    begin
        Codeunit.Run(CodeunitId);
    end;

    local procedure RunAndObserve(var Observer: Codeunit "Probe Observer"; CodeunitId: Integer)
    var
        Log: Codeunit "LT P Trig Log";
        Ok: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Ok := TryRun(CodeunitId);
        Observer.Observe('run_ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run_error');
        Observer.Observe('log', Log.Joined());
    end;

    [Test]
    procedure PUpgrade_RunWithTriggers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAndObserve(Observer, Codeunit::"LT P Upgrade Full");
        Observer.Expect('run_ok', 'No');
        Observer.Expect('run_error|text', 'Upgrade codeunit ''67281'' cannot be invoked outside the schema synchronization process.');
        Observer.Expect('run_error|code', 'UpgradeCodeunitOnRunCall');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure PUpgrade_RunWithoutTriggers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunAndObserve(Observer, Codeunit::"LT P Upgrade Empty");
        Observer.Expect('run_ok', 'No');
        Observer.Expect('run_error|text', 'Upgrade codeunit ''67282'' cannot be invoked outside the schema synchronization process.');
        Observer.Expect('run_error|code', 'UpgradeCodeunitOnRunCall');
        Observer.Expect('log', '');
        Observer.Verify();
    end;
}
