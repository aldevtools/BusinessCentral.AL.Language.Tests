// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoincrement-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 70278, test codeunit 70279
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// changes. The error text is observed with the key shown in it written relative to the first AutoIncrement value this test inserted (the absolute number depends on how
// many rows earlier tests inserted). Also the offsets between consecutive inserts, after a rename attempt and after DeleteAll.
// BC versions: 29 (27 and 28 by CI)

table 70278 "LT P147 AutoInc Composite"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; Code; Code[10]) { DataClassification = SystemMetadata; }
        field(3; Payload; Text[30]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Entry No.", Code) { Clustered = true; }
    }
}

codeunit 70279 "LT P147 AutoInc Relative"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Relative(Value: Text; First: Integer): Text
    var
        i: Integer;
    begin
        // writes every occurrence of First + i (i = 100 down to 0) as <First+i>; longest numbers first so that no prefix is hit
        for i := 100 downto 0 do
            Value := Value.Replace('''' + Format(First + i) + '''', '''<First+' + Format(i) + '>''');
        exit(Value);
    end;

    [Test]
    procedure P147_AutoIncrement_Rename_RelativeText()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P147 AutoInc Composite";
        First: Integer;
    begin
        Rec.DeleteAll();
        Rec.Code := 'A';
        Rec.Insert(true);
        First := Rec."Entry No.";
        Observer.Observe('first value is positive', Format(First > 0));
        Rec.Get(First, 'A');
        Commit();

        asserterror Rec.Rename(First + 50, 'A');
        Observer.Observe('text relative', Relative(GetLastErrorText(), First));
        Observer.Observe('code', GetLastErrorCode());
        Observer.Expect('first value is positive', 'Yes');
        Observer.Expect('text relative', 'You cannot change the value of an AutoIncrement field.\\Field: Entry No.\Table: LT P147 AutoInc Composite\\Identification fields and values:\Entry No.=''<First+50>'',Code=''A''');
        Observer.Expect('code', 'DB:ModifyOnIdentityField');
        Observer.Verify();
    end;

    [Test]
    procedure P147_AutoIncrement_Rename_ErrorAfterObserve()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P147 AutoInc Composite";
        First: Integer;
        Cr: Text[1];
        Expected: Text;
    begin
        Rec.DeleteAll();
        Cr[1] := 13;
        Rec.Code := 'A';
        Rec.Insert(true);
        First := Rec."Entry No.";
        Commit();

        asserterror Rec.Rename(First + 50, 'A');
        Expected := 'You cannot change the value of an AutoIncrement field.' + Cr + '\' + Cr + '\' +
            'Field: Entry No.' + Cr + '\' +
            'Table: LT P147 AutoInc Composite' + Cr + '\' + Cr + '\' +
            'Identification fields and values:' + Cr + '\' +
            'Entry No.=''' + Format(First + 50) + ''',Code=''A''';
        Observer.Observe('text equals the shape built from First + 50', Format(GetLastErrorText() = Expected));
        Observer.Observe('code', GetLastErrorCode());
        Observer.Expect('text equals the shape built from First + 50', 'No');
        Observer.Expect('code', 'DB:ModifyOnIdentityField');
        Observer.Verify();
    end;
}
