// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); permission set "Company - Read" of the System Application (included across apps)
// Probe (gap cycle 6, G6-01b): the rows of Metadata Permission Set Rel. (2000000252) for own permission sets: a set that includes nothing,
//   includes one set, includes two and excludes one, includes a set of another app, a non-assignable set, and a set whose include comes
//   from a permission set extension; read order without SetCurrentKey, Get by the full key (also with the Role ID in lower case), the App ID
//   and Related App ID columns, filters on Type and Role ID, the column list (FieldRef), and writes (Insert, Modify, Delete, DeleteAll run
//   through Codeunit.Run). The System Application reads the table to copy and export permission sets. Neighbour:
//   codeunit/lt-x-object-props/XObjectProps.al:335-360 (count and Type of an include and an exclude).
// BC versions: 27.5, 28.5, 29.0.

permissionset 93201 "LT Y59 RelA"
{
    Assignable = true;
    Permissions = tabledata "LT Y59 Cap Table" = R;
}

permissionset 93202 "LT Y59 RelB"
{
    Assignable = true;
    IncludedPermissionSets = "LT Y59 RelA";
}

permissionset 93203 "LT Y59 RelC"
{
    Assignable = true;
    IncludedPermissionSets = "LT Y59 RelA", "LT Y59 RelB";
    ExcludedPermissionSets = "LT Y59 RelD";
}

permissionset 93204 "LT Y59 RelD"
{
    Assignable = true;
    Permissions = tabledata "LT Y59 NoCap Table" = R;
}

permissionset 93205 "LT Y59 RelE"
{
    Assignable = true;
    IncludedPermissionSets = "Company - Read";
}

permissionset 93206 "LT Y59 RelF"
{
    Assignable = false;
    IncludedPermissionSets = "LT Y59 RelA";
}

permissionsetextension 93200 "LT Y59 RelB Ext" extends "LT Y59 RelB"
{
    IncludedPermissionSets = "LT Y59 RelD";
}

// Runs one write on Metadata Permission Set Rel. in its OnRun, called through Codeunit.Run.
codeunit 93203 "LT Y59 Rel Writer"
{
    var
        Op: Text;
        Shown: Text;

    trigger OnRun()
    var
        Rel: Record "Metadata Permission Set Rel.";
        Module: ModuleInfo;
    begin
        Shown := '';
        NavApp.GetCurrentModuleInfo(Module);
        case Op of
            'insert':
                begin
                    Rel.Init();
                    Rel."App ID" := Module.Id();
                    Rel."Role ID" := 'LT Y59 RELX';
                    Rel."Related App ID" := Module.Id();
                    Rel."Related Role ID" := 'LT Y59 RELA';
                    Rel.Type := Rel.Type::Include;
                    Shown := Format(Rel.Insert());
                end;
            'modify':
                begin
                    Rel.Get(Module.Id(), 'LT Y59 RELC', Module.Id(), 'LT Y59 RELA');
                    Rel.Type := Rel.Type::Exclude;
                    Shown := Format(Rel.Modify());
                end;
            'delete':
                begin
                    Rel.Get(Module.Id(), 'LT Y59 RELB', Module.Id(), 'LT Y59 RELA');
                    Shown := Format(Rel.Delete());
                end;
            'deleteall':
                begin
                    Rel.SetRange("App ID", Module.Id());
                    Rel.SetRange("Role ID", 'LT Y59 RELC');
                    Rel.DeleteAll();
                    Shown := Format(Rel.Count());
                end;
        end;
    end;

    procedure RunAndObserve(NewOp: Text; var Observer: Codeunit "Probe Observer")
    begin
        Op := NewOp;
        Commit();
        if Run() then
            Observer.Observe(NewOp, 'ok|' + Shown)
        else
            Observer.ObserveError(NewOp);
    end;
}

codeunit 93202 "LT Y59 Perm Set Rel"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure OwnAppId(): Guid
    var
        Module: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Module);
        exit(Module.Id());
    end;

    local procedure AppText(AppId: Guid): Text
    begin
        if AppId = OwnAppId() then
            exit('own');
        exit(Format(AppId));
    end;

    local procedure Rows(RoleId: Code[30]): Text
    var
        Rel: Record "Metadata Permission Set Rel.";
        Result: Text;
    begin
        Rel.SetRange("App ID", OwnAppId());
        Rel.SetRange("Role ID", RoleId);
        if Rel.FindSet() then
            repeat
                Result += Format(Rel.Type) + ':' + Rel."Related Role ID" + '@' + AppText(Rel."Related App ID") + ';';
            until Rel.Next() = 0;
        exit(Format(Rel.Count()) + '|' + Result);
    end;

    [Test]
    procedure Y59_Rel_IncludeAndExclude()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('relc', Rows('LT Y59 RELC'));
        Observer.Observe('relb_with_extension', Rows('LT Y59 RELB'));
        Observer.Observe('rela_no_includes', Rows('LT Y59 RELA'));
        Observer.Observe('reld_excluded_only', Rows('LT Y59 RELD'));
        Observer.Observe('relf_not_assignable', Rows('LT Y59 RELF'));
        Observer.Observe('rele_other_app', Rows('LT Y59 RELE'));
        Observer.Finish();
    end;

    [Test]
    procedure Y59_Rel_Get_And_IsEmpty()
    var
        Rel: Record "Metadata Permission Set Rel.";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get_upper', Format(Rel.Get(OwnAppId(), 'LT Y59 RELC', OwnAppId(), 'LT Y59 RELA')));
        Observer.Observe('get_upper_type', Format(Rel.Type));
        Clear(Rel);
        Observer.Observe('get_lower', Format(Rel.Get(OwnAppId(), 'lt y59 relc', OwnAppId(), 'lt y59 rela')));
        Observer.Observe('get_lower_role_id', Rel."Role ID");
        Observer.Observe('get_excluded', Format(Rel.Get(OwnAppId(), 'LT Y59 RELC', OwnAppId(), 'LT Y59 RELD')));
        Observer.Observe('get_excluded_type', Format(Rel.Type));
        Observer.Observe('get_missing', Format(Rel.Get(OwnAppId(), 'LT Y59 RELA', OwnAppId(), 'LT Y59 RELB')));
        Rel.Reset();
        Rel.SetRange("App ID", OwnAppId());
        Rel.SetRange("Role ID", 'LT Y59 RELA');
        Observer.Observe('isempty_no_includes', Format(Rel.IsEmpty()));
        Rel.SetRange("Role ID", 'lt y59 relc');
        Observer.Observe('setrange_lower_count', Format(Rel.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Y59_Rel_AppIdColumns()
    var
        Rel: Record "Metadata Permission Set Rel.";
        Observer: Codeunit "Probe Observer";
    begin
        Rel.SetRange("Role ID", 'LT Y59 RELE');
        Observer.Observe('rele_count_without_app_filter', Format(Rel.Count()));
        if Rel.FindFirst() then begin
            Observer.Observe('rele_app_id', AppText(Rel."App ID"));
            Observer.Observe('rele_related_app_id', AppText(Rel."Related App ID"));
            Observer.Observe('rele_related_role_id', Rel."Related Role ID");
        end;
        Rel.SetRange("Role ID", 'LT Y59 RELB');
        if Rel.FindFirst() then begin
            Observer.Observe('relb_app_id', AppText(Rel."App ID"));
            Observer.Observe('relb_related_app_id', AppText(Rel."Related App ID"));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y59_Rel_FilterByType()
    var
        Rel: Record "Metadata Permission Set Rel.";
        Observer: Codeunit "Probe Observer";
    begin
        Rel.SetRange("App ID", OwnAppId());
        Rel.SetRange("Role ID", 'LT Y59 RELC');
        Rel.SetRange(Type, Rel.Type::Include);
        Observer.Observe('relc_include', Format(Rel.Count()));
        Rel.SetRange(Type, Rel.Type::Exclude);
        Observer.Observe('relc_exclude', Format(Rel.Count()));
        Rel.SetRange(Type);
        Rel.SetFilter("Role ID", 'LT Y59 REL*');
        Observer.Observe('own_rel_sets_count', Format(Rel.Count()));
        Rel.SetRange("Role ID");
        Rel.SetRange("Related Role ID", 'LT Y59 RELA');
        Observer.Observe('related_rela_count', Format(Rel.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Y59_Rel_Columns()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        KRef: KeyRef;
        KeyText: Text;
        i: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.Open(Database::"Metadata Permission Set Rel.");
        for i := 1 to 5 do begin
            FldRef := RecRef.Field(i);
            Observer.Observe('field_' + Format(i), FldRef.Name + '|' + Format(FldRef.Type) + '|' + Format(FldRef.Length) + '|' + Format(FldRef.Class));
        end;
        KRef := RecRef.KeyIndex(1);
        for i := 1 to KRef.FieldCount() do
            KeyText += KRef.FieldIndex(i).Name + ',';
        Observer.Observe('key_1', KeyText);
        Observer.Observe('key_count', Format(RecRef.KeyCount()));
        Observer.Finish();
    end;

    [Test]
    procedure Y59_Rel_Writes()
    var
        Writer: Codeunit "LT Y59 Rel Writer";
        Observer: Codeunit "Probe Observer";
    begin
        Writer.RunAndObserve('insert', Observer);
        Clear(Writer);
        Writer.RunAndObserve('modify', Observer);
        Clear(Writer);
        Writer.RunAndObserve('delete', Observer);
        Clear(Writer);
        Writer.RunAndObserve('deleteall', Observer);
        Observer.Observe('relc_after_writes', Rows('LT Y59 RELC'));
        Observer.Observe('relb_after_writes', Rows('LT Y59 RELB'));
        Observer.Finish();
    end;
}
