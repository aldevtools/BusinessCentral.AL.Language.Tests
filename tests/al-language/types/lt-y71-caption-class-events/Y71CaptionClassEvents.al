// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93830, card page 93831, log 93832, subscribers 93833, test codeunit 93834 (writer Y71, gap cycle 7 spec G7-08b)
// Probe: the events a CaptionClass raises when the session language changes in the test: the platform event UI Helper Triggers.CaptionClassTranslate
//        and the System Application events Caption Class.OnResolveCaptionClass and OnAfterCaptionClassResolve (which the System Application's own
//        subscriber of CaptionClassTranslate raises). Fields with the CaptionClass '3,Lit cap' (area 3, resolved without a subscriber) and 'LTY71,expr'
//        (an area a test subscriber claims) on a card page, opened after GlobalLanguage(1030), opened twice with a language change between, and
//        the statement CaptionClassTranslate('LTY71,x') twice with a language change between.
//        Per step: the log of every event (name, Language as a number, expression, caption) and the captions the TestPage reads.
//        Already pinned nearby: events/lt-global-triggers-statements/P114GlobalTriggerEvents.al (CaptionClassTranslate raised for every caption
//        class, area 3 included, Language = the session language), types/PSCaptionClass.al.

table 93830 "LT Y71 CC Tab"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; F; Text[30])
        {
            CaptionClass = '3,Lit cap';
        }
        field(3; G; Text[30])
        {
            CaptionClass = 'LTY71,expr';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 93831 "LT Y71 CC Card"
{
    PageType = Card;
    SourceTable = "LT Y71 CC Tab";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(FCtl; Rec.F) { ApplicationArea = All; }
            field(GCtl; Rec.G) { ApplicationArea = All; }
        }
    }
}

codeunit 93832 "LT Y71 CC Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        if Lines <> '' then
            Lines += ' | ';
        Lines += Line;
    end;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Text(): Text
    begin
        exit(Lines);
    end;
}

codeunit 93833 "LT Y71 CC Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'CaptionClassTranslate', '', false, false)]
    local procedure OnTranslate(Language: Integer; CaptionExpr: Text[1024]; var Translation: Text[1024])
    var
        Log: Codeunit "LT Y71 CC Log";
    begin
        if not (CaptionExpr in ['3,Lit cap', 'LTY71,expr', 'LTY71,x']) then
            exit;
        Log.Add(StrSubstNo('translate lang=%1 expr=%2 in=%3', Language, CaptionExpr, Translation));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', false, false)]
    local procedure OnResolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    var
        Log: Codeunit "LT Y71 CC Log";
    begin
        if CaptionArea <> 'LTY71' then
            exit;
        Log.Add(StrSubstNo('resolve area=%1 expr=%2 lang=%3', CaptionArea, CaptionExpr, Language));
        Caption := 'res ' + Format(Language);
        Resolved := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnAfterCaptionClassResolve', '', false, false)]
    local procedure OnAfter(Language: Integer; CaptionExpression: Text; var Caption: Text[1024])
    var
        Log: Codeunit "LT Y71 CC Log";
    begin
        if not (CaptionExpression in ['3,Lit cap', 'LTY71,expr', 'LTY71,x']) then
            exit;
        Log.Add(StrSubstNo('after lang=%1 expr=%2 caption=%3', Language, CaptionExpression, Caption));
    end;
}

codeunit 93834 "LT Y71 Caption Class Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Log: Codeunit "LT Y71 CC Log";

    local procedure OpenAndRead(Name: Text)
    var
        Row: Record "LT Y71 CC Tab";
        Card: TestPage "LT Y71 CC Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Card.OpenView();
        Obs.Observe(Name + '|f_caption', Card.FCtl.Caption());
        Obs.Observe(Name + '|g_caption', Card.GCtl.Caption());
        Card.Close();
        Obs.Observe(Name + '|log', Log.Text());
        Log.Reset();
    end;

    [Test]
    procedure CaptionClass_AfterGlobalLanguage1030()
    var
        Subs: Codeunit "LT Y71 CC Subs";
        OriginalLanguage: Integer;
    begin
        OriginalLanguage := GlobalLanguage();
        Log.Reset();
        BindSubscription(Subs);
        GlobalLanguage(1030);
        OpenAndRead('lang_1030');
        GlobalLanguage(OriginalLanguage);
        UnbindSubscription(Subs);
        Obs.Finish();
    end;

    [Test]
    procedure CaptionClass_LanguageChangedBetweenOpens()
    var
        Subs: Codeunit "LT Y71 CC Subs";
        OriginalLanguage: Integer;
    begin
        OriginalLanguage := GlobalLanguage();
        Log.Reset();
        BindSubscription(Subs);
        GlobalLanguage(1033);
        OpenAndRead('lang_1033_first');
        GlobalLanguage(1030);
        OpenAndRead('lang_1030_second');
        GlobalLanguage(1033);
        OpenAndRead('lang_1033_third');
        GlobalLanguage(OriginalLanguage);
        UnbindSubscription(Subs);
        Obs.Finish();
    end;

    [Test]
    procedure CaptionClassTranslate_Statement_AfterLanguageChange()
    var
        Subs: Codeunit "LT Y71 CC Subs";
        OriginalLanguage: Integer;
    begin
        OriginalLanguage := GlobalLanguage();
        Log.Reset();
        BindSubscription(Subs);
        GlobalLanguage(1033);
        Obs.Observe('first', CaptionClassTranslate('LTY71,x'));
        Obs.Observe('first|log', Log.Text());
        Log.Reset();
        GlobalLanguage(1030);
        Obs.Observe('second', CaptionClassTranslate('LTY71,x'));
        Obs.Observe('second|log', Log.Text());
        Log.Reset();
        Obs.Observe('second_again', CaptionClassTranslate('LTY71,x'));
        Obs.Observe('second_again|log', Log.Text());
        Log.Reset();
        Obs.Observe('area3', CaptionClassTranslate('3,Lit cap'));
        Obs.Observe('area3|log', Log.Text());
        GlobalLanguage(OriginalLanguage);
        UnbindSubscription(Subs);
        Obs.Finish();
    end;
}
