// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), Base Application page 6516 "Package No. Information List",
//                which ships PRECOMPILED and which no other corpus test opens (no Base Application
//                pageextension targets it), and Business Foundation PromptDialog page 332
//                "No. Series Generation", also precompiled and opened by no other corpus test.
//
// CLAIM: application-area removal applies to the ACTIONS of a page that ships precompiled, as it
// does to a page compiled here (codeunit 67531). The page states ApplicationArea = ItemTracking at
// object level. A TestPage reports an action as not found when the session's areas do not enable:
//   * the action's own area ("Navigate", #Basic,#Suite);
//   * the PAGE's area, when the action states none ("Comment");
//   * for a promoted actionref ("Navigate_Promoted", which states no area of its own), its
//     target action's area.
// Each negative arm pairs with an action on the same page that IS found under the same areas.
//
// A PromptDialog's system actions (page 332's Generate) are never removed by area: they are found
// under #Basic although they state no ApplicationArea and the session does not enable #All
// explicitly.
//
// Every test sets the session's application areas itself and restores the previous value BEFORE
// it asserts, as codeunit 67530 does.
//
// Written by agent stma-auto2-1, an automated implementation agent acting on the account holder's
// behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4862.

codeunit 67543 "PAA Precompiled Action Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        GenerateVisible: Boolean;

    [Test]
    procedure OwnArea_Enabled_IsFound_PageAreaAction_IsNotFound()
    var
        Packages: TestPage "Package No. Information List";
        PreviousAreas: Text;
        NavigateVisible: Boolean;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        Packages.OpenView();
        NavigateVisible := Packages.Navigate.Visible();
        asserterror Packages.Comment.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(NavigateVisible, 'the #Basic,#Suite action "Navigate" must be found under #Basic,#Suite');
    end;

    [Test]
    procedure PageAreaAction_Enabled_IsFound_OwnAreaAction_IsNotFound()
    var
        Packages: TestPage "Package No. Information List";
        PreviousAreas: Text;
        CommentVisible: Boolean;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#ItemTracking');

        Packages.OpenView();
        CommentVisible := Packages.Comment.Visible();
        asserterror Packages.Navigate.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(CommentVisible, '"Comment", which takes the page''s #ItemTracking, must be found under #ItemTracking');
    end;

    [Test]
    procedure ActionRef_TargetNotEnabled_IsNotFound()
    var
        Packages: TestPage "Package No. Information List";
        PreviousAreas: Text;
        CommentVisible: Boolean;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#ItemTracking');

        Packages.OpenView();
        CommentVisible := Packages.Comment.Visible();
        asserterror Packages.Navigate_Promoted.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
        Assert.IsTrue(CommentVisible, '"Comment" must be found under #ItemTracking');
    end;

    [Test]
    procedure ActionRef_TargetEnabled_IsFound()
    var
        Packages: TestPage "Package No. Information List";
        PreviousAreas: Text;
        RefVisible: Boolean;
    begin
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        Packages.OpenView();
        RefVisible := Packages.Navigate_Promoted.Visible();
        Packages.Close();
        ApplicationArea(PreviousAreas);
        Assert.IsTrue(RefVisible, 'the actionref to "Navigate" must be found when "Navigate" is');
    end;

    [Test]
    [HandlerFunctions('ReadGenerateHandler')]
    procedure PromptDialogSystemAction_IsFoundUnderAnyArea()
    var
        PreviousAreas: Text;
    begin
        GenerateVisible := false;
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic');

        Page.RunModal(Page::"No. Series Generation");
        ApplicationArea(PreviousAreas);
        Assert.IsTrue(GenerateVisible, 'the PromptDialog system action "Generate" must be found under #Basic');
    end;

    [ModalPageHandler]
    procedure ReadGenerateHandler(var Generation: TestPage "No. Series Generation")
    begin
        GenerateVisible := Generation.Generate.Visible();
        Generation.Cancel().Invoke();
    end;
}
