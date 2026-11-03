/// <summary>
/// Writes one marker row into "ALT Universal" without committing it. Used by the
/// statement-form Codeunit.Run test in "Test Write Tx Test Boundary" (60878): a
/// TransactionModel::None test body has no transaction of its own and cannot write, but the
/// transaction Codeunit.Run begins is the run codeunit's own, so a write in HERE is allowed.
/// </summary>
codeunit 60880 "ALT Run Tx None Dirty Inserter"
{
    trigger OnRun()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 9880;
        ALTUniversal."Text Field" := 'DIRTY-NONE';
        ALTUniversal.Insert();
    end;
}
