// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects of PnAQueryObjects.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Query: The Average of a Decimal column keeps 17 places; a quotient where cutting and rounding at the 18th place differ; Sum and Average of an Integer column
// Facts: Query Average/Sum/Min/Max/Count of Decimal and Integer columns for groups whose quotients repeat; Average and Sum of BigInteger and Duration columns
// BC versions: 29 (27 and 28 by CI)

codeunit 70129 "LT PnA Q Average"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        NextEntry: Integer;

    local procedure Ins(G: Code[10]; Q: Integer; A: Decimal; B: BigInteger; D: Duration)
    var
        S: Record "LT PnA Q Src";
    begin
        NextEntry += 1;
        S.Entry := NextEntry;
        S.Grp := G;
        S.Qty := Q;
        S.Amt := A;
        S.Big := B;
        S.Dur := D;
        S.Insert();
    end;

    local procedure Seed()
    var
        S: Record "LT PnA Q Src";
        i: Integer;
    begin
        S.DeleteAll();
        NextEntry := 0;
        Ins('G1', 1, 1, 0, 0);
        Ins('G1', 2, 1, 0, 0);
        Ins('G1', 2, 0, 0, 0);
        Ins('G2', -1, 1, 0, 0);
        Ins('G2', -2, 0, 0, 0);
        Ins('G2', -2, 0, 0, 0);
        Ins('G3', 1, 1, 0, 0);
        Ins('G4', 5, 5, 0, 0);
        Ins('G5', 1, 1, 0, 0);
        Ins('G6', 100, 100, 0, 0);
        Ins('G6', 1, 1, 0, 0);
        Ins('G7', 1, 0.3, 0, 0);
        Ins('G7', 1, 0.3, 0, 0);
        Ins('G7', 1, 0.4, 0, 0);
        for i := 1 to 5 do begin
            Ins('G3', 0, 0, 0, 0);
            Ins('G4', 0, 0, 0, 0);
        end;
        for i := 1 to 6 do
            Ins('G5', 0, 0, 0, 0);
    end;

    [Test]
    procedure Aggregates_PerGroup()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT PnA Q Agg";
    begin
        Seed();
        Q.Open();
        while Q.Read() do
            Observer.Observe(Q.Grp,
              Format(Q.Cnt) + '|' + Format(Q.SumQty) + '|' + Format(Q.AvgQty) + '|' + Format(Q.SumAmt, 0, 9) + '|' +
              Format(Q.AvgAmt, 0, 9) + '|' + Format(Q.MinAmt, 0, 9) + '|' + Format(Q.MaxAmt, 0, 9));
        Q.Close();
        Observer.Expect('G1', '3|5|1|2|0.666666666666666667|0|1');
        Observer.Expect('G2', '3|-5|-1|1|0.333333333333333333|0|1');
        Observer.Expect('G3', '6|1|0|1|0.166666666666666667|0|1');
        Observer.Expect('G4', '6|5|0|5|0.833333333333333333|0|5');
        Observer.Expect('G5', '7|1|0|1|0.142857142857142857|0|1');
        Observer.Expect('G6', '2|101|50|101|50.5|1|100');
        Observer.Expect('G7', '3|3|1|1|0.333333333333333333|0.3|0.4');
        Observer.Verify();
    end;

    [Test]
    procedure BigIntegerAndDuration_SumAndAverage()
    var
        Observer: Codeunit "Probe Observer";
        S: Record "LT PnA Q Src";
        Q: Query "LT PnA Q Agg2";
    begin
        S.DeleteAll();
        NextEntry := 0;
        Ins('H1', 0, 0, 5000000000L, 1500);
        Ins('H1', 0, 0, 5000000001L, 2500);
        Ins('H1', 0, 0, 1, 1);
        Ins('H2', 0, 0, -3, -3);
        Ins('H2', 0, 0, 4, 4);
        Q.Open();
        while Q.Read() do
            Observer.Observe(Q.Grp, Format(Q.SumBig) + '|' + Format(Q.AvgBig) + '|' + Format(Q.SumDur, 0, 9) + '|' + Format(Q.AvgDur, 0, 9));
        Q.Close();
        Observer.Expect('H1', '10000000002|3333333334|P0DT0H0M4.001S|P0DT0H0M1.333S');
        Observer.Expect('H2', '1|0|P0DT0H0M0.001S|P0DT0H0M0.0S');
        Observer.Verify();
    end;
}
