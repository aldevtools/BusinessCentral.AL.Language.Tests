// @expect AL0271 | The action 'NoSuchAction' is not found in the target 'MNC PA P3113'
// An event subscriber for OnBeforeActionEvent of a page action the page does not have (al-runner 7519: subscribers of page actions).
table 53113 "MNC PA T3113"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 53113 "MNC PA P3113"
{
    PageType = Card;
    SourceTable = "MNC PA T3113";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Existing) { ApplicationArea = All; }
        }
    }
}

codeunit 53113 "MNC PA S3113"
{
    [EventSubscriber(ObjectType::Page, Page::"MNC PA P3113", 'OnBeforeActionEvent', 'NoSuchAction', false, false)]
    local procedure BeforeNoSuchAction()
    begin
    end;
}
