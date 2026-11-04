// Worker codeunit for TestPageBgTask_Tests.al's temporary-write probes -- the positive
// counterpart to "Test Page BgTask WriteWorker" (60794), which writes to the DATABASE and is
// refused. This one writes only to temporary records:
//   'TempVar'   -- a `Record "Test Page BgTask Row" temporary` variable, i.e. the very same
//                  table the refused WriteWorker writes to, so the ONLY difference between
//                  the two measurements is the `temporary` keyword on the variable.
//   'TempTable' -- a table declared TableType = Temporary, where the AL author never writes
//                  `temporary` anywhere.
// It reports back what it observed through Page.SetBackgroundTaskResult so the caller can
// assert concrete values rather than "nothing was raised".

codeunit 60784 "Test Page BgTask TempWorker"
{
    trigger OnRun()
    var
        TempRow: Record "Test Page BgTask Row" temporary;
        TempTableRow: Record "Test Page BgTask Temp Row";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Op: Text;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('Op', Op);

        case Op of
            'TempVar':
                begin
                    TempRow.Init();
                    TempRow."No." := 'TMP-1';
                    TempRow.Name := 'WRITTEN-BY-WORKER';
                    TempRow.Insert();
                    TempRow.Init();
                    TempRow."No." := 'TMP-2';
                    TempRow.Name := 'SECOND';
                    TempRow.Insert();
                    Results.Add('Count', Format(TempRow.Count()));
                    TempRow.Get('TMP-1');
                    Results.Add('Name', TempRow.Name);
                end;
            'TempTable':
                begin
                    TempTableRow.Init();
                    TempTableRow."Entry No." := 1;
                    TempTableRow.Name := 'WRITTEN-BY-WORKER';
                    TempTableRow.Insert();
                    TempTableRow.Init();
                    TempTableRow."Entry No." := 2;
                    TempTableRow.Name := 'SECOND';
                    TempTableRow.Insert();
                    Results.Add('Count', Format(TempTableRow.Count()));
                    TempTableRow.Get(1);
                    Results.Add('Name', TempTableRow.Name);
                end;
        end;

        Page.SetBackgroundTaskResult(Results);
    end;
}
