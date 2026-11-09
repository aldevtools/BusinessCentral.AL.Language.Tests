// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-loadpackagedata-method
// Scope: in-scope
// Fixtures used: tests/al-language-xapp-a/Y7366XaPackageData.al (tables 94692-94698, install codeunit 94699) with the data files TAB94692 - TAB94698.navxdata, and the
//   log table 94681 of Y88XaPackageData.al; Probe Observer (69160). The fixture app is a dependency of this app, so these probes also read what the install code
//   of a dependency app loaded with NavApp.LoadPackageData.
// Probe (al-runner issues 7366 and 6649): what NavApp.LoadPackageData does with a data file whose column list ends with the column `$systemId` (as the platform
//   writes it), and with column lists that do not match the table.
// BC versions: 27 - 29
codeunit 94710 "LT Y7366 Package Data"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure LogText(Subject: Text): Text
    var
        Log: Record "LT Y88 Pkg Log";
        T: Text;
    begin
        Log.SetRange(Kind, 'sys7366');
        Log.SetRange(Subject, Subject);
        if Log.FindSet() then
            repeat
                T += Log.Subject + ' -> ' + Log.Detail + ';';
            until Log.Next() = 0;
        exit(T);
    end;

    [Test]
    procedure Y7366_Trailing_LoadsRowsAndSystemIds()
    var
        Row: Record "LT Y7366 Sys Trailing";
        Observer: Codeunit "Probe Observer";
        Content: Text;
        T: Text;
    begin
        Observer.Observe('load', LogText('trailing'));
        if Row.FindSet() then
            repeat
                Row.CalcFields(Content);
                Content := '';
                if Row.Content.HasValue() then begin
                    Content := 'blob';
                end;
                T += Format(Row."Entry No.") + '=' + Row.Description + '/' + Content + '/' + Format(Row.SystemId) + ';';
            until Row.Next() = 0;
        Observer.Observe('rows', T);
        Observer.Observe('count', Format(Row.Count()));
        Observer.Finish();
    end;

    local procedure TextRows(var Row: Record "LT Y7366 Sys Fewer"): Text
    var
        T: Text;
    begin
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Row.Description + '/' + Row.Note + '/' + Format(Row.SystemId) + ';';
            until Row.Next() = 0;
        exit(T);
    end;

    [Test]
    procedure Y7366_Fewer_FileOlderThanTable()
    var
        Row: Record "LT Y7366 Sys Fewer";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('load', LogText('fewer'));
        Observer.Observe('rows', TextRows(Row));
        Observer.Finish();
    end;

    [Test]
    procedure Y7366_More_FileNewerThanTable()
    var
        Row: Record "LT Y7366 Sys More";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Observer.Observe('load', LogText('more'));
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Row.Description + '/' + Format(Row.SystemId) + ';';
            until Row.Next() = 0;
        Observer.Observe('rows', T);
        Observer.Finish();
    end;

    [Test]
    procedure Y7366_SameSystemIdInTwoRows()
    var
        Row: Record "LT Y7366 Sys SameId";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Observer.Observe('load', LogText('sameid'));
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Row.Description + '/' + Format(Row.SystemId) + ';';
            until Row.Next() = 0;
        Observer.Observe('rows', T);
        Observer.Finish();
    end;

    [Test]
    procedure Y7366_SystemIdAlreadyInTable()
    var
        Row: Record "LT Y7366 Sys Existing";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Observer.Observe('preinsert', LogText('existing preinsert'));
        Observer.Observe('load', LogText('existing'));
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Row.Description + '/' + Format(Row.SystemId) + ';';
            until Row.Next() = 0;
        Observer.Observe('rows', T);
        Observer.Finish();
    end;

    [Test]
    procedure Y7366_ZeroSystemIdInFile()
    var
        Row: Record "LT Y7366 Sys Zero";
        Observer: Codeunit "Probe Observer";
        Nothing: Guid;
        T: Text;
    begin
        Observer.Observe('load', LogText('zero'));
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Row.Description + '/' + Format(Row.SystemId) + '/' + Format(IsNullGuid(Row.SystemId)) + ';';
            until Row.Next() = 0;
        Observer.Observe('rows', T);
        Observer.Finish();
    end;

    [Test]
    procedure Y7366_LastColumnNotNamedSystemId()
    var
        Row: Record "LT Y7366 Sys OtherName";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Observer.Observe('load', LogText('othername'));
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Row.Description + '/' + Format(Row.SystemId) + ';';
            until Row.Next() = 0;
        Observer.Observe('rows', T);
        Observer.Finish();
    end;
}
