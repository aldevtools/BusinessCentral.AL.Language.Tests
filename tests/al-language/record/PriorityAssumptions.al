// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 74467 and 74468, logs 74469, workers 74470 and 74471, test codeunit 74472
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: (1) two record variables read the same row; one Modify() with no field changed and a Commit, then the other variable changes a field and Modifies: accepted or the RecordChanged error (text and code), and the same after a Modify that changes a field; (3) ClearAll() on a codeunit with a global temporary record that holds a row and a filter: Count and GetFilters afterwards, called directly and through Codeunit.Run; (4) SetLoadFields and AddLoadFields with a FlowField and with a normal field, then FindFirst and AreFieldsLoaded.
// BC versions: 29 (27 and 28 by CI)

table 74467 "LT PA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT PA Child" where(ParentId = field(Id)));
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 74468 "LT PA Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74469 "LT PA Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 74470 "LT PA Clear Worker"
{
    trigger OnRun()
    begin
        Fill();
        ClearAll();
        Report();
    end;

    var
        Tmp: Record "LT PA Row" temporary;

    procedure Fill()
    begin
        Tmp.Id := 1;
        Tmp.Name := 'a';
        Tmp.Insert();
        Tmp.Id := 2;
        Tmp.Name := 'b';
        Tmp.Insert();
        Tmp.SetRange(Id, 1);
    end;

    procedure ClearGlobals()
    begin
        ClearAll();
    end;

    procedure Report()
    var
        L: Codeunit "LT PA Log";
    begin
        L.Add('count=' + Format(Tmp.Count()) + ' filters=[' + Tmp.GetFilters() + '] temporary=' + Format(Tmp.IsTemporary()));
    end;
}

codeunit 74471 "LT PA Clear Run Worker"
{
    trigger OnRun()
    begin
        Tmp.Id := 5;
        Tmp.Insert();
        Tmp.SetRange(Id, 5);
        ClearAll();
        L.Add('run count=' + Format(Tmp.Count()) + ' filters=[' + Tmp.GetFilters() + ']');
    end;

    var
        Tmp: Record "LT PA Row" temporary;
        L: Codeunit "LT PA Log";
}

codeunit 74472 "LT Priority Assumptions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT PA Row";
        Child: Record "LT PA Child";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        Row.Id := 1; Row.Name := 'one'; Row.Qty := 5; Row.Insert();
        Child.Id := 1; Child.ParentId := 1; Child.Insert();
        Child.Id := 2; Child.ParentId := 1; Child.Insert();
        Commit();
    end;

    local procedure ModifyResult(var Row: Record "LT PA Row"): Text
    var
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Row.Modify();
        if Ok then
            exit('accepted');
        exit('refused|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    [Test]
    procedure Modify_NoChangeByOther_ThenChange()
    var
        First: Record "LT PA Row";
        Second: Record "LT PA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        First.Get(1);
        Second.Get(1);
        First.Modify();
        Commit();
        Second.Qty := 9;
        Observer.Observe('second_modify', ModifyResult(Second));
        Second.Get(1);
        Observer.Observe('qty_after', Format(Second.Qty));
        Observer.Expect('second_modify', 'accepted');
        Observer.Expect('qty_after', '9');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_ChangeByOther_ThenChange()
    var
        First: Record "LT PA Row";
        Second: Record "LT PA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        First.Get(1);
        Second.Get(1);
        First.Qty := 7;
        First.Modify();
        Commit();
        Second.Qty := 9;
        asserterror Second.Modify();
        Observer.ObserveError('second_modify');
        Second.Get(1);
        Observer.Observe('qty_after', Format(Second.Qty));
        Observer.Expect('second_modify|text', 'The changes to the LT PA Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Id=''1''');
        Observer.Expect('second_modify|code', 'DB:RecordChanged');
        Observer.Expect('qty_after', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_ChangeByOther_ThenNoChange()
    var
        First: Record "LT PA Row";
        Second: Record "LT PA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        First.Get(1);
        Second.Get(1);
        First.Qty := 7;
        First.Modify();
        Commit();
        asserterror Second.Modify();
        Observer.ObserveError('second_modify_unchanged');
        Second.Get(1);
        Observer.Observe('qty_after', Format(Second.Qty));
        Observer.Expect('second_modify_unchanged|text', 'The changes to the LT PA Row record cannot be saved because some information on the page is not up-to-date. Close the page, reopen it, and try again.\\Identification fields and values:\\Id=''1''');
        Observer.Expect('second_modify_unchanged|code', 'DB:RecordChanged');
        Observer.Expect('qty_after', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_NoChangeByOther_ThenNoChange()
    var
        First: Record "LT PA Row";
        Second: Record "LT PA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        First.Get(1);
        Second.Get(1);
        First.Modify();
        Commit();
        Observer.Observe('second_modify_unchanged', ModifyResult(Second));
        Observer.Expect('second_modify_unchanged', 'accepted');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_SameValueAssignedByOther_ThenChange()
    var
        First: Record "LT PA Row";
        Second: Record "LT PA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        First.Get(1);
        Second.Get(1);
        First.Qty := 5;
        First.Modify();
        Commit();
        Second.Qty := 9;
        Observer.Observe('second_modify', ModifyResult(Second));
        Observer.Expect('second_modify', 'accepted');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_TemporaryGlobalRecord_DirectCall()
    var
        W: Codeunit "LT PA Clear Worker";
        L: Codeunit "LT PA Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        W.Fill();
        W.Report();
        Observer.Observe('before', L.Take());
        W.ClearGlobals();
        W.Report();
        Observer.Observe('after', L.Take());
        Observer.Expect('before', 'count=1 filters=[Id: 1] temporary=Yes;');
        Observer.Expect('after', 'count=2 filters=[] temporary=Yes;');
        Observer.Verify();
    end;

    [Test]
    procedure ClearAll_TemporaryGlobalRecord_ThroughCodeunitRun()
    var
        L: Codeunit "LT PA Log";
        Observer: Codeunit "Probe Observer";
    begin
        L.Take();
        Codeunit.Run(Codeunit::"LT PA Clear Worker");
        Observer.Observe('run_worker', L.Take());
        Codeunit.Run(Codeunit::"LT PA Clear Run Worker");
        Observer.Observe('run_second_worker', L.Take());
        Observer.Expect('run_worker', 'count=2 filters=[] temporary=Yes;');
        Observer.Expect('run_second_worker', 'run count=1 filters=[];');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_FlowFieldAndNormal()
    var
        Row: Record "LT PA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetLoadFields(Cnt);
        Row.FindFirst();
        Observer.Observe('flow_only_name_loaded', Format(Row.AreFieldsLoaded(Name)));
        Observer.Observe('flow_only_qty_loaded', Format(Row.AreFieldsLoaded(Qty)));
        Observer.Observe('flow_only_cnt_loaded', Format(Row.AreFieldsLoaded(Cnt)));
        Observer.Observe('flow_only_id_loaded', Format(Row.AreFieldsLoaded(Id)));
        Observer.Observe('flow_only_name', Row.Name);
        Clear(Row);
        Row.SetLoadFields(Name, Cnt);
        Row.FindFirst();
        Observer.Observe('mixed_name_loaded', Format(Row.AreFieldsLoaded(Name)));
        Observer.Observe('mixed_qty_loaded', Format(Row.AreFieldsLoaded(Qty)));
        Observer.Observe('mixed_cnt_loaded', Format(Row.AreFieldsLoaded(Cnt)));
        Observer.Observe('mixed_all', Format(Row.AreFieldsLoaded(Name, Cnt)));
        Observer.Expect('flow_only_name_loaded', 'No');
        Observer.Expect('flow_only_qty_loaded', 'No');
        Observer.Expect('flow_only_cnt_loaded', 'Yes');
        Observer.Expect('flow_only_id_loaded', 'Yes');
        Observer.Expect('flow_only_name', 'one');
        Observer.Expect('mixed_name_loaded', 'Yes');
        Observer.Expect('mixed_qty_loaded', 'No');
        Observer.Expect('mixed_cnt_loaded', 'Yes');
        Observer.Expect('mixed_all', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AddLoadFields_FlowFieldAndNormal()
    var
        Row: Record "LT PA Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.SetLoadFields(Name);
        asserterror Row.AddLoadFields(Cnt);
        Observer.ObserveError('add_flow_after_set');
        Clear(Row);
        asserterror Row.AddLoadFields(Cnt);
        Observer.ObserveError('add_flow_only');
        Clear(Row);
        Row.SetLoadFields(Name);
        Row.AddLoadFields(Qty);
        Row.FindFirst();
        Observer.Observe('name_loaded', Format(Row.AreFieldsLoaded(Name)));
        Observer.Observe('qty_loaded', Format(Row.AreFieldsLoaded(Qty)));
        Observer.Observe('cnt_loaded', Format(Row.AreFieldsLoaded(Cnt)));
        Observer.Expect('add_flow_after_set|text', 'The field ''Cnt'' in the ''LT PA Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('add_flow_after_set|code', 'DB:Ok');
        Observer.Expect('add_flow_only|text', 'The field ''Cnt'' in the ''LT PA Row'' table is not valid for auto loading and cannot be passed to calls to AddLoadFields, SetLoadFields, or LoadFields.');
        Observer.Expect('add_flow_only|code', 'DB:Ok');
        Observer.Expect('name_loaded', 'Yes');
        Observer.Expect('qty_loaded', 'Yes');
        Observer.Expect('cnt_loaded', 'Yes');
        Observer.Verify();
    end;
}
