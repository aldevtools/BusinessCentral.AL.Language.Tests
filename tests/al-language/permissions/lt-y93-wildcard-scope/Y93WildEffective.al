// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y93WildObjects.al (94980-94999); xapp-a Y93XaObjects.al; Permissions Mock (131006).
// Probe, writer Y93 (outside issue 6867): "User Permissions".GetEffectivePermission for objects of the main app (M), of xapp-a (A), of Base Application (B)
//   and of System Application (S) under exact sets that hold wildcard grants. Row format: <letters R I M D X>; upper case = Yes, lower case = Indirect,
//   - = none. GetEffectivePermission loads no object, so the first-load rule of the Execute cases does not apply here.
// BC versions: 27, 28, 29

codeunit 94999 "LT Y93 Wild Effective"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";
        Names: List of [Text];
        Values: List of [Text];

    [Test]
    procedure Y93_Eff_Exact_1()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Clear(Names);
        Clear(Values);
        Mock.SetExactPermissionSet('LT Y93 W Cu');
        Collect('LT Y93 W Cu');
        Mock.SetExactPermissionSet('LT Y93 W Page');
        Collect('LT Y93 W Page');
        RestoreMock(WasStarted);
        Flush();
        Observer.Expect('LT Y93 W Cu',
            'cuM=----X cuA=----X cuB=----X pgM=----- pgA=----- pgB=----- tblM=----- tblA=----- tblB=----- tdM=----- tdA=----- tdB=----- repM=----- repA=----- repB=----- qryM=----- qryA=----- qryB=----- xmlM=----- xmlA=----- xmlB=----- cuS=----X tdN=----- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Expect('LT Y93 W Page',
            'cuM=----- cuA=----- cuB=----- pgM=----X pgA=----X pgB=----X tblM=----- tblA=----- tblB=----- tdM=----- tdA=----- tdB=----- repM=----- repA=----- repB=----- qryM=----- qryA=----- qryB=----- xmlM=----- xmlA=----- xmlB=----- cuS=----X tdN=----- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Eff_Exact_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Clear(Names);
        Clear(Values);
        Mock.SetExactPermissionSet('LT Y93 W Table');
        Collect('LT Y93 W Table');
        Mock.SetExactPermissionSet('LT Y93 W Data');
        Collect('LT Y93 W Data');
        RestoreMock(WasStarted);
        Flush();
        Observer.Expect('LT Y93 W Table',
            'cuM=----- cuA=----- cuB=----- pgM=----- pgA=----- pgB=----- tblM=----X tblA=----X tblB=----X tdM=----- tdA=----- tdB=----- repM=----- repA=----- repB=----- qryM=----- qryA=----- qryB=----- xmlM=----- xmlA=----- xmlB=----- cuS=----X tdN=----- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Expect('LT Y93 W Data',
            'cuM=----- cuA=----- cuB=----- pgM=----- pgA=----- pgB=----- tblM=----- tblA=----- tblB=----- tdM=RIMD- tdA=RIMD- tdB=RIMD- repM=----- repA=----- repB=----- qryM=----- qryA=----- qryB=----- xmlM=----- xmlA=----- xmlB=----- cuS=----X tdN=RIMD- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Eff_Exact_3()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Clear(Names);
        Clear(Values);
        Mock.SetExactPermissionSet('LT Y93 W Report');
        Collect('LT Y93 W Report');
        Mock.SetExactPermissionSet('LT Y93 W Query');
        Collect('LT Y93 W Query');
        RestoreMock(WasStarted);
        Flush();
        Observer.Expect('LT Y93 W Report',
            'cuM=----- cuA=----- cuB=----- pgM=----- pgA=----- pgB=----- tblM=----- tblA=----- tblB=----- tdM=----- tdA=----- tdB=----- repM=----X repA=----X repB=----X qryM=----- qryA=----- qryB=----- xmlM=----- xmlA=----- xmlB=----- cuS=----X tdN=----- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Expect('LT Y93 W Query',
            'cuM=----- cuA=----- cuB=----- pgM=----- pgA=----- pgB=----- tblM=----- tblA=----- tblB=----- tdM=----- tdA=----- tdB=----- repM=----- repA=----- repB=----- qryM=----X qryA=----X qryB=----X xmlM=----- xmlA=----- xmlB=----- cuS=----X tdN=----- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Eff_Exact_4()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Clear(Names);
        Clear(Values);
        Mock.SetExactPermissionSet('LT Y93 W Xml');
        Collect('LT Y93 W Xml');
        Mock.SetExactPermissionSet('LT Y93 W Sys');
        Collect('LT Y93 W Sys');
        RestoreMock(WasStarted);
        Flush();
        Observer.Expect('LT Y93 W Xml',
            'cuM=----- cuA=----- cuB=----- pgM=----- pgA=----- pgB=----- tblM=----- tblA=----- tblB=----- tdM=----- tdA=----- tdB=----- repM=----- repA=----- repB=----- qryM=----- qryA=----- qryB=----- xmlM=----X xmlA=----X xmlB=----X cuS=----X tdN=----- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Expect('LT Y93 W Sys',
            'cuM=----- cuA=----- cuB=----- pgM=----- pgA=----- pgB=----- tblM=----- tblA=----- tblB=----- tdM=----- tdA=----- tdB=----- repM=----- repA=----- repB=----- qryM=----- qryA=----- qryB=----- xmlM=----- xmlA=----- xmlB=----- cuS=----X tdN=----- sys6110=----X sys5810=----X sys9026=----X');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Eff_Exact_5()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Clear(Names);
        Clear(Values);
        Mock.SetExactPermissionSet('LT Y93 W All');
        Collect('LT Y93 W All');
        Mock.SetExactPermissionSet('LT Y93 XA All');
        Collect('LT Y93 XA All');
        RestoreMock(WasStarted);
        Flush();
        Observer.Expect('LT Y93 W All',
            'cuM=----X cuA=----X cuB=----X pgM=----X pgA=----X pgB=----X tblM=----X tblA=----X tblB=----X tdM=RIMD- tdA=RIMD- tdB=RIMD- repM=----X repA=----X repB=----X qryM=----X qryA=----X qryB=----X xmlM=----X xmlA=----X xmlB=----X cuS=----X tdN=RIMD- sys6110=----X sys5810=----X sys9026=----X');
        Observer.Expect('LT Y93 XA All',
            'cuM=----X cuA=----X cuB=----X pgM=----X pgA=----X pgB=----X tblM=----X tblA=----X tblB=----X tdM=RIMD- tdA=RIMD- tdB=RIMD- repM=----X repA=----X repB=----X qryM=----X qryA=----X qryB=----X xmlM=----X xmlA=----X xmlB=----X cuS=----X tdN=RIMD- sys6110=----X sys5810=----X sys9026=----X');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Eff_Exact_6()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Clear(Names);
        Clear(Values);
        Mock.SetExactPermissionSet('LT Y93 W Ind');
        Collect('LT Y93 W Ind');
        Mock.SetExactPermissionSet('LT Y93 W Mix Data');
        Collect('LT Y93 W Mix Data');
        RestoreMock(WasStarted);
        Flush();
        Observer.Expect('LT Y93 W Ind',
            'cuM=----- cuA=----- cuB=----- pgM=----- pgA=----- pgB=----- tblM=----- tblA=----- tblB=----- tdM=rimd- tdA=rimd- tdB=rimd- repM=----- repA=----- repB=----- qryM=----- qryA=----- qryB=----- xmlM=----- xmlA=----- xmlB=----- cuS=----X tdN=rimd- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Expect('LT Y93 W Mix Data',
            'cuM=----- cuA=----- cuB=----- pgM=----- pgA=----- pgB=----- tblM=----- tblA=----- tblB=----- tdM=RIMD- tdA=RIMD- tdB=RIMD- repM=----- repA=----- repB=----- qryM=----- qryA=----- qryB=----- xmlM=----- xmlA=----- xmlB=----- cuS=----X tdN=RIMD- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Eff_Exact_7()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Clear(Names);
        Clear(Values);
        Mock.SetExactPermissionSet('LT Y93 W Mix Cu');
        Collect('LT Y93 W Mix Cu');
        Mock.SetExactPermissionSet('LT Y93 W Excl');
        Collect('LT Y93 W Excl');
        RestoreMock(WasStarted);
        Flush();
        Observer.Expect('LT Y93 W Mix Cu',
            'cuM=----X cuA=----X cuB=----X pgM=----- pgA=----- pgB=----- tblM=----- tblA=----- tblB=----- tdM=----- tdA=----- tdB=----- repM=----- repA=----- repB=----- qryM=----- qryA=----- qryB=----- xmlM=----- xmlA=----- xmlB=----- cuS=----X tdN=----- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Expect('LT Y93 W Excl',
            'cuM=----X cuA=----X cuB=----X pgM=----X pgA=----X pgB=----X tblM=----X tblA=----X tblB=----X tdM=R-MD- tdA=RIMD- tdB=RIMD- repM=----X repA=----X repB=----X qryM=----X qryA=----X qryB=----X xmlM=----X xmlA=----X xmlB=----X cuS=----X tdN=RIMD- sys6110=----X sys5810=----X sys9026=----X');
        Observer.Verify();
    end;

    // Permission sets that Microsoft ships (declared in Base Application), exact: do they reach the objects of this app?
    [Test]
    procedure Y93_Eff_MicrosoftSets()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Clear(Names);
        Clear(Values);
        Mock.SetExactPermissionSet('D365 BASIC');
        Collect('D365 BASIC');
        Mock.SetExactPermissionSet('D365 READ');
        Collect('D365 READ');
        RestoreMock(WasStarted);
        Flush();
        Observer.Expect('D365 BASIC',
            'cuM=----X cuA=----X cuB=----X pgM=----X pgA=----X pgB=----X tblM=----X tblA=----X tblB=----X tdM=----- tdA=----- tdB=RIMD- repM=----X repA=----X repB=----X qryM=----X qryA=----X qryB=----X xmlM=----X xmlA=----X xmlB=----X cuS=----X tdN=----- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Expect('D365 READ',
            'cuM=----X cuA=----X cuB=----X pgM=----X pgA=----X pgB=----X tblM=----X tblA=----X tblB=----X tdM=----- tdA=----- tdB=R---- repM=----X repA=----X repB=----X qryM=----X qryA=----X qryB=----X xmlM=----X xmlA=----X xmlB=----X cuS=----X tdN=----- sys6110=----- sys5810=----X sys9026=-----');
        Observer.Verify();
    end;

    // Set and Assign (not exact) with a set that names no object of the call.
    [Test]
    procedure Y93_Eff_SetAssign()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Clear(Names);
        Clear(Values);
        Mock.Set('LT Y93 W Sys');
        Collect('Set W Sys');
        Mock.ClearAssignments();
        Mock.Assign('LT Y93 W Sys');
        Collect('Assign W Sys');
        RestoreMock(WasStarted);
        Flush();
        Observer.Expect('Set W Sys',
            'cuM=----X cuA=----X cuB=----X pgM=----X pgA=----X pgB=----X tblM=----X tblA=----X tblB=----X tdM=----- tdA=----- tdB=----- repM=----X repA=----X repB=----X qryM=----X qryA=----X qryB=----X xmlM=----X xmlA=----X xmlB=----X cuS=----X tdN=----- sys6110=----X sys5810=----X sys9026=----X');
        Observer.Expect('Assign W Sys',
            'cuM=----- cuA=----- cuB=----- pgM=----- pgA=----- pgB=----- tblM=----- tblA=----- tblB=----- tdM=----- tdA=----- tdB=----- repM=----- repA=----- repB=----- qryM=----- qryA=----- qryB=----- xmlM=----- xmlA=----- xmlB=----- cuS=----X tdN=----- sys6110=----X sys5810=----X sys9026=----X');
        Observer.Verify();
    end;

    [Test]
    procedure Y93_Eff_SetAssign_2()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Clear(Names);
        Clear(Values);
        Mock.Set('LT Y93 W Data');
        Collect('Set W Data');
        Mock.ClearAssignments();
        Mock.Assign('LT Y93 W Data');
        Collect('Assign W Data');
        RestoreMock(WasStarted);
        Flush();
        Observer.Expect('Set W Data',
            'cuM=----X cuA=----X cuB=----X pgM=----X pgA=----X pgB=----X tblM=----X tblA=----X tblB=----X tdM=RIMD- tdA=RIMD- tdB=RIMD- repM=----X repA=----X repB=----X qryM=----X qryA=----X qryB=----X xmlM=----X xmlA=----X xmlB=----X cuS=----X tdN=RIMD- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Expect('Assign W Data',
            'cuM=----- cuA=----- cuB=----- pgM=----- pgA=----- pgB=----- tblM=----- tblA=----- tblB=----- tdM=RIMD- tdA=RIMD- tdB=RIMD- repM=----- repA=----- repB=----- qryM=----- qryA=----- qryB=----- xmlM=----- xmlA=----- xmlB=----- cuS=----X tdN=RIMD- sys6110=----- sys5810=----- sys9026=-----');
        Observer.Verify();
    end;

    local procedure Collect(Tag: Text)
    var
        Line: Text;
    begin
        Line := Row('cu', 5, Codeunit::"LT Y93 Cu Q1", Codeunit::"LT Y93 XA Cu 1", Codeunit::"Calendar Management") +
            Row('pg', 8, Page::"LT Y93 Page M1", Page::"LT Y93 XA Page 1", Page::"Units of Measure") +
            Row('tbl', 1, Database::"LT Y93 Tab M1", Database::"LT Y93 XA Tab 1", Database::"Unit of Measure") +
            Row('td', 0, Database::"LT Y93 Row", Database::"LT Y93 XA Row", Database::"Unit of Measure") +
            Row('rep', 3, Report::"LT Y93 Report M1", Report::"LT Y93 XA Report 1", Report::"Customer - List") +
            Row('qry', 9, Query::"LT Y93 Query M1", Query::"LT Y93 XA Query 1", Query::"Bank Account Ledger Entries") +
            Row('xml', 6, Xmlport::"LT Y93 Xml M1", Xmlport::"LT Y93 XA Xml 1", Xmlport::"Export Generic CSV") +
            One('cuS', 5, Codeunit::"Base64 Convert") + One('tdN', 0, Database::"LT Y93 Row Narrow") +
            One('sys6110', 10, 6110) + One('sys5810', 10, 5810) + One('sys9026', 10, 9026);
        Names.Add(Tag);
        Values.Add(Line.TrimEnd());
    end;

    local procedure Row(Label: Text; Kind: Integer; Main: Integer; Xapp: Integer; Base: Integer): Text
    begin
        exit(One(Label + 'M', Kind, Main) + One(Label + 'A', Kind, Xapp) + One(Label + 'B', Kind, Base));
    end;

    local procedure One(Label: Text; Kind: Integer; ObjectId: Integer): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if not TryRights(Kind, ObjectId, Result) then
            Result := 'error: ' + GetLastErrorText() + ' ' + GetLastErrorCode();
        ClearLastError();
        exit(Label + '=' + Result + ' ');
    end;

    local procedure Flush()
    var
        Index: Integer;
    begin
        Mock.ClearAssignments();
        for Index := 1 to Names.Count() do
            Observer.Observe(Names.Get(Index), Values.Get(Index));
    end;

    [TryFunction]
    local procedure TryRights(Kind: Integer; ObjectId: Integer; var Result: Text)
    var
        UserPermissions: Codeunit "User Permissions";
        Expanded: Record "Expanded Permission" temporary;
    begin
        Expanded := UserPermissions.GetEffectivePermission(Kind, ObjectId);
        Result := Letter(Format(Expanded."Read Permission"), 'R') + Letter(Format(Expanded."Insert Permission"), 'I') + Letter(Format(Expanded."Modify Permission"), 'M') +
            Letter(Format(Expanded."Delete Permission"), 'D') + Letter(Format(Expanded."Execute Permission"), 'X');
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
