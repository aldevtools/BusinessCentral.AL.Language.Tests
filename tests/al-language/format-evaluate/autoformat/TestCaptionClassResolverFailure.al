// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Assert (60021), and the table, page and codeunits declared below.
//
// A CaptionClass whose area no built-in resolver claims is handed to the System Application's
// "Caption Class" codeunit (42), which raises OnResolveCaptionClass. An error a subscriber raises there
// reaches the test as that error, from the OpenView of the page that declares the control: the AL error
// text, not a wrapper's. The expression is evaluated when the page opens, so a control nobody reads
// still fails the open (see TestAutoFormatExpressionTiming.al for the timing). The control with a
// resolvable CaptionClass on the same page is the pair: with the failing control gone it reads.
//
// The subscriber raises only for the expression "AFSBOOM", so no other page in this app is affected.
// Subscribing to the event compiles in a user app on every cloud leg.
//
// Written by agent stma-auto-7, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4920.

table 69620 "AFS Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 69620 "AFS Failing Card"
{
    PageType = Card;
    SourceTable = "AFS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(PlainCaptionCtl; Rec.Amount)
            {
                ApplicationArea = All;
                CaptionClass = '3,Plain Caption';
            }
            field(BoomCaptionCtl; Rec.Amount)
            {
                ApplicationArea = All;
                CaptionClass = 'ZZ,AFSBOOM';
            }
        }
    }
}

page 69621 "AFS Working Card"
{
    PageType = Card;
    SourceTable = "AFS Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(PlainCaptionCtl; Rec.Amount)
            {
                ApplicationArea = All;
                CaptionClass = '3,Plain Caption';
            }
            field(UnclaimedAreaCtl; Rec.Amount)
            {
                ApplicationArea = All;
                CaptionClass = 'ZZ,Unclaimed';
            }
        }
    }
}

codeunit 69620 "AFS Resolver Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', false, false)]
    local procedure OnResolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if CaptionExpr.Contains('AFSBOOM') then
            Error('AFS resolver subscriber failed');
    end;
}

codeunit 69621 "AFS Resolver Failure Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        Row: Record "AFS Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'A';
        Row.Amount := 7;
        Row.Insert();
    end;

    [Test]
    procedure FailingResolverSubscriber_OpenRaisesTheSubscribersError()
    var
        P: TestPage "AFS Failing Card";
    begin
        Seed();
        asserterror P.OpenView();
        Assert.ExpectedError('AFS resolver subscriber failed');
    end;

    [Test]
    procedure ResolverThatDoesNotRaise_OpensAndReadsTheCaptions()
    var
        P: TestPage "AFS Working Card";
        Plain: Text;
        Unclaimed: Text;
    begin
        Seed();
        P.OpenView();
        Plain := P.PlainCaptionCtl.Caption();
        Unclaimed := P.UnclaimedAreaCtl.Caption();
        P.Close();
        Assert.AreEqual('Plain Caption', Plain, 'area 3 is resolved by the platform');
        Assert.AreEqual('ZZ,Unclaimed', Unclaimed, 'an area no resolver claims comes back unchanged (corpus 60930)');
    end;
}
