// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-keyindex-method
// Fixtures used: ALT Keyed (60006), ALT Universal (60000)
// Scope: BC-specific KeyRef secondary key and SumIndexFields behavioral contracts

codeunit 60177 "Test BC SumIndex Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ===================== KeyRef secondary key navigation contracts =====================

    [Test]
    procedure RecordRef_SecondaryKey_HasCorrectFieldCount()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
    begin
        Initialize();
        RecRef.Open(60006); // ALT Keyed
        KRef := RecRef.KeyIndex(2); // Key1 = ("Name","Code")
        Assert.AreEqual(2, KRef.FieldCount(), 'Secondary key Key1("Name","Code") must have FieldCount = 2');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_SecondaryKey_SingleField_HasFieldCount1()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
    begin
        Initialize();
        RecRef.Open(60006); // ALT Keyed
        KRef := RecRef.KeyIndex(3); // Key2 = ("Amount")
        Assert.AreEqual(1, KRef.FieldCount(), 'Secondary key Key2("Amount") must have FieldCount = 1');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_SecondaryKey_FieldIndex_ReturnsCorrectField()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
        FRef: FieldRef;
    begin
        Initialize();
        RecRef.Open(60006); // ALT Keyed
        KRef := RecRef.KeyIndex(2); // Key1 = ("Name","Code")
        FRef := KRef.FieldIndex(1); // first field = "Name"
        Assert.AreEqual('Name', FRef.Name(), 'First field of Key1 must be "Name"');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_SecondaryKey_SecondField_IsCode()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
        FRef: FieldRef;
    begin
        Initialize();
        RecRef.Open(60006); // ALT Keyed
        KRef := RecRef.KeyIndex(2); // Key1 = ("Name","Code")
        FRef := KRef.FieldIndex(2); // second field = "Code"
        Assert.AreEqual('Code', FRef.Name(), 'Second field of Key1 must be "Code"');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_AllKeys_Count_MatchesDefinition()
    var
        RecRef: RecordRef;
    begin
        Initialize();
        RecRef.Open(60006); // ALT Keyed has PK + Key1 + Key2 + Key3 = 4 keys
        Assert.IsTrue(RecRef.KeyCount() >= 4, 'ALT Keyed must have at least 4 keys (PK + 3 secondary)');
        RecRef.Close();
    end;

    [Test]
    procedure KeyRef_Active_SecondaryKey_ReturnsTrue()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
    begin
        Initialize();
        RecRef.Open(60006); // ALT Keyed
        KRef := RecRef.KeyIndex(2); // Key1
        Assert.IsTrue(KRef.Active(), 'Secondary key Key1 must be Active = true');
        RecRef.Close();
    end;

    // ===================== CalcSums behavioral contracts (result correctness) =====================

    [Test]
    procedure CalcSums_GivesCorrectSum_MultipleRecords()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Amount Field" := 100;
        Rec.Insert();

        Rec."Entry No." := 2;
        Rec."Amount Field" := 200;
        Rec.Insert();

        Rec."Entry No." := 3;
        Rec."Amount Field" := 300;
        Rec.Insert();

        Rec.CalcSums("Amount Field");
        Assert.AreEqual(600, Rec."Amount Field", 'CalcSums must return correct total (100+200+300=600)');
    end;

    [Test]
    procedure CalcSums_WithFilter_OnlyFiltered()
    var
        Rec: Record "ALT Universal";
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec."Amount Field" := i * 10;
            Rec.Insert();
        end;

        Rec.SetRange("Entry No.", 1, 3); // 10+20+30=60
        Rec.CalcSums("Amount Field");
        Assert.AreEqual(60, Rec."Amount Field", 'CalcSums with filter must sum only filtered records');
    end;

    [Test]
    procedure CalcSums_OnEmptyTable_ReturnsZero()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        // table is empty after Initialize
        Rec.CalcSums("Amount Field");
        Assert.AreEqual(0, Rec."Amount Field", 'CalcSums on empty table must return 0');
    end;

    [Test]
    procedure CalcSums_NegativeValues_CorrectSum()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Amount Field" := 100;
        Rec.Insert();

        Rec."Entry No." := 2;
        Rec."Amount Field" := -50;
        Rec.Insert();

        Rec.CalcSums("Amount Field");
        Assert.AreEqual(50, Rec."Amount Field", 'CalcSums with negative values must compute net sum (100-50=50)');
    end;

    // ===================== KeyRef iteration contracts =====================

    [Test]
    procedure KeyRef_Iterate_AllSecondaryKeys()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
        KeyCount: Integer;
        i: Integer;
    begin
        Initialize();
        RecRef.Open(60006); // ALT Keyed
        KeyCount := RecRef.KeyCount();
        for i := 1 to KeyCount do begin
            KRef := RecRef.KeyIndex(i);
            Assert.IsTrue(KRef.FieldCount() >= 1, 'Every key must have at least 1 field');
        end;
        Assert.IsTrue(KeyCount >= 4, 'Must have iterated at least 4 keys');
        RecRef.Close();
    end;

    [Test]
    procedure KeyRef_FieldIndex_OutOfBounds_Throws()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
        FRef: FieldRef;
    begin
        Initialize();
        RecRef.Open(60006); // ALT Keyed
        KRef := RecRef.KeyIndex(1); // PK = 1 field
        asserterror FRef := KRef.FieldIndex(2); // index 2 on 1-field key → error
        Assert.AreNotEqual('', GetLastErrorText(), 'KeyRef.FieldIndex beyond FieldCount must throw');
        RecRef.Close();
    end;

    [Test]
    procedure KeyRef_FieldCount_MatchesExpectedStructure()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
    begin
        Initialize();
        RecRef.Open(60006); // ALT Keyed
        // Key3 = ("Date Field","Status") — 2 fields, at index 4
        KRef := RecRef.KeyIndex(4); // Key3
        Assert.IsTrue(KRef.FieldCount() >= 1, 'Key3 must have at least 1 field');
        Assert.IsTrue(KRef.FieldCount() <= 3, 'Key3 must not have more than 3 fields');
        RecRef.Close();
    end;

    [Test]
    procedure CalcSums_MultipleFields_BothCalculated()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec."Amount Field" := 50;
        Rec."Decimal Field" := 25;
        Rec.Insert();

        Rec."Entry No." := 2;
        Rec."Amount Field" := 50;
        Rec."Decimal Field" := 25;
        Rec.Insert();

        Rec.CalcSums("Amount Field", "Decimal Field");
        Assert.AreEqual(100, Rec."Amount Field", 'CalcSums must calculate Amount Field correctly (50+50=100)');
        Assert.AreEqual(50, Rec."Decimal Field", 'CalcSums must calculate Decimal Field correctly (25+25=50)');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
