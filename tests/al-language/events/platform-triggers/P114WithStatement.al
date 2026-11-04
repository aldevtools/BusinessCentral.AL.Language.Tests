// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-control-statements
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained: table 70863, test codeunit 70864
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// RISKY: explicit "with" statements may raise a compiler diagnostic; this file is separate so only it drops.
// Facts: a "with Rec do" statement resolves field names, procedures and built-in methods against the record, nests, and a local variable of the same name wins or loses against the field.

table 70863 "LT P114 With Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure Describe(): Text
    begin
        exit(Name + ':' + Format(Qty));
    end;
}

codeunit 70864 "LT P114 With Statement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P114_WithRecordFieldsAndMethods()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P114 With Row";
    begin
        Row.DeleteAll();
        with Row do begin
            Init();
            Id := 1;
            Name := 'one';
            Qty := 5;
            Insert();
            Observer.Observe('describe', Describe());
            Observer.Observe('count', Format(Count()));
            Qty := Qty + 1;
            Modify();
        end;
        Row.Get(1);
        Observer.Observe('stored-qty', Format(Row.Qty));
        Observer.Expect('describe', 'one:5');
        Observer.Expect('count', '1');
        Observer.Expect('stored-qty', '6');
        Observer.Verify();
    end;

    [Test]
    procedure P114_WithSingleStatementAndNested()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P114 With Row";
        Other: Record "LT P114 With Row";
    begin
        Row.DeleteAll();
        with Row do
            Id := 7;
        Observer.Observe('single-statement', Format(Row.Id));
        with Row do begin
            Name := 'outer';
            with Other do begin
                Name := 'inner';
                Qty := 3;
            end;
            Observer.Observe('outer-name', Name);
        end;
        Observer.Observe('inner-name', Other.Name);
        Observer.Observe('inner-qty', Format(Other.Qty));
        Observer.Expect('single-statement', '7');
        Observer.Expect('outer-name', 'outer');
        Observer.Expect('inner-name', 'inner');
        Observer.Expect('inner-qty', '3');
        Observer.Verify();
    end;

    [Test]
    procedure P114_WithLocalVariableShadow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P114 With Row";
        Qty: Integer;
    begin
        Qty := 100;
        with Row do begin
            Name := 'shadow';
            Observer.Observe('qty-inside-with', Format(Qty));
            Qty := 50;
        end;
        Observer.Observe('local-qty', Format(Qty));
        Observer.Observe('row-qty', Format(Row.Qty));
        Observer.Expect('qty-inside-with', '0');
        Observer.Expect('local-qty', '100');
        Observer.Expect('row-qty', '50');
        Observer.Verify();
    end;
}
