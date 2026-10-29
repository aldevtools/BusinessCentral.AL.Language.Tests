// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extending-enums
// Scope: in-scope
// Fixtures used: Library Assert; own enums 90250 and 90251, table 90252, codeunits 90253 and 90255, page 90254
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Settles GitHub issue 6129 (NP Retail): `X::Value` where the table has a field called X (enum "Field Enum") and an enum TYPE
// called X exists too. Inside a procedure of a TableNo codeunit X is the enum type, but inside its OnRun trigger (where Rec is the implicit scope) X is the field. Inside the table itself, inside a page on the table, and
// where a local or global variable called X exists, X is the field or variable (enum "Field Enum"), never the type.
// Must-not-compile companions: tests/must-not-compile/cases/2262 to 2267 (a member that only the other enum has).
// BC versions: 27, 28, 29

enum 90250 "LT UB Field Enum"
{
    value(0; Zero) { }
    value(1; Both) { }
    value(10; OnlyA) { }
}

enum 90251 "LT UB X"
{
    value(0; Zero) { }
    value(2; Both) { }
    value(20; OnlyX) { }
}

table 90252 "LT UB Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; "LT UB X"; Enum "LT UB Field Enum") { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    procedure OnlyA(): Integer
    begin
        exit("LT UB X"::OnlyA.AsInteger());
    end;

    procedure OnlyAText(): Text
    begin
        exit(Format("LT UB X"::OnlyA));
    end;

    procedure Both(): Integer
    begin
        exit("LT UB X"::Both.AsInteger());
    end;

    trigger OnInsert()
    begin
        Id := "LT UB X"::Both.AsInteger();
    end;
}

page 90254 "LT UB Page"
{
    SourceTable = "LT UB Rec";
    layout { area(Content) { field(Id; Rec.Id) { } } }

    procedure PgOnlyA(): Integer
    begin
        exit("LT UB X"::OnlyA.AsInteger());
    end;

    procedure PgOnlyAText(): Text
    begin
        exit(Format("LT UB X"::OnlyA));
    end;

    procedure PgBoth(): Integer
    begin
        exit("LT UB X"::Both.AsInteger());
    end;
}

codeunit 90253 "LT UB Table No"
{
    TableNo = "LT UB Rec";

    procedure OnlyX(): Integer
    begin
        exit("LT UB X"::OnlyX.AsInteger());
    end;

    procedure OnlyXText(): Text
    begin
        exit(Format("LT UB X"::OnlyX));
    end;

    procedure Both(): Integer
    begin
        exit("LT UB X"::Both.AsInteger());
    end;

    trigger OnRun()
    begin
        Rec.Id := "LT UB X"::Both.AsInteger();
    end;
}

codeunit 90256 "LT UB Global Var"
{
    TableNo = "LT UB Rec";

    var
        "LT UB X": Enum "LT UB Field Enum";

    procedure OnlyA(): Integer
    begin
        exit("LT UB X"::OnlyA.AsInteger());
    end;

    procedure Both(): Integer
    begin
        exit("LT UB X"::Both.AsInteger());
    end;

    procedure LocalOnlyA(): Integer
    var
        "LT UB X": Enum "LT UB Field Enum";
    begin
        exit("LT UB X"::OnlyA.AsInteger());
    end;

    procedure LocalBoth(): Integer
    var
        "LT UB X": Enum "LT UB Field Enum";
    begin
        exit("LT UB X"::Both.AsInteger());
    end;
}

codeunit 90255 "LT UB Enum Type Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TableNoCodeunit_ResolvesToEnumType()
    var
        TableNoCu: Codeunit "LT UB Table No";
    begin
        Assert.AreEqual(20, TableNoCu.OnlyX(), 'member only the enum type has');
        Assert.AreEqual('OnlyX', TableNoCu.OnlyXText(), 'Format of that member');
        Assert.AreEqual(2, TableNoCu.Both(), 'member both have: ordinal of the enum type');
    end;

    [Test]
    procedure TableNoCodeunit_OnRunUsesField()
    var
        Rec: Record "LT UB Rec";
    begin
        Codeunit.Run(Codeunit::"LT UB Table No", Rec);
        Assert.AreEqual(1, Rec.Id, 'OnRun of the TableNo codeunit: X is the field of Rec, ordinal of the field enum');
    end;

    [Test]
    procedure TableProcedure_ResolvesToField()
    var
        Rec: Record "LT UB Rec";
    begin
        Assert.AreEqual(10, Rec.OnlyA(), 'member only the field enum has');
        Assert.AreEqual('OnlyA', Rec.OnlyAText(), 'Format of that member');
        Assert.AreEqual(1, Rec.Both(), 'member both have: ordinal of the field enum');
    end;

    [Test]
    procedure TableTrigger_ResolvesToField()
    var
        Rec: Record "LT UB Rec";
    begin
        Rec.Insert(true);
        Assert.AreEqual(1, Rec.Id, 'OnInsert of the table');
    end;

    [Test]
    procedure PageProcedure_ResolvesToField()
    var
        Pg: Page "LT UB Page";
    begin
        Assert.AreEqual(10, Pg.PgOnlyA(), 'member only the field enum has');
        Assert.AreEqual('OnlyA', Pg.PgOnlyAText(), 'Format of that member');
        Assert.AreEqual(1, Pg.PgBoth(), 'member both have: ordinal of the field enum');
    end;

    [Test]
    procedure GlobalVariable_ShadowsEnumType()
    var
        Cu: Codeunit "LT UB Global Var";
    begin
        Assert.AreEqual(10, Cu.OnlyA(), 'member only the variable enum has');
        Assert.AreEqual(1, Cu.Both(), 'member both have: ordinal of the variable enum');
    end;

    [Test]
    procedure LocalVariable_ShadowsEnumType()
    var
        Cu: Codeunit "LT UB Global Var";
    begin
        Assert.AreEqual(10, Cu.LocalOnlyA(), 'member only the variable enum has');
        Assert.AreEqual(1, Cu.LocalBoth(), 'member both have: ordinal of the variable enum');
    end;
}
