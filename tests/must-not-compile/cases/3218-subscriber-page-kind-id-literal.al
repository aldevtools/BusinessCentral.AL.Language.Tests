// @expect AL0104 | Syntax error, ',' expected
// A page event subscriber names its page as Page::<id> (al-runner issue 8470). The bare id (ObjectType::Page, 50001) compiles and runs:
// tests/al-language/events/subscriber-by-id/SbiSubscriberByIdTests.al.
table 50000 "MNC SBI Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

page 50001 "MNC SBI Card"
{
    PageType = Card;
    SourceTable = "MNC SBI Row";
}

codeunit 50002 "MNC SBI Sub"
{
    [EventSubscriber(ObjectType::Page, Page::50001, 'OnOpenPageEvent', '', false, false)]
    local procedure S(var Rec: Record "MNC SBI Row")
    begin
    end;
}
