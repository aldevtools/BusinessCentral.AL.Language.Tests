// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-calcsum-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FieldRef.CalcSum on a Decimal and an Integer field that is a SumIndexField, with no filter, a filter on another field, a filter on the summed field itself,
//   a filter that excludes every row, on an empty table, called twice, on a decimal field that is in no SumIndexFields list, and on a Text field (error text and code).
// BC versions: 29 (27 and 28 by CI)

table 71950 "LT FCS Row"
{
    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Grp; Code[10]) { }
        field(3; Amount; Decimal) { }
        field(4; Qty; Integer) { }
        field(5; Plain; Decimal) { }
        field(6; Name; Text[30]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(GrpKey; Grp) { SumIndexFields = Amount, Qty; }
    }
}

codeunit 71951 "LT FCS CalcSum"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT FCS Row";
    begin
        R.DeleteAll();
        Add('A', 'G1', 10.5, 1, 1.25);
        Add('B', 'G1', 20, 2, 2.5);
        Add('C', 'G2', 100.25, 4, 5);
        Add('D', 'G2', -5, 8, 10);
    end;

    local procedure Add(NewCode: Code[10]; NewGrp: Code[10]; NewAmount: Decimal; NewQty: Integer; NewPlain: Decimal)
    var
        R: Record "LT FCS Row";
    begin
        R.Code := NewCode;
        R.Grp := NewGrp;
        R.Amount := NewAmount;
        R.Qty := NewQty;
        R.Plain := NewPlain;
        R.Name := 'n' + NewCode;
        R.Insert();
    end;

    [Test]
    procedure P184_FieldRefCalcSum_Decimal_NoFilter_And_GroupFilter()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Seed();
        RecRef.Open(71950);
        Fld := RecRef.Field(3);
        Observer.Observe('value before', Format(Fld.Value));
        Observer.Observe('ret nofilter', Format(Fld.CalcSum()));
        Observer.Observe('sum nofilter', Format(Fld.Value));
        RecRef.Field(2).SetRange('G1');
        Fld.CalcSum();
        Observer.Observe('sum g1', Format(Fld.Value));
        RecRef.Field(2).SetRange('G2');
        Fld.CalcSum();
        Observer.Observe('sum g2', Format(Fld.Value));
        RecRef.Field(2).SetFilter('G1|G2');
        Fld.CalcSum();
        Observer.Observe('sum g1 or g2', Format(Fld.Value));
        RecRef.Field(2).SetRange('NONE');
        Fld.CalcSum();
        Observer.Observe('sum none', Format(Fld.Value));
        RecRef.Reset();
        Fld.CalcSum();
        Observer.Observe('sum after reset', Format(Fld.Value));
        Observer.Expect('value before', '0');
        Observer.Expect('ret nofilter', 'Yes');
        Observer.Expect('sum nofilter', '125.75');
        Observer.Expect('sum g1', '30.5');
        Observer.Expect('sum g2', '95.25');
        Observer.Expect('sum g1 or g2', '125.75');
        Observer.Expect('sum none', '0');
        Observer.Expect('sum after reset', '125.75');
        Observer.Verify();
    end;

    [Test]
    procedure P184_FieldRefCalcSum_Decimal_FilterOnSummedField()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Seed();
        RecRef.Open(71950);
        Fld := RecRef.Field(3);
        Fld.SetFilter('>0');
        Fld.CalcSum();
        Observer.Observe('sum positive', Format(Fld.Value));
        Observer.Observe('filter still set', Fld.GetFilter());
        Fld.SetRange(20, 100.25);
        Fld.CalcSum();
        Observer.Observe('sum range', Format(Fld.Value));
        Fld.SetRange(-5);
        Fld.CalcSum();
        Observer.Observe('sum single negative', Format(Fld.Value));
        Fld.SetRange(1000);
        Fld.CalcSum();
        Observer.Observe('sum no row', Format(Fld.Value));
        RecRef.Field(1).SetRange('B');
        Fld.SetRange(20);
        Fld.CalcSum();
        Observer.Observe('sum key B and amount', Format(Fld.Value));
        Observer.Expect('sum positive', '130.75');
        Observer.Expect('filter still set', '>0');
        Observer.Expect('sum range', '120.25');
        Observer.Expect('sum single negative', '-5');
        Observer.Expect('sum no row', '0');
        Observer.Expect('sum key B and amount', '20');
        Observer.Verify();
    end;

    [Test]
    procedure P184_FieldRefCalcSum_Integer_And_TwiceAndEmpty()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Seed();
        RecRef.Open(71950);
        Fld := RecRef.Field(4);
        Fld.CalcSum();
        Observer.Observe('qty sum', Format(Fld.Value));
        Fld.CalcSum();
        Observer.Observe('qty sum twice', Format(Fld.Value));
        RecRef.Field(2).SetRange('G2');
        Fld.CalcSum();
        Observer.Observe('qty g2', Format(Fld.Value));
        RecRef.DeleteAll();
        RecRef.Reset();
        Fld.CalcSum();
        Observer.Observe('qty empty', Format(Fld.Value));
        Fld := RecRef.Field(3);
        Fld.CalcSum();
        Observer.Observe('amount empty', Format(Fld.Value));
        Observer.Expect('qty sum', '15');
        Observer.Expect('qty sum twice', '15');
        Observer.Expect('qty g2', '12');
        Observer.Expect('qty empty', '3');
        Observer.Expect('amount empty', '30.5');
        Observer.Verify();
    end;

    [Test]
    procedure P184_FieldRefCalcSum_DecimalNotInSumIndex()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Seed();
        RecRef.Open(71950);
        Fld := RecRef.Field(5);
        Fld.CalcSum();
        Observer.Observe('plain sum', Format(Fld.Value));
        RecRef.Field(2).SetRange('G1');
        Fld.CalcSum();
        Observer.Observe('plain sum g1', Format(Fld.Value));
        Observer.Observe('plain value of current row', Format(Fld.Value));
        RecRef.Reset();
        RecRef.FindFirst();
        Observer.Observe('plain first row', Format(Fld.Value));
        Fld.CalcSum();
        Observer.Observe('plain sum after find', Format(Fld.Value));
        Observer.Expect('plain sum', '18.75');
        Observer.Expect('plain sum g1', '3.75');
        Observer.Expect('plain value of current row', '3.75');
        Observer.Expect('plain first row', '1.25');
        Observer.Expect('plain sum after find', '18.75');
        Observer.Verify();
    end;

    [Test]
    procedure P184_FieldRefCalcSum_TextField_Errors()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Seed();
        RecRef.Open(71950);
        Fld := RecRef.Field(6);
        asserterror Fld.CalcSum();
        Observer.ObserveError('text field');
        Fld := RecRef.Field(1);
        asserterror Fld.CalcSum();
        Observer.ObserveError('code field');
        Observer.Expect('text field|text', 'Cannot calculate a sum of the values in the Name field in the LT FCS Row table because one or more values are not normal numeric fields.');
        Observer.Expect('text field|code', 'DB:Ok');
        Observer.Expect('code field|text', 'Cannot calculate a sum of the values in the Code field in the LT FCS Row table because one or more values are not normal numeric fields.');
        Observer.Expect('code field|code', 'DB:Ok');
        Observer.Verify();
    end;
}
