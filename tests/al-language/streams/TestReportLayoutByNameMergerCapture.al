// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/eventsubscriber
// Scope: in-scope
// Fixtures used: Report Layout ByName Sample (60530)
//
// Captures what the custom-document merger is actually handed.
//
// The rest of this suite proves the layout NAME picked the right layout — the render fork
// changes, the virtual-table rows are right. None of that proves the layout's CONTENT ever
// reaches the renderer: for a report declaring MORE THAN ONE layout, layout hydration can be
// skipped entirely, so the merger receives an EMPTY template while every by-name assertion
// still passes. The observable symptom on real ISV AL is
// "LF-XML: The template is not well-formed XML: 'Root element is missing.'" — which reads as
// a template bug rather than a platform one.
//
// This subscriber is the missing observable: it records the template bytes BC hands the
// merger, so a test can assert the SELECTED layout's own content arrived.
//
// It lives in its own non-test codeunit so it is bound automatically for the whole run, and
// it handles the render (IsHandled := true) exactly as a real ISV rendering extension would —
// that fork is the in-scope custom-merger path.

codeunit 60532 "Report Layout ByName Capture"
{
    procedure CapturedTemplate(): Text
    var
        Sample: Record "Report Layout ByName Sample";
        InStr: InStream;
        Captured: Text;
    begin
        if not Sample.Get(CaptureEntryNo()) then
            exit('');
        Sample.CalcFields("Blob Data");
        Sample."Blob Data".CreateInStream(InStr);
        InStr.ReadText(Captured);
        exit(Captured);
    end;

    procedure ClearCapture()
    var
        Sample: Record "Report Layout ByName Sample";
    begin
        if Sample.Get(CaptureEntryNo()) then
            Sample.Delete();
    end;

    local procedure CaptureEntryNo(): Integer
    begin
        exit(999);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, OnCustomDocumentMergerEx, '', true, true)]
    local procedure OnCustomDocumentMergerEx(ObjectID: Integer; ReportAction: Option SaveAsPdf,SaveAsWord,SaveAsExcel,Preview,Print,SaveAsHtml; ObjectPayload: JsonObject; var XmlData: InStream; LayoutData: InStream; var DocumentStream: OutStream; var IsHandled: Boolean)
    var
        Sample: Record "Report Layout ByName Sample";
        OutStr: OutStream;
        TemplateText: Text;
        Line: Text;
    begin
        while not LayoutData.EOS() do begin
            LayoutData.ReadText(Line);
            TemplateText += Line;
        end;

        if Sample.Get(CaptureEntryNo()) then
            Sample.Delete();
        Sample.Init();
        Sample."Entry No." := CaptureEntryNo();
        Sample.Description := 'captured template';
        Sample."Blob Data".CreateOutStream(OutStr);
        OutStr.WriteText(TemplateText);
        Sample.Insert();

        // Stand in for the ISV renderer: produce *something* so the render completes and
        // the suite's existing fork assertions keep holding.
        DocumentStream.WriteText('RLB-RENDERED');
        IsHandled := true;
    end;
}
