// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-type-promptdialog
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT AA Row" (AaObjects.al)
// BC versions: 27+ (tested by the corpus CI matrix)
// Facts: Enabled on a system action (PromptDialog page): true, false and an expression, as a modal TestPage handler sees it.

page 76512 "LT AA Prompt Literal"
{
    PageType = PromptDialog;
    ApplicationArea = All;
    SourceTable = "LT AA Row";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Enabled = true;
            }
            systemaction(OK)
            {
                Enabled = false;
            }
            systemaction(Cancel)
            {
                Enabled = CancelEnabled;
            }
        }
    }

    var
        CancelEnabled: Boolean;
}

page 76513 "LT AA Prompt Expression"
{
    PageType = PromptDialog;
    ApplicationArea = All;
    SourceTable = "LT AA Row";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            field(Txt; Rec.Txt) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Enabled = GenerateEnabled;
            }
            systemaction(OK)
            {
                Enabled = GenerateEnabled;
            }
        }
    }

    trigger OnOpenPage()
    begin
        GenerateEnabled := true;
    end;

    var
        GenerateEnabled: Boolean;
}

codeunit 76513 "LT AA System Action Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    [HandlerFunctions('LiteralHandler')]
    procedure AA_SystemAction_EnabledLiteral()
    var
        Modal: Page "LT AA Prompt Literal";
    begin
        Modal.RunModal();
        Observer.Expect('generate-enabled', 'Yes');
        Observer.Expect('ok-enabled', 'No');
        Observer.Expect('cancel-enabled', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ExpressionHandler')]
    procedure AA_SystemAction_EnabledExpression()
    var
        Modal: Page "LT AA Prompt Expression";
    begin
        Modal.RunModal();
        Observer.Expect('generate-enabled', 'Yes');
        Observer.Expect('ok-enabled', 'Yes');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure LiteralHandler(var Modal: TestPage "LT AA Prompt Literal")
    begin
        Observer.Observe('generate-enabled', Format(Modal.Generate.Enabled()));
        Observer.Observe('ok-enabled', Format(Modal.OK.Enabled()));
        Observer.Observe('cancel-enabled', Format(Modal.Cancel.Enabled()));
    end;

    [ModalPageHandler]
    procedure ExpressionHandler(var Modal: TestPage "LT AA Prompt Expression")
    begin
        Observer.Observe('generate-enabled', Format(Modal.Generate.Enabled()));
        Observer.Observe('ok-enabled', Format(Modal.OK.Enabled()));
    end;
}
