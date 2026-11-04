// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); local table 95180, pages 95181 and 95182
// Probe: written against BC 29.0.54011.55816 on the corpus CI (al-runner issue 6918); every literal asserted below is what BC produced.
// Facts: TestPage field SetValue on controls of a card with no source table that are bound to the fields of a global record
// (and of a global temporary record): Code, Text, Integer, Decimal, Boolean, Date, Option, BigInteger and Time fields, with a text
// and with a typed value; the value the control reads back; the value the page's record holds after OK in a ModalPageHandler;
// the errors of a text that does not fit the field; a field with a table OnValidate trigger.
// BC versions: 27.5, 28.5, 29.0 (corpus CI)

table 95180 "TP NSRec Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Railcar; Code[20]) { }
        field(2; Txt; Text[30]) { }
        field(3; Int; Integer) { }
        field(4; Dec; Decimal) { }
        field(5; Flag; Boolean) { }
        field(6; Dt; Date) { }
        field(7; Opt; Option)
        {
            OptionMembers = " ",Alpha,Beta;
            OptionCaption = ' ,Alpha cap,Beta cap';
        }
        field(8; Big; BigInteger) { }
        field(9; Tm; Time) { }
        field(10; Val; Code[10])
        {
            trigger OnValidate()
            begin
                Note := 'validated ' + Val;
            end;
        }
        field(11; Note; Text[50]) { }
    }

    keys
    {
        key(PK; Railcar) { Clustered = true; }
    }
}

page 95181 "TP NSRec Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(ctlRailcar; RowRec.Railcar) { ApplicationArea = All; Caption = 'Railcar'; }
            field(ctlTxt; RowRec.Txt) { ApplicationArea = All; }
            field(ctlInt; RowRec.Int) { ApplicationArea = All; }
            field(ctlDec; RowRec.Dec) { ApplicationArea = All; }
            field(ctlFlag; RowRec.Flag) { ApplicationArea = All; }
            field(ctlDt; RowRec.Dt) { ApplicationArea = All; }
            field(ctlOpt; RowRec.Opt) { ApplicationArea = All; }
            field(ctlBig; RowRec.Big) { ApplicationArea = All; }
            field(ctlTm; RowRec.Tm) { ApplicationArea = All; }
            field(ctlVal; RowRec.Val) { ApplicationArea = All; }
            field(ctlNote; RowRec.Note) { ApplicationArea = All; }
        }
    }

    var
        RowRec: Record "TP NSRec Row";

    procedure GetRow(var Row: Record "TP NSRec Row")
    begin
        Row := RowRec;
    end;
}

page 95182 "TP NSRec Temp Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(ctlRailcar; TempRowRec.Railcar) { ApplicationArea = All; }
            field(ctlInt; TempRowRec.Int) { ApplicationArea = All; }
            field(ctlFlag; TempRowRec.Flag) { ApplicationArea = All; }
        }
    }

    var
        TempRowRec: Record "TP NSRec Row" temporary;

    procedure GetRow(var Row: Record "TP NSRec Row")
    begin
        Row := TempRowRec;
    end;
}

codeunit 95183 "TP NoSource GlobalRec SetValue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerMode: Integer;

    [ModalPageHandler]
    procedure ConfirmCardHandler(var Card: TestPage "TP NSRec Card")
    begin
        case HandlerMode of
            1:
                Card.ctlRailcar.SetValue('rc-001');
            2:
                begin
                    Card.ctlRailcar.SetValue('RC-002');
                    Card.ctlTxt.SetValue('Hello');
                    Card.ctlInt.SetValue('42');
                    Card.ctlDec.SetValue('12.5');
                    Card.ctlFlag.SetValue('Yes');
                    Card.ctlDt.SetValue(DMY2Date(15, 3, 2026));
                    Card.ctlOpt.SetValue('Beta');
                    Card.ctlBig.SetValue('1234567890123');
                    Card.ctlTm.SetValue(103000T);
                    Card.ctlVal.SetValue('v1');
                end;
        end;
        Card.OK().Invoke();
    end;

    local procedure RowText(Row: Record "TP NSRec Row"): Text
    begin
        exit(Row.Railcar + '|' + Row.Txt + '|' + Format(Row.Int) + '|' + Format(Row.Dec) + '|' + Format(Row.Flag) + '|' +
            Format(Row.Dt, 0, 9) + '|' + Format(Row.Opt, 0, 9) + '|' + Format(Row.Big) + '|' + Format(Row.Tm, 0, 9) + '|' + Row.Val + '|' + Row.Note);
    end;

    [Test]
    [HandlerFunctions('ConfirmCardHandler')]
    procedure SetValue_CodeControl_RunModalOK_PageKeepsValue()
    var
        Observer: Codeunit "Probe Observer";
        Card: Page "TP NSRec Card";
        Row: Record "TP NSRec Row";
    begin
        HandlerMode := 1;
        Card.RunModal();
        Card.GetRow(Row);
        Observer.Observe('railcar', Row.Railcar);
        Observer.Observe('row', RowText(Row));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ConfirmCardHandler')]
    procedure SetValue_EveryKind_RunModalOK_PageKeepsValues()
    var
        Observer: Codeunit "Probe Observer";
        Card: Page "TP NSRec Card";
        Row: Record "TP NSRec Row";
    begin
        HandlerMode := 2;
        Card.RunModal();
        Card.GetRow(Row);
        Observer.Observe('row', RowText(Row));
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_EveryKind_TextArgs_ValueReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "TP NSRec Card";
    begin
        Card.OpenEdit();
        Observer.Observe('initial', Card.ctlRailcar.Value() + '|' + Card.ctlInt.Value() + '|' + Card.ctlDec.Value() + '|' + Card.ctlFlag.Value() + '|' + Card.ctlDt.Value() + '|' + Card.ctlOpt.Value() + '|' + Card.ctlBig.Value() + '|' + Card.ctlTm.Value());
        Card.ctlRailcar.SetValue('rc-003');
        Observer.Observe('railcar', Card.ctlRailcar.Value());
        Card.ctlTxt.SetValue('Some text');
        Observer.Observe('txt', Card.ctlTxt.Value());
        Card.ctlInt.SetValue('42');
        Observer.Observe('int', Card.ctlInt.Value());
        Card.ctlDec.SetValue('1234.5');
        Observer.Observe('dec', Card.ctlDec.Value());
        Card.ctlFlag.SetValue('Yes');
        Observer.Observe('flag', Card.ctlFlag.Value());
        Card.ctlDt.SetValue('03/15/2026');
        Observer.Observe('dt', Card.ctlDt.Value());
        Card.ctlOpt.SetValue('Alpha');
        Observer.Observe('opt', Card.ctlOpt.Value());
        Card.ctlBig.SetValue('1234567890123');
        Observer.Observe('big', Card.ctlBig.Value());
        Card.ctlTm.SetValue('10:30:00');
        Observer.Observe('tm', Card.ctlTm.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_EveryKind_TypedArgs_ValueReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "TP NSRec Card";
    begin
        Card.OpenEdit();
        Card.ctlRailcar.SetValue(123);
        Observer.Observe('railcar integer', Card.ctlRailcar.Value());
        Card.ctlTxt.SetValue(7.25);
        Observer.Observe('txt decimal', Card.ctlTxt.Value());
        Card.ctlInt.SetValue(42);
        Observer.Observe('int', Card.ctlInt.Value());
        Card.ctlDec.SetValue(12.5);
        Observer.Observe('dec', Card.ctlDec.Value());
        Card.ctlFlag.SetValue(true);
        Observer.Observe('flag', Card.ctlFlag.Value());
        Card.ctlDt.SetValue(DMY2Date(15, 3, 2026));
        Observer.Observe('dt', Card.ctlDt.Value());
        Card.ctlOpt.SetValue(2);
        Observer.Observe('opt', Card.ctlOpt.Value());
        Card.ctlBig.SetValue(1234567890123L);
        Observer.Observe('big', Card.ctlBig.Value());
        Card.ctlTm.SetValue(103000T);
        Observer.Observe('tm', Card.ctlTm.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_TextThatDoesNotFit_Errors()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "TP NSRec Card";
    begin
        Card.OpenEdit();
        Card.ctlInt.SetValue('5');
        asserterror begin
            Card.ctlInt.SetValue('abc');
            Error('no error');
        end;
        Observer.ObserveError('int abc');
        Observer.Observe('int after', Card.ctlInt.Value());
        asserterror begin
            Card.ctlFlag.SetValue('maybe');
            Error('no error');
        end;
        Observer.ObserveError('flag maybe');
        asserterror begin
            Card.ctlDt.SetValue('notadate');
            Error('no error');
        end;
        Observer.ObserveError('dt notadate');
        asserterror begin
            Card.ctlRailcar.SetValue('ABCDEFGHIJKLMNOPQRSTU');
            Error('no error');
        end;
        Observer.ObserveError('railcar 21 chars');
        Observer.Observe('railcar after', Card.ctlRailcar.Value());
        asserterror begin
            Card.ctlTxt.SetValue('1234567890123456789012345678901');
            Error('no error');
        end;
        Observer.ObserveError('txt 31 chars');
        asserterror begin
            Card.ctlOpt.SetValue('Gamma');
            Error('no error');
        end;
        Observer.ObserveError('opt gamma');
        asserterror begin
            Card.ctlOpt.SetValue('Alpha cap');
            Error('no error');
        end;
        Observer.ObserveError('opt caption');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_FieldWithTableOnValidate()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "TP NSRec Card";
    begin
        Card.OpenEdit();
        Card.ctlVal.SetValue('v1');
        Observer.Observe('val', Card.ctlVal.Value());
        Observer.Observe('note', Card.ctlNote.Value());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure SetValue_GlobalTemporaryRecord_ValueReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "TP NSRec Temp Card";
    begin
        Card.OpenEdit();
        Card.ctlRailcar.SetValue('tmp-1');
        Observer.Observe('railcar', Card.ctlRailcar.Value());
        Card.ctlInt.SetValue('-8');
        Observer.Observe('int', Card.ctlInt.Value());
        Card.ctlFlag.SetValue(true);
        Observer.Observe('flag', Card.ctlFlag.Value());
        Card.Close();
        Observer.Finish();
    end;
}
