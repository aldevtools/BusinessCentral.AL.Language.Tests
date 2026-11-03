// Worker codeunit for TestPageBgTaskTx_Tests.al. Reports, from inside a page background
// task, what the worker's own session sees of the CALLER's transaction:
//   Keys       -- "No." of every "Test Page BgTask Row" whose "No." starts with the 'Prefix'
//                 parameter, comma-separated in key order (every row when no Prefix is given).
//                 Each test uses its own prefix, so no two tests ever issue the same read.
//   InWriteTx  -- Database.IsInWriteTransaction() inside the worker ('true' / 'false')
//   GuardedRun -- 'true' / 'false' from a guarded Codeunit.Run (return value consumed),
//                 the form the platform refuses while a write transaction is open.
// This is the shape the Base Application's "Check Gen. Jnl. Line. Backgr." (9081) uses.

codeunit 67200 "Test Page BgTask TxWorker"
{
    trigger OnRun()
    var
        Row: Record "Test Page BgTask Row";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Prefix: Text;
        Keys: Text;
    begin
        Params := Page.GetBackgroundParameters();
        if Params.Get('Prefix', Prefix) then
            Row.SetFilter("No.", Prefix + '*');
        if Row.FindSet() then
            repeat
                if Keys <> '' then
                    Keys += ',';
                Keys += Row."No.";
            until Row.Next() = 0;
        Results.Add('Keys', Keys);
        Results.Add('InWriteTx', BoolText(Database.IsInWriteTransaction()));
        Results.Add('GuardedRun', BoolText(Codeunit.Run(Codeunit::"Test Page BgTask TxNoop")));
        Page.SetBackgroundTaskResult(Results);
    end;

    local procedure BoolText(Value: Boolean): Text
    begin
        if Value then
            exit('true');
        exit('false');
    end;
}
