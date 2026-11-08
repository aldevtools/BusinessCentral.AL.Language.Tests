// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors-using-try-methods
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT CU Row (85300)
// Probe (al-runner issue 7143): what Insert, Modify, Delete, DeleteAll, ModifyAll and Rename inside a [TryFunction] do when the service tier
//   setting DisableWriteInsideTryFunctions is false (SaaS). This app runs only in the CI job "BC TryWrites", which sets that value through
//   bc-linux's server_settings input. Deny mode (the container default, error TryFunctionWrite) is pinned in tests/al-language/errors/CuTryTests.al.
// BC versions: 27.5, 28.5, 29.0

codeunit 81700 "LT TW Allowed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "LT CU Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'a';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'b';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'c';
        Row.Insert();
        Commit();
        ClearLastError();
    end;

    local procedure State(): Text
    var
        Row: Record "LT CU Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + '=' + Row.Name + ';';
            until Row.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryWrite(Op: Text; FailAfter: Boolean)
    var
        Row: Record "LT CU Row";
    begin
        case Op of
            'insert':
                begin
                    Row.Id := 10;
                    Row.Name := 'new';
                    Row.Insert();
                end;
            'modify':
                begin
                    Row.Get(1);
                    Row.Name := 'mod';
                    Row.Modify();
                end;
            'delete':
                begin
                    Row.Get(1);
                    Row.Delete();
                end;
            'deleteall':
                Row.DeleteAll();
            'modifyall':
                Row.ModifyAll(Name, 'all');
            'rename':
                begin
                    Row.Get(1);
                    Row.Rename(11);
                end;
            'commit':
                Commit();
        end;
        if FailAfter then
            Error('error after write');
    end;

    local procedure Probe(Op: Text; FailAfter: Boolean)
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        Ok := TryWrite(Op, FailAfter);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('lasterror', GetLastErrorText());
        Observer.Observe('lastcode', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('state', State());
        Commit();
        Observer.Observe('state after commit', State());
        Observer.Finish();
    end;

    [Test]
    procedure Insert_InTryFunction_Succeeds() begin Probe('insert', false); end;

    [Test]
    procedure Insert_InTryFunction_ErrorAfter() begin Probe('insert', true); end;

    [Test]
    procedure Modify_InTryFunction_Succeeds() begin Probe('modify', false); end;

    [Test]
    procedure Modify_InTryFunction_ErrorAfter() begin Probe('modify', true); end;

    [Test]
    procedure Delete_InTryFunction_Succeeds() begin Probe('delete', false); end;

    [Test]
    procedure Delete_InTryFunction_ErrorAfter() begin Probe('delete', true); end;

    [Test]
    procedure DeleteAll_InTryFunction_Succeeds() begin Probe('deleteall', false); end;

    [Test]
    procedure DeleteAll_InTryFunction_ErrorAfter() begin Probe('deleteall', true); end;

    [Test]
    procedure ModifyAll_InTryFunction_Succeeds() begin Probe('modifyall', false); end;

    [Test]
    procedure ModifyAll_InTryFunction_ErrorAfter() begin Probe('modifyall', true); end;

    [Test]
    procedure Rename_InTryFunction_Succeeds() begin Probe('rename', false); end;

    [Test]
    procedure Rename_InTryFunction_ErrorAfter() begin Probe('rename', true); end;

    [Test]
    procedure Commit_InTryFunction_Succeeds() begin Probe('commit', false); end;
}
