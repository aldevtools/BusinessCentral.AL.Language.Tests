// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/events/devenv-sub-events
// Scope: in-scope
// Fixtures used: TestPage SubErr Row (60823)
//
// The refusal, raised where Microsoft's own one is raised: in a subscriber to the table's
// OnBeforeDeleteEvent, NOT in the page control's OnValidate body. Nothing on page 60825 knows
// this codeunit exists; the only thing connecting it to the control write is the platform's
// table-event dispatch under Delete(true).
codeunit 60824 "TP SubErr Guard"
{
    var
        GuardedRowErr: Label 'TestPage SubErr row %1 is guarded and cannot be deleted', Comment = '%1 = the row No.';

    [EventSubscriber(ObjectType::Table, Database::"TestPage SubErr Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure RefuseGuardedRow(var Rec: Record "TestPage SubErr Row"; RunTrigger: Boolean)
    begin
        if not RunTrigger then
            exit;
        if Rec.Guarded then
            Error(GuardedRowErr, Rec."No.");
    end;

    // The expected text, so the tests assert against the label this codeunit actually raises
    // rather than a second copy of it that could drift out of step.
    procedure ExpectedMessage(No: Code[20]): Text
    begin
        exit(StrSubstNo(GuardedRowErr, No));
    end;
}
