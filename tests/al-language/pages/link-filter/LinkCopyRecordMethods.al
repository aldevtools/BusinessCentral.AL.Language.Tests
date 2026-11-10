// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-subpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 62660 62661, codeunit 62662, pages 62663..62665, test codeunit 62666
// Probe: observe-only. Area: the record methods on a by-value copy of Rec (a Record parameter without var) of a page that is
//   filtered by a link. R7138RunPageLinkCopyGet.al pins, for a list an action opened through RunPageLink, that the copy made in
//   OnAfterGetCurrRecord carries Rec's fields and no link filter (GetFilters, Count, Get). Not pinned (al-runner issue 7444): the
//   other methods on that copy (IsEmpty, FindFirst, FindSet, Find('='), Next, a SetRange of its own, the filter of group 4,
//   TestField, Modify), the copy made in other places (the table field's OnValidate on a stored and on a new row, a page field's
//   OnValidate, an action, OnOpenPage, OnNewRecord), and the same for a ListPart filtered by SubPageLink.
// Zones: L1 has Z1 and Z2; L2 has Z3 and Z4 (Pick = true). The card stands on L2.
// One test arms one place; only the armed place writes to the log.
// local object: the triggers of the list, the part and the table field are what the test checks
// BC versions: 27, 28, 29

table 62660 "PG RC Loc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 62661 "PG RC Zone"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Loc Code"; Code[10]) { DataClassification = SystemMetadata; }
        field(2; Code; Code[10]) { DataClassification = SystemMetadata; }
        field(3; Pick; Boolean) { DataClassification = SystemMetadata; }
        field(4; "Multi Pick"; Boolean)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Mgt: Codeunit "PG RC Mgt";
            begin
                Mgt.Probe('table-validate', Rec);
            end;
        }
    }

    keys
    {
        key(PK; "Loc Code", Code) { Clustered = true; }
    }
}

codeunit 62662 "PG RC Mgt"
{
    SingleInstance = true;

    var
        Armed: Text;
        Modifies: Boolean;
        Entries: Text;

    procedure Arm(Place: Text; WithModify: Boolean)
    begin
        Armed := Place;
        Modifies := WithModify;
        Entries := '';
    end;

    procedure Take() Result: Text
    begin
        Result := '[' + Entries + ']';
        Entries := '';
        Armed := '';
    end;

    local procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ' | ';
        Entries += Line;
    end;

    local procedure RowKey(var Zone: Record "PG RC Zone"): Text
    begin
        exit(Zone."Loc Code" + '/' + Zone.Code);
    end;

    // Zone is passed by value on purpose: this copy is what the probe is about.
    procedure Probe(Place: Text; Zone: Record "PG RC Zone")
    var
        Work: Record "PG RC Zone";
        Line: Text;
        Rows: Text;
        Steps: Integer;
    begin
        if Place <> Armed then
            exit;
        if Modifies then begin
            Work.Copy(Zone);
            Work.Pick := not Work.Pick;
            Add(Place + ' key=' + RowKey(Zone) + ' modify=' + Format(Work.Modify()));
            exit;
        end;
        Line := Place + ' key=' + RowKey(Zone) + ' pick=' + Format(Zone.Pick) + ' filters=[' + Zone.GetFilters() + ']';
        Work.Copy(Zone);
        Work.FilterGroup(4);
        Line += ' g4=[' + Work.GetFilters() + ']';
        Work.FilterGroup(0);
        Line += ' count=' + Format(Zone.Count()) + ' empty=' + Format(Zone.IsEmpty());
        Work.Copy(Zone);
        if Work.FindFirst() then
            Line += ' first=' + RowKey(Work)
        else
            Line += ' first=none';
        Work.Copy(Zone);
        if Work.FindSet() then
            repeat
                Rows += Work.Code + ' ';
            until Work.Next() = 0;
        Line += ' set=[' + Rows + ']';
        Work.Copy(Zone);
        Line += ' find=' + Format(Work.Find('='));
        Work.Copy(Zone);
        Steps := Work.Next();
        Line += ' next=' + Format(Steps) + ':' + RowKey(Work);
        Work.Copy(Zone);
        Line += ' get-outside=' + Format(Work.Get('L1', 'Z1'));
        Work.Copy(Zone);
        Work.SetRange("Loc Code", 'L1');
        Line += ' own-range=' + Format(Work.Count());
        if TryTestPick(Zone) then
            Line += ' testfield=ok'
        else
            Line += ' testfield=[' + GetLastErrorText() + ']';
        Add(Line);
    end;

    [TryFunction]
    local procedure TryTestPick(Zone: Record "PG RC Zone")
    begin
        Zone.TestField(Pick);
    end;
}

page 62663 "PG RC Zones"
{
    PageType = List;
    SourceTable = "PG RC Zone";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Pick; Rec.Pick)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Mgt.Probe('page-validate', Rec);
                    end;
                }
                field("Multi Pick"; Rec."Multi Pick") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Check)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Mgt.Probe('action', Rec);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "PG RC Mgt";

    trigger OnOpenPage()
    begin
        Mgt.Probe('open', Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Mgt.Probe('agcr', Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Mgt.Probe('new', Rec);
    end;
}

page 62664 "PG RC Zones Part"
{
    PageType = ListPart;
    SourceTable = "PG RC Zone";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Pick; Rec.Pick)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Mgt.Probe('part-page-validate', Rec);
                    end;
                }
                field("Multi Pick"; Rec."Multi Pick") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Check)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Mgt.Probe('part-action', Rec);
                end;
            }
        }
    }

    var
        Mgt: Codeunit "PG RC Mgt";

    trigger OnOpenPage()
    begin
        Mgt.Probe('part-open', Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Mgt.Probe('part-agcr', Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Mgt.Probe('part-new', Rec);
    end;
}

page 62665 "PG RC Loc Card"
{
    PageType = Card;
    SourceTable = "PG RC Loc";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            part(ZonesPart; "PG RC Zones Part")
            {
                ApplicationArea = All;
                SubPageLink = "Loc Code" = field(Code);
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Zones)
            {
                ApplicationArea = All;
                RunObject = page "PG RC Zones";
                RunPageLink = "Loc Code" = field(Code);
            }
        }
    }
}

codeunit 62666 "PG RC Link Copy Methods"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mgt: Codeunit "PG RC Mgt";
        Step: Text;

    local procedure Seed()
    var
        Loc: Record "PG RC Loc";
        Zone: Record "PG RC Zone";
    begin
        Zone.DeleteAll();
        Loc.DeleteAll();
        Loc.Code := 'L1';
        Loc.Insert();
        Loc.Code := 'L2';
        Loc.Insert();
        AddZone('L1', 'Z1', false);
        AddZone('L1', 'Z2', false);
        AddZone('L2', 'Z3', false);
        AddZone('L2', 'Z4', true);
    end;

    local procedure AddZone(LocCode: Code[10]; ZoneCode: Code[10]; Pick: Boolean)
    var
        Zone: Record "PG RC Zone";
    begin
        Zone."Loc Code" := LocCode;
        Zone.Code := ZoneCode;
        Zone.Pick := Pick;
        Zone.Insert();
    end;

    local procedure Zones() Result: Text
    var
        Zone: Record "PG RC Zone";
    begin
        if Zone.FindSet() then
            repeat
                Result += Zone."Loc Code" + '/' + Zone.Code + ':' + Format(Zone.Pick) + ':' + Format(Zone."Multi Pick") + ' ';
            until Zone.Next() = 0;
        Result := '[' + Result + ']';
    end;

    local procedure ViaAction(Place: Text; NewStep: Text; WithModify: Boolean)
    var
        Card: TestPage "PG RC Loc Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('L2');
        Step := NewStep;
        Mgt.Arm(Place, WithModify);
        Card.Zones.Invoke();
        Observer.Observe('log', Mgt.Take());
        Observer.Observe('zones', Zones());
        Card.Close();
        Observer.Finish();
    end;

    local procedure ViaPart(Place: Text; NewStep: Text; WithModify: Boolean)
    var
        Card: TestPage "PG RC Loc Card";
    begin
        Seed();
        if Place = 'part-open' then
            Mgt.Arm(Place, WithModify);
        Card.OpenEdit();
        Card.GoToKey('L2');
        if Place <> 'part-open' then
            Mgt.Arm(Place, WithModify);
        case NewStep of
            'first':
                Card.ZonesPart.First();
            'multi-stored':
                begin
                    Card.ZonesPart.First();
                    Card.ZonesPart."Multi Pick".SetValue(true);
                end;
            'multi-new':
                begin
                    Card.ZonesPart.New();
                    Card.ZonesPart.Code.SetValue('Z9');
                    Card.ZonesPart."Multi Pick".SetValue(true);
                end;
            'pick-stored':
                begin
                    Card.ZonesPart.First();
                    Card.ZonesPart.Pick.SetValue(true);
                end;
            'check':
                begin
                    Card.ZonesPart.Last();
                    Card.ZonesPart.Check.Invoke();
                end;
            'new':
                Card.ZonesPart.New();
        end;
        Observer.Observe('log', Mgt.Take());
        Observer.Observe('zones', Zones());
        Card.Close();
        Observer.Finish();
    end;

    [PageHandler]
    procedure ZonesHandler(var List: TestPage "PG RC Zones")
    begin
        case Step of
            'first':
                List.First();
            'multi-stored':
                begin
                    List.First();
                    List."Multi Pick".SetValue(true);
                end;
            'multi-new':
                begin
                    List.New();
                    List.Code.SetValue('Z9');
                    List."Multi Pick".SetValue(true);
                end;
            'pick-stored':
                begin
                    List.First();
                    List.Pick.SetValue(true);
                end;
            'check':
                begin
                    List.Last();
                    List.Check.Invoke();
                end;
            'new':
                List.New();
        end;
        List.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ZonesHandler')]
    procedure RunPageLinkList_OnOpenPage()
    begin
        ViaAction('open', 'first', false);
    end;

    [Test]
    procedure SubPageLinkPart_OnOpenPage()
    begin
        ViaPart('part-open', 'first', false);
    end;

    [Test]
    [HandlerFunctions('ZonesHandler')]
    procedure RunPageLinkList_OnAfterGetCurrRecord()
    begin
        ViaAction('agcr', 'first', false);
    end;

    [Test]
    procedure SubPageLinkPart_OnAfterGetCurrRecord()
    begin
        ViaPart('part-agcr', 'first', false);
    end;

    [Test]
    [HandlerFunctions('ZonesHandler')]
    procedure RunPageLinkList_TableFieldOnValidate_StoredRow()
    begin
        ViaAction('table-validate', 'multi-stored', false);
    end;

    [Test]
    procedure SubPageLinkPart_TableFieldOnValidate_StoredRow()
    begin
        ViaPart('table-validate', 'multi-stored', false);
    end;

    [Test]
    [HandlerFunctions('ZonesHandler')]
    procedure RunPageLinkList_TableFieldOnValidate_NewRow()
    begin
        ViaAction('table-validate', 'multi-new', false);
    end;

    [Test]
    procedure SubPageLinkPart_TableFieldOnValidate_NewRow()
    begin
        ViaPart('table-validate', 'multi-new', false);
    end;

    [Test]
    [HandlerFunctions('ZonesHandler')]
    procedure RunPageLinkList_PageFieldOnValidate_StoredRow()
    begin
        ViaAction('page-validate', 'pick-stored', false);
    end;

    [Test]
    procedure SubPageLinkPart_PageFieldOnValidate_StoredRow()
    begin
        ViaPart('part-page-validate', 'pick-stored', false);
    end;

    [Test]
    [HandlerFunctions('ZonesHandler')]
    procedure RunPageLinkList_Action_OnLastRow()
    begin
        ViaAction('action', 'check', false);
    end;

    [Test]
    procedure SubPageLinkPart_Action_OnLastRow()
    begin
        ViaPart('part-action', 'check', false);
    end;

    [Test]
    [HandlerFunctions('ZonesHandler')]
    procedure RunPageLinkList_OnNewRecord()
    begin
        ViaAction('new', 'new', false);
    end;

    [Test]
    procedure SubPageLinkPart_OnNewRecord()
    begin
        ViaPart('part-new', 'new', false);
    end;

    [Test]
    [HandlerFunctions('ZonesHandler')]
    procedure RunPageLinkList_TableFieldOnValidate_StoredRow_ModifyOnTheCopy()
    begin
        ViaAction('table-validate', 'multi-stored', true);
    end;

    [Test]
    procedure SubPageLinkPart_TableFieldOnValidate_StoredRow_ModifyOnTheCopy()
    begin
        ViaPart('table-validate', 'multi-stored', true);
    end;

    [Test]
    [HandlerFunctions('ZonesHandler')]
    procedure RunPageLinkList_Action_OnLastRow_ModifyOnTheCopy()
    begin
        ViaAction('action', 'check', true);
    end;

    [Test]
    procedure SubPageLinkPart_Action_OnLastRow_ModifyOnTheCopy()
    begin
        ViaPart('part-action', 'check', true);
    end;

}
