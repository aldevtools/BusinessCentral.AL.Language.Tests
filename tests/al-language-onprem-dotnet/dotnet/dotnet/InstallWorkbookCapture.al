// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-excel-buffer
// Scope: installation workbook -> stored BLOB -> later session; delete flag x styling matrix.
// local object: installation captures failures without allowing them to fail publishing.
codeunit 99462 "LT Install Workbook Capture"
{
    Subtype = Install;
    trigger OnInstallAppPerCompany()
    begin
        Capture('DELETE-PLAIN', true, false);
        Capture('KEEP-PLAIN', false, false);
        Capture('DELETE-STYLED', true, true);
        Capture('KEEP-STYLED', false, true);
    end;

    local procedure Capture(ProbeCode: Code[20]; DeleteSource: Boolean; Styled: Boolean)
    var
        Observation: Record "LT Install Workbook Obs";
        Blob: Codeunit "Temp Blob";
        Input: InStream;
        Output: OutStream;
        Failure: Text;
    begin
        if not TryBuildWorkbook(Blob, ProbeCode, DeleteSource, Styled) then
            Failure := CopyStr(GetLastErrorText(), 1, 250);
        ClearLastError();
        if not Observation.Get(ProbeCode) then begin
            Observation.Init();
            Observation."Code" := ProbeCode;
            if not Observation.Insert(false) then exit;
        end;
        Clear(Observation.Workbook);
        if Blob.HasValue() then begin
            Blob.CreateInStream(Input);
            Observation.Workbook.CreateOutStream(Output);
            CopyStream(Output, Input);
        end;
        Observation."Probe Error" := CopyStr(Failure, 1, 250);
        if Observation.Modify(false) then;
    end;

    [TryFunction]
    local procedure TryBuildWorkbook(var Blob: Codeunit "Temp Blob"; ProbeCode: Code[20]; DeleteSource: Boolean; Styled: Boolean)
    var
        Writer: Record "Excel Buffer" temporary;
        Cleanup: Codeunit "Temp Blob";
        Output: OutStream;
        Note: Text;
    begin
        if Styled then Note := 'NEUTRAL-COMMENT';
        Writer.NewRow();
        Writer.AddColumn(ProbeCode, false, Note, Styled, false, false, '', Writer."Cell Type"::Text);
        Writer.CreateNewBook('InstallProbe');
        Writer.WriteSheet('', CompanyName(), UserId());
        Writer.CloseBook();
        Blob.CreateOutStream(Output);
        Writer.SaveToStream(Output, DeleteSource);
        // The false case measures keeping the source for a second export, then removes it.
        if not DeleteSource then begin
            Cleanup.CreateOutStream(Output);
            Writer.SaveToStream(Output, true);
        end;
    end;
}
