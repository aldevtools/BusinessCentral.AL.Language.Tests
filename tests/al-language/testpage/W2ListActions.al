// Probe: the built-in Edit and View actions of a list page: Visible and Enabled, on a list with a CardPageId, without one, and not editable; with rows and with none.
// Settles: md:282 (Visible and Enabled of the built-in Edit and View actions on a list; the open and read-only behaviour is pinned already).

table 68709 "W2 Card Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Descr; Text[30]) { }
        field(3; Grp; Text[10]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 68710 "W2 Edit Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Card Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Descr; Rec.Descr) { ApplicationArea = All; }
        }
    }
}

page 68711 "W2 Edit List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Card Row";
    CardPageId = "W2 Edit Card";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 68712 "W2 Edit List NoCard"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Card Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 68713 "W2 Edit List ReadOnly"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Card Row";
    CardPageId = "W2 Edit Card";
    Editable = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 68714 "W2 List Action Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(WithRows: Boolean)
    var
        Row: Record "W2 Card Row";
    begin
        Row.DeleteAll();
        if WithRows then begin
            Row."No." := 'A';
            Row.Descr := 'Alpha';
            Row.Insert();
            Row."No." := 'B';
            Row.Descr := 'Bravo';
            Row.Insert();
        end;
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; Result: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, Format(Result))
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure List_WithRows()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Edit List";
        Result: Boolean;
    begin
        Seed(true);
        Pg.OpenView();
        Report(Observer, 'edit_visible', ListEditVisible(Pg, Result), Result);
        Report(Observer, 'edit_enabled', ListEditEnabled(Pg, Result), Result);
        Report(Observer, 'view_visible', ListViewVisible(Pg, Result), Result);
        Report(Observer, 'view_enabled', ListViewEnabled(Pg, Result), Result);
        Pg.Close();
        Observer.Expect('edit_visible', 'Yes');
        Observer.Expect('edit_enabled', 'Yes');
        Observer.Expect('view_visible', 'Yes');
        Observer.Expect('view_enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure List_NoRows()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Edit List";
        Result: Boolean;
    begin
        Seed(false);
        Pg.OpenView();
        Report(Observer, 'edit_visible', ListEditVisible(Pg, Result), Result);
        Report(Observer, 'edit_enabled', ListEditEnabled(Pg, Result), Result);
        Report(Observer, 'view_visible', ListViewVisible(Pg, Result), Result);
        Report(Observer, 'view_enabled', ListViewEnabled(Pg, Result), Result);
        Pg.Close();
        Observer.Expect('edit_visible', 'Yes');
        Observer.Expect('edit_enabled', 'No');
        Observer.Expect('view_visible', 'Yes');
        Observer.Expect('view_enabled', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure List_OpenedForEdit()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Edit List";
        Result: Boolean;
    begin
        Seed(true);
        Pg.OpenEdit();
        Report(Observer, 'edit_visible', ListEditVisible(Pg, Result), Result);
        Report(Observer, 'edit_enabled', ListEditEnabled(Pg, Result), Result);
        Report(Observer, 'view_visible', ListViewVisible(Pg, Result), Result);
        Report(Observer, 'view_enabled', ListViewEnabled(Pg, Result), Result);
        Pg.Close();
        Observer.Expect('edit_visible', 'Yes');
        Observer.Expect('edit_enabled', 'Yes');
        Observer.Expect('view_visible', 'Yes');
        Observer.Expect('view_enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NoCard_WithRows()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Edit List NoCard";
        Result: Boolean;
    begin
        Seed(true);
        Pg.OpenView();
        Report(Observer, 'edit_visible', NoCardEditVisible(Pg, Result), Result);
        Report(Observer, 'edit_enabled', NoCardEditEnabled(Pg, Result), Result);
        Report(Observer, 'view_visible', NoCardViewVisible(Pg, Result), Result);
        Report(Observer, 'view_enabled', NoCardViewEnabled(Pg, Result), Result);
        Pg.Close();
        Observer.Expect('edit_visible', 'Yes');
        Observer.Expect('edit_enabled', 'Yes');
        Observer.Expect('view_visible', 'Yes');
        Observer.Expect('view_enabled', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure NoCard_OpenedForEdit()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Edit List NoCard";
        Result: Boolean;
    begin
        Seed(true);
        Pg.OpenEdit();
        Report(Observer, 'edit_visible', NoCardEditVisible(Pg, Result), Result);
        Report(Observer, 'edit_enabled', NoCardEditEnabled(Pg, Result), Result);
        Report(Observer, 'view_visible', NoCardViewVisible(Pg, Result), Result);
        Report(Observer, 'view_enabled', NoCardViewEnabled(Pg, Result), Result);
        Pg.Close();
        Observer.Expect('edit_visible', 'Yes');
        Observer.Expect('edit_enabled', 'No');
        Observer.Expect('view_visible', 'Yes');
        Observer.Expect('view_enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadOnly_WithRows()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Edit List ReadOnly";
        Result: Boolean;
    begin
        Seed(true);
        Pg.OpenView();
        Report(Observer, 'edit_visible', ReadOnlyEditVisible(Pg, Result), Result);
        Report(Observer, 'edit_enabled', ReadOnlyEditEnabled(Pg, Result), Result);
        Report(Observer, 'view_visible', ReadOnlyViewVisible(Pg, Result), Result);
        Report(Observer, 'view_enabled', ReadOnlyViewEnabled(Pg, Result), Result);
        Pg.Close();
        Observer.Expect('edit_visible', 'Yes');
        Observer.Expect('edit_enabled', 'Yes');
        Observer.Expect('view_visible', 'Yes');
        Observer.Expect('view_enabled', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadOnly_OpenedForEdit()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Edit List ReadOnly";
        Result: Boolean;
    begin
        Seed(true);
        Pg.OpenEdit();
        Report(Observer, 'edit_visible', ReadOnlyEditVisible(Pg, Result), Result);
        Report(Observer, 'edit_enabled', ReadOnlyEditEnabled(Pg, Result), Result);
        Report(Observer, 'view_visible', ReadOnlyViewVisible(Pg, Result), Result);
        Report(Observer, 'view_enabled', ReadOnlyViewEnabled(Pg, Result), Result);
        Pg.Close();
        Observer.Expect('edit_visible', 'Yes');
        Observer.Expect('edit_enabled', 'Yes');
        Observer.Expect('view_visible', 'Yes');
        Observer.Expect('view_enabled', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure ListEditVisible(var Pg: TestPage "W2 Edit List"; var Result: Boolean)
    begin
        Result := Pg.Edit().Visible();
    end;

    [TryFunction]
    local procedure ListEditEnabled(var Pg: TestPage "W2 Edit List"; var Result: Boolean)
    begin
        Result := Pg.Edit().Enabled();
    end;

    [TryFunction]
    local procedure ListViewVisible(var Pg: TestPage "W2 Edit List"; var Result: Boolean)
    begin
        Result := Pg.View().Visible();
    end;

    [TryFunction]
    local procedure ListViewEnabled(var Pg: TestPage "W2 Edit List"; var Result: Boolean)
    begin
        Result := Pg.View().Enabled();
    end;

    [TryFunction]
    local procedure NoCardEditVisible(var Pg: TestPage "W2 Edit List NoCard"; var Result: Boolean)
    begin
        Result := Pg.Edit().Visible();
    end;

    [TryFunction]
    local procedure NoCardEditEnabled(var Pg: TestPage "W2 Edit List NoCard"; var Result: Boolean)
    begin
        Result := Pg.Edit().Enabled();
    end;

    [TryFunction]
    local procedure NoCardViewVisible(var Pg: TestPage "W2 Edit List NoCard"; var Result: Boolean)
    begin
        Result := Pg.View().Visible();
    end;

    [TryFunction]
    local procedure NoCardViewEnabled(var Pg: TestPage "W2 Edit List NoCard"; var Result: Boolean)
    begin
        Result := Pg.View().Enabled();
    end;

    [TryFunction]
    local procedure ReadOnlyEditVisible(var Pg: TestPage "W2 Edit List ReadOnly"; var Result: Boolean)
    begin
        Result := Pg.Edit().Visible();
    end;

    [TryFunction]
    local procedure ReadOnlyEditEnabled(var Pg: TestPage "W2 Edit List ReadOnly"; var Result: Boolean)
    begin
        Result := Pg.Edit().Enabled();
    end;

    [TryFunction]
    local procedure ReadOnlyViewVisible(var Pg: TestPage "W2 Edit List ReadOnly"; var Result: Boolean)
    begin
        Result := Pg.View().Visible();
    end;

    [TryFunction]
    local procedure ReadOnlyViewEnabled(var Pg: TestPage "W2 Edit List ReadOnly"; var Result: Boolean)
    begin
        Result := Pg.View().Enabled();
    end;
}
