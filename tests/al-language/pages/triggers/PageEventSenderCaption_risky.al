// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-publisher-subscriber
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained page 73754, codeunits 73755 (manual subscriber) and 73756 (tests)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): Page.Caption on the Sender variable (a Page variable member) and Sender.Editable / Sender.ObjectId.
// Facts: the subscriber reads the Caption of the sender; the event is raised from a Page variable procedure
// BC versions: 29 (27 and 28 by CI)

page 73754 "LT PgSenderCap Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT PgSenderCap Caption';

    layout
    {
        area(Content)
        {
            field(Dummy; DummyText)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        DummyText: Text;

    procedure RaiseIt()
    begin
        OnCaptionEvent();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCaptionEvent()
    begin
    end;
}

codeunit 73755 "LT PgSenderCap Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        SeenCaption: Text;
        SeenEditable: Boolean;

    [EventSubscriber(ObjectType::Page, Page::"LT PgSenderCap Card", 'OnCaptionEvent', '', false, false)]
    local procedure OnCaptionEvent(var Sender: Page "LT PgSenderCap Card")
    begin
        SeenCaption := Sender.Caption();
        SeenEditable := Sender.Editable();
    end;

    procedure GetSeenCaption(): Text
    begin
        exit(SeenCaption);
    end;

    procedure GetSeenEditable(): Boolean
    begin
        exit(SeenEditable);
    end;
}

codeunit 73756 "LT PgSenderCap Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PageEventCaption_FromPageVariable()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT PgSenderCap Subscriber";
        Pg: Page "LT PgSenderCap Card";
    begin
        BindSubscription(Sub);
        Pg.RaiseIt();
        Observer.Observe('seenCaption', Sub.GetSeenCaption());
        Observer.Observe('seenEditable', Format(Sub.GetSeenEditable()));
        Observer.Observe('pgCaption', Pg.Caption());
        UnbindSubscription(Sub);
        Observer.Expect('seenCaption', 'LT PgSenderCap Caption');
        Observer.Expect('seenEditable', 'Yes');
        Observer.Expect('pgCaption', 'LT PgSenderCap Caption');
        Observer.Verify();
    end;
}
