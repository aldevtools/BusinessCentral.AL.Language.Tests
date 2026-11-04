// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); declares tables 74047-74049, pages 74050-74052
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestPage field.Lookup() on a field whose only lookup source is a TableRelation with several arms (if (Kind = const(1)) A else if (Kind = const(2)) B), with no arm matching, with a where clause that reads a field of the same record, and with a const filter: which lookup page opens, which rows it shows, what is written back
// BC versions: 29 (27 and 28 by CI)

table 74047 "LT P133 Target A"
{
    DataClassification = CustomerContent;
    LookupPageId = "LT P133 Target A List";

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 74048 "LT P133 Target B"
{
    DataClassification = CustomerContent;
    LookupPageId = "LT P133 Target B List";

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 74049 "LT P133 Host"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Integer) { }
        field(3; Ref; Code[10])
        {
            TableRelation = if (Kind = const(1)) "LT P133 Target A" else
            if (Kind = const(2)) "LT P133 Target B";
        }
        field(4; Wanted; Text[30]) { }
        field(5; RefByField; Code[10])
        {
            TableRelation = "LT P133 Target A" where(Descr = field(Wanted));
        }
        field(6; RefConst; Code[10])
        {
            TableRelation = "LT P133 Target A" where(Descr = filter('Alpha' | 'Gamma'));
        }
        field(7; RefThree; Code[10])
        {
            TableRelation = if (Kind = const(1)) "LT P133 Target A" else
            if (Kind = const(2)) "LT P133 Target B" else
            if (Kind = const(3)) "LT P133 Target A" where(Descr = const('Gamma'));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 74050 "LT P133 Target A List"
{
    PageType = List;
    SourceTable = "LT P133 Target A";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec.Code) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 74051 "LT P133 Target B List"
{
    PageType = List;
    SourceTable = "LT P133 Target B";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec.Code) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 74052 "LT P133 Host Card"
{
    PageType = Card;
    SourceTable = "LT P133 Host";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Kind; Rec.Kind) { ApplicationArea = All; }
            field(Ref; Rec.Ref) { ApplicationArea = All; }
            field(Wanted; Rec.Wanted) { ApplicationArea = All; }
            field(RefByField; Rec.RefByField) { ApplicationArea = All; }
            field(RefConst; Rec.RefConst) { ApplicationArea = All; }
            field(RefThree; Rec.RefThree) { ApplicationArea = All; }
        }
    }
}

codeunit 74053 "LT P133 Relation Lookups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Text;

    local procedure Seed()
    var
        A: Record "LT P133 Target A";
        B: Record "LT P133 Target B";
        Host: Record "LT P133 Host";
    begin
        A.DeleteAll();
        B.DeleteAll();
        Host.DeleteAll();
        A.Code := 'A1';
        A.Descr := 'Alpha';
        A.Insert();
        A.Code := 'A2';
        A.Descr := 'Beta';
        A.Insert();
        A.Code := 'A3';
        A.Descr := 'Gamma';
        A.Insert();
        B.Code := 'B1';
        B.Descr := 'Bravo';
        B.Insert();
        B.Code := 'B2';
        B.Descr := 'Beta';
        B.Insert();
        Host.Id := 1;
        Host.Kind := 1;
        Host.Wanted := 'Beta';
        Host.Insert();
        Host.Id := 2;
        Host.Kind := 2;
        Host.Wanted := 'Gamma';
        Host.Insert();
        Host.Id := 3;
        Host.Kind := 0;
        Host.Wanted := 'Nothing';
        Host.Insert();
        Host.Id := 4;
        Host.Kind := 3;
        Host.Wanted := 'Alpha';
        Host.Insert();
        Seen := '';
    end;

    [ModalPageHandler]
    procedure LookupA(var P: TestPage "LT P133 Target A List")
    var
        Rows: Text;
    begin
        if P.First() then
            repeat
                Rows += P.Code.Value + ',';
            until not P.Next();
        Seen += 'A list rows=' + Rows + ';';
        if P.First() then;
        Seen += 'picked=' + P.Code.Value + ';';
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupB(var P: TestPage "LT P133 Target B List")
    var
        Rows: Text;
    begin
        if P.First() then
            repeat
                Rows += P.Code.Value + ',';
            until not P.Next();
        Seen += 'B list rows=' + Rows + ';';
        if P.First() then;
        Seen += 'picked=' + P.Code.Value + ';';
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LookupACancel(var P: TestPage "LT P133 Target A List")
    begin
        Seen += 'A cancel;';
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryLookupRef(var Pg: TestPage "LT P133 Host Card")
    begin
        Pg.Ref.Lookup();
    end;

    [TryFunction]
    local procedure TryLookupByField(var Pg: TestPage "LT P133 Host Card")
    begin
        Pg.RefByField.Lookup();
    end;

    [TryFunction]
    local procedure TryLookupConst(var Pg: TestPage "LT P133 Host Card")
    begin
        Pg.RefConst.Lookup();
    end;

    [TryFunction]
    local procedure TryLookupThree(var Pg: TestPage "LT P133 Host Card")
    begin
        Pg.RefThree.Lookup();
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; Value: Text)
    begin
        if Ok then
            Observer.Observe(Name, 'ok value=[' + Value + '] seen=' + Seen)
        else begin
            Observer.Observe(Name, 'err ' + GetLastErrorText() + ' seen=' + Seen);
            ClearLastError();
        end;
        Seen := '';
    end;

    [Test]
    [HandlerFunctions('LookupA')]
    procedure P133_Lookup_SeveralArms_FirstArmMatches()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P133 Host Card";
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(1);
        Ok := TryLookupRef(Pg);
        Show(Observer, 'kind 1', Ok, Pg.Ref.Value);
        Pg.Close();
        Observer.Expect('kind 1', 'ok value=[A1] seen=A list rows=A1,A2,A3,;picked=A1;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupB')]
    procedure P133_Lookup_SeveralArms_SecondArmMatches()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P133 Host Card";
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(2);
        Ok := TryLookupRef(Pg);
        Show(Observer, 'kind 2', Ok, Pg.Ref.Value);
        Pg.Close();
        Observer.Expect('kind 2', 'ok value=[B1] seen=B list rows=B1,B2,;picked=B1;');
        Observer.Verify();
    end;

    [Test]
    procedure P133_Lookup_SeveralArms_NoArmMatches()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P133 Host Card";
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(3);
        Ok := TryLookupRef(Pg);
        Show(Observer, 'kind 0', Ok, Pg.Ref.Value);
        Pg.GoToKey(4);
        Ok := TryLookupRef(Pg);
        Show(Observer, 'kind 3 (no arm for it on Ref)', Ok, Pg.Ref.Value);
        Pg.Close();
        Observer.Expect('kind 0', 'ok value=[] seen=');
        Observer.Expect('kind 3 (no arm for it on Ref)', 'ok value=[] seen=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupA,LookupB')]
    procedure P133_Lookup_SeveralArms_KindChangedOnThePage()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P133 Host Card";
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(1);
        Ok := TryLookupRef(Pg);
        Show(Observer, 'kind 1', Ok, Pg.Ref.Value);
        Pg.Kind.SetValue(2);
        Ok := TryLookupRef(Pg);
        Show(Observer, 'kind changed to 2 on the page', Ok, Pg.Ref.Value);
        Pg.Close();
        Observer.Expect('kind 1', 'ok value=[A1] seen=A list rows=A1,A2,A3,;picked=A1;');
        Observer.Expect('kind changed to 2 on the page', 'ok value=[B1] seen=B list rows=B1,B2,;picked=B1;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupACancel')]
    procedure P133_Lookup_SeveralArms_CancelKeepsTheValue()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P133 Host Card";
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(1);
        Pg.Ref.SetValue('A2');
        Ok := TryLookupRef(Pg);
        Show(Observer, 'cancel with A2', Ok, Pg.Ref.Value);
        Pg.Close();
        Observer.Expect('cancel with A2', 'ok value=[A2] seen=A cancel;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupA')]
    procedure P133_Lookup_WhereFieldOfTheSameRecord()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P133 Host Card";
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(1);
        Ok := TryLookupByField(Pg);
        Show(Observer, 'wanted Beta', Ok, Pg.RefByField.Value);
        Pg.Close();
        Observer.Expect('wanted Beta', 'ok value=[A2] seen=A list rows=A2,;picked=A2;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupA')]
    procedure P133_Lookup_ConstFilterWithTwoValues()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P133 Host Card";
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(1);
        Ok := TryLookupConst(Pg);
        Show(Observer, 'filter Alpha|Gamma', Ok, Pg.RefConst.Value);
        Pg.Close();
        Observer.Expect('filter Alpha|Gamma', 'ok value=[A1] seen=A list rows=A1,A3,;picked=A1;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('LookupA,LookupB')]
    procedure P133_Lookup_ThreeArms_OneWithWhere()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT P133 Host Card";
        Ok: Boolean;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.GoToKey(4);
        Ok := TryLookupThree(Pg);
        Show(Observer, 'kind 3 third arm with where', Ok, Pg.RefThree.Value);
        Pg.GoToKey(2);
        Ok := TryLookupThree(Pg);
        Show(Observer, 'kind 2 second arm', Ok, Pg.RefThree.Value);
        Pg.Close();
        Observer.Expect('kind 3 third arm with where', 'ok value=[A3] seen=A list rows=A3,;picked=A3;');
        Observer.Expect('kind 2 second arm', 'ok value=[B1] seen=B list rows=B1,B2,;picked=B1;');
        Observer.Verify();
    end;
}
