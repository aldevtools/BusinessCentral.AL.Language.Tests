// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-updatepropagation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT AA Row", page "LT AA Part List" and codeunit "LT AA Counter" (AaObjects.al)
// BC versions: 27+ (tested by the corpus CI matrix)
// Facts: part UpdatePropagation (Both, SubPart, default): whether CurrPage.Update(true) in the part reloads the host page.
// Repeater ShowAsTree / TreeInitialState / IndentationColumn / IndentationControls / FreezeColumn / FileUploadAction / FileUploadRowAction and list page views
// with SharedLayout: the rows a TestPage lists.

page 76508 "LT AA Host Both"
{
    PageType = Card;
    SourceTable = "LT AA Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
            part(Lines; "LT AA Part List")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
                SubPageLink = Id = field(Id);
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Counter: Codeunit "LT AA Counter";
    begin
        Counter.HostLoaded();
    end;
}

page 76509 "LT AA Host Sub"
{
    PageType = Card;
    SourceTable = "LT AA Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
            part(Lines; "LT AA Part List")
            {
                ApplicationArea = All;
                UpdatePropagation = SubPart;
                SubPageLink = Id = field(Id);
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Counter: Codeunit "LT AA Counter";
    begin
        Counter.HostLoaded();
    end;
}

page 76510 "LT AA Host Default"
{
    PageType = Card;
    SourceTable = "LT AA Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
            part(Lines; "LT AA Part List")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Counter: Codeunit "LT AA Counter";
    begin
        Counter.HostLoaded();
    end;
}

page 76506 "LT AA Tree List"
{
    PageType = List;
    SourceTable = "LT AA Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Rec.Lvl;
                IndentationControls = Txt;
                ShowAsTree = true;
                TreeInitialState = ExpandAll;
                FreezeColumn = Id;
                FileUploadAction = TreeUpload;
                FileUploadRowAction = TreeRowUpload;

                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Txt; Rec.Txt) { ApplicationArea = All; }
                field(Lvl; Rec.Lvl) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            fileuploadaction(TreeUpload)
            {
                ApplicationArea = All;

                trigger OnAction(Files: List of [FileUpload])
                begin
                end;
            }
            fileuploadaction(TreeRowUpload)
            {
                ApplicationArea = All;

                trigger OnAction(Files: List of [FileUpload])
                begin
                end;
            }
        }
    }

    views
    {
        view(SharedView)
        {
            Caption = 'Shared';
            SharedLayout = true;
            Filters = where(Id = filter('A*'));
        }
        view(UniqueView)
        {
            Caption = 'Unique';
            SharedLayout = false;
            Filters = where(Id = filter('B*'));
        }
    }
}

page 76511 "LT AA Indent List"
{
    PageType = List;
    SourceTable = "LT AA Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                IndentationColumn = Rec.Lvl;
                IndentationControls = Id, Txt;

                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Txt; Rec.Txt) { ApplicationArea = All; }
                field(Lvl; Rec.Lvl) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 76512 "LT AA Part List Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AA_UpdatePropagation_Both()
    var
        Observer: Codeunit "Probe Observer";
        Counter: Codeunit "LT AA Counter";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Host Both";
    begin
        Seed(Row);
        Counter.Reset();
        P.OpenEdit();
        Observer.Observe('loads-after-open', Format(Counter.GetHostLoads()));
        Observer.Observe('part-row', P.Lines.Id.Value());
        P.Lines.Txt.SetValue('edited');
        Observer.Observe('loads-after-part-edit', Format(Counter.GetHostLoads()));
        Observer.Observe('host-txt-after-part-edit', P.Txt.Value());
        P.Close();
        Row.Get('A');
        Observer.Observe('stored', Row.Txt);
        Observer.Expect('loads-after-open', '1');
        Observer.Expect('part-row', 'A');
        Observer.Expect('loads-after-part-edit', '2');
        Observer.Expect('host-txt-after-part-edit', 'edited');
        Observer.Expect('stored', 'edited');
        Observer.Verify();
    end;

    [Test]
    procedure AA_UpdatePropagation_SubPart()
    var
        Observer: Codeunit "Probe Observer";
        Counter: Codeunit "LT AA Counter";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Host Sub";
    begin
        Seed(Row);
        Counter.Reset();
        P.OpenEdit();
        Observer.Observe('loads-after-open', Format(Counter.GetHostLoads()));
        Observer.Observe('part-row', P.Lines.Id.Value());
        P.Lines.Txt.SetValue('edited');
        Observer.Observe('loads-after-part-edit', Format(Counter.GetHostLoads()));
        Observer.Observe('host-txt-after-part-edit', P.Txt.Value());
        P.Close();
        Row.Get('A');
        Observer.Observe('stored', Row.Txt);
        Observer.Expect('loads-after-open', '1');
        Observer.Expect('part-row', 'A');
        Observer.Expect('loads-after-part-edit', '2');
        Observer.Expect('host-txt-after-part-edit', 'edited');
        Observer.Expect('stored', 'edited');
        Observer.Verify();
    end;

    [Test]
    procedure AA_UpdatePropagation_Default()
    var
        Observer: Codeunit "Probe Observer";
        Counter: Codeunit "LT AA Counter";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Host Default";
    begin
        Seed(Row);
        Counter.Reset();
        P.OpenEdit();
        Observer.Observe('loads-after-open', Format(Counter.GetHostLoads()));
        Observer.Observe('part-row', P.Lines.Id.Value());
        P.Lines.Txt.SetValue('edited');
        Observer.Observe('loads-after-part-edit', Format(Counter.GetHostLoads()));
        Observer.Observe('host-txt-after-part-edit', P.Txt.Value());
        P.Close();
        Row.Get('A');
        Observer.Observe('stored', Row.Txt);
        Observer.Expect('loads-after-open', '1');
        Observer.Expect('part-row', 'A');
        Observer.Expect('loads-after-part-edit', '2');
        Observer.Expect('host-txt-after-part-edit', 'edited');
        Observer.Expect('stored', 'edited');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Repeater_TreeExpandedRows()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Tree List";
        Rows: Text;
        Count: Integer;
    begin
        SeedTree(Row);
        P.OpenView();
        if P.First() then
            repeat
                Count += 1;
                Rows += P.Id.Value() + '/' + P.Txt.Value() + '/' + P.Lvl.Value() + ',';
            until not P.Next();
        Observer.Observe('count', Format(Count));
        Observer.Observe('rows', Rows);
        P.Close();
        Observer.Expect('count', '2');
        Observer.Expect('rows', 'A1/Root/0,B1/Other root/0,');
        Observer.Verify();
    end;

    [Test]
    procedure AA_Repeater_IndentationControlsRows()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AA Row";
        P: TestPage "LT AA Indent List";
        Rows: Text;
        Count: Integer;
    begin
        SeedTree(Row);
        P.OpenView();
        if P.First() then
            repeat
                Count += 1;
                Rows += P.Id.Value() + '/' + P.Txt.Value() + '/' + P.Lvl.Value() + ',';
            until not P.Next();
        Observer.Observe('count', Format(Count));
        Observer.Observe('rows', Rows);
        Observer.Observe('id-editable', Format(P.Id.Editable()));
        P.Close();
        Observer.Expect('count', '4');
        Observer.Expect('rows', 'A1/Root/0,A2/Child/1,A3/Grandchild/2,B1/Other root/0,');
        Observer.Expect('id-editable', 'No');
        Observer.Verify();
    end;

    local procedure Seed(var Row: Record "LT AA Row")
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 'A';
        Row.Insert();
        Commit();
    end;

    local procedure SeedTree(var Row: Record "LT AA Row")
    begin
        Row.DeleteAll();
        InsertRow(Row, 'A1', 'Root', 0);
        InsertRow(Row, 'A2', 'Child', 1);
        InsertRow(Row, 'A3', 'Grandchild', 2);
        InsertRow(Row, 'B1', 'Other root', 0);
    end;

    local procedure InsertRow(var Row: Record "LT AA Row"; NewId: Code[20]; NewTxt: Text[30]; NewLvl: Integer)
    begin
        Row.Init();
        Row.Id := NewId;
        Row.Txt := NewTxt;
        Row.Lvl := NewLvl;
        Row.Insert();
    end;
}
