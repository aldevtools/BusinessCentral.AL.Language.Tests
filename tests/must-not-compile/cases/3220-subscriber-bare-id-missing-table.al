// @expect AL0185 | Table '50099' is missing
// A table event subscriber names its table by a bare id that no table has (al-runner issue 8470).
table 50000 "MNC SBI Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

codeunit 50001 "MNC SBI Sub"
{
    [EventSubscriber(ObjectType::Table, 50099, 'OnAfterInsertEvent', '', false, false)]
    local procedure S(var Rec: Record "MNC SBI Row"; RunTrigger: Boolean)
    begin
    end;
}
