// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-flowfields
// Scope: in-scope (OnPrem app: Published Application is Scope = OnPrem)
// Fixtures used: Probe Observer (69160); SFP Mock Switch (76740, tests/al-language/permissions/SysFlowPermMock.al) over Permissions Mock.
// Probe: al-runner issue 8038. FlowFields of an own table over the system table "Published Application" (2000000206), whose
//   "Tenant Visible" is itself a FlowField over the internal table "NAV App Extra" (2000000157): lookup of Name and Publisher with
//   "Tenant Visible" = const(true), lookup of Name without that filter, exist and count with and without it. Forms: CalcFields of each
//   field, SetAutoCalcFields + FindFirst, and a filter on the FlowField (SetFilter / SetRange + Count). Permission states: (a) a set that
//   grants tabledata "Published Application" = R and the own table, (b) a set that grants only the own table, (c) no mock (the test
//   runs with full permissions). The lookup either finds a row (the ID of this OnPrem app, from NavApp.GetCurrentModuleInfo) or none
//   (a fixed GUID no app has). Every case inserts its own row inside an asserterror that ends in the own error 'SFP ok [...]', so
//   nothing stays.
// Facts (BC 27.5, 28.5 and 29.0 behave the same):
//   With "Published Application" = R, and with no mock (full permissions): CalcFields gives the value with and without the
//   "Tenant Visible" = true filter (Name = this app's name, Publisher = 'AL Language', Exist = Yes, Count = 1; for the unknown app
//   '', No, 0), no error. Without a grant on "Published Application": every CalcFields form (Name, Publisher, Exist, Count, with
//   and without the filter, row found or not) raises DB:ClientReadDenied 'Sorry, the current permissions prevented the action.
//   (TableData 2000000206 Published Application IndirectRead: <this app's name>)'. SetAutoCalcFields + FindFirst and a filter on
//   the FlowField (SetFilter on Name, SetRange on Exist) raise no error in that state and return the same values as with the grant.
// BC versions: 27, 28, 29

table 98740 "SFP Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "App ID"; Guid) { }
        field(3; "Name Visible"; Text[250])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Published Application".Name where(ID = field("App ID"), "Tenant Visible" = const(true)));
        }
        field(4; "Name Any"; Text[250])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Published Application".Name where(ID = field("App ID")));
        }
        field(5; "Publisher Visible"; Text[250])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Published Application".Publisher where(ID = field("App ID"), "Tenant Visible" = const(true)));
        }
        field(6; "Exists Visible"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("Published Application" where(ID = field("App ID"), "Tenant Visible" = const(true)));
        }
        field(7; "Exists Any"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("Published Application" where(ID = field("App ID")));
        }
        field(8; "Count Visible"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Published Application" where(ID = field("App ID"), "Tenant Visible" = const(true)));
        }
        field(9; "Count Any"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Published Application" where(ID = field("App ID")));
        }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

// (a) read on Published Application, nothing on NAV App Extra.
permissionset 98741 "SFP PA READ"
{
    Assignable = true;
    Permissions =
        tabledata "SFP Item" = RIMD,
        tabledata "Published Application" = R;
}

// (b) nothing on Published Application.
permissionset 98742 "SFP NO PA"
{
    Assignable = true;
    Permissions = tabledata "SFP Item" = RIMD;
}

codeunit 98743 "SFP SysFlow Perm"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Switch: Codeunit "SFP Mock Switch";
        NoAppIdTok: Label '{5F1D0C2E-7B44-4E1A-9A3C-2D6E8B9F0A11}', Locked = true;

    [Test]
    procedure PARead_Found_CalcNamePublisher()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'calc_name_visible', 'SFP PA READ', 1, AppId);
        RunCase(Observer, 'calc_name_any', 'SFP PA READ', 2, AppId);
        RunCase(Observer, 'calc_publisher_visible', 'SFP PA READ', 3, AppId);
        Observer.Expect('calc_name_visible|text', 'SFP ok [AL Language Coverage Tests (OnPrem)]');
        Observer.Expect('calc_name_visible|code', 'Dialog');
        Observer.Expect('calc_name_any|text', 'SFP ok [AL Language Coverage Tests (OnPrem)]');
        Observer.Expect('calc_name_any|code', 'Dialog');
        Observer.Expect('calc_publisher_visible|text', 'SFP ok [AL Language]');
        Observer.Expect('calc_publisher_visible|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure PARead_Found_CalcExistCount()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'calc_exists_visible', 'SFP PA READ', 4, AppId);
        RunCase(Observer, 'calc_exists_any', 'SFP PA READ', 5, AppId);
        RunCase(Observer, 'calc_count_visible', 'SFP PA READ', 6, AppId);
        RunCase(Observer, 'calc_count_any', 'SFP PA READ', 7, AppId);
        Observer.Expect('calc_exists_visible|text', 'SFP ok [Yes]');
        Observer.Expect('calc_exists_visible|code', 'Dialog');
        Observer.Expect('calc_exists_any|text', 'SFP ok [Yes]');
        Observer.Expect('calc_exists_any|code', 'Dialog');
        Observer.Expect('calc_count_visible|text', 'SFP ok [1]');
        Observer.Expect('calc_count_visible|code', 'Dialog');
        Observer.Expect('calc_count_any|text', 'SFP ok [1]');
        Observer.Expect('calc_count_any|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure PARead_Found_AutoCalcAndFilter()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'autocalc_findfirst_name_visible', 'SFP PA READ', 8, AppId);
        RunCase(Observer, 'autocalc_findfirst_name_any', 'SFP PA READ', 9, AppId);
        RunCase(Observer, 'filter_name_visible_count', 'SFP PA READ', 10, AppId);
        RunCase(Observer, 'filter_exists_visible_count', 'SFP PA READ', 11, AppId);
        Observer.Expect('autocalc_findfirst_name_visible|text', 'SFP ok [AL Language Coverage Tests (OnPrem)]');
        Observer.Expect('autocalc_findfirst_name_visible|code', 'Dialog');
        Observer.Expect('autocalc_findfirst_name_any|text', 'SFP ok [AL Language Coverage Tests (OnPrem)]');
        Observer.Expect('autocalc_findfirst_name_any|code', 'Dialog');
        Observer.Expect('filter_name_visible_count|text', 'SFP ok [1]');
        Observer.Expect('filter_name_visible_count|code', 'Dialog');
        Observer.Expect('filter_exists_visible_count|text', 'SFP ok [1]');
        Observer.Expect('filter_exists_visible_count|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure PARead_NotFound_CalcNamePublisher()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'calc_name_visible', 'SFP PA READ', 1, AppId);
        RunCase(Observer, 'calc_name_any', 'SFP PA READ', 2, AppId);
        RunCase(Observer, 'calc_publisher_visible', 'SFP PA READ', 3, AppId);
        Observer.Expect('calc_name_visible|text', 'SFP ok []');
        Observer.Expect('calc_name_visible|code', 'Dialog');
        Observer.Expect('calc_name_any|text', 'SFP ok []');
        Observer.Expect('calc_name_any|code', 'Dialog');
        Observer.Expect('calc_publisher_visible|text', 'SFP ok []');
        Observer.Expect('calc_publisher_visible|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure PARead_NotFound_CalcExistCount()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'calc_exists_visible', 'SFP PA READ', 4, AppId);
        RunCase(Observer, 'calc_exists_any', 'SFP PA READ', 5, AppId);
        RunCase(Observer, 'calc_count_visible', 'SFP PA READ', 6, AppId);
        RunCase(Observer, 'calc_count_any', 'SFP PA READ', 7, AppId);
        Observer.Expect('calc_exists_visible|text', 'SFP ok [No]');
        Observer.Expect('calc_exists_visible|code', 'Dialog');
        Observer.Expect('calc_exists_any|text', 'SFP ok [No]');
        Observer.Expect('calc_exists_any|code', 'Dialog');
        Observer.Expect('calc_count_visible|text', 'SFP ok [0]');
        Observer.Expect('calc_count_visible|code', 'Dialog');
        Observer.Expect('calc_count_any|text', 'SFP ok [0]');
        Observer.Expect('calc_count_any|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure PARead_NotFound_AutoCalcAndFilter()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'autocalc_findfirst_name_visible', 'SFP PA READ', 8, AppId);
        RunCase(Observer, 'autocalc_findfirst_name_any', 'SFP PA READ', 9, AppId);
        RunCase(Observer, 'filter_name_visible_count', 'SFP PA READ', 10, AppId);
        RunCase(Observer, 'filter_exists_visible_count', 'SFP PA READ', 11, AppId);
        Observer.Expect('autocalc_findfirst_name_visible|text', 'SFP ok []');
        Observer.Expect('autocalc_findfirst_name_visible|code', 'Dialog');
        Observer.Expect('autocalc_findfirst_name_any|text', 'SFP ok []');
        Observer.Expect('autocalc_findfirst_name_any|code', 'Dialog');
        Observer.Expect('filter_name_visible_count|text', 'SFP ok [0]');
        Observer.Expect('filter_name_visible_count|code', 'Dialog');
        Observer.Expect('filter_exists_visible_count|text', 'SFP ok [0]');
        Observer.Expect('filter_exists_visible_count|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure NoPA_Found_CalcNamePublisher()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'calc_name_visible', 'SFP NO PA', 1, AppId);
        RunCase(Observer, 'calc_name_any', 'SFP NO PA', 2, AppId);
        RunCase(Observer, 'calc_publisher_visible', 'SFP NO PA', 3, AppId);
        Observer.Expect('calc_name_visible|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_name_visible|code', 'DB:ClientReadDenied');
        Observer.Expect('calc_name_any|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_name_any|code', 'DB:ClientReadDenied');
        Observer.Expect('calc_publisher_visible|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_publisher_visible|code', 'DB:ClientReadDenied');
        Observer.Verify();
    end;

    [Test]
    procedure NoPA_Found_CalcExistCount()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'calc_exists_visible', 'SFP NO PA', 4, AppId);
        RunCase(Observer, 'calc_exists_any', 'SFP NO PA', 5, AppId);
        RunCase(Observer, 'calc_count_visible', 'SFP NO PA', 6, AppId);
        RunCase(Observer, 'calc_count_any', 'SFP NO PA', 7, AppId);
        Observer.Expect('calc_exists_visible|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_exists_visible|code', 'DB:ClientReadDenied');
        Observer.Expect('calc_exists_any|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_exists_any|code', 'DB:ClientReadDenied');
        Observer.Expect('calc_count_visible|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_count_visible|code', 'DB:ClientReadDenied');
        Observer.Expect('calc_count_any|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_count_any|code', 'DB:ClientReadDenied');
        Observer.Verify();
    end;

    [Test]
    procedure NoPA_Found_AutoCalcAndFilter()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'autocalc_findfirst_name_visible', 'SFP NO PA', 8, AppId);
        RunCase(Observer, 'autocalc_findfirst_name_any', 'SFP NO PA', 9, AppId);
        RunCase(Observer, 'filter_name_visible_count', 'SFP NO PA', 10, AppId);
        RunCase(Observer, 'filter_exists_visible_count', 'SFP NO PA', 11, AppId);
        Observer.Expect('autocalc_findfirst_name_visible|text', 'SFP ok [AL Language Coverage Tests (OnPrem)]');
        Observer.Expect('autocalc_findfirst_name_visible|code', 'Dialog');
        Observer.Expect('autocalc_findfirst_name_any|text', 'SFP ok [AL Language Coverage Tests (OnPrem)]');
        Observer.Expect('autocalc_findfirst_name_any|code', 'Dialog');
        Observer.Expect('filter_name_visible_count|text', 'SFP ok [1]');
        Observer.Expect('filter_name_visible_count|code', 'Dialog');
        Observer.Expect('filter_exists_visible_count|text', 'SFP ok [1]');
        Observer.Expect('filter_exists_visible_count|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure NoPA_NotFound_CalcNamePublisher()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'calc_name_visible', 'SFP NO PA', 1, AppId);
        RunCase(Observer, 'calc_name_any', 'SFP NO PA', 2, AppId);
        RunCase(Observer, 'calc_publisher_visible', 'SFP NO PA', 3, AppId);
        Observer.Expect('calc_name_visible|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_name_visible|code', 'DB:ClientReadDenied');
        Observer.Expect('calc_name_any|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_name_any|code', 'DB:ClientReadDenied');
        Observer.Expect('calc_publisher_visible|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_publisher_visible|code', 'DB:ClientReadDenied');
        Observer.Verify();
    end;

    [Test]
    procedure NoPA_NotFound_CalcExistCount()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'calc_exists_visible', 'SFP NO PA', 4, AppId);
        RunCase(Observer, 'calc_exists_any', 'SFP NO PA', 5, AppId);
        RunCase(Observer, 'calc_count_visible', 'SFP NO PA', 6, AppId);
        RunCase(Observer, 'calc_count_any', 'SFP NO PA', 7, AppId);
        Observer.Expect('calc_exists_visible|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_exists_visible|code', 'DB:ClientReadDenied');
        Observer.Expect('calc_exists_any|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_exists_any|code', 'DB:ClientReadDenied');
        Observer.Expect('calc_count_visible|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_count_visible|code', 'DB:ClientReadDenied');
        Observer.Expect('calc_count_any|text', 'Sorry, the current permissions prevented the action. (TableData 2000000206 Published Application IndirectRead: AL Language Coverage Tests (OnPrem))');
        Observer.Expect('calc_count_any|code', 'DB:ClientReadDenied');
        Observer.Verify();
    end;

    [Test]
    procedure NoPA_NotFound_AutoCalcAndFilter()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'autocalc_findfirst_name_visible', 'SFP NO PA', 8, AppId);
        RunCase(Observer, 'autocalc_findfirst_name_any', 'SFP NO PA', 9, AppId);
        RunCase(Observer, 'filter_name_visible_count', 'SFP NO PA', 10, AppId);
        RunCase(Observer, 'filter_exists_visible_count', 'SFP NO PA', 11, AppId);
        Observer.Expect('autocalc_findfirst_name_visible|text', 'SFP ok []');
        Observer.Expect('autocalc_findfirst_name_visible|code', 'Dialog');
        Observer.Expect('autocalc_findfirst_name_any|text', 'SFP ok []');
        Observer.Expect('autocalc_findfirst_name_any|code', 'Dialog');
        Observer.Expect('filter_name_visible_count|text', 'SFP ok [0]');
        Observer.Expect('filter_name_visible_count|code', 'Dialog');
        Observer.Expect('filter_exists_visible_count|text', 'SFP ok [0]');
        Observer.Expect('filter_exists_visible_count|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Full_Found_CalcNamePublisher()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'calc_name_visible', '', 1, AppId);
        RunCase(Observer, 'calc_name_any', '', 2, AppId);
        RunCase(Observer, 'calc_publisher_visible', '', 3, AppId);
        Observer.Expect('calc_name_visible|text', 'SFP ok [AL Language Coverage Tests (OnPrem)]');
        Observer.Expect('calc_name_visible|code', 'Dialog');
        Observer.Expect('calc_name_any|text', 'SFP ok [AL Language Coverage Tests (OnPrem)]');
        Observer.Expect('calc_name_any|code', 'Dialog');
        Observer.Expect('calc_publisher_visible|text', 'SFP ok [AL Language]');
        Observer.Expect('calc_publisher_visible|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Full_Found_CalcExistCount()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'calc_exists_visible', '', 4, AppId);
        RunCase(Observer, 'calc_exists_any', '', 5, AppId);
        RunCase(Observer, 'calc_count_visible', '', 6, AppId);
        RunCase(Observer, 'calc_count_any', '', 7, AppId);
        Observer.Expect('calc_exists_visible|text', 'SFP ok [Yes]');
        Observer.Expect('calc_exists_visible|code', 'Dialog');
        Observer.Expect('calc_exists_any|text', 'SFP ok [Yes]');
        Observer.Expect('calc_exists_any|code', 'Dialog');
        Observer.Expect('calc_count_visible|text', 'SFP ok [1]');
        Observer.Expect('calc_count_visible|code', 'Dialog');
        Observer.Expect('calc_count_any|text', 'SFP ok [1]');
        Observer.Expect('calc_count_any|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Full_Found_AutoCalcAndFilter()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'autocalc_findfirst_name_visible', '', 8, AppId);
        RunCase(Observer, 'autocalc_findfirst_name_any', '', 9, AppId);
        RunCase(Observer, 'filter_name_visible_count', '', 10, AppId);
        RunCase(Observer, 'filter_exists_visible_count', '', 11, AppId);
        Observer.Expect('autocalc_findfirst_name_visible|text', 'SFP ok [AL Language Coverage Tests (OnPrem)]');
        Observer.Expect('autocalc_findfirst_name_visible|code', 'Dialog');
        Observer.Expect('autocalc_findfirst_name_any|text', 'SFP ok [AL Language Coverage Tests (OnPrem)]');
        Observer.Expect('autocalc_findfirst_name_any|code', 'Dialog');
        Observer.Expect('filter_name_visible_count|text', 'SFP ok [1]');
        Observer.Expect('filter_name_visible_count|code', 'Dialog');
        Observer.Expect('filter_exists_visible_count|text', 'SFP ok [1]');
        Observer.Expect('filter_exists_visible_count|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Full_NotFound_CalcNamePublisher()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'calc_name_visible', '', 1, AppId);
        RunCase(Observer, 'calc_name_any', '', 2, AppId);
        RunCase(Observer, 'calc_publisher_visible', '', 3, AppId);
        Observer.Expect('calc_name_visible|text', 'SFP ok []');
        Observer.Expect('calc_name_visible|code', 'Dialog');
        Observer.Expect('calc_name_any|text', 'SFP ok []');
        Observer.Expect('calc_name_any|code', 'Dialog');
        Observer.Expect('calc_publisher_visible|text', 'SFP ok []');
        Observer.Expect('calc_publisher_visible|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Full_NotFound_CalcExistCount()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'calc_exists_visible', '', 4, AppId);
        RunCase(Observer, 'calc_exists_any', '', 5, AppId);
        RunCase(Observer, 'calc_count_visible', '', 6, AppId);
        RunCase(Observer, 'calc_count_any', '', 7, AppId);
        Observer.Expect('calc_exists_visible|text', 'SFP ok [No]');
        Observer.Expect('calc_exists_visible|code', 'Dialog');
        Observer.Expect('calc_exists_any|text', 'SFP ok [No]');
        Observer.Expect('calc_exists_any|code', 'Dialog');
        Observer.Expect('calc_count_visible|text', 'SFP ok [0]');
        Observer.Expect('calc_count_visible|code', 'Dialog');
        Observer.Expect('calc_count_any|text', 'SFP ok [0]');
        Observer.Expect('calc_count_any|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Full_NotFound_AutoCalcAndFilter()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'autocalc_findfirst_name_visible', '', 8, AppId);
        RunCase(Observer, 'autocalc_findfirst_name_any', '', 9, AppId);
        RunCase(Observer, 'filter_name_visible_count', '', 10, AppId);
        RunCase(Observer, 'filter_exists_visible_count', '', 11, AppId);
        Observer.Expect('autocalc_findfirst_name_visible|text', 'SFP ok []');
        Observer.Expect('autocalc_findfirst_name_visible|code', 'Dialog');
        Observer.Expect('autocalc_findfirst_name_any|text', 'SFP ok []');
        Observer.Expect('autocalc_findfirst_name_any|code', 'Dialog');
        Observer.Expect('filter_name_visible_count|text', 'SFP ok [0]');
        Observer.Expect('filter_name_visible_count|code', 'Dialog');
        Observer.Expect('filter_exists_visible_count|text', 'SFP ok [0]');
        Observer.Expect('filter_exists_visible_count|code', 'Dialog');
        Observer.Verify();
    end;

    local procedure ThisAppId(): Guid
    var
        Me: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Me);
        exit(Me.Id);
    end;

    local procedure NoAppId() Id: Guid
    begin
        Evaluate(Id, NoAppIdTok);
    end;

    // RoleId '' runs the case without the mock (full permissions).
    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; RoleId: Code[20]; Which: Integer; AppId: Guid)
    begin
        if RoleId <> '' then
            Switch.SetOnly(RoleId);
        asserterror Op(Which, AppId);
        Switch.Restore();
        Observer.ObserveError(Name);
    end;

    local procedure Op(Which: Integer; AppId: Guid)
    var
        Item: Record "SFP Item";
        Result: Text;
    begin
        Item.DeleteAll();
        Item.Init();
        Item."Code" := 'A';
        Item."App ID" := AppId;
        Item.Insert();
        case Which of
            1:
                begin
                    Item.CalcFields("Name Visible");
                    Result := Item."Name Visible";
                end;
            2:
                begin
                    Item.CalcFields("Name Any");
                    Result := Item."Name Any";
                end;
            3:
                begin
                    Item.CalcFields("Publisher Visible");
                    Result := Item."Publisher Visible";
                end;
            4:
                begin
                    Item.CalcFields("Exists Visible");
                    Result := Format(Item."Exists Visible");
                end;
            5:
                begin
                    Item.CalcFields("Exists Any");
                    Result := Format(Item."Exists Any");
                end;
            6:
                begin
                    Item.CalcFields("Count Visible");
                    Result := Format(Item."Count Visible");
                end;
            7:
                begin
                    Item.CalcFields("Count Any");
                    Result := Format(Item."Count Any");
                end;
            8:
                begin
                    Item.Reset();
                    Item.SetAutoCalcFields("Name Visible");
                    Item.FindFirst();
                    Result := Item."Name Visible";
                end;
            9:
                begin
                    Item.Reset();
                    Item.SetAutoCalcFields("Name Any");
                    Item.FindFirst();
                    Result := Item."Name Any";
                end;
            10:
                begin
                    Item.Reset();
                    Item.SetFilter("Name Visible", '<>%1', '');
                    Result := Format(Item.Count());
                end;
            11:
                begin
                    Item.Reset();
                    Item.SetRange("Exists Visible", true);
                    Result := Format(Item.Count());
                end;
        end;
        Error('SFP ok [%1]', Result);
    end;
}
