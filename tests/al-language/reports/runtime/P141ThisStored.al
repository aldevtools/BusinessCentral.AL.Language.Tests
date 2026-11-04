// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 71551, log 71552, keeper (SingleInstance) 71553, publisher 71554, report 71555, subscriber 71556, test 71557
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the report parameter stored in a global of a SingleInstance codeunit (by a static subscriber, in OnPreReport) and used after the report finished: values read through the stored variable, errors caught with a TryFunction, cleared variable, second run replaces the stored one
// Known compile facts (not written): `this` to a var parameter gives AL0130; a Page parameter receiving `this` from a page gives AL0133.
// BC versions: 29 (27 and 28 by CI)

table 71551 "LT P141 S Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71552 "LT P141 S Log"
{
    SingleInstance = true;

    var
        Items: List of [Text];

    procedure Add(Value: Text)
    begin
        Items.Add(Value);
    end;

    procedure Reset()
    begin
        Clear(Items);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        Item: Text;
    begin
        foreach Item in Items do begin
            if Result <> '' then
                Result += ' | ';
            Result += Item;
        end;
        exit(Result);
    end;
}

codeunit 71553 "LT P141 S Keeper"
{
    SingleInstance = true;

    var
        Stored: Report "LT P141 S Rpt";
        Has: Boolean;
        Result: Text;

    procedure Store(Rpt: Report "LT P141 S Rpt")
    begin
        Stored := Rpt;
        Has := true;
    end;

    procedure HasStored(): Boolean
    begin
        exit(Has);
    end;

    procedure Marker(): Text
    begin
        exit(Stored.GetMarker());
    end;

    procedure ChangeStored(Value: Text)
    begin
        Stored.SetMarker(Value);
    end;

    procedure ClearStored()
    begin
        Clear(Stored);
    end;

    [TryFunction]
    local procedure TryMarker()
    begin
        Result := Stored.GetMarker();
    end;

    [TryFunction]
    local procedure TryChange(Value: Text)
    begin
        Stored.SetMarker(Value);
    end;

    [TryFunction]
    local procedure TryRun()
    begin
        Stored.Run();
    end;

    procedure ReadSafe(): Text
    begin
        Result := '';
        if TryMarker() then
            exit('ok:' + Result);
        exit('error:' + CopyStr(GetLastErrorText(), 1, 120) + '|' + GetLastErrorCode());
    end;

    procedure ChangeSafe(Value: Text): Text
    begin
        if TryChange(Value) then
            exit('ok');
        exit('error:' + CopyStr(GetLastErrorText(), 1, 120) + '|' + GetLastErrorCode());
    end;

    procedure RunSafe(): Text
    begin
        if TryRun() then
            exit('ok');
        exit('error:' + CopyStr(GetLastErrorText(), 1, 120) + '|' + GetLastErrorCode());
    end;
}

codeunit 71554 "LT P141 S Pub"
{
    [IntegrationEvent(false, false)]
    procedure OnX(Rpt: Report "LT P141 S Rpt"; Where: Text)
    begin
    end;
}

report 71555 "LT P141 S Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P141 S Row")
        {
            DataItemTableView = sorting(Id);

            trigger OnAfterGetRecord()
            begin
                Marker := 'row' + Format(Row.Id);
            end;
        }
    }

    var
        Marker: Text;
        Pub: Codeunit "LT P141 S Pub";
        Log: Codeunit "LT P141 S Log";
        Keeper: Codeunit "LT P141 S Keeper";

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;

    procedure SetMarker(Value: Text)
    begin
        Marker := Value;
    end;

    trigger OnPreReport()
    begin
        Marker := 'pre';
        Pub.OnX(this, 'pre');
        Log.Add('during pre: keeper sees=' + Keeper.Marker());
    end;

    trigger OnPostReport()
    begin
        Marker := 'post';
        Log.Add('during post: keeper sees=' + Keeper.Marker());
    end;
}

codeunit 71556 "LT P141 S Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT P141 S Pub", 'OnX', '', false, false)]
    local procedure OnPubX(Rpt: Report "LT P141 S Rpt"; Where: Text)
    var
        Keeper: Codeunit "LT P141 S Keeper";
    begin
        Keeper.Store(Rpt);
    end;
}

codeunit 71557 "LT P141 S Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(Count: Integer)
    var
        Row: Record "LT P141 S Row";
        Log: Codeunit "LT P141 S Log";
        i: Integer;
    begin
        Row.DeleteAll();
        Log.Reset();
        for i := 1 to Count do begin
            Row.Id := i;
            Row.Insert();
        end;
    end;

    local procedure RunInScope()
    var
        Rpt: Report "LT P141 S Rpt";
    begin
        Rpt.UseRequestPage(false);
        Rpt.Run();
    end;

    [Test]
    procedure P141_StoredAfterRun_ReadAndChange()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 S Log";
        Keeper: Codeunit "LT P141 S Keeper";
    begin
        Seed(2);
        Keeper.ClearStored();
        RunInScope();
        Observer.Observe('log', Log.Joined());
        Observer.Observe('has stored', Format(Keeper.HasStored()));
        Observer.Observe('read after run (run scope left)', Keeper.ReadSafe());
        Observer.Observe('change after run', Keeper.ChangeSafe('later'));
        Observer.Observe('read after change', Keeper.ReadSafe());
        Observer.Expect('log', 'during pre: keeper sees=pre | during post: keeper sees=post');
        Observer.Expect('has stored', 'Yes');
        Observer.Expect('read after run (run scope left)', 'ok:post');
        Observer.Expect('change after run', 'ok');
        Observer.Expect('read after change', 'ok:later');
        Observer.Verify();
    end;

    [Test]
    procedure P141_StoredAfterRun_SameVariableInScope()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P141 S Log";
        Keeper: Codeunit "LT P141 S Keeper";
        Rpt: Report "LT P141 S Rpt";
    begin
        Seed(1);
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('keeper read', Keeper.ReadSafe());
        Observer.Observe('own read', Rpt.GetMarker());
        Rpt.SetMarker('own-change');
        Observer.Observe('keeper read after own change', Keeper.ReadSafe());
        Keeper.ChangeStored('keeper-change');
        Observer.Observe('own read after keeper change', Rpt.GetMarker());
        Observer.Observe('log', Log.Joined());
        Observer.Expect('keeper read', 'ok:post');
        Observer.Expect('own read', '');
        Observer.Expect('keeper read after own change', 'ok:post');
        Observer.Expect('own read after keeper change', 'own-change');
        Observer.Expect('log', 'during pre: keeper sees=pre | during post: keeper sees=post');
        Observer.Verify();
    end;

    [Test]
    procedure P141_StoredAfterRun_RunAgain()
    var
        Observer: Codeunit "Probe Observer";
        Keeper: Codeunit "LT P141 S Keeper";
    begin
        Seed(1);
        RunInScope();
        Observer.Observe('read after first run', Keeper.ReadSafe());
        Observer.Observe('run the stored report again', Keeper.RunSafe());
        Observer.Observe('read after stored run', Keeper.ReadSafe());
        Observer.Expect('read after first run', 'ok:post');
        Observer.Expect('run the stored report again', 'error:The object has been run. Use the function CLEAR(Report).|ObjectHasAlreadyBeenRun');
        Observer.Expect('read after stored run', 'ok:');
        Observer.Verify();
    end;

    [Test]
    procedure P141_StoredAfterRun_Cleared()
    var
        Observer: Codeunit "Probe Observer";
        Keeper: Codeunit "LT P141 S Keeper";
    begin
        Seed(1);
        RunInScope();
        Keeper.ClearStored();
        Observer.Observe('read after clear', Keeper.ReadSafe());
        Observer.Observe('change after clear', Keeper.ChangeSafe('x'));
        Observer.Observe('read after clear and change', Keeper.ReadSafe());
        Observer.Expect('read after clear', 'ok:');
        Observer.Expect('change after clear', 'ok');
        Observer.Expect('read after clear and change', 'ok:x');
        Observer.Verify();
    end;

    [Test]
    procedure P141_StoredAfterRun_SecondRunReplaces()
    var
        Observer: Codeunit "Probe Observer";
        Keeper: Codeunit "LT P141 S Keeper";
        Rpt1: Report "LT P141 S Rpt";
        Rpt2: Report "LT P141 S Rpt";
    begin
        Seed(1);
        Rpt1.UseRequestPage(false);
        Rpt1.Run();
        Rpt1.SetMarker('first');
        Observer.Observe('keeper after first', Keeper.ReadSafe());
        Rpt2.UseRequestPage(false);
        Rpt2.Run();
        Rpt2.SetMarker('second');
        Observer.Observe('keeper after second', Keeper.ReadSafe());
        Observer.Observe('rpt1', Rpt1.GetMarker());
        Observer.Observe('rpt2', Rpt2.GetMarker());
        Observer.Expect('keeper after first', 'ok:post');
        Observer.Expect('keeper after second', 'ok:post');
        Observer.Expect('rpt1', 'first');
        Observer.Expect('rpt2', 'second');
        Observer.Verify();
    end;
}
