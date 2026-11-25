// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrorobject-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-runpagebackgroundtask-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (GetLastErrorObject has scope OnPrem; must-not-compile case 0110), AL compiler 18.0 or newer
// local object: what a second page background task's worker reads of GetLastErrorObject is what is under test
// Fixtures used: Assert (60021); table 97390 "LEW Host" and page 97392 "LEW Hosts" of the AL Language Coverage Tests app
//   (pages/background-tasks/BgTaskWorkerLastError.al); worker codeunit 99408 "LWO Reader" (BgTaskWorkerLastErrorObject.al);
//   codeunit 99410 (tests)
// Probe (al-runner issue 8697, next to BgTaskWorkerLastErrorObject.al): each worker starts in a session of its own.
// Cells:
//   - two tasks in a row, the first worker catches an error of its own: the second worker's GetLastErrorObject before an error
//     of its own is null (:34).
// BC versions: 29.1 (local W1 container).
codeunit 99410 "LWO Two Task Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Run(Mode: Text; var Results: Dictionary of [Text, Text])
    var
        Hosts: TestPage "LEW Hosts";
        Parameters: Dictionary of [Text, Text];
    begin
        Parameters.Add('Mode', Mode);
        Hosts.OpenView();
        Results := Hosts.RunPageBackgroundTask(Codeunit::"LWO Reader", Parameters, false);
        Hosts.Close();
    end;

    [Test]
    procedure TwoTasks_SecondWorkerAfterAFirstCaughtItsError_GetLastErrorObjectNull()
    var
        Results: Dictionary of [Text, Text];
        IsNullSeen: Text;
    begin
        Run('catch', Results);
        Run('read', Results);
        Results.Get('IsNull', IsNullSeen);
        Assert.AreEqual(Format(true), IsNullSeen, 'IsNull of the second worker''s GetLastErrorObject');
    end;
}
