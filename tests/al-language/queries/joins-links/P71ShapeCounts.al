// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624, queries of P71Queries.al, Probe Observer (codeunit 69160), Seed (72625)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Counts grouped by item and location over the Locations-from-items shape
// BC versions: 29 (27 and 28 by CI)

codeunit 72809 "LT P71 Shape Counts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Count_Left_ZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Group Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LocCode) + '|' + Format(Q.Cnt));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|L1|1');
        Observer.Expect('r2', 'B|L3|1');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Count_Inner_ZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Group Inner";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LocCode) + '|' + Format(Q.Cnt));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|L1|1');
        Observer.Expect('r2', 'B|L3|1');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Count_Full_ZoneN()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Group Full";
        i: Integer;
    begin
        Seed.Seed();
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LocCode) + '|' + Format(Q.Cnt));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', '|L5|1');
        Observer.Expect('r2', 'A|L1|1');
        Observer.Expect('r3', 'B|L3|1');
        Observer.Expect('rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Count_Left_RuntimeItemNoA()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Group Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(ItemNo, 'A');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LocCode) + '|' + Format(Q.Cnt));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|L1|1');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Count_Left_RuntimeLocCodeBlank()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Group Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetFilter(LocCode, '');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LocCode) + '|' + Format(Q.Cnt));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|L1|1');
        Observer.Expect('r2', 'B|L3|1');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Count_Left_RuntimeLocCodeL1()
    var
        Observer: Codeunit "Probe Observer";
        Seed: Codeunit "LT P71 Seed";
        Q: Query "LT P71 S Group Left";
        i: Integer;
    begin
        Seed.Seed();
        Q.SetRange(LocCode, 'L1');
        Q.Open();
        while Q.Read() do begin
            i += 1;
            Observer.Observe('r' + Format(i), Format(Q.ItemNo) + '|' + Format(Q.LocCode) + '|' + Format(Q.Cnt));
        end;
        Q.Close();
        Observer.Observe('rows', Format(i));
        Observer.Expect('r1', 'A|L1|1');
        Observer.Expect('rows', '1');
        Observer.Verify();
    end;
}
