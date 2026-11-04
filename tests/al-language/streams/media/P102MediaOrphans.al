// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P102 Rec (71615), LT P102 Helper (71616)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Risky (static FindOrphans call form unsure, may not compile): kept in its own file; only the relation "an imported media that is deleted with its record appears or not among the orphans" is observed, never the absolute list.
// BC versions: 29 (27 and 28 by CI)

codeunit 71624 "LT P102 Media Orphans"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P102_MediaFindOrphans()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Ins: InStream;
        Id: Guid;
        Orphans: List of [Guid];
    begin
        Helper.Fresh(Rec);
        Helper.Png(Rec);
        Rec.Data.CreateInStream(Ins);
        Id := Rec.Pic.ImportStream(Ins, 'desc', 'image/png');
        Rec.Modify();
        Orphans := Media.FindOrphans();
        Observer.Observe('attached_in_orphans', Format(Orphans.Contains(Id)));
        Rec.Delete();
        Orphans := Media.FindOrphans();
        Observer.Observe('deleted_in_orphans', Format(Orphans.Contains(Id)));
        Observer.Expect('attached_in_orphans', 'No');
        Observer.Expect('deleted_in_orphans', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P102_MediaSetFindOrphans()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Ins: InStream;
        Id: Guid;
        Orphans: List of [Guid];
    begin
        Helper.Fresh(Rec);
        Helper.Png(Rec);
        Rec.Data.CreateInStream(Ins);
        Id := Rec.Pics.ImportStream(Ins, 'desc', 'image/png');
        Rec.Modify();
        Orphans := MediaSet.FindOrphans();
        Observer.Observe('attached_in_orphans', Format(Orphans.Contains(Id)));
        Rec.Delete();
        Orphans := MediaSet.FindOrphans();
        Observer.Observe('deleted_in_orphans', Format(Orphans.Contains(Id)));
        Observer.Expect('attached_in_orphans', 'No');
        Observer.Expect('deleted_in_orphans', 'No');
        Observer.Verify();
    end;
}
