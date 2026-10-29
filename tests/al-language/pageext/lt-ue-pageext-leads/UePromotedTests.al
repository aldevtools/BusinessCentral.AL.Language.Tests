// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects in UePromotedObjects.al and UeTriggerObjects.al (table 90330); test codeunit 90345
// Probe: written against the Windows BC 29 container.
// BC versions: 29 (27 and 28 by CI)
// Facts (AL Runner issues 6150 and 6158): a page extension adds an actionref to Category_New / Category_Report / Category_Process of a base page whose
//   area(Promoted) holds only Category_Process, to area(Promoted) of a page that declares no area(Promoted), and to area(Promoted) and Category_New of a page
//   that declares no actions section. Whether it compiles, and whether the actions and their actionrefs are there and run from a TestPage.
// Already pinned elsewhere: addlast(Promoted) on a page that declares area(Promoted) (handlers/TestPagePromotedActionref_Page.al), addafter(Category_New) on a page
//   without actions (pages/W1ActionAreasPromoted.al), addlast(Category_Category4) (pages/lt-page-ext-promoted/PageExtPromotedCategoryRisky.al).
codeunit 90345 "LT UE Promoted Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT UE Promo Log";

    local procedure Initialize()
    var
        Row: Record "LT UE Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Take();
    end;

    [Test]
    procedure CategoryNew_BaseDeclaresOnlyCategoryProcess()
    var
        Card: TestPage "LT UE Promo Process";
    begin
        Initialize();
        Card.OpenEdit();
        Observer.Observe('base visible', Format(Card.BaseAct.Visible()));
        Observer.Observe('base ref visible', Format(Card.BaseAct_Promoted.Visible()));
        Observer.Observe('new visible', Format(Card.ExtNew.Visible()));
        Observer.Observe('new ref visible', Format(Card.ExtNew_Promoted.Visible()));
        Observer.Observe('report ref visible', Format(Card.ExtReport_Promoted.Visible()));
        Observer.Observe('process ref visible', Format(Card.ExtProcess_Promoted.Visible()));
        Card.ExtNew.Invoke();
        Card.ExtNew_Promoted.Invoke();
        Card.ExtReport_Promoted.Invoke();
        Card.ExtProcess_Promoted.Invoke();
        Card.BaseAct_Promoted.Invoke();
        Observer.Observe('log', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Promoted_BaseDeclaresNoPromotedArea()
    var
        Card: TestPage "LT UE Promo No Area";
    begin
        Initialize();
        Card.OpenEdit();
        Observer.Observe('last ref visible', Format(Card.ExtLast_Promoted.Visible()));
        Observer.Observe('first ref visible', Format(Card.ExtFirst_Promoted.Visible()));
        Card.ExtLast_Promoted.Invoke();
        Card.ExtFirst_Promoted.Invoke();
        Card.BaseAct.Invoke();
        Observer.Observe('log', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Promoted_BaseDeclaresNoActions()
    var
        Card: TestPage "LT UE Promo No Actions";
    begin
        Initialize();
        Card.OpenView();
        Observer.Observe('action visible', Format(Card.NavAct.Visible()));
        Observer.Observe('first ref visible', Format(Card.NavAct_Promoted.Visible()));
        Observer.Observe('last ref visible', Format(Card.NavAct2_Promoted.Visible()));
        Card.NavAct.Invoke();
        Card.NavAct_Promoted.Invoke();
        Card.NavAct2_Promoted.Invoke();
        Observer.Observe('log', Log.Take());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CategoryNew_BaseDeclaresNoActions()
    var
        Card: TestPage "LT UE Promo No Actions Cat";
    begin
        Initialize();
        Card.OpenView();
        Observer.Observe('action visible', Format(Card.CatAct.Visible()));
        Observer.Observe('ref visible', Format(Card.CatAct_Promoted.Visible()));
        Card.CatAct_Promoted.Invoke();
        Observer.Observe('log', Log.Take());
        Card.Close();
        Observer.Finish();
    end;
}
