/// <summary>
/// Subscribes, from the dependent app, to OnAfterValidateEvent of "Trigger Field" on a table
/// that the AL Internals Test Fixture app defines, and mutates "Target Field" through the
/// by-reference var Rec, via a nested var procedure.
/// </summary>
codeunit 67460 "ALT XApp Mut Subscriber"
{
    [EventSubscriber(ObjectType::Table, Database::"ALT XApp Mut Probe", OnAfterValidateEvent, 'Trigger Field', false, false)]
    local procedure TriggerField_OnAfterValidate(var Rec: Record "ALT XApp Mut Probe"; var xRec: Record "ALT XApp Mut Probe"; CurrFieldNo: Integer)
    begin
        UpdateTargetField(Rec, Rec."Trigger Field");
    end;

    local procedure UpdateTargetField(var ProbeRec: Record "ALT XApp Mut Probe"; SourceValue: Code[20])
    begin
        ProbeRec."Target Field" := CopyStr('MUTATED:' + SourceValue, 1, MaxStrLen(ProbeRec."Target Field"));
    end;
}
