// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-find-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73936, codeunit 73937
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "Find with the directions in another order" (Tests-SCM-Service ...: LoadFields, TestField with an ErrorInfo, WordMergeDataItem, Time and Option arithmetic, issue 41)
// Facts: Find('=<>'), Find('<>='), Find('=><'), Find('><='), Find('<=>') and Find('>=<') on the same record position, with a row only on one side, on the position itself, and on neither side
// BC versions: 29 (27 and 28 by CI)

table 73936 "LT PnF FD Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73937 "LT PnF Find Directions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFind(var Row: Record "LT PnF FD Row"; Which: Text; var Found: Boolean)
    begin
        Found := Row.Find(Which);
    end;

    local procedure Probe(Name: Text; KeyValue: Integer; Which: Text; var Observer: Codeunit "Probe Observer")
    var
        Row: Record "LT PnF FD Row";
        Found: Boolean;
    begin
        Row.Id := KeyValue;
        if TryFind(Row, Which, Found) then
            Observer.Observe(Name, Format(Found) + '|' + Format(Row.Id))
        else
            Observer.ObserveError(Name);
    end;

    local procedure SeedGaps()
    var
        Row: Record "LT PnF FD Row";
    begin
        Row.DeleteAll();
        Row.Id := 10;
        Row.Insert();
        Row.Id := 20;
        Row.Insert();
        Row.Id := 30;
        Row.Insert();
    end;

    [Test]
    procedure Find_OnPosition()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedGaps();
        Probe('eq_gt_lt', 20, '=><', Observer);
        Probe('eq_lt_gt', 20, '=<>', Observer);
        Probe('lt_gt_eq', 20, '<>=', Observer);
        Probe('gt_lt_eq', 20, '><=', Observer);
        Probe('lt_eq_gt', 20, '<=>', Observer);
        Probe('gt_eq_lt', 20, '>=<', Observer);
        Observer.Expect('eq_gt_lt', 'Yes|20');
        Observer.Expect('eq_lt_gt', 'Yes|20');
        Observer.Expect('lt_gt_eq', 'Yes|10');
        Observer.Expect('gt_lt_eq', 'Yes|30');
        Observer.Expect('lt_eq_gt', 'Yes|10');
        Observer.Expect('gt_eq_lt', 'Yes|30');
        Observer.Verify();
    end;

    [Test]
    procedure Find_BetweenRows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedGaps();
        Probe('eq_gt_lt', 25, '=><', Observer);
        Probe('eq_lt_gt', 25, '=<>', Observer);
        Probe('lt_gt_eq', 25, '<>=', Observer);
        Probe('gt_lt_eq', 25, '><=', Observer);
        Probe('lt_eq_gt', 25, '<=>', Observer);
        Probe('gt_eq_lt', 25, '>=<', Observer);
        Observer.Expect('eq_gt_lt', 'Yes|30');
        Observer.Expect('eq_lt_gt', 'Yes|20');
        Observer.Expect('lt_gt_eq', 'Yes|20');
        Observer.Expect('gt_lt_eq', 'Yes|30');
        Observer.Expect('lt_eq_gt', 'Yes|20');
        Observer.Expect('gt_eq_lt', 'Yes|30');
        Observer.Verify();
    end;

    [Test]
    procedure Find_RowOnlyBelow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedGaps();
        Probe('eq_gt_lt', 35, '=><', Observer);
        Probe('eq_lt_gt', 35, '=<>', Observer);
        Probe('lt_gt_eq', 35, '<>=', Observer);
        Probe('gt_lt_eq', 35, '><=', Observer);
        Observer.Expect('eq_gt_lt', 'Yes|30');
        Observer.Expect('eq_lt_gt', 'Yes|30');
        Observer.Expect('lt_gt_eq', 'Yes|30');
        Observer.Expect('gt_lt_eq', 'Yes|30');
        Observer.Verify();
    end;

    [Test]
    procedure Find_RowOnlyAbove()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedGaps();
        Probe('eq_gt_lt', 5, '=><', Observer);
        Probe('eq_lt_gt', 5, '=<>', Observer);
        Probe('lt_gt_eq', 5, '<>=', Observer);
        Probe('gt_lt_eq', 5, '><=', Observer);
        Observer.Expect('eq_gt_lt', 'Yes|10');
        Observer.Expect('eq_lt_gt', 'Yes|10');
        Observer.Expect('lt_gt_eq', 'Yes|10');
        Observer.Expect('gt_lt_eq', 'Yes|10');
        Observer.Verify();
    end;

    [Test]
    procedure Find_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF FD Row";
    begin
        Row.DeleteAll();
        Probe('eq_gt_lt', 20, '=><', Observer);
        Probe('eq_lt_gt', 20, '=<>', Observer);
        Probe('lt_gt_eq', 20, '<>=', Observer);
        Observer.Expect('eq_gt_lt', 'No|20');
        Observer.Expect('eq_lt_gt', 'No|20');
        Observer.Expect('lt_gt_eq', 'No|20');
        Observer.Verify();
    end;
}
