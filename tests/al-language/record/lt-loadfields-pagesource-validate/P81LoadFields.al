// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setloadfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 70301, 70302 and codeunit 70303
// Probe: written against BC 29 (tag P81, GitHub issue 81); every literal asserted later is what a local BC 29 tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetLoadFields / AddLoadFields with a FlowField, a FlowFilter field, a Blob, a Media and the system fields; AreFieldsLoaded, the values read, CalcFields on them, Modify afterwards
// BC versions: 29 (27 and 28 by CI)

table 70301 "LT P81 LF Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Parent Code"; Code[10]) { }
        field(3; Kind; Code[10]) { }
        field(4; Amount; Decimal) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 70302 "LT P81 LF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Notes; Blob) { }
        field(5; Pic; Media) { }
        field(6; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT P81 LF Child" where("Parent Code" = field(Code), Kind = field("Kind Filter")));
        }
        field(7; "Kind Filter"; Code[10]) { FieldClass = FlowFilter; }
        field(8; "Sum Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT P81 LF Child".Amount where("Parent Code" = field(Code)));
        }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 70303 "LT P81 LoadFields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P81 LF Row";
        Child: Record "LT P81 LF Child";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        Row.Init();
        Row.Code := 'A';
        Row.Name := 'alpha';
        Row.Qty := 7;
        SetNotes(Row, 'blob-a');
        Row.Insert();
        Row.Init();
        Row.Code := 'B';
        Row.Name := 'bravo';
        Row.Qty := 8;
        Row.Insert();
        Child.Init();
        Child."Entry No." := 1;
        Child."Parent Code" := 'A';
        Child.Kind := 'X';
        Child.Amount := 10;
        Child.Insert();
        Child.Init();
        Child."Entry No." := 2;
        Child."Parent Code" := 'A';
        Child.Kind := 'Y';
        Child.Amount := 20;
        Child.Insert();
    end;

    local procedure SetNotes(var Row: Record "LT P81 LF Row"; Txt: Text)
    var
        OutS: OutStream;
    begin
        Row.Notes.CreateOutStream(OutS);
        OutS.WriteText(Txt);
    end;

    local procedure GetNotes(var Row: Record "LT P81 LF Row"): Text
    var
        InS: InStream;
        T: Text;
    begin
        if not Row.Notes.HasValue() then
            exit('<empty>');
        Row.Notes.CreateInStream(InS);
        InS.ReadText(T);
        exit(T);
    end;

    [TryFunction]
    local procedure TryLoaded(var Row: Record "LT P81 LF Row"; Which: Integer; var R: Boolean)
    begin
        case Which of
            1:
                R := Row.AreFieldsLoaded(Row.Code);
            2:
                R := Row.AreFieldsLoaded(Row.Name);
            3:
                R := Row.AreFieldsLoaded(Row.Qty);
            4:
                R := Row.AreFieldsLoaded(Row.Notes);
            5:
                R := Row.AreFieldsLoaded(Row.Pic);
            6:
                R := Row.AreFieldsLoaded(Row.Cnt);
            7:
                R := Row.AreFieldsLoaded(Row."Kind Filter");
            8:
                R := Row.AreFieldsLoaded(Row."Sum Amount");
            9:
                R := Row.AreFieldsLoaded(Row.SystemId);
            10:
                R := Row.AreFieldsLoaded(Row.SystemCreatedAt);
            11:
                R := Row.AreFieldsLoaded(Row.SystemModifiedAt);
            12:
                R := Row.AreFieldsLoaded(Row.SystemCreatedBy);
            13:
                R := Row.AreFieldsLoaded(Row.SystemModifiedBy);
        end;
    end;

    local procedure Loaded(var Row: Record "LT P81 LF Row"; Which: Integer): Text
    var
        R: Boolean;
    begin
        if TryLoaded(Row, Which, R) then
            exit(Format(R));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ObserveLoaded(var Observer: Codeunit "Probe Observer"; var Row: Record "LT P81 LF Row"; Prefix: Text)
    var
        Names: List of [Text];
        i: Integer;
    begin
        Names.Add('Code');
        Names.Add('Name');
        Names.Add('Qty');
        Names.Add('Notes');
        Names.Add('Pic');
        Names.Add('Cnt');
        Names.Add('KindFilter');
        Names.Add('SumAmount');
        Names.Add('SystemId');
        Names.Add('SystemCreatedAt');
        Names.Add('SystemModifiedAt');
        Names.Add('SystemCreatedBy');
        Names.Add('SystemModifiedBy');
        for i := 1 to Names.Count() do
            Observer.Observe(Prefix + '_loaded_' + Names.Get(i), Loaded(Row, i));
    end;

    [Test]
    procedure LoadFields_Name_Get_LoadedFlags()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('name', Row.Name);
        Observer.Observe('qty', Format(Row.Qty));
        Observer.Observe('code', Row.Code);
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'Yes');
        Observer.Expect('a_loaded_Qty', 'No');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'No');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('name', 'alpha');
        Observer.Expect('qty', '7');
        Observer.Expect('code', 'A');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FlowField_ReadThenCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Cnt);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('cnt_before', Format(Row.Cnt));
        Observer.Observe('name', Row.Name);
        Row.CalcFields(Cnt);
        Observer.Observe('cnt_after', Format(Row.Cnt));
        Observer.Observe('loaded_cnt_after', Loaded(Row, 6));
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'No');
        Observer.Expect('a_loaded_Qty', 'No');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'No');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('cnt_before', '0');
        Observer.Expect('name', 'alpha');
        Observer.Expect('cnt_after', '2');
        Observer.Expect('loaded_cnt_after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FlowFieldSum_Find()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields("Sum Amount");
        Row.SetRange(Code, 'A');
        Row.FindFirst();
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('sum_before', Format(Row."Sum Amount"));
        Row.CalcFields("Sum Amount");
        Observer.Observe('sum_after', Format(Row."Sum Amount"));
        Observer.Observe('name', Row.Name);
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'No');
        Observer.Expect('a_loaded_Qty', 'No');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'No');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('sum_before', '0');
        Observer.Expect('sum_after', '30');
        Observer.Expect('name', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FlowFilterField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields("Kind Filter");
        Row.SetRange("Kind Filter", 'X');
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('filter', Row.GetFilter("Kind Filter"));
        Row.CalcFields(Cnt);
        Observer.Observe('cnt_x', Format(Row.Cnt));
        Observer.Observe('loaded_cnt_after', Loaded(Row, 6));
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'No');
        Observer.Expect('a_loaded_Qty', 'No');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'No');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('filter', 'X');
        Observer.Expect('cnt_x', '1');
        Observer.Expect('loaded_cnt_after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FlowFieldAndFlowFilter_Together()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Cnt, "Kind Filter");
        Row.SetRange("Kind Filter", 'Y');
        Row.Get('A');
        Observer.Observe('loaded_cnt', Loaded(Row, 6));
        Observer.Observe('loaded_kindfilter', Loaded(Row, 7));
        Observer.Observe('loaded_name', Loaded(Row, 2));
        Row.CalcFields(Cnt);
        Observer.Observe('cnt_y', Format(Row.Cnt));
        Row.SetRange("Kind Filter", 'Z');
        Row.CalcFields(Cnt);
        Observer.Observe('cnt_z', Format(Row.Cnt));
        Row.SetRange("Kind Filter");
        Row.CalcFields(Cnt);
        Observer.Observe('cnt_all', Format(Row.Cnt));
        Observer.Expect('loaded_cnt', 'Yes');
        Observer.Expect('loaded_kindfilter', 'Yes');
        Observer.Expect('loaded_name', 'No');
        Observer.Expect('cnt_y', '1');
        Observer.Expect('cnt_z', '0');
        Observer.Expect('cnt_all', '2');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Blob_ReadAndCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Notes);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('hasvalue_before', Format(Row.Notes.HasValue()));
        Row.CalcFields(Notes);
        Observer.Observe('hasvalue_after', Format(Row.Notes.HasValue()));
        Observer.Observe('text', GetNotes(Row));
        Observer.Observe('name', Row.Name);
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'No');
        Observer.Expect('a_loaded_Qty', 'No');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'No');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('hasvalue_before', 'Yes');
        Observer.Expect('hasvalue_after', 'Yes');
        Observer.Expect('text', 'blob-a');
        Observer.Expect('name', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_BlobNotLoaded_CalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Observer.Observe('loaded_notes_before', Loaded(Row, 4));
        Observer.Observe('hasvalue_before', Format(Row.Notes.HasValue()));
        Row.CalcFields(Notes);
        Observer.Observe('loaded_notes_after', Loaded(Row, 4));
        Observer.Observe('hasvalue_after', Format(Row.Notes.HasValue()));
        Observer.Observe('text', GetNotes(Row));
        Observer.Expect('loaded_notes_before', 'Yes');
        Observer.Expect('hasvalue_before', 'Yes');
        Observer.Expect('loaded_notes_after', 'Yes');
        Observer.Expect('hasvalue_after', 'Yes');
        Observer.Expect('text', 'blob-a');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_Media_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Pic);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('pic_hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('pic_mediaid_null', Format(IsNullGuid(Row.Pic.MediaId())));
        Observer.Observe('name', Row.Name);
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'No');
        Observer.Expect('a_loaded_Qty', 'No');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'Yes');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('pic_hasvalue', 'No');
        Observer.Expect('pic_mediaid_null', 'Yes');
        Observer.Expect('name', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_MediaNotLoaded()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Observer.Observe('loaded_pic', Loaded(Row, 5));
        Observer.Observe('pic_hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('pic_mediaid_null', Format(IsNullGuid(Row.Pic.MediaId())));
        asserterror Row.CalcFields(Pic);
        Observer.ObserveError('af329');
        Observer.Observe('loaded_pic_after_calc', Loaded(Row, 5));
        Observer.Expect('loaded_pic', 'No');
        Observer.Expect('pic_hasvalue', 'No');
        Observer.Expect('pic_mediaid_null', 'Yes');
        Observer.Expect('af329|text', 'The Pic field in the LT P81 LF Row table must be a FlowField.');
        Observer.Expect('af329|code', 'DB:Ok');
        Observer.Expect('loaded_pic_after_calc', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_SystemId_Only()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Full.Get('A');
        Row.SetLoadFields(SystemId);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('systemid_null', Format(IsNullGuid(Row.SystemId)));
        Observer.Observe('systemid_equals_full', Format(Row.SystemId = Full.SystemId));
        Observer.Observe('name', Row.Name);
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'Yes');
        Observer.Expect('a_loaded_Qty', 'Yes');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'Yes');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('systemid_null', 'No');
        Observer.Expect('systemid_equals_full', 'Yes');
        Observer.Expect('name', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_SystemTimestamps_Only()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Full.Get('A');
        Row.SetLoadFields(SystemCreatedAt, SystemModifiedAt);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('createdat_zero', Format(Row.SystemCreatedAt = 0DT));
        Observer.Observe('modifiedat_ge_createdat', Format(Row.SystemModifiedAt >= Row.SystemCreatedAt));
        Observer.Observe('createdat_equals_full', Format(Row.SystemCreatedAt = Full.SystemCreatedAt));
        Observer.Observe('createdby_null', Format(IsNullGuid(Row.SystemCreatedBy)));
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'Yes');
        Observer.Expect('a_loaded_Qty', 'Yes');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'Yes');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('createdat_zero', 'No');
        Observer.Expect('modifiedat_ge_createdat', 'Yes');
        Observer.Expect('createdat_equals_full', 'Yes');
        Observer.Expect('createdby_null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_SystemCreatedBy_Only()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Full.Get('A');
        Row.SetLoadFields(SystemCreatedBy, SystemModifiedBy);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('createdby_equals_full', Format(Row.SystemCreatedBy = Full.SystemCreatedBy));
        Observer.Observe('modifiedby_equals_full', Format(Row.SystemModifiedBy = Full.SystemModifiedBy));
        Observer.Observe('systemid_null', Format(IsNullGuid(Row.SystemId)));
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'Yes');
        Observer.Expect('a_loaded_Qty', 'Yes');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'Yes');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('createdby_equals_full', 'Yes');
        Observer.Expect('modifiedby_equals_full', 'Yes');
        Observer.Expect('systemid_null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AddLoadFields_WithoutSetLoadFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.AddLoadFields(Qty);
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Observe('name', Row.Name);
        Observer.Observe('qty', Format(Row.Qty));
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'Yes');
        Observer.Expect('a_loaded_Qty', 'Yes');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'Yes');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('name', 'alpha');
        Observer.Expect('qty', '7');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_Empty_ResetsToAllFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.SetLoadFields();
        Row.Get('A');
        ObserveLoaded(Observer, Row, 'a');
        Observer.Expect('a_loaded_Code', 'Yes');
        Observer.Expect('a_loaded_Name', 'Yes');
        Observer.Expect('a_loaded_Qty', 'Yes');
        Observer.Expect('a_loaded_Notes', 'Yes');
        Observer.Expect('a_loaded_Pic', 'Yes');
        Observer.Expect('a_loaded_Cnt', 'Yes');
        Observer.Expect('a_loaded_KindFilter', 'Yes');
        Observer.Expect('a_loaded_SumAmount', 'Yes');
        Observer.Expect('a_loaded_SystemId', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('a_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('a_loaded_SystemModifiedBy', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_AfterGet_AppliesToNextRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.Get('A');
        Observer.Observe('full_loaded_qty', Loaded(Row, 3));
        Row.SetLoadFields(Name);
        Observer.Observe('after_set_loaded_qty', Loaded(Row, 3));
        Row.Get('B');
        Observer.Observe('b_name', Row.Name);
        Observer.Observe('b_qty', Format(Row.Qty));
        Observer.Observe('b_loaded_qty', Loaded(Row, 3));
        Observer.Observe('b_loaded_name', Loaded(Row, 2));
        Observer.Expect('full_loaded_qty', 'Yes');
        Observer.Expect('after_set_loaded_qty', 'Yes');
        Observer.Expect('b_name', 'bravo');
        Observer.Expect('b_qty', '8');
        Observer.Expect('b_loaded_qty', 'Yes');
        Observer.Expect('b_loaded_name', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_FindSet_Loop()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        n: Integer;
    begin
        Seed();
        Row.SetLoadFields(Name, Cnt);
        if Row.FindSet() then
            repeat
                n += 1;
                Row.CalcFields(Cnt);
                Observer.Observe('row' + Format(n) + '_name', Row.Name);
                Observer.Observe('row' + Format(n) + '_qty', Format(Row.Qty));
                Observer.Observe('row' + Format(n) + '_cnt', Format(Row.Cnt));
            until Row.Next() = 0;
        Observer.Observe('rows', Format(n));
        Observer.Expect('row1_name', 'alpha');
        Observer.Expect('row1_qty', '7');
        Observer.Expect('row1_cnt', '2');
        Observer.Expect('row2_name', 'bravo');
        Observer.Expect('row2_qty', '8');
        Observer.Expect('row2_cnt', '0');
        Observer.Expect('rows', '2');
        Observer.Verify();
    end;

    [Test]
    procedure CalcFields_OnNotLoadedFlowAndBlob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Row.CalcFields(Cnt, "Sum Amount", Notes);
        Observer.Observe('cnt', Format(Row.Cnt));
        Observer.Observe('sum', Format(Row."Sum Amount"));
        Observer.Observe('notes', GetNotes(Row));
        Observer.Observe('loaded_cnt', Loaded(Row, 6));
        Observer.Observe('loaded_sum', Loaded(Row, 8));
        Observer.Observe('loaded_notes', Loaded(Row, 4));
        Observer.Observe('loaded_qty', Loaded(Row, 3));
        Observer.Expect('cnt', '2');
        Observer.Expect('sum', '30');
        Observer.Expect('notes', 'blob-a');
        Observer.Expect('loaded_cnt', 'Yes');
        Observer.Expect('loaded_sum', 'Yes');
        Observer.Expect('loaded_notes', 'Yes');
        Observer.Expect('loaded_qty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_AfterPartialLoad_KeepsUnloadedFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Row.Name := 'beta';
        Row.Modify();
        Full.Get('A');
        Full.CalcFields(Cnt, Notes);
        Observer.Observe('name', Full.Name);
        Observer.Observe('qty', Format(Full.Qty));
        Observer.Observe('notes', GetNotes(Full));
        Observer.Observe('cnt', Format(Full.Cnt));
        Observer.Expect('name', 'beta');
        Observer.Expect('qty', '7');
        Observer.Expect('notes', 'blob-a');
        Observer.Expect('cnt', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_AfterLoadingOnlyFlowField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Cnt);
        Row.Get('A');
        Row.CalcFields(Cnt);
        Row.Modify();
        Full.Get('A');
        Observer.Observe('name', Full.Name);
        Observer.Observe('qty', Format(Full.Qty));
        Observer.Observe('row_name_in_buffer', Row.Name);
        Observer.Expect('name', 'alpha');
        Observer.Expect('qty', '7');
        Observer.Expect('row_name_in_buffer', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_AfterLoadingOnlyBlob_NewText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Notes);
        Row.Get('A');
        Row.CalcFields(Notes);
        SetNotes(Row, 'blob-new');
        Row.Modify();
        Full.Get('A');
        Full.CalcFields(Notes);
        Observer.Observe('notes', GetNotes(Full));
        Observer.Observe('name', Full.Name);
        Observer.Observe('qty', Format(Full.Qty));
        Observer.Expect('notes', 'blob-new');
        Observer.Expect('name', 'alpha');
        Observer.Expect('qty', '7');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_AssignUnloadedField_ThenModify()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Row.Qty := 99;
        Row.Modify();
        Full.Get('A');
        Observer.Observe('name', Full.Name);
        Observer.Observe('qty', Format(Full.Qty));
        Observer.Expect('name', 'alpha');
        Observer.Expect('qty', '99');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_WithSystemFieldsLoaded_Timestamps()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        Full: Record "LT P81 LF Row";
        CreatedBefore: DateTime;
    begin
        Seed();
        Full.Get('A');
        CreatedBefore := Full.SystemCreatedAt;
        Row.SetLoadFields(SystemId, SystemModifiedAt, Name);
        Row.Get('A');
        Row.Name := 'gamma';
        Row.Modify();
        Full.Get('A');
        Observer.Observe('name', Full.Name);
        Observer.Observe('created_unchanged', Format(Full.SystemCreatedAt = CreatedBefore));
        Observer.Observe('modified_ge_created', Format(Full.SystemModifiedAt >= Full.SystemCreatedAt));
        Observer.Observe('systemid_same', Format(Row.SystemId = Full.SystemId));
        Observer.Expect('name', 'gamma');
        Observer.Expect('created_unchanged', 'Yes');
        Observer.Expect('modified_ge_created', 'Yes');
        Observer.Expect('systemid_same', 'Yes');
        Observer.Verify();
    end;

    // Corpus issue 668 items 41-44 (writer br): fields loaded besides the requested ones (relation and formula fields, extension fields),
    // validation of a relation field whose condition field is not loaded, and the return value of SetLoadFields / AddLoadFields for a
    // FlowField and a FlowFilter field.
    local procedure BrSeed()
    var
        Target: Record "LT BR LF Target";
        Other: Record "LT BR LF Other";
        Row: Record "LT BR LF Row";
    begin
        Target.DeleteAll();
        Other.DeleteAll();
        Row.DeleteAll();
        Target."No." := 'T1';
        Target.Kind := 'G1';
        Target.Insert();
        Target."No." := 'T2';
        Target.Kind := 'G2';
        Target.Insert();
        Other."No." := 'O1';
        Other.Insert();
        Row.Init();
        Row.Id := 1;
        Row.Kind := Row.Kind::Other;
        Row."No." := 'O1';
        Row.Grp := 'G1';
        Row.Note := 'note one';
        Row.RelFiltered := 'T1';
        Row.ExtNote := 'ext one';
        Row.ExtRel := '';
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Kind := Row.Kind::Target;
        Row."No." := 'T2';
        Row.Grp := 'G2';
        Row.Note := 'note two';
        Row.ExtNote := 'ext two';
        Row.ExtRel := 'T2';
        Row.Insert();
    end;

    local procedure BrLoaded(var Row: Record "LT BR LF Row"): Text
    begin
        exit(
            'Kind=' + Format(Row.AreFieldsLoaded(Row.Kind)) +
            ' No=' + Format(Row.AreFieldsLoaded(Row."No.")) +
            ' Grp=' + Format(Row.AreFieldsLoaded(Row.Grp)) +
            ' Cnt=' + Format(Row.AreFieldsLoaded(Row.Cnt)) +
            ' Note=' + Format(Row.AreFieldsLoaded(Row.Note)) +
            ' RelFiltered=' + Format(Row.AreFieldsLoaded(Row.RelFiltered)) +
            ' ExtNote=' + Format(Row.AreFieldsLoaded(Row.ExtNote)) +
            ' ExtRel=' + Format(Row.AreFieldsLoaded(Row.ExtRel)));
    end;

    [Test]
    procedure BR_LoadFields_RelationAndFormulaFields_WhatElseIsLoaded()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BR LF Row";
    begin
        BrSeed();
        Row.SetLoadFields(Note);
        Row.FindFirst();
        Observer.Observe('note only', BrLoaded(Row));
        Clear(Row);
        Row.SetLoadFields(Cnt);
        Row.FindFirst();
        Observer.Observe('flowfield using Grp', BrLoaded(Row));
        Clear(Row);
        Row.SetLoadFields("No.");
        Row.FindFirst();
        Observer.Observe('conditional relation on Kind', BrLoaded(Row));
        Clear(Row);
        Row.SetLoadFields(RelFiltered);
        Row.FindFirst();
        Observer.Observe('relation filtered by Grp', BrLoaded(Row));
        Clear(Row);
        Row.SetLoadFields(ExtRel);
        Row.Get(2);
        Observer.Observe('extension relation field', BrLoaded(Row));
        Clear(Row);
        Row.SetLoadFields(ExtNote);
        Row.Get(2);
        Observer.Observe('extension text field', BrLoaded(Row));
        Observer.Expect('note only', 'Kind=Yes No=No Grp=Yes Cnt=Yes Note=Yes RelFiltered=No ExtNote=No ExtRel=No');
        Observer.Expect('flowfield using Grp', 'Kind=Yes No=No Grp=Yes Cnt=Yes Note=No RelFiltered=No ExtNote=No ExtRel=No');
        Observer.Expect('conditional relation on Kind', 'Kind=Yes No=Yes Grp=Yes Cnt=Yes Note=No RelFiltered=No ExtNote=No ExtRel=No');
        Observer.Expect('relation filtered by Grp', 'Kind=Yes No=No Grp=Yes Cnt=Yes Note=No RelFiltered=Yes ExtNote=No ExtRel=No');
        Observer.Expect('extension relation field', 'Kind=Yes No=No Grp=Yes Cnt=Yes Note=No RelFiltered=No ExtNote=No ExtRel=Yes');
        Observer.Expect('extension text field', 'Kind=Yes No=No Grp=Yes Cnt=Yes Note=No RelFiltered=No ExtNote=Yes ExtRel=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure BR_LoadFields_ValidateRelationField_ConditionFieldNotLoaded()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BR LF Row";
    begin
        BrSeed();
        Row.SetLoadFields(Note);
        Row.Get(1);
        Observer.Observe('before', BrLoaded(Row));
        ClearLastError();
        if TryValidateNo(Row, 'O1') then
            Observer.Observe('validate O1 on Kind Other', 'ok|' + Row."No.")
        else
            Observer.Observe('validate O1 on Kind Other', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('after', BrLoaded(Row));
        Clear(Row);
        Row.SetLoadFields(Note);
        Row.Get(2);
        ClearLastError();
        if TryValidateNo(Row, 'T1') then
            Observer.Observe('validate T1 on Kind Target', 'ok|' + Row."No.")
        else
            Observer.Observe('validate T1 on Kind Target', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryValidateNo(Row, 'O1') then
            Observer.Observe('validate O1 on Kind Target', 'ok|' + Row."No.")
        else
            Observer.Observe('validate O1 on Kind Target', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        Clear(Row);
        Row.SetLoadFields(Note);
        Row.Get(1);
        ClearLastError();
        if TryValidateRelFiltered(Row, 'T1') then
            Observer.Observe('validate RelFiltered T1 Grp G1', 'ok|' + Row.RelFiltered)
        else
            Observer.Observe('validate RelFiltered T1 Grp G1', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryValidateRelFiltered(Row, 'T2') then
            Observer.Observe('validate RelFiltered T2 Grp G1', 'ok|' + Row.RelFiltered)
        else
            Observer.Observe('validate RelFiltered T2 Grp G1', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('after relfiltered', BrLoaded(Row));
        Observer.Expect('before', 'Kind=Yes No=No Grp=Yes Cnt=Yes Note=Yes RelFiltered=No ExtNote=No ExtRel=No');
        Observer.Expect('validate O1 on Kind Other', 'ok|O1');
        Observer.Expect('after', 'Kind=Yes No=Yes Grp=Yes Cnt=Yes Note=Yes RelFiltered=Yes ExtNote=Yes ExtRel=Yes');
        Observer.Expect('validate T1 on Kind Target', 'ok|T1');
        Observer.Expect('validate O1 on Kind Target', 'error|The field No. of table LT BR LF Row contains a value (O1) that cannot be found in the related table (LT BR LF Target).|DB:PrimRecordNotFound');
        Observer.Expect('validate RelFiltered T1 Grp G1', 'ok|T1');
        Observer.Expect('validate RelFiltered T2 Grp G1', 'error|The field RelFiltered of table LT BR LF Row contains a value (T2) that cannot be found in the related table (LT BR LF Target).|DB:NothingInsideFilter');
        Observer.Expect('after relfiltered', 'Kind=Yes No=Yes Grp=Yes Cnt=Yes Note=Yes RelFiltered=Yes ExtNote=Yes ExtRel=Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryValidateNo(var Row: Record "LT BR LF Row"; NewNo: Code[20])
    begin
        Row.Validate("No.", NewNo);
    end;

    [TryFunction]
    local procedure TryValidateRelFiltered(var Row: Record "LT BR LF Row"; NewNo: Code[20])
    begin
        Row.Validate(RelFiltered, NewNo);
    end;

    [TryFunction]
    local procedure TryAddLoadFieldsResult(var Row: Record "LT BR LF Row"; Which: Integer; var Ok: Boolean)
    begin
        case Which of
            1:
                Ok := Row.AddLoadFields(Cnt);
            2:
                Ok := Row.AddLoadFields(KindFilter);
            3:
                Ok := Row.AddLoadFields(Note);
        end;
    end;

    local procedure AddResult(var Row: Record "LT BR LF Row"; Which: Integer): Text
    var
        Ok: Boolean;
    begin
        ClearLastError();
        if TryAddLoadFieldsResult(Row, Which, Ok) then
            exit('ok|' + Format(Ok));
        exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure BR_SetLoadFields_ReturnValue_FlowFieldAndFlowFilter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BR LF Row";
        Ok: Boolean;
    begin
        BrSeed();
        Ok := Row.SetLoadFields(Cnt);
        Observer.Observe('set flowfield', Format(Ok));
        Row.FindFirst();
        Observer.Observe('set flowfield loaded', BrLoaded(Row));
        Clear(Row);
        Ok := Row.SetLoadFields(KindFilter);
        Observer.Observe('set flowfilter', Format(Ok));
        Clear(Row);
        Ok := Row.SetLoadFields(Note, Cnt);
        Observer.Observe('set normal and flowfield', Format(Ok));
        Clear(Row);
        Ok := Row.SetLoadFields(Note);
        Observer.Observe('set normal', Format(Ok));
        Observer.Observe('add flowfield', AddResult(Row, 1));
        Observer.Observe('add flowfilter', AddResult(Row, 2));
        Observer.Observe('add normal', AddResult(Row, 3));
        Clear(Row);
        Ok := Row.SetLoadFields();
        Observer.Observe('set none', Format(Ok));
        Observer.Expect('set flowfield', 'Yes');
        Observer.Expect('set flowfield loaded', 'Kind=Yes No=No Grp=Yes Cnt=Yes Note=No RelFiltered=No ExtNote=No ExtRel=No');
        Observer.Expect('set flowfilter', 'Yes');
        Observer.Expect('set normal and flowfield', 'Yes');
        Observer.Expect('set normal', 'Yes');
        Observer.Expect('add flowfield', 'ok|No');
        Observer.Expect('add flowfilter', 'ok|No');
        Observer.Expect('add normal', 'ok|No');
        Observer.Expect('set none', 'Yes');
        Observer.Verify();
    end;

    // Writer RN (al-runner issue 5764): reading a field that is not loaded loads which fields; Modify of a record read with
    // SetLoadFields after a second record variable (same session) changed the stored row: which fields the Modify writes.
    // Measured (BC 29.0; 27.5 and 28.5 by CI): reading one field that is not loaded loads every field; the next row (Next) loads the
    // load fields plus the field read (Name), not Qty. Modify of the partial record writes the fields it has loaded (also a loaded field
    // it did not change: the other variable's Name change is lost) and the ones assigned, keeps a stored value of a field never loaded
    // or assigned (Qty 99, the Blob), raises no error. A field read (JIT) before the other change writes the old value back (Qty 7).
    // Not asked: a change by another session (single session only).
    local procedure RnStored(): Text
    var
        Full: Record "LT P81 LF Row";
    begin
        Full.Get('A');
        Full.CalcFields(Notes);
        exit(Full.Name + '|' + Format(Full.Qty) + '|' + GetNotes(Full));
    end;

    [Test]
    procedure RN_JitRead_UnloadedField_LoadsWhich()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
        KeyOnly: Record "LT P81 LF Row";
        Q: Integer;
        N: Text;
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Q := Row.Qty;
        Observer.Observe('qty', Format(Q));
        ObserveLoaded(Observer, Row, 'name_after_qty');
        KeyOnly.SetLoadFields(Code);
        KeyOnly.FindFirst();
        ObserveLoaded(Observer, KeyOnly, 'key_before');
        N := KeyOnly.Name;
        Observer.Observe('name', N);
        ObserveLoaded(Observer, KeyOnly, 'key_after_name');
        KeyOnly.Next();
        ObserveLoaded(Observer, KeyOnly, 'key_after_next');
        Observer.Expect('qty', '7');
        Observer.Expect('name_after_qty_loaded_Code', 'Yes');
        Observer.Expect('name_after_qty_loaded_Name', 'Yes');
        Observer.Expect('name_after_qty_loaded_Qty', 'Yes');
        Observer.Expect('name_after_qty_loaded_Notes', 'Yes');
        Observer.Expect('name_after_qty_loaded_Pic', 'Yes');
        Observer.Expect('name_after_qty_loaded_Cnt', 'Yes');
        Observer.Expect('name_after_qty_loaded_KindFilter', 'Yes');
        Observer.Expect('name_after_qty_loaded_SumAmount', 'Yes');
        Observer.Expect('name_after_qty_loaded_SystemId', 'Yes');
        Observer.Expect('name_after_qty_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('name_after_qty_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('name_after_qty_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('name_after_qty_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('key_before_loaded_Code', 'Yes');
        Observer.Expect('key_before_loaded_Name', 'No');
        Observer.Expect('key_before_loaded_Qty', 'No');
        Observer.Expect('key_before_loaded_Notes', 'Yes');
        Observer.Expect('key_before_loaded_Pic', 'No');
        Observer.Expect('key_before_loaded_Cnt', 'Yes');
        Observer.Expect('key_before_loaded_KindFilter', 'Yes');
        Observer.Expect('key_before_loaded_SumAmount', 'Yes');
        Observer.Expect('key_before_loaded_SystemId', 'Yes');
        Observer.Expect('key_before_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('key_before_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('key_before_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('key_before_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('name', 'alpha');
        Observer.Expect('key_after_name_loaded_Code', 'Yes');
        Observer.Expect('key_after_name_loaded_Name', 'Yes');
        Observer.Expect('key_after_name_loaded_Qty', 'Yes');
        Observer.Expect('key_after_name_loaded_Notes', 'Yes');
        Observer.Expect('key_after_name_loaded_Pic', 'Yes');
        Observer.Expect('key_after_name_loaded_Cnt', 'Yes');
        Observer.Expect('key_after_name_loaded_KindFilter', 'Yes');
        Observer.Expect('key_after_name_loaded_SumAmount', 'Yes');
        Observer.Expect('key_after_name_loaded_SystemId', 'Yes');
        Observer.Expect('key_after_name_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('key_after_name_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('key_after_name_loaded_SystemCreatedBy', 'Yes');
        Observer.Expect('key_after_name_loaded_SystemModifiedBy', 'Yes');
        Observer.Expect('key_after_next_loaded_Code', 'Yes');
        Observer.Expect('key_after_next_loaded_Name', 'Yes');
        Observer.Expect('key_after_next_loaded_Qty', 'No');
        Observer.Expect('key_after_next_loaded_Notes', 'Yes');
        Observer.Expect('key_after_next_loaded_Pic', 'No');
        Observer.Expect('key_after_next_loaded_Cnt', 'Yes');
        Observer.Expect('key_after_next_loaded_KindFilter', 'Yes');
        Observer.Expect('key_after_next_loaded_SumAmount', 'Yes');
        Observer.Expect('key_after_next_loaded_SystemId', 'Yes');
        Observer.Expect('key_after_next_loaded_SystemCreatedAt', 'Yes');
        Observer.Expect('key_after_next_loaded_SystemModifiedAt', 'Yes');
        Observer.Expect('key_after_next_loaded_SystemCreatedBy', 'Yes');
        Observer.Ignore('key_after_next_loaded_SystemModifiedBy'); // cut from the observation message, not measured
        Observer.Verify();
    end;

    [Test]
    procedure RN_StaleModify_UnloadedFieldChangedElsewhere()
    var
        Observer: Codeunit "Probe Observer";
        Partial: Record "LT P81 LF Row";
        Other: Record "LT P81 LF Row";
    begin
        Seed();
        Partial.SetLoadFields(Name);
        Partial.Get('A');
        Other.Get('A');
        Other.Qty := 99;
        Other.Modify();
        Partial.Name := 'partial';
        Observer.Observe('modify', Format(Partial.Modify()));
        Observer.Observe('stored', RnStored());
        Observer.Observe('partial_qty_loaded', Loaded(Partial, 3));
        Observer.Observe('partial_qty', Format(Partial.Qty));
        Observer.Expect('modify', 'Yes');
        Observer.Expect('stored', 'partial|99|blob-a');
        Observer.Expect('partial_qty_loaded', 'Yes');
        Observer.Expect('partial_qty', '99');
        Observer.Verify();
    end;

    [Test]
    procedure RN_StaleModify_LoadedFieldChangedElsewhere()
    var
        Observer: Codeunit "Probe Observer";
        Partial: Record "LT P81 LF Row";
        Other: Record "LT P81 LF Row";
    begin
        Seed();
        Partial.SetLoadFields(Name);
        Partial.Get('A');
        Other.Get('A');
        Other.Name := 'other';
        Other.Qty := 99;
        Other.Modify();
        Partial.Name := 'partial';
        Observer.Observe('modify', Format(Partial.Modify()));
        Observer.Observe('stored', RnStored());
        Observer.Expect('modify', 'Yes');
        Observer.Expect('stored', 'partial|99|blob-a');
        Observer.Verify();
    end;

    [Test]
    procedure RN_StaleModify_UnloadedFieldSetHere_LoadedChangedElsewhere()
    var
        Observer: Codeunit "Probe Observer";
        Partial: Record "LT P81 LF Row";
        Other: Record "LT P81 LF Row";
    begin
        Seed();
        Partial.SetLoadFields(Name);
        Partial.Get('A');
        Other.Get('A');
        Other.Name := 'other';
        Other.Modify();
        Partial.Qty := 5;
        Observer.Observe('modify', Format(Partial.Modify()));
        Observer.Observe('stored', RnStored());
        Observer.Observe('partial_name', Partial.Name);
        Observer.Expect('modify', 'Yes');
        Observer.Expect('stored', 'alpha|5|blob-a');
        Observer.Expect('partial_name', 'alpha');
        Observer.Verify();
    end;

    [Test]
    procedure RN_StaleModify_JitReadBeforeOtherChange()
    var
        Observer: Codeunit "Probe Observer";
        Partial: Record "LT P81 LF Row";
        Other: Record "LT P81 LF Row";
    begin
        Seed();
        Partial.SetLoadFields(Name);
        Partial.Get('A');
        Observer.Observe('jit_qty', Format(Partial.Qty));
        Other.Get('A');
        Other.Qty := 99;
        Other.Modify();
        Partial.Name := 'partial';
        Observer.Observe('modify', Format(Partial.Modify()));
        Observer.Observe('stored', RnStored());
        Observer.Expect('jit_qty', '7');
        Observer.Expect('modify', 'Yes');
        Observer.Expect('stored', 'partial|7|blob-a');
        Observer.Verify();
    end;

    [Test]
    procedure RN_StaleModify_JitReadAfterOtherChange()
    var
        Observer: Codeunit "Probe Observer";
        Partial: Record "LT P81 LF Row";
        Other: Record "LT P81 LF Row";
    begin
        Seed();
        Partial.SetLoadFields(Name);
        Partial.Get('A');
        Other.Get('A');
        Other.Qty := 99;
        Other.Modify();
        Observer.Observe('jit_qty', Format(Partial.Qty));
        Partial.Name := 'partial';
        Observer.Observe('modify', Format(Partial.Modify()));
        Observer.Observe('stored', RnStored());
        Observer.Expect('jit_qty', '99');
        Observer.Expect('modify', 'Yes');
        Observer.Expect('stored', 'partial|99|blob-a');
        Observer.Verify();
    end;

    [Test]
    procedure RN_StaleModify_BlobChangedElsewhere()
    var
        Observer: Codeunit "Probe Observer";
        Partial: Record "LT P81 LF Row";
        Other: Record "LT P81 LF Row";
    begin
        Seed();
        Partial.SetLoadFields(Name);
        Partial.Get('A');
        Other.Get('A');
        SetNotes(Other, 'blob-other');
        Other.Modify();
        Partial.Name := 'partial';
        Observer.Observe('modify', Format(Partial.Modify()));
        Observer.Observe('stored', RnStored());
        Observer.Expect('modify', 'Yes');
        Observer.Expect('stored', 'partial|7|blob-other');
        Observer.Verify();
    end;

    // Writer Y64 (2026-11-01, al-runner issue 6654): ModifyAll on a record variable that was fetched with SetLoadFields (a loaded and an unloaded
    // field, with and without a filter, with RunTrigger), and a read of an unloaded field after the primary key of the variable was changed since
    // the fetch (to another existing row, to a missing row), then Modify and ModifyAll on that variable.
    local procedure Y64Rows(): Text
    var
        Full: Record "LT P81 LF Row";
        Result: Text;
    begin
        if Full.FindSet() then
            repeat
                Result += Full.Code + ':' + Full.Name + ':' + Format(Full.Qty) + ';';
            until Full.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure Y64TryReadQty(var Row: Record "LT P81 LF Row"; var Q: Integer)
    begin
        Q := Row.Qty;
    end;

    local procedure Y64Qty(var Row: Record "LT P81 LF Row"): Text
    var
        Q: Integer;
    begin
        ClearLastError();
        if Y64TryReadQty(Row, Q) then
            exit(Format(Q));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Y64_ModifyAll_PartialRecord_LoadedField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.FindSet();
        Row.ModifyAll(Name, 'new value');
        Observer.Observe('rows', Y64Rows());
        Observer.Observe('var code', Row.Code);
        Observer.Observe('var name', Row.Name);
        Observer.Observe('var qty loaded', Loaded(Row, 3));
        Observer.Observe('var qty', Y64Qty(Row));
        Observer.Observe('var name after qty', Row.Name);
        Observer.Observe('next', Format(Row.Next()));
        Observer.Observe('next code name', Row.Code + ':' + Row.Name);
        Observer.Expect('rows', 'A:new value:7;B:new value:8;');
        Observer.Expect('var code', 'A');
        Observer.Expect('var name', 'alpha');
        Observer.Expect('var qty loaded', 'No');
        Observer.Expect('var qty', 'error:The field ''Name'' on table ''LT P81 LF Row'' has changed in the database between initial and JIT load. The fields causing the JIT load are: ''Qty''.\\The error may be transient if multiple users are editing the same record or permanent if the same user edits the record while keeping an old record.\\Identification values: ''Code=''A''''\    |InconsistentRead');
        Observer.Expect('var name after qty', 'alpha');
        Observer.Expect('next', '1');
        Observer.Expect('next code name', 'B:new value');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_ModifyAll_PartialRecord_UnloadedField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.FindSet();
        Row.ModifyAll(Qty, 5);
        Observer.Observe('rows', Y64Rows());
        Observer.Observe('var qty loaded', Loaded(Row, 3));
        Observer.Observe('var qty', Y64Qty(Row));
        Row.Name := 'changed';
        asserterror Row.Modify();
        Observer.ObserveError('modify');
        Observer.Expect('rows', 'A:alpha:5;B:bravo:5;');
        Observer.Expect('var qty loaded', 'No');
        Observer.Expect('var qty', '5');
        Observer.Expect('modify|text', 'Sorry, we just updated this page. Reopen it, and try again.');
        Observer.Expect('modify|code', 'DB:RecordChanged');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_ModifyAll_PartialRecord_FilterAndRunTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetRange(Code, 'B');
        Row.SetLoadFields(Name);
        Row.FindFirst();
        Row.ModifyAll(Name, 'only b', true);
        Observer.Observe('rows', Y64Rows());
        Row.SetRange(Code);
        Row.SetLoadFields(Code);
        Row.FindFirst();
        Row.ModifyAll(Qty, 3, true);
        Observer.Observe('rows after all', Y64Rows());
        Observer.Observe('var', Row.Code + ':' + Y64Qty(Row));
        Observer.Expect('rows', 'A:alpha:7;B:only b:8;');
        Observer.Expect('rows after all', 'A:alpha:3;B:only b:3;');
        Observer.Expect('var', 'A:3');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_PartialRecord_KeyChangedSinceFetch_ReadUnloaded()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Row.Code := 'B';
        Observer.Observe('to existing: qty loaded before', Loaded(Row, 3));
        Observer.Observe('to existing: qty', Y64Qty(Row));
        Observer.Observe('to existing: code name', Row.Code + ':' + Row.Name);
        Observer.Observe('to existing: notes', GetNotes(Row));
        Clear(Row);
        Row.SetLoadFields(Name);
        Row.Get('A');
        Row.Code := 'Z';
        Observer.Observe('to missing: qty', Y64Qty(Row));
        Observer.Observe('to missing: code name', Row.Code + ':' + Row.Name);
        Observer.Observe('rows', Y64Rows());
        Observer.Expect('to existing: qty loaded before', 'No');
        Observer.Expect('to existing: qty', '7');
        Observer.Expect('to existing: code name', 'B:alpha');
        Observer.Expect('to existing: notes', '');
        Observer.Expect('to missing: qty', '7');
        Observer.Expect('to missing: code name', 'Z:alpha');
        Observer.Expect('rows', 'A:alpha:7;B:bravo:8;');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_PartialRecord_KeyChangedSinceFetch_ModifyAndModifyAll()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Row.Code := 'B';
        Row.Name := 'via a';
        Observer.Observe('modify', Format(Row.Modify()));
        Observer.Observe('rows after modify', Y64Rows());
        Seed();
        Row.SetLoadFields(Name);
        Row.Get('A');
        Row.Code := 'B';
        Row.ModifyAll(Name, 'all');
        Observer.Observe('rows after modifyall', Y64Rows());
        Observer.Observe('var after modifyall', Row.Code + ':' + Row.Name + ':' + Y64Qty(Row));
        Observer.Expect('modify', 'Yes');
        Observer.Expect('rows after modify', 'A:alpha:7;B:via a:8;');
        Observer.Expect('rows after modifyall', 'A:all:7;B:all:8;');
        Observer.Expect('var after modifyall', 'B:alpha:error:The field ''Name'' on table ''LT P81 LF Row'' has changed in the database between initial and JIT load. The fields causing the JIT load are: ''Qty''.\\The error may be transient if multiple users are editing the same record or permanent if the same user edits the record while keeping an old record.\\Identification values: ''Code=''A''''\    |InconsistentRead');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_ModifyAll_PartialRecord_PrimaryKeyField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P81 LF Row";
    begin
        Seed();
        Row.SetRange(Code, 'A');
        Row.SetLoadFields(Name);
        Row.FindFirst();
        asserterror Row.ModifyAll(Code, 'Q');
        Observer.ObserveError('modifyall key field');
        Observer.Expect('modifyall key field|text', 'The MODIFYALL function cannot be used on the Code field in the LT P81 LF Row table because it is part of the primary key.');
        Observer.Expect('modifyall key field|code', 'DB:Ok');
        Observer.Verify();
    end;
}

table 82952 "LT BR LF Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Kind; Code[10]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 82953 "LT BR LF Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 82954 "LT BR LF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option) { OptionMembers = Target,Other; }
        field(3; "No."; Code[20])
        {
            TableRelation = if (Kind = const(Target)) "LT BR LF Target"."No."
            else
            if (Kind = const(Other)) "LT BR LF Other"."No.";
        }
        field(4; Grp; Code[10]) { }
        field(5; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT BR LF Target" where(Kind = field(Grp)));
        }
        field(6; Note; Text[30]) { }
        field(7; KindFilter; Code[10]) { FieldClass = FlowFilter; }
        field(8; RelFiltered; Code[20]) { TableRelation = "LT BR LF Target"."No." where(Kind = field(Grp)); }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 82954 "LT BR LF Row Ext" extends "LT BR LF Row"
{
    fields
    {
        field(82954; ExtNote; Text[30]) { DataClassification = SystemMetadata; }
        field(82955; ExtRel; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = if (Kind = const(Target)) "LT BR LF Target"."No.";
        }
    }
}
