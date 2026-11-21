// @expect AL0284 | The type of the parameter 'Rec' on the event subscriber 'S' does not match the expected type 'Record "MNC SBI Row"'.
// A table event subscriber names table 50000 by its bare id and declares Rec as a record of another table (al-runner issue 8470): the
// compiler resolves the id to table 50000 and checks the parameter against it.
table 50000 "MNC SBI Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

table 50002 "MNC SBI Other"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

codeunit 50001 "MNC SBI Sub"
{
    [EventSubscriber(ObjectType::Table, 50000, 'OnAfterInsertEvent', '', false, false)]
    local procedure S(var Rec: Record "MNC SBI Other"; RunTrigger: Boolean)
    begin
    end;
}
