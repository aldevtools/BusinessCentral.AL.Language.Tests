// Probe: application areas on a TestPage. Which controls, groups, actions and actionrefs the session's areas remove, the full error texts, and whether a change of the areas after the page is open matters.
// Settles: md:264 (page-level area, control without area, All, actionref without area, areas read at open; an ApplicationArea on a group does not compile, AL0124), md:265 (full error text of a removed action, actionref, field).
// Every test restores the session's areas before it finishes.

table 68694 "W2 Area Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; F1; Text[30]) { }
        field(3; F2; Text[30]) { }
        field(4; F3; Text[30]) { }
        field(5; F4; Text[30]) { }
        field(6; F5; Text[30]) { }
        field(7; F6; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

page 68695 "W2 Area Card"
{
    PageType = Card;
    ApplicationArea = Basic;
    SourceTable = "W2 Area Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(MainGroup)
            {
                field(InheritCtl; Rec.F1) { }
                field(BasicCtl; Rec.F2) { ApplicationArea = Basic; }
                field(SuiteCtl; Rec.F3) { ApplicationArea = Suite; }
                field(AllCtl; Rec.F4) { ApplicationArea = All; }
            }
            group(PlainGroup)
            {
                field(InGroupNoArea; Rec.F5) { }
                field(InGroupSuite; Rec.F6) { ApplicationArea = Suite; }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(RefNoArea; ActNoArea) { }
            actionref(RefToSuite; ActSuite) { }
            actionref(RefToBasic; ActBasic) { }
        }
        area(Processing)
        {
            action(ActNoArea)
            {
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
            action(ActAll)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                end;
            }
        }
    }
}

// No ApplicationArea at page level.
page 68696 "W2 Area Bare Card"
{
    PageType = Card;
    SourceTable = "W2 Area Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoAreaCtl; Rec.F1) { }
            field(BasicCtl; Rec.F2) { ApplicationArea = Basic; }
            field(AllCtl; Rec.F4) { ApplicationArea = All; }
        }
    }
}

codeunit 68697 "W2 Area Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "W2 Area Row";
    begin
        Row.DeleteAll();
        Row.Code := 'R1';
        Row.F1 := 'one';
        Row.F2 := 'two';
        Row.F3 := 'three';
        Row.F4 := 'four';
        Row.F5 := 'five';
        Row.F6 := 'six';
        Row.Insert();
    end;

    local procedure OpenCard(var Pg: TestPage "W2 Area Card")
    var
        Row: Record "W2 Area Row";
    begin
        Row.Get('R1');
        Pg.OpenEdit();
        Pg.GoToRecord(Row);
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'found')
        else
            Observer.ObserveError(Name);
    end;

    local procedure ReportFields(var Observer: Codeunit "Probe Observer"; var Pg: TestPage "W2 Area Card")
    var
        Value: Text;
    begin
        Report(Observer, 'InheritCtl_no_area_page_Basic', ReadInherit(Pg, Value));
        Report(Observer, 'BasicCtl', ReadBasic(Pg, Value));
        Report(Observer, 'SuiteCtl', ReadSuite(Pg, Value));
        Report(Observer, 'AllCtl', ReadAll(Pg, Value));
        Report(Observer, 'InGroupNoArea', ReadInGroupNoArea(Pg, Value));
        Report(Observer, 'InGroupSuite', ReadInGroupSuite(Pg, Value));
    end;

    local procedure ReportActions(var Observer: Codeunit "Probe Observer"; var Pg: TestPage "W2 Area Card")
    begin
        Report(Observer, 'ActNoArea_page_Basic', InvokeNoArea(Pg));
        Report(Observer, 'ActBasic', InvokeBasic(Pg));
        Report(Observer, 'ActSuite', InvokeSuite(Pg));
        Report(Observer, 'ActAll', InvokeAll(Pg));
        Report(Observer, 'RefNoArea_target_no_area', InvokeRefNoArea(Pg));
        Report(Observer, 'RefToSuite', InvokeRefToSuite(Pg));
        Report(Observer, 'RefToBasic', InvokeRefToBasic(Pg));
    end;

    // ---- areas set before the page opens ----

    [Test]
    procedure Basic_Fields()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Card";
        Previous: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic');
        OpenCard(Pg);
        ReportFields(Observer, Pg);
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('InheritCtl_no_area_page_Basic', 'found');
        Observer.Expect('BasicCtl', 'found');
        Observer.Expect('SuiteCtl|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('SuiteCtl|code', 'TestFieldNotFound');
        Observer.Expect('AllCtl', 'found');
        Observer.Expect('InGroupNoArea', 'found');
        Observer.Expect('InGroupSuite|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('InGroupSuite|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Basic_Actions()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Card";
        Previous: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic');
        OpenCard(Pg);
        ReportActions(Observer, Pg);
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('ActNoArea_page_Basic', 'found');
        Observer.Expect('ActBasic', 'found');
        Observer.Expect('ActSuite|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('ActSuite|code', 'TestActionNotFound');
        Observer.Expect('ActAll', 'found');
        Observer.Expect('RefNoArea_target_no_area', 'found');
        Observer.Expect('RefToSuite|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('RefToSuite|code', 'TestActionNotFound');
        Observer.Expect('RefToBasic', 'found');
        Observer.Verify();
    end;

    [Test]
    procedure Suite_Fields()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Card";
        Previous: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Suite');
        OpenCard(Pg);
        ReportFields(Observer, Pg);
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('InheritCtl_no_area_page_Basic|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('InheritCtl_no_area_page_Basic|code', 'TestFieldNotFound');
        Observer.Expect('BasicCtl|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('BasicCtl|code', 'TestFieldNotFound');
        Observer.Expect('SuiteCtl', 'found');
        Observer.Expect('AllCtl', 'found');
        Observer.Expect('InGroupNoArea|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('InGroupNoArea|code', 'TestFieldNotFound');
        Observer.Expect('InGroupSuite', 'found');
        Observer.Verify();
    end;

    [Test]
    procedure Suite_Actions()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Card";
        Previous: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Suite');
        OpenCard(Pg);
        ReportActions(Observer, Pg);
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('ActNoArea_page_Basic|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('ActNoArea_page_Basic|code', 'TestActionNotFound');
        Observer.Expect('ActBasic|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('ActBasic|code', 'TestActionNotFound');
        Observer.Expect('ActSuite', 'found');
        Observer.Expect('ActAll', 'found');
        Observer.Expect('RefNoArea_target_no_area|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('RefNoArea_target_no_area|code', 'TestActionNotFound');
        Observer.Expect('RefToSuite', 'found');
        Observer.Expect('RefToBasic|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('RefToBasic|code', 'TestActionNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure OtherAreaOnly_Fields()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Card";
        Previous: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Service');
        OpenCard(Pg);
        ReportFields(Observer, Pg);
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('InheritCtl_no_area_page_Basic|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('InheritCtl_no_area_page_Basic|code', 'TestFieldNotFound');
        Observer.Expect('BasicCtl|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('BasicCtl|code', 'TestFieldNotFound');
        Observer.Expect('SuiteCtl|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('SuiteCtl|code', 'TestFieldNotFound');
        Observer.Expect('AllCtl', 'found');
        Observer.Expect('InGroupNoArea|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('InGroupNoArea|code', 'TestFieldNotFound');
        Observer.Expect('InGroupSuite|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('InGroupSuite|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure AllAreasEnabled_FieldsAndActions()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Card";
        Previous: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('');
        OpenCard(Pg);
        ReportFields(Observer, Pg);
        ReportActions(Observer, Pg);
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('InheritCtl_no_area_page_Basic', 'found');
        Observer.Expect('BasicCtl', 'found');
        Observer.Expect('SuiteCtl', 'found');
        Observer.Expect('AllCtl', 'found');
        Observer.Expect('InGroupNoArea', 'found');
        Observer.Expect('InGroupSuite', 'found');
        Observer.Expect('ActNoArea_page_Basic', 'found');
        Observer.Expect('ActBasic', 'found');
        Observer.Expect('ActSuite', 'found');
        Observer.Expect('ActAll', 'found');
        Observer.Expect('RefNoArea_target_no_area', 'found');
        Observer.Expect('RefToSuite', 'found');
        Observer.Expect('RefToBasic', 'found');
        Observer.Verify();
    end;

    // ---- the areas change while the page is open ----

    [Test]
    procedure ChangeAfterOpen_OpenedUnrestricted_ThenBasic()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Card";
        Previous: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('');
        OpenCard(Pg);
        ApplicationArea('#Basic');
        ReportFields(Observer, Pg);
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('InheritCtl_no_area_page_Basic', 'found');
        Observer.Expect('BasicCtl', 'found');
        Observer.Expect('SuiteCtl', 'found');
        Observer.Expect('AllCtl', 'found');
        Observer.Expect('InGroupNoArea', 'found');
        Observer.Expect('InGroupSuite', 'found');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeAfterOpen_OpenedBasic_ThenUnrestricted()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Card";
        Previous: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic');
        OpenCard(Pg);
        ApplicationArea('');
        ReportFields(Observer, Pg);
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('InheritCtl_no_area_page_Basic', 'found');
        Observer.Expect('BasicCtl', 'found');
        Observer.Expect('SuiteCtl|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('SuiteCtl|code', 'TestFieldNotFound');
        Observer.Expect('AllCtl', 'found');
        Observer.Expect('InGroupNoArea', 'found');
        Observer.Expect('InGroupSuite|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('InGroupSuite|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeAfterOpen_OpenedBasic_ThenSuite()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Card";
        Previous: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic');
        OpenCard(Pg);
        ApplicationArea('#Suite');
        ReportFields(Observer, Pg);
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('InheritCtl_no_area_page_Basic', 'found');
        Observer.Expect('BasicCtl', 'found');
        Observer.Expect('SuiteCtl|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('SuiteCtl|code', 'TestFieldNotFound');
        Observer.Expect('AllCtl', 'found');
        Observer.Expect('InGroupNoArea', 'found');
        Observer.Expect('InGroupSuite|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('InGroupSuite|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeAfterOpen_Actions_OpenedBasic_ThenSuite()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Card";
        Previous: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic');
        OpenCard(Pg);
        ApplicationArea('#Suite');
        ReportActions(Observer, Pg);
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('ActNoArea_page_Basic', 'found');
        Observer.Expect('ActBasic', 'found');
        Observer.Expect('ActSuite|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('ActSuite|code', 'TestActionNotFound');
        Observer.Expect('ActAll', 'found');
        Observer.Expect('RefNoArea_target_no_area', 'found');
        Observer.Expect('RefToSuite|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('RefToSuite|code', 'TestActionNotFound');
        Observer.Expect('RefToBasic', 'found');
        Observer.Verify();
    end;

    // A page opened before the change, closed and opened again after it.
    [Test]
    procedure ChangeBetweenOpens()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Card";
        Previous: Text;
        Value: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic');
        OpenCard(Pg);
        Report(Observer, 'first_open_SuiteCtl', ReadSuite(Pg, Value));
        Pg.Close();
        ApplicationArea('#Suite');
        OpenCard(Pg);
        Report(Observer, 'second_open_SuiteCtl', ReadSuite(Pg, Value));
        Report(Observer, 'second_open_BasicCtl', ReadBasic(Pg, Value));
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('first_open_SuiteCtl|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('first_open_SuiteCtl|code', 'TestFieldNotFound');
        Observer.Expect('second_open_SuiteCtl', 'found');
        Observer.Expect('second_open_BasicCtl|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('second_open_BasicCtl|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    // ---- a page with no ApplicationArea at page level ----

    [Test]
    procedure BarePage_Basic()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Bare Card";
        Row: Record "W2 Area Row";
        Previous: Text;
        Value: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic');
        Row.Get('R1');
        Pg.OpenEdit();
        Pg.GoToRecord(Row);
        Report(Observer, 'NoAreaCtl', ReadBareNoArea(Pg, Value));
        Report(Observer, 'BasicCtl', ReadBareBasic(Pg, Value));
        Report(Observer, 'AllCtl', ReadBareAll(Pg, Value));
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('NoAreaCtl|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('NoAreaCtl|code', 'TestFieldNotFound');
        Observer.Expect('BasicCtl', 'found');
        Observer.Expect('AllCtl', 'found');
        Observer.Verify();
    end;

    [Test]
    procedure BarePage_AllAreasEnabled()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Bare Card";
        Row: Record "W2 Area Row";
        Previous: Text;
        Value: Text;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('');
        Row.Get('R1');
        Pg.OpenEdit();
        Pg.GoToRecord(Row);
        Report(Observer, 'NoAreaCtl', ReadBareNoArea(Pg, Value));
        Report(Observer, 'BasicCtl', ReadBareBasic(Pg, Value));
        Report(Observer, 'AllCtl', ReadBareAll(Pg, Value));
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('NoAreaCtl', 'found');
        Observer.Expect('BasicCtl', 'found');
        Observer.Expect('AllCtl', 'found');
        Observer.Verify();
    end;

    // ---- full texts of the errors (md:265), with the exact call a test writes ----

    [Test]
    procedure RemovedControl_ErrorTexts()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Area Card";
        Previous: Text;
        Value: Text;
        Seen: Boolean;
    begin
        Seed();
        Previous := ApplicationArea();
        ApplicationArea('#Basic');
        OpenCard(Pg);
        asserterror Value := Pg.SuiteCtl.Value();
        Observer.ObserveError('field_Value');
        asserterror Pg.SuiteCtl.SetValue('x');
        Observer.ObserveError('field_SetValue');
        asserterror Pg.ActSuite.Invoke();
        Observer.ObserveError('action_Invoke');
        asserterror Pg.RefToSuite.Invoke();
        Observer.ObserveError('actionref_Invoke');
        Report(Observer, 'action_Enabled', ActionEnabled(Pg, Seen));
        Report(Observer, 'field_Visible', FieldVisible(Pg, Seen));
        Pg.Close();
        ApplicationArea(Previous);
        Observer.Expect('field_Value|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('field_Value|code', 'TestFieldNotFound');
        Observer.Expect('field_SetValue|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('field_SetValue|code', 'TestFieldNotFound');
        Observer.Expect('action_Invoke|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('action_Invoke|code', 'TestActionNotFound');
        Observer.Expect('actionref_Invoke|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('actionref_Invoke|code', 'TestActionNotFound');
        Observer.Expect('action_Enabled|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('action_Enabled|code', 'TestActionNotFound');
        Observer.Expect('field_Visible|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('field_Visible|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure ActionEnabled(var Pg: TestPage "W2 Area Card"; var Result: Boolean)
    begin
        Result := Pg.ActSuite.Enabled();
    end;

    [TryFunction]
    local procedure FieldVisible(var Pg: TestPage "W2 Area Card"; var Result: Boolean)
    begin
        Result := Pg.SuiteCtl.Visible();
    end;

    [TryFunction]
    local procedure ReadInherit(var Pg: TestPage "W2 Area Card"; var Value: Text)
    begin
        Value := Pg.InheritCtl.Value();
    end;

    [TryFunction]
    local procedure ReadBasic(var Pg: TestPage "W2 Area Card"; var Value: Text)
    begin
        Value := Pg.BasicCtl.Value();
    end;

    [TryFunction]
    local procedure ReadSuite(var Pg: TestPage "W2 Area Card"; var Value: Text)
    begin
        Value := Pg.SuiteCtl.Value();
    end;

    [TryFunction]
    local procedure ReadAll(var Pg: TestPage "W2 Area Card"; var Value: Text)
    begin
        Value := Pg.AllCtl.Value();
    end;

    [TryFunction]
    local procedure ReadInGroupNoArea(var Pg: TestPage "W2 Area Card"; var Value: Text)
    begin
        Value := Pg.InGroupNoArea.Value();
    end;

    [TryFunction]
    local procedure ReadInGroupSuite(var Pg: TestPage "W2 Area Card"; var Value: Text)
    begin
        Value := Pg.InGroupSuite.Value();
    end;

    [TryFunction]
    local procedure ReadBareNoArea(var Pg: TestPage "W2 Area Bare Card"; var Value: Text)
    begin
        Value := Pg.NoAreaCtl.Value();
    end;

    [TryFunction]
    local procedure ReadBareBasic(var Pg: TestPage "W2 Area Bare Card"; var Value: Text)
    begin
        Value := Pg.BasicCtl.Value();
    end;

    [TryFunction]
    local procedure ReadBareAll(var Pg: TestPage "W2 Area Bare Card"; var Value: Text)
    begin
        Value := Pg.AllCtl.Value();
    end;

    [TryFunction]
    local procedure InvokeNoArea(var Pg: TestPage "W2 Area Card")
    begin
        Pg.ActNoArea.Invoke();
    end;

    [TryFunction]
    local procedure InvokeBasic(var Pg: TestPage "W2 Area Card")
    begin
        Pg.ActBasic.Invoke();
    end;

    [TryFunction]
    local procedure InvokeSuite(var Pg: TestPage "W2 Area Card")
    begin
        Pg.ActSuite.Invoke();
    end;

    [TryFunction]
    local procedure InvokeAll(var Pg: TestPage "W2 Area Card")
    begin
        Pg.ActAll.Invoke();
    end;

    [TryFunction]
    local procedure InvokeRefNoArea(var Pg: TestPage "W2 Area Card")
    begin
        Pg.RefNoArea.Invoke();
    end;

    [TryFunction]
    local procedure InvokeRefToSuite(var Pg: TestPage "W2 Area Card")
    begin
        Pg.RefToSuite.Invoke();
    end;

    [TryFunction]
    local procedure InvokeRefToBasic(var Pg: TestPage "W2 Area Card")
    begin
        Pg.RefToBasic.Invoke();
    end;
}

// md:266 The session starts a test method with every area enabled.
codeunit 68699 "W2 Area Boundary Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        AreasAtFirstTest: Text;
        FirstTestRan: Boolean;

    [Test]
    procedure A_FirstTest_SetsAnArea()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AreasAtFirstTest := ApplicationArea();
        FirstTestRan := true;
        ApplicationArea('#Basic,#W2BoundaryProbe');
        Observer.Observe('after_set', ApplicationArea());
        Observer.Expect('after_set', '#Basic,#W2BoundaryProbe');
        Observer.Verify();
    end;

}
