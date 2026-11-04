// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P102 Rec (71615), LT P102 Helper (71616)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Skipped (OnPrem or not existing): Media.ExportFile, Media.ImportFile, MediaSet.ExportFile, MediaSet.ImportFile (File based), Blob.Export/Import, Media.ImportStream with 4 arguments (AL0126).
// BC versions: 29 (27 and 28 by CI)

codeunit 71623 "LT P102 Media"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P102_MediaImportStreamPng()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Ins: InStream;
        Out: OutStream;
        TargetIns: InStream;
        Id: Guid;
        Back: Integer;
        B: Byte;
    begin
        Helper.Fresh(Rec);
        Helper.Png(Rec);
        Rec.CalcFields(Data);
        Observer.Observe('pnglen', Format(Rec.Data.Length()));
        Rec.Data.CreateInStream(Ins);
        Id := Rec.Pic.ImportStream(Ins, 'desc', 'image/png');
        Observer.Observe('idnull', Format(IsNullGuid(Id)));
        Observer.Observe('hasvalue_before_modify', Format(Rec.Pic.HasValue()));
        Rec.Modify();
        Rec.Get(1);
        Observer.Observe('hasvalue_after', Format(Rec.Pic.HasValue()));
        Observer.Observe('mediaid_equal', Format(Rec.Pic.MediaId() = Id));
        Observer.Expect('pnglen', '70');
        Observer.Expect('idnull', 'No');
        Observer.Expect('hasvalue_before_modify', 'Yes');
        Observer.Expect('hasvalue_after', 'Yes');
        Observer.Expect('mediaid_equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P102_MediaSetImportStream()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Ins: InStream;
        Id: Guid;
    begin
        Helper.Fresh(Rec);
        Helper.Png(Rec);
        Rec.Data.CreateInStream(Ins);
        Id := Rec.Pics.ImportStream(Ins, 'desc', 'image/png');
        Observer.Observe('idnull', Format(IsNullGuid(Id)));
        Rec.Modify();
        Rec.Get(1);
        Observer.Observe('count', Format(Rec.Pics.Count()));
        Observer.Observe('item1_equal', Format(Rec.Pics.Item(1) = Id));
        Observer.Expect('idnull', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('item1_equal', 'No');
        Observer.Verify();
    end;
}
