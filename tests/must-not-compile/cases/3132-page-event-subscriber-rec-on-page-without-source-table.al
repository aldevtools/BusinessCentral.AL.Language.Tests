// @expect AL0441 | Parameter Rec is only available when the page specifies a 'SourceTable'.
// @expect AL0441 | Parameter Rec is only available when the page specifies a 'SourceTable'.
// @expect AL0441 | Parameter Rec is only available when the page specifies a 'SourceTable'.
// @expect AL0441 | Parameter Rec is only available when the page specifies a 'SourceTable'.
// @expect AL0441 | Parameter Rec is only available when the page specifies a 'SourceTable'.
// @expect AL0441 | Parameter Rec is only available when the page specifies a 'SourceTable'.
// @expect AL0441 | Parameter xRec is only available when the page specifies a 'SourceTable'.
// @expect AL0441 | Parameter Rec is only available when the page specifies a 'SourceTable'.
// @expect AL0441 | Parameter xRec is only available when the page specifies a 'SourceTable'.
// @expect AL0441 | Parameter Rec is only available when the page specifies a 'SourceTable'.
// @expect AL0441 | Parameter xRec is only available when the page specifies a 'SourceTable'.
// @expect AL0441 | Parameter Rec is only available when the page specifies a 'SourceTable'.
// Subscribers of the page trigger events of a page WITHOUT a SourceTable that declare Rec or xRec (al-runner issue 7430). The events exist,
// but the page has no record, so every Rec and xRec parameter is refused (one diagnostic per parameter). The same subscribers without
// Rec and xRec compile: tests/al-language/events/page-events/NoSourcePageFixtures.al.
page 50001 "MNC PNS Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
}

table 50002 "MNC PNS Row"
{
    fields { field(1; Id; Integer) { } }
}

codeunit 50003 "MNC PNS Subs"
{
    [EventSubscriber(ObjectType::Page, Page::"MNC PNS Card", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpen(var Rec: Record "MNC PNS Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"MNC PNS Card", 'OnClosePageEvent', '', false, false)]
    local procedure OnClose(var Rec: Record "MNC PNS Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"MNC PNS Card", 'OnQueryClosePageEvent', '', false, false)]
    local procedure OnQueryClose(var Rec: Record "MNC PNS Row"; var AllowClose: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"MNC PNS Card", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure OnAfterGetRecord(var Rec: Record "MNC PNS Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"MNC PNS Card", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecord(var Rec: Record "MNC PNS Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"MNC PNS Card", 'OnNewRecordEvent', '', false, false)]
    local procedure OnNew(var Rec: Record "MNC PNS Row"; BelowxRec: Boolean; var xRec: Record "MNC PNS Row")
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"MNC PNS Card", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsert(var Rec: Record "MNC PNS Row"; BelowxRec: Boolean; var xRec: Record "MNC PNS Row"; var AllowInsert: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"MNC PNS Card", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModify(var Rec: Record "MNC PNS Row"; var xRec: Record "MNC PNS Row"; var AllowModify: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"MNC PNS Card", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDelete(var Rec: Record "MNC PNS Row"; var AllowDelete: Boolean)
    begin
    end;
}
