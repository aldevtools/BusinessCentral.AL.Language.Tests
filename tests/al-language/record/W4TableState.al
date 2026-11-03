// Probe (observe only): record-typed globals of a table under Clear / Reset / Init, records in arrays and SetTable targets, OnRename on the variable's instance,
// xRec in a plain procedure, an array of records.
// Settles docs/probes-needed.md rows 615, 616, 617, 618, 892 (batch 4). Object ids 68048 - 68053.

table 68048 "W4 TG Kid"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Val; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    var
        Hits: Integer;

    procedure Hit(): Integer
    begin
        Hits += 1;
        exit(Hits);
    end;

    procedure HitCount(): Integer
    begin
        exit(Hits);
    end;
}

table 68049 "W4 TG Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Val; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    var
        Kid: Record "W4 TG Kid";
        Kids: array[2] of Record "W4 TG Kid";
        Hits: Integer;
        Renames: Integer;
        LastOld: Integer;
        LastNew: Integer;
        HitsSeenInRename: Integer;
        KidHitsSeenInRename: Integer;

    trigger OnRename()
    begin
        Renames += 1;
        LastOld := xRec.Id;
        LastNew := Rec.Id;
        HitsSeenInRename := Hits;
        KidHitsSeenInRename := Kid.HitCount();
        Hits += 100;
    end;

    procedure Hit(): Integer
    begin
        Hits += 1;
        exit(Hits);
    end;

    procedure HitCount(): Integer
    begin
        exit(Hits);
    end;

    procedure KidFilter(Value: Integer)
    begin
        Kid.SetRange(Id, Value);
    end;

    procedure KidFilters(): Text
    begin
        exit(Kid.GetFilters());
    end;

    procedure KidHit(): Integer
    begin
        exit(Kid.Hit());
    end;

    procedure KidHits(): Integer
    begin
        exit(Kid.HitCount());
    end;

    procedure KidsFilter(Index: Integer; Value: Integer)
    begin
        Kids[Index].SetRange(Id, Value);
    end;

    procedure KidsFilters(Index: Integer): Text
    begin
        exit(Kids[Index].GetFilters());
    end;

    procedure KidsHit(Index: Integer): Integer
    begin
        exit(Kids[Index].Hit());
    end;

    procedure KidsHits(Index: Integer): Integer
    begin
        exit(Kids[Index].HitCount());
    end;

    procedure RenameInfo(): Text
    begin
        exit(StrSubstNo('renames=%1 old=%2 new=%3 hitsInTrigger=%4 kidHitsInTrigger=%5 hits=%6', Renames, LastOld, LastNew, HitsSeenInRename, KidHitsSeenInRename, Hits));
    end;
}

table 68050 "W4 XRec Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Val; Integer)
        {
            trigger OnValidate()
            begin
                SeenXInValidate := xRec.Val;
            end;
        }
    }
    keys { key(PK; Id) { Clustered = true; } }

    var
        SeenXInValidate: Integer;

    procedure Both(): Text
    begin
        exit(StrSubstNo('rec=%1/%2 xrec=%3/%4', Rec.Id, Rec.Val, xRec.Id, xRec.Val));
    end;

    procedure BothViaCopy(): Text
    var
        Other: Record "W4 XRec Row";
    begin
        Other := Rec;
        exit(Other.Both());
    end;

    procedure ChangeThenBoth(NewVal: Integer): Text
    begin
        Rec.Val := NewVal;
        exit(Both());
    end;

    procedure XSeenInValidate(): Integer
    begin
        exit(SeenXInValidate);
    end;
}

codeunit 68051 "W4 Table State Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Prepare(var Row: Record "W4 TG Row")
    begin
        Row.Hit();
        Row.KidFilter(7);
        Row.KidHit();
        Row.KidsHit(1);
        Row.KidsFilter(2, 5);
    end;

    local procedure Observe(var Observer: Codeunit "Probe Observer"; Prefix: Text; var Row: Record "W4 TG Row")
    begin
        Observer.Observe(Prefix + '_hits', Format(Row.HitCount()));
        Observer.Observe(Prefix + '_kid_filters', '[' + Row.KidFilters() + ']');
        Observer.Observe(Prefix + '_kid_hits', Format(Row.KidHits()));
        Observer.Observe(Prefix + '_kids1_hits', Format(Row.KidsHits(1)));
        Observer.Observe(Prefix + '_kids2_filters', '[' + Row.KidsFilters(2) + ']');
    end;

    [Test]
    procedure RecordGlobals_Baseline_NothingDone()
    var
        Row: Record "W4 TG Row";
        Observer: Codeunit "Probe Observer";
    begin
        Prepare(Row);
        Observe(Observer, 'prepared', Row);
        Observer.Expect('prepared_hits', '1');
        Observer.Expect('prepared_kid_filters', '[Id: 7]');
        Observer.Expect('prepared_kid_hits', '1');
        Observer.Expect('prepared_kids1_hits', '1');
        Observer.Expect('prepared_kids2_filters', '[Id: 5]');
        Observer.Verify();
    end;

    [Test]
    procedure RecordGlobals_AfterClear()
    var
        Row: Record "W4 TG Row";
        Observer: Codeunit "Probe Observer";
    begin
        Prepare(Row);
        Clear(Row);
        Observe(Observer, 'after_clear', Row);
        Observer.Expect('after_clear_hits', '0');
        Observer.Expect('after_clear_kid_filters', '[]');
        Observer.Expect('after_clear_kid_hits', '0');
        Observer.Expect('after_clear_kids1_hits', '0');
        Observer.Expect('after_clear_kids2_filters', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecordGlobals_AfterReset()
    var
        Row: Record "W4 TG Row";
        Observer: Codeunit "Probe Observer";
    begin
        Prepare(Row);
        Row.Reset();
        Observe(Observer, 'after_reset', Row);
        Observer.Expect('after_reset_hits', '0');
        Observer.Expect('after_reset_kid_filters', '[]');
        Observer.Expect('after_reset_kid_hits', '0');
        Observer.Expect('after_reset_kids1_hits', '0');
        Observer.Expect('after_reset_kids2_filters', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecordGlobals_AfterInit()
    var
        Row: Record "W4 TG Row";
        Observer: Codeunit "Probe Observer";
    begin
        Prepare(Row);
        Row.Init();
        Observe(Observer, 'after_init', Row);
        Observer.Expect('after_init_hits', '1');
        Observer.Expect('after_init_kid_filters', '[Id: 7]');
        Observer.Expect('after_init_kid_hits', '1');
        Observer.Expect('after_init_kids1_hits', '1');
        Observer.Expect('after_init_kids2_filters', '[Id: 5]');
        Observer.Verify();
    end;

    [Test]
    procedure RecordGlobals_InArraysAndSetTableTargets()
    var
        Arr: array[2] of Record "W4 TG Row";
        Row: Record "W4 TG Row";
        Target: Record "W4 TG Row";
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Arr[1].Hit();
        Arr[1].Hit();
        Arr[1].KidHit();
        Arr[1].KidFilter(3);
        Observer.Observe('arr1_hits', Format(Arr[1].HitCount()));
        Observer.Observe('arr2_hits', Format(Arr[2].HitCount()));
        Observer.Observe('arr1_kid_filters', '[' + Arr[1].KidFilters() + ']');
        Observer.Observe('arr2_kid_filters', '[' + Arr[2].KidFilters() + ']');
        Arr[2] := Arr[1];
        Observer.Observe('assign_arr2_hits', Format(Arr[2].HitCount()));
        Observer.Observe('assign_arr1_hits', Format(Arr[1].HitCount()));
        Clear(Arr[1]);
        Observer.Observe('clear_element_arr1_hits', Format(Arr[1].HitCount()));
        Observer.Observe('clear_element_arr2_hits', Format(Arr[2].HitCount()));
        Arr[1].Hit();
        Arr[2].Hit();
        Clear(Arr);
        Observer.Observe('clear_array_arr1_hits', Format(Arr[1].HitCount()));
        Observer.Observe('clear_array_arr2_hits', Format(Arr[2].HitCount()));
        // SetTable targets: GetTable / SetTable move field values, not the globals.
        Row.Hit();
        Row.Id := 5;
        Target.Hit();
        Target.Hit();
        Target.Hit();
        RR.GetTable(Row);
        RR.SetTable(Target);
        Observer.Observe('settable_target_id', Format(Target.Id));
        Observer.Observe('settable_target_hits', Format(Target.HitCount()));
        Observer.Observe('settable_source_hits', Format(Row.HitCount()));
        Arr[1].Hit();
        RR.SetTable(Arr[2]);
        Observer.Observe('settable_into_array_id', Format(Arr[2].Id));
        Observer.Observe('settable_into_array_hits', Format(Arr[2].HitCount()));
        Observer.Observe('settable_into_array_other_hits', Format(Arr[1].HitCount()));
        Observer.Expect('arr1_hits', '2');
        Observer.Expect('arr2_hits', '0');
        Observer.Expect('arr1_kid_filters', '[Id: 3]');
        Observer.Expect('arr2_kid_filters', '[]');
        Observer.Expect('assign_arr2_hits', '0');
        Observer.Expect('assign_arr1_hits', '2');
        Observer.Expect('clear_element_arr1_hits', '0');
        Observer.Expect('clear_element_arr2_hits', '0');
        Observer.Expect('clear_array_arr1_hits', '0');
        Observer.Expect('clear_array_arr2_hits', '0');
        Observer.Expect('settable_target_id', '5');
        Observer.Expect('settable_target_hits', '3');
        Observer.Expect('settable_source_hits', '1');
        Observer.Expect('settable_into_array_id', '5');
        Observer.Expect('settable_into_array_hits', '0');
        Observer.Expect('settable_into_array_other_hits', '1');
        Observer.Verify();
    end;

    [Test]
    procedure RecordGlobals_ArrayGlobalOfTheTable_AndTheSingleOne()
    var
        Row: Record "W4 TG Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.KidsHit(1);
        Row.KidsHit(1);
        Row.KidsHit(2);
        Row.KidHit();
        Observer.Observe('kids1_hits', Format(Row.KidsHits(1)));
        Observer.Observe('kids2_hits', Format(Row.KidsHits(2)));
        Observer.Observe('kid_hits', Format(Row.KidHits()));
        Row.KidsFilter(1, 4);
        Observer.Observe('kids1_filters', '[' + Row.KidsFilters(1) + ']');
        Observer.Observe('kids2_filters', '[' + Row.KidsFilters(2) + ']');
        Observer.Observe('kid_filters', '[' + Row.KidFilters() + ']');
        Observer.Expect('kids1_hits', '2');
        Observer.Expect('kids2_hits', '1');
        Observer.Expect('kid_hits', '1');
        Observer.Expect('kids1_filters', '[Id: 4]');
        Observer.Expect('kids2_filters', '[]');
        Observer.Expect('kid_filters', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayOfRecords_ElementsAreVariablesOfTheirOwn()
    var
        A: array[3] of Record "W4 TG Kid";
        Observer: Codeunit "Probe Observer";
    begin
        A[1].DeleteAll();
        A[1].Init();
        A[1].Id := 1;
        A[1].Val := 10;
        A[1].Insert();
        A[2].Id := 2;
        A[2].Val := 20;
        A[2].Insert();
        A[1].SetRange(Id, 1);
        Observer.Observe('a1_filters', '[' + A[1].GetFilters() + ']');
        Observer.Observe('a2_filters', '[' + A[2].GetFilters() + ']');
        Observer.Observe('a1_count', Format(A[1].Count()));
        Observer.Observe('a2_count', Format(A[2].Count()));
        Observer.Observe('a3_empty_id', Format(A[3].Id));
        A[3].Get(2);
        Observer.Observe('a3_after_get_val', Format(A[3].Val));
        Observer.Observe('a2_val_unchanged', Format(A[2].Val));
        A[1].DeleteAll();
        Observer.Expect('a1_filters', '[Id: 1]');
        Observer.Expect('a2_filters', '[]');
        Observer.Expect('a1_count', '1');
        Observer.Expect('a2_count', '2');
        Observer.Expect('a3_empty_id', '0');
        Observer.Expect('a3_after_get_val', '20');
        Observer.Expect('a2_val_unchanged', '20');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_OnRenameRunsOnTheVariablesInstance()
    var
        Row: Record "W4 TG Row";
        Same: Record "W4 TG Row";
        Other: Record "W4 TG Row";
        Arr: array[2] of Record "W4 TG Row";
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Hit();
        Row.KidHit();
        Row.Rename(2);
        Observer.Observe('first_rename', Row.RenameInfo());
        Row.Rename(3);
        Observer.Observe('second_rename', Row.RenameInfo());
        Same.Get(3);
        Observer.Observe('other_variable_same_row_before', Same.RenameInfo());
        Same.Rename(4);
        Observer.Observe('other_variable_after_rename', Same.RenameInfo());
        Observer.Observe('first_variable_after_other_rename', Row.RenameInfo());
        // A RecordRef holds the buffer, the variable keeps its instance.
        Other.Get(4);
        RR.GetTable(Other);
        RR.Rename(5);
        Observer.Observe('recref_rename_variable', Other.RenameInfo());
        Observer.Observe('recref_rename_variable_id', Format(Other.Id));
        // An array element.
        Arr[1].Get(5);
        Arr[1].Rename(6);
        Observer.Observe('array_element_rename', Arr[1].RenameInfo());
        Observer.Observe('array_other_element', Arr[2].RenameInfo());
        Row.DeleteAll();
        Observer.Expect('first_rename', 'renames=1 old=1 new=2 hitsInTrigger=1 kidHitsInTrigger=1 hits=101');
        Observer.Expect('second_rename', 'renames=2 old=2 new=3 hitsInTrigger=101 kidHitsInTrigger=1 hits=201');
        Observer.Expect('other_variable_same_row_before', 'renames=0 old=0 new=0 hitsInTrigger=0 kidHitsInTrigger=0 hits=0');
        Observer.Expect('other_variable_after_rename', 'renames=1 old=3 new=4 hitsInTrigger=0 kidHitsInTrigger=0 hits=100');
        Observer.Expect('first_variable_after_other_rename', 'renames=2 old=2 new=3 hitsInTrigger=101 kidHitsInTrigger=1 hits=201');
        Observer.Expect('recref_rename_variable', 'renames=0 old=0 new=0 hitsInTrigger=0 kidHitsInTrigger=0 hits=0');
        Observer.Expect('recref_rename_variable_id', '4');
        Observer.Expect('array_element_rename', 'renames=1 old=5 new=6 hitsInTrigger=0 kidHitsInTrigger=0 hits=100');
        Observer.Expect('array_other_element', 'renames=0 old=0 new=0 hitsInTrigger=0 kidHitsInTrigger=0 hits=0');
        Observer.Verify();
    end;

    [Test]
    procedure XRec_InAPlainProcedure()
    var
        Row: Record "W4 XRec Row";
        Fresh: Record "W4 XRec Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Val := 10;
        Row.Insert();
        Row.Id := 2;
        Row.Val := 20;
        Row.Insert();
        Observer.Observe('fresh_variable', Fresh.Both());
        Row.Get(1);
        Observer.Observe('after_get_1', Row.Both());
        Row.Val := 15;
        Observer.Observe('field_assigned_no_modify', Row.Both());
        Observer.Observe('inside_procedure_changes_val', Row.ChangeThenBoth(16));
        Row.Modify();
        Observer.Observe('after_modify', Row.Both());
        Row.Get(2);
        Observer.Observe('after_get_2', Row.Both());
        Observer.Observe('via_local_copy', Row.BothViaCopy());
        Row.Validate(Val, 25);
        Observer.Observe('after_validate_both', Row.Both());
        Observer.Observe('x_seen_in_validate', Format(Row.XSeenInValidate()));
        Row.Init();
        Observer.Observe('after_init', Row.Both());
        Row.DeleteAll();
        Observer.Expect('fresh_variable', 'rec=0/0 xrec=0/0');
        Observer.Expect('after_get_1', 'rec=1/10 xrec=0/0');
        Observer.Expect('field_assigned_no_modify', 'rec=1/15 xrec=0/0');
        Observer.Expect('inside_procedure_changes_val', 'rec=1/16 xrec=0/0');
        Observer.Expect('after_modify', 'rec=1/16 xrec=0/0');
        Observer.Expect('after_get_2', 'rec=2/20 xrec=0/0');
        Observer.Expect('via_local_copy', 'rec=2/20 xrec=0/0');
        Observer.Expect('after_validate_both', 'rec=2/25 xrec=0/0');
        Observer.Expect('x_seen_in_validate', '20');
        Observer.Expect('after_init', 'rec=2/0 xrec=0/0');
        Observer.Verify();
    end;
}
