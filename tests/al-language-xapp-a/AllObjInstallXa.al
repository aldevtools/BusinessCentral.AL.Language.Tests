// Probe of what AllObj and AllObjWithCaption show during the install of another app (al-runner issues 8954 and 6924).
// The install code of A, B and D (per database and per company; codeunits 94694 below, 61385 in xapp-b/AllObjInstallXb.al, 61395 in
// xapp-d/AllObjInstallXd.al) calls Probe of the hub below. For each of the apps A, B and D (the installing app itself included) Probe notes whether
// AllObj and AllObjWithCaption have a row for that app's table (types Table and TableData) and install codeunit, whether NAV App Installed App has
// the app and whether NavApp.GetModuleInfo finds it. Then it counts the AllObj and AllObjWithCaption rows filtered on "App Package ID", for every
// package id of the main test app and of XApp A, B, C, D, N and T (one named object each, see TryPackages). B and D have no dependency path to each other, both depend on A.
// The test "LT Y79 Install Unrelated" (94170, tests/al-language/install-upgrade/install-triggers/Y79InstallUnrelated.al) reads the notes back
// and orders the installs by the first note of each app.
// Install code must never fail (check-install-triggers.py): every read runs in a TryFunction that writes nothing, and the only write is
// `if Insert() then;` into the DataPerCompany = false table 94696.
// local object: the test asserts which objects of which app AllObj shows during an install.

table 94696 "INS AllObj Inst Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Seq; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[100]) { }
        field(3; Value; Text[250]) { }
    }

    keys { key(PK; Seq) { Clustered = true; } }
}

table 94697 "INS AllObj Inst XA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 94693 "INS AllObj Inst Hub"
{
    procedure Probe(App: Text; Phase: Text)
    begin
        Note(App + '|' + Phase + '|start', '');
        ProbeApp(App, Phase, 'A', 'cd6a4292-f27b-4af9-89bc-15a5956f5c71', 94697, 94694);
        ProbeApp(App, Phase, 'B', 'c87ced6d-11a6-4ad2-87c7-ac10083d0a2f', 61386, 61385);
        ProbeApp(App, Phase, 'D', 'e92be076-de11-44ed-895e-17031341df29', 61396, 61395);
        PackageCounts(App, Phase);
    end;

    local procedure Note(Tag: Text; Value: Text)
    var
        Row: Record "INS AllObj Inst Log";
    begin
        Row.Tag := CopyStr(Tag, 1, MaxStrLen(Row.Tag));
        Row.Value := CopyStr(Value, 1, MaxStrLen(Row.Value));
        if Row.Insert() then;
    end;

    local procedure ProbeApp(App: Text; Phase: Text; Other: Text; OtherIdText: Text; TableId: Integer; CodeunitId: Integer)
    var
        Where: Text;
        Found: Boolean;
    begin
        Where := App + '|' + Phase + '|' + Other + '|';
        if TryInstalled(OtherIdText, Found) then
            Note(Where + 'installed', Format(Found))
        else
            Note(Where + 'installed', 'error ' + GetLastErrorCode());
        if TryModuleInfo(OtherIdText, Found) then
            Note(Where + 'moduleinfo', Format(Found))
        else
            Note(Where + 'moduleinfo', 'error ' + GetLastErrorCode());
        AllObjRow(Where + 'allobj table', 0, TableId);
        AllObjRow(Where + 'allobj tabledata', 1, TableId);
        AllObjRow(Where + 'allobj codeunit', 2, CodeunitId);
        CaptionRow(Where + 'caption table', 0, TableId);
        CaptionRow(Where + 'caption tabledata', 1, TableId);
        CaptionRow(Where + 'caption codeunit', 2, CodeunitId);
    end;

    // Kind: 0 Table, 1 TableData, 2 Codeunit. The value is Yes or No, and for a found row its "App Package ID" after '|'.
    local procedure AllObjRow(Tag: Text; Kind: Integer; Id: Integer)
    var
        Found: Boolean;
        Pkg: Guid;
    begin
        if TryAllObj(Kind, Id, Found, Pkg) then begin
            if Found then
                Note(Tag, 'Yes|' + Format(Pkg))
            else
                Note(Tag, 'No');
        end else
            Note(Tag, 'error ' + GetLastErrorCode());
    end;

    local procedure CaptionRow(Tag: Text; Kind: Integer; Id: Integer)
    var
        Found: Boolean;
        Pkg: Guid;
    begin
        if TryCaption(Kind, Id, Found, Pkg) then begin
            if Found then
                Note(Tag, 'Yes|' + Format(Pkg))
            else
                Note(Tag, 'No');
        end else
            Note(Tag, 'error ' + GetLastErrorCode());
    end;

    // For the package id of each app that owns one of the named objects in TryPackages: the count of AllObj and of AllObjWithCaption rows
    // filtered on that "App Package ID" alone. Tag: App|Phase|pkg|<package id>, value: allobj=<n>;caption=<n>.
    local procedure PackageCounts(App: Text; Phase: Text)
    var
        Packages: List of [Guid];
        Pkg: Guid;
        ObjCount: Integer;
        CapCount: Integer;
    begin
        if not TryPackages(Packages) then begin
            Note(App + '|' + Phase + '|pkg|error', GetLastErrorCode());
            exit;
        end;
        foreach Pkg in Packages do
            if TryCounts(Pkg, ObjCount, CapCount) then
                Note(App + '|' + Phase + '|pkg|' + Format(Pkg), 'allobj=' + Format(ObjCount) + ';caption=' + Format(CapCount))
            else
                Note(App + '|' + Phase + '|pkg|' + Format(Pkg), 'error ' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryInstalled(OtherIdText: Text; var Found: Boolean)
    var
        Installed: Record "NAV App Installed App";
        AppId: Guid;
    begin
        Evaluate(AppId, OtherIdText);
        Found := Installed.Get(AppId);
    end;

    [TryFunction]
    local procedure TryModuleInfo(OtherIdText: Text; var Found: Boolean)
    var
        Info: ModuleInfo;
        AppId: Guid;
    begin
        Evaluate(AppId, OtherIdText);
        Found := NavApp.GetModuleInfo(AppId, Info);
    end;

    [TryFunction]
    local procedure TryAllObj(Kind: Integer; Id: Integer; var Found: Boolean; var Pkg: Guid)
    var
        Obj: Record AllObj;
    begin
        case Kind of
            0:
                Found := Obj.Get(Obj."Object Type"::Table, Id);
            1:
                Found := Obj.Get(Obj."Object Type"::TableData, Id);
            2:
                Found := Obj.Get(Obj."Object Type"::Codeunit, Id);
        end;
        if Found then
            Pkg := Obj."App Package ID";
    end;

    [TryFunction]
    local procedure TryCaption(Kind: Integer; Id: Integer; var Found: Boolean; var Pkg: Guid)
    var
        Obj: Record AllObjWithCaption;
    begin
        case Kind of
            0:
                Found := Obj.Get(Obj."Object Type"::Table, Id);
            1:
                Found := Obj.Get(Obj."Object Type"::TableData, Id);
            2:
                Found := Obj.Get(Obj."Object Type"::Codeunit, Id);
        end;
        if Found then
            Pkg := Obj."App Package ID";
    end;

    [TryFunction]
    local procedure TryPackages(var Packages: List of [Guid])
    var
        Obj: Record AllObj;
    begin
        // One named object per app (main test app, XApp A, B, C, D, N, T), single ids only (CONTRIBUTING.md, standing rule 10).
        Obj.SetFilter("Object Type", '%1|%2', Obj."Object Type"::Table, Obj."Object Type"::Codeunit);
        Obj.SetFilter("Object ID", '61121|61386|61396|94170|94697|97810|97815');
        if Obj.FindSet() then
            repeat
                if not Packages.Contains(Obj."App Package ID") then
                    Packages.Add(Obj."App Package ID");
            until Obj.Next() = 0;
    end;

    [TryFunction]
    local procedure TryCounts(Pkg: Guid; var ObjCount: Integer; var CapCount: Integer)
    var
        Obj: Record AllObj;
        Cap: Record AllObjWithCaption;
    begin
        Obj.SetRange("App Package ID", Pkg);
        ObjCount := Obj.Count();
        Cap.SetRange("App Package ID", Pkg);
        CapCount := Cap.Count();
    end;
}

codeunit 94694 "INS AllObj Inst XA Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Hub: Codeunit "INS AllObj Inst Hub";
    begin
        Hub.Probe('A', 'db');
    end;

    trigger OnInstallAppPerCompany()
    var
        Hub: Codeunit "INS AllObj Inst Hub";
    begin
        Hub.Probe('A', 'co');
    end;
}
