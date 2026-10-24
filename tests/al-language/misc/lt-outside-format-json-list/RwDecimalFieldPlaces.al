// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-strsubstno-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own fixtures declared in this file (LT RW)
// Probe (al-runner issue 5791): StrSubstNo('%1', Rec.Field), Message('%1', Rec.Field) and Error('%1', Rec.Field) of a Decimal field with
// AutoFormatType (0, 1, 2, 10) or DecimalPlaces, next to Format(Rec.Field) of the same field; and whether the field's places survive a Decimal
// variable, a Decimal parameter, a Variant, an expression, a FieldRef and FieldRef.Value. Object ids 88780, 88790.
// BC versions: 27, 28, 29 (CI matrix)

table 88780 "LT RW Amount Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amt1; Decimal) { AutoFormatType = 1; AutoFormatExpression = ''; }
        field(3; Amt1NoExpr; Decimal) { AutoFormatType = 1; }
        field(4; Amt0; Decimal) { AutoFormatType = 0; }
        field(5; Amt2; Decimal) { AutoFormatType = 2; AutoFormatExpression = ''; }
        field(6; Amt10; Decimal) { AutoFormatType = 10; AutoFormatExpression = '<Precision,3:3><Standard Format,0>'; }
        field(7; Plain; Decimal) { }
        field(8; Dp22; Decimal) { DecimalPlaces = 2 : 2; }
        field(9; Dp05; Decimal) { DecimalPlaces = 0 : 5; }
        field(10; Dp33Amt1; Decimal) { DecimalPlaces = 3 : 3; AutoFormatType = 1; AutoFormatExpression = ''; }
        field(11; Dp00; Decimal) { DecimalPlaces = 0 : 0; }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 88790 "LT RW Decimal Field Places"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LastMessage: Text;

    local procedure Fill(var Row: Record "LT RW Amount Row"; Value: Decimal)
    begin
        Row.Amt1 := Value;
        Row.Amt1NoExpr := Value;
        Row.Amt0 := Value;
        Row.Amt2 := Value;
        Row.Amt10 := Value;
        Row.Plain := Value;
        Row.Dp22 := Value;
        Row.Dp05 := Value;
        Row.Dp33Amt1 := Value;
        Row.Dp00 := Value;
    end;

    local procedure ObserveAll(var Observer: Codeunit "Probe Observer"; Tag: Text; var Row: Record "LT RW Amount Row")
    begin
        Observer.Observe(Tag + '-fmt-Amt1', Format(Row.Amt1));
        Observer.Observe(Tag + '-sub-Amt1', StrSubstNo('%1', Row.Amt1));
        Observer.Observe(Tag + '-fmt-Amt1NoExpr', Format(Row.Amt1NoExpr));
        Observer.Observe(Tag + '-sub-Amt1NoExpr', StrSubstNo('%1', Row.Amt1NoExpr));
        Observer.Observe(Tag + '-fmt-Amt0', Format(Row.Amt0));
        Observer.Observe(Tag + '-sub-Amt0', StrSubstNo('%1', Row.Amt0));
        Observer.Observe(Tag + '-fmt-Amt2', Format(Row.Amt2));
        Observer.Observe(Tag + '-sub-Amt2', StrSubstNo('%1', Row.Amt2));
        Observer.Observe(Tag + '-fmt-Amt10', Format(Row.Amt10));
        Observer.Observe(Tag + '-sub-Amt10', StrSubstNo('%1', Row.Amt10));
        Observer.Observe(Tag + '-fmt-Plain', Format(Row.Plain));
        Observer.Observe(Tag + '-sub-Plain', StrSubstNo('%1', Row.Plain));
        Observer.Observe(Tag + '-fmt-Dp22', Format(Row.Dp22));
        Observer.Observe(Tag + '-sub-Dp22', StrSubstNo('%1', Row.Dp22));
        Observer.Observe(Tag + '-fmt-Dp05', Format(Row.Dp05));
        Observer.Observe(Tag + '-sub-Dp05', StrSubstNo('%1', Row.Dp05));
        Observer.Observe(Tag + '-fmt-Dp33Amt1', Format(Row.Dp33Amt1));
        Observer.Observe(Tag + '-sub-Dp33Amt1', StrSubstNo('%1', Row.Dp33Amt1));
        Observer.Observe(Tag + '-fmt-Dp00', Format(Row.Dp00));
        Observer.Observe(Tag + '-sub-Dp00', StrSubstNo('%1', Row.Dp00));
    end;

    // The reporter's shape: a temporary record, values 70 and 0; plus 1234.5 (thousands separator) and 3.14159 (more places than declared).
    [Test]
    procedure RW_StrSubstNo_DecimalField_TempRecord()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "LT RW Amount Row" temporary;
    begin
        TempRow.Code := 'A';
        Fill(TempRow, 70);
        ObserveAll(Observer, '70', TempRow);
        Fill(TempRow, 0);
        ObserveAll(Observer, '0', TempRow);
        Fill(TempRow, 1234.5);
        ObserveAll(Observer, '1234.5', TempRow);
        Fill(TempRow, 3.14159);
        ObserveAll(Observer, '3.14159', TempRow);
        Observer.Finish();
    end;

    [Test]
    procedure RW_StrSubstNo_DecimalField_TempRecord_More1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    [Test]
    procedure RW_StrSubstNo_DecimalField_TempRecord_More2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.More();
    end;

    // A database record read back with Get, two placeholders in one string, and a placeholder between other text.
    [Test]
    procedure RW_StrSubstNo_DecimalField_DatabaseRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RW Amount Row";
    begin
        Row.DeleteAll();
        Row.Code := 'B';
        Fill(Row, -12.5);
        Row.Insert();
        Clear(Row);
        Row.Get('B');
        Observer.Observe('db-sub-Amt1', StrSubstNo('%1', Row.Amt1));
        Observer.Observe('db-sub-Dp22', StrSubstNo('%1', Row.Dp22));
        Observer.Observe('db-sub-Plain', StrSubstNo('%1', Row.Plain));
        Observer.Observe('db-sub-two', StrSubstNo('%1|%2', Row.Amt1, Row.Plain));
        Observer.Observe('db-sub-text', StrSubstNo('CostActual=%1;', Row.Amt1));
        Observer.Observe('db-sub-twice', StrSubstNo('%1 %1', Row.Amt1));
        Observer.Finish();
    end;

    // Does the field's format reach StrSubstNo through other carriers of the same value?
    [Test]
    procedure RW_StrSubstNo_DecimalField_Carriers()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "LT RW Amount Row" temporary;
        RecRef: RecordRef;
        Fr: FieldRef;
        D: Decimal;
        V: Variant;
    begin
        TempRow.Code := 'C';
        Fill(TempRow, 70);
        TempRow.Insert();
        D := TempRow.Amt1;
        Observer.Observe('decimal-var', StrSubstNo('%1', D));
        Observer.Observe('decimal-param', SubstDecimal(TempRow.Amt1));
        V := TempRow.Amt1;
        Observer.Observe('variant-sub', StrSubstNo('%1', V));
        Observer.Observe('variant-fmt', Format(V));
        Observer.Observe('variant-param', SubstVariant(TempRow.Amt1));
        Observer.Observe('expr-plus0', StrSubstNo('%1', TempRow.Amt1 + 0));
        Observer.Observe('expr-paren', StrSubstNo('%1', (TempRow.Amt1)));
        Observer.Observe('fmt-in-sub', StrSubstNo('%1', Format(TempRow.Amt1)));
        RecRef.GetTable(TempRow);
        Fr := RecRef.Field(TempRow.FieldNo(Amt1));
        Observer.Observe('fieldref-sub', StrSubstNo('%1', Fr));
        Observer.Observe('fieldref-fmt', Format(Fr));
        Observer.Observe('fieldref-value-sub', StrSubstNo('%1', Fr.Value));
        Observer.Observe('fieldref-value-fmt', Format(Fr.Value));
        Fr := RecRef.Field(TempRow.FieldNo(Dp22));
        Observer.Observe('fieldref-dp22-sub', StrSubstNo('%1', Fr));
        Observer.Observe('fieldref-dp22-value-sub', StrSubstNo('%1', Fr.Value));
        Observer.Finish();
    end;

    // Error and Message take the same placeholders as StrSubstNo.
    [Test]
    [HandlerFunctions('RwMessageHandler')]
    procedure RW_MessageError_DecimalField()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "LT RW Amount Row" temporary;
    begin
        TempRow.Code := 'D';
        Fill(TempRow, 70);
        asserterror Error('%1', TempRow.Amt1);
        Observer.Observe('error-Amt1', GetLastErrorText());
        asserterror Error('%1', TempRow.Dp22);
        Observer.Observe('error-Dp22', GetLastErrorText());
        asserterror Error('%1', TempRow.Plain);
        Observer.Observe('error-Plain', GetLastErrorText());
        asserterror Error('x=%1', TempRow.Amt2);
        Observer.Observe('error-Amt2', GetLastErrorText());
        ClearLastError();
        Message('%1', TempRow.Amt1);
        Observer.Observe('message-Amt1', LastMessage);
        Message('%1', TempRow.Dp22);
        Observer.Observe('message-Dp22', LastMessage);
        Message('%1', TempRow.Plain);
        Observer.Observe('message-Plain', LastMessage);
        Message('x=%1', TempRow.Amt2);
        Observer.Observe('message-Amt2', LastMessage);
        Observer.Finish();
    end;

    local procedure SubstDecimal(D: Decimal): Text
    begin
        exit(StrSubstNo('%1', D));
    end;

    local procedure SubstVariant(V: Variant): Text
    begin
        exit(StrSubstNo('%1', V));
    end;

    [MessageHandler]
    procedure RwMessageHandler(Msg: Text[1024])
    begin
        LastMessage := Msg;
    end;
}
