/// <summary>
/// Writes one marker row into "ALT Universal" and commits it, so the row survives
/// any rollback the caller's own transaction later performs. That makes "did this
/// codeunit run?" answerable by a plain row count, independent of rollback behaviour.
/// </summary>
codeunit 60253 "ALT Run Tx Inserter"
{
    trigger OnRun()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 9253;
        ALTUniversal."Text Field" := 'RAN';
        ALTUniversal.Insert();
        Commit();
    end;
}
