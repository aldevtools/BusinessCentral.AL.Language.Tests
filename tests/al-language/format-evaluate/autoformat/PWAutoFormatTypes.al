// Probe writer-c, round 3: AutoFormatType 1, 2, 4, 5 on page fields (docs/probes-needed.md "AutoFormatType of a decimal control (issue 17)").
// A TestPage field Value text of one Decimal under General Ledger Setup decimal places, a currency code and Show Currency.
// Observe-only. Reuses the corpus table "ALT AutoFormat Row" (60603).
// Fixtures: page 69775, codeunit 69776.

page 69775 "PW AutoFormat Card"
{
    PageType = Card;
    SourceTable = "ALT AutoFormat Row";
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
                field(Type1Blank; Rec.Amount) { ApplicationArea = All; AutoFormatType = 1; AutoFormatExpression = ''; }
                field(Type2Blank; Rec.Amount) { ApplicationArea = All; AutoFormatType = 2; AutoFormatExpression = ''; }
                field(Type4Blank; Rec.Amount) { ApplicationArea = All; AutoFormatType = 4; AutoFormatExpression = ''; }
                field(Type5Blank; Rec.Amount) { ApplicationArea = All; AutoFormatType = 5; AutoFormatExpression = ''; }
            }
        }
    }
}

codeunit 69776 "PW AutoFormat Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure SetSetup(AmountPlaces: Text; UnitPlaces: Text; ShowCurrency: Enum "Show Currency")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not GLSetup.Get() then begin
            GLSetup.Init();
            GLSetup.Insert();
        end;
        GLSetup."Amount Decimal Places" := CopyStr(AmountPlaces, 1, MaxStrLen(GLSetup."Amount Decimal Places"));
        GLSetup."Unit-Amount Decimal Places" := CopyStr(UnitPlaces, 1, MaxStrLen(GLSetup."Unit-Amount Decimal Places"));
        GLSetup."Show Currency" := ShowCurrency;
        GLSetup.Modify();
    end;

    // Back to the values of the container (Setup_AsInTheContainer_NoCurrency). The BC 27.5 test runner commits what a test
    // leaves, so without this the '2:5' of the last test stayed in the database for every later codeunit (publisher 8,
    // subset run 39257271546: the decimal format tests of later codeunits read '2:5').
    local procedure RestoreSetup()
    begin
        SetSetup('2:2', '2:5', "Show Currency"::Never);
    end;

    local procedure SeedCurrency(Code: Code[10]; AmountPlaces: Text; UnitPlaces: Text; Symbol: Text)
    var
        Currency: Record Currency;
    begin
        if Currency.Get(Code) then
            Currency.Delete();
        Currency.Init();
        Currency.Code := Code;
        Currency."Amount Decimal Places" := CopyStr(AmountPlaces, 1, MaxStrLen(Currency."Amount Decimal Places"));
        Currency."Unit-Amount Decimal Places" := CopyStr(UnitPlaces, 1, MaxStrLen(Currency."Unit-Amount Decimal Places"));
        Currency.Symbol := CopyStr(Symbol, 1, MaxStrLen(Currency.Symbol));
        Currency.Insert();
    end;

    local procedure ReadAll(Tag: Text; CurrencyCode: Code[10]; Amount: Decimal)
    var
        Row: Record "ALT AutoFormat Row";
        Card: TestPage "PW AutoFormat Card";
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
        Observer.Observe(Tag + '_t1blank', Card.Type1Blank.Value);
        Observer.Observe(Tag + '_t2blank', Card.Type2Blank.Value);
        Observer.Observe(Tag + '_t4blank', Card.Type4Blank.Value);
        Observer.Observe(Tag + '_t5blank', Card.Type5Blank.Value);
        Card.Close();
    end;

    local procedure ReadBoth(Tag: Text; CurrencyCode: Code[10])
    begin
        ReadAll(Tag + '_unit5dec', CurrencyCode, 110.74398);
        ReadAll(Tag + '_1234_5', CurrencyCode, 1234.5);
    end;

    [Test]
    procedure Setup_AsInTheContainer_NoCurrency()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if GLSetup.Get() then begin
            Observer.Observe('gl_amount_places', GLSetup."Amount Decimal Places");
            Observer.Observe('gl_unit_places', GLSetup."Unit-Amount Decimal Places");
            Observer.Observe('gl_show_currency', Format(GLSetup."Show Currency"));
        end else
            Observer.Observe('gl_setup_row', 'none');
        ReadBoth('asis', '');
        Observer.Expect('gl_amount_places', '2:2');
        Observer.Expect('gl_unit_places', '2:5');
        Observer.Expect('gl_show_currency', 'Never');
        Observer.Expect('asis_unit5dec_t1', '110.74');
        Observer.Expect('asis_unit5dec_t2', '110.74398');
        Observer.Expect('asis_unit5dec_t4', '110.74');
        Observer.Expect('asis_unit5dec_t5', '110.74398');
        Observer.Expect('asis_unit5dec_t1blank', '110.74');
        Observer.Expect('asis_unit5dec_t2blank', '110.74398');
        Observer.Expect('asis_unit5dec_t4blank', '110.74');
        Observer.Expect('asis_unit5dec_t5blank', '110.74398');
        Observer.Expect('asis_1234_5_t1', '1,234.50');
        Observer.Expect('asis_1234_5_t2', '1,234.50');
        Observer.Expect('asis_1234_5_t4', '1,234.50');
        Observer.Expect('asis_1234_5_t5', '1,234.50');
        Observer.Expect('asis_1234_5_t1blank', '1,234.50');
        Observer.Expect('asis_1234_5_t2blank', '1,234.50');
        Observer.Expect('asis_1234_5_t4blank', '1,234.50');
        Observer.Expect('asis_1234_5_t5blank', '1,234.50');
        Observer.Verify();
    end;

    [Test]
    procedure Setup_AmountPlaces2to5_NoCurrency()
    begin
        SetSetup('2:5', '2:5', "Show Currency"::Never);
        ReadBoth('amt25_unit25', '');
        Observer.Expect('amt25_unit25_unit5dec_t1', '110.74');
        Observer.Expect('amt25_unit25_unit5dec_t2', '110.74398');
        Observer.Expect('amt25_unit25_unit5dec_t4', '110.74');
        Observer.Expect('amt25_unit25_unit5dec_t5', '110.74398');
        Observer.Expect('amt25_unit25_unit5dec_t1blank', '110.74');
        Observer.Expect('amt25_unit25_unit5dec_t2blank', '110.74398');
        Observer.Expect('amt25_unit25_unit5dec_t4blank', '110.74');
        Observer.Expect('amt25_unit25_unit5dec_t5blank', '110.74398');
        Observer.Expect('amt25_unit25_1234_5_t1', '1,234.50');
        Observer.Expect('amt25_unit25_1234_5_t2', '1,234.50');
        Observer.Expect('amt25_unit25_1234_5_t4', '1,234.50');
        Observer.Expect('amt25_unit25_1234_5_t5', '1,234.50');
        Observer.Expect('amt25_unit25_1234_5_t1blank', '1,234.50');
        Observer.Expect('amt25_unit25_1234_5_t2blank', '1,234.50');
        Observer.Expect('amt25_unit25_1234_5_t4blank', '1,234.50');
        Observer.Expect('amt25_unit25_1234_5_t5blank', '1,234.50');
        RestoreSetup();
        Observer.Verify();
    end;

    [Test]
    procedure Setup_AmountPlaces2to2_UnitPlaces2to5_NoCurrency()
    begin
        SetSetup('2:2', '2:5', "Show Currency"::Never);
        ReadBoth('amt22_unit25', '');
        Observer.Expect('amt22_unit25_unit5dec_t1', '110.74');
        Observer.Expect('amt22_unit25_unit5dec_t2', '110.74398');
        Observer.Expect('amt22_unit25_unit5dec_t4', '110.74');
        Observer.Expect('amt22_unit25_unit5dec_t5', '110.74398');
        Observer.Expect('amt22_unit25_unit5dec_t1blank', '110.74');
        Observer.Expect('amt22_unit25_unit5dec_t2blank', '110.74398');
        Observer.Expect('amt22_unit25_unit5dec_t4blank', '110.74');
        Observer.Expect('amt22_unit25_unit5dec_t5blank', '110.74398');
        Observer.Expect('amt22_unit25_1234_5_t1', '1,234.50');
        Observer.Expect('amt22_unit25_1234_5_t2', '1,234.50');
        Observer.Expect('amt22_unit25_1234_5_t4', '1,234.50');
        Observer.Expect('amt22_unit25_1234_5_t5', '1,234.50');
        Observer.Expect('amt22_unit25_1234_5_t1blank', '1,234.50');
        Observer.Expect('amt22_unit25_1234_5_t2blank', '1,234.50');
        Observer.Expect('amt22_unit25_1234_5_t4blank', '1,234.50');
        Observer.Expect('amt22_unit25_1234_5_t5blank', '1,234.50');
        RestoreSetup();
        Observer.Verify();
    end;

    [Test]
    procedure Setup_AmountPlaces2to5_UnitPlaces2to2_NoCurrency()
    begin
        SetSetup('2:5', '2:2', "Show Currency"::Never);
        ReadBoth('amt25_unit22', '');
        Observer.Expect('amt25_unit22_unit5dec_t1', '110.74');
        Observer.Expect('amt25_unit22_unit5dec_t2', '110.74398');
        Observer.Expect('amt25_unit22_unit5dec_t4', '110.74');
        Observer.Expect('amt25_unit22_unit5dec_t5', '110.74398');
        Observer.Expect('amt25_unit22_unit5dec_t1blank', '110.74');
        Observer.Expect('amt25_unit22_unit5dec_t2blank', '110.74398');
        Observer.Expect('amt25_unit22_unit5dec_t4blank', '110.74');
        Observer.Expect('amt25_unit22_unit5dec_t5blank', '110.74398');
        Observer.Expect('amt25_unit22_1234_5_t1', '1,234.50');
        Observer.Expect('amt25_unit22_1234_5_t2', '1,234.50');
        Observer.Expect('amt25_unit22_1234_5_t4', '1,234.50');
        Observer.Expect('amt25_unit22_1234_5_t5', '1,234.50');
        Observer.Expect('amt25_unit22_1234_5_t1blank', '1,234.50');
        Observer.Expect('amt25_unit22_1234_5_t2blank', '1,234.50');
        Observer.Expect('amt25_unit22_1234_5_t4blank', '1,234.50');
        Observer.Expect('amt25_unit22_1234_5_t5blank', '1,234.50');
        RestoreSetup();
        Observer.Verify();
    end;

    [Test]
    procedure CurrencyCode_CurrencyHasOwnPlaces_ShowCurrencyNever()
    begin
        SetSetup('2:5', '2:5', "Show Currency"::Never);
        SeedCurrency('PWC', '3:3', '4:4', 'PW$');
        ReadBoth('cur_never', 'PWC');
        Observer.Expect('cur_never_unit5dec_t1', '110.744');
        Observer.Expect('cur_never_unit5dec_t2', '110.7440');
        Observer.Expect('cur_never_unit5dec_t4', '110.744');
        Observer.Expect('cur_never_unit5dec_t5', '110.7440');
        Observer.Expect('cur_never_unit5dec_t1blank', '110.74');
        Observer.Expect('cur_never_unit5dec_t2blank', '110.74398');
        Observer.Expect('cur_never_unit5dec_t4blank', '110.74');
        Observer.Expect('cur_never_unit5dec_t5blank', '110.74398');
        Observer.Expect('cur_never_1234_5_t1', '1,234.500');
        Observer.Expect('cur_never_1234_5_t2', '1,234.5000');
        Observer.Expect('cur_never_1234_5_t4', '1,234.500');
        Observer.Expect('cur_never_1234_5_t5', '1,234.5000');
        Observer.Expect('cur_never_1234_5_t1blank', '1,234.50');
        Observer.Expect('cur_never_1234_5_t2blank', '1,234.50');
        Observer.Expect('cur_never_1234_5_t4blank', '1,234.50');
        Observer.Expect('cur_never_1234_5_t5blank', '1,234.50');
        RestoreSetup();
        Observer.Verify();
    end;

    [Test]
    procedure CurrencyCode_CurrencyHasOwnPlaces_ShowCurrencyFcySymbolOnly()
    begin
        SetSetup('2:5', '2:5', "Show Currency"::"FCY Symbol Only");
        SeedCurrency('PWC', '3:3', '4:4', 'PW$');
        ReadBoth('cur_fcy_symbol', 'PWC');
        Observer.Expect('cur_fcy_symbol_unit5dec_t1', '110.744');
        Observer.Expect('cur_fcy_symbol_unit5dec_t2', '110.7440');
        Observer.Expect('cur_fcy_symbol_unit5dec_t4', '110.744');
        Observer.Expect('cur_fcy_symbol_unit5dec_t5', '110.7440');
        Observer.Expect('cur_fcy_symbol_unit5dec_t1blank', '110.74');
        Observer.Expect('cur_fcy_symbol_unit5dec_t2blank', '110.74398');
        Observer.Expect('cur_fcy_symbol_unit5dec_t4blank', '110.74');
        Observer.Expect('cur_fcy_symbol_unit5dec_t5blank', '110.74398');
        Observer.Expect('cur_fcy_symbol_1234_5_t1', '1,234.500');
        Observer.Expect('cur_fcy_symbol_1234_5_t2', '1,234.5000');
        Observer.Expect('cur_fcy_symbol_1234_5_t4', '1,234.500');
        Observer.Expect('cur_fcy_symbol_1234_5_t5', '1,234.5000');
        Observer.Expect('cur_fcy_symbol_1234_5_t1blank', '1,234.50');
        Observer.Expect('cur_fcy_symbol_1234_5_t2blank', '1,234.50');
        Observer.Expect('cur_fcy_symbol_1234_5_t4blank', '1,234.50');
        Observer.Expect('cur_fcy_symbol_1234_5_t5blank', '1,234.50');
        RestoreSetup();
        Observer.Verify();
    end;

    [Test]
    procedure CurrencyCode_CurrencyWithoutPlacesOrSymbol_ShowCurrencyFcySymbolOnly()
    begin
        SetSetup('2:2', '2:5', "Show Currency"::"FCY Symbol Only");
        SeedCurrency('PWD', '', '', '');
        ReadBoth('cur_empty_fcy_symbol', 'PWD');
        Observer.Expect('cur_empty_fcy_symbol_unit5dec_t1', '110.74');
        Observer.Expect('cur_empty_fcy_symbol_unit5dec_t2', '110.74');
        Observer.Expect('cur_empty_fcy_symbol_unit5dec_t4', '110.74');
        Observer.Expect('cur_empty_fcy_symbol_unit5dec_t5', '110.74');
        Observer.Expect('cur_empty_fcy_symbol_unit5dec_t1blank', '110.74');
        Observer.Expect('cur_empty_fcy_symbol_unit5dec_t2blank', '110.74398');
        Observer.Expect('cur_empty_fcy_symbol_unit5dec_t4blank', '110.74');
        Observer.Expect('cur_empty_fcy_symbol_unit5dec_t5blank', '110.74398');
        Observer.Expect('cur_empty_fcy_symbol_1234_5_t1', '1,234.50');
        Observer.Expect('cur_empty_fcy_symbol_1234_5_t2', '1,234.50');
        Observer.Expect('cur_empty_fcy_symbol_1234_5_t4', '1,234.50');
        Observer.Expect('cur_empty_fcy_symbol_1234_5_t5', '1,234.50');
        Observer.Expect('cur_empty_fcy_symbol_1234_5_t1blank', '1,234.50');
        Observer.Expect('cur_empty_fcy_symbol_1234_5_t2blank', '1,234.50');
        Observer.Expect('cur_empty_fcy_symbol_1234_5_t4blank', '1,234.50');
        Observer.Expect('cur_empty_fcy_symbol_1234_5_t5blank', '1,234.50');
        RestoreSetup();
        Observer.Verify();
    end;

    [Test]
    procedure CurrencyCode_ShowCurrency_FcyCurrencyCodeOnly()
    begin
        SetSetup('2:5', '2:5', "Show Currency"::"FCY Currency Code Only");
        SeedCurrency('PWC', '3:3', '4:4', 'PW$');
        ReadBoth('cur_fcy_code', 'PWC');
        Observer.Expect('cur_fcy_code_unit5dec_t1', '110.744');
        Observer.Expect('cur_fcy_code_unit5dec_t2', '110.7440');
        Observer.Expect('cur_fcy_code_unit5dec_t4', '110.744');
        Observer.Expect('cur_fcy_code_unit5dec_t5', '110.7440');
        Observer.Expect('cur_fcy_code_unit5dec_t1blank', '110.74');
        Observer.Expect('cur_fcy_code_unit5dec_t2blank', '110.74398');
        Observer.Expect('cur_fcy_code_unit5dec_t4blank', '110.74');
        Observer.Expect('cur_fcy_code_unit5dec_t5blank', '110.74398');
        Observer.Expect('cur_fcy_code_1234_5_t1', '1,234.500');
        Observer.Expect('cur_fcy_code_1234_5_t2', '1,234.5000');
        Observer.Expect('cur_fcy_code_1234_5_t4', '1,234.500');
        Observer.Expect('cur_fcy_code_1234_5_t5', '1,234.5000');
        Observer.Expect('cur_fcy_code_1234_5_t1blank', '1,234.50');
        Observer.Expect('cur_fcy_code_1234_5_t2blank', '1,234.50');
        Observer.Expect('cur_fcy_code_1234_5_t4blank', '1,234.50');
        Observer.Expect('cur_fcy_code_1234_5_t5blank', '1,234.50');
        RestoreSetup();
        Observer.Verify();
    end;

    [Test]
    procedure CurrencyCode_ShowCurrency_LcyAndFcySymbol()
    begin
        SetSetup('2:5', '2:5', "Show Currency"::"LCY and FCY Symbol");
        SeedCurrency('PWC', '3:3', '4:4', 'PW$');
        ReadBoth('lcy_fcy_symbol_fcy_row', 'PWC');
        ReadBoth('lcy_fcy_symbol_lcy_row', '');
        Observer.Expect('lcy_fcy_symbol_fcy_row_unit5dec_t1', '110.744');
        Observer.Expect('lcy_fcy_symbol_fcy_row_unit5dec_t2', '110.7440');
        Observer.Expect('lcy_fcy_symbol_fcy_row_unit5dec_t4', '110.744');
        Observer.Expect('lcy_fcy_symbol_fcy_row_unit5dec_t5', '110.7440');
        Observer.Expect('lcy_fcy_symbol_fcy_row_unit5dec_t1blank', '110.74');
        Observer.Expect('lcy_fcy_symbol_fcy_row_unit5dec_t2blank', '110.74398');
        Observer.Expect('lcy_fcy_symbol_fcy_row_unit5dec_t4blank', '110.74');
        Observer.Expect('lcy_fcy_symbol_fcy_row_unit5dec_t5blank', '110.74398');
        Observer.Expect('lcy_fcy_symbol_fcy_row_1234_5_t1', '1,234.500');
        Observer.Expect('lcy_fcy_symbol_fcy_row_1234_5_t2', '1,234.5000');
        Observer.Expect('lcy_fcy_symbol_fcy_row_1234_5_t4', '1,234.500');
        Observer.Expect('lcy_fcy_symbol_fcy_row_1234_5_t5', '1,234.5000');
        Observer.Expect('lcy_fcy_symbol_fcy_row_1234_5_t1blank', '1,234.50');
        Observer.Expect('lcy_fcy_symbol_fcy_row_1234_5_t2blank', '1,234.50');
        Observer.Expect('lcy_fcy_symbol_fcy_row_1234_5_t4blank', '1,234.50');
        Observer.Expect('lcy_fcy_symbol_fcy_row_1234_5_t5blank', '1,234.50');
        Observer.Expect('lcy_fcy_symbol_lcy_row_unit5dec_t1', '110.74');
        Observer.Expect('lcy_fcy_symbol_lcy_row_unit5dec_t2', '110.74398');
        Observer.Expect('lcy_fcy_symbol_lcy_row_unit5dec_t4', '110.74');
        Observer.Expect('lcy_fcy_symbol_lcy_row_unit5dec_t5', '110.74398');
        Observer.Expect('lcy_fcy_symbol_lcy_row_unit5dec_t1blank', '110.74');
        Observer.Expect('lcy_fcy_symbol_lcy_row_unit5dec_t2blank', '110.74398');
        Observer.Expect('lcy_fcy_symbol_lcy_row_unit5dec_t4blank', '110.74');
        Observer.Expect('lcy_fcy_symbol_lcy_row_unit5dec_t5blank', '110.74398');
        Observer.Expect('lcy_fcy_symbol_lcy_row_1234_5_t1', '1,234.50');
        Observer.Expect('lcy_fcy_symbol_lcy_row_1234_5_t2', '1,234.50');
        Observer.Expect('lcy_fcy_symbol_lcy_row_1234_5_t4', '1,234.50');
        Observer.Expect('lcy_fcy_symbol_lcy_row_1234_5_t5', '1,234.50');
        Observer.Expect('lcy_fcy_symbol_lcy_row_1234_5_t1blank', '1,234.50');
        Observer.Expect('lcy_fcy_symbol_lcy_row_1234_5_t2blank', '1,234.50');
        Observer.Expect('lcy_fcy_symbol_lcy_row_1234_5_t4blank', '1,234.50');
        Observer.Expect('lcy_fcy_symbol_lcy_row_1234_5_t5blank', '1,234.50');
        RestoreSetup();
        Observer.Verify();
    end;

    [Test]
    procedure CurrencyCode_ShowCurrency_LcyAndFcyCurrencyCode()
    begin
        SetSetup('2:5', '2:5', "Show Currency"::"LCY and FCY Currency Code");
        SeedCurrency('PWC', '3:3', '4:4', 'PW$');
        ReadBoth('lcy_fcy_code_fcy_row', 'PWC');
        ReadBoth('lcy_fcy_code_lcy_row', '');
        Observer.Expect('lcy_fcy_code_fcy_row_unit5dec_t1', '110.744');
        Observer.Expect('lcy_fcy_code_fcy_row_unit5dec_t2', '110.7440');
        Observer.Expect('lcy_fcy_code_fcy_row_unit5dec_t4', '110.744');
        Observer.Expect('lcy_fcy_code_fcy_row_unit5dec_t5', '110.7440');
        Observer.Expect('lcy_fcy_code_fcy_row_unit5dec_t1blank', '110.74');
        Observer.Expect('lcy_fcy_code_fcy_row_unit5dec_t2blank', '110.74398');
        Observer.Expect('lcy_fcy_code_fcy_row_unit5dec_t4blank', '110.74');
        Observer.Expect('lcy_fcy_code_fcy_row_unit5dec_t5blank', '110.74398');
        Observer.Expect('lcy_fcy_code_fcy_row_1234_5_t1', '1,234.500');
        Observer.Expect('lcy_fcy_code_fcy_row_1234_5_t2', '1,234.5000');
        Observer.Expect('lcy_fcy_code_fcy_row_1234_5_t4', '1,234.500');
        Observer.Expect('lcy_fcy_code_fcy_row_1234_5_t5', '1,234.5000');
        Observer.Expect('lcy_fcy_code_fcy_row_1234_5_t1blank', '1,234.50');
        Observer.Expect('lcy_fcy_code_fcy_row_1234_5_t2blank', '1,234.50');
        Observer.Expect('lcy_fcy_code_fcy_row_1234_5_t4blank', '1,234.50');
        Observer.Expect('lcy_fcy_code_fcy_row_1234_5_t5blank', '1,234.50');
        Observer.Expect('lcy_fcy_code_lcy_row_unit5dec_t1', '110.74');
        Observer.Expect('lcy_fcy_code_lcy_row_unit5dec_t2', '110.74398');
        Observer.Expect('lcy_fcy_code_lcy_row_unit5dec_t4', '110.74');
        Observer.Expect('lcy_fcy_code_lcy_row_unit5dec_t5', '110.74398');
        Observer.Expect('lcy_fcy_code_lcy_row_unit5dec_t1blank', '110.74');
        Observer.Expect('lcy_fcy_code_lcy_row_unit5dec_t2blank', '110.74398');
        Observer.Expect('lcy_fcy_code_lcy_row_unit5dec_t4blank', '110.74');
        Observer.Expect('lcy_fcy_code_lcy_row_unit5dec_t5blank', '110.74398');
        Observer.Expect('lcy_fcy_code_lcy_row_1234_5_t1', '1,234.50');
        Observer.Expect('lcy_fcy_code_lcy_row_1234_5_t2', '1,234.50');
        Observer.Expect('lcy_fcy_code_lcy_row_1234_5_t4', '1,234.50');
        Observer.Expect('lcy_fcy_code_lcy_row_1234_5_t5', '1,234.50');
        Observer.Expect('lcy_fcy_code_lcy_row_1234_5_t1blank', '1,234.50');
        Observer.Expect('lcy_fcy_code_lcy_row_1234_5_t2blank', '1,234.50');
        Observer.Expect('lcy_fcy_code_lcy_row_1234_5_t4blank', '1,234.50');
        Observer.Expect('lcy_fcy_code_lcy_row_1234_5_t5blank', '1,234.50');
        RestoreSetup();
        Observer.Verify();
    end;

    [Test]
    procedure CurrencyCode_UnknownCurrency()
    begin
        SetSetup('2:5', '2:5', "Show Currency"::"FCY Symbol Only");
        ReadBoth('cur_unknown', 'NOPE');
        Observer.Expect('cur_unknown_unit5dec_t1', '110.74398');
        Observer.Expect('cur_unknown_unit5dec_t2', '110.74398');
        Observer.Expect('cur_unknown_unit5dec_t4', '110.74398');
        Observer.Expect('cur_unknown_unit5dec_t5', '110.74398');
        Observer.Expect('cur_unknown_unit5dec_t1blank', '110.74');
        Observer.Expect('cur_unknown_unit5dec_t2blank', '110.74398');
        Observer.Expect('cur_unknown_unit5dec_t4blank', '110.74');
        Observer.Expect('cur_unknown_unit5dec_t5blank', '110.74398');
        Observer.Expect('cur_unknown_1234_5_t1', '1,234.50');
        Observer.Expect('cur_unknown_1234_5_t2', '1,234.50');
        Observer.Expect('cur_unknown_1234_5_t4', '1,234.50');
        Observer.Expect('cur_unknown_1234_5_t5', '1,234.50');
        Observer.Expect('cur_unknown_1234_5_t1blank', '1,234.50');
        Observer.Expect('cur_unknown_1234_5_t2blank', '1,234.50');
        Observer.Expect('cur_unknown_1234_5_t4blank', '1,234.50');
        Observer.Expect('cur_unknown_1234_5_t5blank', '1,234.50');
        RestoreSetup();
        Observer.Verify();
    end;
}
