// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT AA Row" and page "LT AA Part List" (AaObjects.al)
// BC versions: 27+ (tested by the corpus CI matrix)
// Facts: label ColumnSpan / RowSpan / Width, part and system part Enabled / Editable / ShowFilter / Provider / UpdatePropagation,
// API part Multiplicity / EntityName / EntitySetName, field NavigationPageId / ODataEDMType, action Gesture / Scope / InFooterBar /
// Enabled / Ellipsis, split button group, header separator, file upload action and custom (Power Automate) action: compile result and what a TestPage sees.

page 76503 "LT AA API Sub"
{
    PageType = API;
    SourceTable = "LT AA Row";
    APIPublisher = 'ltaa';
    APIGroup = 'ltaa';
    APIVersion = 'v1.0';
    EntityName = 'aaSub';
    EntitySetName = 'aaSubs';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(id; Rec.SystemId) { }
                field(rel; Rec.Rel) { NavigationPageId = "LT AA Target Card"; }
                field(dt; Rec.Dt) { ODataEDMType = 'Edm.DateTimeOffset'; }
            }
        }
    }
}

page 76504 "LT AA API Main"
{
    PageType = API;
    SourceTable = "LT AA Row";
    APIPublisher = 'ltaa';
    APIGroup = 'ltaa';
    APIVersion = 'v1.0';
    EntityName = 'aaMain';
    EntitySetName = 'aaMains';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(id; Rec.SystemId) { }
            }
            part(many; "LT AA API Sub")
            {
                EntityName = 'aaSub';
                EntitySetName = 'aaSubs';
                Multiplicity = Many;
                SubPageLink = Id = field(Id);
            }
            part(one; "LT AA API Sub")
            {
                EntityName = 'aaSub';
                EntitySetName = 'aaSubs';
                Multiplicity = ZeroOrOne;
                SubPageLink = Id = field(Id);
            }
        }
    }
}

page 76505 "LT AA Controls Card"
{
    PageType = Card;
    SourceTable = "LT AA Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Flag; Rec.Flag) { ApplicationArea = All; }
            grid(Grid1)
            {
                GridLayout = Rows;

                group(Row1)
                {
                    Caption = 'Row one';

                    label(Lbl1)
                    {
                        ApplicationArea = All;
                        Caption = 'Label one';
                        ColumnSpan = 2;
                        RowSpan = 1;
                        Width = 10;
                    }
                    field(GridTxt; Rec.Txt) { ApplicationArea = All; }
                }
            }
            cuegroup(Cues)
            {
                CuegroupLayout = Wide;

                field(Cue1; Rec.Amt) { ApplicationArea = All; }
            }
            group(UploadGroup)
            {
                FileUploadAction = Upload1;
            }
            part(PartPlain; "LT AA Part List")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
            part(PartDisabled; "LT AA Part List")
            {
                ApplicationArea = All;
                Enabled = false;
                Editable = false;
                ShowFilter = false;
                UpdatePropagation = Both;
                Provider = PartPlain;
                SubPageView = sorting(Id) order(descending);
            }
            part(PartByFlag; "LT AA Part List")
            {
                ApplicationArea = All;
                Enabled = EnabledFlag;
                Editable = EnabledFlag;
                UpdatePropagation = SubPart;
                ShowFilter = true;
                FileUploadAction = Upload1;
            }
            systempart(SysNotes; Notes)
            {
                ApplicationArea = All;
                Enabled = false;
                Editable = false;
                ShowFilter = false;
                UpdatePropagation = Both;
                Provider = PartPlain;
            }
            systempart(SysLinks; Links)
            {
                ApplicationArea = All;
                Enabled = EnabledFlag;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Toggle)
            {
                ApplicationArea = All;
                Caption = 'Toggle';

                trigger OnAction()
                begin
                    EnabledFlag := not EnabledFlag;
                end;
            }
            action(ActSwipeLeft)
            {
                ApplicationArea = All;
                Gesture = LeftSwipe;

                trigger OnAction()
                begin
                end;
            }
            action(ActSwipeRight)
            {
                ApplicationArea = All;
                Gesture = RightSwipe;

                trigger OnAction()
                begin
                end;
            }
            action(ActNone)
            {
                ApplicationArea = All;
                Gesture = None;
                Scope = Repeater;

                trigger OnAction()
                begin
                end;
            }
            action(ActPageScope)
            {
                ApplicationArea = All;
                Scope = Page;
                InFooterBar = true;

                trigger OnAction()
                begin
                end;
            }
            action(ActEnabledTrue)
            {
                ApplicationArea = All;
                Enabled = true;

                trigger OnAction()
                begin
                end;
            }
            action(ActEnabledFalse)
            {
                ApplicationArea = All;
                Enabled = false;

                trigger OnAction()
                begin
                end;
            }
            action(ActEnabledFlag)
            {
                ApplicationArea = All;
                Enabled = EnabledFlag;

                trigger OnAction()
                begin
                end;
            }
            action(ActEllipsis)
            {
                ApplicationArea = All;
                Caption = 'Ellipsis action';
                Ellipsis = true;

                trigger OnAction()
                begin
                end;
            }
            group(SplitGroup)
            {
                Caption = 'Split';
                ShowAs = SplitButton;

                action(SplitFirst)
                {
                    ApplicationArea = All;

                    trigger OnAction()
                    begin
                    end;
                }
                action(SplitSecond)
                {
                    ApplicationArea = All;

                    trigger OnAction()
                    begin
                    end;
                }
            }
            group(StandardGroup)
            {
                Caption = 'Standard';
                ShowAs = Standard;

                action(StandardFirst)
                {
                    ApplicationArea = All;

                    trigger OnAction()
                    begin
                    end;
                }
            }
            group(HeaderGroup)
            {
                Caption = 'Headers';

                separator(HeaderSep)
                {
                    IsHeader = true;
                    Caption = 'Header text';
                }
                action(AfterHeader)
                {
                    ApplicationArea = All;

                    trigger OnAction()
                    begin
                    end;
                }
                separator(PlainSep)
                {
                    IsHeader = false;
                }
            }
            fileuploadaction(Upload1)
            {
                ApplicationArea = All;
                Gesture = LeftSwipe;
                InFooterBar = true;

                trigger OnAction(Files: List of [FileUpload])
                begin
                end;
            }
            customaction(FlowCustom)
            {
                ApplicationArea = All;
                CustomActionType = Flow;
                FlowId = '00001111-aaaa-2222-bbbb-3333cccc4444';
                FlowEnvironmentId = 'Default-44445555-eeee-6666-ffff-7777aaaa8888';
                Scope = Repeater;
                Enabled = false;
                Ellipsis = true;
                Caption = 'Flow action';
            }
            customaction(FlowTemplateCustom)
            {
                ApplicationArea = All;
                CustomActionType = FlowTemplate;
                FlowTemplateId = '00001111-aaaa-2222-bbbb-3333cccc4444';
                FlowCaption = 'Flow caption';
            }
            customaction(FlowGalleryCustom)
            {
                ApplicationArea = All;
                CustomActionType = FlowTemplateGallery;
                FlowTemplateCategoryName = 'Category';
                FlowCaption = 'Gallery caption';
            }
        }
    }

    var
        EnabledFlag: Boolean;
}

// Values the compiler accepts although they look out of range: label ColumnSpan / RowSpan / Width, field SignDisplacement and
// ODataEDMType (any text), and ShowAsTree on a group (a warning, not an error).
page 76514 "LT AA Lenient Card"
{
    PageType = Card;
    SourceTable = "LT AA Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            grid(LenientGrid)
            {
                GridLayout = Columns;

                group(LenientRow)
                {
                    label(BigSpan)
                    {
                        ApplicationArea = All;
                        Caption = 'Big span';
                        ColumnSpan = 1000;
                        RowSpan = 1000;
                    }
                    label(NegativeSpan)
                    {
                        ApplicationArea = All;
                        Caption = 'Negative span';
                        ColumnSpan = -1;
                    }
                    label(WideLabel)
                    {
                        ApplicationArea = All;
                        Caption = 'Wide';
                        Width = 100000;
                    }
                }
            }
            field(BigSign; Rec.Amt)
            {
                ApplicationArea = All;
                SignDisplacement = 9;
                ODataEDMType = 'Edm.Nonsense';
            }
            group(TreeGroup)
            {
                ShowAsTree = true;

                field(TreeTxt; Rec.Txt) { ApplicationArea = All; }
            }
        }
    }
}

// Writer BP (corpus issue 664, microsoft/AL issue 5507): a page field whose source is the bare name SystemId. This app has no
// NoImplicitWith feature, so the name binds to Rec.SystemId (warning AL0604); with the feature it is AL0118 (must-not-compile case 1446).
page 82550 "LT BP SysId Card"
{
    PageType = Card;
    SourceTable = "LT AA Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
#pragma warning disable AL0604
            field(SystemId; SystemId) { ApplicationArea = All; }
#pragma warning restore AL0604
            field(SysIdRec; Rec.SystemId) { ApplicationArea = All; }
        }
    }
}
codeunit 76511 "LT AA Controls Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AA_Controls_FieldsAndGrid()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Controls Card";
    begin
        Seed(Row);
        Row.Txt := 'in grid';
        Row.Amt := 42;
        Row.Modify();
        P.OpenEdit();
        Observer.Observe('grid-field', P.GridTxt.Value());
        Observer.Observe('grid-field-visible', Format(P.GridTxt.Visible()));
        Observer.Observe('cue-field', P.Cue1.Value());
        Observer.Observe('cue-field-visible', Format(P.Cue1.Visible()));
        P.Close();
        Observer.Expect('grid-field', 'in grid');
        Observer.Expect('grid-field-visible', 'Yes');
        Observer.Expect('cue-field', '42.00');
        Observer.Expect('cue-field-visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Controls_Action_Gestures()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Controls Card";
    begin
        Seed(Row);
        P.OpenEdit();
        Observer.Observe('left-visible', Format(P.ActSwipeLeft.Visible()));
        Observer.Observe('left-enabled', Format(P.ActSwipeLeft.Enabled()));
        Observer.Observe('right-visible', Format(P.ActSwipeRight.Visible()));
        Observer.Observe('right-enabled', Format(P.ActSwipeRight.Enabled()));
        P.Close();
        Observer.Expect('left-visible', 'Yes');
        Observer.Expect('left-enabled', 'Yes');
        Observer.Expect('right-visible', 'Yes');
        Observer.Expect('right-enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Controls_Action_ScopeRepeater()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Controls Card";
    begin
        Seed(Row);
        P.OpenEdit();
        Observer.Observe('none-visible', Format(P.ActNone.Visible()));
        Observer.Observe('none-enabled', Format(P.ActNone.Enabled()));
        P.Close();
        Observer.Expect('none-visible', 'Yes');
        Observer.Expect('none-enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Controls_Action_ScopePageFooter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Controls Card";
    begin
        Seed(Row);
        P.OpenEdit();
        Observer.Observe('page-scope-visible', Format(P.ActPageScope.Visible()));
        Observer.Observe('page-scope-enabled', Format(P.ActPageScope.Enabled()));
        P.Close();
        Observer.Expect('page-scope-visible', 'Yes');
        Observer.Expect('page-scope-enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Controls_Action_EnabledLiterals()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Controls Card";
    begin
        Seed(Row);
        P.OpenEdit();
        Observer.Observe('true-visible', Format(P.ActEnabledTrue.Visible()));
        Observer.Observe('true-enabled', Format(P.ActEnabledTrue.Enabled()));
        Observer.Observe('false-visible', Format(P.ActEnabledFalse.Visible()));
        Observer.Observe('false-enabled', Format(P.ActEnabledFalse.Enabled()));
        P.Close();
        Observer.Expect('true-visible', 'Yes');
        Observer.Expect('true-enabled', 'Yes');
        Observer.Expect('false-visible', 'Yes');
        Observer.Expect('false-enabled', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Controls_Action_Ellipsis()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Controls Card";
    begin
        Seed(Row);
        P.OpenEdit();
        Observer.Observe('ellipsis-visible', Format(P.ActEllipsis.Visible()));
        Observer.Observe('ellipsis-enabled', Format(P.ActEllipsis.Enabled()));
        P.Close();
        Observer.Expect('ellipsis-visible', 'Yes');
        Observer.Expect('ellipsis-enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Controls_Action_SplitButton()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Controls Card";
    begin
        Seed(Row);
        P.OpenEdit();
        Observer.Observe('split-first-visible', Format(P.SplitFirst.Visible()));
        Observer.Observe('split-first-enabled', Format(P.SplitFirst.Enabled()));
        Observer.Observe('split-second-visible', Format(P.SplitSecond.Visible()));
        Observer.Observe('split-second-enabled', Format(P.SplitSecond.Enabled()));
        P.Close();
        Observer.Expect('split-first-visible', 'Yes');
        Observer.Expect('split-first-enabled', 'Yes');
        Observer.Expect('split-second-visible', 'Yes');
        Observer.Expect('split-second-enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Controls_Action_StandardGroup()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Controls Card";
    begin
        Seed(Row);
        P.OpenEdit();
        Observer.Observe('standard-first-visible', Format(P.StandardFirst.Visible()));
        Observer.Observe('standard-first-enabled', Format(P.StandardFirst.Enabled()));
        P.Close();
        Observer.Expect('standard-first-visible', 'Yes');
        Observer.Expect('standard-first-enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Controls_Action_HeaderSeparator()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Controls Card";
    begin
        Seed(Row);
        P.OpenEdit();
        Observer.Observe('after-header-visible', Format(P.AfterHeader.Visible()));
        Observer.Observe('after-header-enabled', Format(P.AfterHeader.Enabled()));
        P.Close();
        Observer.Expect('after-header-visible', 'Yes');
        Observer.Expect('after-header-enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Controls_Action_EnabledExpression()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Controls Card";
    begin
        Seed(Row);
        P.OpenEdit();
        Observer.Observe('flag-enabled-before', Format(P.ActEnabledFlag.Enabled()));
        P.Toggle.Invoke();
        Observer.Observe('flag-enabled-after', Format(P.ActEnabledFlag.Enabled()));
        P.Toggle.Invoke();
        Observer.Observe('flag-enabled-again', Format(P.ActEnabledFlag.Enabled()));
        P.Close();
        Observer.Expect('flag-enabled-before', 'No');
        Observer.Expect('flag-enabled-after', 'Yes');
        Observer.Expect('flag-enabled-again', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Controls_PartState()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Controls Card";
    begin
        Seed(Row);
        P.OpenEdit();
        Observer.Observe('plain-visible', Format(P.PartPlain.Visible()));
        Observer.Observe('plain-enabled', Format(P.PartPlain.Enabled()));
        Observer.Observe('plain-editable', Format(P.PartPlain.Editable()));
        Observer.Observe('disabled-visible', Format(P.PartDisabled.Visible()));
        Observer.Observe('disabled-enabled', Format(P.PartDisabled.Enabled()));
        Observer.Observe('disabled-editable', Format(P.PartDisabled.Editable()));
        Observer.Observe('flag-enabled-before', Format(P.PartByFlag.Enabled()));
        Observer.Observe('flag-editable-before', Format(P.PartByFlag.Editable()));
        P.Toggle.Invoke();
        Observer.Observe('flag-enabled-after', Format(P.PartByFlag.Enabled()));
        Observer.Observe('flag-editable-after', Format(P.PartByFlag.Editable()));
        P.Close();
        Observer.Expect('plain-visible', 'Yes');
        Observer.Expect('plain-enabled', 'Yes');
        Observer.Expect('plain-editable', 'Yes');
        Observer.Expect('disabled-visible', 'Yes');
        Observer.Expect('disabled-enabled', 'No');
        Observer.Expect('disabled-editable', 'Yes');
        Observer.Expect('flag-enabled-before', 'No');
        Observer.Expect('flag-editable-before', 'Yes');
        Observer.Expect('flag-enabled-after', 'Yes');
        Observer.Expect('flag-editable-after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Controls_LenientValuesOpen()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Lenient Card";
    begin
        Seed(Row);
        Row.Txt := 'tree text';
        Row.Amt := -3;
        Row.Modify();
        P.OpenEdit();
        Observer.Observe('tree-txt', P.TreeTxt.Value());
        Observer.Observe('big-sign', P.BigSign.Value());
        P.Close();
        Observer.Expect('tree-txt', 'tree text');
        Observer.Expect('big-sign', '-3.00');
        Observer.Verify();
    end;

    // Writer BP (corpus issue 664): the bare SystemId page field shows the SystemId of the current record, like Rec.SystemId.
    [Test]
    procedure AA_BP_Page_BareSystemIdField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT BP SysId Card";
        Id: Text;
    begin
        Seed(Row);
        Row.Get('A');
        Id := Format(Row.SystemId);
        P.OpenView();
        Observer.Observe('bare', P.SystemId.Value().Replace(Id, '<id>').Replace(LowerCase(Id), '<lower id>'));
        Observer.Observe('rec', P.SysIdRec.Value().Replace(Id, '<id>').Replace(LowerCase(Id), '<lower id>'));
        Observer.Observe('bare editable', Format(P.SystemId.Editable()));
        Observer.Observe('bare caption', P.SystemId.Caption());
        P.Close();
        Observer.Expect('bare', '<lower id>');
        Observer.Expect('rec', '<lower id>');
        Observer.Expect('bare editable', 'No');
        Observer.Expect('bare caption', 'System ID');
        Observer.Verify();
    end;
    local procedure Seed(var Row: Record "LT AA Row")
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 'A';
        Row.Insert();
        Commit();
    end;
}
