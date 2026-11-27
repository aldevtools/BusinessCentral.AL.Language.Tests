// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/codeunit/codeunit-company-triggers
// Scope: in-scope
// Fixtures for UlInstallUserLoginTests.al: what the System Application table 9008 "User Login" holds when it is read inside the
//   install session of this app (company-open subscriber and install code), in the current company and through ChangeCompany.
// No Subtype = Install codeunit (check-install-triggers.py): the install code is two "Extension Triggers" subscribers; the
//   "Company Triggers" OnCompanyOpen subscriber reads only when the execution context is Install.
// "User Login" is Access = Internal in the System Application, so every read goes through a RecordRef. Reads run in TryFunctions;
//   the log row is written after the read (no writes inside a TryFunction). Every write is `if Insert() then;` into a
//   DataPerCompany = false table.
// BC versions: 27 - 29

table 76430 "LT UL9 Read"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Kind; Text[40]) { }
        field(3; Company; Text[60]) { }
        field(4; Target; Text[60]) { }
        field(5; "Via ChangeCompany"; Boolean) { }
        field(6; "All Rows"; Text[1000]) { }
        field(7; "User Rows"; Text[1000]) { }
        field(8; "User SID"; Guid) { }
        field(9; Context; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 76431 "LT UL9 Reader"
{
    // Reads "User Login" in the current company and, through ChangeCompany, in every company of the database; one log row per read.
    procedure LogReads(Kind: Text)
    var
        Company: Record Company;
        AllRows: Text;
        UserRows: Text;
    begin
        Read('', false, AllRows, UserRows);
        Write(Kind, CompanyName(), false, AllRows, UserRows);
        if Company.FindSet() then
            repeat
                Read(Company.Name, true, AllRows, UserRows);
                Write(Kind, Company.Name, true, AllRows, UserRows);
            until Company.Next() = 0;
    end;

    // AllRows: the unfiltered table. UserRows: filtered on UserSecurityId(), and the primary key lookup (Get) of UserSecurityId().
    procedure Read(Target: Text; ViaChangeCompany: Boolean; var AllRows: Text; var UserRows: Text)
    begin
        ClearLastError();
        if not TryAllRows(Target, ViaChangeCompany, AllRows) then
            AllRows := 'error: ' + CopyStr(GetLastErrorText(), 1, 200);
        ClearLastError();
        if not TryUserRows(Target, ViaChangeCompany, UserRows) then
            UserRows := 'error: ' + CopyStr(GetLastErrorText(), 1, 200);
    end;

    local procedure OpenTable(var RecRef: RecordRef; Target: Text; ViaChangeCompany: Boolean)
    begin
        RecRef.Open(9008);
        if ViaChangeCompany then
            RecRef.ChangeCompany(Target);
    end;

    [TryFunction]
    local procedure TryAllRows(Target: Text; ViaChangeCompany: Boolean; var Facts: Text)
    var
        RecRef: RecordRef;
    begin
        Facts := '';
        OpenTable(RecRef, Target, ViaChangeCompany);
        Facts := 'isempty=' + Format(RecRef.IsEmpty()) + '|count=' + Bucket(RecRef.Count());
        Facts += '|findfirst=' + FindFirstFacts(RecRef);
        RecRef.Close();
    end;

    [TryFunction]
    local procedure TryUserRows(Target: Text; ViaChangeCompany: Boolean; var Facts: Text)
    var
        RecRef: RecordRef;
        GetRef: RecordRef;
        Found: Boolean;
    begin
        Facts := '';
        OpenTable(RecRef, Target, ViaChangeCompany);
        RecRef.Field(1).SetRange(UserSecurityId());
        Facts := 'isempty=' + Format(RecRef.IsEmpty()) + '|count=' + Bucket(RecRef.Count());
        Facts += '|findfirst=' + FindFirstFacts(RecRef);
        RecRef.Close();
        OpenTable(GetRef, Target, ViaChangeCompany);
        GetRef.Field(1).Value := UserSecurityId();
        Found := GetRef.Find('=');
        Facts += '|get=' + Format(Found);
        if Found then
            Facts += RowFacts(GetRef);
        GetRef.Close();
    end;

    local procedure FindFirstFacts(var RecRef: RecordRef): Text
    begin
        if not RecRef.FindFirst() then
            exit('No');
        exit('Yes' + RowFacts(RecRef));
    end;

    local procedure RowFacts(var RecRef: RecordRef): Text
    var
        Sid: Guid;
        First: Date;
        Penultimate: DateTime;
        Last: DateTime;
    begin
        Sid := RecRef.Field(1).Value();
        First := RecRef.Field(2).Value();
        Penultimate := RecRef.Field(3).Value();
        Last := RecRef.Field(4).Value();
        exit(' (sid blank=' + Format(IsNullGuid(Sid)) + ', sid is current user=' + Format(Sid = UserSecurityId()) +
            ', first login date blank=' + Format(First = 0D) + ', penultimate login blank=' + Format(Penultimate = 0DT) +
            ', last login blank=' + Format(Last = 0DT) + ')');
    end;

    local procedure Bucket(N: Integer): Text
    begin
        if N > 1 then
            exit('more than 1');
        exit(Format(N));
    end;

    local procedure Write(Kind: Text; Target: Text; ViaChangeCompany: Boolean; AllRows: Text; UserRows: Text)
    var
        Log: Record "LT UL9 Read";
    begin
        Log.Init();
        Log.Kind := CopyStr(Kind, 1, MaxStrLen(Log.Kind));
        Log.Company := CopyStr(CompanyName(), 1, MaxStrLen(Log.Company));
        Log.Target := CopyStr(Target, 1, MaxStrLen(Log.Target));
        Log."Via ChangeCompany" := ViaChangeCompany;
        Log."All Rows" := CopyStr(AllRows, 1, MaxStrLen(Log."All Rows"));
        Log."User Rows" := CopyStr(UserRows, 1, MaxStrLen(Log."User Rows"));
        Log."User SID" := UserSecurityId();
        Log.Context := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Log.Context));
        if Log.Insert() then;
    end;
}

codeunit 76432 "LT UL9 Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpen', '', false, false)]
    local procedure CompanyOpen()
    var
        Reader: Codeunit "LT UL9 Reader";
    begin
        if Session.GetExecutionContext() <> ExecutionContext::Install then
            exit;
        Reader.LogReads('company open');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    var
        Reader: Codeunit "LT UL9 Reader";
    begin
        Reader.LogReads('install per company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    var
        Reader: Codeunit "LT UL9 Reader";
    begin
        Reader.LogReads('install per database');
    end;
}
