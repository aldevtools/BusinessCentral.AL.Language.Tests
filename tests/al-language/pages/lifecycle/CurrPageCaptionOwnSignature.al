// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-caption-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Probe Observer (codeunit 69160); pages 75416 to 75418, codeunit 75412 (tests)
// Probe: the same cells as CurrPageCaptionOwnPublic.al on pages whose own Caption has no return value (public, local) or one Text parameter (al-runner 8193, 8444, PR 8439). Called shows whether the own procedure ran.
// Every page has Caption = 'Static'. OnOpenPage reads CurrPage.Caption and CurrPage.Caption() (ReadBefore, ReadBeforeParens), assigns
// CurrPage.Caption := 'Assigned', reads both forms again (ReadAfter, ReadAfterParens) and calls the unqualified Caption() where it returns a
// value (OwnCall) or as a statement. Action CallForm runs CurrPage.Caption('ByCall'), action BareCall runs the unqualified Caption('Bare');
// each then reads CurrPage.Caption. Called records the calls of the own procedure. The test reads TestPage.Caption and the stored values.
// Compile facts (alc 16, 17, 18 and 30): a read of CurrPage.Caption or CurrPage.Caption() is Text whatever the own procedure returns
// (must-not-compile 3211, 3212); CurrPage.Caption := 'Assigned' compiles beside every own Caption shape, also beside Caption(): Integer;
// the bare Caption := 'X' beside an own parameterless Caption is AL0129 (3210); an unqualified Caption() calls the own procedure (3213, 3214),
// and so does P.Caption() on a Page variable (3215).
// Measured on BC 29.0 (Windows container, local observation; corpus CI measures 27.5, 28.5 and 29.0 on Linux):
// - CurrPage.Caption and CurrPage.Caption() read the platform caption beside every own Caption shape ('Static' before the assignment,
//   'Assigned' after it); they never call the own procedure (Called stays empty, OwnCall is unchanged).
// - CurrPage.Caption := 'Assigned' sets the platform caption (TestPage.Caption 'Assigned') beside every own Caption shape, also beside
//   Caption(): Integer and Caption(NewCaption: Text); the own procedure does not run.
// - CurrPage.Caption('ByCall') and the unqualified Caption('Bare') set the platform caption, also beside Caption(NewCaption: Text): the
//   one-argument call never reaches the own procedure with one Text parameter.
// - The unqualified Caption() calls the own procedure when there is one ('Own', '5', Called 'own;'), whatever its access (public, local,
//   protected, internal); without one it reads the platform caption ('Assigned').
// - A Page variable: P.Caption() and P.Caption call the own parameterless procedure ('Own', '5', Called 'own;'); P.Caption('Out') is the
//   platform setter (beside Caption(): Text the next P.Caption() is still 'Own'; beside Caption(NewCaption: Text) the own procedure does not
//   run and P.Caption() reads 'Out'); without an own procedure P.Caption() and P.Caption read 'Static'.
// BC versions: 29.0 measured locally (Windows); 27.5, 28.5 and 29.0 through corpus CI

// local object: a page that declares its own procedure named Caption (procedure Caption()).
page 75416 "CPC Own No Return"
{
    PageType = Card;
    Caption = 'Static';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(ReadBefore; ReadBefore) { ApplicationArea = All; }
            field(ReadBeforeParens; ReadBeforeParens) { ApplicationArea = All; }
            field(ReadAfter; ReadAfter) { ApplicationArea = All; }
            field(ReadAfterParens; ReadAfterParens) { ApplicationArea = All; }
            field(OwnCall; OwnCall) { ApplicationArea = All; }
            field(Called; Called) { ApplicationArea = All; }
            field(ReadByCall; ReadByCall) { ApplicationArea = All; }
            field(ReadBare; ReadBare) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CallForm)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Caption('ByCall');
                    ReadByCall := CurrPage.Caption;
                end;
            }
            action(BareCall)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Caption('Bare');
                    ReadBare := CurrPage.Caption;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ReadBefore := CurrPage.Caption;
        ReadBeforeParens := CurrPage.Caption();
        CurrPage.Caption := 'Assigned';
        ReadAfter := CurrPage.Caption;
        ReadAfterParens := CurrPage.Caption();
        Caption();
    end;

    var
        ReadBefore: Text;
        ReadBeforeParens: Text;
        ReadAfter: Text;
        ReadAfterParens: Text;
        OwnCall: Text;
        Called: Text;
        ReadByCall: Text;
        ReadBare: Text;

    procedure GetCalled(): Text
    begin
        exit(Called);
    end;

    procedure Caption()
    begin
        Called += 'own;';
    end;
}

// local object: a page that declares its own procedure named Caption (local procedure Caption()).
page 75417 "CPC Own Local No Return"
{
    PageType = Card;
    Caption = 'Static';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(ReadBefore; ReadBefore) { ApplicationArea = All; }
            field(ReadBeforeParens; ReadBeforeParens) { ApplicationArea = All; }
            field(ReadAfter; ReadAfter) { ApplicationArea = All; }
            field(ReadAfterParens; ReadAfterParens) { ApplicationArea = All; }
            field(OwnCall; OwnCall) { ApplicationArea = All; }
            field(Called; Called) { ApplicationArea = All; }
            field(ReadByCall; ReadByCall) { ApplicationArea = All; }
            field(ReadBare; ReadBare) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CallForm)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Caption('ByCall');
                    ReadByCall := CurrPage.Caption;
                end;
            }
            action(BareCall)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Caption('Bare');
                    ReadBare := CurrPage.Caption;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ReadBefore := CurrPage.Caption;
        ReadBeforeParens := CurrPage.Caption();
        CurrPage.Caption := 'Assigned';
        ReadAfter := CurrPage.Caption;
        ReadAfterParens := CurrPage.Caption();
        Caption();
    end;

    var
        ReadBefore: Text;
        ReadBeforeParens: Text;
        ReadAfter: Text;
        ReadAfterParens: Text;
        OwnCall: Text;
        Called: Text;
        ReadByCall: Text;
        ReadBare: Text;

    procedure GetCalled(): Text
    begin
        exit(Called);
    end;

    local procedure Caption()
    begin
        Called += 'own;';
    end;
}

// local object: a page that declares its own procedure named Caption (procedure Caption(NewCaption: Text)).
page 75418 "CPC Own Text Parameter"
{
    PageType = Card;
    Caption = 'Static';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(ReadBefore; ReadBefore) { ApplicationArea = All; }
            field(ReadBeforeParens; ReadBeforeParens) { ApplicationArea = All; }
            field(ReadAfter; ReadAfter) { ApplicationArea = All; }
            field(ReadAfterParens; ReadAfterParens) { ApplicationArea = All; }
            field(OwnCall; OwnCall) { ApplicationArea = All; }
            field(Called; Called) { ApplicationArea = All; }
            field(ReadByCall; ReadByCall) { ApplicationArea = All; }
            field(ReadBare; ReadBare) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CallForm)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Caption('ByCall');
                    ReadByCall := CurrPage.Caption;
                end;
            }
            action(BareCall)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Caption('Bare');
                    ReadBare := CurrPage.Caption;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ReadBefore := CurrPage.Caption;
        ReadBeforeParens := CurrPage.Caption();
        CurrPage.Caption := 'Assigned';
        ReadAfter := CurrPage.Caption;
        ReadAfterParens := CurrPage.Caption();
    end;

    var
        ReadBefore: Text;
        ReadBeforeParens: Text;
        ReadAfter: Text;
        ReadAfterParens: Text;
        OwnCall: Text;
        Called: Text;
        ReadByCall: Text;
        ReadBare: Text;

    procedure GetCalled(): Text
    begin
        exit(Called);
    end;

    procedure Caption(NewCaption: Text)
    begin
        Called += 'own:' + NewCaption + ';';
    end;
}

codeunit 75412 "CPC Own Signature Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OwnNoReturn_AssignAndRead_Observed()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "CPC Own No Return";
    begin
        P.OpenView();
        Observer.Observe('open: TestPage.Caption', P.Caption());
        Observer.Observe('open: ReadBefore', P.ReadBefore.Value());
        Observer.Observe('open: ReadBeforeParens', P.ReadBeforeParens.Value());
        Observer.Observe('open: ReadAfter', P.ReadAfter.Value());
        Observer.Observe('open: ReadAfterParens', P.ReadAfterParens.Value());
        Observer.Observe('open: OwnCall', P.OwnCall.Value());
        Observer.Observe('open: Called', P.Called.Value());
        P.CallForm.Invoke();
        Observer.Observe('CurrPage.Caption(ByCall): TestPage.Caption', P.Caption());
        Observer.Observe('CurrPage.Caption(ByCall): ReadByCall', P.ReadByCall.Value());
        Observer.Observe('CurrPage.Caption(ByCall): Called', P.Called.Value());
        P.BareCall.Invoke();
        Observer.Observe('Caption(Bare): TestPage.Caption', P.Caption());
        Observer.Observe('Caption(Bare): ReadBare', P.ReadBare.Value());
        Observer.Observe('Caption(Bare): Called', P.Called.Value());
        P.Close();
        Observer.Expect('open: TestPage.Caption', 'Assigned');
        Observer.Expect('open: ReadBefore', 'Static');
        Observer.Expect('open: ReadBeforeParens', 'Static');
        Observer.Expect('open: ReadAfter', 'Assigned');
        Observer.Expect('open: ReadAfterParens', 'Assigned');
        Observer.Expect('open: OwnCall', '');
        Observer.Expect('open: Called', 'own;');
        Observer.Expect('CurrPage.Caption(ByCall): TestPage.Caption', 'ByCall');
        Observer.Expect('CurrPage.Caption(ByCall): ReadByCall', 'ByCall');
        Observer.Expect('CurrPage.Caption(ByCall): Called', 'own;');
        Observer.Expect('Caption(Bare): TestPage.Caption', 'Bare');
        Observer.Expect('Caption(Bare): ReadBare', 'Bare');
        Observer.Expect('Caption(Bare): Called', 'own;');
        Observer.Verify();
    end;

    [Test]
    procedure OwnLocalNoReturn_AssignAndRead_Observed()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "CPC Own Local No Return";
    begin
        P.OpenView();
        Observer.Observe('open: TestPage.Caption', P.Caption());
        Observer.Observe('open: ReadBefore', P.ReadBefore.Value());
        Observer.Observe('open: ReadBeforeParens', P.ReadBeforeParens.Value());
        Observer.Observe('open: ReadAfter', P.ReadAfter.Value());
        Observer.Observe('open: ReadAfterParens', P.ReadAfterParens.Value());
        Observer.Observe('open: OwnCall', P.OwnCall.Value());
        Observer.Observe('open: Called', P.Called.Value());
        P.CallForm.Invoke();
        Observer.Observe('CurrPage.Caption(ByCall): TestPage.Caption', P.Caption());
        Observer.Observe('CurrPage.Caption(ByCall): ReadByCall', P.ReadByCall.Value());
        Observer.Observe('CurrPage.Caption(ByCall): Called', P.Called.Value());
        P.BareCall.Invoke();
        Observer.Observe('Caption(Bare): TestPage.Caption', P.Caption());
        Observer.Observe('Caption(Bare): ReadBare', P.ReadBare.Value());
        Observer.Observe('Caption(Bare): Called', P.Called.Value());
        P.Close();
        Observer.Expect('open: TestPage.Caption', 'Assigned');
        Observer.Expect('open: ReadBefore', 'Static');
        Observer.Expect('open: ReadBeforeParens', 'Static');
        Observer.Expect('open: ReadAfter', 'Assigned');
        Observer.Expect('open: ReadAfterParens', 'Assigned');
        Observer.Expect('open: OwnCall', '');
        Observer.Expect('open: Called', 'own;');
        Observer.Expect('CurrPage.Caption(ByCall): TestPage.Caption', 'ByCall');
        Observer.Expect('CurrPage.Caption(ByCall): ReadByCall', 'ByCall');
        Observer.Expect('CurrPage.Caption(ByCall): Called', 'own;');
        Observer.Expect('Caption(Bare): TestPage.Caption', 'Bare');
        Observer.Expect('Caption(Bare): ReadBare', 'Bare');
        Observer.Expect('Caption(Bare): Called', 'own;');
        Observer.Verify();
    end;

    [Test]
    procedure OwnTextParameter_AssignAndRead_Observed()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "CPC Own Text Parameter";
    begin
        P.OpenView();
        Observer.Observe('open: TestPage.Caption', P.Caption());
        Observer.Observe('open: ReadBefore', P.ReadBefore.Value());
        Observer.Observe('open: ReadBeforeParens', P.ReadBeforeParens.Value());
        Observer.Observe('open: ReadAfter', P.ReadAfter.Value());
        Observer.Observe('open: ReadAfterParens', P.ReadAfterParens.Value());
        Observer.Observe('open: OwnCall', P.OwnCall.Value());
        Observer.Observe('open: Called', P.Called.Value());
        P.CallForm.Invoke();
        Observer.Observe('CurrPage.Caption(ByCall): TestPage.Caption', P.Caption());
        Observer.Observe('CurrPage.Caption(ByCall): ReadByCall', P.ReadByCall.Value());
        Observer.Observe('CurrPage.Caption(ByCall): Called', P.Called.Value());
        P.BareCall.Invoke();
        Observer.Observe('Caption(Bare): TestPage.Caption', P.Caption());
        Observer.Observe('Caption(Bare): ReadBare', P.ReadBare.Value());
        Observer.Observe('Caption(Bare): Called', P.Called.Value());
        P.Close();
        Observer.Expect('open: TestPage.Caption', 'Assigned');
        Observer.Expect('open: ReadBefore', 'Static');
        Observer.Expect('open: ReadBeforeParens', 'Static');
        Observer.Expect('open: ReadAfter', 'Assigned');
        Observer.Expect('open: ReadAfterParens', 'Assigned');
        Observer.Expect('open: OwnCall', '');
        Observer.Expect('open: Called', '');
        Observer.Expect('CurrPage.Caption(ByCall): TestPage.Caption', 'ByCall');
        Observer.Expect('CurrPage.Caption(ByCall): ReadByCall', 'ByCall');
        Observer.Expect('CurrPage.Caption(ByCall): Called', '');
        Observer.Expect('Caption(Bare): TestPage.Caption', 'Bare');
        Observer.Expect('Caption(Bare): ReadBare', 'Bare');
        Observer.Expect('Caption(Bare): Called', '');
        Observer.Verify();
    end;

    [Test]
    procedure OwnSignature_PageVariableCalls_Observed()
    var
        Observer: Codeunit "Probe Observer";
        NoReturn: Page "CPC Own No Return";
        TextParameter: Page "CPC Own Text Parameter";
    begin
        NoReturn.Caption();
        Observer.Observe('no return: called after Caption()', NoReturn.GetCalled());
        TextParameter.Caption('Out');
        Observer.Observe('Text parameter: called after Caption(Out)', TextParameter.GetCalled());
        Observer.Observe('Text parameter: Caption()', TextParameter.Caption());
        Observer.Expect('no return: called after Caption()', 'own;');
        Observer.Expect('Text parameter: called after Caption(Out)', '');
        Observer.Expect('Text parameter: Caption()', 'Out');
        Observer.Verify();
    end;
}
