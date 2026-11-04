// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); SingleInstance log 74570 declared above its single user
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (own file): a field bound to an element of an array of records may not compile on a page.
// BC versions: 29 (27 and 28 by CI)

table 74566 "LT P167 Totals Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74570 "LT P167 Totals Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Clear()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Content(): Text
    begin
        exit(Entries);
    end;
}

page 74567 "LT P167 Totals Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(AmountCtl; Totals[1].Amount)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "LT P167 Totals Log";
                begin
                    Log.Add('validate:' + Format(Totals[1].Amount) + ':second=' + Format(Totals[2].Amount));
                end;
            }
            field(SecondCtl; Totals[2].Amount)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        Totals: array[2] of Record "LT P167 Totals Row" temporary;
}

codeunit 74568 "LT P167 Page Array SetValue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetText(var P: TestPage "LT P167 Totals Page"; Value: Text)
    begin
        P.AmountCtl.SetValue(Value);
    end;

    [Test]
    procedure ArrayElementField_SetValueNumber_RunsOnValidate()
    var
        P: TestPage "LT P167 Totals Page";
        Log: Codeunit "LT P167 Totals Log";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Clear();
        P.OpenEdit();
        Observer.Observe('initial', P.AmountCtl.Value());
        P.AmountCtl.SetValue(5);
        Observer.Observe('log', Log.Content());
        Observer.Observe('control_after', P.AmountCtl.Value());
        Observer.Observe('second_after', P.SecondCtl.Value());
        P.Close();
        Observer.Expect('initial', '0.00');
        Observer.Expect('log', 'validate:5:second=0;');
        Observer.Expect('control_after', '5.00');
        Observer.Expect('second_after', '0.00');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayElementField_SetValueText_ConvertsToDecimal()
    var
        P: TestPage "LT P167 Totals Page";
        Log: Codeunit "LT P167 Totals Log";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Clear();
        P.OpenEdit();
        P.AmountCtl.SetValue('12.5');
        Observer.Observe('log', Log.Content());
        Observer.Observe('control_after', P.AmountCtl.Value());
        P.Close();
        Observer.Expect('log', 'validate:12.5:second=0;');
        Observer.Expect('control_after', '12.50');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayElementField_SetValueUnconvertible_IsRefused()
    var
        P: TestPage "LT P167 Totals Page";
        Log: Codeunit "LT P167 Totals Log";
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Log.Clear();
        P.OpenEdit();
        Ok := TrySetText(P, 'x');
        Observer.Observe('ok', Format(Ok));
        if not Ok then
            Observer.Observe('error_start', CopyStr(GetLastErrorText(), 1, 150));
        Observer.Observe('log', Log.Content());
        Observer.Observe('control_after', P.AmountCtl.Value());
        P.Close();
        Observer.Expect('ok', 'No');
        Observer.Expect('error_start', 'Validation error for Field: AmountCtl,  Message = ''Your entry of ''x'' is not an acceptable value for ''AmountCtl''. ''x'' is not a part of a valid decimal ');
        Observer.Expect('log', '');
        Observer.Expect('control_after', '0.00');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayElementField_SecondElement_SetValue()
    var
        P: TestPage "LT P167 Totals Page";
        Log: Codeunit "LT P167 Totals Log";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Clear();
        P.OpenEdit();
        P.SecondCtl.SetValue(7);
        Observer.Observe('log', Log.Content());
        Observer.Observe('second_after', P.SecondCtl.Value());
        Observer.Observe('first_after', P.AmountCtl.Value());
        P.Close();
        Observer.Expect('log', '');
        Observer.Expect('second_after', '7.00');
        Observer.Expect('first_after', '0.00');
        Observer.Verify();
    end;
}
