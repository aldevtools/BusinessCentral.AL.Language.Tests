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
        field(4; H; Text[30])
        {
            CaptionClass = '3,Lit two';
        }
        field(5; I; Text[30])
        {
            CaptionClass = 'LTY71,two';
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
            field(HCtl; Rec.H) { ApplicationArea = All; }
            field(ICtl; Rec.I) { ApplicationArea = All; }
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
        if not (CaptionExpr in ['3,Lit cap', 'LTY71,expr', '3,Lit two', 'LTY71,two', 'LTY71,x1', 'LTY71,x2', '3,Lit x3']) then
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
        if not (CaptionExpression in ['3,Lit cap', 'LTY71,expr', '3,Lit two', 'LTY71,two', 'LTY71,x1', 'LTY71,x2', '3,Lit x3']) then
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

    local procedure OpenAndRead(Name: Text; SecondPair: Boolean)
    var
        Row: Record "LT Y71 CC Tab";
        Card: TestPage "LT Y71 CC Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Card.OpenView();
        if SecondPair then begin
            Obs.Observe(Name + '|h_caption', Card.HCtl.Caption());
            Obs.Observe(Name + '|i_caption', Card.ICtl.Caption());
        end else begin
            Obs.Observe(Name + '|f_caption', Card.FCtl.Caption());
            Obs.Observe(Name + '|g_caption', Card.GCtl.Caption());
        end;
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
        OpenAndRead('lang_1030', false);
        GlobalLanguage(OriginalLanguage);
        UnbindSubscription(Subs);
        Obs.Expect('lang_1030|f_caption', 'Lit cap');
        Obs.Expect('lang_1030|g_caption', 'res 1030');
        Obs.Expect('lang_1030|log', 'after lang=1030 expr=3,Lit cap caption=Lit cap | translate lang=1030 expr=3,Lit cap in=Lit cap | resolve area=LTY71 expr=expr lang=1030 | after lang=1030 expr=LTY71,expr caption=res 1030 | translate lang=1030 expr=LTY71,expr in=res 1030 | after lang=1030 expr=3,Lit two caption=Lit two | translate lang=1030 expr=3,Lit two in=Lit two | resolve area=LTY71 expr=two lang=1030 | after lang=1030 expr=LTY71,two caption=res 1030 | translate lang=1030 expr=LTY71,two in=res 1030');
        Obs.Verify();
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
        GlobalLanguage(1031);
        OpenAndRead('lang_1031_first', true);
        GlobalLanguage(1036);
        OpenAndRead('lang_1036_second', true);
        GlobalLanguage(1031);
        OpenAndRead('lang_1031_third', true);
        GlobalLanguage(OriginalLanguage);
        UnbindSubscription(Subs);
        Obs.Expect('lang_1031_first|h_caption', 'Lit two');
        Obs.Expect('lang_1031_first|i_caption', 'res 1031');
        Obs.Expect('lang_1031_first|log', 'after lang=1031 expr=3,Lit cap caption=Lit cap | translate lang=1031 expr=3,Lit cap in=Lit cap | resolve area=LTY71 expr=expr lang=1031 | after lang=1031 expr=LTY71,expr caption=res 1031 | translate lang=1031 expr=LTY71,expr in=res 1031 | after lang=1031 expr=3,Lit two caption=Lit two | translate lang=1031 expr=3,Lit two in=Lit two | resolve area=LTY71 expr=two lang=1031 | after lang=1031 expr=LTY71,two caption=res 1031 | translate lang=1031 expr=LTY71,two in=res 1031');
        Obs.Expect('lang_1036_second|h_caption', 'Lit two');
        Obs.Expect('lang_1036_second|i_caption', 'res 1036');
        Obs.Expect('lang_1036_second|log', 'after lang=1036 expr=3,Lit cap caption=Lit cap | translate lang=1036 expr=3,Lit cap in=Lit cap | resolve area=LTY71 expr=expr lang=1036 | after lang=1036 expr=LTY71,expr caption=res 1036 | translate lang=1036 expr=LTY71,expr in=res 1036 | after lang=1036 expr=3,Lit two caption=Lit two | translate lang=1036 expr=3,Lit two in=Lit two | resolve area=LTY71 expr=two lang=1036 | after lang=1036 expr=LTY71,two caption=res 1036 | translate lang=1036 expr=LTY71,two in=res 1036');
        Obs.Expect('lang_1031_third|h_caption', 'Lit two');
        Obs.Expect('lang_1031_third|i_caption', 'res 1031');
        Obs.Expect('lang_1031_third|log', '');
        Obs.Verify();
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
        Obs.Observe('x1_1033', CaptionClassTranslate('LTY71,x1'));
        Obs.Observe('x1_1033|log', Log.Text());
        Log.Reset();
        GlobalLanguage(1030);
        Obs.Observe('x1_1030', CaptionClassTranslate('LTY71,x1'));
        Obs.Observe('x1_1030|log', Log.Text());
        Log.Reset();
        Obs.Observe('x1_1030_again', CaptionClassTranslate('LTY71,x1'));
        Obs.Observe('x1_1030_again|log', Log.Text());
        Log.Reset();
        Obs.Observe('x2_1030', CaptionClassTranslate('LTY71,x2'));
        Obs.Observe('x2_1030|log', Log.Text());
        Log.Reset();
        Obs.Observe('area3_x3', CaptionClassTranslate('3,Lit x3'));
        Obs.Observe('area3_x3|log', Log.Text());
        Log.Reset();
        Obs.Observe('area3_x3_again', CaptionClassTranslate('3,Lit x3'));
        Obs.Observe('area3_x3_again|log', Log.Text());
        GlobalLanguage(OriginalLanguage);
        UnbindSubscription(Subs);
        Obs.Expect('x1_1033', 'res 1033');
        Obs.Expect('x1_1033|log', 'resolve area=LTY71 expr=x1 lang=1033 | after lang=1033 expr=LTY71,x1 caption=res 1033 | translate lang=1033 expr=LTY71,x1 in=res 1033');
        Obs.Expect('x1_1030', 'res 1030');
        Obs.Expect('x1_1030|log', 'resolve area=LTY71 expr=x1 lang=1030 | after lang=1030 expr=LTY71,x1 caption=res 1030 | translate lang=1030 expr=LTY71,x1 in=res 1030');
        Obs.Expect('x1_1030_again', 'res 1030');
        Obs.Expect('x1_1030_again|log', '');
        Obs.Expect('x2_1030', 'res 1030');
        Obs.Expect('x2_1030|log', 'resolve area=LTY71 expr=x2 lang=1030 | after lang=1030 expr=LTY71,x2 caption=res 1030 | translate lang=1030 expr=LTY71,x2 in=res 1030');
        Obs.Expect('area3_x3', 'Lit x3');
        Obs.Expect('area3_x3|log', 'after lang=1030 expr=3,Lit x3 caption=Lit x3 | translate lang=1030 expr=3,Lit x3 in=Lit x3');
        Obs.Expect('area3_x3_again', 'Lit x3');
        Obs.Expect('area3_x3_again|log', '');
        Obs.Verify();
    end;

}
