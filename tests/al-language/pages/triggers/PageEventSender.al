// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-publisher-subscriber
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73750, page 73751, codeunits 73752 (manual subscriber) and 73753 (tests)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a page publishes [IntegrationEvent(true, false)]; a manual subscriber with (var Sender: Page X) calls a procedure of the sender, reads a page variable of it and changes it.
//   Raised from a procedure of a Page variable (the subscriber's change must be visible on that same variable) and from OnOpenPage of a page opened by TestPage.OpenView
//   (the change shows in a field of the opened page). The event arguments after the sender arrive as well.
// BC versions: 29 (27 and 28 by CI)

table 73750 "LT PgSender Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 73751 "LT PgSender Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PgSender Row";
    Caption = 'LT PgSender Card';

    layout
    {
        area(Content)
        {
            field("Code"; Rec.Code)
            {
                ApplicationArea = All;
            }
            field(MarkerField; Marker)
            {
                ApplicationArea = All;
                Caption = 'Marker';
            }
            field(BumpsField; Bumps)
            {
                ApplicationArea = All;
                Caption = 'Bumps';
            }
        }
    }

    var
        Marker: Text[100];
        Bumps: Integer;

    trigger OnOpenPage()
    begin
        Marker := 'opened';
        OnSomething(7, 'arg');
    end;

    procedure SetMarker(NewMarker: Text)
    begin
        Marker := CopyStr(NewMarker, 1, MaxStrLen(Marker));
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;

    procedure Bump()
    begin
        Bumps += 1;
    end;

    procedure GetBumps(): Integer
    begin
        exit(Bumps);
    end;

    procedure RaiseIt()
    begin
        OnSomething(3, 'proc');
    end;

    [IntegrationEvent(true, false)]
    local procedure OnSomething(Number: Integer; Info: Text)
    begin
    end;
}

codeunit 73752 "LT PgSender Subscriber"
{
    EventSubscriberInstance = Manual;

    var
        Calls: Integer;
        SeenMarker: Text;
        SeenNumber: Integer;
        SeenText: Text;
        SeenBumps: Integer;

    [EventSubscriber(ObjectType::Page, Page::"LT PgSender Card", 'OnSomething', '', false, false)]
    local procedure OnSomething(var Sender: Page "LT PgSender Card"; Number: Integer; Info: Text)
    begin
        Calls += 1;
        SeenMarker := Sender.GetMarker();
        SeenNumber := Number;
        SeenText := Info;
        Sender.Bump();
        Sender.Bump();
        SeenBumps := Sender.GetBumps();
        Sender.SetMarker('set by subscriber');
    end;

    procedure GetCalls(): Integer
    begin
        exit(Calls);
    end;

    procedure GetSeenMarker(): Text
    begin
        exit(SeenMarker);
    end;

    procedure GetSeenNumber(): Integer
    begin
        exit(SeenNumber);
    end;

    procedure GetSeenText(): Text
    begin
        exit(SeenText);
    end;

    procedure GetSeenBumps(): Integer
    begin
        exit(SeenBumps);
    end;
}

codeunit 73753 "LT PgSender Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PageEvent_FromPageVariable_SenderIsTheVariable()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT PgSender Subscriber";
        Pg: Page "LT PgSender Card";
    begin
        BindSubscription(Sub);
        Pg.SetMarker('before');
        Pg.RaiseIt();
        Observer.Observe('calls', Format(Sub.GetCalls()));
        Observer.Observe('seenMarker', Sub.GetSeenMarker());
        Observer.Observe('seenNumber', Format(Sub.GetSeenNumber()));
        Observer.Observe('seenText', Sub.GetSeenText());
        Observer.Observe('seenBumps', Format(Sub.GetSeenBumps()));
        Observer.Observe('markerAfter', Pg.GetMarker());
        Observer.Observe('bumpsAfter', Format(Pg.GetBumps()));
        UnbindSubscription(Sub);
        Observer.Expect('calls', '1');
        Observer.Expect('seenMarker', 'before');
        Observer.Expect('seenNumber', '3');
        Observer.Expect('seenText', 'proc');
        Observer.Expect('seenBumps', '2');
        Observer.Expect('markerAfter', 'set by subscriber');
        Observer.Expect('bumpsAfter', '2');
        Observer.Verify();
    end;

    [Test]
    procedure PageEvent_RaisedTwice_SenderKeepsState()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT PgSender Subscriber";
        Pg: Page "LT PgSender Card";
    begin
        BindSubscription(Sub);
        Pg.RaiseIt();
        Pg.RaiseIt();
        Observer.Observe('calls', Format(Sub.GetCalls()));
        Observer.Observe('seenMarkerSecond', Sub.GetSeenMarker());
        Observer.Observe('seenBumpsSecond', Format(Sub.GetSeenBumps()));
        Observer.Observe('bumpsAfter', Format(Pg.GetBumps()));
        UnbindSubscription(Sub);
        Observer.Expect('calls', '2');
        Observer.Expect('seenMarkerSecond', 'set by subscriber');
        Observer.Expect('seenBumpsSecond', '4');
        Observer.Expect('bumpsAfter', '4');
        Observer.Verify();
    end;

    [Test]
    procedure PageEvent_TwoPageVariables_SeparateSenders()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT PgSender Subscriber";
        PgA: Page "LT PgSender Card";
        PgB: Page "LT PgSender Card";
    begin
        BindSubscription(Sub);
        PgA.SetMarker('a');
        PgB.SetMarker('b');
        PgA.RaiseIt();
        Observer.Observe('markerA', PgA.GetMarker());
        Observer.Observe('markerB', PgB.GetMarker());
        Observer.Observe('bumpsA', Format(PgA.GetBumps()));
        Observer.Observe('bumpsB', Format(PgB.GetBumps()));
        PgB.RaiseIt();
        Observer.Observe('seenMarkerB', Sub.GetSeenMarker());
        Observer.Observe('bumpsB2', Format(PgB.GetBumps()));
        Observer.Observe('bumpsA2', Format(PgA.GetBumps()));
        UnbindSubscription(Sub);
        Observer.Expect('markerA', 'set by subscriber');
        Observer.Expect('markerB', 'b');
        Observer.Expect('bumpsA', '2');
        Observer.Expect('bumpsB', '0');
        Observer.Expect('seenMarkerB', 'b');
        Observer.Expect('bumpsB2', '2');
        Observer.Expect('bumpsA2', '2');
        Observer.Verify();
    end;

    [Test]
    procedure PageEvent_FromOpenPage_SenderIsTheOpenedPage()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT PgSender Subscriber";
        Row: Record "LT PgSender Row";
        Card: TestPage "LT PgSender Card";
    begin
        Row.DeleteAll();
        Row.Code := 'R1';
        Row.Insert();
        BindSubscription(Sub);
        Card.OpenView();
        Observer.Observe('calls', Format(Sub.GetCalls()));
        Observer.Observe('seenMarker', Sub.GetSeenMarker());
        Observer.Observe('seenNumber', Format(Sub.GetSeenNumber()));
        Observer.Observe('seenText', Sub.GetSeenText());
        Observer.Observe('seenBumps', Format(Sub.GetSeenBumps()));
        Observer.Observe('pageMarker', Format(Card.MarkerField.Value));
        Observer.Observe('pageBumps', Format(Card.BumpsField.Value));
        Card.Close();
        UnbindSubscription(Sub);
        Observer.Expect('calls', '1');
        Observer.Expect('seenMarker', 'opened');
        Observer.Expect('seenNumber', '7');
        Observer.Expect('seenText', 'arg');
        Observer.Expect('seenBumps', '2');
        Observer.Expect('pageMarker', 'set by subscriber');
        Observer.Expect('pageBumps', '2');
        Observer.Verify();
    end;

    [Test]
    procedure PageEvent_NotBound_NoCall()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Codeunit "LT PgSender Subscriber";
        Pg: Page "LT PgSender Card";
    begin
        Pg.SetMarker('untouched');
        Pg.RaiseIt();
        Observer.Observe('calls', Format(Sub.GetCalls()));
        Observer.Observe('marker', Pg.GetMarker());
        Observer.Observe('bumps', Format(Pg.GetBumps()));
        Observer.Expect('calls', '0');
        Observer.Expect('marker', 'untouched');
        Observer.Expect('bumps', '0');
        Observer.Verify();
    end;
}
