// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-caption-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: Probe Observer (codeunit 69160); pages 75420 to 75422, page extensions 75410 to 75412, codeunit 75414 (tests)
// Probe: a procedure named Caption and the CurrPage.Caption assignment and reads split between a page and its page extension (al-runner 8193, 8444, PR 8439): own Caption(): Text in the base page with the code in the extension; own Caption(): Text in the extension with the code in the base page; both in the extension.
// OnOpenPage (of the base page or of the extension) reads CurrPage.Caption and CurrPage.Caption(), assigns CurrPage.Caption := 'Assigned', reads
// both forms again and stores the unqualified Caption() (OwnCall). Every page has Caption = 'Static'.
// BC versions: OBSERVATION FORM (not yet measured)

// local object: base page with its own Caption(): Text; the extension holds the code.
page 75420 "CPC Base Own Caption"
{
    PageType = Card;
    Caption = 'Static';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Marker; Marker) { ApplicationArea = All; }
        }
    }

    var
        Marker: Text;

    procedure Caption(): Text
    begin
        exit('Own');
    end;
}

pageextension 75410 "CPC Ext Code" extends "CPC Base Own Caption"
{
    layout
    {
        addlast(Content)
        {
            field(ReadBefore; ReadBefore) { ApplicationArea = All; }
            field(ReadBeforeParens; ReadBeforeParens) { ApplicationArea = All; }
            field(ReadAfter; ReadAfter) { ApplicationArea = All; }
            field(ReadAfterParens; ReadAfterParens) { ApplicationArea = All; }
            field(OwnCall; OwnCall) { ApplicationArea = All; }
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
}

// local object: base page with the code; the extension declares Caption(): Text.
page 75421 "CPC Base Code"
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
}

pageextension 75411 "CPC Ext Own Caption" extends "CPC Base Code"
{
    procedure Caption(): Text
    begin
        exit('ExtOwn');
    end;
}

// local object: plain base page; the extension declares Caption(): Text and holds the code.
page 75422 "CPC Base Plain"
{
    PageType = Card;
    Caption = 'Static';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Marker; Marker) { ApplicationArea = All; }
        }
    }

    var
        Marker: Text;
}

pageextension 75412 "CPC Ext Own Caption And Code" extends "CPC Base Plain"
{
    layout
    {
        addlast(Content)
        {
            field(ReadBefore; ReadBefore) { ApplicationArea = All; }
            field(ReadBeforeParens; ReadBeforeParens) { ApplicationArea = All; }
            field(ReadAfter; ReadAfter) { ApplicationArea = All; }
            field(ReadAfterParens; ReadAfterParens) { ApplicationArea = All; }
            field(OwnCall; OwnCall) { ApplicationArea = All; }
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

    procedure Caption(): Text
    begin
        exit('ExtOwn');
    end;
}

codeunit 75414 "CPC Own Caption Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OwnInBaseCodeInExtension_AssignAndRead_Observed()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "CPC Base Own Caption";
    begin
        P.OpenView();
        Observer.Observe('open: TestPage.Caption', P.Caption());
        Observer.Observe('open: ReadBefore', P.ReadBefore.Value());
        Observer.Observe('open: ReadBeforeParens', P.ReadBeforeParens.Value());
        Observer.Observe('open: ReadAfter', P.ReadAfter.Value());
        Observer.Observe('open: ReadAfterParens', P.ReadAfterParens.Value());
        Observer.Observe('open: OwnCall', P.OwnCall.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CodeInBaseOwnInExtension_AssignAndRead_Observed()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "CPC Base Code";
    begin
        P.OpenView();
        Observer.Observe('open: TestPage.Caption', P.Caption());
        Observer.Observe('open: ReadBefore', P.ReadBefore.Value());
        Observer.Observe('open: ReadBeforeParens', P.ReadBeforeParens.Value());
        Observer.Observe('open: ReadAfter', P.ReadAfter.Value());
        Observer.Observe('open: ReadAfterParens', P.ReadAfterParens.Value());
        Observer.Observe('open: OwnCall', P.OwnCall.Value());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure OwnAndCodeInExtension_AssignAndRead_Observed()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "CPC Base Plain";
    begin
        P.OpenView();
        Observer.Observe('open: TestPage.Caption', P.Caption());
        Observer.Observe('open: ReadBefore', P.ReadBefore.Value());
        Observer.Observe('open: ReadBeforeParens', P.ReadBeforeParens.Value());
        Observer.Observe('open: ReadAfter', P.ReadAfter.Value());
        Observer.Observe('open: ReadAfterParens', P.ReadAfterParens.Value());
        Observer.Observe('open: OwnCall', P.OwnCall.Value());
        P.Close();
        Observer.Finish();
    end;
}
