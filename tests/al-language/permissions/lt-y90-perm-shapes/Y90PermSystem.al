// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y90PermObjects.al (94780-94829); Y69 permission sets (Y69PermSets.al) (named system grants); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 probes P13 and P19 (shadow run: 91 reads of system tables, 33 FlowFields over system tables, 8 WritePermission queries on system
//   tables, 10 effective permission queries). Y19PermSystemTables.al pins Tenant Media, Company, AllObj and Field. This file adds Language Selection (a
//   read-only system table), Report Layout List, Table Relations Metadata (virtual) and NAV App Installed App: FindFirst, Count, IsEmpty, an insert,
//   a FlowField count and exist over them from an own table, and ReadPermission/WritePermission, under a set that names only the own table, one that
//   grants them R and one that grants them RIMD, assigned exactly and with Set. A last test pins GetEffectivePermission for named System objects under
//   exact sets, Set and no assignment, and for table data with mixed direct and indirect letters.
// BC versions: 27, 28, 29

codeunit 94810 "LT Y90 Perm System"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y90_Sys_ExactNone()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunAll('LT Y90 S None', true, 'none');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y90_Sys_ExactR()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunAll('LT Y90 S R', true, 'r');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y90_Sys_ExactRimd()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunAll('LT Y90 S RIMD', true, 'rimd');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y90_Sys_SetNone()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunAll('LT Y90 S None', false, 'setnone');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y90_Sys_SetR()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunAll('LT Y90 S R', false, 'setr');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y90_Sys_Effective()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        EffectiveSystem('LT Y69 SY Many', true, 'many exact');
        EffectiveSystem('LT Y69 SY Many', false, 'many set');
        EffectiveSystem('LT Y69 SY Wild', true, 'wild exact');
        EffectiveSystem('LT Y69 SY Basic', true, 'basic exact');
        EffectiveSystem('LT Y69 SY Indirect', true, 'indirect exact');
        Mock.ClearAssignments();
        Observer.Observe('noset', EffectiveSystemNow());
        EffectiveGuard('LT Y90 E Mixed', true, 'RiMd exact');
        EffectiveGuard('LT Y90 E Mixed', false, 'RiMd set');
        EffectiveGuard('LT Y90 S None', true, 'none exact');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    local procedure EffectiveSystem(SetName: Code[20]; Exact: Boolean; Tag: Text)
    begin
        Mock.ClearAssignments();
        Assign(SetName, Exact);
        Observer.Observe(Tag, EffectiveSystemNow());
        Mock.ClearAssignments();
    end;

    local procedure EffectiveSystemNow(): Text
    begin
        exit('5810=' + Rights(10, 5810) + ' 9026=' + Rights(10, 9026) + ' 6110=' + Rights(10, 6110) + ' 5310=' + Rights(10, 5310) +
            ' 9100=' + Rights(10, 9100) + ' 5820=' + Rights(10, 5820));
    end;

    local procedure EffectiveGuard(SetName: Code[20]; Exact: Boolean; Tag: Text)
    var
        Text1: Text;
    begin
        Mock.ClearAssignments();
        Assign(SetName, Exact);
        Text1 := Rights(0, Database::"LT Y90 Guard");
        Mock.ClearAssignments();
        Observer.Observe(Tag, Text1);
    end;

    local procedure Rights(Kind: Integer; ObjectId: Integer): Text
    var
        UserPermissions: Codeunit "User Permissions";
        Expanded: Record "Expanded Permission" temporary;
    begin
        Expanded := UserPermissions.GetEffectivePermission(Kind, ObjectId);
        exit(Letter(Format(Expanded."Read Permission"), 'R') + Letter(Format(Expanded."Insert Permission"), 'I') + Letter(Format(Expanded."Modify Permission"), 'M') +
            Letter(Format(Expanded."Delete Permission"), 'D') + Letter(Format(Expanded."Execute Permission"), 'X'));
    end;

    local procedure Letter(Value: Text; Mark: Text): Text
    begin
        case Value of
            'Yes':
                exit(Mark);
            'Indirect':
                exit(Mark.ToLower());
            ' ', '':
                exit('-');
        end;
        exit('?' + Value);
    end;

    local procedure Assign(SetName: Code[20]; Exact: Boolean)
    begin
        if Exact then
            Mock.SetExactPermissionSet(SetName)
        else
            Mock.Set(SetName);
    end;

    local procedure RunAll(SetName: Code[20]; Exact: Boolean; Tag: Text)
    var
        Which: Integer;
    begin
        for Which := 1 to 14 do
            RunOne(Tag, SetName, Exact, Which);
    end;

    local procedure RunOne(Tag: Text; SetName: Code[20]; Exact: Boolean; Which: Integer)
    var
        Row: Record "LT Y90 Row";
        ErrorText: Text;
        ErrorCode: Text;
    begin
        Mock.ClearAssignments();
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Assign(SetName, Exact);
        asserterror Op(Which);
        ErrorText := GetLastErrorText();
        ErrorCode := GetLastErrorCode();
        Mock.ClearAssignments();
        ClearLastError();
        if ErrorText.StartsWith('LT Y90 ok ') then
            Observer.Observe(Tag + '|' + Format(Which), CopyStr(ErrorText, 11))
        else
            Observer.Observe(Tag + '|' + Format(Which), ErrorText + ' | ' + ErrorCode);
    end;

    local procedure Op(Which: Integer)
    var
        Row: Record "LT Y90 Row";
        Lang: Record "Language Selection";
        Layout: Record "Report Layout List";
        Rel: Record "Table Relations Metadata";
        App: Record "NAV App Installed App";
        Found: Boolean;
        Total: Integer;
        Result: Text;
    begin
        case Which of
            1:
                Result := 'lang find ' + Format(Lang.FindFirst());
            2:
                Result := 'lang count>0 ' + Format(Lang.Count() > 0);
            3:
                Result := 'lang isempty ' + Format(Lang.IsEmpty());
            4:
                Result := 'layout find ' + Format(Layout.FindFirst());
            5:
                Result := 'rel find ' + Format(Rel.FindFirst());
            6:
                Result := 'app find ' + Format(App.FindFirst());
            7:
                begin
                    Row.Get(1);
                    Row.CalcFields(LangCount);
                    Result := 'flow lang>0 ' + Format(Row.LangCount > 0);
                end;
            8:
                begin
                    Row.Get(1);
                    Row.CalcFields(LayoutCount);
                    Result := 'flow layout calculated';
                end;
            9:
                begin
                    Row.Get(1);
                    Row.CalcFields(RelCount);
                    Result := 'flow rel>0 ' + Format(Row.RelCount > 0);
                end;
            10:
                begin
                    Row.Get(1);
                    Row.CalcFields(AppCount);
                    Result := 'flow app>0 ' + Format(Row.AppCount > 0);
                end;
            11:
                begin
                    Row.Get(1);
                    Row.CalcFields(LangExists);
                    Result := 'flow exist ' + Format(Row.LangExists);
                end;
            12:
                begin
                    Lang.Init();
                    Lang.Name := 'LT Y90 Language';
                    Lang."Language ID" := 99999;
                    Lang.Insert();
                    Result := 'lang inserted';
                end;
            13:
                Result := 'lang R/W ' + Format(Lang.ReadPermission()) + '/' + Format(Lang.WritePermission()) + ' layout R/W ' + Format(Layout.ReadPermission()) + '/' +
                    Format(Layout.WritePermission()) + ' rel R/W ' + Format(Rel.ReadPermission()) + '/' + Format(Rel.WritePermission()) + ' app R/W ' + Format(App.ReadPermission()) +
                    '/' + Format(App.WritePermission());
            14:
                begin
                    Row.FindFirst();
                    Row.SetAutoCalcFields(LangCount, RelCount);
                    Row.Get(1);
                    Found := Row.LangCount > 0;
                    Total := Row.RelCount;
                    Result := 'autocalc lang>0 ' + Format(Found) + ' rel>0 ' + Format(Total > 0);
                end;
        end;
        Error('LT Y90 ok %1', Result);
    end;

    local procedure StartMock() WasStarted: Boolean
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
    end;

    local procedure RestoreMock(WasStarted: Boolean)
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;
}
