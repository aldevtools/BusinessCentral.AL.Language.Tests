// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 70107/70110
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: CalcFormula: two conditions on one source field other than field() + field(filter()); `-` before min / max / lookup
// Facts: a negated min/max/lookup CalcFormula and two conditions on one source field: values or the refusal. NOTE the lead: the objects may be rejected by the compiler (AL error) - then the compile error text itself is the observation, drop the field
// BC versions: 29 (27 and 28 by CI)

table 70110 "LT PnA CF Odd"
{
    fields
    {
        field(1; "No."; Code[10]) { }
        field(10; NegMin; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = -min("LT PnA CF Line".Amt where(Doc = field("No.")));
        }
        field(11; NegMax; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = -max("LT PnA CF Line".Amt where(Doc = field("No.")));
        }
        field(12; NegLookup; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = -lookup("LT PnA CF Line".Amt where(Entry = const(1)));
        }
        field(13; TwoFilters; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT PnA CF Line" where(Doc = field("No."), Qty = filter(> 1), Qty = filter(< 4)));
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 70112 "LT PnA CF Odd Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Odd: Record "LT PnA CF Odd";
        Res: Text;

    local procedure Seed()
    var
        L: Record "LT PnA CF Line";
    begin
        L.DeleteAll();
        Odd.DeleteAll();
        AddLine(1, 'D1', 2, 10.5);
        AddLine(2, 'D1', 3, 20.25);
        AddLine(3, 'D1', 4, 3);
        AddLine(4, 'D2', 3, 8);
        Odd."No." := 'D1';
        Odd.Insert();
        Odd."No." := 'D2';
        Odd.Insert();
        Odd."No." := 'D3';
        Odd.Insert();
    end;

    local procedure AddLine(EntryNo: Integer; DocNo: Code[10]; Q: Integer; A: Decimal)
    var
        L: Record "LT PnA CF Line";
    begin
        L.Entry := EntryNo;
        L.Doc := DocNo;
        L.Qty := Q;
        L.Amt := A;
        L.Insert();
    end;

    [TryFunction]
    local procedure TryCalc(DocNo: Code[10]; Op: Integer)
    begin
        Res := '';
        Odd.Get(DocNo);
        case Op of
            1:
                begin
                    Odd.CalcFields(NegMin);
                    Res := Format(Odd.NegMin);
                end;
            2:
                begin
                    Odd.CalcFields(NegMax);
                    Res := Format(Odd.NegMax);
                end;
            3:
                begin
                    Odd.CalcFields(NegLookup);
                    Res := Format(Odd.NegLookup);
                end;
            4:
                begin
                    Odd.CalcFields(TwoFilters);
                    Res := Format(Odd.TwoFilters);
                end;
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; DocNo: Code[10]; Op: Integer)
    begin
        Observer.Observe(Name, Format(TryCalc(DocNo, Op)) + '|' + Res);
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure Negated_MinMaxLookup()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'neg-min-D1', 'D1', 1);
        Probe(Observer, 'neg-max-D1', 'D1', 2);
        Probe(Observer, 'neg-min-D3-empty', 'D3', 1);
        Probe(Observer, 'neg-lookup', 'D1', 3);
        Observer.Expect('neg-min-D1', 'Yes|-3');
        Observer.Expect('neg-min-D1|text', '');
        Observer.Expect('neg-min-D1|code', '');
        Observer.Expect('neg-max-D1', 'Yes|-20.25');
        Observer.Expect('neg-max-D1|text', '');
        Observer.Expect('neg-max-D1|code', '');
        Observer.Expect('neg-min-D3-empty', 'Yes|0');
        Observer.Expect('neg-min-D3-empty|text', '');
        Observer.Expect('neg-min-D3-empty|code', '');
        Observer.Expect('neg-lookup', 'Yes|10.5');
        Observer.Expect('neg-lookup|text', '');
        Observer.Expect('neg-lookup|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure TwoConditionsOnOneField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'two-filters-D1', 'D1', 4);
        Probe(Observer, 'two-filters-D2', 'D2', 4);
        Observer.Expect('two-filters-D1', 'Yes|2');
        Observer.Expect('two-filters-D1|text', '');
        Observer.Expect('two-filters-D1|code', '');
        Observer.Expect('two-filters-D2', 'Yes|1');
        Observer.Expect('two-filters-D2|text', '');
        Observer.Expect('two-filters-D2|code', '');
        Observer.Verify();
    end;
}
