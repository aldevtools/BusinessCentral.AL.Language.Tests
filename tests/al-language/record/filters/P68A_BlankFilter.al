// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 70701
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetFilter(Field, '') on a Record: whether it removes the field's filter, per field type
// BC versions: 29 (27 and 28 by CI)

codeunit 70720 "LT P68 Blank Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(var R: Record "LT P68 Flt")
    begin
        R.DeleteAll();
        Add(R, 1, '', '', 0, 0D);
        Add(R, 2, 'Apple', 'A1', 1, DMY2Date(1, 1, 2024));
        Add(R, 3, 'Banana', 'B2', 2, DMY2Date(2, 1, 2024));
        Add(R, 4, 'apple', 'A3', 3, DMY2Date(3, 1, 2024));
        Add(R, 5, 'Cherry', 'C4', 5, DMY2Date(4, 1, 2024));
        R.Reset();
    end;

    local procedure Add(var R: Record "LT P68 Flt"; No: Integer; T: Text[30]; C: Code[20]; I: Integer; D: Date)
    begin
        R.Init();
        R."No." := No;
        R.Txt := T;
        R.Cod := C;
        R.Int := I;
        R.Dt := D;
        R.Insert();
    end;

    [Test]
    procedure BlankFilter_Text()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
    begin
        Seed(R);
        Observer.Observe('none-count', Format(R.Count()));
        R.SetFilter(Txt, 'A*');
        Observer.Observe('set-filter', R.GetFilter(Txt));
        Observer.Observe('set-count', Format(R.Count()));
        Observer.Observe('set-hasfilter', Format(R.HasFilter()));
        R.SetFilter(Txt, '');
        Observer.Observe('blank-filter', R.GetFilter(Txt));
        Observer.Observe('blank-count', Format(R.Count()));
        Observer.Observe('blank-hasfilter', Format(R.HasFilter()));
        Observer.Observe('blank-filters', R.GetFilters());
        R.SetFilter(Txt, 'Apple');
        R.SetFilter(Txt, '%1', '');
        Observer.Observe('param-filter', R.GetFilter(Txt));
        Observer.Observe('param-count', Format(R.Count()));
        R.SetFilter(Txt, '''''');
        Observer.Observe('quoted-filter', R.GetFilter(Txt));
        Observer.Observe('quoted-count', Format(R.Count()));
        R.SetFilter(Txt, 'Apple');
        R.SetRange(Txt);
        Observer.Observe('range-clear-filter', R.GetFilter(Txt));
        Observer.Observe('range-clear-count', Format(R.Count()));
        R.SetRange(Txt, '');
        Observer.Observe('range-blank-filter', R.GetFilter(Txt));
        Observer.Observe('range-blank-count', Format(R.Count()));
        Observer.Expect('none-count', '5');
        Observer.Expect('set-filter', 'A*');
        Observer.Expect('set-count', '1');
        Observer.Expect('set-hasfilter', 'Yes');
        Observer.Expect('blank-filter', '');
        Observer.Expect('blank-count', '5');
        Observer.Expect('blank-hasfilter', 'No');
        Observer.Expect('blank-filters', '');
        Observer.Expect('param-filter', '''''');
        Observer.Expect('param-count', '1');
        Observer.Expect('quoted-filter', '''''');
        Observer.Expect('quoted-count', '1');
        Observer.Expect('range-clear-filter', '');
        Observer.Expect('range-clear-count', '5');
        Observer.Expect('range-blank-filter', '''''');
        Observer.Expect('range-blank-count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure BlankFilter_Code()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
    begin
        Seed(R);
        R.SetFilter(Cod, 'A*');
        Observer.Observe('set-filter', R.GetFilter(Cod));
        Observer.Observe('set-count', Format(R.Count()));
        R.SetFilter(Cod, '');
        Observer.Observe('blank-filter', R.GetFilter(Cod));
        Observer.Observe('blank-count', Format(R.Count()));
        Observer.Observe('blank-hasfilter', Format(R.HasFilter()));
        R.SetFilter(Cod, 'B2');
        R.SetFilter(Cod, '%1', '');
        Observer.Observe('param-filter', R.GetFilter(Cod));
        Observer.Observe('param-count', Format(R.Count()));
        R.SetRange(Cod, '');
        Observer.Observe('range-blank-filter', R.GetFilter(Cod));
        Observer.Observe('range-blank-count', Format(R.Count()));
        Observer.Expect('set-filter', 'A*');
        Observer.Expect('set-count', '2');
        Observer.Expect('blank-filter', '');
        Observer.Expect('blank-count', '5');
        Observer.Expect('blank-hasfilter', 'No');
        Observer.Expect('param-filter', '''''');
        Observer.Expect('param-count', '1');
        Observer.Expect('range-blank-filter', '''''');
        Observer.Expect('range-blank-count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure BlankFilter_Integer()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
    begin
        Seed(R);
        R.SetFilter(Int, '>=2');
        Observer.Observe('set-filter', R.GetFilter(Int));
        Observer.Observe('set-count', Format(R.Count()));
        R.SetFilter(Int, '');
        Observer.Observe('blank-filter', R.GetFilter(Int));
        Observer.Observe('blank-count', Format(R.Count()));
        Observer.Observe('blank-hasfilter', Format(R.HasFilter()));
        R.SetFilter(Int, '2');
        R.SetFilter(Int, '%1', 0);
        Observer.Observe('zero-filter', R.GetFilter(Int));
        Observer.Observe('zero-count', Format(R.Count()));
        R.SetRange(Int, 0);
        Observer.Observe('range-zero-filter', R.GetFilter(Int));
        Observer.Observe('range-zero-count', Format(R.Count()));
        Observer.Expect('set-filter', '>=2');
        Observer.Expect('set-count', '3');
        Observer.Expect('blank-filter', '');
        Observer.Expect('blank-count', '5');
        Observer.Expect('blank-hasfilter', 'No');
        Observer.Expect('zero-filter', '0');
        Observer.Expect('zero-count', '1');
        Observer.Expect('range-zero-filter', '0');
        Observer.Expect('range-zero-count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure BlankFilter_Date()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
    begin
        Seed(R);
        R.SetFilter(Dt, '>%1', DMY2Date(2, 1, 2024));
        Observer.Observe('set-filter', R.GetFilter(Dt));
        Observer.Observe('set-count', Format(R.Count()));
        R.SetFilter(Dt, '');
        Observer.Observe('blank-filter', R.GetFilter(Dt));
        Observer.Observe('blank-count', Format(R.Count()));
        Observer.Observe('blank-hasfilter', Format(R.HasFilter()));
        R.SetFilter(Dt, '%1', 0D);
        Observer.Observe('zerodate-filter', R.GetFilter(Dt));
        Observer.Observe('zerodate-count', Format(R.Count()));
        R.SetRange(Dt, 0D);
        Observer.Observe('range-zerodate-count', Format(R.Count()));
        Observer.Expect('set-filter', '>01/02/24');
        Observer.Expect('set-count', '2');
        Observer.Expect('blank-filter', '');
        Observer.Expect('blank-count', '5');
        Observer.Expect('blank-hasfilter', 'No');
        Observer.Expect('zerodate-filter', '''''');
        Observer.Expect('zerodate-count', '1');
        Observer.Expect('range-zerodate-count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure BlankFilter_OtherFiltersKept()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
    begin
        Seed(R);
        R.SetFilter(Txt, 'A*');
        R.SetFilter(Int, '>=2');
        Observer.Observe('both-count', Format(R.Count()));
        R.SetFilter(Txt, '');
        Observer.Observe('txt-blank-int-filter', R.GetFilter(Int));
        Observer.Observe('txt-blank-count', Format(R.Count()));
        Observer.Observe('txt-blank-filters', R.GetFilters());
        R.SetFilter(Int, '');
        Observer.Observe('all-blank-filters', R.GetFilters());
        Observer.Observe('all-blank-count', Format(R.Count()));
        Observer.Observe('all-blank-hasfilter', Format(R.HasFilter()));
        Observer.Expect('both-count', '0');
        Observer.Expect('txt-blank-int-filter', '>=2');
        Observer.Expect('txt-blank-count', '3');
        Observer.Expect('txt-blank-filters', 'Int: >=2');
        Observer.Expect('all-blank-filters', '');
        Observer.Expect('all-blank-count', '5');
        Observer.Expect('all-blank-hasfilter', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure BlankFilter_FilterGroup()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
    begin
        Seed(R);
        R.SetFilter(Txt, 'A*');
        R.FilterGroup(5);
        R.SetFilter(Txt, '');
        Observer.Observe('g5-filter', R.GetFilter(Txt));
        Observer.Observe('g5-count', Format(R.Count()));
        R.FilterGroup(0);
        Observer.Observe('g0-filter', R.GetFilter(Txt));
        Observer.Observe('g0-count', Format(R.Count()));
        Observer.Expect('g5-filter', '');
        Observer.Expect('g5-count', '1');
        Observer.Expect('g0-filter', 'A*');
        Observer.Expect('g0-count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure BlankFilter_Decimal_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P68 Flt";
    begin
        Seed(R);
        R.SetFilter(Dec, '>0');
        Observer.Observe('dec-set-count', Format(R.Count()));
        R.SetFilter(Dec, '');
        Observer.Observe('dec-blank-filter', R.GetFilter(Dec));
        Observer.Observe('dec-blank-count', Format(R.Count()));
        R.SetFilter(Flag, 'Yes');
        Observer.Observe('flag-set-filter', R.GetFilter(Flag));
        Observer.Observe('flag-set-count', Format(R.Count()));
        R.SetFilter(Flag, '');
        Observer.Observe('flag-blank-filter', R.GetFilter(Flag));
        Observer.Observe('flag-blank-count', Format(R.Count()));
        Observer.Expect('dec-set-count', '0');
        Observer.Expect('dec-blank-filter', '');
        Observer.Expect('dec-blank-count', '5');
        Observer.Expect('flag-set-filter', 'Yes');
        Observer.Expect('flag-set-count', '0');
        Observer.Expect('flag-blank-filter', '');
        Observer.Expect('flag-blank-count', '5');
        Observer.Verify();
    end;
}
