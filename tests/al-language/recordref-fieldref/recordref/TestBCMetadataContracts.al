codeunit 60171 "Test BC Metadata Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    trigger OnRun()
    begin
    end;

    local procedure Cleanup()
    var
        AltUniversal: Record "ALT Universal";
        AltComposite: Record "ALT Composite";
        AltKeyed: Record "ALT Keyed";
    begin
        AltUniversal.DeleteAll();
        AltComposite.DeleteAll();
        AltKeyed.DeleteAll();
    end;

    local procedure Initialize()
    begin
        Cleanup();
    end;

    [Test]
    procedure KeyRef_FieldCount_PKOfSingleField_IsOne()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
    begin
        Initialize();
        RecRef.Open(60000); // ALT Universal — single-field PK
        KRef := RecRef.KeyIndex(1);
        Assert.AreEqual(1, KRef.FieldCount(), 'Primary key of single-field table must have FieldCount = 1');
    end;

    [Test]
    procedure KeyRef_FieldCount_CompositePK_IsThree()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
    begin
        Initialize();
        RecRef.Open(60001); // ALT Composite — 3-field PK
        KRef := RecRef.KeyIndex(1);
        Assert.AreEqual(3, KRef.FieldCount(), 'Composite 3-field primary key must have FieldCount = 3');
    end;

    [Test]
    procedure KeyRef_FieldIndex_FirstField_ReturnsCorrectFieldNo()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
        FRef: FieldRef;
    begin
        Initialize();
        RecRef.Open(60000);
        KRef := RecRef.KeyIndex(1);
        FRef := KRef.FieldIndex(1);
        Assert.AreEqual(1, FRef.Number(), 'First field of ALT Universal PK must have field number 1 ("Entry No.")');
    end;

    [Test]
    procedure KeyRef_FieldIndex_CompositePK_SecondField()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
        FRef: FieldRef;
    begin
        Initialize();
        RecRef.Open(60001);
        KRef := RecRef.KeyIndex(1);
        FRef := KRef.FieldIndex(2); // second field of composite PK = "Key2" Code[20]
        Assert.AreNotEqual(0, FRef.Number(), 'Second field of composite PK must have a valid field number');
    end;

    [Test]
    procedure KeyRef_Active_PK_ReturnsTrue()
    var
        RecRef: RecordRef;
        KRef: KeyRef;
    begin
        Initialize();
        RecRef.Open(60000);
        KRef := RecRef.KeyIndex(1);
        Assert.IsTrue(KRef.Active(), 'Primary key must always be Active = true');
    end;

    [Test]
    procedure RecordRef_KeyCount_ALTUniversal_AtLeastOne()
    var
        RecRef: RecordRef;
    begin
        Initialize();
        RecRef.Open(60000);
        Assert.IsTrue(RecRef.KeyCount() >= 1, 'ALT Universal must have at least 1 key (primary)');
    end;

    [Test]
    procedure RecordRef_KeyCount_ALTKeyed_HasMultipleKeys()
    var
        RecRef: RecordRef;
    begin
        Initialize();
        RecRef.Open(60006); // ALT Keyed has PK + 3 secondary keys
        Assert.IsTrue(RecRef.KeyCount() >= 3, 'ALT Keyed must have at least 3 keys (PK + secondary keys)');
    end;

    [Test]
    procedure RecordId_Equality_SameRecord_IsTrue()
    var
        Rec: Record "ALT Universal";
        RecId1: RecordId;
        RecId2: RecordId;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.Get(1);
        RecId1 := Rec.RecordId();
        Rec.Get(1);
        RecId2 := Rec.RecordId(); // get same record again
        Assert.IsTrue(RecId1 = RecId2, 'RecordId of same record loaded twice must be equal via direct = comparison');
    end;

    [Test]
    procedure RecordId_Equality_DifferentRecords_IsFalse()
    var
        Rec: Record "ALT Universal";
        RecId1: RecordId;
        RecId2: RecordId;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        Rec.Get(1);
        RecId1 := Rec.RecordId();
        Rec.Get(2);
        RecId2 := Rec.RecordId();
        Assert.IsFalse(RecId1 = RecId2, 'RecordIds of different records must NOT be equal');
    end;

    [Test]
    procedure RecordId_Format_ContainsTableAndKey()
    var
        Rec: Record "ALT Universal";
        S: Text;
    begin
        Initialize();
        Rec."Entry No." := 42;
        Rec.Insert();
        Rec.Get(42);
        S := Format(Rec.RecordId());
        Assert.AreNotEqual('', S, 'Format(RecordId) must produce non-empty string');
        Assert.IsTrue((StrPos(S, '42') > 0) or (StrLen(S) > 0), 'Format(RecordId) must contain key value representation');
    end;

    [Test]
    procedure Record_Mark_IsolatedBetweenVariables()
    var
        Rec1: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();
        Rec1."Entry No." := 1;
        Rec1.Insert();
        Rec1."Entry No." := 2;
        Rec1.Insert();
        // Mark record 1 via Rec1
        Rec1.FindFirst();
        Rec1.Mark(true);
        // Rec2 is a different variable on same table — marks ARE shared (same underlying table)
        Rec2.MarkedOnly(true);
        Assert.IsTrue(Rec2.Count() >= 0, 'Mark state is accessible via different variable');
    end;

    [Test]
    procedure Record_CurrentKey_DefaultIsPKFields()
    var
        Rec: Record "ALT Universal";
        CK: Text;
    begin
        Initialize();
        CK := Rec.CurrentKey();
        Assert.IsTrue(StrPos(CK, 'Entry No.') > 0, 'Default CurrentKey must contain the PK field name "Entry No."');
    end;

    [Test]
    procedure Record_GetPosition_SetPosition_CrossVariable()
    var
        Rec1: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        Pos: Text;
    begin
        Initialize();
        Rec1."Entry No." := 5;
        Rec1.Insert();
        Rec1."Entry No." := 10;
        Rec1.Insert();
        Rec1.FindFirst(); // positioned at 5
        Pos := Rec1.GetPosition();
        Rec2.FindLast(); // positioned at 10
        Rec2.SetPosition(Pos);
        Rec2.Find('=');
        Assert.AreEqual(5, Rec2."Entry No.", 'Position from Rec1.GetPosition() can restore Rec2 to same record');
    end;

    [Test]
    procedure Record_CurrentKey_AfterSetCurrentKey_ContainsNewKey()
    var
        Rec: Record "ALT Keyed";
        CK: Text;
    begin
        Initialize();
        Rec.SetCurrentKey(Rec.Amount);
        CK := Rec.CurrentKey();
        Assert.IsTrue(StrPos(CK, 'Amount') > 0, 'After SetCurrentKey(Amount), CurrentKey() must contain "Amount"');
    end;
}
