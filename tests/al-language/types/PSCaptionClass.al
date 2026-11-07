// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-captionclasstranslate-method
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// CaptionClassTranslate(Text): area 3 returns the text after the FIRST comma without raising an event ('3,Foo' gives 'Foo', '3,One,Two' gives 'One,Two', '3,' gives ''); a text
// with no comma ('No Comma') and the empty text come back unchanged and raise no event; every other area ('1', '2', 'ZZ', 'PSCC') raises OnResolveCaptionClass of codeunit
// "Caption Class" with (area, the rest after the first comma, the session language): 'ZZ,Text here' comes back UNCHANGED when no subscriber resolves it (areas 1 and 2 are handled by Base Application setup and are not pinned), a subscriber
// that sets Resolved and Caption decides the result ('PSCC,Text here' gives 'resolved:Text here'). The language passed is the session language.
// Fixtures used: self-contained codeunits 69552 (static subscriber) and 69553
// BC versions: 27.5

codeunit 69552 "PS Caption Subscriber"
{
    SingleInstance = true;

    var
        Calls: Text;
        Active: Boolean;

    // The log is written only between Start and Stop, so the OnResolveCaptionClass calls of other test codeunits leave no state here
    // (every test starts it and stops it again).
    procedure Start()
    begin
        Calls := '';
        Active := true;
    end;

    procedure Stop()
    begin
        Calls := '';
        Active := false;
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Calls;
        Calls := '';
        exit(Result);
    end;

    local procedure LanguageText(Language: Integer): Text
    begin
        if Language = GlobalLanguage() then
            exit('session');
        exit(Format(Language));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure OnResolve(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        if Active then
            Calls += 'resolve(' + CaptionArea + '|' + CaptionExpr + '|lang=' + LanguageText(Language) + ')';
        if CaptionArea = 'PSCC' then begin
            Caption := 'resolved:' + CaptionExpr;
            Resolved := true;
        end;
    end;
}

codeunit 69553 "PS Caption Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CaptionClassTranslate_Expressions()
    var
        Subscriber: Codeunit "PS Caption Subscriber";
        Observer: Codeunit "Probe Observer";
    begin
        Subscriber.Start();
        Observer.Observe('area3', CaptionClassTranslate('3,Foo'));
        Observer.Observe('area3_events', Subscriber.Take());
        Observer.Observe('no_comma', CaptionClassTranslate('No Comma'));
        Observer.Observe('no_comma_events', Subscriber.Take());
        Observer.Observe('empty', '[' + CaptionClassTranslate('') + ']');
        Observer.Observe('empty_events', Subscriber.Take());
        Observer.Observe('claimed_area', CaptionClassTranslate('PSCC,Text here'));
        Observer.Observe('claimed_events', Subscriber.Take());
        Observer.Observe('unclaimed_area', CaptionClassTranslate('ZZ,Text here'));
        Observer.Observe('unclaimed_events', Subscriber.Take());
        Observer.Observe('area3_two_commas', CaptionClassTranslate('3,One,Two'));
        Observer.Observe('area3_empty_text', '[' + CaptionClassTranslate('3,') + ']');
        Observer.Expect('area3', 'Foo');
        Observer.Expect('area3_events', '');
        Observer.Expect('no_comma', 'No Comma');
        Observer.Expect('no_comma_events', '');
        Observer.Expect('empty', '[]');
        Observer.Expect('empty_events', '');
        Observer.Expect('claimed_area', 'resolved:Text here');
        Observer.Expect('claimed_events', 'resolve(PSCC|Text here|lang=session)');
        Observer.Expect('unclaimed_area', 'ZZ,Text here');
        Observer.Expect('unclaimed_events', 'resolve(ZZ|Text here|lang=session)');
        Observer.Expect('area3_two_commas', 'One,Two');
        Observer.Expect('area3_empty_text', '[]');
        Observer.Verify();
        Subscriber.Stop();
    end;

    // Corpus issue 670 (writer CY): the docs say CaptionClassTranslate caches per session and SelectLatestVersion clears the cache.
    // The same expression is translated twice, then once more after SelectLatestVersion(); the subscriber log shows whether the
    // OnResolveCaptionClass event ran each time. The expressions are used by no other test.
    [Test]
    procedure CY_CaptionClassTranslate_Cache_And_SelectLatestVersion()
    var
        Subscriber: Codeunit "PS Caption Subscriber";
        Observer: Codeunit "Probe Observer";
    begin
        Subscriber.Start();
        Observer.Observe('first', CaptionClassTranslate('PSCC,CY cache one'));
        Observer.Observe('first_events', Subscriber.Take());
        Observer.Observe('second', CaptionClassTranslate('PSCC,CY cache one'));
        Observer.Observe('second_events', Subscriber.Take());
        Observer.Observe('unclaimed_first', CaptionClassTranslate('ZZ,CY cache two'));
        Observer.Observe('unclaimed_first_events', Subscriber.Take());
        Observer.Observe('unclaimed_second', CaptionClassTranslate('ZZ,CY cache two'));
        Observer.Observe('unclaimed_second_events', Subscriber.Take());
        SelectLatestVersion();
        Observer.Observe('after_select_latest', CaptionClassTranslate('PSCC,CY cache one'));
        Observer.Observe('after_select_latest_events', Subscriber.Take());
        Observer.Expect('first', 'resolved:CY cache one');
        Observer.Expect('first_events', 'resolve(PSCC|CY cache one|lang=session)');
        Observer.Expect('second', 'resolved:CY cache one');
        Observer.Expect('second_events', '');
        Observer.Expect('unclaimed_first', 'ZZ,CY cache two');
        Observer.Expect('unclaimed_first_events', 'resolve(ZZ|CY cache two|lang=session)');
        Observer.Expect('unclaimed_second', 'ZZ,CY cache two');
        Observer.Expect('unclaimed_second_events', '');
        Observer.Expect('after_select_latest', 'resolved:CY cache one');
        Observer.Expect('after_select_latest_events', 'resolve(PSCC|CY cache one|lang=session)');
        Observer.Verify();
        Subscriber.Stop();
    end;
}
