// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-listresources-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), resource files session/res/greeting.txt, session/res/sub/nested.txt, session/res/ac-sample.json
// Probe: ModuleInfo.ContextSensitiveHelpUrl, EULA, Help, PrivacyStatement and the NavApp resource overloads that take an AppId: GetResource, GetResourceAsJson, GetResourceAsText, ListResources and ListAppsWithPublicResources (BC 29 and later; BC 27 and 28 reject them, see must-not-compile cases 0964 to 0966). Settles #627 items 5 to 13.
// BC versions: 29

#if BC29PLUS
codeunit 77521 "LT AC ModuleInfo Help"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_ModuleInfo_HelpTexts_CurrentApp()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Observer.Observe('name', Info.Name());
        Observer.Observe('context_help', Info.ContextSensitiveHelpUrl());
        Observer.Observe('eula', Info.EULA());
        Observer.Observe('help', Info.Help());
        Observer.Observe('privacy', Info.PrivacyStatement());
        Observer.Expect('name', 'AL Language Coverage Tests');
        Observer.Expect('context_help', '');
        Observer.Expect('eula', '');
        Observer.Expect('help', '');
        Observer.Expect('privacy', '');
        Observer.Verify();
    end;

    [Test]
    procedure AC_ModuleInfo_HelpTexts_SysApp()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        Observer.Observe('found', Format(NavApp.GetModuleInfo('63ca2fa4-4f03-4f2b-a480-172fef340d3f', Info)));
        Observer.Observe('context_help', Info.ContextSensitiveHelpUrl());
        Observer.Observe('eula', Info.EULA());
        Observer.Observe('help', Info.Help());
        Observer.Observe('privacy', Info.PrivacyStatement());
        Observer.Expect('found', 'Yes');
        Observer.Expect('context_help', '');
        Observer.Expect('eula', 'https://go.microsoft.com/fwlink/?linkid=2009120');
        Observer.Expect('help', 'https://go.microsoft.com/fwlink/?linkid=2103698');
        Observer.Expect('privacy', 'https://go.microsoft.com/fwlink/?linkid=724009');
        Observer.Verify();
    end;

    [Test]
    procedure AC_ModuleInfo_HelpTexts_BaseApp()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        Observer.Observe('found', Format(NavApp.GetModuleInfo('437dbf0e-84ff-417a-965d-ed2bb9650972', Info)));
        Observer.Observe('context_help', Info.ContextSensitiveHelpUrl());
        Observer.Observe('eula', Info.EULA());
        Observer.Observe('help', Info.Help());
        Observer.Observe('privacy', Info.PrivacyStatement());
        Observer.Expect('found', 'Yes');
        Observer.Expect('context_help', '');
        Observer.Expect('eula', 'https://go.microsoft.com/fwlink/?linkid=2009120');
        Observer.Expect('help', 'https://go.microsoft.com/fwlink/?linkid=2104024');
        Observer.Expect('privacy', 'https://go.microsoft.com/fwlink/?LinkId=724009');
        Observer.Verify();
    end;

    [Test]
    procedure AC_ModuleInfo_HelpTexts_Fixture()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        Observer.Observe('found', Format(NavApp.GetModuleInfo('f1e2d3c4-b5a6-7890-fedc-ba9876543210', Info)));
        Observer.Observe('context_help', Info.ContextSensitiveHelpUrl());
        Observer.Observe('eula', Info.EULA());
        Observer.Observe('help', Info.Help());
        Observer.Observe('privacy', Info.PrivacyStatement());
        Observer.Expect('found', 'Yes');
        Observer.Expect('context_help', '');
        Observer.Expect('eula', '');
        Observer.Expect('help', '');
        Observer.Expect('privacy', '');
        Observer.Verify();
    end;

    [Test]
    procedure AC_ModuleInfo_Unknown_Found()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        Observer.Observe('found', Format(NavApp.GetModuleInfo('00000000-0000-0000-0000-000000000001', Info)));
        Observer.Expect('found', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AC_ModuleInfo_Unknown_ContextHelp()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        Observer.Observe('context_help', Info.ContextSensitiveHelpUrl());
        Observer.Expect('context_help', '');
        Observer.Verify();
    end;

    [Test]
    procedure AC_ModuleInfo_Unknown_Eula()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        Observer.Observe('eula', Info.EULA());
        Observer.Expect('eula', '');
        Observer.Verify();
    end;

    [Test]
    procedure AC_ModuleInfo_Unknown_Help()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        Observer.Observe('help', Info.Help());
        Observer.Expect('help', '');
        Observer.Verify();
    end;

    [Test]
    procedure AC_ModuleInfo_Unknown_Privacy()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        Observer.Observe('privacy', Info.PrivacyStatement());
        Observer.Expect('privacy', '');
        Observer.Verify();
    end;
}

codeunit 77522 "LT AC NavApp Resources"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_NavApp_GetResource_AppId()
    var
        Observer: Codeunit "Probe Observer";
        Stream: InStream;
    begin
        asserterror NavApp.GetResource('greeting.txt', GetCurrentAppId(), Stream);
        Observer.ObserveError('default_encoding');
        asserterror NavApp.GetResource('greeting.txt', GetCurrentAppId(), Stream, TextEncoding::UTF8);
        Observer.ObserveError('utf8');
        asserterror NavApp.GetResource('sub/nested.txt', GetCurrentAppId(), Stream, TextEncoding::UTF8);
        Observer.ObserveError('nested');
        asserterror NavApp.GetResource('greeting.txt', GetCurrentAppId(), Stream, TextEncoding::UTF16);
        Observer.ObserveError('utf16');
        Observer.Expect('default_encoding|text', 'A resource matching ''greeting.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('default_encoding|code', 'ResourceNotFound');
        Observer.Expect('utf8|text', 'A resource matching ''greeting.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('utf8|code', 'ResourceNotFound');
        Observer.Expect('nested|text', 'A resource matching ''sub/nested.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('nested|code', 'ResourceNotFound');
        Observer.Expect('utf16|text', 'A resource matching ''greeting.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('utf16|code', 'ResourceNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure AC_NavApp_GetResource_AppId_Errors()
    var
        Observer: Codeunit "Probe Observer";
        Stream: InStream;
        Unknown: Guid;
    begin
        Evaluate(Unknown, '00000000-0000-0000-0000-000000000001');
        asserterror NavApp.GetResource('missing.txt', GetCurrentAppId(), Stream);
        Observer.ObserveError('missing_resource');
        asserterror NavApp.GetResource('greeting.txt', Unknown, Stream);
        Observer.ObserveError('unknown_app');
        asserterror NavApp.GetResource('greeting.txt', '63ca2fa4-4f03-4f2b-a480-172fef340d3f', Stream);
        Observer.ObserveError('other_app_not_public');
        asserterror NavApp.GetResource('', GetCurrentAppId(), Stream);
        Observer.ObserveError('empty_name');
        Observer.Expect('missing_resource|text', 'A resource matching ''missing.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('missing_resource|code', 'ResourceNotFound');
        Observer.Expect('unknown_app|text', 'A resource matching ''greeting.txt'' could not be found in app ''00000000-0000-0000-0000-000000000001''.');
        Observer.Expect('unknown_app|code', 'ResourceNotFound');
        Observer.Expect('other_app_not_public|text', 'A resource matching ''greeting.txt'' could not be found in app ''63ca2fa4-4f03-4f2b-a480-172fef340d3f''.');
        Observer.Expect('other_app_not_public|code', 'ResourceNotFound');
        Observer.Expect('empty_name|text', 'A resource matching '''' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('empty_name|code', 'ResourceNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure AC_NavApp_GetResourceAsJson_AppId()
    var
        Observer: Codeunit "Probe Observer";
        Json: JsonObject;
        Unknown: Guid;
    begin
        asserterror Json := NavApp.GetResourceAsJson('ac-sample.json', GetCurrentAppId());
        Observer.ObserveError('content');
        asserterror Json := NavApp.GetResourceAsJson('ac-sample.json', GetCurrentAppId(), TextEncoding::UTF8);
        Observer.ObserveError('utf8');
        asserterror Json := NavApp.GetResourceAsJson('greeting.txt', GetCurrentAppId());
        Observer.ObserveError('not_json');
        asserterror Json := NavApp.GetResourceAsJson('missing.json', GetCurrentAppId());
        Observer.ObserveError('missing');
        Evaluate(Unknown, '00000000-0000-0000-0000-000000000001');
        asserterror Json := NavApp.GetResourceAsJson('ac-sample.json', Unknown);
        Observer.ObserveError('unknown_app');
        Observer.Expect('content|text', 'A resource matching ''ac-sample.json'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('content|code', 'ResourceNotFound');
        Observer.Expect('utf8|text', 'A resource matching ''ac-sample.json'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('utf8|code', 'ResourceNotFound');
        Observer.Expect('not_json|text', 'A resource matching ''greeting.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('not_json|code', 'ResourceNotFound');
        Observer.Expect('missing|text', 'A resource matching ''missing.json'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('missing|code', 'ResourceNotFound');
        Observer.Expect('unknown_app|text', 'A resource matching ''ac-sample.json'' could not be found in app ''00000000-0000-0000-0000-000000000001''.');
        Observer.Expect('unknown_app|code', 'ResourceNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure AC_NavApp_GetResourceAsText_AppId()
    var
        Observer: Codeunit "Probe Observer";
        Unknown: Guid;
        Content: Text;
    begin
        asserterror Content := NavApp.GetResourceAsText('greeting.txt', GetCurrentAppId());
        Observer.ObserveError('default');
        asserterror Content := NavApp.GetResourceAsText('greeting.txt', GetCurrentAppId(), TextEncoding::UTF8);
        Observer.ObserveError('utf8');
        asserterror Content := NavApp.GetResourceAsText('greeting.txt', GetCurrentAppId(), TextEncoding::UTF16);
        Observer.ObserveError('utf16');
        asserterror Content := NavApp.GetResourceAsText('greeting.txt', GetCurrentAppId(), TextEncoding::MSDos);
        Observer.ObserveError('msdos');
        asserterror Content := NavApp.GetResourceAsText('greeting.txt', GetCurrentAppId(), TextEncoding::Windows);
        Observer.ObserveError('windows');
        asserterror Content := NavApp.GetResourceAsText('sub/nested.txt', GetCurrentAppId());
        Observer.ObserveError('nested');
        asserterror Content := NavApp.GetResourceAsText('missing.txt', GetCurrentAppId());
        Observer.ObserveError('missing');
        Evaluate(Unknown, '00000000-0000-0000-0000-000000000001');
        asserterror Content := NavApp.GetResourceAsText('greeting.txt', Unknown);
        Observer.ObserveError('unknown_app');
        Observer.Expect('default|text', 'A resource matching ''greeting.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('default|code', 'ResourceNotFound');
        Observer.Expect('utf8|text', 'A resource matching ''greeting.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('utf8|code', 'ResourceNotFound');
        Observer.Expect('utf16|text', 'A resource matching ''greeting.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('utf16|code', 'ResourceNotFound');
        Observer.Expect('msdos|text', 'A resource matching ''greeting.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('msdos|code', 'ResourceNotFound');
        Observer.Expect('windows|text', 'A resource matching ''greeting.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('windows|code', 'ResourceNotFound');
        Observer.Expect('nested|text', 'A resource matching ''sub/nested.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('nested|code', 'ResourceNotFound');
        Observer.Expect('missing|text', 'A resource matching ''missing.txt'' could not be found in app ''a1b2c3d4-e5f6-7890-abcd-ef1234567890''.');
        Observer.Expect('missing|code', 'ResourceNotFound');
        Observer.Expect('unknown_app|text', 'A resource matching ''greeting.txt'' could not be found in app ''00000000-0000-0000-0000-000000000001''.');
        Observer.Expect('unknown_app|code', 'ResourceNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure AC_NavApp_ListResources_AppId()
    var
        Observer: Codeunit "Probe Observer";
        Names: List of [Text];
        Name: Text;
        Joined: Text;
        Unknown: Guid;
    begin
        Names := NavApp.ListResources(GetCurrentAppId());
        
        
        foreach Name in Names do
            Joined += '[' + Name + ']';
        Observer.Observe('all', Joined);
        Observer.Observe('all_count', Format(Names.Count()));
        Clear(Joined);
        Names := NavApp.ListResources(GetCurrentAppId(), '*.txt');
        foreach Name in Names do
            Joined += '[' + Name + ']';
        Observer.Observe('txt', Joined);
        Clear(Joined);
        Names := NavApp.ListResources(GetCurrentAppId(), '*.json');
        foreach Name in Names do
            Joined += '[' + Name + ']';
        Observer.Observe('json', Joined);
        Clear(Joined);
        Names := NavApp.ListResources(GetCurrentAppId(), 'sub/*');
        foreach Name in Names do
            Joined += '[' + Name + ']';
        Observer.Observe('sub', Joined);
        Clear(Joined);
        Names := NavApp.ListResources(GetCurrentAppId(), '*.xyz');
        Observer.Observe('no_match_count', Format(Names.Count()));
        Evaluate(Unknown, '00000000-0000-0000-0000-000000000001');
        if TryList(Unknown, Names) then
            Observer.Observe('unknown_app', Format(Names.Count()))
        else
            Observer.ObserveError('unknown_app');
        if TryList('63ca2fa4-4f03-4f2b-a480-172fef340d3f', Names) then
            Observer.Observe('system_application', Format(Names.Count()))
        else
            Observer.ObserveError('system_application');
        Observer.Expect('all', '');
        Observer.Expect('all_count', '0');
        Observer.Expect('txt', '');
        Observer.Expect('json', '');
        Observer.Expect('sub', '');
        Observer.Expect('no_match_count', '0');
        Observer.Expect('unknown_app', '0');
        Observer.Expect('system_application', '0');
        Observer.Verify();
    end;

    [Test]
    procedure AC_NavApp_ListAppsWithPublicResources()
    var
        Observer: Codeunit "Probe Observer";
        Apps: List of [Guid];
        AppId: Guid;
        Joined: Text;
    begin
        Apps := NavApp.ListAppsWithPublicResources();
        foreach AppId in Apps do
            Joined += '[' + Format(AppId) + ']';
        Observer.Observe('all', Joined);
        Observer.Observe('all_count', Format(Apps.Count()));
        Observer.Observe('contains_self', Format(Apps.Contains(GetCurrentAppId())));
        Clear(Joined);
        Apps := NavApp.ListAppsWithPublicResources('*.json');
        foreach AppId in Apps do
            Joined += '[' + Format(AppId) + ']';
        Observer.Observe('json', Joined);
        Clear(Joined);
        Apps := NavApp.ListAppsWithPublicResources('*.xyz');
        foreach AppId in Apps do
            Joined += '[' + Format(AppId) + ']';
        Observer.Observe('xyz', Joined);
        Observer.Expect('all', '');
        Observer.Expect('all_count', '0');
        Observer.Expect('contains_self', 'No');
        Observer.Expect('json', '');
        Observer.Expect('xyz', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryList(AppId: Guid; var Names: List of [Text])
    begin
        Names := NavApp.ListResources(AppId);
    end;

    local procedure GetCurrentAppId(): Guid
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Id());
    end;
}
#endif
