// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope (OnPrem app: Published Application is Scope = OnPrem)
// Fixtures used: Probe Observer (69160); cross-app fixture C (its app.json declares a brief and empty help, url, EULA and privacy statement);
//        self-contained objects 98702, 98705
// Probe: gap cycle 5, spec G5-01 (writer Y48). The Published Application row of the Application app (c1335042-...): its columns, its
//        Package ID and how it relates to the other rows, to NavApp.GetModuleInfo and to AllObjWithCaption (the filter Microsoft's
//        Extension Management and Objects page use); the columns no corpus test read before (10 Package Type, 14 Brief, 16 to 19,
//        36 Resource Exposure Policy, 37, 38 to 41 source and build) for the corpus apps and Microsoft's apps; a Modify of the Application row.
//        Package IDs and versions change per build: only relations are observed, never the values.
//        Not done: the spec's change of a cross-app fixture's app.json (help, url, resourceExposurePolicy, source, build); fixture C is read as it is.
//        Asserted values: the CI containers BC 27.5, 28.5 and 29.0, the same on all three except column 37 of System Application (Yes on 29.0 only).
//        The Application row is an ordinary row: its own Package ID (not Base Application's, no AllObjWithCaption object carries it), the version of
//        Base Application, Published As Global, Resource Exposure Policy 7; a Modify of its Brief succeeds.
// BC versions: 27, 28, 29

codeunit 98705 "LT Y48 PA Modify"
{
    TableNo = "Published Application";

    trigger OnRun()
    begin
        Rec.Brief := 'LT Y48 changed brief';
        Rec.Modify();
    end;
}

codeunit 98702 "LT Y48 Published App"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ApplicationIdTok: Label 'c1335042-3002-4257-bf8a-75c898ccb1b8', Locked = true;
        BaseAppIdTok: Label '437dbf0e-84ff-417a-965d-ed2bb9650972', Locked = true;
        SystemAppIdTok: Label '63ca2fa4-4f03-4f2b-a480-172fef340d3f', Locked = true;
        CloudAppIdTok: Label 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', Locked = true;
        AppCIdTok: Label '0df0fadc-d339-4b0f-a1d5-51dc51f10900', Locked = true;

    local procedure IdOf(IdText: Text) Id: Guid
    begin
        Evaluate(Id, IdText);
    end;

    local procedure RowOf(AppId: Guid; var App: Record "Published Application"): Boolean
    begin
        App.Reset();
        App.SetRange(ID, AppId);
        exit(App.FindFirst());
    end;

    local procedure RowCount(AppId: Guid): Integer
    var
        App: Record "Published Application";
    begin
        App.SetRange(ID, AppId);
        exit(App.Count());
    end;

    local procedure Presence(Value: Text): Text
    begin
        if Value = '' then
            exit('<empty>');
        exit('<value>');
    end;

    // Every normal field as no=value; Guids as null yes/no, Blob/Media/MediaSet by type, the four version parts as v (they change per build,
    // see the version relations), hashes, keys and connection strings as empty/value.
    local procedure Dump(var App: Record "Published Application"): Text
    var
        RecRef: RecordRef;
        FR: FieldRef;
        Index: Integer;
        Result: Text;
        Value: Text;
        G: Guid;
    begin
        RecRef.GetTable(App);
        for Index := 1 to RecRef.FieldCount() do begin
            FR := RecRef.FieldIndex(Index);
            if FR.Class = FieldClass::Normal then begin
                case true of
                    FR.Type in [FieldType::Blob, FieldType::Media, FieldType::MediaSet]:
                        Value := '<' + Format(FR.Type) + '>';
                    FR.Type = FieldType::Guid:
                        begin
                            G := FR.Value;
                            Value := '<guid null=' + Format(IsNullGuid(G)) + '>';
                        end;
                    FR.Number in [6, 7, 8, 9]:
                        Value := 'v';
                    FR.Number in [26, 28, 32, 35]:
                        Value := Presence(Format(FR.Value));
                    else
                        Value := Format(FR.Value);
                end;
                Result += Format(FR.Number) + '=' + Value + ';';
            end;
        end;
        exit(Result);
    end;

    local procedure Columns(var App: Record "Published Application"; MicrosoftApp: Boolean): Text
    var
        SourceBuild: Text;
    begin
        if MicrosoftApp then
            SourceBuild := 'Source Repository Url=' + Presence(App."Source Repository Url") + '|Source Commit ID=' + Presence(App."Source Commit ID") +
                '|Build By=' + Presence(App."Build By") + '|Build Url=' + Presence(App."Build Url")
        else
            SourceBuild := 'Source Repository Url=[' + App."Source Repository Url" + ']|Source Commit ID=[' + App."Source Commit ID" +
                ']|Build By=[' + App."Build By" + ']|Build Url=[' + App."Build Url" + ']';
        exit('Package Type=' + Format(App."Package Type") + '|Published As=' + Format(App."Published As") + '|Help=[' + App.Help + ']|Url=[' + App.Url +
            ']|EULA=[' + App.EULA + ']|Privacy Statement=[' + App."Privacy Statement" + ']|Brief=[' + App.Brief + ']|Resource Exposure Policy=' +
            Format(App."Resource Exposure Policy") + '|Applicable To Dev Extension=' + Format(App."Resource Exposure Policy Applicable To Dev Extension") + '|' + SourceBuild);
    end;

    local procedure SameVersion(var A: Record "Published Application"; var B: Record "Published Application"): Text
    begin
        exit('major=' + Format(A."Version Major" = B."Version Major") + ' minor=' + Format(A."Version Minor" = B."Version Minor") +
            ' build=' + Format(A."Version Build" = B."Version Build") + ' revision=' + Format(A."Version Revision" = B."Version Revision"));
    end;

    [Test]
    procedure PA_ApplicationRow_Columns()
    var
        App: Record "Published Application";
        Base: Record "Published Application";
        Sys: Record "Published Application";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', Format(RowCount(IdOf(ApplicationIdTok))));
        Observer.Observe('found', Format(RowOf(IdOf(ApplicationIdTok), App)));
        Observer.Observe('dump', Dump(App));
        Observer.Observe('name', App.Name);
        Observer.Observe('publisher', App.Publisher);
        Observer.Observe('columns', Columns(App, true));
        Observer.Observe('tenant id', '[' + App."Tenant ID" + ']');
        App.CalcFields(Description, Blob, Symbols, Documentation);
        Observer.Observe('blobs', 'Description=' + Format(App.Description.HasValue()) + ' Blob=' + Format(App.Blob.HasValue()) +
            ' Symbols=' + Format(App.Symbols.HasValue()) + ' Documentation=' + Format(App.Documentation.HasValue()));
        Observer.Observe('version major is a major', Format((App."Version Major" >= 27) and (App."Version Major" <= 40)));
        RowOf(IdOf(BaseAppIdTok), Base);
        RowOf(IdOf(SystemAppIdTok), Sys);
        Observer.Observe('version = base application', SameVersion(App, Base));
        Observer.Observe('version = system application', SameVersion(App, Sys));
        Observer.Expect('rows', '1');
        Observer.Expect('found', 'Yes');
        Observer.Expect('dump', '1=<guid null=No>;2=<guid null=No>;3=<guid null=No>;4=Application;5=Microsoft;6=v;7=v;8=v;9=v;10=Extension;11=Global;12=;14=Application (W1);15=<BLOB>;16=https://go.microsoft.com/fwlink/?LinkId=724009;17=https://go.microsoft.com/fwlink/?linkid=2182906;18=https://go.microsoft.com/fwlink/?LinkId=724011;19=https://go.microsoft.com/fwlink/?linkid=2104024;20=<Media>;21=<MediaSet>;22=<BLOB>;25=<BLOB>;26=<empty>;27=No;28=<value>;29=<guid null=Yes>;32=<empty>;33=<guid null=Yes>;34=<BLOB>;35=<empty>;36=7;37=No;38=;39=;40=;41=;');
        Observer.Expect('name', 'Application');
        Observer.Expect('publisher', 'Microsoft');
        Observer.Expect('columns', 'Package Type=Extension|Published As=Global|Help=[https://go.microsoft.com/fwlink/?linkid=2104024]|Url=[https://go.microsoft.com/fwlink/?LinkId=724011]|EULA=[https://go.microsoft.com/fwlink/?linkid=2182906]|Privacy Statement=[https://go.microsoft.com/fwlink/?LinkId=724009]|Brief=[Application (W1)]|Resource Exposure Policy=7|Applicable To Dev Extension=No|Source Repository Url=<empty>|Source Commit ID=<empty>|Build By=<empty>|Build Url=<empty>');
        Observer.Expect('tenant id', '[]');
        Observer.Expect('blobs', 'Description=Yes Blob=Yes Symbols=Yes Documentation=Yes');
        Observer.Expect('version major is a major', 'Yes');
        Observer.Expect('version = base application', 'major=Yes minor=Yes build=Yes revision=Yes');
        Observer.Expect('version = system application', 'major=Yes minor=Yes build=Yes revision=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PA_ApplicationRow_PackageIds()
    var
        App: Record "Published Application";
        Base: Record "Published Application";
        Sys: Record "Published Application";
        ThisApp: Record "Published Application";
        PA2: Record "Published Application";
        AllObj: Record AllObjWithCaption;
        Observer: Codeunit "Probe Observer";
        MI: ModuleInfo;
        ThisModule: ModuleInfo;
    begin
        RowOf(IdOf(ApplicationIdTok), App);
        RowOf(IdOf(BaseAppIdTok), Base);
        RowOf(IdOf(SystemAppIdTok), Sys);
        NavApp.GetCurrentModuleInfo(ThisModule);
        RowOf(ThisModule.Id(), ThisApp);
        Observer.Observe('package id null', Format(IsNullGuid(App."Package ID")));
        Observer.Observe('runtime package id null', Format(IsNullGuid(App."Runtime Package ID")));
        Observer.Observe('package id = runtime package id', Format(App."Package ID" = App."Runtime Package ID"));
        Observer.Observe('package id = base application', Format(App."Package ID" = Base."Package ID"));
        Observer.Observe('package id = system application', Format(App."Package ID" = Sys."Package ID"));
        Observer.Observe('package id = this app', Format(App."Package ID" = ThisApp."Package ID"));
        Observer.Observe('base: package id = runtime package id', Format(Base."Package ID" = Base."Runtime Package ID"));
        Observer.Observe('this: package id = runtime package id', Format(ThisApp."Package ID" = ThisApp."Runtime Package ID"));

        Observer.Observe('GetModuleInfo(application)', Format(NavApp.GetModuleInfo(IdOf(ApplicationIdTok), MI)));
        Observer.Observe('module info package id = row', Format(MI.PackageId() = App."Package ID"));
        Observer.Observe('module info package id null', Format(IsNullGuid(MI.PackageId())));
        Observer.Observe('module info package id = base application', Format(MI.PackageId() = Base."Package ID"));

        AllObj.SetRange("App Package ID", App."Package ID");
        Observer.Observe('allobj rows with the application package id', Format(AllObj.Count()));
        AllObj.SetRange("App Package ID", Base."Package ID");
        Observer.Observe('allobj rows with the base application package id > 0', Format(AllObj.Count() > 0));

        PA2.SetRange("Package ID", Base."Package ID");
        PA2.SetRange("Tenant Visible", true);
        if PA2.FindFirst() then
            Observer.Observe('package id of base + tenant visible', PA2.Name + ' rows=' + Format(PA2.Count()))
        else
            Observer.Observe('package id of base + tenant visible', 'none');
        PA2.SetRange("Package ID", App."Package ID");
        if PA2.FindFirst() then
            Observer.Observe('package id of application + tenant visible', PA2.Name + ' rows=' + Format(PA2.Count()))
        else
            Observer.Observe('package id of application + tenant visible', 'none');
        PA2.SetRange("Tenant Visible");
        Observer.Observe('package id of application, any visibility', Format(PA2.Count()));

        AllObj.Reset();
        AllObj.Get(AllObj."Object Type"::Table, Database::Customer);
        Observer.Observe('customer: app package id null', Format(IsNullGuid(AllObj."App Package ID")));
        Observer.Observe('customer: app package id = base application', Format(AllObj."App Package ID" = Base."Package ID"));
        PA2.Reset();
        PA2.SetRange("Package ID", AllObj."App Package ID");
        if PA2.FindFirst() then
            Observer.Observe('customer: published application', PA2.Name)
        else
            Observer.Observe('customer: published application', 'none');
        AllObj.Get(AllObj."Object Type"::Table, Database::"Published Application");
        Observer.Observe('published application table: app package id null', Format(IsNullGuid(AllObj."App Package ID")));
        Observer.Observe('published application table: app package id = application', Format(AllObj."App Package ID" = App."Package ID"));
        PA2.SetRange("Package ID", AllObj."App Package ID");
        if PA2.FindFirst() then
            Observer.Observe('published application table: published application', PA2.Name + ' rows=' + Format(PA2.Count()))
        else
            Observer.Observe('published application table: published application', 'none');
        Observer.Expect('package id null', 'No');
        Observer.Expect('runtime package id null', 'No');
        Observer.Expect('package id = runtime package id', 'No');
        Observer.Expect('package id = base application', 'No');
        Observer.Expect('package id = system application', 'No');
        Observer.Expect('package id = this app', 'No');
        Observer.Expect('base: package id = runtime package id', 'No');
        Observer.Expect('this: package id = runtime package id', 'Yes');
        Observer.Expect('GetModuleInfo(application)', 'Yes');
        Observer.Expect('module info package id = row', 'Yes');
        Observer.Expect('module info package id null', 'No');
        Observer.Expect('module info package id = base application', 'No');
        Observer.Expect('allobj rows with the application package id', '0');
        Observer.Expect('allobj rows with the base application package id > 0', 'Yes');
        Observer.Expect('package id of base + tenant visible', 'Base Application rows=1');
        Observer.Expect('package id of application + tenant visible', 'Application rows=1');
        Observer.Expect('package id of application, any visibility', '1');
        Observer.Expect('customer: app package id null', 'No');
        Observer.Expect('customer: app package id = base application', 'Yes');
        Observer.Expect('customer: published application', 'Base Application');
        Observer.Expect('published application table: app package id null', 'No');
        Observer.Expect('published application table: app package id = application', 'No');
        Observer.Expect('published application table: published application', 'none');
        Observer.Verify();
    end;

    [Test]
    procedure PA_ExtensionSettingsColumns_CorpusAndMicrosoftApps()
    var
        App: Record "Published Application";
        Observer: Codeunit "Probe Observer";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        RowOf(ThisModule.Id(), App);
        Observer.Observe('onprem app', Columns(App, false));
        RowOf(IdOf(CloudAppIdTok), App);
        Observer.Observe('cloud coverage app', Columns(App, false));
        RowOf(IdOf(BaseAppIdTok), App);
        Observer.Observe('base application', Columns(App, true));
        RowOf(IdOf(SystemAppIdTok), App);
        Observer.Observe('system application', Columns(App, true));
#if BC29PLUS
        Observer.Expect('onprem app', 'Package Type=Extension|Published As= Dev|Help=[]|Url=[]|EULA=[]|Privacy Statement=[]|Brief=[Executable proof for the AL surface that only a Target = OnPrem app can name at all.]|Resource Exposure Policy=7|Applicable To Dev Extension=No|Source Repository Url=[]|Source Commit ID=[]|Build By=[]|Build Url=[]');
        Observer.Expect('cloud coverage app', 'Package Type=Extension|Published As= Dev|Help=[]|Url=[]|EULA=[]|Privacy Statement=[]|Brief=[Executable proof that the AL language works correctly against a real BC instance.]|Resource Exposure Policy=0|Applicable To Dev Extension=No|Source Repository Url=[]|Source Commit ID=[]|Build By=[]|Build Url=[]');
        Observer.Expect('base application', 'Package Type=Extension|Published As=Global|Help=[https://go.microsoft.com/fwlink/?linkid=2104024]|Url=[https://go.microsoft.com/fwlink/?LinkId=724011]|EULA=[https://go.microsoft.com/fwlink/?linkid=2009120]|Privacy Statement=[https://go.microsoft.com/fwlink/?LinkId=724009]|Brief=[Base Application (W1)]|Resource Exposure Policy=7|Applicable To Dev Extension=No|Source Repository Url=<empty>|Source Commit ID=<empty>|Build By=<empty>|Build Url=<empty>');
        Observer.Expect('system application', 'Package Type=Extension|Published As=Global|Help=[https://go.microsoft.com/fwlink/?linkid=2103698]|Url=[https://go.microsoft.com/fwlink/?linkid=724011]|EULA=[https://go.microsoft.com/fwlink/?linkid=2009120]|Privacy Statement=[https://go.microsoft.com/fwlink/?linkid=724009]|Brief=[Provides a standard set of capabilities that serve as a foundation for developing business apps.]|Resource Exposure Policy=7|Applicable To Dev Extension=Yes|Source Repository Url=<value>|Source Commit ID=<value>|Build By=<empty>|Build Url=<empty>');
#else
        Observer.Expect('onprem app', 'Package Type=Extension|Published As= Dev|Help=[]|Url=[]|EULA=[]|Privacy Statement=[]|Brief=[Executable proof for the AL surface that only a Target = OnPrem app can name at all.]|Resource Exposure Policy=7|Applicable To Dev Extension=No|Source Repository Url=[]|Source Commit ID=[]|Build By=[]|Build Url=[]');
        Observer.Expect('cloud coverage app', 'Package Type=Extension|Published As= Dev|Help=[]|Url=[]|EULA=[]|Privacy Statement=[]|Brief=[Executable proof that the AL language works correctly against a real BC instance.]|Resource Exposure Policy=0|Applicable To Dev Extension=No|Source Repository Url=[]|Source Commit ID=[]|Build By=[]|Build Url=[]');
        Observer.Expect('base application', 'Package Type=Extension|Published As=Global|Help=[https://go.microsoft.com/fwlink/?linkid=2104024]|Url=[https://go.microsoft.com/fwlink/?LinkId=724011]|EULA=[https://go.microsoft.com/fwlink/?linkid=2009120]|Privacy Statement=[https://go.microsoft.com/fwlink/?LinkId=724009]|Brief=[Base Application (W1)]|Resource Exposure Policy=7|Applicable To Dev Extension=No|Source Repository Url=<empty>|Source Commit ID=<empty>|Build By=<empty>|Build Url=<empty>');
        Observer.Expect('system application', 'Package Type=Extension|Published As=Global|Help=[https://go.microsoft.com/fwlink/?linkid=2103698]|Url=[https://go.microsoft.com/fwlink/?linkid=724011]|EULA=[https://go.microsoft.com/fwlink/?linkid=2009120]|Privacy Statement=[https://go.microsoft.com/fwlink/?linkid=724009]|Brief=[Provides a standard set of capabilities that serve as a foundation for developing business apps.]|Resource Exposure Policy=7|Applicable To Dev Extension=No|Source Repository Url=<value>|Source Commit ID=<value>|Build By=<empty>|Build Url=<empty>');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure PA_AppJsonFields_ReachTheRow()
    var
        App: Record "Published Application";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('found', Format(RowOf(IdOf(AppCIdTok), App)));
        Observer.Observe('fixture c', Columns(App, false));
        Observer.Observe('format resource exposure policy', Format(App."Resource Exposure Policy"));
        Observer.Expect('found', 'Yes');
        Observer.Expect('fixture c', 'Package Type=Extension|Published As= Dev|Help=[]|Url=[]|EULA=[]|Privacy Statement=[]|Brief=[Cross-app fixture C: extends a page of cross-app fixture B without depending on the app that declares a type the page uses.]|Resource Exposure Policy=0|Applicable To Dev Extension=No|Source Repository Url=[]|Source Commit ID=[]|Build By=[]|Build Url=[]');
        Observer.Expect('format resource exposure policy', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PA_ApplicationRow_Writes()
    var
        App: Record "Published Application";
        Observer: Codeunit "Probe Observer";
        ThisModule: ModuleInfo;
    begin
        RowOf(IdOf(ApplicationIdTok), App);
        ClearLastError();
        Observer.Observe('modify application row', Format(Codeunit.Run(Codeunit::"LT Y48 PA Modify", App)));
        Observer.ObserveError('modify application row');
        RowOf(IdOf(ApplicationIdTok), App);
        Observer.Observe('application brief after', '[' + App.Brief + ']');
        NavApp.GetCurrentModuleInfo(ThisModule);
        RowOf(ThisModule.Id(), App);
        ClearLastError();
        Observer.Observe('modify this app row', Format(Codeunit.Run(Codeunit::"LT Y48 PA Modify", App)));
        Observer.ObserveError('modify this app row');
        RowOf(ThisModule.Id(), App);
        Observer.Observe('this app brief after', '[' + App.Brief + ']');
        Observer.Expect('modify application row', 'Yes');
        Observer.Expect('modify application row|text', '');
        Observer.Expect('modify application row|code', '');
        Observer.Expect('application brief after', '[LT Y48 changed brief]');
        Observer.Expect('modify this app row', 'Yes');
        Observer.Expect('modify this app row|text', '');
        Observer.Expect('modify this app row|code', '');
        Observer.Expect('this app brief after', '[LT Y48 changed brief]');
        Observer.Verify();
    end;
}
