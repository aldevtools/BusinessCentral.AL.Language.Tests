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
// The extra read (ReadWindowsLanguageExtra, the "Extra" field): a checksum over every field of every row (RecordRef, FieldIndex 1 to FieldCount, so all
//   columns, not the ones the fixed read names), a Get of language id 99999 and a Get of 0 (no such row), and Count() under a filter on another field
//   ("Primary CodePage" = '1' and "Language Tag" = 'hy-AM'). It follows Stefan Maron's note on corpus PR 1609 (the first read covers four rows and four columns).
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
        field(7; Extra; Text[500]) { }
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
            Write('OnCompanyOpen', Read, ReadWindowsLanguageExtra());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    begin
        Write('install per company', ReadWindowsLanguage(), ReadWindowsLanguageExtra());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    begin
        Write('install per database', ReadWindowsLanguage(), ReadWindowsLanguageExtra());
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

    procedure ReadWindowsLanguageExtra(): Text
    var
        WindowsLanguage: Record "Windows Language";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        I: Integer;
        Rows: Integer;
        Checksum: BigInteger;
        FieldCountOfTable: Integer;
        CodePageOne: Integer;
        TagOne: Integer;
    begin
        RecRef.Open(Database::"Windows Language");
        FieldCountOfTable := RecRef.FieldCount();
        if RecRef.FindSet() then
            repeat
                Rows += 1;
                for I := 1 to FieldCountOfTable do begin
                    FieldRef := RecRef.FieldIndex(I);
                    Hash(Format(FieldRef.Value) + '|', Checksum);
                end;
                Hash(';', Checksum);
            until RecRef.Next() = 0;
        RecRef.Close();
        WindowsLanguage.SetRange("Primary CodePage", '1');
        CodePageOne := WindowsLanguage.Count();
        WindowsLanguage.Reset();
        WindowsLanguage.SetRange("Language Tag", 'hy-AM');
        TagOne := WindowsLanguage.Count();
        exit('rows=' + Format(Rows) + ',fields=' + Format(FieldCountOfTable) + ',checksum=' + Format(Checksum) + ',' +
            GetRow(99999) + GetRow(0) + 'codepage 1 count=' + Format(CodePageOne) + ',tag hy-AM count=' + Format(TagOne));
    end;

    local procedure Hash(Value: Text; var State: BigInteger)
    var
        Ch: Char;
        I: Integer;
        Code: Integer;
    begin
        for I := 1 to StrLen(Value) do begin
            Ch := Value[I];
            Code := Ch;
            State := (State * 31 + Code) mod 2147483629;
        end;
    end;

    local procedure GetRow(LanguageId: Integer): Text
    var
        WindowsLanguage: Record "Windows Language";
    begin
        if not WindowsLanguage.Get(LanguageId) then
            exit(Format(LanguageId) + '=No,');
        exit(Format(LanguageId) + '=Yes|' + WindowsLanguage.Name + '|' + WindowsLanguage."Primary CodePage" + '|' + WindowsLanguage."Language Tag" + ',');
    end;

    local procedure Write(Kind: Text; Read: Text; Extra: Text)
    var
        Log: Record "LT WLI Log";
    begin
        Log.Init();
        Log.Kind := CopyStr(Kind, 1, MaxStrLen(Log.Kind));
        Log.Company := CopyStr(CompanyName(), 1, MaxStrLen(Log.Company));
        Log."Session Id" := SessionId();
        Log.Context := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Log.Context));
        Log."Read" := CopyStr(Read, 1, MaxStrLen(Log."Read"));
        Log.Extra := CopyStr(Extra, 1, MaxStrLen(Log.Extra));
        if Log.Insert() then;
    end;
}
