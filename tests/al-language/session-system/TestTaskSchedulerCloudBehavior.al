// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none
// BC versions: 27.5+
//
// CLAIM: TaskScheduler.CreateTask succeeds even when called from inside a running
// test -- Cloud does not refuse it just because the caller is in a test transaction.

codeunit 60877 "Test TaskScheduler Behavior"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TaskScheduler_CreateTask_InsideTest_ReturnsNonEmptyGuid()
    var
        TaskId: Guid;
        NoTaskId: Guid;
    begin
        TaskId := TaskScheduler.CreateTask(
            Codeunit::"Test TaskScheduler Behavior", Codeunit::"Test TaskScheduler Behavior");

        Assert.AreNotEqual(
            NoTaskId, TaskId, 'TaskScheduler.CreateTask must return a real task ID, even when called from a running test');
    end;
}
