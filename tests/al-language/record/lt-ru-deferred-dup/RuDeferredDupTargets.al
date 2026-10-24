// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope
// Fixtures used: table "Probe Dup No Blob" (68138, record/TestRecordRuntimeTextsAndViews.al); tests in that file's codeunit 68137 (the RU_* tests)
// Objects (AL Runner issue 5788, writer RU): a codeunit whose OnRun inserts a new row (Id 2) and then, as its last statement, a duplicate of
//   the existing row Id 1 in the statement form, so the duplicate-key error is still deferred when OnRun ends.
// BC versions: 27, 28, 29

codeunit 88665 "LT RU Dup At End"
{
    trigger OnRun()
    var
        Row: Record "Probe Dup No Blob";
    begin
        Row.Id := 2;
        Row.Txt := 'new';
        Row.Insert();
        Row.Id := 1;
        Row.Txt := 'dup';
        Row.Insert();
    end;
}
