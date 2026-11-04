/// <summary>
/// Writes one marker row into "ALT Universal" and does NOT commit it, so the row is
/// left to whatever the platform does with the transaction that a guarded
/// Codeunit.Run opens around this codeunit. Companion to "ALT Run Tx Inserter"
/// (60253), which commits its own row; the difference between the two is the point.
/// </summary>
codeunit 60255 "ALT Run Tx Dirty Inserter"
{
    trigger OnRun()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 9255;
        ALTUniversal."Text Field" := 'DIRTY';
        ALTUniversal.Insert();
    end;
}
