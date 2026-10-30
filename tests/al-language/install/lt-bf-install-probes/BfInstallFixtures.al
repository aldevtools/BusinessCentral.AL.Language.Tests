// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Probe: corpus issue 661 (writer BF), the install code of this app. Two "Extension Triggers" subscriber codeunits and one install codeunit log every
//   install call into "LT BF Install Log" (no company). Their ids and names are chosen so the order of the rows tells the rules apart:
//     81253 "LT BF Z Subs"        subscriber, lowest id, name sorts last
//     81254 "LT BF Install Late"  install codeunit, id between the two subscribers (all other install codeunits of this app have ids below 69851)
//     81255 "LT BF A Subs"        subscriber, highest id, name sorts first
//   Each row holds CompanyName(), SessionId(), the execution context, a call counter of a SingleInstance codeunit of this app (81252), the counter
//   of the fixture app's SingleInstance codeunit (61054) and how many Company Triggers calls this session saw (81258).
//   The per-company subscriber of "LT BF Z Subs" also counts rows of five Base Application tables (P3). The per-database calls read the per-company
//   table "LT BF Per Company Row" inside a TryFunction and log the error (P7).
// Install code must never fail (check-install-triggers.py): only reads go inside a TryFunction (a write there is an error the TryFunction does not catch,
//   error-handling/TestTryFunctionContracts.al), and every write is `if Insert() then;` into a DataPerCompany = false table.
// BC versions: 27 - 29

table 81250 "LT BF Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; "Source"; Text[30]) { }
        field(3; "Event Name"; Text[60]) { }
        field(4; "Company"; Text[60]) { }
        field(5; "Session Id"; Integer) { }
        field(6; "Context"; Text[30]) { }
        field(7; "Counter"; Integer) { }
        field(8; "Fixture Counter"; Integer) { }
        field(9; "Company Open Calls"; Integer) { }
        field(10; Info; Text[2048]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// A per-company table (DataPerCompany is true by default). Never written; the per-database install code reads it.
table 81251 "LT BF Per Company Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 81252 "LT BF Install State"
{
    SingleInstance = true;

    var
        Calls: Integer;

    procedure Next(): Integer
    begin
        Calls += 1;
        exit(Calls);
    end;
}

// Shared by the three install sources. No test codeunit calls it.
codeunit 81256 "LT BF Install Writer"
{
    procedure WriteRow(Source: Text; EventName: Text; Info: Text)
    var
        Row: Record "LT BF Install Log";
        State: Codeunit "LT BF Install State";
        FixtureState: Codeunit "LT BF Fixture Install State";
        CompanyOpen: Codeunit "LT BF Company Open State";
    begin
        Row.Init();
        Row."Source" := CopyStr(Source, 1, MaxStrLen(Row."Source"));
        Row."Event Name" := CopyStr(EventName, 1, MaxStrLen(Row."Event Name"));
        Row."Company" := CopyStr(CompanyName(), 1, MaxStrLen(Row."Company"));
        Row."Session Id" := SessionId();
        Row."Context" := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Row."Context"));
        Row."Counter" := State.Next();
        Row."Fixture Counter" := FixtureState.Current();
        Row."Company Open Calls" := CompanyOpen.Calls();
        Row.Info := CopyStr(Info, 1, MaxStrLen(Row.Info));
        if Row.Insert() then;
    end;

    // P7: what a read of a per-company table does in the per-database part.
    procedure PerCompanyReads(): Text
    var
        Result: Text;
    begin
        if TryIsEmpty() then
            Result := 'isempty=ok'
        else
            Result := 'isempty=error|' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        if TryFindFirst() then
            Result += ';findfirst=ok'
        else
            Result += ';findfirst=error|' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    // P3: row counts of Base Application tables in the company the install code runs in.
    procedure BaseCounts(): Text
    begin
        exit('79=' + CountOf(79) + ';98=' + CountOf(98) + ';242=' + CountOf(242) + ';77=' + CountOf(77) + ';308=' + CountOf(308));
    end;

    local procedure CountOf(TableNo: Integer): Text
    var
        N: Integer;
    begin
        if TryCount(TableNo, N) then
            exit(Format(N));
        ClearLastError();
        exit('error');
    end;

    [TryFunction]
    local procedure TryCount(TableNo: Integer; var N: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        N := RecRef.Count();
        RecRef.Close();
    end;

    [TryFunction]
    local procedure TryIsEmpty()
    var
        Row: Record "LT BF Per Company Row";
    begin
        if Row.IsEmpty() then;
    end;

    [TryFunction]
    local procedure TryFindFirst()
    var
        Row: Record "LT BF Per Company Row";
    begin
        if Row.FindFirst() then;
    end;
}

codeunit 81253 "LT BF Z Subs"
{
    var
        Writer: Codeunit "LT BF Install Writer";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    begin
        Writer.WriteRow('Z Subs', 'OnInstallAppPerCompany', Writer.BaseCounts());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    begin
        Writer.WriteRow('Z Subs', 'OnInstallAppPerDatabase', Writer.PerCompanyReads());
    end;
}

codeunit 81254 "LT BF Install Late"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Writer: Codeunit "LT BF Install Writer";
    begin
        Writer.WriteRow('Install Late', 'OnInstallAppPerCompany', '');
    end;

    trigger OnInstallAppPerDatabase()
    var
        Writer: Codeunit "LT BF Install Writer";
    begin
        Writer.WriteRow('Install Late', 'OnInstallAppPerDatabase', Writer.PerCompanyReads());
    end;
}

codeunit 81255 "LT BF A Subs"
{
    var
        Writer: Codeunit "LT BF Install Writer";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    begin
        Writer.WriteRow('A Subs', 'OnInstallAppPerCompany', '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    begin
        Writer.WriteRow('A Subs', 'OnInstallAppPerDatabase', '');
    end;
}

// Probe UM (ADR-046 Q1): see install/lt-um-install-order/UmInstallOrder.al. Writes only `if Insert() then;` into a DataPerCompany = false log.
codeunit 90432 "LT UM b Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('b', 'OnInstallAppPerCompany');
    end;

    trigger OnInstallAppPerDatabase()
    var
        Writer: Codeunit "LT UM Install Writer";
    begin
        Writer.WriteRow('b', 'OnInstallAppPerDatabase');
    end;
}
