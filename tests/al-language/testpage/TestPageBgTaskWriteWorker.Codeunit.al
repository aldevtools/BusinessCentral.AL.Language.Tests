// Worker codeunit for TestPageBgTask_Tests.al's session-isolation probes: writes to the
// SAME table the page's TestPage caller reads, run inside a page background task. Writes
// DIRECTLY (no TryFunction) -- an earlier version wrapped the write in a [TryFunction] local
// procedure, which measured a DIFFERENT, unrelated restriction instead: real BC (BC 27.5 and
// 28.3, corpus PR #135) rejected that shape outright with "Call to the function 'INSERT' is
// not allowed inside the call to 'RootMethodScope' when it is used as a TryFunction" -- a
// TryFunction cannot be the first call made from a freshly-dispatched root scope (a
// background task's own OnRun is one), regardless of what it tries to do, so it could not
// answer "is the write visible/committed" at all. Writing directly avoids that unrelated
// restriction and lets the caller (Z_OBS_WorkerWrite_*) use its OWN TryFunction, from an
// ordinary nested call site, to observe whatever the worker's write actually does.

codeunit 60794 "Test Page BgTask WriteWorker"
{
    trigger OnRun()
    var
        Row: Record "Test Page BgTask Row";
        Params: Dictionary of [Text, Text];
        Op: Text;
        RowNo: Text;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('Op', Op);
        Params.Get('No', RowNo);

        case Op of
            'Insert':
                begin
                    Row.Init();
                    Row."No." := CopyStr(RowNo, 1, MaxStrLen(Row."No."));
                    Row.Name := 'WRITTEN-BY-WORKER';
                    Row.Insert();
                end;
            'Modify':
                begin
                    Row.Get(CopyStr(RowNo, 1, MaxStrLen(Row."No.")));
                    Row.Name := 'MODIFIED-BY-WORKER';
                    Row.Modify();
                end;
            'Rename':
                begin
                    Row.Get(CopyStr(RowNo, 1, MaxStrLen(Row."No.")));
                    Row.Rename(CopyStr(RowNo + '-R', 1, MaxStrLen(Row."No.")));
                end;
        end;
    end;
}
