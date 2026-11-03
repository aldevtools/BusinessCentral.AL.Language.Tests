// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 73036, list pages 73054-73055, test codeunit 73056
// Probe: written against BC 29 ...; observed values are added by the lead after measuring (tag P84, GitHub issue #84)
// Facts: list page opened over a temporary record (Page.RunModal / Page.Run) or a real record: is there a blank new-row line after the last row (Next count, last row values)
// BC versions: 29

page 73054 "LT P84 Row List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT P84 Row";
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field(NameF; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

page 73055 "LT P84 Row List RO"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT P84 Row";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field(NameF; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

codeunit 73056 "LT P84 List Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Tag: Text;

    local procedure Seed(RowCount: Integer)
    var
        Row: Record "LT P84 Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to RowCount do begin
            Row.Init();
            Row.Id := i * 10;
            Row.Name := 'Row' + Format(i);
            Row.Insert();
        end;
    end;

    local procedure SeedTemp(var Temp: Record "LT P84 Row" temporary; RowCount: Integer)
    var
        i: Integer;
    begin
        Temp.Reset();
        Temp.DeleteAll();
        for i := 1 to RowCount do begin
            Temp.Init();
            Temp.Id := i * 10;
            Temp.Name := 'Row' + Format(i);
            Temp.Insert();
        end;
    end;

    local procedure Walk(var P: TestPage "LT P84 Row List")
    var
        Cnt: Integer;
        Ids: Text;
        Names: Text;
    begin
        if P.First() then
            repeat
                Cnt += 1;
                Ids += P.IdF.Value() + ',';
                Names += P.NameF.Value() + ',';
            until not P.Next();
        Observer.Observe(Tag + '_count', Format(Cnt));
        Observer.Observe(Tag + '_ids', Ids);
        Observer.Observe(Tag + '_names', Names);
        Observer.Observe(Tag + '_next_after_end', Format(P.Next()));
        Observer.Observe(Tag + '_last_id', P.IdF.Value());
        Observer.Observe(Tag + '_last_name', P.NameF.Value());
    end;

    local procedure WalkRO(var P: TestPage "LT P84 Row List RO")
    var
        Cnt: Integer;
        Ids: Text;
    begin
        if P.First() then
            repeat
                Cnt += 1;
                Ids += P.IdF.Value() + ',';
            until not P.Next();
        Observer.Observe(Tag + '_count', Format(Cnt));
        Observer.Observe(Tag + '_ids', Ids);
        Observer.Observe(Tag + '_next_after_end', Format(P.Next()));
        Observer.Observe(Tag + '_last_id', P.IdF.Value());
    end;

    [ModalPageHandler]
    procedure ListHandler(var P: TestPage "LT P84 Row List")
    begin
        Walk(P);
    end;

    [ModalPageHandler]
    procedure ListROHandler(var P: TestPage "LT P84 Row List RO")
    begin
        WalkRO(P);
    end;

    [PageHandler]
    procedure ListModelessHandler(var P: TestPage "LT P84 Row List")
    begin
        Walk(P);
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Temp_ThreeRows()
    var
        Temp: Record "LT P84 Row" temporary;
    begin
        SeedTemp(Temp, 3);
        Tag := 'temp3';
        Page.RunModal(Page::"LT P84 Row List", Temp);
        Observer.Expect('temp3_count', '4');
        Observer.Expect('temp3_ids', '10,20,30,0,');
        Observer.Expect('temp3_names', 'Row1,Row2,Row3,,');
        Observer.Expect('temp3_next_after_end', 'No');
        Observer.Expect('temp3_last_id', '0');
        Observer.Expect('temp3_last_name', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Temp_OneRow()
    var
        Temp: Record "LT P84 Row" temporary;
    begin
        SeedTemp(Temp, 1);
        Tag := 'temp1';
        Page.RunModal(Page::"LT P84 Row List", Temp);
        Observer.Expect('temp1_count', '2');
        Observer.Expect('temp1_ids', '10,0,');
        Observer.Expect('temp1_names', 'Row1,,');
        Observer.Expect('temp1_next_after_end', 'No');
        Observer.Expect('temp1_last_id', '0');
        Observer.Expect('temp1_last_name', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Temp_NoRows()
    var
        Temp: Record "LT P84 Row" temporary;
    begin
        SeedTemp(Temp, 0);
        Tag := 'temp0';
        Page.RunModal(Page::"LT P84 Row List", Temp);
        Observer.Expect('temp0_count', '0');
        Observer.Expect('temp0_ids', '');
        Observer.Expect('temp0_names', '');
        Observer.Expect('temp0_next_after_end', 'No');
        Observer.Expect('temp0_last_id', '0');
        Observer.Expect('temp0_last_name', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Real_ThreeRows()
    var
        Row: Record "LT P84 Row";
    begin
        Seed(3);
        Tag := 'real3';
        Page.RunModal(Page::"LT P84 Row List", Row);
        Observer.Expect('real3_count', '4');
        Observer.Expect('real3_ids', '10,20,30,0,');
        Observer.Expect('real3_names', 'Row1,Row2,Row3,,');
        Observer.Expect('real3_next_after_end', 'No');
        Observer.Expect('real3_last_id', '0');
        Observer.Expect('real3_last_name', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Real_OneRow()
    var
        Row: Record "LT P84 Row";
    begin
        Seed(1);
        Tag := 'real1';
        Page.RunModal(Page::"LT P84 Row List", Row);
        Observer.Expect('real1_count', '2');
        Observer.Expect('real1_ids', '10,0,');
        Observer.Expect('real1_names', 'Row1,,');
        Observer.Expect('real1_next_after_end', 'No');
        Observer.Expect('real1_last_id', '0');
        Observer.Expect('real1_last_name', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Real_NoRows()
    var
        Row: Record "LT P84 Row";
    begin
        Seed(0);
        Tag := 'real0';
        Page.RunModal(Page::"LT P84 Row List", Row);
        Observer.Expect('real0_count', '0');
        Observer.Expect('real0_ids', '');
        Observer.Expect('real0_names', '');
        Observer.Expect('real0_next_after_end', 'No');
        Observer.Expect('real0_last_id', '0');
        Observer.Expect('real0_last_name', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListROHandler')]
    procedure RunModal_ReadOnlyList_Temp()
    var
        Temp: Record "LT P84 Row" temporary;
    begin
        SeedTemp(Temp, 3);
        Tag := 'ro_temp3';
        Page.RunModal(Page::"LT P84 Row List RO", Temp);
        Observer.Expect('ro_temp3_count', '3');
        Observer.Expect('ro_temp3_ids', '10,20,30,');
        Observer.Expect('ro_temp3_next_after_end', 'No');
        Observer.Expect('ro_temp3_last_id', '30');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListROHandler')]
    procedure RunModal_ReadOnlyList_Real()
    var
        Row: Record "LT P84 Row";
    begin
        Seed(3);
        Tag := 'ro_real3';
        Page.RunModal(Page::"LT P84 Row List RO", Row);
        Observer.Expect('ro_real3_count', '3');
        Observer.Expect('ro_real3_ids', '10,20,30,');
        Observer.Expect('ro_real3_next_after_end', 'No');
        Observer.Expect('ro_real3_last_id', '30');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListModelessHandler')]
    procedure Run_Temp_ThreeRows()
    var
        Temp: Record "LT P84 Row" temporary;
    begin
        SeedTemp(Temp, 3);
        Tag := 'run_temp3';
        Page.Run(Page::"LT P84 Row List", Temp);
        Observer.Expect('run_temp3_count', '4');
        Observer.Expect('run_temp3_ids', '10,20,30,0,');
        Observer.Expect('run_temp3_names', 'Row1,Row2,Row3,,');
        Observer.Expect('run_temp3_next_after_end', 'No');
        Observer.Expect('run_temp3_last_id', '0');
        Observer.Expect('run_temp3_last_name', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListModelessHandler')]
    procedure Run_Real_ThreeRows()
    var
        Row: Record "LT P84 Row";
    begin
        Seed(3);
        Tag := 'run_real3';
        Page.Run(Page::"LT P84 Row List", Row);
        Observer.Expect('run_real3_count', '4');
        Observer.Expect('run_real3_ids', '10,20,30,0,');
        Observer.Expect('run_real3_names', 'Row1,Row2,Row3,,');
        Observer.Expect('run_real3_next_after_end', 'No');
        Observer.Expect('run_real3_last_id', '0');
        Observer.Expect('run_real3_last_name', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_Temp_Filtered()
    var
        Temp: Record "LT P84 Row" temporary;
    begin
        SeedTemp(Temp, 3);
        Temp.SetFilter(Id, '>=20');
        Tag := 'temp_filtered';
        Page.RunModal(Page::"LT P84 Row List", Temp);
        Observer.Expect('temp_filtered_count', '3');
        Observer.Expect('temp_filtered_ids', '20,30,0,');
        Observer.Expect('temp_filtered_names', 'Row2,Row3,,');
        Observer.Expect('temp_filtered_next_after_end', 'No');
        Observer.Expect('temp_filtered_last_id', '0');
        Observer.Expect('temp_filtered_last_name', '');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_Real_OpenView()
    var
        P: TestPage "LT P84 Row List";
    begin
        Seed(3);
        Tag := 'tp_view3';
        P.OpenView();
        Walk(P);
        P.Close();
        Observer.Expect('tp_view3_count', '3');
        Observer.Expect('tp_view3_ids', '10,20,30,');
        Observer.Expect('tp_view3_names', 'Row1,Row2,Row3,');
        Observer.Expect('tp_view3_next_after_end', 'No');
        Observer.Expect('tp_view3_last_id', '30');
        Observer.Expect('tp_view3_last_name', 'Row3');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_Real_OpenEdit()
    var
        P: TestPage "LT P84 Row List";
    begin
        Seed(3);
        Tag := 'tp_edit3';
        P.OpenEdit();
        Walk(P);
        P.Close();
        Observer.Expect('tp_edit3_count', '4');
        Observer.Expect('tp_edit3_ids', '10,20,30,0,');
        Observer.Expect('tp_edit3_names', 'Row1,Row2,Row3,,');
        Observer.Expect('tp_edit3_next_after_end', 'No');
        Observer.Expect('tp_edit3_last_id', '0');
        Observer.Expect('tp_edit3_last_name', '');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_Real_OpenNew()
    var
        P: TestPage "LT P84 Row List";
    begin
        Seed(3);
        Tag := 'tp_new3';
        P.OpenNew();
        Walk(P);
        P.Close();
        Observer.Expect('tp_new3_count', '0');
        Observer.Expect('tp_new3_ids', '');
        Observer.Expect('tp_new3_names', '');
        Observer.Expect('tp_new3_next_after_end', 'No');
        Observer.Expect('tp_new3_last_id', '0');
        Observer.Expect('tp_new3_last_name', '');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_Real_OpenEdit_Empty()
    var
        P: TestPage "LT P84 Row List";
    begin
        Seed(0);
        Tag := 'tp_edit0';
        P.OpenEdit();
        Walk(P);
        P.Close();
        Observer.Expect('tp_edit0_count', '0');
        Observer.Expect('tp_edit0_ids', '');
        Observer.Expect('tp_edit0_names', '');
        Observer.Expect('tp_edit0_next_after_end', 'No');
        Observer.Expect('tp_edit0_last_id', '0');
        Observer.Expect('tp_edit0_last_name', '');
        Observer.Verify();
    end;
}
