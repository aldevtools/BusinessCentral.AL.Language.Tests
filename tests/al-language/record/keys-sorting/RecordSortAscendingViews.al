// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setascending-method
// Scope: in-scope
// Fixtures used: LT P161 Sort Row (72715)
//
// SetAscending(Field, false) on a single-field key and what reads it back: Ascending(), GetAscending,
// GetView, a Copy of the record, SetView with the text, Reset, and the order of rows with equal sort
// values (ties). Rows 1..6 with Grp = 1,2,1,2,1,2 (ties in Grp, distinct Id).
//
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 72715 "LT P161 Sort Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp) { }
    }
}

codeunit 72716 "LT P161 Sort Views"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P161 Sort Row";
        i: Integer;
    begin
        R.DeleteAll();
        for i := 1 to 6 do begin
            R.Init();
            R.Id := i;
            R.Grp := 2 - (i mod 2) ;
            R.Insert();
        end;
    end;

    local procedure Walk(var R: Record "LT P161 Sort Row"): Text
    var
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Grp) + '/' + Format(R.Id) + ' ';
            until R.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure P161_SetAscending_Single_ReadBack()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P161 Sort Row";
    begin
        Seed();
        R.SetCurrentKey(Grp);
        Observer.Observe('asc-default', Format(R.Ascending()));
        Observer.Observe('walk-default', Walk(R));
        R.SetAscending(Grp, false);
        Observer.Observe('asc-after', Format(R.Ascending()));
        Observer.Observe('getAsc-after', Format(R.GetAscending(Grp)));
        Observer.Observe('walk-after', Walk(R));
        Observer.Observe('view', R.GetView());
        Observer.Observe('viewNoNames', R.GetView(false));
        Observer.Observe('currentKey', R.CurrentKey());
        Observer.Expect('asc-default', 'Yes');
        Observer.Expect('walk-default', '1/1 1/3 1/5 2/2 2/4 2/6 ');
        Observer.Expect('asc-after', 'No');
        Observer.Expect('getAsc-after', 'No');
        Observer.Expect('walk-after', '2/2 2/4 2/6 1/1 1/3 1/5 ');
        Observer.Expect('view', 'VERSION(1) SORTING(Grp) ORDER(Descending)');
        Observer.Expect('viewNoNames', 'VERSION(1) SORTING(Field2) ORDER(1)');
        Observer.Expect('currentKey', 'Grp');
        Observer.Verify();
    end;

    [Test]
    procedure P161_SetAscending_Single_CopyAndSetView()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P161 Sort Row";
        C: Record "LT P161 Sort Row";
        V: Record "LT P161 Sort Row";
    begin
        Seed();
        R.SetCurrentKey(Grp);
        R.SetAscending(Grp, false);
        C.Copy(R);
        Observer.Observe('copy.asc', Format(C.Ascending()));
        Observer.Observe('copy.getAsc', Format(C.GetAscending(Grp)));
        Observer.Observe('copy.walk', Walk(C));
        Observer.Observe('copy.view', C.GetView());
        V.SetView(R.GetView());
        Observer.Observe('setview.asc', Format(V.Ascending()));
        Observer.Observe('setview.walk', Walk(V));
        Observer.Observe('setview.key', V.CurrentKey());
        Observer.Expect('copy.asc', 'No');
        Observer.Expect('copy.getAsc', 'No');
        Observer.Expect('copy.walk', '2/2 2/4 2/6 1/1 1/3 1/5 ');
        Observer.Expect('copy.view', 'VERSION(1) SORTING(Grp) ORDER(Descending)');
        Observer.Expect('setview.asc', 'No');
        Observer.Expect('setview.walk', '2/6 2/4 2/2 1/5 1/3 1/1 ');
        Observer.Expect('setview.key', 'Grp');
        Observer.Verify();
    end;

    [Test]
    procedure P161_SetAscending_Single_ResetAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P161 Sort Row";
    begin
        Seed();
        R.SetCurrentKey(Grp);
        R.SetAscending(Grp, false);
        R.SetRange(Grp, 2);
        Observer.Observe('filtered.walk', Walk(R));
        Observer.Observe('filtered.asc', Format(R.Ascending()));
        Observer.Observe('filtered.view', R.GetView());
        R.SetFilter(Id, '>2');
        Observer.Observe('twoFilters.walk', Walk(R));
        R.Reset();
        Observer.Observe('reset.asc', Format(R.Ascending()));
        Observer.Observe('reset.key', R.CurrentKey());
        Observer.Observe('reset.walk', Walk(R));
        Observer.Expect('filtered.walk', '2/2 2/4 2/6 ');
        Observer.Expect('filtered.asc', 'No');
        Observer.Expect('filtered.view', 'VERSION(1) SORTING(Grp) ORDER(Descending) WHERE(Grp=FILTER(2))');
        Observer.Expect('twoFilters.walk', '2/4 2/6 ');
        Observer.Expect('reset.asc', 'Yes');
        Observer.Expect('reset.key', 'Id');
        Observer.Expect('reset.walk', '1/1 2/2 1/3 2/4 1/5 2/6 ');
        Observer.Verify();
    end;

    [Test]
    procedure P161_SetAscending_Single_AscendingMethodAndTies()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P161 Sort Row";
    begin
        Seed();
        R.SetCurrentKey(Grp);
        R.Ascending(false);
        Observer.Observe('method.asc', Format(R.Ascending()));
        Observer.Observe('method.getAsc', Format(R.GetAscending(Grp)));
        Observer.Observe('method.walk', Walk(R));
        R.SetAscending(Grp, true);
        Observer.Observe('back.asc', Format(R.Ascending()));
        Observer.Observe('back.walk', Walk(R));
        Observer.Observe('back.view', R.GetView());
        R.SetAscending(Grp, false);
        R.FindFirst();
        Observer.Observe('findFirst', Format(R.Grp) + '/' + Format(R.Id));
        R.FindLast();
        Observer.Observe('findLast', Format(R.Grp) + '/' + Format(R.Id));
        R.Next(-1);
        Observer.Observe('stepBack', Format(R.Grp) + '/' + Format(R.Id));
        Observer.Expect('method.asc', 'No');
        Observer.Expect('method.getAsc', 'No');
        Observer.Expect('method.walk', '2/6 2/4 2/2 1/5 1/3 1/1 ');
        Observer.Expect('back.asc', 'Yes');
        Observer.Expect('back.walk', '1/5 1/3 1/1 2/6 2/4 2/2 ');
        Observer.Expect('back.view', 'VERSION(1) SORTING(Grp)');
        Observer.Expect('findFirst', '2/6');
        Observer.Expect('findLast', '1/1');
        Observer.Expect('stepBack', '1/3');
        Observer.Verify();
    end;
}
