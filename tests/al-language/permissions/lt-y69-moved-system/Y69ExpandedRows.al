// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permission-set-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y69PermSets.al (sets 93700-93708, 93720-93731, extensions 93707 and 93732, helper 93735).
// Probe (writer Y69, al-runner issues 6716 and 6717 by SShadowS): the Expanded Permission rows of the Y69 permission sets, which need no Permissions Mock
//   (so they run on the SaaS sandbox, a Windows server). 6716: which table a set that names a table BC 29 ships twice under one id (the Base Application's
//   ObsoleteState = Moved copy and the Business Foundation target) binds to: the row's object id; one row per table, also with the table grant and the
//   tabledata grant of the same name, through an included set, an excluded set and a permission set extension. 6717: the rows a named system grant
//   `system "<name>" = X` makes (object type System, the system object's id) and what the included and the excluded sets leave of them.
//   Row format: <object type ordinal>:<object id>:<R I M D X letters; lower case = indirect; - = none>.
// BC versions: 27, 28, 29
codeunit 93713 "LT Y69 Expanded Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y69 Helper";

    [Test]
    procedure Y69_MV_ExpandedRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('name', Helper.Expanded('LT Y69 MV NAME'));
        Observer.Observe('plain', Helper.Expanded('LT Y69 MV PLAIN'));
        Observer.Observe('all', Helper.Expanded('LT Y69 MV ALL'));
        Observer.Observe('outer', Helper.Expanded('LT Y69 MV OUTER'));
        Observer.Observe('excl', Helper.Expanded('LT Y69 MV EXCL'));
        Observer.Observe('ext_base', Helper.Expanded('LT Y69 MV EXT BASE'));
        Observer.Observe('indirect', Helper.Expanded('LT Y69 MV INDIRECT'));
        Observer.Expect('name', '2 rows 0:18:R----;0:231:R----;');
        Observer.Expect('plain', '1 rows 0:18:R----;');
        Observer.Expect('all', '11 rows 0:18:R----;0:230:RIMD-;0:231:RIMD-;0:242:RIMD-;0:308:RIMD-;0:309:RIMD-;0:310:RIMD-;0:1263:RIMD-;0:6635:RIMD-;1:231:----X;1:308:----X;');
        Observer.Expect('outer', '2 rows 0:18:R----;0:6635:R----;');
        Observer.Expect('excl', '10 rows 0:230:RIMD-;0:231:-IMD-;0:242:RIMD-;0:308:RIMD-;0:309:RIMD-;0:310:RIMD-;0:1263:RIMD-;0:6635:RIMD-;1:231:----X;1:308:----X;');
        Observer.Expect('ext_base', '3 rows 0:18:R----;0:230:R----;0:1263:RIMD-;');
        Observer.Expect('indirect', '3 rows 0:18:R----;0:231:r----;0:308:r----;');
        Observer.Verify();
    end;


    [Test]
    procedure Y69_SY_ExpandedRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('basic', Helper.Expanded('LT Y69 SY BASIC'));
        Observer.Observe('outer', Helper.Expanded('LT Y69 SY OUTER'));
        Observer.Observe('many', Helper.Expanded('LT Y69 SY MANY'));
        Observer.Observe('only', Helper.Expanded('LT Y69 SY ONLY'));
        Observer.Observe('indirect', Helper.Expanded('LT Y69 SY INDIRECT'));
        Observer.Observe('wild', Helper.Expanded('LT Y69 SY WILD'));
        Observer.Observe('mid', Helper.Expanded('LT Y69 SY MID'));
        Observer.Observe('excl', Helper.Expanded('LT Y69 SY EXCL'));
        Observer.Observe('plain', Helper.Expanded('LT Y69 SY PLAIN'));
        Observer.Expect('basic', '2 rows 0:18:R----;10:5810:----X;');
        Observer.Expect('outer', '2 rows 0:18:R----;10:5810:----X;');
        Observer.Expect('many', '5 rows 0:18:R----;10:5310:----X;10:6110:----X;10:9026:----X;10:9100:----X;');
        Observer.Expect('only', '1 rows 10:5810:----X;');
        Observer.Expect('indirect', '2 rows 0:18:R----;10:5810:----x;');
        Observer.Expect('wild', '2 rows 0:18:R----;10:0:----X;');
        Observer.Expect('mid', '2 rows 0:18:R----;10:5810:----X;');
        Observer.Expect('excl', '4 rows 10:5310:----X;10:6110:----X;10:9026:----X;10:9100:----X;');
        Observer.Expect('plain', '2 rows 0:18:R----;10:5810:----X;');
        Observer.Verify();
    end;

    // The Base Application's own sets that name moved tables (the issue's impact: 'D365 BASIC - EDIT' has tabledata "Reason Code" = IMD).
    [Test]
    procedure Y69_MV_BaseApplicationSets()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('d365_basic', RowsOf('D365 BASIC', 0, '230|231|242|308|309|310|1263|6635'));
        Observer.Observe('d365_basic_edit', RowsOf('D365 BASIC - EDIT', 0, '230|231|242|308|309|310|1263|6635'));
        Observer.Observe('d365_bus_full_access', RowsOf('D365 BUS FULL ACCESS', 0, '230|231|242|308|309|310|1263|6635'));
        Observer.Observe('d365_full_access', RowsOf('D365 FULL ACCESS', 0, '230|231|242|308|309|310|1263|6635'));
        Observer.Observe('d365_read', RowsOf('D365 READ', 0, '230|231|242|308|309|310|1263|6635'));
        Observer.Observe('d365_setup', RowsOf('D365 SETUP', 0, '230|231|242|308|309|310|1263|6635'));
        Observer.Expect('d365_basic', '8 rows 230:RI---;231:RIMD-;242:RI---;308:R----;309:R----;310:R----;1263:rimd-;6635:RI---;');
        Observer.Expect('d365_basic_edit', '8 rows 230:RI---;231:RIMD-;242:RI---;308:R----;309:R----;310:R----;1263:rimd-;6635:RI---;');
        Observer.Expect('d365_bus_full_access', '8 rows 230:RIMD-;231:RIMD-;242:RIMD-;308:RIMD-;309:RIMD-;310:RIMD-;1263:RIMD-;6635:RIMD-;');
        Observer.Expect('d365_full_access', '8 rows 230:RIMD-;231:RIMD-;242:RIMD-;308:RIMD-;309:RIMD-;310:RIMD-;1263:RIMD-;6635:RIMD-;');
        Observer.Expect('d365_read', '8 rows 230:R----;231:R----;242:R----;308:R----;309:R----;310:R----;1263:R----;6635:R----;');
        Observer.Expect('d365_setup', '6 rows 230:RIMD-;242:RIMD-;308:RIMD-;309:RIMD-;310:RIMD-;6635:RIMD-;');
        Observer.Verify();
    end;

    // The Base Application's own sets that carry named system grants (the issue's impact: 'D365 FULL ACCESS' has system "Add Table Field To Page" = X, its
    // included 'D365 BUS FULL ACCESS' has system "Tools, Security, Roles" = X). Only a few rows are asserted: the sets differ between BC releases.
    [Test]
    procedure Y69_SY_BaseApplicationSets()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('full_access_9026_add_table_field_to_page', Format(HasRow('D365 FULL ACCESS', 10, 9026)));
        Observer.Observe('full_access_5810_tools_security_roles', Format(HasRow('D365 FULL ACCESS', 10, 5810)));
        Observer.Observe('bus_full_access_5810', Format(HasRow('D365 BUS FULL ACCESS', 10, 5810)));
        Observer.Observe('bus_full_access_9026', Format(HasRow('D365 BUS FULL ACCESS', 10, 9026)));
        Observer.Observe('read_5810', Format(HasRow('D365 READ', 10, 5810)));
        Observer.Observe('full_access_reason_code_tabledata', Format(HasRow('D365 FULL ACCESS', 0, 231)));
        Observer.Expect('full_access_9026_add_table_field_to_page', 'Yes');
        Observer.Expect('full_access_5810_tools_security_roles', 'Yes');
        Observer.Expect('bus_full_access_5810', 'Yes');
        Observer.Expect('bus_full_access_9026', 'No');
        Observer.Expect('read_5810', 'Yes');
        Observer.Expect('full_access_reason_code_tabledata', 'Yes');
        Observer.Verify();
    end;

    local procedure HasRow(RoleId: Code[20]; ObjectType: Integer; ObjectId: Integer): Boolean
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        ExpandedPermission.SetRange("Role ID", RoleId);
        ExpandedPermission.SetRange("Object Type", ObjectType);
        ExpandedPermission.SetRange("Object ID", ObjectId);
        exit(not ExpandedPermission.IsEmpty());
    end;

    // Expanded Permission rows of one role, one object type (ordinal) and an object id filter, as 'count: id:RIMDX;...'.
    local procedure RowsOf(RoleId: Code[20]; ObjectType: Integer; IdFilter: Text): Text
    var
        ExpandedPermission: Record "Expanded Permission";
        Result: Text;
    begin
        ExpandedPermission.SetRange("Role ID", RoleId);
        ExpandedPermission.SetRange("Object Type", ObjectType);
        if IdFilter <> '' then
            ExpandedPermission.SetFilter("Object ID", IdFilter);
        if ExpandedPermission.FindSet() then
            repeat
                Result += Format(ExpandedPermission."Object ID") + ':' + Letter(ExpandedPermission."Read Permission", 'R') + Letter(ExpandedPermission."Insert Permission", 'I') +
                    Letter(ExpandedPermission."Modify Permission", 'M') + Letter(ExpandedPermission."Delete Permission", 'D') +
                    Letter(ExpandedPermission."Execute Permission", 'X') + ';';
            until ExpandedPermission.Next() = 0;
        exit(Format(ExpandedPermission.Count()) + ' rows ' + Result);
    end;

    local procedure Letter(Value: Option " ",Yes,Indirect; Which: Text[1]): Text
    begin
        case Value of
            Value::Yes:
                exit(Which);
            Value::Indirect:
                exit(Which.ToLower());
        end;
        exit('-');
    end;
}
