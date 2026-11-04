// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-commit-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000)
//
// Worker for "Test Codeunit Run Guard" (60217). Writes one row, COMMITS it, writes a second
// row, then errors -- so a caller can tell the two halves of the rollback boundary apart in a
// single guarded run: 93771 is committed before the error and 93772 is not.
//
// Keys are deliberately high and unshared. The Commit() below makes 93771 durable against the
// guarded run's own rollback, so it survives into the session until a later
// ALTFixtureCleanup.Initialize() deletes it -- every [Test] in 60217 calls one first, and
// GuardedRun_StaticForm_CommitThenError_ClearsTheCommittedRow closes the suite by deleting
// both keys and committing that delete.
codeunit 60257 "ALT Run Tx Commit Then Error"
{
    trigger OnRun()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 93771;
        ALTUniversal."Text Field" := 'COMMITTED-BEFORE-ERROR';
        ALTUniversal.Insert();

        Commit();

        ALTUniversal.Init();
        ALTUniversal."Entry No." := 93772;
        ALTUniversal."Text Field" := 'WRITTEN-AFTER-COMMIT';
        ALTUniversal.Insert();

        Error('BOOM-AFTER-COMMIT');
    end;
}
