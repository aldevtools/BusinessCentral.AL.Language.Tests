// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (issue 625): ObsoleteState = Pending, ObsoleteReason and ObsoleteTag on a table field group, page group, repeater, grid, fixed group, system part,
// user control, action, action group, file upload action, custom action, view, page customization, permission set, profile, query column, query filter,
// report data item and request page: the object still works. ObsoleteState = Removed is not a value for any of these (AL0169) and the page content and
// action areas take none of the three properties (AL0666): must-not-compile cases 0797-0799. Using a Pending action in code gives the compiler warning
// AL0432 "Action 'x' is marked for removal. Reason: r. Tag: 1.0." (a warning, so it cannot be a must-not-compile case). Object ids 75050-75099.

table 75050 "LT X Obs Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Id, Name)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Use the brick.';
            ObsoleteTag = '1.0';
        }
        fieldgroup(Brick; Id, Name, Amount) { }
    }
}

controladdin "LT X Obs AddIn"
{
    RequestedHeight = 100;
}

codeunit 75051 "LT X Obs Log"
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

page 75052 "LT X Obs List"
{
    PageType = List;
    SourceTable = "LT X Obs Src";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Repeater replaced.';
                ObsoleteTag = '1.0';

                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            systempart(RecordLinks; Links)
            {
                ApplicationArea = All;
                ObsoleteState = Pending;
                ObsoleteReason = 'System part replaced.';
                ObsoleteTag = '1.0';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ObsAction)
            {
                ApplicationArea = All;
                ObsoleteState = Pending;
                ObsoleteReason = 'Action replaced.';
                ObsoleteTag = '1.0';

                trigger OnAction()
                var
                    Log: Codeunit "LT X Obs Log";
                begin
                    Log.Add('ObsAction');
                end;
            }
            group(ObsGroup)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Action group replaced.';
                ObsoleteTag = '1.0';

                action(InGroup)
                {
                    ApplicationArea = All;

                    trigger OnAction()
                    var
                        Log: Codeunit "LT X Obs Log";
                    begin
                        Log.Add('InGroup');
                    end;
                }
            }
            fileuploadaction(ObsUpload)
            {
                ApplicationArea = All;
                ObsoleteState = Pending;
                ObsoleteReason = 'Upload replaced.';
                ObsoleteTag = '1.0';
            }
            customaction(ObsCustom)
            {
                ApplicationArea = All;
                CustomActionType = Flow;
                FlowId = '11111111-1111-1111-1111-111111111111';
                ObsoleteState = Pending;
                ObsoleteReason = 'Custom action replaced.';
                ObsoleteTag = '1.0';
            }
        }
    }

    views
    {
        view(ObsView)
        {
            Caption = 'Obsolete view';
            Filters = where(Id = const(2));
            ObsoleteState = Pending;
            ObsoleteReason = 'View replaced.';
            ObsoleteTag = '1.0';
        }
    }
}

page 75053 "LT X Obs Card"
{
    PageType = Card;
    SourceTable = "LT X Obs Src";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(ObsGroupControl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Group replaced.';
                ObsoleteTag = '1.0';

                field(Id; Rec.Id) { ApplicationArea = All; }
            }
            grid(ObsGrid)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Grid replaced.';
                ObsoleteTag = '1.0';

                group(GridRow)
                {
                    field(NameInGrid; Rec.Name) { ApplicationArea = All; }
                }
            }
            fixed(ObsFixed)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Fixed group replaced.';
                ObsoleteTag = '1.0';

                group(FixedRow)
                {
                    field(AmountInFixed; Rec.Amount) { ApplicationArea = All; }
                }
            }
            usercontrol(ObsAddIn; "LT X Obs AddIn")
            {
                ApplicationArea = All;
                ObsoleteState = Pending;
                ObsoleteReason = 'Add-in replaced.';
                ObsoleteTag = '1.0';
            }
        }
    }
}

pagecustomization "LT X Obs Customization" customizes "LT X Obs Card"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Customization replaced.';
    ObsoleteTag = '1.0';

    layout
    {
        modify(Id) { Visible = false; }
    }
}

page 75054 "LT X Obs Role Center"
{
    PageType = RoleCenter;
    ApplicationArea = All;
    UsageCategory = None;
}

profile "LT X Obs Profile"
{
    Caption = 'LT X Obs Profile Caption';
    RoleCenter = "LT X Obs Role Center";
    ObsoleteState = Pending;
    ObsoleteReason = 'Profile replaced.';
    ObsoleteTag = '1.0';
}

permissionset 75055 "LT X Obs PS"
{
    Assignable = true;
    Permissions = tabledata "LT X Obs Src" = RI;
    ObsoleteState = Pending;
    ObsoleteReason = 'Permission set replaced.';
    ObsoleteTag = '1.0';
}

query 75056 "LT X Obs Query"
{
    elements
    {
        dataitem(Source; "LT X Obs Src")
        {
            column(Id; Id)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Column replaced.';
                ObsoleteTag = '1.0';
            }
            column(Name; Name) { }
            filter(AmountFilter; Amount)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Filter replaced.';
                ObsoleteTag = '1.0';
            }
        }
    }
}

report 75057 "LT X Obs Report"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = true;

    dataset
    {
        dataitem(Source; "LT X Obs Src")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Data item replaced.';
            ObsoleteTag = '1.0';

            column(IdCol; Id) { }
            column(NameCol; Name) { }
            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT X Obs Log";
            begin
                Log.Add('row' + Format(Source.Id) + '/' + Format(Mode));
            end;
        }
    }

    requestpage
    {
        ObsoleteState = Pending;
        ObsoleteReason = 'Request page replaced.';
        ObsoleteTag = '1.0';

        layout
        {
            area(Content)
            {
                field(ModeField; Mode) { ApplicationArea = All; }
            }
        }
    }

    var
        Mode: Integer;
}

codeunit 75058 "LT X Obsolete Pending Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Src: Record "LT X Obs Src";
    begin
        Src.DeleteAll();
        Src.Id := 1;
        Src.Name := 'one';
        Src.Amount := 1.5;
        Src.Insert();
        Src.Id := 2;
        Src.Name := 'two';
        Src.Amount := 2.5;
        Src.Insert();
    end;

    local procedure CurrentAppId(): Guid
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Id);
    end;

    [Test]
    procedure ObsoletePending_ListPageRepeaterAndActions_StillWork()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT X Obs Log";
        Pg: TestPage "LT X Obs List";
        Rows: Text;
    begin
        Seed();
        Log.Take();
        Pg.OpenView();
        if Pg.First() then
            repeat
                Rows += Pg.Id.Value + '=' + Pg.Name.Value + ';';
            until not Pg.Next();
        Observer.Observe('repeater_rows', Rows);
        Pg.ObsAction.Invoke();
        Pg.InGroup.Invoke();
        Observer.Observe('actions_run', Log.Take());
        Observer.Observe('obs_action_enabled', Format(Pg.ObsAction.Enabled()));
        Observer.Observe('obs_action_visible', Format(Pg.ObsAction.Visible()));
        Pg.Close();
        Observer.Expect('repeater_rows', '1=one;2=two;');
        Observer.Expect('actions_run', 'ObsAction;InGroup;');
        Observer.Expect('obs_action_enabled', 'Yes');
        Observer.Expect('obs_action_visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ObsoletePending_CardGroupGridFixedUserControl_StillWork()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT X Obs Card";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(2);
        Observer.Observe('group_field', Pg.Id.Value);
        Observer.Observe('grid_field', Pg.NameInGrid.Value);
        Observer.Observe('fixed_field', Pg.AmountInFixed.Value);
        Pg.NameInGrid.SetValue('changed');
        Pg.Close();
        Observer.Expect('group_field', '2');
        Observer.Expect('grid_field', 'two');
        Observer.Expect('fixed_field', '2.50');
        Observer.Verify();
    end;

    [Test]
    procedure ObsoletePending_PageCustomization_CardOpens()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT X Obs Card";
    begin
        Seed();
        Pg.OpenView();
        Observer.Observe('opened_id', Pg.Id.Value);
        Observer.Observe('id_visible_with_customization', Format(Pg.Id.Visible()));
        Pg.Close();
        Observer.Expect('opened_id', '1');
        Observer.Expect('id_visible_with_customization', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ObsoletePending_TableFieldGroup_RowsStillReadable()
    var
        Observer: Codeunit "Probe Observer";
        Src: Record "LT X Obs Src";
    begin
        Seed();
        Src.FindFirst();
        Observer.Observe('first', Src.Name);
        Observer.Observe('count', Format(Src.Count()));
        Src.Get(2);
        Observer.Observe('second_amount', Format(Src.Amount));
        Observer.Expect('first', 'one');
        Observer.Expect('count', '2');
        Observer.Expect('second_amount', '2.5');
        Observer.Verify();
    end;

    [Test]
    procedure ObsoletePending_Profile_RowInAllProfile()
    var
        Observer: Codeunit "Probe Observer";
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("App ID", CurrentAppId());
        AllProfile.SetRange("Profile ID", 'LT X Obs Profile');
        Observer.Observe('row_count', Format(AllProfile.Count()));
        if AllProfile.FindFirst() then begin
            Observer.Observe('caption', AllProfile.Caption);
            Observer.Observe('role_center_is_page', Format(AllProfile."Role Center ID" = Page::"LT X Obs Role Center"));
            Observer.Observe('enabled', Format(AllProfile.Enabled));
        end;
        Observer.Expect('row_count', '1');
        Observer.Expect('caption', 'LT X Obs Profile Caption');
        Observer.Expect('role_center_is_page', 'Yes');
        Observer.Expect('enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ObsoletePending_PermissionSet_RowAndGrants()
    var
        Observer: Codeunit "Probe Observer";
        MetaSet: Record "Metadata Permission Set";
        Expanded: Record "Expanded Permission";
    begin
        MetaSet.SetRange("App ID", CurrentAppId());
        MetaSet.SetRange("Role ID", 'LT X OBS PS');
        Observer.Observe('set_rows', Format(MetaSet.Count()));
        if MetaSet.FindFirst() then
            Observer.Observe('assignable', Format(MetaSet.Assignable));
        Expanded.SetRange("App ID", CurrentAppId());
        Expanded.SetRange("Role ID", 'LT X OBS PS');
        Expanded.SetRange("Object ID", Database::"LT X Obs Src");
        if Expanded.FindFirst() then
            Observer.Observe('grant', 'R=' + Format(Expanded."Read Permission") + ' I=' + Format(Expanded."Insert Permission") + ' M=' + Format(Expanded."Modify Permission"));
        Observer.Expect('set_rows', '1');
        Observer.Expect('assignable', 'Yes');
        Observer.Expect('grant', 'R=Yes I=Yes M= ');
        Observer.Verify();
    end;

    [Test]
    procedure ObsoletePending_QueryColumnAndFilter_StillWork()
    var
        Observer: Codeunit "Probe Observer";
        Obs: Query "LT X Obs Query";
        Rows: Text;
    begin
        Seed();
        Obs.Open();
        while Obs.Read() do
            Rows += Format(Obs.Id) + '=' + Obs.Name + ';';
        Obs.Close();
        Observer.Observe('all_rows', Rows);
        Rows := '';
        Obs.SetRange(AmountFilter, 2);
        Obs.Open();
        while Obs.Read() do
            Rows += Format(Obs.Id) + '=' + Obs.Name + ';';
        Obs.Close();
        Observer.Observe('filtered_rows_amount_2', Rows);
        Rows := '';
        Obs.SetRange(AmountFilter, 2.5);
        Obs.Open();
        while Obs.Read() do
            Rows += Format(Obs.Id) + '=' + Obs.Name + ';';
        Obs.Close();
        Observer.Observe('filtered_rows_amount_2_5', Rows);
        Observer.Expect('all_rows', '1=one;2=two;');
        Observer.Expect('filtered_rows_amount_2', '');
        Observer.Expect('filtered_rows_amount_2_5', '2=two;');
        Observer.Verify();
    end;

    local procedure RunReport(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer)
    var
        Log: Codeunit "LT X Obs Log";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        Seed();
        Log.Take();
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(ReportId, '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Line.Trim().StartsWith('<Column ') then
                Result += '[' + Line.Trim() + ']';
        end;
        Observer.Observe(Name + '_columns', Result);
        Observer.Observe(Name + '_rows', Log.Take());
    end;

    [Test]
    procedure ObsoletePending_ReportDataItemAndRequestPage_SaveAsXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunReport(Observer, 'obsolete_dataitem_and_requestpage', Report::"LT X Obs Report");
        Observer.Expect('obsolete_dataitem_and_requestpage_columns', '[<Column name="IdCol">1</Column>][<Column name="NameCol">one</Column>][<Column name="IdCol">2</Column>][<Column name="NameCol">two</Column>]');
        Observer.Expect('obsolete_dataitem_and_requestpage_rows', 'row1/0;row2/0;');
        Observer.Verify();
    end;

    [Test]
    procedure ObsoletePending_ReportPlain_SaveAsXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunReport(Observer, 'plain', Report::"LT X Obs Report Plain");
        Observer.Expect('plain_columns', '[<Column name="IdCol">1</Column>][<Column name="NameCol">one</Column>][<Column name="IdCol">2</Column>][<Column name="NameCol">two</Column>]');
        Observer.Expect('plain_rows', 'row1;row2;');
        Observer.Verify();
    end;

    [Test]
    procedure ObsoletePending_ReportObsoleteDataItem_SaveAsXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunReport(Observer, 'obsolete_dataitem', Report::"LT X Obs Report Item");
        Observer.Expect('obsolete_dataitem_columns', '[<Column name="IdCol">1</Column>][<Column name="NameCol">one</Column>][<Column name="IdCol">2</Column>][<Column name="NameCol">two</Column>]');
        Observer.Expect('obsolete_dataitem_rows', 'row1;row2;');
        Observer.Verify();
    end;
}

report 75059 "LT X Obs Report Plain"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "LT X Obs Src")
        {
            column(IdCol; Id) { }
            column(NameCol; Name) { }
            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT X Obs Log";
            begin
                Log.Add('row' + Format(Source.Id));
            end;
        }
    }
}

report 75060 "LT X Obs Report Item"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Source; "LT X Obs Src")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Data item replaced.';
            ObsoleteTag = '1.0';

            column(IdCol; Id) { }
            column(NameCol; Name) { }
            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT X Obs Log";
            begin
                Log.Add('row' + Format(Source.Id));
            end;
        }
    }
}
