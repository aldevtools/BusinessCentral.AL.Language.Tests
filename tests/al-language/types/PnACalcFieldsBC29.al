// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 70107/70108
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: CalcFields (BC 29): the refusal of a min or max FlowField over SystemRowVersion (full text) and BigInteger source into an Integer FlowField / average of Integer into BigInteger
// Facts: full GetLastErrorText and code of CalcFields over SystemRowVersion; values and errors of FlowFields whose type differs from the source type (BigInteger and Integer)
// BC versions: 29 (27 and 28 by CI)

table 70107 "LT PnA CF Line"
{
    fields
    {
        field(1; Entry; Integer) { }
        field(2; Doc; Code[10]) { }
        field(3; Qty; Integer) { }
        field(4; Big; BigInteger) { }
        field(5; Amt; Decimal) { }
    }
    keys
    {
        key(PK; Entry) { Clustered = true; }
    }
}

table 70108 "LT PnA CF Hdr"
{
    fields
    {
        field(1; "No."; Code[10]) { }
        field(10; LastRV; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = max("LT PnA CF Line".SystemRowVersion where(Doc = field("No.")));
        }
        field(11; FirstRV; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = min("LT PnA CF Line".SystemRowVersion where(Doc = field("No.")));
        }
        field(12; BigToInt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT PnA CF Line".Big where(Doc = field("No.")));
        }
        field(13; AvgQtyToBig; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = average("LT PnA CF Line".Qty where(Doc = field("No.")));
        }
        field(14; SumQtyToBig; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT PnA CF Line".Qty where(Doc = field("No.")));
        }
        field(15; SumBig; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT PnA CF Line".Big where(Doc = field("No.")));
        }
        field(16; AvgBig; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = average("LT PnA CF Line".Big where(Doc = field("No.")));
        }
        field(17; SumQty; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT PnA CF Line".Qty where(Doc = field("No.")));
        }
        field(18; MaxBig; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = max("LT PnA CF Line".Big where(Doc = field("No.")));
        }
        field(19; LookupRV; BigInteger)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT PnA CF Line".SystemRowVersion where(Entry = const(1)));
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

#if BC29PLUS
codeunit 70109 "LT PnA CF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Hdr: Record "LT PnA CF Hdr";
        Res: Text;

    local procedure Seed()
    var
        L: Record "LT PnA CF Line";
        H: Record "LT PnA CF Hdr";
    begin
        L.DeleteAll();
        H.DeleteAll();
        AddLine(1, 'D1', 2, 10);
        AddLine(2, 'D1', 3, 20);
        AddLine(3, 'D1', 4, 31);
        AddLine(4, 'D2', 1, 5000000000L);
        AddLine(5, 'D3', 5, 7);
        H."No." := 'D1';
        H.Insert();
        H."No." := 'D2';
        H.Insert();
        H."No." := 'D3';
        H.Insert();
        H."No." := 'D0';
        H.Insert();
    end;

    local procedure AddLine(EntryNo: Integer; DocNo: Code[10]; Q: Integer; B: BigInteger)
    var
        L: Record "LT PnA CF Line";
    begin
        L.Entry := EntryNo;
        L.Doc := DocNo;
        L.Qty := Q;
        L.Big := B;
        L.Insert();
    end;

    [TryFunction]
    local procedure TryCalc(DocNo: Code[10]; Op: Integer)
    begin
        Res := '';
        Hdr.Get(DocNo);
        case Op of
            1:
                begin
                    Hdr.CalcFields(LastRV);
                    Res := Format(Hdr.LastRV <> 0);
                end;
            2:
                begin
                    Hdr.CalcFields(FirstRV);
                    Res := Format(Hdr.FirstRV <> 0);
                end;
            3:
                begin
                    Hdr.CalcFields(BigToInt);
                    Res := Format(Hdr.BigToInt);
                end;
            4:
                begin
                    Hdr.CalcFields(AvgQtyToBig);
                    Res := Format(Hdr.AvgQtyToBig);
                end;
            5:
                begin
                    Hdr.CalcFields(SumQtyToBig);
                    Res := Format(Hdr.SumQtyToBig);
                end;
            6:
                begin
                    Hdr.CalcFields(SumBig);
                    Res := Format(Hdr.SumBig);
                end;
            7:
                begin
                    Hdr.CalcFields(AvgBig);
                    Res := Format(Hdr.AvgBig);
                end;
            8:
                begin
                    Hdr.CalcFields(SumQty);
                    Res := Format(Hdr.SumQty);
                end;
            9:
                begin
                    Hdr.CalcFields(MaxBig);
                    Res := Format(Hdr.MaxBig);
                end;
            10:
                begin
                    Hdr.CalcFields(LookupRV);
                    Res := Format(Hdr.LookupRV <> 0);
                end;
            11:
                begin
                    Hdr.CalcFields(LastRV, FirstRV);
                    Res := Format(Hdr.LastRV <> 0);
                end;
            12:
                begin
                    Hdr.CalcFields(SumQty, LastRV);
                    Res := Format(Hdr.SumQty);
                end;
            13:
                begin
                    Hdr.CalcFields(LastRV, SumQty);
                    Res := Format(Hdr.SumQty);
                end;
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; DocNo: Code[10]; Op: Integer)
    begin
        Observer.Observe(Name, Format(TryCalc(DocNo, Op)) + '|' + Res);
        Observer.ObserveError(Name);
    end;

#if BC28PLUS
    [Test]
    procedure SystemRowVersion_Aggregates_FullText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'max-D1', 'D1', 1);
        Probe(Observer, 'min-D1', 'D1', 2);
        Probe(Observer, 'max-empty-D0', 'D0', 1);
        Probe(Observer, 'lookup-D1', 'D1', 10);
        Probe(Observer, 'max-then-min-D1', 'D1', 11);
        Probe(Observer, 'sumqty-then-max-D1', 'D1', 12);
        Probe(Observer, 'max-then-sumqty-D1', 'D1', 13);
        Observer.Expect('max-D1', 'No|');
        Observer.Expect('max-D1|text', 'Table content in the LT PnA CF Hdr table on SQL Server contains a value that is not compatible with the corresponding data type that is defined for the table.\\Field: LastRV\Type: BigInteger\SQL type: timestamp\\The table design may have been changed outside Business Central.');
        Observer.Expect('max-D1|code', 'NDBCS:IncompatibleSqlType');
        Observer.Expect('min-D1', 'No|');
        Observer.Expect('min-D1|text', 'Table content in the LT PnA CF Hdr table on SQL Server contains a value that is not compatible with the corresponding data type that is defined for the table.\\Field: FirstRV\Type: BigInteger\SQL type: timestamp\\The table design may have been changed outside Business Central.');
        Observer.Expect('min-D1|code', 'NDBCS:IncompatibleSqlType');
        Observer.Expect('max-empty-D0', 'No|');
        Observer.Expect('max-empty-D0|text', 'Table content in the LT PnA CF Hdr table on SQL Server contains a value that is not compatible with the corresponding data type that is defined for the table.\\Field: LastRV\Type: BigInteger\SQL type: timestamp\\The table design may have been changed outside Business Central.');
        Observer.Expect('max-empty-D0|code', 'NDBCS:IncompatibleSqlType');
        Observer.Expect('lookup-D1', 'Yes|Yes');
        Observer.Expect('lookup-D1|text', '');
        Observer.Expect('lookup-D1|code', '');
        Observer.Expect('max-then-min-D1', 'No|');
        Observer.Expect('max-then-min-D1|text', 'Table content in the LT PnA CF Hdr table on SQL Server contains a value that is not compatible with the corresponding data type that is defined for the table.\\Field: LastRV\Type: BigInteger\SQL type: timestamp\\The table design may have been changed outside Business Central.');
        Observer.Expect('max-then-min-D1|code', 'NDBCS:IncompatibleSqlType');
        Observer.Expect('sumqty-then-max-D1', 'No|');
        Observer.Expect('sumqty-then-max-D1|text', 'Table content in the LT PnA CF Hdr table on SQL Server contains a value that is not compatible with the corresponding data type that is defined for the table.\\Field: LastRV\Type: BigInteger\SQL type: timestamp\\The table design may have been changed outside Business Central.');
        Observer.Expect('sumqty-then-max-D1|code', 'NDBCS:IncompatibleSqlType');
        Observer.Expect('max-then-sumqty-D1', 'No|');
        Observer.Expect('max-then-sumqty-D1|text', 'Table content in the LT PnA CF Hdr table on SQL Server contains a value that is not compatible with the corresponding data type that is defined for the table.\\Field: LastRV\Type: BigInteger\SQL type: timestamp\\The table design may have been changed outside Business Central.');
        Observer.Expect('max-then-sumqty-D1|code', 'NDBCS:IncompatibleSqlType');
        Observer.Verify();
    end;
#endif





#if BC28PLUS
    [Test]
    procedure TypeMismatch_BigIntegerAndInteger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'big-to-int-D1', 'D1', 3);
        Probe(Observer, 'big-to-int-D2-above-int-range', 'D2', 3);
        Probe(Observer, 'big-to-int-D0-empty', 'D0', 3);
        Probe(Observer, 'avg-int-to-big-D1', 'D1', 4);
        Probe(Observer, 'avg-int-to-big-D3', 'D3', 4);
        Probe(Observer, 'avg-int-to-big-D0-empty', 'D0', 4);
        Probe(Observer, 'sum-int-to-big-D1', 'D1', 5);
        Probe(Observer, 'sum-big-D1', 'D1', 6);
        Probe(Observer, 'sum-big-D2', 'D2', 6);
        Probe(Observer, 'avg-big-D1', 'D1', 7);
        Probe(Observer, 'sum-int-D1', 'D1', 8);
        Probe(Observer, 'max-big-D1', 'D1', 9);
        Observer.Expect('big-to-int-D1', 'Yes|61');
        Observer.Expect('big-to-int-D1|text', '');
        Observer.Expect('big-to-int-D1|code', '');
        Observer.Expect('big-to-int-D2-above-int-range', 'No|');
        Observer.Expect('big-to-int-D2-above-int-range|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('big-to-int-D2-above-int-range|code', 'AL:Overflow');
        Observer.Expect('big-to-int-D0-empty', 'Yes|0');
        Observer.Expect('big-to-int-D0-empty|text', '');
        Observer.Expect('big-to-int-D0-empty|code', '');
        Observer.Expect('avg-int-to-big-D1', 'Yes|3');
        Observer.Expect('avg-int-to-big-D1|text', '');
        Observer.Expect('avg-int-to-big-D1|code', '');
        Observer.Expect('avg-int-to-big-D3', 'Yes|5');
        Observer.Expect('avg-int-to-big-D3|text', '');
        Observer.Expect('avg-int-to-big-D3|code', '');
        Observer.Expect('avg-int-to-big-D0-empty', 'Yes|0');
        Observer.Expect('avg-int-to-big-D0-empty|text', '');
        Observer.Expect('avg-int-to-big-D0-empty|code', '');
        Observer.Expect('sum-int-to-big-D1', 'Yes|9');
        Observer.Expect('sum-int-to-big-D1|text', '');
        Observer.Expect('sum-int-to-big-D1|code', '');
        Observer.Expect('sum-big-D1', 'Yes|61');
        Observer.Expect('sum-big-D1|text', '');
        Observer.Expect('sum-big-D1|code', '');
        Observer.Expect('sum-big-D2', 'Yes|5000000000');
        Observer.Expect('sum-big-D2|text', '');
        Observer.Expect('sum-big-D2|code', '');
        Observer.Expect('avg-big-D1', 'Yes|20');
        Observer.Expect('avg-big-D1|text', '');
        Observer.Expect('avg-big-D1|code', '');
        Observer.Expect('sum-int-D1', 'Yes|9');
        Observer.Expect('sum-int-D1|text', '');
        Observer.Expect('sum-int-D1|code', '');
        Observer.Expect('max-big-D1', 'Yes|31');
        Observer.Expect('max-big-D1|text', '');
        Observer.Expect('max-big-D1|code', '');
        Observer.Verify();
    end;
#endif
}
#endif
