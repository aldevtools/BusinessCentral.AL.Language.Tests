// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-charallowed-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT AA Row" (76500, AaObjects.al)
// BC versions: 27+ (tested by the corpus CI matrix)
// Facts: page field properties CharAllowed, DateFormula, OptionCaptionML, SignDisplacement and Title as a TestPage sees them.

page 76502 "LT AA Field Card"
{
    PageType = Card;
    SourceTable = "LT AA Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(PageLower; Rec.Txt)
            {
                ApplicationArea = All;
                CharAllowed = 'az';
            }
            field(PageDigits; Rec.Txt)
            {
                ApplicationArea = All;
                CharAllowed = '09';
            }
            field(TableLower; Rec.Lower) { ApplicationArea = All; }
            field(DateText; Rec."When")
            {
                ApplicationArea = All;
                DateFormula = true;
            }
            field(PlainText; Rec."When") { ApplicationArea = All; }
            field(OptTranslated; Rec.Opt)
            {
                ApplicationArea = All;
                OptionCaptionML = ENU = 'One,Two,Three', DEU = 'Eins,Zwei,Drei';
            }
            field(OptPlain; Rec.Opt) { ApplicationArea = All; }
            field(SignOne; Rec.Amt)
            {
                ApplicationArea = All;
                SignDisplacement = 1;
            }
            field(SignTwo; Rec.Amt)
            {
                ApplicationArea = All;
                SignDisplacement = 2;
            }
            field(PlainAmt; Rec.Amt) { ApplicationArea = All; }
            field(TitleField; Rec.Txt)
            {
                ApplicationArea = All;
                Title = true;
            }
        }
    }
}

codeunit 76510 "LT AA Field Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AA_CharAllowed_PageField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Field Card";
    begin
        Seed(Row);
        P.OpenEdit();
        P.PageLower.SetValue('abc');
        Observer.Observe('lower-ok', P.PageLower.Value());
        asserterror P.PageLower.SetValue('aBc');
        Observer.ObserveError('lower-upper-error');
        P.PageLower.SetValue('xyz');
        Observer.Observe('lower-after', P.PageLower.Value());
        P.PageDigits.SetValue('123');
        Observer.Observe('digits-ok', P.PageDigits.Value());
        asserterror P.PageDigits.SetValue('12a');
        Observer.ObserveError('digits-letter-error');
        P.Close();
        Row.Get('A');
        Observer.Observe('stored', Row.Txt);
        Observer.Expect('lower-ok', 'abc');
        Observer.Expect('lower-upper-error|text', 'Validation error for Field: PageLower,  Message = ''The character B is not valid in this field. You can specify the following characters: az. (Select Refresh to discard errors)''');
        Observer.Expect('lower-upper-error|code', 'TestValidation');
        Observer.Expect('lower-after', 'xyz');
        Observer.Expect('digits-ok', '123');
        Observer.Expect('digits-letter-error|text', 'Validation error for Field: PageDigits,  Message = ''The character a is not valid in this field. You can specify the following characters: 09. (Select Refresh to discard errors)''');
        Observer.Expect('digits-letter-error|code', 'TestValidation');
        Observer.Expect('stored', '');
        Observer.Verify();
    end;

    [Test]
    procedure AA_CharAllowed_TableField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Field Card";
    begin
        Seed(Row);
        P.OpenEdit();
        Observer.Observe('page-lower-ok', Format(TrySetTableLower(P, 'abc')));
        Observer.Observe('page-lower-value', P.TableLower.Value());
        Observer.Observe('page-upper-ok', Format(TrySetTableLower(P, 'ABC')));
        if GetLastErrorText() <> '' then
            Observer.ObserveError('page-upper-error');
        Observer.Observe('page-upper-value', P.TableLower.Value());
        P.Close();
        Row.Get('A');
        Observer.Observe('stored-after-page', Row.Lower);
        Observer.Observe('validate-ok', Format(TryValidateLower(Row, 'xyz')));
        Observer.Observe('validate-ok-value', Row.Lower);
        Observer.Observe('validate-upper', Format(TryValidateLower(Row, 'XYZ')));
        if GetLastErrorText() <> '' then
            Observer.ObserveError('validate-upper-error');
        Row.Lower := 'QRS';
        Observer.Observe('assign', Row.Lower);
        Observer.Expect('page-lower-ok', 'Yes');
        Observer.Expect('page-lower-value', 'abc');
        Observer.Expect('page-upper-ok', 'No');
        Observer.Expect('page-upper-error|text', 'Validation error for Field: TableLower,  Message = ''The character A is not valid in this field. You can specify the following characters: az. (Select Refresh to discard errors)''');
        Observer.Expect('page-upper-error|code', 'TestValidation');
        Observer.Expect('page-upper-value', 'abc');
        Observer.Expect('stored-after-page', '');
        Observer.Expect('validate-ok', 'Yes');
        Observer.Expect('validate-ok-value', 'xyz');
        Observer.Expect('validate-upper', 'Yes');
        Observer.Expect('assign', 'QRS');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetTableLower(var P: TestPage "LT AA Field Card"; NewValue: Text)
    begin
        P.TableLower.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TryValidateLower(var Row: Record "LT AA Row"; NewValue: Text)
    begin
        Row.Validate(Lower, CopyStr(NewValue, 1, MaxStrLen(Row.Lower)));
    end;

    [Test]
    procedure AA_DateFormula_PageField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Field Card";
    begin
        Seed(Row);
        P.OpenEdit();
        P.DateText.SetValue('1D');
        Observer.Observe('formula-1D', P.DateText.Value());
        P.DateText.SetValue('CM+1D');
        Observer.Observe('formula-CM+1D', P.DateText.Value());
        P.DateText.SetValue('text that is no formula');
        Observer.Observe('no-formula', P.DateText.Value());
        P.PlainText.SetValue('1D');
        Observer.Observe('plain-1D', P.PlainText.Value());
        P.Close();
        Row.Get('A');
        Observer.Observe('stored', Row."When");
        Observer.Expect('formula-1D', '1D');
        Observer.Expect('formula-CM+1D', 'CM+1D');
        Observer.Expect('no-formula', 'text that is no formula');
        Observer.Expect('plain-1D', '1D');
        Observer.Expect('stored', '1D');
        Observer.Verify();
    end;

    [Test]
    procedure AA_OptionCaptionML_PageField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Field Card";
        Saved: Integer;
        i: Integer;
        Count: Integer;
    begin
        Seed(Row);
        Saved := GlobalLanguage();
        P.OpenEdit();
        GlobalLanguage(1033);
        Observer.Observe('enu-value', P.OptTranslated.Value());
        Observer.Observe('enu-count', Format(P.OptTranslated.OptionCount()));
        Count := P.OptTranslated.OptionCount();
        for i := 1 to Count do
            Observer.Observe('enu-option-' + Format(i), P.OptTranslated.GetOption(i));
        Observer.Observe('plain-value', P.OptPlain.Value());
        GlobalLanguage(1031);
        Observer.Observe('deu-value', P.OptTranslated.Value());
        for i := 1 to P.OptTranslated.OptionCount() do
            Observer.Observe('deu-option-' + Format(i), P.OptTranslated.GetOption(i));
        GlobalLanguage(1036);
        Observer.Observe('fra-value', P.OptTranslated.Value());
        for i := 1 to P.OptTranslated.OptionCount() do
            Observer.Observe('fra-option-' + Format(i), P.OptTranslated.GetOption(i));
        GlobalLanguage(1033);
        P.OptTranslated.SetValue('Three');
        Observer.Observe('set-by-caption', P.OptPlain.Value());
        GlobalLanguage(Saved);
        P.Close();
        Row.Get('A');
        Observer.Observe('stored', Format(Row.Opt, 0, 2));
        Observer.Expect('enu-value', 'One');
        Observer.Expect('enu-count', '3');
        Observer.Expect('enu-option-1', 'One');
        Observer.Expect('enu-option-2', 'Two');
        Observer.Expect('enu-option-3', 'Three');
        Observer.Expect('plain-value', 'Alpha');
        Observer.Expect('deu-value', 'One');
        Observer.Expect('deu-option-1', 'One');
        Observer.Expect('deu-option-2', 'Two');
        Observer.Expect('deu-option-3', 'Three');
        Observer.Expect('fra-value', 'One');
        Observer.Expect('fra-option-1', 'One');
        Observer.Expect('fra-option-2', 'Two');
        Observer.Expect('fra-option-3', 'Three');
        Observer.Expect('set-by-caption', 'Gamma');
        Observer.Expect('stored', '2');
        Observer.Verify();
    end;

    [Test]
    procedure AA_SignDisplacement_PageField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Field Card";
    begin
        Seed(Row);
        Row.Amt := -5;
        Row.Modify();
        P.OpenEdit();
        Observer.Observe('neg-plain', P.PlainAmt.Value());
        Observer.Observe('neg-sign1', P.SignOne.Value());
        Observer.Observe('neg-sign2', P.SignTwo.Value());
        P.Close();
        Row.Amt := 7;
        Row.Modify();
        P.OpenEdit();
        Observer.Observe('pos-plain', P.PlainAmt.Value());
        Observer.Observe('pos-sign1', P.SignOne.Value());
        Observer.Observe('pos-sign2', P.SignTwo.Value());
        P.Close();
        Observer.Observe('format-neg', Format(-5));
        Observer.Expect('neg-plain', '-5.00');
        Observer.Expect('neg-sign1', '-5.00');
        Observer.Expect('neg-sign2', '-5.00');
        Observer.Expect('pos-plain', '7.00');
        Observer.Expect('pos-sign1', '7.00');
        Observer.Expect('pos-sign2', '7.00');
        Observer.Expect('format-neg', '-5');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Title_PageField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Field Card";
    begin
        Seed(Row);
        Row.Txt := 'Titled';
        Row.Modify();
        P.OpenEdit();
        Observer.Observe('title-value', P.TitleField.Value());
        Observer.Observe('title-caption', P.TitleField.Caption());
        Observer.Observe('title-visible', Format(P.TitleField.Visible()));
        Observer.Observe('title-editable', Format(P.TitleField.Editable()));
        Observer.Observe('page-caption', P.Caption());
        P.Close();
        Observer.Expect('title-value', 'Titled');
        Observer.Expect('title-caption', 'Txt');
        Observer.Expect('title-visible', 'Yes');
        Observer.Expect('title-editable', 'Yes');
        Observer.Expect('page-caption', 'LT AA Field Card - A');
        Observer.Verify();
    end;

    local procedure Seed(var Row: Record "LT AA Row")
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 'A';
        Row.Insert();
        Commit();
    end;
}
