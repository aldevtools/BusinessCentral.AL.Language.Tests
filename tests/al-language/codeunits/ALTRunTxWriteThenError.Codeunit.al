/// <summary>
/// Writes one marker row into "ALT Universal", uncommitted, then raises an error. Used to
/// pin that a guarded Codeunit.Run's own failed transaction rolls its own writes back,
/// for BOTH the static and instance spellings of the call — AlRunner#2334.
/// </summary>
codeunit 60256 "ALT Run Tx Write Then Error"
{
    trigger OnRun()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 9256;
        ALTUniversal."Text Field" := 'SHOULD-NOT-SURVIVE';
        ALTUniversal.Insert();
        Error('BOOM-FROM-WRITE-THEN-ERROR');
    end;
}
