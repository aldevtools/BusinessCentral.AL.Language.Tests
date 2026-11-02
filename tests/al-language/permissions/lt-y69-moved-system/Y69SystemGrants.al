// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permission-set-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y69PermSets.al (sets 93720-93731, extension 93732, helper 93735); LT Y19 Perm Helper (91935); Permissions Mock (131006).
// Probe (writer Y69, al-runner issue 6717 by SShadowS): named system grants `system "<name>" = X` in permission sets. What a system grant does under
//   Permissions Mock.Set: whether the set still grants its tabledata (the reporter's Basic set: system "Tools, Security, Roles" = X and tabledata
//   Customer = R), the same through an included set and an included set that grants a system object, a set with only a system grant, several
//   system objects, a lower case x (indirect execute), a wildcard `system * = X`, an excluded set, a permission set extension; and what a test can
//   observe of a system grant: GetEffectivePermission for the System object (Execute column) and the Expanded Permission rows of the role.
//   System object ids (AllObj type System): 5810 Tools, Security, Roles; 9026 Add Table Field To Page; 6110 Allow Action Export To Excel;
//   5310 Tools, Debugger; 9100 Microsoft Dynamics NAV Server; 5820 Tools, Security, DB Logins.
// Compile: the name must be one of the valid system objects (AL0443), the kind only X (AL0195), by id AL0653, the same object twice in a set AL0393
//   (must-not-compile cases 2671 - 2673); `system * = X` and a lower case x compile.
// BC versions: 27, 28, 29
codeunit 93711 "LT Y69 System Grants"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y69 Helper";
        Y19Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y69_SY_ReporterShapes()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        ObserveCustomerRead(Observer, 'LT Y69 SY Basic');
        ObserveCustomerRead(Observer, 'LT Y69 SY Outer');
        ObserveCustomerRead(Observer, 'LT Y69 SY Only');
        ObserveCustomerRead(Observer, 'LT Y69 SY Plain');
        ObserveCustomerRead(Observer, 'LT Y69 SY Mid');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y69_SY_OtherShapes()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        ObserveCustomerRead(Observer, 'LT Y69 SY Many');
        ObserveCustomerRead(Observer, 'LT Y69 SY Indirect');
        ObserveCustomerRead(Observer, 'LT Y69 SY Wild');
        ObserveCustomerRead(Observer, 'LT Y69 SY Excl');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y69_SY_ExtensionOfPlainSet()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        ObserveCustomerRead(Observer, 'LT Y69 SY Plain');
        Mock.ClearAssignments();
        Observer.Observe('plain_system_5810', EffectiveSystem('LT Y69 SY Plain', 5810));
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y69_SY_EffectiveExecute()
    var
        Observer: Codeunit "Probe Observer";
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        Observer.Observe('basic', EffectiveSystemMany('LT Y69 SY Basic'));
        Observer.Observe('outer', EffectiveSystemMany('LT Y69 SY Outer'));
        Observer.Observe('many', EffectiveSystemMany('LT Y69 SY Many'));
        Observer.Observe('only', EffectiveSystemMany('LT Y69 SY Only'));
        Observer.Observe('indirect', EffectiveSystemMany('LT Y69 SY Indirect'));
        Observer.Observe('wild', EffectiveSystemMany('LT Y69 SY Wild'));
        Observer.Observe('mid', EffectiveSystemMany('LT Y69 SY Mid'));
        Observer.Observe('excl', EffectiveSystemMany('LT Y69 SY Excl'));
        Observer.Observe('plain', EffectiveSystemMany('LT Y69 SY Plain'));
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    local procedure ObserveCustomerRead(var Observer: Codeunit "Probe Observer"; SetName: Code[20])
    var
        Customer: Record Customer;
    begin
        Mock.ClearAssignments();
        ClearLastError();
        if not TrySet(SetName) then begin
            Observer.Observe(SetName + '|set', 'failed: ' + GetLastErrorText());
            Observer.Observe(SetName + '|set_code', GetLastErrorCode());
            ClearLastError();
            exit;
        end;
        asserterror begin
            if Customer.FindFirst() then;
            Error('LT Y69 ok');
        end;
        Observer.ObserveError(SetName + '|customer_read');
        Mock.ClearAssignments();
    end;

    // Execute column of the effective permission of the system objects 5810, 9026, 6110, 5310, 9100, 5820, comma separated.
    local procedure EffectiveSystemMany(SetName: Code[20]): Text
    begin
        exit(EffectiveSystem(SetName, 5810) + ' ' + EffectiveSystem(SetName, 9026) + ' ' + EffectiveSystem(SetName, 6110) + ' ' +
            EffectiveSystem(SetName, 5310) + ' ' + EffectiveSystem(SetName, 9100) + ' ' + EffectiveSystem(SetName, 5820));
    end;

    local procedure EffectiveSystem(SetName: Code[20]; SystemId: Integer): Text
    begin
        Mock.ClearAssignments();
        ClearLastError();
        if not TrySet(SetName) then begin
            ClearLastError();
            exit('set failed');
        end;
        exit(Format(SystemId) + '=' + Y19Helper.Rights(10, SystemId));
    end;

    [TryFunction]
    local procedure TrySet(SetName: Code[20])
    begin
        Mock.Set(SetName);
    end;
}
