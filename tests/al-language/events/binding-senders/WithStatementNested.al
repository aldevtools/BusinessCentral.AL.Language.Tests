// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-control-statements
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 72781 and 72782, test codeunit 72783
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// RISKY: explicit "with" statements may raise a compiler diagnostic; this file is separate so only it drops.
// Facts: nested "with" over two different records: which record an unqualified field, an unqualified procedure and an assignment bind to when both records have the name, when only the outer or only the inner one has it, and with the nesting reversed; "with" over a temporary record and over a record loop.
table 72781 "LT WithN A"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; OnlyA; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure Describe(): Text
    begin
        exit('A:' + Name);
    end;

    procedure OnlyAProc(): Text
    begin
        exit('only-a-proc');
    end;
}

table 72782 "LT WithN B"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Decimal) { }
        field(4; OnlyB; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure Describe(): Text
    begin
        exit('B:' + Name);
    end;
}

codeunit 72783 "LT WithN"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P195_NestedWith_SameFieldName_InnerOrOuter()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT WithN A";
        B: Record "LT WithN B";
    begin
        A.DeleteAll();
        B.DeleteAll();
        A.Name := 'a-name';
        B.Name := 'b-name';
        with A do
            with B do
                Observer.Observe('a-b-name', Name);
        with B do
            with A do
                Observer.Observe('b-a-name', Name);
        with A do
            with B do
                Observer.Observe('a-b-describe', Describe());
        with B do
            with A do
                Observer.Observe('b-a-describe', Describe());
        with A do
            with B do
                Observer.Observe('a-b-id', Format(Id));
        Observer.Expect('a-b-name', 'b-name');
        Observer.Expect('b-a-name', 'a-name');
        Observer.Expect('a-b-describe', 'B:b-name');
        Observer.Expect('b-a-describe', 'A:a-name');
        Observer.Expect('a-b-id', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P195_NestedWith_AssignmentTarget()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT WithN A";
        B: Record "LT WithN B";
    begin
        A.DeleteAll();
        B.DeleteAll();
        with A do
            with B do begin
                Name := 'assigned';
                Qty := 3;
            end;
        Observer.Observe('a-name', A.Name);
        Observer.Observe('b-name', B.Name);
        Observer.Observe('a-qty', Format(A.Qty));
        Observer.Observe('b-qty', Format(B.Qty));
        with B do
            with A do begin
                Name := 'reversed';
                Qty := 4;
            end;
        Observer.Observe('a-name-reversed', A.Name);
        Observer.Observe('b-name-reversed', B.Name);
        Observer.Observe('a-qty-reversed', Format(A.Qty));
        Observer.Observe('b-qty-reversed', Format(B.Qty));
        Observer.Expect('a-name', '');
        Observer.Expect('b-name', 'assigned');
        Observer.Expect('a-qty', '0');
        Observer.Expect('b-qty', '3');
        Observer.Expect('a-name-reversed', 'reversed');
        Observer.Expect('b-name-reversed', 'assigned');
        Observer.Expect('a-qty-reversed', '4');
        Observer.Expect('b-qty-reversed', '3');
        Observer.Verify();
    end;

    [Test]
    procedure P195_NestedWith_NameOnlyInOuter_OrOnlyInInner()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT WithN A";
        B: Record "LT WithN B";
    begin
        A.DeleteAll();
        B.DeleteAll();
        A.OnlyA := 'oa';
        B.OnlyB := 'ob';
        with A do
            with B do begin
                Observer.Observe('outer-only-field', OnlyA);
                Observer.Observe('inner-only-field', OnlyB);
                Observer.Observe('outer-only-proc', OnlyAProc());
            end;
        with B do
            with A do begin
                Observer.Observe('rev-outer-only-field', OnlyB);
                Observer.Observe('rev-inner-only-field', OnlyA);
            end;
        Observer.Expect('outer-only-field', 'oa');
        Observer.Expect('inner-only-field', 'ob');
        Observer.Expect('outer-only-proc', 'only-a-proc');
        Observer.Expect('rev-outer-only-field', 'ob');
        Observer.Expect('rev-inner-only-field', 'oa');
        Observer.Verify();
    end;

    [Test]
    procedure P195_NestedWith_SameRecordTwice_AndSequential()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT WithN A";
        Other: Record "LT WithN A";
    begin
        A.DeleteAll();
        A.Name := 'first';
        Other.Name := 'second';
        with A do
            with A do
                Name := Name + '-twice';
        Observer.Observe('same-twice', A.Name);
        with A do begin
            with Other do
                Name := Name + '-inner';
            Name := Name + '-outer';
        end;
        Observer.Observe('outer-after-inner', A.Name);
        Observer.Observe('other-after', Other.Name);
        with Other do
            with A do
                Name := 'x';
        Observer.Observe('a-after-swap', A.Name);
        Observer.Observe('other-after-swap', Other.Name);
        Observer.Expect('same-twice', 'first-twice');
        Observer.Expect('outer-after-inner', 'first-twice-outer');
        Observer.Expect('other-after', 'second-inner');
        Observer.Expect('a-after-swap', 'x');
        Observer.Expect('other-after-swap', 'second-inner');
        Observer.Verify();
    end;

    [Test]
    procedure P195_With_TemporaryRecord_AndLoop()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Record "LT WithN A" temporary;
        Sum: Integer;
    begin
        with Rows do begin
            Init();
            Id := 1;
            Qty := 10;
            Insert();
            Init();
            Id := 2;
            Qty := 20;
            Insert();
            Observer.Observe('count', Format(Count()));
            Observer.Observe('is-temporary', Format(IsTemporary()));
            if FindSet() then
                repeat
                    Sum += Qty;
                    Qty := Qty + 1;
                    Modify();
                until Next() = 0;
            Observer.Observe('sum', Format(Sum));
            Observer.Observe('get-2', Format(Get(2)));
            Observer.Observe('qty-2', Format(Qty));
            SetRange(Qty, 11);
            Observer.Observe('filtered-count', Format(Count()));
        end;
        Observer.Observe('filter-view', Rows.GetFilters());
        Observer.Expect('count', '2');
        Observer.Expect('is-temporary', 'Yes');
        Observer.Expect('sum', '30');
        Observer.Expect('get-2', 'Yes');
        Observer.Expect('qty-2', '21');
        Observer.Expect('filtered-count', '1');
        Observer.Expect('filter-view', 'Qty: 11');
        Observer.Verify();
    end;
}
