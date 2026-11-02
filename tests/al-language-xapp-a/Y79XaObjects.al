// Cross-app fixtures of writer Y79 (al-runner issues 6644 and 6755, install-time behavior), app A. The install code of A, B and D (B and D have no
// dependency path to each other; their install codeunits are in Y8XaInstallOrder.al, Y8XbInstallOrder.al and Y8XdInstallOrder.al) call Probe of the
// hub below, per database and per company. Probe arms the hub, writes one row with Insert(true) into the per-company table 61370 and the
// DataPerCompany = false table 61371, writes a Reason Code and a Job Queue Entry with Insert(true) (per company only), asks the Upgrade Tag codeunit for
// its tags and notes what it sees of the Object tables. The subscribers and table extensions of B and D (Y79XbSubs.al, Y79XdSubs.al) note, while the hub is
// armed, which install they ran in. Every note is a row of the DataPerCompany = false table 61374 (Insert() without triggers, so a note asks for no trigger
// setup); the Seq column gives the order. Install code must never fail (check-install-triggers.py): every write is `if Insert(..) then`, a Reason Code and a Job Queue Entry are deleted again at once (other tests count the rows) and the
// reads cannot raise. Tests: tests/al-language/install/lt-y79-install-unrelated/Y79InstallUnrelated.al.

table 61370 "LT Y79 XA Data"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Note; Text[50]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 61371 "LT Y79 XA Db Data"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Note; Text[50]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 61377 "LT Y79 XA Mask 2"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Note; Text[50]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 61378 "LT Y79 XA Mask 4"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Note; Text[50]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 61379 "LT Y79 XA Mask 8"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Note; Text[50]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 61374 "LT Y79 XA Seen"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Seq; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[250]) { }
        field(3; "Company"; Text[30]) { }
    }

    keys { key(PK; Seq) { Clustered = true; } }
}

codeunit 61372 "LT Y79 XA Hub"
{
    SingleInstance = true;

    var
        ArmedApp: Text;

    procedure Arm(App: Text)
    begin
        ArmedApp := App;
    end;

    procedure Disarm()
    begin
        ArmedApp := '';
    end;

    procedure Armed(): Text
    begin
        exit(ArmedApp);
    end;

    // '-' when no install code is running a probe (a test session, the application's own work).
    procedure Where(): Text
    begin
        if ArmedApp = '' then
            exit('-');
        exit(ArmedApp);
    end;

    procedure Note(Tag: Text)
    var
        Row: Record "LT Y79 XA Seen";
    begin
        Row.Tag := CopyStr(Tag, 1, MaxStrLen(Row.Tag));
        Row."Company" := CopyStr(CompanyName(), 1, MaxStrLen(Row."Company"));
        if Row.Insert() then;
    end;

    procedure Probe(App: Text; Phase: Text)
    var
        Info: ModuleInfo;
    begin
        Arm(App + '|' + Phase);
        Note('install|' + App + '|' + Phase);
        WriteRows(App, Phase);
        Tags(App, Phase);
        NavApp.GetCurrentModuleInfo(Info);
        Objects(App, Phase, Info);
        Disarm();
    end;

    local procedure RowNo(App: Text): Integer
    begin
        case App of
            'A':
                exit(1);
            'D':
                exit(10);
        end;
        exit(20);
    end;

    local procedure WriteRows(App: Text; Phase: Text)
    var
        DbRow: Record "LT Y79 XA Db Data";
        Row: Record "LT Y79 XA Data";
        ReasonCode: Record "Reason Code";
        Jqe: Record "Job Queue Entry";
    begin
        DbRow.Init();
        DbRow."No." := RowNo(App);
        DbRow.Note := CopyStr(App + '|' + Phase, 1, MaxStrLen(DbRow.Note));
        if DbRow.Insert(true) then;
        if Phase <> 'co' then
            exit;
        Row.Init();
        Row."No." := RowNo(App);
        Row.Note := CopyStr(App + '|' + Phase, 1, MaxStrLen(Row.Note));
        if Row.Insert(true) then;
        ReasonCode.Init();
        ReasonCode.Code := CopyStr('LTY79' + App, 1, MaxStrLen(ReasonCode.Code));
        ReasonCode.Description := 'LT Y79 install probe';
        if ReasonCode.Insert(true) then
            ReasonCode.Delete();
        Jqe.Init();
        Jqe."Object Type to Run" := Jqe."Object Type to Run"::Codeunit;
        Jqe."Object ID to Run" := Codeunit::"LT Y79 XA Hub";
        Jqe.Description := CopyStr('LT Y79 ' + App, 1, MaxStrLen(Jqe.Description));
        Jqe.Status := Jqe.Status::"On Hold";
        if Jqe.Insert(true) then
            Jqe.Delete();
    end;

    local procedure Tags(App: Text; Phase: Text)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: List of [Code[250]];
    begin
        if Phase = 'co' then
            UpgradeTag.GetPerCompanyUpgradeTags(Tags)
        else
            UpgradeTag.GetPerDatabaseUpgradeTags(Tags);
        Note('tags|' + App + '|' + Phase + '|A=' + Format(Tags.Contains('LT-Y79-A')) + '|B=' + Format(Tags.Contains('LT-Y79-B')) + '|D=' + Format(Tags.Contains('LT-Y79-D')));
    end;

    local procedure Objects(App: Text; Phase: Text; Info: ModuleInfo)
    var
        Render: Codeunit "LT Y79 XA Render";
    begin
        Note('objects|' + App + '|' + Phase + '|own|' + Render.Describe(Database::"LT Y79 XA Data", Info));
        Note('objects|' + App + '|' + Phase + '|ms|' + Render.Describe(Database::Contact, Info));
    end;
}

// Describes the AllObjWithCaption / AllObj rows of one table for the app of ModuleInfo Own and for the Base Application: whether each app column is empty,
// the app's own value, the Base Application's value or another one, and how the TableData row relates to the Table row.
codeunit 61373 "LT Y79 XA Render"
{
    procedure Describe(TableId: Integer; Own: ModuleInfo): Text
    var
        Base: ModuleInfo;
        TableData: Record AllObjWithCaption;
        TableRow: Record AllObjWithCaption;
        AllObjTableData: Record AllObj;
        Result: Text;
    begin
        if not NavApp.GetModuleInfo('437dbf0e-84ff-417a-965d-ed2bb9650972', Base) then
            Result := 'base?|';
        if not TableData.Get(TableData."Object Type"::TableData, TableId) then
            exit(Result + 'cap=<no TableData row>');
        Result += 'cap name=' + TableData."Object Name" + ' caption=' + TableData."Object Caption" + ' subtype=[' + TableData."Object Subtype" + '] ns=[' + TableData."AL Namespace" + ']';
        Result += ' pkg=' + Kind(TableData."App Package ID", Own.PackageId, Base.PackageId);
        Result += ' rt=' + Kind(TableData."App Runtime Package ID", Own.PackageId, Base.PackageId) + ' rt=pkg:' + Format(TableData."App Runtime Package ID" = TableData."App Package ID");
        Result += ' app=' + Kind(TableData."App ID", Own.Id, Base.Id);
        if TableRow.Get(TableRow."Object Type"::Table, TableId) then
            Result += ' |same as Table row: pkg=' + Format(TableRow."App Package ID" = TableData."App Package ID") + ' rt=' + Format(TableRow."App Runtime Package ID" = TableData."App Runtime Package ID") + ' app=' + Format(TableRow."App ID" = TableData."App ID") + ' ns=' + Format(TableRow."AL Namespace" = TableData."AL Namespace")
        else
            Result += ' |no Table row';
        if AllObjTableData.Get(AllObjTableData."Object Type"::TableData, TableId) then
            Result += ' |AllObj same: pkg=' + Format(AllObjTableData."App Package ID" = TableData."App Package ID") + ' rt=' + Format(AllObjTableData."App Runtime Package ID" = TableData."App Runtime Package ID") + ' ns=' + Format(AllObjTableData."AL Namespace" = TableData."AL Namespace")
        else
            Result += ' |no AllObj row';
        exit(Result);
    end;

    procedure Kind(Value: Guid; Own: Guid; Base: Guid): Text
    begin
        if IsNullGuid(Value) then
            exit('null');
        if Value = Own then
            exit('own');
        if Value = Base then
            exit('base');
        exit('other');
    end;
}

codeunit 61375 "LT Y79 XA Tag Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure OnCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('A-tags-co|' + Hub.Armed());
        PerCompanyUpgradeTags.Add('LT-Y79-A');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure OnDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('A-tags-db|' + Hub.Armed());
        PerDatabaseUpgradeTags.Add('LT-Y79-A');
    end;
}
