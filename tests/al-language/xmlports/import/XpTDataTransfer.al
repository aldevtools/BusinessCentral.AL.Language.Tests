// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: Fixtures.al (own tables 73406-73409, helper 73430, DT runner 73450), XmlPortFixtures.al, QueryFixtures.al, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// DataTransfer: SetTables, AddFieldValue, AddConstantValue, AddSourceFilter, UpdateAuditFields, AddJoin, CopyRows and CopyFields with the error texts (each mode runs in LT XpT DT Runner and reports ok or the error).
// BC versions: 29 (27 and 28 by CI)

codeunit 73520 "LT XpT DataTransfer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CopyRows_ThreeFields()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(1));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_AllFields()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(2));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_EmptySource()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('run', Helper.RunDT(1));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_ConstantValues()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(3));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_SourceFilterGreaterEqual()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(4));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_SourceFilterTextOr()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(5));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_SourceFilterNoMatch()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(21));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_NoFieldsMapped()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(6));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_NoFieldsMappedEmptySource()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('run', Helper.RunDT(6));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_SameSourceAndDestinationTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(7));
        Observer.Observe('items', Helper.DumpItems());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('items', '1|Alpha|10|1.5|true|A|2024-01-15;2|Beta|20|2.5|false|A|2023-12-31;3|Gamma|30|3.5|true|B|;');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_Twice()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(8));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_UpdateAuditFieldsFalse()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(9));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_TextIntoShorterField()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(10));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_TextIntoInteger()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(11));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_ConstantOfWrongType()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(14));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_ConstantTwiceSameField()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(19));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_IntegerIntoTextField()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(20));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyRows_ExistingTargetRowConflict()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Helper.RunDT(1);
        Observer.Observe('run', Helper.RunDT(1));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFields_JoinOnId()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Helper.RunDT(2);
        Observer.Observe('run', Helper.RunDT(12));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFields_JoinEmptyDestination()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Observer.Observe('run', Helper.RunDT(12));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFields_WithoutJoin()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Helper.Seed();
        Helper.RunDT(2);
        Observer.Observe('run', Helper.RunDT(13));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure AddSourceFilter_UnknownField()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('run', Helper.RunDT(15));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:DataTransfer is only usable during upgrade and installation code.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure AddFieldValue_WithoutSetTables()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('run', Helper.RunDT(16));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:SetTables must first be called before calling other methods on DataTransfer.|DB:Ok');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetTables_UnknownTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT XpT Helper";
    begin
        Helper.Wipe();
        Observer.Observe('run', Helper.RunDT(18));
        Observer.Observe('targets', Helper.DumpTargets());
        Observer.Expect('run', 'error:You tried to invoke the Table object with the ID 99999999 from the object LT XpT Helper. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('targets', '');
        Observer.Verify();
    end;
}
