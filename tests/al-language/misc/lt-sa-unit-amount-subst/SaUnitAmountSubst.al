// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-strsubstno-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT SA UA *); System tables Currency and General Ledger Setup
// Probe (al-runner issue 5827): Format(Rec.Field), StrSubstNo('%1', Rec.Field), Message('%1', Rec.Field) and Error('%1', Rec.Field) of
//   Decimal fields with AutoFormatType 1, 2, 4 and 5, each with AutoFormatExpression = Rec."Currency Code", without an expression and with a
//   constant currency code, under General Ledger Setup places that differ from the defaults (amount 1:3, unit amount 2:5) and a currency
//   with amount places 3:3 and unit-amount places 4:4; the currency code blank, set, and naming no currency; a database record read with
//   Get (the reporter's shape) and a temporary record; a Decimal variable copy of such a field.
//   Covers the shapes of al-sema lower/call.rs "StrSubstNo, Message or Error %n of a Decimal field with this DecimalPlaces or AutoFormat".
// Object ids 88950-88951. BC versions: 27, 28, 29 (CI matrix)

table 88950 "LT SA UA Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; "Currency Code"; Code[10]) { }
        field(3; A1; Decimal) { AutoFormatType = 1; AutoFormatExpression = Rec."Currency Code"; }
        field(4; A2; Decimal) { AutoFormatType = 2; AutoFormatExpression = Rec."Currency Code"; }
        field(5; A4; Decimal) { AutoFormatType = 4; AutoFormatExpression = Rec."Currency Code"; }
        field(6; A5; Decimal) { AutoFormatType = 5; AutoFormatExpression = Rec."Currency Code"; }
        field(7; A1No; Decimal) { AutoFormatType = 1; }
        field(8; A2No; Decimal) { AutoFormatType = 2; }
        field(9; A4No; Decimal) { AutoFormatType = 4; }
        field(10; A5No; Decimal) { AutoFormatType = 5; }
        field(11; A1Lit; Decimal) { AutoFormatType = 1; AutoFormatExpression = 'SAU'; }
        field(12; A2Lit; Decimal) { AutoFormatType = 2; AutoFormatExpression = 'SAU'; }
        field(13; A2Dp; Decimal) { AutoFormatType = 2; AutoFormatExpression = Rec."Currency Code"; DecimalPlaces = 0 : 1; }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
    }
}

codeunit 88951 "LT SA UA Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LastMessage: Text;
        SavedAmountPlaces: Text;
        SavedUnitPlaces: Text;
        SavedShowCurrency: Enum "Show Currency";

    local procedure SetSetup(ShowCurrency: Enum "Show Currency")
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if not GLSetup.Get() then begin
            GLSetup.Init();
            GLSetup.Insert();
        end;
        SavedAmountPlaces := GLSetup."Amount Decimal Places";
        SavedUnitPlaces := GLSetup."Unit-Amount Decimal Places";
        SavedShowCurrency := GLSetup."Show Currency";
        GLSetup."Amount Decimal Places" := '1:3';
        GLSetup."Unit-Amount Decimal Places" := '2:5';
        GLSetup."Show Currency" := ShowCurrency;
        GLSetup.Modify();
        if Currency.Get('SAU') then
            Currency.Delete();
        Currency.Init();
        Currency.Code := 'SAU';
        Currency.Symbol := 'U$';
        Currency."Amount Decimal Places" := '3:3';
        Currency."Unit-Amount Decimal Places" := '4:4';
        Currency.Insert();
        if Currency.Get('SANONE') then
            Currency.Delete();
    end;

    // The BC 27.5 test runner commits what a test leaves (autoformat/PWAutoFormatTypes.al RestoreSetup), so every test puts the setup back.
    local procedure RestoreSetup()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        Line: Record "LT SA UA Line";
    begin
        Line.DeleteAll();
        if Currency.Get('SAU') then
            Currency.Delete();
        if not GLSetup.Get() then
            exit;
        GLSetup."Amount Decimal Places" := CopyStr(SavedAmountPlaces, 1, MaxStrLen(GLSetup."Amount Decimal Places"));
        GLSetup."Unit-Amount Decimal Places" := CopyStr(SavedUnitPlaces, 1, MaxStrLen(GLSetup."Unit-Amount Decimal Places"));
        GLSetup."Show Currency" := SavedShowCurrency;
        GLSetup.Modify();
    end;

    local procedure Fill(var Line: Record "LT SA UA Line"; LineNo: Integer; CurrencyCode: Code[10]; Value: Decimal)
    begin
        Line.Init();
        Line."Line No." := LineNo;
        Line."Currency Code" := CurrencyCode;
        Line.A1 := Value;
        Line.A2 := Value;
        Line.A4 := Value;
        Line.A5 := Value;
        Line.A1No := Value;
        Line.A2No := Value;
        Line.A4No := Value;
        Line.A5No := Value;
        Line.A1Lit := Value;
        Line.A2Lit := Value;
        Line.A2Dp := Value;
    end;

    local procedure ObserveSubst(var Observer: Codeunit "Probe Observer"; Tag: Text; var Line: Record "LT SA UA Line")
    begin
        Observer.Observe(Tag + 'A1', StrSubstNo('%1', Line.A1));
        Observer.Observe(Tag + 'A2', StrSubstNo('%1', Line.A2));
        Observer.Observe(Tag + 'A4', StrSubstNo('%1', Line.A4));
        Observer.Observe(Tag + 'A5', StrSubstNo('%1', Line.A5));
        Observer.Observe(Tag + 'A1No', StrSubstNo('%1', Line.A1No));
        Observer.Observe(Tag + 'A2No', StrSubstNo('%1', Line.A2No));
        Observer.Observe(Tag + 'A4No', StrSubstNo('%1', Line.A4No));
        Observer.Observe(Tag + 'A5No', StrSubstNo('%1', Line.A5No));
        Observer.Observe(Tag + 'A1Lit', StrSubstNo('%1', Line.A1Lit));
        Observer.Observe(Tag + 'A2Lit', StrSubstNo('%1', Line.A2Lit));
        Observer.Observe(Tag + 'A2Dp', StrSubstNo('%1', Line.A2Dp));
    end;

    local procedure ObserveFormat(var Observer: Codeunit "Probe Observer"; Tag: Text; var Line: Record "LT SA UA Line")
    begin
        Observer.Observe(Tag + 'A1', Format(Line.A1));
        Observer.Observe(Tag + 'A2', Format(Line.A2));
        Observer.Observe(Tag + 'A4', Format(Line.A4));
        Observer.Observe(Tag + 'A5', Format(Line.A5));
        Observer.Observe(Tag + 'A1No', Format(Line.A1No));
        Observer.Observe(Tag + 'A2No', Format(Line.A2No));
        Observer.Observe(Tag + 'A4No', Format(Line.A4No));
        Observer.Observe(Tag + 'A5No', Format(Line.A5No));
        Observer.Observe(Tag + 'A1Lit', Format(Line.A1Lit));
        Observer.Observe(Tag + 'A2Lit', Format(Line.A2Lit));
        Observer.Observe(Tag + 'A2Dp', Format(Line.A2Dp));
    end;

    local procedure Seed(Value: Decimal)
    var
        Line: Record "LT SA UA Line";
    begin
        Line.DeleteAll();
        Fill(Line, 1, '', Value);
        Line.Insert();
        Fill(Line, 2, 'SAU', Value);
        Line.Insert();
        Fill(Line, 3, 'SANONE', Value);
        Line.Insert();
    end;

    local procedure ObserveLines(var Observer: Codeunit "Probe Observer"; Value: Decimal; WithFormat: Boolean)
    var
        Line: Record "LT SA UA Line";
        LineNo: Integer;
    begin
        Seed(Value);
        for LineNo := 1 to 3 do begin
            Line.Get(LineNo);
            if WithFormat then
                ObserveFormat(Observer, 'f' + Format(LineNo), Line)
            else
                ObserveSubst(Observer, 's' + Format(LineNo), Line);
        end;
    end;

    // The reporter's values: 1234.5 needs one decimal on its own, 7.2 is below the thousands, 3.14159265 has more places than any maximum.
    // Tags: s = StrSubstNo, f = Format; 1 = blank currency, 2 = SAU, 3 = SANONE (no such currency).
    [Test]
    procedure SA_UA_Subst_1234_5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup("Show Currency"::Never);
        ObserveLines(Observer, 1234.5, false);
        RestoreSetup();
        Observer.Finish();
    end;

    [Test]
    procedure SA_UA_Subst_7_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup("Show Currency"::Never);
        ObserveLines(Observer, 7.2, false);
        RestoreSetup();
        Observer.Finish();
    end;

    [Test]
    procedure SA_UA_Subst_ManyPlaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup("Show Currency"::Never);
        ObserveLines(Observer, 3.14159265, false);
        RestoreSetup();
        Observer.Finish();
    end;

    [Test]
    procedure SA_UA_Format_1234_5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup("Show Currency"::Never);
        ObserveLines(Observer, 1234.5, true);
        RestoreSetup();
        Observer.Finish();
    end;

    [Test]
    procedure SA_UA_Format_ManyPlaces()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetSetup("Show Currency"::Never);
        ObserveLines(Observer, 3.14159265, true);
        RestoreSetup();
        Observer.Finish();
    end;

    [Test]
    procedure SA_UA_Subst_Zero_Negative()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT SA UA Line";
    begin
        SetSetup("Show Currency"::Never);
        Seed(0);
        Line.Get(2);
        ObserveSubst(Observer, 'z', Line);
        Seed(-1234.5);
        Line.Get(2);
        ObserveSubst(Observer, 'n', Line);
        RestoreSetup();
        Observer.Finish();
    end;

    // Show Currency of the setup on the text of a field (it shows a symbol on a page control).
    [Test]
    procedure SA_UA_Subst_ShowCurrencySymbol()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT SA UA Line";
    begin
        SetSetup("Show Currency"::"LCY and FCY Symbol");
        Seed(1234.5);
        Line.Get(1);
        ObserveSubst(Observer, 's1', Line);
        Line.Get(2);
        ObserveSubst(Observer, 's2', Line);
        Observer.Observe('f2A1', Format(Line.A1));
        RestoreSetup();
        Observer.Finish();
    end;

    // A temporary record, the currency code changed after the value was set (no Modify), and a Decimal variable copy.
    [Test]
    procedure SA_UA_Subst_TempRecord_Carrier()
    var
        Observer: Codeunit "Probe Observer";
        TempLine: Record "LT SA UA Line" temporary;
        Copy: Decimal;
    begin
        SetSetup("Show Currency"::Never);
        Fill(TempLine, 1, 'SAU', 1234.5);
        TempLine.Insert();
        ObserveSubst(Observer, 't', TempLine);
        TempLine."Currency Code" := '';
        Observer.Observe('changedA1', StrSubstNo('%1', TempLine.A1));
        Observer.Observe('changedA2', StrSubstNo('%1', TempLine.A2));
        TempLine."Currency Code" := 'SAU';
        Copy := TempLine.A2;
        Observer.Observe('varA2', StrSubstNo('%1', Copy));
        Observer.Observe('twoA2', StrSubstNo('%1|%2', TempLine.A2, TempLine.A1));
        RestoreSetup();
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SaMessageHandler')]
    procedure SA_UA_MessageError()
    var
        Observer: Codeunit "Probe Observer";
        Line: Record "LT SA UA Line";
        LineNo: Integer;
    begin
        SetSetup("Show Currency"::Never);
        Seed(1234.5);
        for LineNo := 1 to 3 do begin
            Line.Get(LineNo);
            asserterror Error('%1', Line.A1);
            Observer.Observe(Format(LineNo) + '-errA1', GetLastErrorText());
            asserterror Error('x=%1', Line.A2);
            Observer.Observe(Format(LineNo) + '-errA2', GetLastErrorText());
            asserterror Error('%1', Line.A2No);
            Observer.Observe(Format(LineNo) + '-errA2No', GetLastErrorText());
            asserterror Error('%1', Line.A5);
            Observer.Observe(Format(LineNo) + '-errA5', GetLastErrorText());
            ClearLastError();
            Message('%1', Line.A1);
            Observer.Observe(Format(LineNo) + '-msgA1', LastMessage);
            Message('x=%1', Line.A2);
            Observer.Observe(Format(LineNo) + '-msgA2', LastMessage);
            Message('%1', Line.A2No);
            Observer.Observe(Format(LineNo) + '-msgA2No', LastMessage);
            Message('%1', Line.A4);
            Observer.Observe(Format(LineNo) + '-msgA4', LastMessage);
        end;
        RestoreSetup();
        Observer.Finish();
    end;

    [MessageHandler]
    procedure SaMessageHandler(Msg: Text[1024])
    begin
        LastMessage := Msg;
    end;
}
