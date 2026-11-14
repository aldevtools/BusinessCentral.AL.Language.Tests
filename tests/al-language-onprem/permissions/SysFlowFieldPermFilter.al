// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-permissions
// Scope: in-scope (OnPrem app: Published Application is Scope = OnPrem)
// Fixtures used: Probe Observer (69160); SFP Mock Switch (76740, tests/al-language/permissions/SysFlowPermMock.al) over Permissions Mock;
//   the permission sets "SFP PA READ" and "SFP NO PA" of tests/al-language-onprem/permissions/SysFlowFieldPerm.al.
// Probe: al-runner issue 8038, shape 1 (Guided Experience Impl. GetExtensionLogo): filters on the system table "Published Application"
//   (2000000160) read directly, where "Tenant Visible" is itself a FlowField over the internal table "NAV App Extra". Forms: SetRange(ID)
//   + SetRange("Tenant Visible", true) then FindFirst, FindSet, FindLast, Find('-'), IsEmpty and Count; the ID filter alone; the
//   "Tenant Visible" filter alone; "Tenant Visible" = false; CalcFields("Tenant Visible") after a FindFirst, and the FlowField read
//   without CalcFields. Permission states: a set that grants tabledata "Published Application" = R only, a set that grants nothing on
//   it, no mock (full permissions). The ID is this OnPrem app's or a fixed GUID no app has. Every case ends in the own error
//   'SFP ok [...]', so the observed text is the value, or the error BC raised before that.

codeunit 98744 "SFP SysFlow Filter Perm"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Switch: Codeunit "SFP Mock Switch";
        NoAppIdTok: Label '{5F1D0C2E-7B44-4E1A-9A3C-2D6E8B9F0A11}', Locked = true;


    [Test]
    procedure PARead_Found_A()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'findfirst_id_tv', 'SFP PA READ', 1, AppId);
        RunCase(Observer, 'findset_id_tv', 'SFP PA READ', 2, AppId);
        RunCase(Observer, 'isempty_id_tv', 'SFP PA READ', 3, AppId);
        RunCase(Observer, 'count_id_tv', 'SFP PA READ', 4, AppId);
        RunCase(Observer, 'findfirst_id', 'SFP PA READ', 5, AppId);
        RunCase(Observer, 'isempty_tv', 'SFP PA READ', 6, AppId);
        Observer.Finish();
    end;

    [Test]
    procedure PARead_Found_B()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'findfirst_id_tv_calc', 'SFP PA READ', 7, AppId);
        RunCase(Observer, 'findfirst_id_calc', 'SFP PA READ', 8, AppId);
        RunCase(Observer, 'findfirst_id_nocalc', 'SFP PA READ', 9, AppId);
        RunCase(Observer, 'findfirst_id_tvfalse', 'SFP PA READ', 10, AppId);
        RunCase(Observer, 'findlast_id_tv', 'SFP PA READ', 11, AppId);
        RunCase(Observer, 'find_dash_id_tv', 'SFP PA READ', 12, AppId);
        Observer.Finish();
    end;

    [Test]
    procedure PARead_NotFound_A()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'findfirst_id_tv', 'SFP PA READ', 1, AppId);
        RunCase(Observer, 'findset_id_tv', 'SFP PA READ', 2, AppId);
        RunCase(Observer, 'isempty_id_tv', 'SFP PA READ', 3, AppId);
        RunCase(Observer, 'count_id_tv', 'SFP PA READ', 4, AppId);
        RunCase(Observer, 'findfirst_id', 'SFP PA READ', 5, AppId);
        RunCase(Observer, 'isempty_tv', 'SFP PA READ', 6, AppId);
        Observer.Finish();
    end;

    [Test]
    procedure PARead_NotFound_B()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'findfirst_id_tv_calc', 'SFP PA READ', 7, AppId);
        RunCase(Observer, 'findfirst_id_calc', 'SFP PA READ', 8, AppId);
        RunCase(Observer, 'findfirst_id_nocalc', 'SFP PA READ', 9, AppId);
        RunCase(Observer, 'findfirst_id_tvfalse', 'SFP PA READ', 10, AppId);
        RunCase(Observer, 'findlast_id_tv', 'SFP PA READ', 11, AppId);
        RunCase(Observer, 'find_dash_id_tv', 'SFP PA READ', 12, AppId);
        Observer.Finish();
    end;

    [Test]
    procedure NoPA_Found_A()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'findfirst_id_tv', 'SFP NO PA', 1, AppId);
        RunCase(Observer, 'findset_id_tv', 'SFP NO PA', 2, AppId);
        RunCase(Observer, 'isempty_id_tv', 'SFP NO PA', 3, AppId);
        RunCase(Observer, 'count_id_tv', 'SFP NO PA', 4, AppId);
        RunCase(Observer, 'findfirst_id', 'SFP NO PA', 5, AppId);
        RunCase(Observer, 'isempty_tv', 'SFP NO PA', 6, AppId);
        Observer.Finish();
    end;

    [Test]
    procedure NoPA_Found_B()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'findfirst_id_tv_calc', 'SFP NO PA', 7, AppId);
        RunCase(Observer, 'findfirst_id_calc', 'SFP NO PA', 8, AppId);
        RunCase(Observer, 'findfirst_id_nocalc', 'SFP NO PA', 9, AppId);
        RunCase(Observer, 'findfirst_id_tvfalse', 'SFP NO PA', 10, AppId);
        RunCase(Observer, 'findlast_id_tv', 'SFP NO PA', 11, AppId);
        RunCase(Observer, 'find_dash_id_tv', 'SFP NO PA', 12, AppId);
        Observer.Finish();
    end;

    [Test]
    procedure NoPA_NotFound_A()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'findfirst_id_tv', 'SFP NO PA', 1, AppId);
        RunCase(Observer, 'findset_id_tv', 'SFP NO PA', 2, AppId);
        RunCase(Observer, 'isempty_id_tv', 'SFP NO PA', 3, AppId);
        RunCase(Observer, 'count_id_tv', 'SFP NO PA', 4, AppId);
        RunCase(Observer, 'findfirst_id', 'SFP NO PA', 5, AppId);
        RunCase(Observer, 'isempty_tv', 'SFP NO PA', 6, AppId);
        Observer.Finish();
    end;

    [Test]
    procedure NoPA_NotFound_B()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'findfirst_id_tv_calc', 'SFP NO PA', 7, AppId);
        RunCase(Observer, 'findfirst_id_calc', 'SFP NO PA', 8, AppId);
        RunCase(Observer, 'findfirst_id_nocalc', 'SFP NO PA', 9, AppId);
        RunCase(Observer, 'findfirst_id_tvfalse', 'SFP NO PA', 10, AppId);
        RunCase(Observer, 'findlast_id_tv', 'SFP NO PA', 11, AppId);
        RunCase(Observer, 'find_dash_id_tv', 'SFP NO PA', 12, AppId);
        Observer.Finish();
    end;

    [Test]
    procedure Full_Found_A()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'findfirst_id_tv', '', 1, AppId);
        RunCase(Observer, 'findset_id_tv', '', 2, AppId);
        RunCase(Observer, 'isempty_id_tv', '', 3, AppId);
        RunCase(Observer, 'count_id_tv', '', 4, AppId);
        RunCase(Observer, 'findfirst_id', '', 5, AppId);
        RunCase(Observer, 'isempty_tv', '', 6, AppId);
        Observer.Finish();
    end;

    [Test]
    procedure Full_Found_B()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := ThisAppId();
        RunCase(Observer, 'findfirst_id_tv_calc', '', 7, AppId);
        RunCase(Observer, 'findfirst_id_calc', '', 8, AppId);
        RunCase(Observer, 'findfirst_id_nocalc', '', 9, AppId);
        RunCase(Observer, 'findfirst_id_tvfalse', '', 10, AppId);
        RunCase(Observer, 'findlast_id_tv', '', 11, AppId);
        RunCase(Observer, 'find_dash_id_tv', '', 12, AppId);
        Observer.Finish();
    end;

    [Test]
    procedure Full_NotFound_A()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'findfirst_id_tv', '', 1, AppId);
        RunCase(Observer, 'findset_id_tv', '', 2, AppId);
        RunCase(Observer, 'isempty_id_tv', '', 3, AppId);
        RunCase(Observer, 'count_id_tv', '', 4, AppId);
        RunCase(Observer, 'findfirst_id', '', 5, AppId);
        RunCase(Observer, 'isempty_tv', '', 6, AppId);
        Observer.Finish();
    end;

    [Test]
    procedure Full_NotFound_B()
    var
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        AppId := NoAppId();
        RunCase(Observer, 'findfirst_id_tv_calc', '', 7, AppId);
        RunCase(Observer, 'findfirst_id_calc', '', 8, AppId);
        RunCase(Observer, 'findfirst_id_nocalc', '', 9, AppId);
        RunCase(Observer, 'findfirst_id_tvfalse', '', 10, AppId);
        RunCase(Observer, 'findlast_id_tv', '', 11, AppId);
        RunCase(Observer, 'find_dash_id_tv', '', 12, AppId);
        Observer.Finish();
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
        Rec: Record "Published Application";
        Result: Text;
    begin
        case Which of
            1:
                begin
                    Rec.SetRange(ID, AppId);
                    Rec.SetRange("Tenant Visible", true);
                    Rec.FindFirst();
                    Result := Rec.Name;
                end;
            2:
                begin
                    Rec.SetRange(ID, AppId);
                    Rec.SetRange("Tenant Visible", true);
                    Rec.FindSet();
                    Result := Rec.Name;
                end;
            3:
                begin
                    Rec.SetRange(ID, AppId);
                    Rec.SetRange("Tenant Visible", true);
                    Result := Format(Rec.IsEmpty());
                end;
            4:
                begin
                    Rec.SetRange(ID, AppId);
                    Rec.SetRange("Tenant Visible", true);
                    Result := Format(Rec.Count());
                end;
            5:
                begin
                    Rec.SetRange(ID, AppId);
                    Rec.FindFirst();
                    Result := Rec.Name;
                end;
            6:
                begin
                    Rec.SetRange("Tenant Visible", true);
                    Result := Format(Rec.IsEmpty());
                end;
            7:
                begin
                    Rec.SetRange(ID, AppId);
                    Rec.SetRange("Tenant Visible", true);
                    Rec.FindFirst();
                    Rec.CalcFields("Tenant Visible");
                    Result := Format(Rec."Tenant Visible");
                end;
            8:
                begin
                    Rec.SetRange(ID, AppId);
                    Rec.FindFirst();
                    Rec.CalcFields("Tenant Visible");
                    Result := Format(Rec."Tenant Visible");
                end;
            9:
                begin
                    Rec.SetRange(ID, AppId);
                    Rec.FindFirst();
                    Result := Format(Rec."Tenant Visible");
                end;
            10:
                begin
                    Rec.SetRange(ID, AppId);
                    Rec.SetRange("Tenant Visible", false);
                    Rec.FindFirst();
                    Result := Rec.Name;
                end;
            11:
                begin
                    Rec.SetRange(ID, AppId);
                    Rec.SetRange("Tenant Visible", true);
                    Rec.FindLast();
                    Result := Rec.Name;
                end;
            12:
                begin
                    Rec.SetRange(ID, AppId);
                    Rec.SetRange("Tenant Visible", true);
                    Rec.Find(-);
                    Result := Rec.Name;
                end;
        end;
        Error('SFP ok [%1]', Result);
    end;
}
