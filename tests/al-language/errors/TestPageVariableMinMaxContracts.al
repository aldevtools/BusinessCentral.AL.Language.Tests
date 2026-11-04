// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minvalue-property
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 69020, page 69021, codeunit 69022
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins SetValue through a TestPage on a control bound to a PAGE VARIABLE with its own MinValue / MaxValue (and on a table field with
// MinValue / MaxValue, and on a Text variable that is too long). The bounds are enforced by the page and the error is a
// TestValidation error:
//   Validation error for Field: <control>,  Message = '<text>'    (two spaces before Message)
//  - Integer above MaxValue: "The value must be less than or equal to 10. Value: 11."; below MinValue: "The value must be
//    greater than or equal to 1. Value: 0."; the control keeps its old value; the bounds themselves are accepted;
//  - Decimal: the same texts with the decimal bound as written (2.5, 0.5) and the value with two decimals (Value: 2.60, 0.40);
//  - a Decimal with more than two decimals is shown with two, rounded half up and without a thousands separator (3.14159 reads 3.14,
//    2.505 reads 2.51, -1234567.891 reads -1234567.89);
//  - a table field with MinValue / MaxValue gives the same text followed by " (Select Refresh to discard errors)";
//  - a Text[5] variable given 7 characters: "The length of the string is 7, but it must be less than or equal to 5
//    characters. Value: toolong".
// All have the code TestValidation.
// BC versions: 27.5

table 69020 "Probe MinMax Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer)
        {
            MinValue = 1;
            MaxValue = 10;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 69021 "Probe MinMax Page"
{
    PageType = Card;
    SourceTable = "Probe MinMax Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Qty; Rec.Qty) { ApplicationArea = All; }
            field(IntVar; IntVar)
            {
                ApplicationArea = All;
                MinValue = 1;
                MaxValue = 10;
            }
            field(DecVar; DecVar)
            {
                ApplicationArea = All;
                MinValue = 0.5;
                MaxValue = 2.5;
            }
            field(TxtVar; TxtVar) { ApplicationArea = All; }
        }
    }

    var
        IntVar: Integer;
        DecVar: Decimal;
        TxtVar: Text[5];
}

codeunit 69022 "Probe Page Variable MinMax"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure OpenPage(var MmPage: TestPage "Probe MinMax Page")
    var
        MmRec: Record "Probe MinMax Table";
    begin
        MmRec.DeleteAll();
        MmRec.Id := 1;
        MmRec.Insert();
        Commit();
        MmPage.OpenEdit();
    end;

    [Test]
    procedure IntegerVariable_OutsideTheBounds_RaisesATestValidationError()
    var
        MmPage: TestPage "Probe MinMax Page";
    begin
        OpenPage(MmPage);
        MmPage.IntVar.SetValue(5);

        asserterror MmPage.IntVar.SetValue(11);
        Assert.AreEqual('Validation error for Field: IntVar,  Message = ''The value must be less than or equal to 10. Value: 11.''', GetLastErrorText(), 'above');
        Assert.AreEqual('TestValidation', GetLastErrorCode(), 'code');
        Assert.AreEqual('5', MmPage.IntVar.Value(), 'the old value stays');

        asserterror MmPage.IntVar.SetValue(0);
        Assert.AreEqual('Validation error for Field: IntVar,  Message = ''The value must be greater than or equal to 1. Value: 0.''', GetLastErrorText(), 'below');

        MmPage.IntVar.SetValue(1);
        MmPage.IntVar.SetValue(10);
        Assert.AreEqual('10', MmPage.IntVar.Value(), 'the bounds are accepted');
        MmPage.Close();
    end;

    [Test]
    procedure DecimalVariable_OutsideTheBounds_RaisesATestValidationError()
    var
        MmPage: TestPage "Probe MinMax Page";
    begin
        OpenPage(MmPage);
        MmPage.DecVar.SetValue(1.5);

        asserterror MmPage.DecVar.SetValue(2.6);
        Assert.AreEqual('Validation error for Field: DecVar,  Message = ''The value must be less than or equal to 2.5. Value: 2.60.''', GetLastErrorText(), 'above');
        asserterror MmPage.DecVar.SetValue(0.4);
        Assert.AreEqual('Validation error for Field: DecVar,  Message = ''The value must be greater than or equal to 0.5. Value: 0.40.''', GetLastErrorText(), 'below');
        MmPage.Close();
    end;

    [Test]
    procedure DecimalVariable_WithMoreThanTwoDecimals_ShowsTheValueRoundedToTwoDecimals()
    var
        MmPage: TestPage "Probe MinMax Page";
    begin
        OpenPage(MmPage);

        asserterror MmPage.DecVar.SetValue(3.14159);
        Assert.AreEqual('Validation error for Field: DecVar,  Message = ''The value must be less than or equal to 2.5. Value: 3.14.''', GetLastErrorText(), '3.14159');
        asserterror MmPage.DecVar.SetValue(0.123456);
        Assert.AreEqual('Validation error for Field: DecVar,  Message = ''The value must be greater than or equal to 0.5. Value: 0.12.''', GetLastErrorText(), '0.123456');
        asserterror MmPage.DecVar.SetValue(2.505);
        Assert.AreEqual('Validation error for Field: DecVar,  Message = ''The value must be less than or equal to 2.5. Value: 2.51.''', GetLastErrorText(), '2.505 rounds half up');
        asserterror MmPage.DecVar.SetValue(-1234567.891);
        Assert.AreEqual('Validation error for Field: DecVar,  Message = ''The value must be greater than or equal to 0.5. Value: -1234567.89.''', GetLastErrorText(), 'no thousands separator');
        MmPage.Close();
    end;

    [Test]
    procedure TableFieldBounds_AndTextLength_HaveTheirOwnTexts()
    var
        MmPage: TestPage "Probe MinMax Page";
    begin
        OpenPage(MmPage);

        asserterror MmPage.Qty.SetValue(11);
        Assert.AreEqual('Validation error for Field: Qty,  Message = ''The value must be less than or equal to 10. Value: 11. (Select Refresh to discard errors)''', GetLastErrorText(), 'table field');
        asserterror MmPage.TxtVar.SetValue('toolong');
        Assert.AreEqual('Validation error for Field: TxtVar,  Message = ''The length of the string is 7, but it must be less than or equal to 5 characters. Value: toolong''', GetLastErrorText(), 'text length');
        Assert.AreEqual('TestValidation', GetLastErrorCode(), 'code');
        MmPage.Close();
    end;
}
