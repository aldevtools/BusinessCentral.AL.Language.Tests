// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setview-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 95870 - 95876
// Probe: Rec.SetView() in the OnOpenPage of a list an action opens through RunPageLink (al-runner issue 7089, corpus issue 712). The
//   reporter's shape: RunPageLink = RelationType = const(Inbound), Transport = field("Transport no.") and RunPageView = sorting(RelationType,
//   ID); the list's SourceTableView = sorting(ID). OnOpenPage logs GetFilters, GetView, Count, CurrentKey, Ascending and the fields of Rec,
//   and (in the tests named _Groups) the filters of every filter group 0 to 10, before and after a SetView of: the view Rec has (read from
//   Rec, and from a RecordRef copy), a view with another filter, an empty view, a sorting-only view, a view on the linked field with another
//   value, and the view of a RecordRef copy that got a view and a filter of its own. Routes: the action with RunPageView, without it, with a
//   RunPageView that holds a where filter, and a target whose SourceTableView holds a where filter. The test reads the rows the opened page
//   lists (TestPage.Trap, First/Next).
//   Work orders: 1 Inbound/T1 MINE, 2 Inbound/T2 OTHER-T, 3 Outbound/T1 OTHER-O, 4 Inbound/T1 HIDDEN. The host H1 has transport T1.
// Log codeunit 95872 is SingleInstance and used only by codeunit 95876.
// Result (BC 29.0, corpus CI run 42020533240): before any SetView, Rec in OnOpenPage holds the link in filter group 0, a RunPageView
//   where filter in group 3 and the target's SourceTableView where filter in group 2; GetFilters and GetView read group 0 only, Count
//   counts the rows of every group; the linked fields are filled (rec=0/Inbound/T1/); a RunPageView sorting does not change the key, the
//   target's SourceTableView sorting stays (key=ID), with and without RunPageView. SetView replaces the view of group 0, the link
//   included: a SetView of the view Rec has (from Rec or from a RecordRef copy) changes nothing, another filter or an empty or
//   sorting-only view drops the link, a filter on the linked field with another value replaces it. Groups 2 and 3 stay. The linked field
//   values stay in Rec. The page then lists the rows of the new view in its order.
// BC versions: 27, 28, 29

table 95870 "LT RSV Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[10]) { }
        field(2; "Transport no."; Code[10]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 95871 "LT RSV Work Order"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ID; Integer) { }
        field(2; RelationType; Option) { OptionMembers = Inbound,Outbound; }
        field(3; Transport; Code[10]) { }
        field(4; Information; Text[30]) { }
    }

    keys
    {
        key(PK; ID) { Clustered = true; }
        key(Key2; RelationType, ID) { }
    }
}

// The target, like the reporter's work order list: OnOpenPage applies a view with SetView.
page 95873 "LT RSV List"
{
    PageType = List;
    SourceTable = "LT RSV Work Order";
    SourceTableView = sorting(ID);
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(ID; Rec.ID) { ApplicationArea = All; }
                field(Information; Rec.Information) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT RSV Log";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        if Log.Groups() then
            Log.Add('groups before=' + GroupFilters());
        case Log.Mode() of
            'none':
                Log.Add('before ' + State());
            'same':
                Rec.SetView(Rec.GetView());
            'sameref':
                begin
                    RecRef.GetTable(Rec);
                    Rec.SetView(RecRef.GetView());
                end;
            'extra':
                Rec.SetView('SORTING(ID) WHERE(Information=FILTER(MINE|OTHER-T))');
            'empty':
                Rec.SetView('');
            'sortonly':
                Rec.SetView('SORTING(ID) ORDER(Descending)');
            'linkother':
                Rec.SetView('WHERE(Transport=FILTER(T2))');
            'saved':
                begin
                    RecRef.GetTable(Rec);
                    RecRef.SetView('SORTING(ID) ORDER(Ascending)');
                    FieldRef := RecRef.Field(1);
                    FieldRef.SetFilter('>0');
                    if RecRef.FindFirst() then;
                    Rec.SetView(RecRef.GetView());
                end;
        end;
        if Log.Mode() <> 'none' then
            Log.Add('after ' + State());
        if Log.Groups() then
            Log.Add('groups after=' + GroupFilters());
    end;

    local procedure State(): Text
    begin
        exit('filters=' + Rec.GetFilters() + ' view=' + Rec.GetView() + ' count=' + Format(Rec.Count()) + ' key=' + Rec.CurrentKey() +
          ' asc=' + Format(Rec.Ascending()) + ' rec=' + Format(Rec.ID) + '/' + Format(Rec.RelationType) + '/' + Rec.Transport + '/' + Rec.Information);
    end;

    local procedure GroupFilters(): Text
    var
        Group: Integer;
        Result: Text;
    begin
        for Group := 0 to 10 do begin
            Rec.FilterGroup(Group);
            if Rec.GetFilters() <> '' then
                Result += Format(Group) + ':' + Rec.GetFilters() + '|';
        end;
        Rec.FilterGroup(0);
        exit(Result);
    end;
}

// A target whose SourceTableView holds a where filter.
page 95874 "LT RSV List Where"
{
    PageType = List;
    SourceTable = "LT RSV Work Order";
    SourceTableView = sorting(ID) where(Information = filter(<> 'HIDDEN'));
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(ID; Rec.ID) { ApplicationArea = All; }
                field(Information; Rec.Information) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT RSV Log";
    begin
        if Log.Groups() then
            Log.Add('groups before=' + GroupFilters());
        case Log.Mode() of
            'none':
                Log.Add('before ' + State());
            'same':
                Rec.SetView(Rec.GetView());
            'empty':
                Rec.SetView('');
        end;
        if Log.Mode() <> 'none' then
            Log.Add('after ' + State());
        if Log.Groups() then
            Log.Add('groups after=' + GroupFilters());
    end;

    local procedure State(): Text
    begin
        exit('filters=' + Rec.GetFilters() + ' view=' + Rec.GetView() + ' count=' + Format(Rec.Count()) + ' key=' + Rec.CurrentKey() +
          ' asc=' + Format(Rec.Ascending()) + ' rec=' + Format(Rec.ID) + '/' + Format(Rec.RelationType) + '/' + Rec.Transport + '/' + Rec.Information);
    end;

    local procedure GroupFilters(): Text
    var
        Group: Integer;
        Result: Text;
    begin
        for Group := 0 to 10 do begin
            Rec.FilterGroup(Group);
            if Rec.GetFilters() <> '' then
                Result += Format(Group) + ':' + Rec.GetFilters() + '|';
        end;
        Rec.FilterGroup(0);
        exit(Result);
    end;
}

// The host, like the reporter's card: actions open the list through RunPageLink.
page 95875 "LT RSV Host Card"
{
    PageType = Card;
    SourceTable = "LT RSV Host";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field("Transport no."; Rec."Transport no.") { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LinkAndView)
            {
                ApplicationArea = All;
                RunObject = page "LT RSV List";
                RunPageLink = RelationType = const(Inbound), Transport = field("Transport no.");
                RunPageView = sorting(RelationType, ID);
            }
            action(LinkOnly)
            {
                ApplicationArea = All;
                RunObject = page "LT RSV List";
                RunPageLink = RelationType = const(Inbound), Transport = field("Transport no.");
            }
            action(LinkAndWhereView)
            {
                ApplicationArea = All;
                RunObject = page "LT RSV List";
                RunPageLink = RelationType = const(Inbound), Transport = field("Transport no.");
                RunPageView = where(Information = filter(<> 'HIDDEN'));
            }
            action(LinkToWhereList)
            {
                ApplicationArea = All;
                RunObject = page "LT RSV List Where";
                RunPageLink = RelationType = const(Inbound), Transport = field("Transport no.");
            }
        }
    }
}

codeunit 95872 "LT RSV Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        CurrentMode: Text;
        WithGroups: Boolean;

    procedure Start(NewMode: Text; NewGroups: Boolean)
    begin
        Entries := '';
        CurrentMode := NewMode;
        WithGroups := NewGroups;
    end;

    procedure Mode(): Text
    begin
        exit(CurrentMode);
    end;

    procedure Groups(): Boolean
    begin
        exit(WithGroups);
    end;

    procedure Add(Value: Text)
    begin
        Entries += Value + ';';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}

codeunit 95876 "LT RSV RunPageLink SetView"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RSV Log";

    // The reporter's route: RunPageLink and RunPageView = sorting(RelationType, ID).

    [Test]
    procedure RSV_LinkAndView_NoSetView()
    begin
        Observer.Observe('rows', OpenList('LinkAndView', 'none', false));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,HIDDEN,');
        Observer.Expect('log', 'before filters=RelationType: Inbound, Transport: T1 view=VERSION(1) SORTING(ID) WHERE(RelationType=FILTER(Inbound),Transport=FILTER(T1)) count=2 key=ID asc=Yes rec=0/Inbound/T1/;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndView_NoSetView_Groups()
    begin
        Observer.Observe('rows', OpenList('LinkAndView', 'none', true));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,HIDDEN,');
        Observer.Expect('log', 'groups before=0:RelationType: Inbound, Transport: T1|;before filters=RelationType: Inbound, Transport: T1 view=VERSION(1) SORTING(ID) WHERE(RelationType=FILTER(Inbound),Transport=FILTER(T1)) count=2 key=ID asc=Yes rec=0/Inbound/T1/;groups after=0:RelationType: Inbound, Transport: T1|;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndView_SameView()
    begin
        Observer.Observe('rows', OpenList('LinkAndView', 'same', false));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,HIDDEN,');
        Observer.Expect('log', 'after filters=RelationType: Inbound, Transport: T1 view=VERSION(1) SORTING(ID) WHERE(RelationType=FILTER(Inbound),Transport=FILTER(T1)) count=2 key=ID asc=Yes rec=0/Inbound/T1/;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndView_SameView_Groups()
    begin
        Observer.Observe('rows', OpenList('LinkAndView', 'same', true));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,HIDDEN,');
        Observer.Expect('log', 'groups before=0:RelationType: Inbound, Transport: T1|;after filters=RelationType: Inbound, Transport: T1 view=VERSION(1) SORTING(ID) WHERE(RelationType=FILTER(Inbound),Transport=FILTER(T1)) count=2 key=ID asc=Yes rec=0/Inbound/T1/;groups after=0:RelationType: Inbound, Transport: T1|;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndView_SameViewOfRecordRef()
    begin
        Observer.Observe('rows', OpenList('LinkAndView', 'sameref', false));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,HIDDEN,');
        Observer.Expect('log', 'after filters=RelationType: Inbound, Transport: T1 view=VERSION(1) SORTING(ID) WHERE(RelationType=FILTER(Inbound),Transport=FILTER(T1)) count=2 key=ID asc=Yes rec=0/Inbound/T1/;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndView_OtherFilter()
    begin
        Observer.Observe('rows', OpenList('LinkAndView', 'extra', false));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,OTHER-T,');
        Observer.Expect('log', 'after filters=Information: MINE|OTHER-T view=VERSION(1) SORTING(ID) WHERE(Information=FILTER(MINE|OTHER-T)) count=2 key=ID asc=Yes rec=0/Inbound/T1/;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndView_OtherFilter_Groups()
    begin
        Observer.Observe('rows', OpenList('LinkAndView', 'extra', true));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,OTHER-T,');
        Observer.Expect('log', 'groups before=0:RelationType: Inbound, Transport: T1|;after filters=Information: MINE|OTHER-T view=VERSION(1) SORTING(ID) WHERE(Information=FILTER(MINE|OTHER-T)) count=2 key=ID asc=Yes rec=0/Inbound/T1/;groups after=0:Information: MINE|OTHER-T|;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndView_EmptyView()
    begin
        Observer.Observe('rows', OpenList('LinkAndView', 'empty', false));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,OTHER-T,OTHER-O,HIDDEN,');
        Observer.Expect('log', 'after filters= view=VERSION(1) SORTING(ID) count=4 key=ID asc=Yes rec=0/Inbound/T1/;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndView_EmptyView_Groups()
    begin
        Observer.Observe('rows', OpenList('LinkAndView', 'empty', true));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,OTHER-T,OTHER-O,HIDDEN,');
        Observer.Expect('log', 'groups before=0:RelationType: Inbound, Transport: T1|;after filters= view=VERSION(1) SORTING(ID) count=4 key=ID asc=Yes rec=0/Inbound/T1/;groups after=;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndView_SortingOnly()
    begin
        Observer.Observe('rows', OpenList('LinkAndView', 'sortonly', false));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'HIDDEN,OTHER-O,OTHER-T,MINE,');
        Observer.Expect('log', 'after filters= view=VERSION(1) SORTING(ID) ORDER(Descending) count=4 key=ID asc=No rec=0/Inbound/T1/;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndView_LinkedFieldOtherValue()
    begin
        Observer.Observe('rows', OpenList('LinkAndView', 'linkother', false));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'OTHER-T,');
        Observer.Expect('log', 'after filters=Transport: T2 view=VERSION(1) SORTING(ID) WHERE(Transport=FILTER(T2)) count=1 key=ID asc=Yes rec=0/Inbound/T1/;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndView_ViewOfACopyWithItsOwnFilter()
    begin
        Observer.Observe('rows', OpenList('LinkAndView', 'saved', false));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,OTHER-T,OTHER-O,HIDDEN,');
        Observer.Expect('log', 'after filters=ID: >0 view=VERSION(1) SORTING(ID) WHERE(ID=FILTER(>0)) count=4 key=ID asc=Yes rec=0/Inbound/T1/;');
        Observer.Verify();
    end;

    // RunPageLink without RunPageView.

    [Test]
    procedure RSV_LinkOnly_NoSetView_Groups()
    begin
        Observer.Observe('rows', OpenList('LinkOnly', 'none', true));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,HIDDEN,');
        Observer.Expect('log', 'groups before=0:RelationType: Inbound, Transport: T1|;before filters=RelationType: Inbound, Transport: T1 view=VERSION(1) SORTING(ID) WHERE(RelationType=FILTER(Inbound),Transport=FILTER(T1)) count=2 key=ID asc=Yes rec=0/Inbound/T1/;groups after=0:RelationType: Inbound, Transport: T1|;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkOnly_SameView()
    begin
        Observer.Observe('rows', OpenList('LinkOnly', 'same', false));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,HIDDEN,');
        Observer.Expect('log', 'after filters=RelationType: Inbound, Transport: T1 view=VERSION(1) SORTING(ID) WHERE(RelationType=FILTER(Inbound),Transport=FILTER(T1)) count=2 key=ID asc=Yes rec=0/Inbound/T1/;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkOnly_OtherFilter()
    begin
        Observer.Observe('rows', OpenList('LinkOnly', 'extra', false));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,OTHER-T,');
        Observer.Expect('log', 'after filters=Information: MINE|OTHER-T view=VERSION(1) SORTING(ID) WHERE(Information=FILTER(MINE|OTHER-T)) count=2 key=ID asc=Yes rec=0/Inbound/T1/;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkOnly_EmptyView_Groups()
    begin
        Observer.Observe('rows', OpenList('LinkOnly', 'empty', true));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,OTHER-T,OTHER-O,HIDDEN,');
        Observer.Expect('log', 'groups before=0:RelationType: Inbound, Transport: T1|;after filters= view=VERSION(1) SORTING(ID) count=4 key=ID asc=Yes rec=0/Inbound/T1/;groups after=;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkOnly_SortingOnly()
    begin
        Observer.Observe('rows', OpenList('LinkOnly', 'sortonly', false));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'HIDDEN,OTHER-O,OTHER-T,MINE,');
        Observer.Expect('log', 'after filters= view=VERSION(1) SORTING(ID) ORDER(Descending) count=4 key=ID asc=No rec=0/Inbound/T1/;');
        Observer.Verify();
    end;

    // RunPageLink and a RunPageView with a where filter.

    [Test]
    procedure RSV_LinkAndWhereView_NoSetView_Groups()
    begin
        Observer.Observe('rows', OpenList('LinkAndWhereView', 'none', true));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,');
        Observer.Expect('log', 'groups before=0:RelationType: Inbound, Transport: T1|3:Information: <>HIDDEN|;before filters=RelationType: Inbound, Transport: T1 view=VERSION(1) SORTING(ID) WHERE(RelationType=FILTER(Inbound),Transport=FILTER(T1)) count=1 key=ID asc=Yes rec=0/Inbound/T1/;groups after=0:RelationType: Inbound, Transport: T1|3:Information: <>HIDDEN|;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndWhereView_SameView_Groups()
    begin
        Observer.Observe('rows', OpenList('LinkAndWhereView', 'same', true));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,');
        Observer.Expect('log', 'groups before=0:RelationType: Inbound, Transport: T1|3:Information: <>HIDDEN|;after filters=RelationType: Inbound, Transport: T1 view=VERSION(1) SORTING(ID) WHERE(RelationType=FILTER(Inbound),Transport=FILTER(T1)) count=1 key=ID asc=Yes rec=0/Inbound/T1/;groups after=0:RelationType: Inbound, Transport: T1|3:Information: <>HIDDEN|;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkAndWhereView_EmptyView_Groups()
    begin
        Observer.Observe('rows', OpenList('LinkAndWhereView', 'empty', true));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,OTHER-T,OTHER-O,');
        Observer.Expect('log', 'groups before=0:RelationType: Inbound, Transport: T1|3:Information: <>HIDDEN|;after filters= view=VERSION(1) SORTING(ID) count=3 key=ID asc=Yes rec=0/Inbound/T1/;groups after=3:Information: <>HIDDEN|;');
        Observer.Verify();
    end;

    // RunPageLink to a target whose SourceTableView holds a where filter.

    [Test]
    procedure RSV_LinkToWhereList_NoSetView_Groups()
    begin
        Observer.Observe('rows', OpenWhereList('none', true));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,');
        Observer.Expect('log', 'groups before=0:RelationType: Inbound, Transport: T1|2:Information: <>HIDDEN|;before filters=RelationType: Inbound, Transport: T1 view=VERSION(1) SORTING(ID) WHERE(RelationType=FILTER(Inbound),Transport=FILTER(T1)) count=1 key=ID asc=Yes rec=0/Inbound/T1/;groups after=0:RelationType: Inbound, Transport: T1|2:Information: <>HIDDEN|;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkToWhereList_SameView_Groups()
    begin
        Observer.Observe('rows', OpenWhereList('same', true));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,');
        Observer.Expect('log', 'groups before=0:RelationType: Inbound, Transport: T1|2:Information: <>HIDDEN|;after filters=RelationType: Inbound, Transport: T1 view=VERSION(1) SORTING(ID) WHERE(RelationType=FILTER(Inbound),Transport=FILTER(T1)) count=1 key=ID asc=Yes rec=0/Inbound/T1/;groups after=0:RelationType: Inbound, Transport: T1|2:Information: <>HIDDEN|;');
        Observer.Verify();
    end;

    [Test]
    procedure RSV_LinkToWhereList_EmptyView_Groups()
    begin
        Observer.Observe('rows', OpenWhereList('empty', true));
        Observer.Observe('log', Log.Get());
        Observer.Expect('rows', 'MINE,OTHER-T,OTHER-O,');
        Observer.Expect('log', 'groups before=0:RelationType: Inbound, Transport: T1|2:Information: <>HIDDEN|;after filters= view=VERSION(1) SORTING(ID) count=3 key=ID asc=Yes rec=0/Inbound/T1/;groups after=2:Information: <>HIDDEN|;');
        Observer.Verify();
    end;

    local procedure OpenList(ActionName: Text; Mode: Text; Groups: Boolean) Rows: Text
    var
        Card: TestPage "LT RSV Host Card";
        List: TestPage "LT RSV List";
    begin
        Setup(Mode, Groups);
        Card.OpenView();
        Card.GoToKey('H1');
        List.Trap();
        case ActionName of
            'LinkAndView':
                Card.LinkAndView.Invoke();
            'LinkOnly':
                Card.LinkOnly.Invoke();
            'LinkAndWhereView':
                Card.LinkAndWhereView.Invoke();
        end;
        if List.First() then
            repeat
                Rows += List.Information.Value() + ',';
            until not List.Next();
        List.Close();
        Card.Close();
    end;

    local procedure OpenWhereList(Mode: Text; Groups: Boolean) Rows: Text
    var
        Card: TestPage "LT RSV Host Card";
        List: TestPage "LT RSV List Where";
    begin
        Setup(Mode, Groups);
        Card.OpenView();
        Card.GoToKey('H1');
        List.Trap();
        Card.LinkToWhereList.Invoke();
        if List.First() then
            repeat
                Rows += List.Information.Value() + ',';
            until not List.Next();
        List.Close();
        Card.Close();
    end;

    local procedure Setup(Mode: Text; Groups: Boolean)
    var
        Host: Record "LT RSV Host";
        WorkOrder: Record "LT RSV Work Order";
    begin
        Host.DeleteAll();
        WorkOrder.DeleteAll();
        Host.Id := 'H1';
        Host."Transport no." := 'T1';
        Host.Insert();
        AddWorkOrder(1, WorkOrder.RelationType::Inbound, 'T1', 'MINE');
        AddWorkOrder(2, WorkOrder.RelationType::Inbound, 'T2', 'OTHER-T');
        AddWorkOrder(3, WorkOrder.RelationType::Outbound, 'T1', 'OTHER-O');
        AddWorkOrder(4, WorkOrder.RelationType::Inbound, 'T1', 'HIDDEN');
        Log.Start(Mode, Groups);
    end;

    local procedure AddWorkOrder(Id: Integer; Relation: Option; Transport: Code[10]; Info: Text[30])
    var
        WorkOrder: Record "LT RSV Work Order";
    begin
        WorkOrder.ID := Id;
        WorkOrder.RelationType := Relation;
        WorkOrder.Transport := Transport;
        WorkOrder.Information := Info;
        WorkOrder.Insert();
    end;
}
