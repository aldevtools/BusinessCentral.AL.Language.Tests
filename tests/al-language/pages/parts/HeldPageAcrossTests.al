// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-singleinstance-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al (IncludeSender)
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 64730, part pages 64731 64734, host pages 64732 64735, holder codeunit 64733,
//   test codeunit 64736
// Probe: observe-only. Area: a page held across test methods. A SingleInstance codeunit keeps the sender of an event that page "PGA HA
//   Held" raises in OnAfterGetCurrRecord (a Page variable). A later test of the same codeunit opens another page ("PGA HA Other") whose
//   FactBox runs, in OnAfterGetCurrRecord, a procedure of the SingleInstance codeunit that calls a procedure of the held page, which calls
//   a procedure of the held page's own part (CurrPage.Fb.Page.Refresh()). The tests run in declaration order in one session, in pairs:
//   the first test of a pair opens the held page and ends it one way, the second opens the other page.
//   Ways the held page ended: TestPage.Close(), still open at the end of the test, OK of the TestPage, Page.Run with a PageHandler that
//   does nothing, Page.RunModal with a ModalPageHandler that invokes OK.
//   Already pinned: pages/parts/HeldSenderPartAccess.al (the held page closed by TestPage.Close(), reached from a FactBox event while
//   another TestPage of the same page opens). Not pinned: the other ways to end the held page, and a different page opening.
// Observed: whether the other page opens (or the error text and code), and the log (fb-refresh(<row the held part shows>), touch,
//   held-agcr, other-agcr).
// local object: the SingleInstance holder of a Page variable and the pages are what the test checks
// BC versions: 27, 28, 29

table 64730 "PGA HA Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Name; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 64731 "PGA HA Fb"
{
    PageType = CardPart;
    SourceTable = "PGA HA Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }

    procedure Refresh()
    var
        Holder: Codeunit "PGA HA Holder";
    begin
        Holder.Add('fb-refresh(' + Rec."No." + ')');
        CurrPage.Update(false);
    end;
}

page 64732 "PGA HA Held"
{
    PageType = Card;
    SourceTable = "PGA HA Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(Fb; "PGA HA Fb")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Holder: Codeunit "PGA HA Holder";
    begin
        Holder.Add('held-agcr(' + Rec."No." + ')');
        OnHeldGotRecord();
    end;

    procedure UpdateFb()
    begin
        CurrPage.Fb.Page.Refresh();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnHeldGotRecord()
    begin
    end;
}

codeunit 64733 "PGA HA Holder"
{
    SingleInstance = true;

    var
        Held: Page "PGA HA Held";
        HasHeld: Boolean;
        Entries: Text;

    [EventSubscriber(ObjectType::Page, Page::"PGA HA Held", 'OnHeldGotRecord', '', false, false)]
    local procedure KeepHeld(sender: Page "PGA HA Held")
    begin
        Held := sender;
        HasHeld := true;
    end;

    procedure TouchHeld()
    begin
        Add('touch(' + Format(HasHeld) + ')');
        if HasHeld then
            Held.UpdateFb();
    end;

    procedure Forget()
    begin
        Clear(Held);
        HasHeld := false;
        Entries := '';
    end;

    procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ' ';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        Result := '[' + Entries + ']';
        Entries := '';
    end;
}

page 64734 "PGA HA Other Fb"
{
    PageType = CardPart;
    SourceTable = "PGA HA Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Holder: Codeunit "PGA HA Holder";
    begin
        Holder.Add('other-agcr(' + Rec."No." + ')');
        Holder.TouchHeld();
    end;
}

page 64735 "PGA HA Other"
{
    PageType = Card;
    SourceTable = "PGA HA Doc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(OtherFb; "PGA HA Other Fb")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }
}

codeunit 64736 "PGA HA Held Across Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "PGA HA Holder";

    local procedure Initialize(Forget: Boolean)
    var
        Doc: Record "PGA HA Doc";
    begin
        Observer.Discard();
        if Forget then
            Holder.Forget();
        Doc.DeleteAll();
        Doc.Init();
        Doc."No." := 'H1';
        Doc.Insert();
        Doc.Init();
        Doc."No." := 'H2';
        Doc.Insert();
    end;

    [TryFunction]
    local procedure TryOpenOther(var P: TestPage "PGA HA Other")
    begin
        P.OpenView();
        P.GoToKey('H2');
    end;

    local procedure OpenOther()
    var
        P: TestPage "PGA HA Other";
    begin
        Holder.Take();
        if TryOpenOther(P) then
            Observer.Observe('other-open', 'ok')
        else
            Observer.ObserveError('other-open');
        Observer.Observe('log', Holder.Take());
    end;

    [Test]
    procedure A1_HeldClosedByTestPageClose()
    var
        P: TestPage "PGA HA Held";
    begin
        Initialize(true);
        P.OpenView();
        P.GoToKey('H1');
        P.Close();
        Observer.Observe('log', Holder.Take());
        Observer.Finish();
    end;

    [Test]
    procedure A2_OtherPageReachesHeldClosedByTestPageClose()
    begin
        Initialize(false);
        OpenOther();
        Observer.Finish();
    end;

    [Test]
    procedure B1_HeldOpenAtTestEnd()
    var
        P: TestPage "PGA HA Held";
    begin
        Initialize(true);
        P.OpenView();
        P.GoToKey('H1');
        Observer.Observe('log', Holder.Take());
        Observer.Finish();
    end;

    [Test]
    procedure B2_OtherPageReachesHeldOpenAtTestEnd()
    begin
        Initialize(false);
        OpenOther();
        Observer.Finish();
    end;

    [Test]
    procedure C1_HeldClosedByOK()
    var
        P: TestPage "PGA HA Held";
    begin
        Initialize(true);
        P.OpenEdit();
        P.GoToKey('H1');
        P.OK().Invoke();
        Observer.Observe('log', Holder.Take());
        Observer.Finish();
    end;

    [Test]
    procedure C2_OtherPageReachesHeldClosedByOK()
    begin
        Initialize(false);
        OpenOther();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HeldPageHandler')]
    procedure D1_HeldRunByPageRunWithPageHandler()
    var
        Doc: Record "PGA HA Doc";
    begin
        Initialize(true);
        Doc.Get('H1');
        Page.Run(Page::"PGA HA Held", Doc);
        Observer.Observe('log', Holder.Take());
        Observer.Finish();
    end;

    [Test]
    procedure D2_OtherPageReachesHeldRunByPageRun()
    begin
        Initialize(false);
        OpenOther();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HeldModalHandler')]
    procedure E1_HeldRunModalClosedByOKInHandler()
    var
        Doc: Record "PGA HA Doc";
    begin
        Initialize(true);
        Doc.Get('H1');
        Observer.Observe('action', Format(Page.RunModal(Page::"PGA HA Held", Doc)));
        Observer.Observe('log', Holder.Take());
        Observer.Finish();
    end;

    [Test]
    procedure E2_OtherPageReachesHeldRunModal()
    begin
        Initialize(false);
        OpenOther();
        Observer.Finish();
    end;

    [PageHandler]
    procedure HeldPageHandler(var P: TestPage "PGA HA Held")
    begin
    end;

    [ModalPageHandler]
    procedure HeldModalHandler(var P: TestPage "PGA HA Held")
    begin
        P.OK().Invoke();
    end;
}
