// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-mediaid-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/mediaset/mediaset-mediaid-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Media (60980)
// BC versions: 27.5+
//
// Companion of StefanMaron/BusinessCentral.AL.Runner#4775: what MediaId() answers on a Media
// or MediaSet field that holds no media, and whether two record variables reading the same
// row agree on it. Every IsNullGuid assertion prints the value it read, so a red leg records
// what the service tier answered.
codeunit 60243 "Test Media Empty MediaId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Media_MediaId_InitNotInserted_IsNullGuid()
    // CLAIM: an Init'ed, never-inserted record's empty Media field answers a null MediaId.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();

        Rec.Init();
        Rec.Code := 'E0';

        Assert.IsTrue(IsNullGuid(Rec.Picture.MediaId()), 'Media.MediaId() on an empty field, not inserted, must be null; read ' + Format(Rec.Picture.MediaId()));
    end;

    [Test]
    procedure MediaSet_MediaId_InitNotInserted_IsNullGuid()
    // CLAIM: an Init'ed, never-inserted record's empty MediaSet field answers a null MediaId.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();

        Rec.Init();
        Rec.Code := 'E0';

        Assert.IsTrue(IsNullGuid(Rec.Images.MediaId()), 'MediaSet.MediaId() on an empty field, not inserted, must be null; read ' + Format(Rec.Images.MediaId()));
    end;

    [Test]
    procedure Media_MediaId_InitInsert_IsNullGuid()
    // CLAIM: after Init + Insert, an empty Media field still answers a null MediaId.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();

        Rec.Init();
        Rec.Code := 'E1';
        Rec.Insert();

        Assert.IsTrue(IsNullGuid(Rec.Picture.MediaId()), 'Media.MediaId() on an empty field after Insert must be null; read ' + Format(Rec.Picture.MediaId()));
    end;

    [Test]
    procedure MediaSet_MediaId_InitInsert_IsNullGuid()
    // CLAIM: after Init + Insert, an empty MediaSet field still answers a null MediaId.
    var
        Rec: Record "ALT Media";
    begin
        Initialize();

        Rec.Init();
        Rec.Code := 'E1';
        Rec.Insert();

        Assert.IsTrue(IsNullGuid(Rec.Images.MediaId()), 'MediaSet.MediaId() on an empty field after Insert must be null; read ' + Format(Rec.Images.MediaId()));
    end;

    [Test]
    procedure Media_MediaId_EmptyField_GetIntoTwoVariables_IsNullAndEqual()
    // CLAIM: two record variables that Get the same row with an empty Media field both answer
    // a null MediaId, so they agree.
    var
        Rec: Record "ALT Media";
        First: Record "ALT Media";
        Second: Record "ALT Media";
    begin
        Initialize();

        Rec.Init();
        Rec.Code := 'E2';
        Rec.Insert();

        First.Get('E2');
        Second.Get('E2');

        Assert.AreEqual(First.Picture.MediaId(), Second.Picture.MediaId(), 'two reads of one row must answer one Media.MediaId()');
        Assert.IsTrue(IsNullGuid(First.Picture.MediaId()), 'Media.MediaId() on an empty field read back by Get must be null; read ' + Format(First.Picture.MediaId()));
    end;

    [Test]
    procedure MediaSet_MediaId_EmptyField_GetIntoTwoVariables_IsNullAndEqual()
    // CLAIM: two record variables that Get the same row with an empty MediaSet field both
    // answer a null MediaId, so they agree.
    var
        Rec: Record "ALT Media";
        First: Record "ALT Media";
        Second: Record "ALT Media";
    begin
        Initialize();

        Rec.Init();
        Rec.Code := 'E3';
        Rec.Insert();

        First.Get('E3');
        Second.Get('E3');

        Assert.AreEqual(First.Images.MediaId(), Second.Images.MediaId(), 'two reads of one row must answer one MediaSet.MediaId()');
        Assert.IsTrue(IsNullGuid(First.Images.MediaId()), 'MediaSet.MediaId() on an empty field read back by Get must be null; read ' + Format(First.Images.MediaId()));
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
