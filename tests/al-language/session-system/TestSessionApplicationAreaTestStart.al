// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-applicationarea-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 75440, pages 75441-75444, test codeunits 75445-75446
// Probe: corpus issue "application areas at test start under the two BC test runners", 2026-11-20.
//
// BC runs tests in two ways (see pages/UiHandlerModes.al): through Test Runner 130450, as this
// corpus's CI does on BC 27, and through the dev endpoint's test runner (VS Code "Run tests",
// al runtests). The session's application areas at the start of a test differ: empty under
// Test Runner 130450 (permissions/testpermissions/BaTpEnv.al), the company setup's list under the
// dev endpoint's runner. The [Test] procedures below assert only what holds under both:
// 1. At test start, and in the test codeunit's OnRun, ApplicationArea() is either empty or equal
//    to Application Area Mgmt. Facade.GetApplicationAreaSetup().
// 2. A TestPage opened with the start areas finds the same controls as one opened after
//    ApplicationArea(<start areas>) was called explicitly. Controls in area All, controls without
//    an area on an All page, an All part and an All action are always found.
// 3. Areas set in OnRun are what the first test starts with.
// 4. A page decides which controls it has from the areas set before it opened: when its OnInit or
//    OnOpenPage calls ApplicationArea('#Suite') after the test set '#Basic', the #Basic control is
//    found and the #Suite control is not (TestFieldNotFound), and the session keeps '#Suite' after
//    the page closes.
// 5. With the measured BC 27.5 company setup list set explicitly, #Basic and #Suite controls,
//    parts and actions are found; #Advanced and an area outside the list are not.
// The values measured under the dev endpoint's runner (start list per version, language, work
// date, carry-over between tests) are in the non-[Test] procedure DevEndpointTestRunner_MeasuredValues.
// Measured on Windows BC 27.5 and 28.5 containers through the dev endpoint's runner.
// Not measured: an ApplicationArea on a page group (does not compile, AL0124, see
// pages/application-area/W2AppAreas.al).
// BC versions: 27, 28, 29

table 75440 "LT SLA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { DataClassification = SystemMetadata; }
        field(2; F1; Text[30]) { DataClassification = SystemMetadata; }
        field(3; F2; Text[30]) { DataClassification = SystemMetadata; }
        field(4; F3; Text[30]) { DataClassification = SystemMetadata; }
        field(5; F4; Text[30]) { DataClassification = SystemMetadata; }
        field(6; F5; Text[30]) { DataClassification = SystemMetadata; }
        field(7; F6; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

page 75441 "LT SLA Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT SLA Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoAreaCtl; Rec.F1) { }
            field(AllCtl; Rec.F2) { ApplicationArea = All; }
            field(BasicCtl; Rec.F3) { ApplicationArea = Basic; }
            field(SuiteCtl; Rec.F4) { ApplicationArea = Suite; }
            field(AdvancedCtl; Rec.F5) { ApplicationArea = Advanced; }
            field(ProbeCtl; Rec.F6) { ApplicationArea = LTSlaProbe; }
            part(SubBasic; "LT SLA Sub") { ApplicationArea = Basic; }
            part(SubAll; "LT SLA Sub") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActAll)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                end;
            }
            action(ActBasic)
            {
                ApplicationArea = Basic;

                trigger OnAction()
                begin
                end;
            }
            action(ActSuite)
            {
                ApplicationArea = Suite;

                trigger OnAction()
                begin
                end;
            }
            action(ActProbe)
            {
                ApplicationArea = LTSlaProbe;

                trigger OnAction()
                begin
                end;
            }
        }
    }
}

page 75442 "LT SLA Sub"
{
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "LT SLA Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(SubInfo; Rec.F1) { ApplicationArea = All; }
        }
    }
}

// OnInit sets the session's areas to #Suite.
page 75443 "LT SLA Init Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT SLA Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(AllCtl; Rec.F2) { ApplicationArea = All; }
            field(BasicCtl; Rec.F3) { ApplicationArea = Basic; }
            field(SuiteCtl; Rec.F4) { ApplicationArea = Suite; }
        }
    }

    trigger OnInit()
    begin
        ApplicationArea('#Suite');
    end;
}

// OnOpenPage sets the session's areas to #Suite.
page 75444 "LT SLA Open Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT SLA Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(AllCtl; Rec.F2) { ApplicationArea = All; }
            field(BasicCtl; Rec.F3) { ApplicationArea = Basic; }
            field(SuiteCtl; Rec.F4) { ApplicationArea = Suite; }
        }
    }

    trigger OnOpenPage()
    begin
        ApplicationArea('#Suite');
    end;
}

codeunit 75445 "LT SLA Start Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Start_Areas_EmptyOrCompanySetup()
    var
        Observer: Codeunit "Probe Observer";
        Facade: Codeunit "Application Area Mgmt. Facade";
        AtStart: Text;
    begin
        AtStart := ApplicationArea();
        Observer.Observe('emptyOrSetup', YesNo((AtStart = '') or (AtStart = Facade.GetApplicationAreaSetup())));
        Observer.Expect('emptyOrSetup', 'yes');
        Observer.Verify();
    end;

    [Test]
    procedure Start_Controls_SameAsAfterSettingTheStartAreas()
    var
        Observer: Codeunit "Probe Observer";
        AtStart: Text;
        Before: Text;
        After: Text;
    begin
        Seed();
        AtStart := ApplicationArea();
        Before := ReadCard();
        ApplicationArea(AtStart);
        After := ReadCard();
        ApplicationArea(AtStart);
        Observer.Observe('same', YesNo(Before = After));
        Observer.Observe('fixed', FixedControls());
        Observer.Expect('same', 'yes');
        Observer.Expect('fixed', 'NoAreaCtl=found AllCtl=found SubAll=found ActAll=found');
        Observer.Verify();
    end;

    [Test]
    procedure OnInit_SetsSuite_AfterTestSetBasic()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT SLA Init Card";
        AtStart: Text;
    begin
        Seed();
        AtStart := ApplicationArea();
        ApplicationArea('#Basic');
        Pg.OpenView();
        Observer.Observe('all', ReadInitAll(Pg));
        Observer.Observe('basic', ReadInitBasic(Pg));
        Observer.Observe('suite', ReadInitSuite(Pg));
        Observer.Observe('areasWhileOpen', ApplicationArea());
        Pg.Close();
        Observer.Observe('areasAfterClose', ApplicationArea());
        ApplicationArea(AtStart);
        Observer.Expect('all', 'found');
        Observer.Expect('basic', 'found');
        Observer.Expect('suite', 'missing:TestFieldNotFound');
        Observer.Expect('areasWhileOpen', '#Suite');
        Observer.Expect('areasAfterClose', '#Suite');
        Observer.Verify();
    end;

    [Test]
    procedure OnOpenPage_SetsSuite_AfterTestSetBasic()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT SLA Open Card";
        AtStart: Text;
    begin
        Seed();
        AtStart := ApplicationArea();
        ApplicationArea('#Basic');
        Pg.OpenView();
        Observer.Observe('all', ReadOpenAll(Pg));
        Observer.Observe('basic', ReadOpenBasic(Pg));
        Observer.Observe('suite', ReadOpenSuite(Pg));
        Observer.Observe('areasWhileOpen', ApplicationArea());
        Pg.Close();
        Observer.Observe('areasAfterClose', ApplicationArea());
        ApplicationArea(AtStart);
        Observer.Expect('all', 'found');
        Observer.Expect('basic', 'found');
        Observer.Expect('suite', 'missing:TestFieldNotFound');
        Observer.Expect('areasWhileOpen', '#Suite');
        Observer.Expect('areasAfterClose', '#Suite');
        Observer.Verify();
    end;

    [Test]
    procedure Card_UnderTheMeasuredCompanySetupList()
    var
        Observer: Codeunit "Probe Observer";
        AtStart: Text;
        Card: Text;
    begin
        Seed();
        AtStart := ApplicationArea();
        ApplicationArea(MeasuredStartAreas27());
        Card := ReadCard();
        ApplicationArea(AtStart);
        Observer.Observe('card', Card);
        Observer.Expect('card', 'NoAreaCtl=found AllCtl=found BasicCtl=found SuiteCtl=found AdvancedCtl=missing:TestFieldNotFound ProbeCtl=missing:TestFieldNotFound SubBasic=found SubAll=found ActAll=found ActBasic=found ActSuite=found ActProbe=missing:TestActionNotFound');
        Observer.Verify();
    end;

    local procedure Seed()
    var
        Row: Record "LT SLA Row";
    begin
        Row.DeleteAll();
        Row.Code := 'A';
        Row.F1 := 'f1';
        Row.F2 := 'f2';
        Row.F3 := 'f3';
        Row.F4 := 'f4';
        Row.F5 := 'f5';
        Row.F6 := 'f6';
        Row.Insert();
    end;

    // The controls whose answer does not depend on the session's areas: page-level All, own All, an All part, an All action.
    local procedure FixedControls(): Text
    var
        Pg: TestPage "LT SLA Card";
        Result: Text;
    begin
        Pg.OpenView();
        Result := 'NoAreaCtl=' + Outcome(TryNoArea(Pg)) + ' AllCtl=' + Outcome(TryAll(Pg)) +
            ' SubAll=' + Outcome(TrySubAll(Pg)) + ' ActAll=' + Outcome(TryActAll(Pg));
        Pg.Close();
        exit(Result);
    end;

    local procedure ReadCard(): Text
    var
        Pg: TestPage "LT SLA Card";
        Result: Text;
    begin
        Pg.OpenView();
        Result := 'NoAreaCtl=' + Outcome(TryNoArea(Pg)) + ' AllCtl=' + Outcome(TryAll(Pg)) + ' BasicCtl=' + Outcome(TryBasic(Pg)) +
            ' SuiteCtl=' + Outcome(TrySuite(Pg)) + ' AdvancedCtl=' + Outcome(TryAdvanced(Pg)) + ' ProbeCtl=' + Outcome(TryProbe(Pg)) +
            ' SubBasic=' + Outcome(TrySubBasic(Pg)) + ' SubAll=' + Outcome(TrySubAll(Pg)) +
            ' ActAll=' + Outcome(TryActAll(Pg)) + ' ActBasic=' + Outcome(TryActBasic(Pg)) + ' ActSuite=' + Outcome(TryActSuite(Pg)) +
            ' ActProbe=' + Outcome(TryActProbe(Pg));
        Pg.Close();
        exit(Result);
    end;

    // The areas the BC 27.5 CRONUS company setup gives. Measured under the
    // dev endpoint's test runner, where each test starts with them; see DevEndpointTestRunner_MeasuredValues.
    local procedure MeasuredStartAreas27(): Text
    begin
        exit('#Basic,#Suite,#RelationshipMgmt,#Jobs,#FixedAssets,#Location,#BasicHR,#Assembly,#ItemCharges,#Warehouse,#Planning,#Dimensions,#ItemTracking,#Intercompany,#SalesReturnOrder,#PurchReturnOrder,#Prepayments,#CostAccounting,#SalesBudget,#PurchaseBudget,#ItemBudget,#SalesAnalysis,#PurchaseAnalysis,#InventoryAnalysis,#Reservation,#OrderPromising,#ADCS,#Comments,#RecordLinks,#Notes,#VAT,#ItemReferences,#BasicEU');
    end;

    // Not a test. The corpus CI runs the tests through Test Runner 130450, where every test starts with
    // the areas empty (permissions/testpermissions/BaTpEnv.al). The dev endpoint's test runner (VS Code
    // "Run tests", al runtests) starts each test with the company setup's areas instead. A [Test] cannot
    // assert that mode, so the values measured under it on Windows BC containers are kept here.
    procedure DevEndpointTestRunner_MeasuredValues(): Text
    begin
        exit(
            'GuiAllowed at test start | true (27.5, 28.5)\' +
            'Test Runner 130450, 130451, 130454 on the call stack | none (27.5, 28.5)\' +
            'ApplicationArea() at test start | equal to Application Area Mgmt. Facade.GetApplicationAreaSetup(), not empty (27.5, 28.5)\' +
            'ApplicationArea() at test start, BC 27.5 CRONUS | #Basic,#Suite,#RelationshipMgmt,#Jobs,#FixedAssets,#Location,#BasicHR,#Assembly,#ItemCharges,#Warehouse,#Planning,#Dimensions,#ItemTracking,#Intercompany,#SalesReturnOrder,#PurchReturnOrder,#Prepayments,#CostAccounting,#SalesBudget,#PurchaseBudget,#ItemBudget,#SalesAnalysis,#PurchaseAnalysis,#InventoryAnalysis,#Reservation,#OrderPromising,#ADCS,#Comments,#RecordLinks,#Notes,#VAT,#ItemReferences,#BasicEU\' +
            'ApplicationArea() at test start, BC 28.5 CRONUS | the 27.5 list followed by ,#QualityManagement\' +
            'ApplicationArea() in the test codeunit OnRun | the same company setup list (27.5, 28.5)\' +
            'areas set in OnRun | seen by the first test only; the second test starts with the list OnRun saw (27.5, 28.5)\' +
            'areas set in one test | the next test starts with the start list again (27.5, 28.5)\' +
            'GlobalLanguage and WindowsLanguage at test start | 1033 (27.5, 28.5)\' +
            'GlobalLanguage(1031) set in one test | the next test still reads 1031 (27.5, 28.5)\' +
            'WorkDate at test start | not Today (27.5, 28.5)\' +
            'LT SLA Card at test start, BC 27.5 | NoAreaCtl, AllCtl, BasicCtl, SuiteCtl, SubBasic, SubAll, ActAll, ActBasic, ActSuite found; AdvancedCtl and ProbeCtl TestFieldNotFound; ActProbe TestActionNotFound');
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('found');
        exit('missing:' + GetLastErrorCode());
    end;

    local procedure YesNo(Value: Boolean): Text
    begin
        if Value then
            exit('yes');
        exit('no');
    end;

    local procedure ReadInitAll(var Pg: TestPage "LT SLA Init Card"): Text
    begin
        exit(Outcome(TryInitAll(Pg)));
    end;

    local procedure ReadInitBasic(var Pg: TestPage "LT SLA Init Card"): Text
    begin
        exit(Outcome(TryInitBasic(Pg)));
    end;

    local procedure ReadInitSuite(var Pg: TestPage "LT SLA Init Card"): Text
    begin
        exit(Outcome(TryInitSuite(Pg)));
    end;

    local procedure ReadOpenAll(var Pg: TestPage "LT SLA Open Card"): Text
    begin
        exit(Outcome(TryOpenAll(Pg)));
    end;

    local procedure ReadOpenBasic(var Pg: TestPage "LT SLA Open Card"): Text
    begin
        exit(Outcome(TryOpenBasic(Pg)));
    end;

    local procedure ReadOpenSuite(var Pg: TestPage "LT SLA Open Card"): Text
    begin
        exit(Outcome(TryOpenSuite(Pg)));
    end;

    [TryFunction]
    local procedure TryNoArea(var Pg: TestPage "LT SLA Card")
    var
        V: Text;
    begin
        V := Pg.NoAreaCtl.Value();
    end;

    [TryFunction]
    local procedure TryAll(var Pg: TestPage "LT SLA Card")
    var
        V: Text;
    begin
        V := Pg.AllCtl.Value();
    end;

    [TryFunction]
    local procedure TryBasic(var Pg: TestPage "LT SLA Card")
    var
        V: Text;
    begin
        V := Pg.BasicCtl.Value();
    end;

    [TryFunction]
    local procedure TrySuite(var Pg: TestPage "LT SLA Card")
    var
        V: Text;
    begin
        V := Pg.SuiteCtl.Value();
    end;

    [TryFunction]
    local procedure TryAdvanced(var Pg: TestPage "LT SLA Card")
    var
        V: Text;
    begin
        V := Pg.AdvancedCtl.Value();
    end;

    [TryFunction]
    local procedure TryProbe(var Pg: TestPage "LT SLA Card")
    var
        V: Text;
    begin
        V := Pg.ProbeCtl.Value();
    end;

    [TryFunction]
    local procedure TrySubBasic(var Pg: TestPage "LT SLA Card")
    var
        V: Text;
    begin
        V := Pg.SubBasic.SubInfo.Value();
    end;

    [TryFunction]
    local procedure TrySubAll(var Pg: TestPage "LT SLA Card")
    var
        V: Text;
    begin
        V := Pg.SubAll.SubInfo.Value();
    end;

    [TryFunction]
    local procedure TryActAll(var Pg: TestPage "LT SLA Card")
    begin
        Pg.ActAll.Invoke();
    end;

    [TryFunction]
    local procedure TryActBasic(var Pg: TestPage "LT SLA Card")
    begin
        Pg.ActBasic.Invoke();
    end;

    [TryFunction]
    local procedure TryActSuite(var Pg: TestPage "LT SLA Card")
    begin
        Pg.ActSuite.Invoke();
    end;

    [TryFunction]
    local procedure TryActProbe(var Pg: TestPage "LT SLA Card")
    begin
        Pg.ActProbe.Invoke();
    end;

    [TryFunction]
    local procedure TryInitAll(var Pg: TestPage "LT SLA Init Card")
    var
        V: Text;
    begin
        V := Pg.AllCtl.Value();
    end;

    [TryFunction]
    local procedure TryInitBasic(var Pg: TestPage "LT SLA Init Card")
    var
        V: Text;
    begin
        V := Pg.BasicCtl.Value();
    end;

    [TryFunction]
    local procedure TryInitSuite(var Pg: TestPage "LT SLA Init Card")
    var
        V: Text;
    begin
        V := Pg.SuiteCtl.Value();
    end;

    [TryFunction]
    local procedure TryOpenAll(var Pg: TestPage "LT SLA Open Card")
    var
        V: Text;
    begin
        V := Pg.AllCtl.Value();
    end;

    [TryFunction]
    local procedure TryOpenBasic(var Pg: TestPage "LT SLA Open Card")
    var
        V: Text;
    begin
        V := Pg.BasicCtl.Value();
    end;

    [TryFunction]
    local procedure TryOpenSuite(var Pg: TestPage "LT SLA Open Card")
    var
        V: Text;
    begin
        V := Pg.SuiteCtl.Value();
    end;
}

codeunit 75446 "LT SLA OnRun Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        AtOnRun: Text;
        SetupAtOnRun: Text;
        OnRunRan: Boolean;

    trigger OnRun()
    var
        Facade: Codeunit "Application Area Mgmt. Facade";
    begin
        AtOnRun := ApplicationArea();
        SetupAtOnRun := Facade.GetApplicationAreaSetup();
        OnRunRan := true;
        ApplicationArea('#Basic,#LTSlaOnRun');
    end;

    [Test]
    procedure OnRun_Areas_EmptyOrCompanySetup_FirstTest_EmptyOrOnRunValue()
    var
        Observer: Codeunit "Probe Observer";
        AtFirstTest: Text;
    begin
        AtFirstTest := ApplicationArea();
        Observer.Observe('onRunRan', YesNo(OnRunRan));
        Observer.Observe('onRunEmptyOrSetup', YesNo((AtOnRun = '') or (AtOnRun = SetupAtOnRun)));
        Observer.Observe('firstTestEmptyOrOnRunValue', YesNo((AtFirstTest = '') or (AtFirstTest = '#Basic,#LTSlaOnRun')));
        Observer.Expect('onRunRan', 'yes');
        Observer.Expect('onRunEmptyOrSetup', 'yes');
        Observer.Expect('firstTestEmptyOrOnRunValue', 'yes');
        Observer.Verify();
    end;

    local procedure YesNo(Value: Boolean): Text
    begin
        if Value then
            exit('yes');
        exit('no');
    end;
}
