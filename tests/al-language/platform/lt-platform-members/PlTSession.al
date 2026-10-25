// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunit 74210
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Members: Session.LogMessage (all overloads, Verbosity, DataClassification, TelemetryScope), ApplicationArea (get/set), GlobalLanguage (get/set),
// WindowsLanguage, SessionId / IsSessionActive relations.
// BC versions: 29 (27 and 28 by CI)

codeunit 74210 "LT PlT Session"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryLog(Verb: Verbosity; Class: DataClassification; Scope: TelemetryScope)
    begin
        Session.LogMessage('LTPLT001', 'probe message', Verb, Class, Scope, 'Dim1', 'Val1');
    end;

    local procedure Run(Verb: Verbosity; Class: DataClassification; Scope: TelemetryScope): Text
    begin
        if TryLog(Verb, Class, Scope) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryDict(EventId: Text; Msg: Text; Dim: Dictionary of [Text, Text])
    begin
        Session.LogMessage(EventId, Msg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dim);
    end;

    local procedure RunDict(EventId: Text; Msg: Text; Dim: Dictionary of [Text, Text]): Text
    begin
        if TryDict(EventId, Msg, Dim) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure LogMessage_VerbosityValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('critical', Run(Verbosity::Critical, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher));
        Observer.Observe('error', Run(Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher));
        Observer.Observe('warning', Run(Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher));
        Observer.Observe('normal', Run(Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher));
        Observer.Observe('verbose', Run(Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher));
        Observer.Observe('enum_ints', Format(Verbosity::Critical, 0, 2) + Format(Verbosity::Error, 0, 2) + Format(Verbosity::Warning, 0, 2) + Format(Verbosity::Normal, 0, 2) + Format(Verbosity::Verbose, 0, 2));
        Observer.Expect('critical', 'ok');
        Observer.Expect('error', 'ok');
        Observer.Expect('warning', 'ok');
        Observer.Expect('normal', 'ok');
        Observer.Expect('verbose', 'ok');
        Observer.Expect('enum_ints', '12345');
        Observer.Verify();
    end;

    [Test]
    procedure LogMessage_DataClassificationValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tobeclassified', Run(Verbosity::Normal, DataClassification::ToBeClassified, TelemetryScope::ExtensionPublisher));
        Observer.Observe('customercontent', Run(Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher));
        Observer.Observe('enduseridentifiableinformation', Run(Verbosity::Normal, DataClassification::EndUserIdentifiableInformation, TelemetryScope::ExtensionPublisher));
        Observer.Observe('accountdata', Run(Verbosity::Normal, DataClassification::AccountData, TelemetryScope::ExtensionPublisher));
        Observer.Observe('systemmetadata', Run(Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher));
        Observer.Observe('organizationidentifiableinformation', Run(Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher));
        Observer.Observe('endusepseudonymousidentifiers', Run(Verbosity::Normal, DataClassification::EndUserPseudonymousIdentifiers, TelemetryScope::ExtensionPublisher));
        Observer.Expect('tobeclassified', 'ok');
        Observer.Expect('customercontent', 'ok');
        Observer.Expect('enduseridentifiableinformation', 'ok');
        Observer.Expect('accountdata', 'ok');
        Observer.Expect('systemmetadata', 'ok');
        Observer.Expect('organizationidentifiableinformation', 'ok');
        Observer.Expect('endusepseudonymousidentifiers', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure LogMessage_TelemetryScopeValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('extensionpublisher', Run(Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher));
        Observer.Observe('all', Run(Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All));
        Observer.Observe('all_customercontent', Run(Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::All));
        Observer.Observe('all_enduser', Run(Verbosity::Normal, DataClassification::EndUserIdentifiableInformation, TelemetryScope::All));
        Observer.Observe('enum_ints', Format(TelemetryScope::ExtensionPublisher, 0, 2) + '|' + Format(TelemetryScope::All, 0, 2));
        Observer.Expect('extensionpublisher', 'ok');
        Observer.Expect('all', 'ok');
        Observer.Expect('all_customercontent', 'ok');
        Observer.Expect('all_enduser', 'ok');
        Observer.Expect('enum_ints', '1|2');
        Observer.Verify();
    end;

    [Test]
    procedure LogMessage_DimensionOverloads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Session.LogMessage('LTPLT011', 'one pair', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'D1', 'V1');
        Observer.Observe('one', 'no error');
        Session.LogMessage('LTPLT012', 'two pairs', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'D1', 'V1', 'D2', 'V2');
        Observer.Observe('two', 'no error');
        Observer.Expect('one', 'no error');
        Observer.Expect('two', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure LogMessage_DictionaryOverload()
    var
        Observer: Codeunit "Probe Observer";
        Dim: Dictionary of [Text, Text];
        Many: Dictionary of [Text, Text];
        i: Integer;
    begin
        Observer.Observe('empty_dictionary', RunDict('LTPLT020', 'empty dictionary', Dim));
        Dim.Add('Key1', 'Value1');
        Observer.Observe('one_entry', RunDict('LTPLT021', 'one entry', Dim));
        Dim.Add('Key2', '');
        Observer.Observe('empty_value', RunDict('LTPLT022', 'empty value', Dim));
        for i := 1 to 40 do
            Many.Add('K' + Format(i), 'V' + Format(i));
        Observer.Observe('forty_entries', RunDict('LTPLT023', 'many entries', Many));
        Session.LogMessage('LTPLT024', 'direct dictionary', Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::All, Dim);
        Observer.Observe('direct', 'no error');
        Observer.Expect('empty_dictionary', 'ok');
        Observer.Expect('one_entry', 'ok');
        Observer.Expect('empty_value', 'ok');
        Observer.Expect('forty_entries', 'ok');
        Observer.Expect('direct', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure LogMessage_EdgeTexts()
    var
        Observer: Codeunit "Probe Observer";
        Dim: Dictionary of [Text, Text];
    begin
        Observer.Observe('empty_event_id', RunDict('', 'message', Dim));
        Observer.Observe('empty_message', RunDict('LTPLT030', '', Dim));
        Observer.Observe('both_empty', RunDict('', '', Dim));
        Observer.Observe('long_message', RunDict('LTPLT031', PadStr('', 5000, 'm'), Dim));
        Observer.Observe('long_event_id', RunDict(PadStr('', 300, 'e'), 'message', Dim));
        Observer.Observe('unicode', RunDict('LTPLT032', 'Gr' + 'ü' + 'ße ' + '日本語', Dim));
        Dim.Add('', 'value for empty key');
        Observer.Observe('empty_key', RunDict('LTPLT033', 'empty key', Dim));
        Clear(Dim);
        Dim.Add(PadStr('', 300, 'k'), 'long key');
        Observer.Observe('long_key', RunDict('LTPLT034', 'long key', Dim));
        Clear(Dim);
        Dim.Add('Key', PadStr('', 5000, 'v'));
        Observer.Observe('long_value', RunDict('LTPLT035', 'long value', Dim));
        Observer.Expect('empty_event_id', 'ok');
        Observer.Expect('empty_message', 'ok');
        Observer.Expect('both_empty', 'ok');
        Observer.Expect('long_message', 'ok');
        Observer.Expect('long_event_id', 'ok');
        Observer.Expect('unicode', 'ok');
        Observer.Expect('empty_key', 'ok');
        Observer.Expect('long_key', 'ok');
        Observer.Expect('long_value', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure ApplicationArea_SetAndRestore()
    var
        Observer: Codeunit "Probe Observer";
        Old: Text;
    begin
        Old := ApplicationArea();
        ApplicationArea('#All');
        Observer.Observe('set_all', ApplicationArea());
        ApplicationArea('#Basic');
        Observer.Observe('set_basic', ApplicationArea());
        ApplicationArea('#Basic,#Suite');
        Observer.Observe('set_two', ApplicationArea());
        ApplicationArea('');
        Observer.Observe('set_empty', ApplicationArea());
        ApplicationArea(Old);
        Observer.Observe('restored', Format(ApplicationArea() = Old));
        Observer.Expect('set_all', '#All');
        Observer.Expect('set_basic', '#Basic');
        Observer.Expect('set_two', '#Basic,#Suite');
        Observer.Expect('set_empty', '');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ApplicationArea_SetTwiceAndInvalid()
    var
        Observer: Codeunit "Probe Observer";
        Old: Text;
    begin
        Old := ApplicationArea();
        ApplicationArea('#Suite');
        ApplicationArea('#Basic');
        Observer.Observe('last_wins', ApplicationArea());
        asserterror ApplicationArea('NoSuchArea');
        Observer.ObserveError('af168');
        Observer.Observe('unknown_area', ApplicationArea());
        ApplicationArea(Old);
        Observer.Expect('last_wins', '#Basic');
        Observer.Expect('af168|text', '''NoSuchArea'' is not a valid value for the APPLICATIONAREA function parameter.\\    The value must be a text string that contains one or more application area tags.\    A tag must start with # and can be followed by any combination of letters (Aa-Zz) and numbers (0-9).\    Use a comma to separate multiple tags. Example: #Basic,#Suite');
        Observer.Expect('af168|code', 'Argument');
        Observer.Expect('unknown_area', '#Basic');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalLanguage_SetAndRestore()
    var
        Observer: Codeunit "Probe Observer";
        Old: Integer;
    begin
        Old := GlobalLanguage();
        Observer.Observe('positive', Format(Old > 0));
        GlobalLanguage(1033);
        Observer.Observe('english_us', Format(GlobalLanguage()));
        GlobalLanguage(1031);
        Observer.Observe('german', Format(GlobalLanguage()));
        Observer.Observe('date_text_german', Format(DMY2Date(1, 3, 2020), 0, '<Month Text>'));
        GlobalLanguage(1033);
        Observer.Observe('date_text_english', Format(DMY2Date(1, 3, 2020), 0, '<Month Text>'));
        GlobalLanguage(Old);
        Observer.Observe('restored', Format(GlobalLanguage() = Old));
        Observer.Expect('positive', 'Yes');
        Observer.Expect('english_us', '1033');
        Observer.Expect('german', '1031');
        Observer.Expect('date_text_german', 'März');
        Observer.Expect('date_text_english', 'March');
        Observer.Expect('restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalLanguage_InvalidIds()
    var
        Observer: Codeunit "Probe Observer";
        Old: Integer;
    begin
        Old := GlobalLanguage();
        asserterror GlobalLanguage(0);
        Observer.ObserveError('zero');
        asserterror GlobalLanguage(-1);
        Observer.ObserveError('negative');
        asserterror GlobalLanguage(99999);
        Observer.ObserveError('unknown');
        Observer.Observe('unchanged', Format(GlobalLanguage() = Old));
        GlobalLanguage(Old);
        Observer.Expect('zero|text', '''0'' is not a valid language code. You must specify a locale identifier (LCID) or code in the format of language-country/region, such as en-US, de-DE, or da-DK.');
        Observer.Expect('zero|code', 'NotSupportedLanguage');
        Observer.Expect('negative|text', '''-1'' is not a valid language code. You must specify a locale identifier (LCID) or code in the format of language-country/region, such as en-US, de-DE, or da-DK.');
        Observer.Expect('negative|code', 'NotSupportedLanguage');
        Observer.Expect('unknown|text', '''99999'' is not a valid language code. You must specify a locale identifier (LCID) or code in the format of language-country/region, such as en-US, de-DE, or da-DK.');
        Observer.Expect('unknown|code', 'NotSupportedLanguage');
        Observer.Expect('unchanged', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Language_Relations()
    var
        Observer: Codeunit "Probe Observer";
        Old: Integer;
    begin
        Old := GlobalLanguage();
        Observer.Observe('windows_positive', Format(WindowsLanguage() > 0));
        Observer.Observe('global_twice_equal', Format(GlobalLanguage() = GlobalLanguage()));
        GlobalLanguage(1031);
        Observer.Observe('windows_unchanged_by_global', Format(WindowsLanguage() <> 0));
        GlobalLanguage(Old);
        Observer.Expect('windows_positive', 'Yes');
        Observer.Expect('global_twice_equal', 'Yes');
        Observer.Expect('windows_unchanged_by_global', 'Ja');
        Observer.Verify();
    end;

    [Test]
    procedure SessionId_Relations()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('positive', Format(SessionId() > 0));
        Observer.Observe('twice_equal', Format(SessionId() = SessionId()));
        Observer.Observe('active', Format(Session.IsSessionActive(SessionId())));
        Observer.Observe('active_zero', Format(Session.IsSessionActive(0)));
        Observer.Observe('active_huge', Format(Session.IsSessionActive(2147483647)));
        Observer.Expect('positive', 'Yes');
        Observer.Expect('twice_equal', 'Yes');
        Observer.Expect('active', 'Yes');
        Observer.Expect('active_zero', 'No');
        Observer.Expect('active_huge', 'No');
        Observer.Verify();
    end;

    // Writer SN (2026-10-25, runtime hand-off refuse-platform "GlobalLanguage(0/-1/99999): which positive ids raise NotSupportedLanguage"):
    [TryFunction]
    local procedure TrySetLanguage(Id: Integer)
    begin
        GlobalLanguage(Id);
    end;

    local procedure LanguageOutcome(Id: Integer; Old: Integer): Text
    var
        Now: Integer;
    begin
        ClearLastError();
        if TrySetLanguage(Id) then begin
            Now := GlobalLanguage();
            GlobalLanguage(Old);
            exit('ok ' + Format(Now));
        end;
        exit(GetLastErrorCode() + ' ' + GetLastErrorText());
    end;

    [Test]
    procedure GlobalLanguage_PositiveIds()
    var
        Observer: Codeunit "Probe Observer";
        Old: Integer;
    begin
        Old := GlobalLanguage();
        Observer.Observe('1', LanguageOutcome(1, Old));
        Observer.Observe('9', LanguageOutcome(9, Old));
        Observer.Observe('127', LanguageOutcome(127, Old));
        Observer.Observe('1000', LanguageOutcome(1000, Old));
        Observer.Observe('1030', LanguageOutcome(1030, Old));
        Observer.Observe('1036', LanguageOutcome(1036, Old));
        Observer.Observe('2057', LanguageOutcome(2057, Old));
        Observer.Observe('3082', LanguageOutcome(3082, Old));
        Observer.Observe('4096', LanguageOutcome(4096, Old));
        Observer.Observe('8192', LanguageOutcome(8192, Old));
        Observer.Observe('9999', LanguageOutcome(9999, Old));
        Observer.Observe('32767', LanguageOutcome(32767, Old));
        Observer.Observe('65535', LanguageOutcome(65535, Old));
        Observer.Observe('restored', Format(GlobalLanguage() = Old));
        Observer.Finish();
    end;
}
