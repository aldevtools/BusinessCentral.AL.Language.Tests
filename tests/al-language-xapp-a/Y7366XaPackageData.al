// Cross-app fixture A: NavApp.LoadPackageData of a data file whose column list ends with a `$systemId` column (al-runner issues 7366 and 6649). The files
// TAB<id>.navxdata in this folder have the layout of Y85XaPackageData.al, except that the column list (count and names) differs as noted per table. They are loaded by
// the install codeunit 94699 below in OnInstallAppPerDatabase (the tables are DataPerCompany = false, the shape of the report), each load in a TryFunction whose error goes to
// the log table 94681 (Kind 'sys7366'). Tests: tests/al-language/install-upgrade/install-triggers/Y7366SystemIdPackageData.al.
//   94692 trailing: columns Entry No., Description, Content, $systemId (count 4 for 3 fields), 2 rows.
//   94693 fewer: table has No., Description, Note; the file lists No., Description, $systemId and its rows carry no Note value.
//   94694 more: table has No., Description; the file lists No., Description, Extra, $systemId and each row carries an Extra string.
//   94695 sameid: two rows with different keys and the same SystemId.
//   94696 existing: the install code inserts the row PRE with the SystemId the file gives row I1, then loads (I1 has another key than PRE).
//   94697 zero: row J1 has 16 zero bytes as SystemId, row J2 a value.
//   94698 othername: columns No., Description, Bogus (count 3 for 2 fields): the last name is not $systemId.

table 94692 "LT Y7366 Sys Trailing"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(10; Description; Text[100]) { }
        field(20; Content; Blob) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 94693 "LT Y7366 Sys Fewer"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30]) { }
        field(3; Note; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 94694 "LT Y7366 Sys More"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 94695 "LT Y7366 Sys SameId"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 94696 "LT Y7366 Sys Existing"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 94697 "LT Y7366 Sys Zero"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 94698 "LT Y7366 Sys OtherName"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

// Install code must never fail: every load is in a TryFunction, the log is written with `if Insert() then;`, a table is loaded only while it is empty.
codeunit 94699 "LT Y7366 Sys Install"
{
    Subtype = Install;

    local procedure LoadOne(TableId: Integer; Name: Text)
    var
        Log: Record "LT Y88 Pkg Log";
        Ok: Boolean;
    begin
        Ok := TryLoad(TableId);
        Log.Kind := 'sys7366';
        Log.Subject := CopyStr(Name, 1, 50);
        if Ok then
            Log.Detail := 'ok'
        else
            Log.Detail := CopyStr('error ' + GetLastErrorCode() + ': ' + GetLastErrorText(), 1, 250);
        if Log.Insert() then;
    end;

    [TryFunction]
    local procedure TryLoad(TableId: Integer)
    begin
        NavApp.LoadPackageData(TableId);
    end;

    [TryFunction]
    local procedure TryPreInsert()
    var
        Pre: Record "LT Y7366 Sys Existing";
        Id: Guid;
    begin
        Evaluate(Id, '{00000000-0000-0000-0000-0000007366E1}');
        Pre.Init();
        Pre."No." := 'PRE';
        Pre.Description := 'pre';
        Pre.SystemId := Id;
        Pre.Insert(false, true);
    end;

    trigger OnInstallAppPerDatabase()
    var
        Trailing: Record "LT Y7366 Sys Trailing";
        Fewer: Record "LT Y7366 Sys Fewer";
        More: Record "LT Y7366 Sys More";
        SameId: Record "LT Y7366 Sys SameId";
        Existing: Record "LT Y7366 Sys Existing";
        Zero: Record "LT Y7366 Sys Zero";
        OtherName: Record "LT Y7366 Sys OtherName";
        Log: Record "LT Y88 Pkg Log";
    begin
        if Trailing.IsEmpty() then
            LoadOne(Database::"LT Y7366 Sys Trailing", 'trailing');
        if Fewer.IsEmpty() then
            LoadOne(Database::"LT Y7366 Sys Fewer", 'fewer');
        if More.IsEmpty() then
            LoadOne(Database::"LT Y7366 Sys More", 'more');
        if SameId.IsEmpty() then
            LoadOne(Database::"LT Y7366 Sys SameId", 'sameid');
        if Existing.IsEmpty() then begin
            if not TryPreInsert() then begin
                Log.Kind := 'sys7366';
                Log.Subject := 'existing preinsert';
                Log.Detail := CopyStr('error ' + GetLastErrorCode() + ': ' + GetLastErrorText(), 1, 250);
                if Log.Insert() then;
            end;
            LoadOne(Database::"LT Y7366 Sys Existing", 'existing');
        end;
        if Zero.IsEmpty() then
            LoadOne(Database::"LT Y7366 Sys Zero", 'zero');
        if OtherName.IsEmpty() then
            LoadOne(Database::"LT Y7366 Sys OtherName", 'othername');
    end;
}
