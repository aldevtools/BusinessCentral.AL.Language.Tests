// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-keys
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), AsFixtures.al (table 79905)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 644, item 8).
// Facts: the key order of Code values that start with a hyphen or a plus sign (-+5, -A, +5, -0, 0 and neighbours) in FindSet, ascending and
//   descending, and filters on them (a range, < and >, a single value, a wildcard).
// BC versions: 27-29

codeunit 79925 "LT AS Code Key Signs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        K: Record "LT AS Code Key";
    begin
        K.DeleteAll();
        Add('-+5');
        Add('-A');
        Add('+5');
        Add('-0');
        Add('0');
        Add('5');
        Add('A');
        Add('-5');
        Add('+A');
        Add('--5');
    end;

    local procedure Add(Value: Code[20])
    var
        K: Record "LT AS Code Key";
    begin
        K."Code" := Value;
        K.Insert();
    end;

    local procedure List(var K: Record "LT AS Code Key"): Text
    var
        Result: Text;
    begin
        if K.FindSet() then
            repeat
                Result += K."Code" + ' ';
            until K.Next() = 0;
        exit(Result.TrimEnd());
    end;

    [Test]
    procedure Order_Ascending()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT AS Code Key";
    begin
        Seed();
        Observer.Observe('asc', List(K));
        Observer.Expect('asc', '+5 -+5 +A 0 -0 5 -5 --5 A -A');
        Observer.Verify();
    end;

    [Test]
    procedure Order_Descending()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT AS Code Key";
    begin
        Seed();
        K.Ascending(false);
        Observer.Observe('desc', List(K));
        Observer.Expect('desc', '-A A --5 -5 5 -0 0 +A -+5 +5');
        Observer.Verify();
    end;

    [Test]
    procedure Filters_Range()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT AS Code Key";
    begin
        Seed();
        K.SetRange("Code", '+5', '0');
        Observer.Observe('range_plus5_0', List(K));
        K.SetRange("Code", '-0', 'A');
        Observer.Observe('range_minus0_A', List(K));
        Observer.Expect('range_plus5_0', '+5 -+5 +A 0');
        Observer.Expect('range_minus0_A', '-0 5 -5 --5 A');
        Observer.Verify();
    end;

    [Test]
    procedure Filters_Compare()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT AS Code Key";
    begin
        Seed();
        K.SetFilter("Code", '<%1', '-A');
        Observer.Observe('lt_minusA', List(K));
        K.SetFilter("Code", '>%1', '-+5');
        Observer.Observe('gt_minusplus5', List(K));
        Observer.Expect('lt_minusA', '+5 -+5 +A 0 -0 5 -5 --5 A');
        Observer.Expect('gt_minusplus5', '+A 0 -0 5 -5 --5 A -A');
        Observer.Verify();
    end;

    [Test]
    procedure Filters_Single()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT AS Code Key";
    begin
        Seed();
        K.SetFilter("Code", '-+5');
        Observer.Observe('literal_minusplus5', List(K));
        K.SetFilter("Code", '%1', '-0');
        Observer.Observe('arg_minus0', List(K));
        K.SetFilter("Code", '-*');
        Observer.Observe('wild_minus', List(K));
        K.SetFilter("Code", '+*');
        Observer.Observe('wild_plus', List(K));
        Observer.Expect('literal_minusplus5', '-+5');
        Observer.Expect('arg_minus0', '-0');
        Observer.Expect('wild_minus', '-+5 -0 -5 --5 -A');
        Observer.Expect('wild_plus', '+5 +A');
        Observer.Verify();
    end;
}
