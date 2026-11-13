// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
codeunit 51743 "Probe Shadow Subscriber"
{
    EventSubscriberInstance = Manual;

    procedure Initialize(var Shadow: Record "Probe Shadow" temporary)
    begin
        Rows.Copy(Shadow, true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnInsert(var Rec: Record "Probe Line"; RunTrigger: Boolean)
    begin
        Rows.Init();
        Rows.LineNo := Rec.LineNo;
        Rows.Insert();
    end;

    var
        Rows: Record "Probe Shadow" temporary;
}
