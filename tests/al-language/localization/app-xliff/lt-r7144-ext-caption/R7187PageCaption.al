// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-work-with-translation-files
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 95994 "LT R7144 Row" (field "No." with a nl-NL unit 'Rijnummer'); page 96164 and
//   table extension 96163 of Base Application's "Sales Line"; translation units in Translations/AL Language Coverage Tests.nl-NL.xlf.
// Probe (al-runner issues 7187 and 7184 follow-up, writer cw-7184): under GlobalLanguage 1043 (the app ships an nl-NL file), TestPage control
//   Caption() of the app's own page for a control with its own Caption property and a unit, and for a field control whose caption comes
//   from the table field; the error text of a SetValue that the control cannot take (it names the caption); and Sales Line."Inv. Discount
//   Amount" (a Base Application field with a CaptionClass) while this app extends Sales Line without touching that field.
// BC versions: 27.0+

tableextension 96163 "LT R7187 Sales Line Ext" extends "Sales Line"
{
    fields
    {
        field(96163; "R7187 Ext Note"; Text[30])
        {
            Caption = 'R7187 note';
            DataClassification = CustomerContent;
        }
    }
}

page 96164 "LT R7187 Row Card"
{
    PageType = Card;
    SourceTable = "LT R7144 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(RowIdCtl; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Row id';
            }
            field(PlainCtl; Rec."No.")
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 96165 "LT R7187 Page Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure R7187_PageControlCaptions_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R7187 Row Card";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1043);
        Card.OpenNew();
        Observer.Observe('own control caption with unit', Card.RowIdCtl.Caption());
        Observer.Observe('field control caption from the table field', Card.PlainCtl.Caption());
        Card.Close();
        GlobalLanguage(Saved);
        Observer.Expect('own control caption with unit', 'Rij-id');
        Observer.Expect('field control caption from the table field', 'Rijnummer');
        Observer.Verify();
    end;

    [Test]
    procedure R7187_PageControlCaptions_English()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R7187 Row Card";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Card.OpenNew();
        Observer.Observe('own control caption', Card.RowIdCtl.Caption());
        Observer.Observe('field control caption', Card.PlainCtl.Caption());
        Card.Close();
        GlobalLanguage(Saved);
        Observer.Expect('own control caption', 'Row id');
        Observer.Expect('field control caption', 'Row number');
        Observer.Verify();
    end;

    [Test]
    procedure R7187_SetValueError_OwnControl_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R7187 Row Card";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1043);
        Card.OpenNew();
        if TrySetOwn(Card) then
            Error('SetValue did not fail');
        Observer.Observe('own control text', GetLastErrorText());
        Observer.Observe('own control code', GetLastErrorCode());
        Card.Close();
        GlobalLanguage(Saved);
        Observer.Expect('own control text', 'Validatiefout voor veld: RowIdCtl, bericht = ''Your entry of ''abc'' is not an acceptable value for ''Rij-id''. De waarde "abc" kan niet worden geëvalueerd tot type Integer.''');
        Observer.Expect('own control code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure R7187_SetValueError_OwnControl_English()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R7187 Row Card";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Card.OpenNew();
        if TrySetOwn(Card) then
            Error('SetValue did not fail');
        Observer.Observe('own control text', GetLastErrorText());
        Observer.Observe('own control code', GetLastErrorCode());
        Card.Close();
        GlobalLanguage(Saved);
        Observer.Expect('own control text', 'Validation error for Field: RowIdCtl,  Message = ''Your entry of ''abc'' is not an acceptable value for ''Row id''. The value "abc" can''t be evaluated into type Integer.''');
        Observer.Expect('own control code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure R7187_SetValueError_FieldControlText_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R7187 Row Card";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1043);
        Card.OpenNew();
        if TrySetPlain(Card) then
            Error('SetValue did not fail');
        Observer.Observe('field control text', GetLastErrorText());
        Card.Close();
        GlobalLanguage(Saved);
        Observer.Expect('field control text', 'Validatiefout voor veld: PlainCtl, bericht = ''Your entry of ''abc'' is not an acceptable value for ''Rijnummer''. De waarde "abc" kan niet worden geëvalueerd tot type Integer.'''');
        Observer.Verify();
    end;

    [Test]
    procedure R7187_SetValueError_FieldControlCode_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R7187 Row Card";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1043);
        Card.OpenNew();
        if TrySetPlain(Card) then
            Error('SetValue did not fail');
        Observer.Observe('field control code', GetLastErrorCode());
        Card.Close();
        GlobalLanguage(Saved);
        Observer.Expect('field control code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure R7187_SetValueError_FieldControlText_English()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R7187 Row Card";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Card.OpenNew();
        if TrySetPlain(Card) then
            Error('SetValue did not fail');
        Observer.Observe('field control text', GetLastErrorText());
        Card.Close();
        GlobalLanguage(Saved);
        Observer.Expect('field control text', 'Validation error for Field: PlainCtl,  Message = ''Your entry of ''abc'' is not an acceptable value for ''Row number''. The value "abc" can''t be evaluated into type Integer.'''');
        Observer.Verify();
    end;

    [Test]
    procedure R7187_SetValueError_FieldControlCode_English()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R7187 Row Card";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Card.OpenNew();
        if TrySetPlain(Card) then
            Error('SetValue did not fail');
        Observer.Observe('field control code', GetLastErrorCode());
        Card.Close();
        GlobalLanguage(Saved);
        Observer.Expect('field control code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure R7187_SalesLineCaptionClassField_Dutch()
    var
        Observer: Codeunit "Probe Observer";
        SalesLine: Record "Sales Line";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1043);
        Observer.Observe('SalesLine.FieldCaption Inv. Discount Amount', SalesLine.FieldCaption("Inv. Discount Amount"));
        Observer.Observe('FieldRef.Caption 69', RefCaption(Database::"Sales Line", 69));
        Observer.Observe('SalesLine.FieldCaption Description', SalesLine.FieldCaption(Description));
        Observer.Observe('SalesLine.FieldCaption extension field', SalesLine.FieldCaption("R7187 Ext Note"));
        GlobalLanguage(Saved);
        Observer.Expect('SalesLine.FieldCaption Inv. Discount Amount', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('FieldRef.Caption 69', 'Inv. Discount Amount Excl. VAT');
        Observer.Expect('SalesLine.FieldCaption Description', 'Description');
        Observer.Expect('SalesLine.FieldCaption extension field', 'R7187 note');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetOwn(var Card: TestPage "LT R7187 Row Card")
    begin
        Card.RowIdCtl.SetValue('abc');
    end;

    [TryFunction]
    local procedure TrySetPlain(var Card: TestPage "LT R7187 Row Card")
    begin
        Card.PlainCtl.SetValue('abc');
    end;

    local procedure RefCaption(TableNo: Integer; FieldNo: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Caption: Text;
    begin
        RecRef.Open(TableNo);
        FldRef := RecRef.Field(FieldNo);
        Caption := FldRef.Caption();
        RecRef.Close();
        exit(Caption);
    end;
}
