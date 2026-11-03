// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 76000, log 76002 (ZFixtures.al); pages 76010-76016, codeunit 76020
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles corpus issue 616: Page properties AdditionalSearchTermsML, EntityCaption(ML), EntitySetCaption(ML), PromotedActionCategoriesML, PromptMode.
// Facts: what compiles (this file compiles on 27-29), what the Page Metadata table reports for the pages, what a TestPage sees. The properties that cannot
//   be read from AL (captions of the API metadata, search terms, category names) are pinned by compiling and by the unchanged run-time behavior.
//   The combinations the compiler rejects are must-not-compile cases (tests/must-not-compile/cases/0840 and following).
// BC versions: 29 (27 and 28 by CI)

page 76010 "LT Z Search"
{
    PageType = Card;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'LT Z Search caption';
    AdditionalSearchTermsML = ENU = 'alpha,beta', DEU = 'gamma', FRA = 'delta', ESP = 'epsilon';

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}

page 76011 "LT Z Search Terms"
{
    PageType = Card;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;
    AdditionalSearchTerms = 'one,two';

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}

page 76012 "LT Z Api"
{
    PageType = API;
    SourceTable = "LT Z Row";
    APIPublisher = 'ltz';
    APIGroup = 'ltz';
    APIVersion = 'v1.0';
    EntityName = 'ltzRow';
    EntitySetName = 'ltzRows';
    EntityCaption = 'LT Z Row';
    EntitySetCaption = 'LT Z Rows';
    ODataKeyFields = Id;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(id; Rec.Id) { }
                field(name; Rec.Name) { }
            }
        }
    }
}

page 76013 "LT Z Api ML"
{
    PageType = API;
    SourceTable = "LT Z Row";
    APIPublisher = 'ltz';
    APIGroup = 'ltz';
    APIVersion = 'v1.0';
    EntityName = 'ltzRowMl';
    EntitySetName = 'ltzRowsMl';
    EntityCaptionML = ENU = 'LT Z Row', DEU = 'LT Z Zeile';
    EntitySetCaptionML = ENU = 'LT Z Rows', DEU = 'LT Z Zeilen';
    ODataKeyFields = Id;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(id; Rec.Id) { }
                field(name; Rec.Name) { }
            }
        }
    }
}

page 76014 "LT Z Promoted ML"
{
    PageType = Card;
    SourceTable = "LT Z Row";
    ApplicationArea = All;
    UsageCategory = None;
    PromotedActionCategoriesML = ENU = 'One,Two,Three', DEU = 'Eins,Zwei,Drei';

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(A1)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Category4;

                trigger OnAction()
                var
                    Log: Codeunit "LT Z Log";
                begin
                    Log.Add('a1');
                end;
            }
        }
    }
}

page 76015 "LT Z Prompt Prompt"
{
    PageType = PromptDialog;
    Extensible = false;
    PromptMode = Prompt;

    layout { area(Prompt) { field(Nm; Nm) { ApplicationArea = All; } } }

    var
        Nm: Text;
}

page 76016 "LT Z Prompt Content"
{
    PageType = PromptDialog;
    Extensible = false;
    PromptMode = Content;

    layout { area(Content) { field(Nm; Nm) { ApplicationArea = All; } } }

    var
        Nm: Text;
}

page 76017 "LT Z Prompt Generate"
{
    PageType = PromptDialog;
    Extensible = false;
    PromptMode = Generate;

    layout { area(Prompt) { field(Nm; Nm) { ApplicationArea = All; } } }

    var
        Nm: Text;
}

codeunit 76020 "LT Z Page Props Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Meta(PageId: Integer; Prefix: Text)
    var
        PageMeta: Record "Page Metadata";
    begin
        if not PageMeta.Get(PageId) then begin
            Observer.Observe(Prefix + ' meta', 'not found');
            exit;
        end;
        Observer.Observe(Prefix + ' name', PageMeta.Name);
        Observer.Observe(Prefix + ' caption', PageMeta.Caption);
        Observer.Observe(Prefix + ' page type', Format(PageMeta.PageType));
        Observer.Observe(Prefix + ' entity name', PageMeta.EntityName);
        Observer.Observe(Prefix + ' entity set name', PageMeta.EntitySetName);
        Observer.Observe(Prefix + ' api publisher', PageMeta.APIPublisher);
        Observer.Observe(Prefix + ' api group', PageMeta.APIGroup);
        Observer.Observe(Prefix + ' api version', PageMeta.APIVersion);
    end;

    [Test]
    procedure ZSearchTermsML_PageRunsUnchanged()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z Search";
        P2: TestPage "LT Z Search Terms";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Name := 'One';
        R.Insert();
        P.OpenView();
        Observer.Observe('ml name', P.Name.Value());
        Observer.Observe('ml caption', P.Caption());
        Observer.Observe('ml name editable', Format(P.Name.Editable()));
        P.Close();
        P2.OpenView();
        Observer.Observe('plain name', P2.Name.Value());
        P2.Close();
        Meta(Page::"LT Z Search", 'ml');
        Meta(Page::"LT Z Search Terms", 'plain');
        Observer.Expect('ml name', 'One');
        Observer.Expect('ml caption', 'LT Z Search caption - 1');
        Observer.Expect('ml name editable', 'No');
        Observer.Expect('plain name', 'One');
        Observer.Expect('ml name', 'LT Z Search');
        Observer.Expect('ml caption', 'LT Z Search caption');
        Observer.Expect('ml page type', 'Card');
        Observer.Expect('ml entity name', '');
        Observer.Expect('ml entity set name', '');
        Observer.Expect('ml api publisher', '');
        Observer.Expect('ml api group', '');
        Observer.Expect('ml api version', 'beta');
        Observer.Expect('plain name', 'LT Z Search Terms');
        Observer.Expect('plain caption', 'LT Z Search Terms');
        Observer.Expect('plain page type', 'Card');
        Observer.Expect('plain entity name', '');
        Observer.Expect('plain entity set name', '');
        Observer.Expect('plain api publisher', '');
        Observer.Expect('plain api group', '');
        Observer.Expect('plain api version', 'beta');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryOpen(var P: TestPage "LT Z Api")
    begin
        P.OpenView();
        P.Close();
    end;

    [TryFunction]
    local procedure TryOpenMl(var P: TestPage "LT Z Api ML")
    begin
        P.OpenView();
        P.Close();
    end;

    [Test]
    procedure ZApiEntityCaptions_MetadataAndTestPage()
    var
        R: Record "LT Z Row";
        P: TestPage "LT Z Api";
        P2: TestPage "LT Z Api ML";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Name := 'One';
        R.Insert();
        Meta(Page::"LT Z Api", 'api');
        Meta(Page::"LT Z Api ML", 'apiml');
        ClearLastError();
        Observer.Observe('api open ok', Format(TryOpen(P)));
        Observer.ObserveError('api open view');
        Observer.Observe('apiml open ok', Format(TryOpenMl(P2)));
        Observer.ObserveError('apiml open view');
        Observer.Expect('api name', 'LT Z Api');
        Observer.Expect('api caption', 'LT Z Api');
        Observer.Expect('api page type', 'API');
        Observer.Expect('api entity name', 'ltzRow');
        Observer.Expect('api entity set name', 'ltzRows');
        Observer.Expect('api api publisher', 'ltz');
        Observer.Expect('api api group', 'ltz');
        Observer.Expect('api api version', 'v1.0');
        Observer.Expect('apiml name', 'LT Z Api ML');
        Observer.Expect('apiml caption', 'LT Z Api ML');
        Observer.Expect('apiml page type', 'API');
        Observer.Expect('apiml entity name', 'ltzRowMl');
        Observer.Expect('apiml entity set name', 'ltzRowsMl');
        Observer.Expect('apiml api publisher', 'ltz');
        Observer.Expect('apiml api group', 'ltz');
        Observer.Expect('apiml api version', 'v1.0');
        Observer.Expect('api open ok', 'Yes');
        Observer.Expect('api open view|text', '');
        Observer.Expect('api open view|code', '');
        Observer.Expect('apiml open ok', 'Yes');
        Observer.Expect('apiml open view|text', '');
        Observer.Expect('apiml open view|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure ZPromotedActionCategoriesML_ActionUnchanged()
    var
        R: Record "LT Z Row";
        Log: Codeunit "LT Z Log";
        P: TestPage "LT Z Promoted ML";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Insert();
        Log.Take();
        P.OpenView();
        Observer.Observe('visible', Format(P.A1.Visible()));
        Observer.Observe('enabled', Format(P.A1.Enabled()));
        P.A1.Invoke();
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Expect('visible', 'Yes');
        Observer.Expect('enabled', 'Yes');
        Observer.Expect('log', 'a1;');
        Observer.Verify();
    end;

    [Test]
    procedure ZPromptModes_Metadata()
    begin
        Meta(Page::"LT Z Prompt Prompt", 'prompt');
        Meta(Page::"LT Z Prompt Content", 'content');
        Meta(Page::"LT Z Prompt Generate", 'generate');
        Observer.Expect('prompt name', 'LT Z Prompt Prompt');
        Observer.Expect('prompt caption', 'LT Z Prompt Prompt');
        Observer.Expect('prompt page type', '20');
        Observer.Expect('prompt entity name', '');
        Observer.Expect('prompt entity set name', '');
        Observer.Expect('prompt api publisher', '');
        Observer.Expect('prompt api group', '');
        Observer.Expect('prompt api version', 'beta');
        Observer.Expect('content name', 'LT Z Prompt Content');
        Observer.Expect('content caption', 'LT Z Prompt Content');
        Observer.Expect('content page type', '20');
        Observer.Expect('content entity name', '');
        Observer.Expect('content entity set name', '');
        Observer.Expect('content api publisher', '');
        Observer.Expect('content api group', '');
        Observer.Expect('content api version', 'beta');
        Observer.Expect('generate name', 'LT Z Prompt Generate');
        Observer.Expect('generate caption', 'LT Z Prompt Generate');
        Observer.Expect('generate page type', '20');
        Observer.Expect('generate entity name', '');
        Observer.Expect('generate entity set name', '');
        Observer.Expect('generate api publisher', '');
        Observer.Expect('generate api group', '');
        Observer.Expect('generate api version', 'beta');
        Observer.Verify();
    end;
}
