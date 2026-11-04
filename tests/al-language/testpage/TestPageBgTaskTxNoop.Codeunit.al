// Target of the guarded Codeunit.Run in Test Page BgTask TxWorker (67200) and in
// TestPageBgTaskTx_Tests.al. Does nothing, so a 'true' result means only "the platform let
// the guarded run start".

codeunit 67201 "Test Page BgTask TxNoop"
{
    trigger OnRun()
    begin
    end;
}
