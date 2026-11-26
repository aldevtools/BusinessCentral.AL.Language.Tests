// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/table/system.globalization.windows-language
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/codeunit/codeunit-company-triggers
// Scope: in-scope
// Fixtures for WlInstallWindowsLanguageTests.al (al-runner issue 9046, provider table 2000000045 "Windows Language" on the codeunit 151 path):
//   what the virtual table "Windows Language" returns while the install session of this app runs.
// local object: the test must read rows that install code wrote in another session.
// No Subtype = Install codeunit (check-install-triggers.py): the install code is two "Extension Triggers" subscribers.
// The "Company Triggers" OnCompanyOpen subscriber reads the table in every session; it notes the read in the SingleInstance "LT WLI State"
//   (no write) and writes a log row only when the execution context is Install or Upgrade. The install subscribers write a row with the same
//   read and the session id, so the test can tell the install session's rows from rows of other sessions.
// The read: Count(); Get of 1033, 1031, 1049 and 1067 (a language with no OEM code page) with Name, Primary CodePage and Language Tag;
//   FindSet over SetRange("Globally Enabled", true) with the number of rows iterated and the sum of their Language ID.
// Every write is `if Insert() then;` into a DataPerCompany = false table; Get is used as `if Get() then`, so nothing here can raise.
// BC versions: 27 - 29

table 96000 "LT WLI Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Kind; Text[40]) { }
        field(3; Company; Text[60]) { }
        field(4; "Session Id"; Integer) { }
        field(5; Context; Text[30]) { }
        field(6; "Read"; Text[1000]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 96001 "LT WLI State"
{
    SingleInstance = true;

    var
        Calls: Text;

    procedure Add(Entry: Text)
    begin
        Calls += Entry + ';';
    end;

    procedure AsText(): Text
    begin
        exit(Calls);
    end;
}

codeunit 96002 "LT WLI Subs"
{
    var
        State: Codeunit "LT WLI State";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpen', '', false, false)]
    local procedure CompanyOpen()
    var
        Read: Text;
    begin
        Read := ReadWindowsLanguage();
        State.Add('OnCompanyOpen|' + Read);
        if Session.GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            Write('OnCompanyOpen', Read);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    begin
        Write('install per company', ReadWindowsLanguage());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    begin
        Write('install per database', ReadWindowsLanguage());
    end;

    procedure ReadWindowsLanguage(): Text
    var
        WindowsLanguage: Record "Windows Language";
        Result: Text;
        Iterated: Integer;
        IdSum: Integer;
    begin
        Result := 'count=' + Format(WindowsLanguage.Count()) + ',';
        Result += GetRow(1033) + GetRow(1031) + GetRow(1049) + GetRow(1067);
        WindowsLanguage.SetRange("Globally Enabled", true);
        if WindowsLanguage.FindSet() then
            repeat
                Iterated += 1;
                IdSum += WindowsLanguage."Language ID";
            until WindowsLanguage.Next() = 0;
        Result += 'globally enabled findset=' + Format(Iterated) + '|' + Format(IdSum);
        exit(Result);
    end;

    local procedure GetRow(LanguageId: Integer): Text
    var
        WindowsLanguage: Record "Windows Language";
    begin
        if not WindowsLanguage.Get(LanguageId) then
            exit(Format(LanguageId) + '=No,');
        exit(Format(LanguageId) + '=Yes|' + WindowsLanguage.Name + '|' + WindowsLanguage."Primary CodePage" + '|' + WindowsLanguage."Language Tag" + ',');
    end;

    local procedure Write(Kind: Text; Read: Text)
    var
        Log: Record "LT WLI Log";
    begin
        Log.Init();
        Log.Kind := CopyStr(Kind, 1, MaxStrLen(Log.Kind));
        Log.Company := CopyStr(CompanyName(), 1, MaxStrLen(Log.Company));
        Log."Session Id" := SessionId();
        Log.Context := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Log.Context));
        Log."Read" := CopyStr(Read, 1, MaxStrLen(Log."Read"));
        if Log.Insert() then;
    end;
}
