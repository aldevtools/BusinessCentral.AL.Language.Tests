// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 92643 - 92648
// Probe: gap cycle 3 spec C3-14. A dialog with two line parts behind Visible variables, opened by Page.RunModal on a Page variable
//   (LookupMode); after RunModal returned, a procedure of the dialog reaches a part through CurrPage.<part>.Page and the part copies its
//   Rec and calls CurrPage.SetSelectionFilter (the shape of a "get posted document lines" dialog). Also CurrPage.Update / SaveRecord and a
//   part's CurrPage.Update called by the dialog's code after it closed. Every literal asserted below is what the BC service tier produced.
// Facts: the record the part hands out after the dialog closed (OK, Cancel, a moved part row, the other part shown by an option control),
//   on a dialog that never ran, and after Page.Run closed; ok or the error text and code of Update / SaveRecord after close.
// BC versions: 27, 28, 29

table 92643 "LT Y37 PC Vend"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 92644 "LT Y37 PC Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Vend; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Kind; Integer) { }
        field(4; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; Vend, "Line No.") { Clustered = true; }
    }
}

page 92645 "LT Y37 PC Part A"
{
    PageType = ListPart;
    SourceTable = "LT Y37 PC Line";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    procedure GetSelectedLine(var L: Record "LT Y37 PC Line")
    begin
        L.Copy(Rec);
        CurrPage.SetSelectionFilter(L);
    end;

    procedure PartUpdate()
    begin
        CurrPage.Update(false);
    end;

    procedure RecText(): Text
    begin
        exit(Rec.Vend + '/' + Format(Rec."Line No.") + ' filters [' + Rec.GetFilters() + ']');
    end;
}

page 92646 "LT Y37 PC Part B"
{
    PageType = ListPart;
    SourceTable = "LT Y37 PC Line";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    procedure GetSelectedLine(var L: Record "LT Y37 PC Line")
    begin
        L.Copy(Rec);
        CurrPage.SetSelectionFilter(L);
    end;
}

page 92647 "LT Y37 PC Dialog"
{
    PageType = Card;
    SourceTable = "LT Y37 PC Vend";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; Editable = false; }
            field(MenuOpt; MenuOpt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    ChangeMenu(MenuOpt);
                end;
            }
            part(PartA; "LT Y37 PC Part A")
            {
                ApplicationArea = All;
                SubPageLink = Vend = field("No.");
                SubPageView = where(Kind = const(0));
                Visible = VisA;
            }
            part(PartB; "LT Y37 PC Part B")
            {
                ApplicationArea = All;
                SubPageLink = Vend = field("No.");
                SubPageView = where(Kind = const(1));
                Visible = VisB;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ChangeMenu(MenuOpt::x0);
    end;

    var
        MenuOpt: Option x0,x1;
        CurrentMenu: Integer;
        VisA: Boolean;
        VisB: Boolean;

    local procedure ChangeMenu(NewMenu: Integer)
    begin
        VisA := NewMenu = 0;
        VisB := NewMenu = 1;
        CurrentMenu := NewMenu;
    end;

    procedure GetCurrentMenu(): Integer
    begin
        exit(CurrentMenu);
    end;

    procedure CopySel(Menu: Integer; var L: Record "LT Y37 PC Line")
    begin
        case Menu of
            0:
                CurrPage.PartA.Page.GetSelectedLine(L);
            1:
                CurrPage.PartB.Page.GetSelectedLine(L);
        end;
    end;

    procedure PartARecText(): Text
    begin
        exit(CurrPage.PartA.Page.RecText());
    end;

    procedure HostUpdate(Save: Boolean)
    begin
        CurrPage.Update(Save);
    end;

    procedure HostSaveRecord()
    begin
        CurrPage.SaveRecord();
    end;

    procedure PartAUpdate()
    begin
        CurrPage.PartA.Page.PartUpdate();
    end;
}

codeunit 92648 "LT Y37 PC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        HandlerMode: Integer;

    local procedure Seed(var V: Record "LT Y37 PC Vend")
    var
        L: Record "LT Y37 PC Line";
    begin
        V.DeleteAll();
        L.DeleteAll();
        V."No." := 'V2';
        V.Insert();
        AddLine('V2', 10000, 0, 'x1');
        V."No." := 'V1';
        V.Name := 'One';
        V.Insert();
        AddLine('V1', 10000, 0, 'a1');
        AddLine('V1', 20000, 0, 'a2');
        AddLine('V1', 30000, 1, 'b1');
        AddLine('V1', 40000, 1, 'b2');
    end;

    local procedure AddLine(Vend: Code[20]; LineNo: Integer; Kind: Integer; Descr: Text[30])
    var
        L: Record "LT Y37 PC Line";
    begin
        L.Vend := Vend;
        L."Line No." := LineNo;
        L.Kind := Kind;
        L.Descr := Descr;
        L.Insert();
    end;

    local procedure Lines(var L: Record "LT Y37 PC Line"): Text
    var
        T: Text;
    begin
        if L.FindSet() then
            repeat
                T += Format(L."Line No.") + ';';
            until L.Next() = 0;
        exit(T);
    end;

    // Copies the selection of part Menu into a record and observes its count, filters and rows; an error is observed instead.
    local procedure ObserveSel(Name: Text; var Pg: Page "LT Y37 PC Dialog"; Menu: Integer)
    var
        L: Record "LT Y37 PC Line";
    begin
        ClearLastError();
        if TryCopySel(Pg, Menu, L) then begin
            Observer.Observe(Name + ' count', Format(L.Count()));
            Observer.Observe(Name + ' filters', L.GetFilters());
            Observer.Observe(Name + ' rows', Lines(L));
        end else
            Observer.ObserveError(Name + ' error');
    end;

    [TryFunction]
    local procedure TryCopySel(var Pg: Page "LT Y37 PC Dialog"; Menu: Integer; var L: Record "LT Y37 PC Line")
    begin
        Pg.CopySel(Menu, L);
    end;

    [TryFunction]
    local procedure TryHostUpdate(var Pg: Page "LT Y37 PC Dialog"; Save: Boolean)
    begin
        Pg.HostUpdate(Save);
    end;

    [TryFunction]
    local procedure TryHostSaveRecord(var Pg: Page "LT Y37 PC Dialog")
    begin
        Pg.HostSaveRecord();
    end;

    [TryFunction]
    local procedure TryPartAUpdate(var Pg: Page "LT Y37 PC Dialog")
    begin
        Pg.PartAUpdate();
    end;

    [TryFunction]
    local procedure TryPartARecText(var Pg: Page "LT Y37 PC Dialog"; var T: Text)
    begin
        T := Pg.PartARecText();
    end;

    local procedure Step(Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name, Format(Ok));
        if not Ok then
            Observer.ObserveError(Name + ' error')
        else
            ClearLastError();
    end;

    local procedure RunDialog(var Pg: Page "LT Y37 PC Dialog"; var V: Record "LT Y37 PC Vend"; Mode: Integer)
    begin
        HandlerMode := Mode;
        Pg.SetRecord(V);
        Pg.LookupMode := true;
        Observer.Observe('runmodal', Format(Pg.RunModal()));
    end;

    [ModalPageHandler]
    procedure DialogHandler(var P: TestPage "LT Y37 PC Dialog")
    begin
        case HandlerMode of
            0:
                P.OK().Invoke();
            1:
                begin
                    P.PartA.Last();
                    P.OK().Invoke();
                end;
            2:
                begin
                    P.MenuOpt.SetValue('x1');
                    P.PartB.Last();
                    P.OK().Invoke();
                end;
            3:
                P.Cancel().Invoke();
        end;
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure LT_C314_AfterRunModalOK_PartSelection()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
        T: Text;
    begin
        Seed(V);
        RunDialog(Pg, V, 0);
        Observer.Observe('menu', Format(Pg.GetCurrentMenu()));
        ObserveSel('A', Pg, 0);
        if TryPartARecText(Pg, T) then
            Observer.Observe('A rec', T)
        else
            Observer.ObserveError('A rec error');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure LT_C314_AfterRunModalOK_PartRowMoved()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
    begin
        Seed(V);
        RunDialog(Pg, V, 1);
        ObserveSel('A', Pg, 0);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure LT_C314_AfterRunModalOK_OtherPartShown()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
    begin
        Seed(V);
        RunDialog(Pg, V, 2);
        Observer.Observe('menu', Format(Pg.GetCurrentMenu()));
        ObserveSel('B', Pg, 1);
        ObserveSel('A hidden', Pg, 0);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure LT_C314_AfterRunModalCancel_PartSelection()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
    begin
        Seed(V);
        RunDialog(Pg, V, 3);
        ObserveSel('A', Pg, 0);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure LT_C314_AfterRunModalOK_UpdateAndSave()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
    begin
        Seed(V);
        RunDialog(Pg, V, 0);
        Step('host update false', TryHostUpdate(Pg, false));
        Step('host update true', TryHostUpdate(Pg, true));
        Step('host saverecord', TryHostSaveRecord(Pg));
        Step('part update', TryPartAUpdate(Pg));
        ObserveSel('A after', Pg, 0);
        V.Get('V1');
        Observer.Observe('stored name', V.Name);
        Observer.Finish();
    end;

    [Test]
    procedure LT_C314_NeverRan_PartSelection()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
    begin
        Seed(V);
        Pg.SetRecord(V);
        ObserveSel('A', Pg, 0);
        ObserveSel('B', Pg, 1);
        Step('host update false', TryHostUpdate(Pg, false));
        Step('host saverecord', TryHostSaveRecord(Pg));
        Observer.Finish();
    end;

    [Test]
    procedure LT_C314_AfterRunClosed_PartSelection()
    var
        V: Record "LT Y37 PC Vend";
        Pg: Page "LT Y37 PC Dialog";
        P: TestPage "LT Y37 PC Dialog";
    begin
        Seed(V);
        P.Trap();
        Pg.SetRecord(V);
        Pg.Run();
        Observer.Observe('shown no', P."No.".Value());
        P.PartA.Last();
        Observer.Observe('shown part row', P.PartA."Line No.".Value());
        ObserveSel('A shown', Pg, 0);
        P.Close();
        ObserveSel('A closed', Pg, 0);
        Step('host update false closed', TryHostUpdate(Pg, false));
        Observer.Finish();
    end;
}
