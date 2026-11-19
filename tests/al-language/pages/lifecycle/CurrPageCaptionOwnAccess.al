// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-caption-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Probe Observer (codeunit 69160); pages 75413 to 75415, codeunit 75411 (tests)
// Probe: the same cells as CurrPageCaptionOwnPublic.al on pages whose own Caption(): Text is local, protected or internal (al-runner 8193, 8444, PR 8439).
// Every page has Caption = 'Static'. OnOpenPage reads CurrPage.Caption and CurrPage.Caption() (ReadBefore, ReadBeforeParens), assigns
// CurrPage.Caption := 'Assigned', reads both forms again (ReadAfter, ReadAfterParens) and calls the unqualified Caption() where it returns a
// value (OwnCall) or as a statement. Action CallForm runs CurrPage.Caption('ByCall'), action BareCall runs the unqualified Caption('Bare');
// each then reads CurrPage.Caption. Called records the calls of the own procedure. The test reads TestPage.Caption and the stored values.
// Compile facts (alc 16, 17, 18 and 30): a read of CurrPage.Caption or CurrPage.Caption() is Text whatever the own procedure returns
// (must-not-compile 3211, 3212); CurrPage.Caption := 'Assigned' compiles beside every own Caption shape, also beside Caption(): Integer;
// the bare Caption := 'X' beside an own parameterless Caption is AL0129 (3210); an unqualified Caption() calls the own procedure (3213, 3214),
// and so does P.Caption() on a Page variable (3215).
// BC versions: OBSERVATION FORM (not yet measured)

// local object: a page that declares its own procedure named Caption (local procedure Caption(): Text).
page 75413 "CPC Own Local Text"
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
        OwnCall := Caption();
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

    local procedure Caption(): Text
    begin
        exit('Own');
    end;
}

// local object: a page that declares its own procedure named Caption (protected procedure Caption(): Text).
page 75414 "CPC Own Protected Text"
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
        OwnCall := Caption();
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

    protected procedure Caption(): Text
    begin
        exit('Own');
    end;
}

// local object: a page that declares its own procedure named Caption (internal procedure Caption(): Text).
page 75415 "CPC Own Internal Text"
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
        OwnCall := Caption();
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

    internal procedure Caption(): Text
    begin
        exit('Own');
    end;
}

codeunit 75411 "CPC Own Access Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OwnLocalText_AssignAndRead_Observed()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "CPC Own Local Text";
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
        Observer.Finish();
    end;

    [Test]
    procedure OwnProtectedText_AssignAndRead_Observed()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "CPC Own Protected Text";
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
        Observer.Finish();
    end;

    [Test]
    procedure OwnInternalText_AssignAndRead_Observed()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "CPC Own Internal Text";
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
        Observer.Finish();
    end;

    [Test]
    procedure OwnInternal_PageVariableCall_Observed()
    var
        Observer: Codeunit "Probe Observer";
        OwnInternal: Page "CPC Own Internal Text";
    begin
        Observer.Observe('own internal: Caption()', OwnInternal.Caption());
        Observer.Finish();
    end;
}
