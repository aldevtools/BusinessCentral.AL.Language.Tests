// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformattype-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (table 74303, page 74304); System tables Currency and General Ledger Setup
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: AutoFormatType 1/2/4/5 with a currency code whose Amount Decimal Places or Unit-Amount Decimal Places is empty (one of the two, and both), under General Ledger Setup places that differ from the defaults; zero places; a blank code under other setup places
// Settles docs/probes-needed.md row "AutoFormatType of a decimal control (issue 17)": a currency with one place empty, other setup places combined with a currency code
// BC versions: 29 (27 and 28 by CI)

table 74303 "LT P166 AF Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { }
        field(3; "Currency Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 74304 "LT P166 AF Card"
{
    PageType = Card;
    SourceTable = "LT P166 AF Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Type1; Rec.Amount) { ApplicationArea = All; AutoFormatType = 1; AutoFormatExpression = Rec."Currency Code"; }
                field(Type2; Rec.Amount) { ApplicationArea = All; AutoFormatType = 2; AutoFormatExpression = Rec."Currency Code"; }
                field(Type4; Rec.Amount) { ApplicationArea = All; AutoFormatType = 4; AutoFormatExpression = Rec."Currency Code"; }
                field(Type5; Rec.Amount) { ApplicationArea = All; AutoFormatType = 5; AutoFormatExpression = Rec."Currency Code"; }
            }
        }
    }
}

codeunit 74305 "LT P166 AutoFormat"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        SavedAmountPlaces: Text;
        SavedUnitPlaces: Text;
        SavedShowCurrency: Enum "Show Currency";
        SavedExisted: Boolean;

    local procedure SetSetup(AmountPlaces: Text; UnitPlaces: Text)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        SavedExisted := GLSetup.Get();
        if not SavedExisted then begin
            GLSetup.Init();
            GLSetup.Insert();
        end;
        SavedAmountPlaces := GLSetup."Amount Decimal Places";
        SavedUnitPlaces := GLSetup."Unit-Amount Decimal Places";
        SavedShowCurrency := GLSetup."Show Currency";
        GLSetup."Amount Decimal Places" := CopyStr(AmountPlaces, 1, MaxStrLen(GLSetup."Amount Decimal Places"));
        GLSetup."Unit-Amount Decimal Places" := CopyStr(UnitPlaces, 1, MaxStrLen(GLSetup."Unit-Amount Decimal Places"));
        GLSetup."Show Currency" := GLSetup."Show Currency"::Never;
        GLSetup.Modify();
    end;

    local procedure RestoreSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not GLSetup.Get() then
            exit;
        GLSetup."Amount Decimal Places" := CopyStr(SavedAmountPlaces, 1, MaxStrLen(GLSetup."Amount Decimal Places"));
        GLSetup."Unit-Amount Decimal Places" := CopyStr(SavedUnitPlaces, 1, MaxStrLen(GLSetup."Unit-Amount Decimal Places"));
        GLSetup."Show Currency" := SavedShowCurrency;
        GLSetup.Modify();
    end;

    local procedure SeedCurrency(CurrencyCode: Code[10]; AmountPlaces: Text; UnitPlaces: Text)
    var
        Currency: Record Currency;
    begin
        if Currency.Get(CurrencyCode) then
            Currency.Delete();
        Currency.Init();
        Currency.Code := CurrencyCode;
        Currency."Amount Decimal Places" := CopyStr(AmountPlaces, 1, MaxStrLen(Currency."Amount Decimal Places"));
        Currency."Unit-Amount Decimal Places" := CopyStr(UnitPlaces, 1, MaxStrLen(Currency."Unit-Amount Decimal Places"));
        Currency.Insert();
    end;

    local procedure DropCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        if Currency.Get(CurrencyCode) then
            Currency.Delete();
    end;

    local procedure ReadAll(var Observer: Codeunit "Probe Observer"; Tag: Text; CurrencyCode: Code[10]; Amount: Decimal)
    var
        Row: Record "LT P166 AF Row";
        Card: TestPage "LT P166 AF Card";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'AF-1';
        Row.Amount := Amount;
        Row."Currency Code" := CurrencyCode;
        Row.Insert();
        Card.OpenView();
        Observer.Observe(Tag + '_t1', Card.Type1.Value);
        Observer.Observe(Tag + '_t2', Card.Type2.Value);
        Observer.Observe(Tag + '_t4', Card.Type4.Value);
        Observer.Observe(Tag + '_t5', Card.Type5.Value);
        Card.Close();
        Row.DeleteAll();
    end;

    local procedure ReadBoth(var Observer: Codeunit "Probe Observer"; Tag: Text; CurrencyCode: Code[10])
    begin
        ReadAll(Observer, Tag + '_unit5dec', CurrencyCode, 110.74398);
        ReadAll(Observer, Tag + '_1234_5', CurrencyCode, 1234.5);
    end;

    [Test]
    procedure Currency_AmountPlacesOnly_DefaultSetup()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup('2:2', '2:5');
        SeedCurrency('P166A', '3:3', '');
        ReadBoth(Observer, 'amt33_unitEmpty', 'P166A');
        DropCurrency('P166A');
        RestoreSetup();
        Observer.Expect('amt33_unitEmpty_unit5dec_t1', '110.744');
        Observer.Expect('amt33_unitEmpty_unit5dec_t2', '110.74');
        Observer.Expect('amt33_unitEmpty_unit5dec_t4', '110.744');
        Observer.Expect('amt33_unitEmpty_unit5dec_t5', '110.74');
        Observer.Expect('amt33_unitEmpty_1234_5_t1', '1,234.500');
        Observer.Expect('amt33_unitEmpty_1234_5_t2', '1,234.50');
        Observer.Expect('amt33_unitEmpty_1234_5_t4', '1,234.500');
        Observer.Expect('amt33_unitEmpty_1234_5_t5', '1,234.50');
        Observer.Verify();
    end;

    [Test]
    procedure Currency_UnitPlacesOnly_DefaultSetup()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup('2:2', '2:5');
        SeedCurrency('P166B', '', '4:4');
        ReadBoth(Observer, 'amtEmpty_unit44', 'P166B');
        DropCurrency('P166B');
        RestoreSetup();
        Observer.Expect('amtEmpty_unit44_unit5dec_t1', '110.74');
        Observer.Expect('amtEmpty_unit44_unit5dec_t2', '110.7440');
        Observer.Expect('amtEmpty_unit44_unit5dec_t4', '110.74');
        Observer.Expect('amtEmpty_unit44_unit5dec_t5', '110.7440');
        Observer.Expect('amtEmpty_unit44_1234_5_t1', '1,234.50');
        Observer.Expect('amtEmpty_unit44_1234_5_t2', '1,234.5000');
        Observer.Expect('amtEmpty_unit44_1234_5_t4', '1,234.50');
        Observer.Expect('amtEmpty_unit44_1234_5_t5', '1,234.5000');
        Observer.Verify();
    end;

    [Test]
    procedure Currency_AmountPlacesOnly_OtherSetup()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup('5:5', '6:6');
        SeedCurrency('P166A', '3:3', '');
        ReadBoth(Observer, 'amt33_unitEmpty_gl55_66', 'P166A');
        DropCurrency('P166A');
        RestoreSetup();
        Observer.Expect('amt33_unitEmpty_gl55_66_unit5dec_t1', '110.744');
        Observer.Expect('amt33_unitEmpty_gl55_66_unit5dec_t2', '110.74');
        Observer.Expect('amt33_unitEmpty_gl55_66_unit5dec_t4', '110.744');
        Observer.Expect('amt33_unitEmpty_gl55_66_unit5dec_t5', '110.74');
        Observer.Expect('amt33_unitEmpty_gl55_66_1234_5_t1', '1,234.500');
        Observer.Expect('amt33_unitEmpty_gl55_66_1234_5_t2', '1,234.50');
        Observer.Expect('amt33_unitEmpty_gl55_66_1234_5_t4', '1,234.500');
        Observer.Expect('amt33_unitEmpty_gl55_66_1234_5_t5', '1,234.50');
        Observer.Verify();
    end;

    [Test]
    procedure Currency_UnitPlacesOnly_OtherSetup()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup('5:5', '6:6');
        SeedCurrency('P166B', '', '4:4');
        ReadBoth(Observer, 'amtEmpty_unit44_gl55_66', 'P166B');
        DropCurrency('P166B');
        RestoreSetup();
        Observer.Expect('amtEmpty_unit44_gl55_66_unit5dec_t1', '110.74');
        Observer.Expect('amtEmpty_unit44_gl55_66_unit5dec_t2', '110.7440');
        Observer.Expect('amtEmpty_unit44_gl55_66_unit5dec_t4', '110.74');
        Observer.Expect('amtEmpty_unit44_gl55_66_unit5dec_t5', '110.7440');
        Observer.Expect('amtEmpty_unit44_gl55_66_1234_5_t1', '1,234.50');
        Observer.Expect('amtEmpty_unit44_gl55_66_1234_5_t2', '1,234.5000');
        Observer.Expect('amtEmpty_unit44_gl55_66_1234_5_t4', '1,234.50');
        Observer.Expect('amtEmpty_unit44_gl55_66_1234_5_t5', '1,234.5000');
        Observer.Verify();
    end;

    [Test]
    procedure Currency_BothPlacesEmpty_OtherSetup()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup('5:5', '6:6');
        SeedCurrency('P166C', '', '');
        ReadBoth(Observer, 'bothEmpty_gl55_66', 'P166C');
        DropCurrency('P166C');
        RestoreSetup();
        Observer.Expect('bothEmpty_gl55_66_unit5dec_t1', '110.74');
        Observer.Expect('bothEmpty_gl55_66_unit5dec_t2', '110.74');
        Observer.Expect('bothEmpty_gl55_66_unit5dec_t4', '110.74');
        Observer.Expect('bothEmpty_gl55_66_unit5dec_t5', '110.74');
        Observer.Expect('bothEmpty_gl55_66_1234_5_t1', '1,234.50');
        Observer.Expect('bothEmpty_gl55_66_1234_5_t2', '1,234.50');
        Observer.Expect('bothEmpty_gl55_66_1234_5_t4', '1,234.50');
        Observer.Expect('bothEmpty_gl55_66_1234_5_t5', '1,234.50');
        Observer.Verify();
    end;

    [Test]
    procedure Currency_ZeroAndMixedPlaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup('2:2', '2:5');
        SeedCurrency('P166D', '0:0', '0:0');
        ReadBoth(Observer, 'zero', 'P166D');
        SeedCurrency('P166E', '0:2', '2:0');
        ReadBoth(Observer, 'mixed', 'P166E');
        DropCurrency('P166D');
        DropCurrency('P166E');
        RestoreSetup();
        Observer.Expect('zero_unit5dec_t1', '111');
        Observer.Expect('zero_unit5dec_t2', '111');
        Observer.Expect('zero_unit5dec_t4', '111');
        Observer.Expect('zero_unit5dec_t5', '111');
        Observer.Expect('zero_1234_5_t1', '1,235');
        Observer.Expect('zero_1234_5_t2', '1,235');
        Observer.Expect('zero_1234_5_t4', '1,235');
        Observer.Expect('zero_1234_5_t5', '1,235');
        Observer.Expect('mixed_unit5dec_t1', '110.74');
        Observer.Expect('mixed_unit5dec_t2', '111');
        Observer.Expect('mixed_unit5dec_t4', '110.74');
        Observer.Expect('mixed_unit5dec_t5', '111');
        Observer.Expect('mixed_1234_5_t1', '1,234.5');
        Observer.Expect('mixed_1234_5_t2', '1,235');
        Observer.Expect('mixed_1234_5_t4', '1,234.5');
        Observer.Expect('mixed_1234_5_t5', '1,235');
        Observer.Verify();
    end;
}
