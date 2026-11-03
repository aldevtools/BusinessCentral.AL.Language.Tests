// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained enums 74856 and 74857, table 74858, codeunit 74859
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetLastErrorText(true) (ExcludeCustomerContent) against GetLastErrorText(false) and GetLastErrorCode for TestField(F) and TestField(F, Value) on Option and Enum fields, with the zero member (blank member and named member) and with another member; a field with a non-zero member passes TestField(F) without error. The message texts without the flag are pinned in record/TestTestFieldOptionEnumContracts.al.
// BC versions: 29 (27 and 28 by CI)

enum 74856 "LT TFE Blank"
{
    Extensible = true;

    value(0; " ") { }
    value(1; One) { Caption = 'One cap'; }
}

enum 74857 "LT TFE Named"
{
    Extensible = true;

    value(0; Zero) { Caption = 'Zero cap'; }
    value(1; One) { Caption = 'One cap'; }
}

table 74858 "LT TFE Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; OptBlank; Option)
        {
            OptionMembers = " ",A,B;
            OptionCaption = ' ,A cap,B cap';
        }
        field(3; OptNamed; Option)
        {
            OptionMembers = Zero,One;
        }
        field(4; EnumBlank; Enum "LT TFE Blank") { }
        field(5; EnumNamed; Enum "LT TFE Named") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74859 "LT TFE TestField Flag"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Forms(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '_true', GetLastErrorText(true));
        Observer.Observe(Name + '_false', GetLastErrorText(false));
        Observer.Observe(Name + '_code', GetLastErrorCode());
        ClearLastError();
    end;

    [Test]
    procedure TestFieldOption_ZeroAndMismatch_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TFE Row";
    begin
        Row.Id := 1;
        asserterror Row.TestField(OptBlank);
        Forms('optblank_zero', Observer);
        asserterror Row.TestField(OptNamed);
        Forms('optnamed_zero', Observer);
        asserterror Row.TestField(OptBlank, Row.OptBlank::A);
        Forms('optblank_expect_a', Observer);
        Row.OptBlank := Row.OptBlank::A;
        asserterror Row.TestField(OptBlank, Row.OptBlank::B);
        Forms('opta_expect_b', Observer);
        Row.OptNamed := Row.OptNamed::One;
        asserterror Row.TestField(OptNamed, Row.OptNamed::Zero);
        Forms('optone_expect_zero', Observer);
        Row.TestField(OptBlank);
        Row.TestField(OptNamed);
        Observer.Observe('nonzero_passes', 'no error');
        Observer.Expect('optblank_zero_true', 'OptBlank must not be   in LT TFE Row: <redacted>');
        Observer.Expect('optblank_zero_false', 'OptBlank must not be   in LT TFE Row: Id=1');
        Observer.Expect('optblank_zero_code', 'TestField');
        Observer.Expect('optnamed_zero_true', 'OptNamed must not be Zero in LT TFE Row: <redacted>');
        Observer.Expect('optnamed_zero_false', 'OptNamed must not be Zero in LT TFE Row: Id=1');
        Observer.Expect('optnamed_zero_code', 'TestField');
        Observer.Expect('optblank_expect_a_true', 'OptBlank must be equal to ''<redacted>''  in LT TFE Row: <redacted>. Current value is ''<redacted>''.');
        Observer.Expect('optblank_expect_a_false', 'OptBlank must be equal to ''A cap''  in LT TFE Row: Id=1. Current value is '' ''.');
        Observer.Expect('optblank_expect_a_code', 'TestField');
        Observer.Expect('opta_expect_b_true', 'OptBlank must be equal to ''<redacted>''  in LT TFE Row: <redacted>. Current value is ''<redacted>''.');
        Observer.Expect('opta_expect_b_false', 'OptBlank must be equal to ''B cap''  in LT TFE Row: Id=1. Current value is ''A cap''.');
        Observer.Expect('opta_expect_b_code', 'TestField');
        Observer.Expect('optone_expect_zero_true', 'OptNamed must be equal to ''<redacted>''  in LT TFE Row: <redacted>. Current value is ''<redacted>''.');
        Observer.Expect('optone_expect_zero_false', 'OptNamed must be equal to ''Zero''  in LT TFE Row: Id=1. Current value is ''One''.');
        Observer.Expect('optone_expect_zero_code', 'TestField');
        Observer.Expect('nonzero_passes', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure TestFieldEnum_ZeroAndMismatch_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TFE Row";
    begin
        Row.Id := 2;
        asserterror Row.TestField(EnumBlank);
        Forms('enumblank_zero', Observer);
        asserterror Row.TestField(EnumNamed);
        Forms('enumnamed_zero', Observer);
        asserterror Row.TestField(EnumBlank, Enum::"LT TFE Blank"::One);
        Forms('enumblank_expect_one', Observer);
        Row.EnumBlank := Enum::"LT TFE Blank"::One;
        asserterror Row.TestField(EnumBlank, Enum::"LT TFE Blank"::" ");
        Forms('enumone_expect_blank', Observer);
        Row.EnumNamed := Enum::"LT TFE Named"::One;
        asserterror Row.TestField(EnumNamed, Enum::"LT TFE Named"::Zero);
        Forms('enumnamedone_expect_zero', Observer);
        Row.TestField(EnumBlank);
        Row.TestField(EnumNamed);
        Observer.Observe('nonzero_passes', 'no error');
        Observer.Expect('enumblank_zero_true', 'EnumBlank must not be   in LT TFE Row: <redacted>');
        Observer.Expect('enumblank_zero_false', 'EnumBlank must not be   in LT TFE Row: Id=2');
        Observer.Expect('enumblank_zero_code', 'TestField');
        Observer.Expect('enumnamed_zero_true', 'EnumNamed must not be Zero cap in LT TFE Row: <redacted>');
        Observer.Expect('enumnamed_zero_false', 'EnumNamed must not be Zero cap in LT TFE Row: Id=2');
        Observer.Expect('enumnamed_zero_code', 'TestField');
        Observer.Expect('enumblank_expect_one_true', 'EnumBlank must be equal to ''<redacted>''  in LT TFE Row: <redacted>. Current value is ''<redacted>''.');
        Observer.Expect('enumblank_expect_one_false', 'EnumBlank must be equal to ''One cap''  in LT TFE Row: Id=2. Current value is '' ''.');
        Observer.Expect('enumblank_expect_one_code', 'TestField');
        Observer.Expect('enumone_expect_blank_true', 'EnumBlank must be equal to ''<redacted>''  in LT TFE Row: <redacted>. Current value is ''<redacted>''.');
        Observer.Expect('enumone_expect_blank_false', 'EnumBlank must be equal to '' ''  in LT TFE Row: Id=2. Current value is ''One cap''.');
        Observer.Expect('enumone_expect_blank_code', 'TestField');
        Observer.Expect('enumnamedone_expect_zero_true', 'EnumNamed must be equal to ''<redacted>''  in LT TFE Row: <redacted>. Current value is ''<redacted>''.');
        Observer.Expect('enumnamedone_expect_zero_false', 'EnumNamed must be equal to ''Zero cap''  in LT TFE Row: Id=2. Current value is ''One cap''.');
        Observer.Expect('enumnamedone_expect_zero_code', 'TestField');
        Observer.Expect('nonzero_passes', 'no error');
        Observer.Verify();
    end;
}
