// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setascending-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67152 "LT SA Row"
// Probe: per-field sort direction edges. GetView and GetView(false) with every key field descending, with mixed directions, and with only the first field
// descending; SetView with ORDER(Descending,Ascending), ORDER(Descending) alone and SORTING plus ORDER, with the rows read back; SetAscending on a primary key
// field that only follows the current key; SetAscending after Ascending(false); and the text of the error for a field outside the key (field name or caption).
// Object ids 67152 - 67153.

table 67152 "LT SA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Qty; Integer) { Caption = 'LT Quantity'; }
        field(4; Note; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp, Qty) { }
    }
}

codeunit 67153 "LT SA Edges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT SA Row";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 6 do begin
            Row.Init();
            Row.Id := Index;
            Row.Grp := (Index - 1) div 3 + 1;
            Row.Qty := 10 - Index;
            Row.Note := 'N' + Format(Index);
            Row.Insert();
        end;
    end;

    local procedure Ids(var Row: Record "LT SA Row"): Text
    var
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySetView(var Row: Record "LT SA Row"; View: Text)
    begin
        Row.SetView(View);
    end;

    local procedure ViewOutcome(View: Text): Text
    var
        Row: Record "LT SA Row";
    begin
        ClearLastError();
        Row.Reset();
        if not TrySetView(Row, View) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit('ok:view=' + Row.GetView() + '|plain=' + Row.GetView(false) + '|asc_grp=' + AscOutcome(Row, 1) + '|asc_qty=' + AscOutcome(Row, 2) + '|ascending=' + Format(Row.Ascending()) + '|ids=' + Ids(Row));
    end;

    [TryFunction]
    local procedure TryGetAscending(var Row: Record "LT SA Row"; Which: Integer; var Result: Boolean)
    begin
        if Which = 1 then
            Result := Row.GetAscending(Grp)
        else
            Result := Row.GetAscending(Qty);
    end;

    local procedure AscOutcome(var Row: Record "LT SA Row"; Which: Integer): Text
    var
        Result: Boolean;
    begin
        ClearLastError();
        if not TryGetAscending(Row, Which, Result) then
            exit('error:' + GetLastErrorText());
        exit(Format(Result));
    end;

    [Test]
    procedure GetView_AllKeyFieldsDescending()
    var
        Row: Record "LT SA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetCurrentKey(Grp, Qty);
        Row.SetAscending(Grp, false);
        Row.SetAscending(Qty, false);
        Observer.Observe('view', Row.GetView());
        Observer.Observe('view_plain', Row.GetView(false));
        Observer.Observe('ascending', Format(Row.Ascending()));
        Observer.Observe('ids', Ids(Row));
        Observer.Expect('view', 'VERSION(1) SORTING(Grp,LT Quantity) ORDER(Descending)');
        Observer.Expect('view_plain', 'VERSION(1) SORTING(Field2,Field3) ORDER(1)');
        Observer.Expect('ascending', 'No');
        Observer.Expect('ids', '4,5,6,1,2,3,');
        Observer.Verify();
    end;

    [Test]
    procedure GetView_MixedDirections()
    var
        Row: Record "LT SA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetCurrentKey(Grp, Qty);
        Row.SetAscending(Grp, false);
        Observer.Observe('grp_desc_view', Row.GetView());
        Observer.Observe('grp_desc_view_plain', Row.GetView(false));
        Observer.Observe('grp_desc_ids', Ids(Row));
        Row.Reset();
        Row.SetCurrentKey(Grp, Qty);
        Row.SetAscending(Qty, false);
        Observer.Observe('qty_desc_view', Row.GetView());
        Observer.Observe('qty_desc_view_plain', Row.GetView(false));
        Observer.Observe('qty_desc_ids', Ids(Row));
        Observer.Observe('qty_desc_ascending', Format(Row.Ascending()));
        Observer.Expect('grp_desc_view', 'VERSION(1) SORTING(Grp,LT Quantity) ORDER(Descending,Ascending)');
        Observer.Expect('grp_desc_view_plain', 'VERSION(1) SORTING(Field2,Field3) ORDER(1,0)');
        Observer.Expect('grp_desc_ids', '6,5,4,3,2,1,');
        Observer.Expect('qty_desc_view', 'VERSION(1) SORTING(Grp,LT Quantity) ORDER(Ascending,Descending)');
        Observer.Expect('qty_desc_view_plain', 'VERSION(1) SORTING(Field2,Field3) ORDER(0,1)');
        Observer.Expect('qty_desc_ids', '1,2,3,4,5,6,');
        Observer.Expect('qty_desc_ascending', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_OrderClauses()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('sorting_order_desc_asc', ViewOutcome('SORTING(Grp,Qty) ORDER(Descending,Ascending)'));
        Observer.Observe('sorting_order_asc_desc', ViewOutcome('SORTING(Grp,Qty) ORDER(Ascending,Descending)'));
        Observer.Observe('sorting_order_desc_desc', ViewOutcome('SORTING(Grp,Qty) ORDER(Descending,Descending)'));
        Observer.Observe('sorting_order_desc_only', ViewOutcome('SORTING(Grp,Qty) ORDER(Descending)'));
        Observer.Observe('order_desc_asc_no_sorting', ViewOutcome('ORDER(Descending,Ascending)'));
        Observer.Observe('order_desc_no_sorting', ViewOutcome('ORDER(Descending)'));
        Observer.Observe('order_ascending_only', ViewOutcome('SORTING(Grp,Qty) ORDER(Ascending)'));
        Observer.Observe('order_three_values', ViewOutcome('SORTING(Grp,Qty) ORDER(Descending,Ascending,Descending)'));
        Observer.Expect('sorting_order_desc_asc', 'ok:view=VERSION(1) SORTING(Grp,LT Quantity) ORDER(Descending,Ascending)|plain=VERSION(1) SORTING(Field2,Field3) ORDER(1,0)|asc_grp=No|asc_qty=Yes|ascending=No|ids=6,5,4,3,2,1,');
        Observer.Expect('sorting_order_asc_desc', 'ok:view=VERSION(1) SORTING(Grp,LT Quantity) ORDER(Ascending,Descending)|plain=VERSION(1) SORTING(Field2,Field3) ORDER(0,1)|asc_grp=Yes|asc_qty=No|ascending=No|ids=1,2,3,4,5,6,');
        Observer.Expect('sorting_order_desc_desc', 'ok:view=VERSION(1) SORTING(Grp,LT Quantity) ORDER(Descending)|plain=VERSION(1) SORTING(Field2,Field3) ORDER(1)|asc_grp=No|asc_qty=No|ascending=No|ids=4,5,6,1,2,3,');
        Observer.Expect('sorting_order_desc_only', 'ok:view=VERSION(1) SORTING(Grp,LT Quantity) ORDER(Descending)|plain=VERSION(1) SORTING(Field2,Field3) ORDER(1)|asc_grp=No|asc_qty=No|ascending=No|ids=4,5,6,1,2,3,');
        Observer.Expect('order_desc_asc_no_sorting', 'error:The number of ascending/descending specifications in the ORDER clause must either be 1 or the same as number of fields specified in the SORTING clause.|DB:Ok');
        Observer.Expect('order_desc_no_sorting', 'ok:view=VERSION(1) SORTING(Id) ORDER(Descending)|plain=VERSION(1) SORTING(Field1) ORDER(1)|asc_grp=error:Cannot call GetAscending on field Grp because it is not part of the current sorting.|asc_qty=error:Cannot call GetAscending on field Qty because it is not part of the current sorting.|ascending=No|ids=6,5,4,3,2,1,');
        Observer.Expect('order_ascending_only', 'ok:view=VERSION(1) SORTING(Grp,LT Quantity)|plain=VERSION(1) SORTING(Field2,Field3)|asc_grp=Yes|asc_qty=Yes|ascending=Yes|ids=3,2,1,6,5,4,');
        Observer.Expect('order_three_values', 'error:The number of ascending/descending specifications in the ORDER clause must either be 1 or the same as number of fields specified in the SORTING clause.|DB:Ok');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetAscendingId(var Row: Record "LT SA Row")
    begin
        Row.SetAscending(Id, false);
    end;

    [Test]
    procedure SetAscending_PrimaryKeyFieldFollowingTheKey()
    var
        Row: Record "LT SA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetCurrentKey(Grp, Qty);
        Observer.Observe('default_view', Row.GetView());
        Observer.Observe('id_ascending_before', Format(Row.GetAscending(Id)));
        ClearLastError();
        Observer.Observe('set_id_outcome', Format(TrySetAscendingId(Row)));
        Observer.ObserveError('set_id');
        Observer.Observe('id_desc_view', Row.GetView());
        Observer.Observe('id_desc_view_plain', Row.GetView(false));
        Observer.Observe('id_ascending_after', Format(Row.GetAscending(Id)));
        Observer.Observe('grp_ascending_after', Format(Row.GetAscending(Grp)));
        Observer.Observe('ids', Ids(Row));
        Observer.Expect('default_view', 'VERSION(1) SORTING(Grp,LT Quantity)');
        Observer.Expect('id_ascending_before', 'Yes');
        Observer.Expect('set_id_outcome', 'No');
        Observer.Expect('set_id|text', 'The specified sorting could not be set on field ''Id'' with the key consisting of ''Grp,Qty''.');
        Observer.Expect('set_id|code', 'InvalidSortingFields');
        Observer.Expect('id_desc_view', 'VERSION(1) SORTING(Grp,LT Quantity)');
        Observer.Expect('id_desc_view_plain', 'VERSION(1) SORTING(Field2,Field3)');
        Observer.Expect('id_ascending_after', 'Yes');
        Observer.Expect('grp_ascending_after', 'Yes');
        Observer.Expect('ids', '3,2,1,6,5,4,');
        Observer.Verify();
    end;

    [Test]
    procedure SetAscending_AfterAscendingFalse()
    var
        Row: Record "LT SA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetCurrentKey(Grp, Qty);
        Row.Ascending(false);
        Observer.Observe('after_ascending_false_view', Row.GetView());
        Observer.Observe('after_ascending_false_grp', Format(Row.GetAscending(Grp)));
        Observer.Observe('after_ascending_false_qty', Format(Row.GetAscending(Qty)));
        Row.SetAscending(Grp, true);
        Observer.Observe('then_grp_true_view', Row.GetView());
        Observer.Observe('then_grp_true_grp', Format(Row.GetAscending(Grp)));
        Observer.Observe('then_grp_true_qty', Format(Row.GetAscending(Qty)));
        Observer.Observe('then_grp_true_ascending', Format(Row.Ascending()));
        Observer.Observe('then_grp_true_ids', Ids(Row));
        Observer.Expect('after_ascending_false_view', 'VERSION(1) SORTING(Grp,LT Quantity) ORDER(Descending)');
        Observer.Expect('after_ascending_false_grp', 'No');
        Observer.Expect('after_ascending_false_qty', 'No');
        Observer.Expect('then_grp_true_view', 'VERSION(1) SORTING(Grp,LT Quantity) ORDER(Ascending,Descending)');
        Observer.Expect('then_grp_true_grp', 'Yes');
        Observer.Expect('then_grp_true_qty', 'No');
        Observer.Expect('then_grp_true_ascending', 'No');
        Observer.Expect('then_grp_true_ids', '1,2,3,4,5,6,');
        Observer.Verify();
    end;

    [Test]
    procedure SetAscending_AfterPerFieldThenAscendingTrue()
    var
        Row: Record "LT SA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetCurrentKey(Grp, Qty);
        Row.SetAscending(Qty, false);
        Row.Ascending(true);
        Observer.Observe('view', Row.GetView());
        Observer.Observe('grp', Format(Row.GetAscending(Grp)));
        Observer.Observe('qty', Format(Row.GetAscending(Qty)));
        Row.Ascending(false);
        Observer.Observe('then_false_view', Row.GetView());
        Observer.Observe('then_false_grp', Format(Row.GetAscending(Grp)));
        Observer.Observe('then_false_qty', Format(Row.GetAscending(Qty)));
        Observer.Expect('view', 'VERSION(1) SORTING(Grp,LT Quantity)');
        Observer.Expect('grp', 'Yes');
        Observer.Expect('qty', 'Yes');
        Observer.Expect('then_false_view', 'VERSION(1) SORTING(Grp,LT Quantity) ORDER(Descending)');
        Observer.Expect('then_false_grp', 'No');
        Observer.Expect('then_false_qty', 'No');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetAscendingNote(var Row: Record "LT SA Row")
    begin
        Row.SetAscending(Note, false);
    end;

    [TryFunction]
    local procedure TrySetAscendingQtyOnPrimaryKey(var Row: Record "LT SA Row")
    begin
        Row.SetAscending(Qty, false);
    end;

    [Test]
    procedure SetAscending_FieldOutsideTheKey_ErrorText()
    var
        Row: Record "LT SA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetCurrentKey(Grp, Qty);
        ClearLastError();
        Observer.Observe('note_outcome', Format(TrySetAscendingNote(Row)));
        Observer.ObserveError('note');
        Row.Reset();
        ClearLastError();
        Observer.Observe('qty_on_primary_key_outcome', Format(TrySetAscendingQtyOnPrimaryKey(Row)));
        Observer.ObserveError('qty_on_primary_key');
        Observer.Expect('note_outcome', 'No');
        Observer.Expect('note|text', 'Cannot call SetAscending on field Note because it is not part of the current sorting.');
        Observer.Expect('note|code', 'DB:Ok');
        Observer.Expect('qty_on_primary_key_outcome', 'No');
        Observer.Expect('qty_on_primary_key|text', 'Cannot call SetAscending on field Qty because it is not part of the current sorting.');
        Observer.Expect('qty_on_primary_key|code', 'DB:Ok');
        Observer.Verify();
    end;
}
