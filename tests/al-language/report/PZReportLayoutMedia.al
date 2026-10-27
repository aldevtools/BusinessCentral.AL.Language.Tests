// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-layouts
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 69352
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816). Other BC versions are checked by the CI matrix.
//
// The Layout Media column of the Report Layout List rows (RDLC, Word, Excel) reads HasValue No for the layouts of the installed apps; the rows themselves exist.
// BC versions: 29.0
codeunit 69352 "PZ Report Layout Media"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(var Layout: Record "Report Layout List"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Start: Text;
        Size: Integer;
    begin
        if not Layout.Layout.HasValue() then
            exit('no value');
        TempBlob.CreateOutStream(OutS);
        Layout.Layout.ExportStream(OutS);
        Size := TempBlob.Length();
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        InS.ReadText(Start, 5);
        exit('has value, size>0=' + Format(Size > 0) + ' starts=[' + Start + ']');
    end;

    [Test]
    procedure Layout_Media_OfBuiltInLayouts()
    var
        Layout: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
    begin
        Layout.SetRange("Layout Format", Layout."Layout Format"::RDLC);
        Layout.FindFirst();
        Observer.Observe('first rdlc layout', Describe(Layout));
        Layout.SetRange("Layout Format", Layout."Layout Format"::Word);
        Layout.FindFirst();
        Observer.Observe('first word layout', Describe(Layout));
        Layout.SetRange("Layout Format", Layout."Layout Format"::Excel);
        if Layout.FindFirst() then
            Observer.Observe('first excel layout', Describe(Layout))
        else
            Observer.Observe('first excel layout', 'no row');
        Layout.SetRange("Layout Format");
        Layout.SetRange("Report ID", 1306);
        Observer.Observe('layouts of report 1306', Format(Layout.Count() > 0));
        Observer.Expect('first rdlc layout', 'no value');
        Observer.Expect('first word layout', 'no value');
        Observer.Expect('first excel layout', 'no value');
        Observer.Expect('layouts of report 1306', 'Yes');
        Observer.Verify();
    end;

    // Writer SO (2026-10-28), aldevtools/BusinessCentral.AL.Runner#5993: ExportStream of the empty Layout of a built-in layout row:
    // what it answers and how many bytes it writes.
    local procedure SoExport(var Layout: Record "Report Layout List"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Answer: Boolean;
    begin
        TempBlob.CreateOutStream(OutS);
        Answer := Layout.Layout.ExportStream(OutS);
        exit('returned=' + Format(Answer) + ' len=' + Format(TempBlob.Length()) + ' hasvalue after=' + Format(Layout.Layout.HasValue()));
    end;

    [Test]
    procedure SO_Layout_ExportStream_OfBuiltInLayouts()
    var
        Layout: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
    begin
        Layout.SetRange("Layout Format", Layout."Layout Format"::RDLC);
        Layout.FindFirst();
        Observer.Observe('first rdlc layout', SoExport(Layout));
        Layout.SetRange("Layout Format", Layout."Layout Format"::Word);
        Layout.FindFirst();
        Observer.Observe('first word layout', SoExport(Layout));
        Observer.Finish();
    end;
}
