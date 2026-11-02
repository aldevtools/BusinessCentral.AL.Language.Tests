// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y84PermObjects.al (94380-94421); Y24PermObjects.al (query, xmlport, report, codeunit, page and table); Permissions Mock (131006).
// Probe: al-runtime-rs ADR-062 stage 3, writer Y84: "User Permissions".GetEffectivePermission (System Application) for the object kinds Y24PermExecute.al does not
//   cover (Query 9, XmlPort 6) next to Report, Codeunit, Page and Table, under no set and under exact sets that grant Execute directly, indirectly (lower
//   case x) and not at all; and for table data under exact sets that grant the guard table in each letter and level (R, I, M, D, IM, RIMD, indirect r, i and rimd).
//   System objects are pinned in lt-y69-moved-system/Y69SystemGrants.al (Y69_SY_EffectiveExecute).
// Row format: <letters R I M D X>; upper case = Yes, lower case = Indirect, - = none.
// BC versions: 27, 28, 29

codeunit 94394 "LT Y84 Perm Effective"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y84_Eff_ObjectKinds()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Clear(Names);
        Clear(Values);
        Mock.ClearAssignments();
        Collect('noset');
        Mock.SetExactPermissionSet('LT Y84 X Some');
        Collect('some');
        Mock.SetExactPermissionSet('LT Y84 X Other');
        Collect('other');
        Mock.SetExactPermissionSet('LT Y84 X Ind');
        Collect('ind');
        Mock.SetExactPermissionSet('LT Y84 X None');
        Collect('none');
        Mock.Set('LT Y84 X None');
        Collect('set none');
        RestoreMock(WasStarted);
        Flush();
        Observer.Finish();
    end;

    [Test]
    procedure Y84_Eff_TableDataLevels()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Clear(Names);
        Clear(Values);
        CollectTable('LT Y84 C R');
        CollectTable('LT Y84 C I');
        CollectTable('LT Y84 C M');
        CollectTable('LT Y84 C D');
        CollectTable('LT Y84 C IM');
        CollectTable('LT Y84 C RIMD');
        CollectTable('LT Y84 C Ind R');
        CollectTable('LT Y84 C Ind I');
        CollectTable('LT Y84 C Ind RIMD');
        CollectTable('LT Y84 C None');
        Mock.ClearAssignments();
        Collect2('noset', 'td');
        RestoreMock(WasStarted);
        Flush();
        Observer.Finish();
    end;

    var
        Names: List of [Text];
        Values: List of [Text];

    // One row per kind, collected while the set is assigned and observed after the assignment is cleared.
    local procedure Collect(Tag: Text)
    var
        Kinds: List of [Integer];
        Ids: List of [Integer];
        Labels: List of [Text];
        Index: Integer;
        Line: Text;
        Result: Text;
    begin
        Kinds.Add(9);
        Ids.Add(Query::"LT Y24 Row Query");
        Labels.Add('qry');
        Kinds.Add(6);
        Ids.Add(Xmlport::"LT Y24 Row Xml");
        Labels.Add('xml');
        Kinds.Add(3);
        Ids.Add(Report::"LT Y24 Proc Rep");
        Labels.Add('rep');
        Kinds.Add(5);
        Ids.Add(Codeunit::"LT Y24 Exec Target");
        Labels.Add('cu');
        Kinds.Add(8);
        Ids.Add(Page::"LT Y24 Row Card");
        Labels.Add('pg');
        Kinds.Add(1);
        Ids.Add(Database::"LT Y24 Row");
        Labels.Add('tbl');
        for Index := 1 to Kinds.Count() do begin
            ClearLastError();
            if TryRights(Kinds.Get(Index), Ids.Get(Index), Result) then
                Line += Labels.Get(Index) + '=' + Result + ' '
            else
                Line += Labels.Get(Index) + '=error: ' + GetLastErrorText() + ' ' + GetLastErrorCode() + ' ';
            ClearLastError();
        end;
        Names.Add(Tag);
        Values.Add(Line.TrimEnd());
    end;

    local procedure CollectTable(SetName: Code[20])
    begin
        Mock.SetExactPermissionSet(SetName);
        Collect2(SetName, 'td');
    end;

    local procedure Collect2(Tag: Text; What: Text)
    var
        Result: Text;
    begin
        ClearLastError();
        if TryRights(0, Database::"LT Y84 Guard", Result) then
            Names.Add(Tag)
        else begin
            Names.Add(Tag);
            Result := 'error: ' + GetLastErrorText() + ' ' + GetLastErrorCode();
        end;
        ClearLastError();
        Values.Add(What + '=' + Result);
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
