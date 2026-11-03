/// <summary>
/// Writes one marker row into "ALT Universal" and commits it, so "did this codeunit run?"
/// is answerable by a plain row count. Same shape as "ALT Run Tx Inserter" (60253) with its
/// own marker number, because 60253's marker is already committed by the time the
/// TransactionModel::None tests in "Test Write Tx Test Boundary" (60878) run — re-running it
/// would fail on a duplicate key and read as "the platform refused the call".
/// </summary>
codeunit 60879 "ALT Run Tx None Inserter"
{
    trigger OnRun()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 9879;
        ALTUniversal."Text Field" := 'RAN-NONE';
        ALTUniversal.Insert();
        Commit();
    end;
}
