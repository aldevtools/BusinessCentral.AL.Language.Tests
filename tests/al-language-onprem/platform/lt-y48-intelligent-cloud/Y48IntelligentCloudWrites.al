// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope (OnPrem app: Intelligent Cloud is Scope = OnPrem, AL0296 in a Cloud app, must-not-compile 0021)
// Fixtures used: Probe Observer (69160); LT PT OnPrem Ops (61247, PtOnPremOps.al); self-contained objects 98703, 98704
// Probe: gap cycle 5, spec G5-02 (writer Y48), the Intelligent Cloud part. Microsoft's Upgrade Tag tests run
//        `if not IntelligentCloud.Get() then IntelligentCloud.Insert(); Enabled := true; Modify();` on this table. Each write runs in a
//        codeunit of its own (Codeunit.Run), so an error BC raises is observed and the test goes on. The read side is pinned by
//        PtOnPremTables.al QZ_IntelligentCloud_Read (empty table, Get No).
// BC versions: 27, 28, 29

codeunit 98704 "LT Y48 IC Step"
{
    var
        Step: Text;
        Result: Text;

    procedure SetStep(NewStep: Text)
    begin
        Step := NewStep;
        Result := '';
    end;

    procedure GetResult(): Text
    begin
        exit(Result);
    end;

    trigger OnRun()
    var
        IC: Record "Intelligent Cloud";
    begin
        case Step of
            'get or insert':
                if not IC.Get() then
                    Result := 'get=No insert=' + Format(IC.Insert())
                else
                    Result := 'get=Yes';
            'insert':
                Result := Format(IC.Insert());
            'modify enabled':
                begin
                    IC.Get();
                    IC.Enabled := true;
                    Result := Format(IC.Modify());
                end;
            'delete':
                begin
                    IC.Get();
                    Result := Format(IC.Delete());
                end;
        end;
    end;
}

codeunit 98703 "LT Y48 Intelligent Cloud"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Name: Text; Step: Text)
    var
        StepCu: Codeunit "LT Y48 IC Step";
    begin
        StepCu.SetStep(Step);
        ClearLastError();
        if StepCu.Run() then
            Observer.Observe(Name, 'ok:' + StepCu.GetResult())
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure State(): Text
    var
        IC: Record "Intelligent Cloud";
        Found: Boolean;
    begin
        Found := IC.Get();
        exit('get=' + Format(Found) + ' enabled=' + Format(IC.Enabled) + ' isempty=' + Format(IC.IsEmpty()) + ' count=' + Format(IC.Count()));
    end;

    [Test]
    procedure IC_InsertModifyGet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('before', State());
        Run(Observer, 'get or insert', 'get or insert');
        Observer.Observe('after insert', State());
        Run(Observer, 'modify enabled', 'modify enabled');
        Observer.Observe('after modify', State());
        Run(Observer, 'insert again', 'insert');
        Run(Observer, 'delete', 'delete');
        Observer.Observe('after delete', State());
        Observer.Finish();
    end;

    [Test]
    procedure IC_Standard()
    var
        Observer: Codeunit "Probe Observer";
        Ops: Codeunit "LT PT OnPrem Ops";
        TableNo: Integer;
    begin
        TableNo := Database::"Intelligent Cloud";
        Observer.Observe('has_rows', Ops.Perform(TableNo, 'hasrows', '', false));
        Observer.Observe('insert', Ops.Perform(TableNo, 'insert', '1=;2=false', true));
        Observer.Observe('find_inserted', Ops.Perform(TableNo, 'find', '1=', false));
        Observer.Observe('count_inserted', Ops.Perform(TableNo, 'count', '1=', false));
        Observer.Observe('insert_duplicate', Ops.Perform(TableNo, 'insert', '1=;2=false', true));
        Observer.Observe('modify', Ops.Perform(TableNo, 'modify', '1=|2=true', true));
        Observer.Observe('find_modified', Ops.Perform(TableNo, 'find', '1=', false));
        Observer.Observe('delete', Ops.Perform(TableNo, 'delete', '1=', true));
        Observer.Observe('count_deleted', Ops.Perform(TableNo, 'count', '1=', false));
        Observer.Observe('insert_other_key', Ops.Perform(TableNo, 'insert', '1=LTY48;2=true', false));
        Observer.Observe('count_all', Ops.Perform(TableNo, 'count', '', false));
        Observer.Observe('delete_all_no_triggers', Ops.Perform(TableNo, 'deleteall', '', false));
        Observer.Observe('count_after_delete_all', Ops.Perform(TableNo, 'count', '', false));
        Observer.Finish();
    end;
}
