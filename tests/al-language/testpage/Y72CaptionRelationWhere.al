// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionfields-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al) where logs are read; own objects: table 93851,93852,93853,93854,93855,93856; codeunit 93851,93852; page 93854,93855,93856,93857
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: the caption of a list whose DataCaptionFields field has a TableRelation with a where(field()) clause to a table with a
//   two-field primary key (the journal pattern: a batch name related to the batch table of the template). The batch table declares
//   DataCaptionFields = Name, Description. The page sets the template and batch filter in filter group 2 in OnOpenPage (the journal
//   pattern), or the caller hands a filtered record (filter group 0). Also: a const where on a one-field key, only the batch filtered
//   (no template), DataCaptionFields declared on the table instead of the page.
//   Batch rows (Tmpl, Name, Description): (T1, BAT, 'Batch one'), (T2, BAT, 'Batch two'), (T1, OTHER, '').
// Neighbours: pages/lt-y45-list-caption-relation/Y45ListCaptionRelation.al (a one-field key relation without where()).
// Measured (27.5, 28.5, 29.0 and SaaS 29 alike): with the template and batch filter in filter group 2 the caption of the journal list is
//   '<page caption> - BAT ∙ Batch one' for T1/BAT, and also for T2/BAT (the related row is the first row of the batch table with that name,
//   whatever the template: 'Batch one', not 'Batch two'). A batch without a description shows only the name ('... - OTHER'), also when no
//   batch of that name exists in the template (T2/OTHER). A const where clause on a one-field key shows the related row only when the
//   const matches ('X1 ∙ x'); a row whose const does not match shows its own description ('X2 ∙ y' as well); a missing batch row shows
//   no suffix. With only the batch filtered the caption is the same as with both. DataCaptionFields declared on the table (not the page)
//   gives no suffix at all. A filter handed in filter group 0 by the caller (Page.Run with a record) gives the same suffix; unfiltered no suffix.
// BC versions: all (CI)

table 93851 "LT Y72 Cap Tmpl"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

table 93852 "LT Y72 Cap Batch"
{
    DataClassification = SystemMetadata;
    DataCaptionFields = Name, Description;

    fields
    {
        field(1; Tmpl; Code[10]) { }
        field(2; Name; Code[10]) { }
        field(3; Description; Text[50]) { }
    }

    keys { key(PK; Tmpl, Name) { Clustered = true; } }
}

table 93853 "LT Y72 Cap Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Tmpl; Code[10]) { TableRelation = "LT Y72 Cap Tmpl"; }
        field(2; Batch; Code[10]) { TableRelation = "LT Y72 Cap Batch".Name where(Tmpl = field(Tmpl)); }
        field(3; "Line No."; Integer) { }
    }

    keys { key(PK; Tmpl, Batch, "Line No.") { Clustered = true; } }
}

table 93854 "LT Y72 Cap Line Tbl"
{
    DataClassification = SystemMetadata;
    DataCaptionFields = Batch;

    fields
    {
        field(1; Tmpl; Code[10]) { TableRelation = "LT Y72 Cap Tmpl"; }
        field(2; Batch; Code[10]) { TableRelation = "LT Y72 Cap Batch".Name where(Tmpl = field(Tmpl)); }
        field(3; "Line No."; Integer) { }
    }

    keys { key(PK; Tmpl, Batch, "Line No.") { Clustered = true; } }
}

table 93855 "LT Y72 Cap Batch1"
{
    DataClassification = SystemMetadata;
    DataCaptionFields = Name, Description;

    fields
    {
        field(1; Name; Code[10]) { }
        field(2; Description; Text[50]) { }
    }

    keys { key(PK; Name) { Clustered = true; } }
}

table 93856 "LT Y72 Cap Line1"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; Code[10]) { TableRelation = "LT Y72 Cap Batch1".Name where(Description = const('x')); }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93851 "LT Y72 Cap Setup"
{
    SingleInstance = true;

    var
        CurrTmplValue: Code[10];
        CurrBatchValue: Code[10];
        SkipTmplValue: Boolean;

    procedure Set(Tmpl: Code[10]; Batch: Code[10]; SkipTmpl: Boolean)
    begin
        CurrTmplValue := Tmpl;
        CurrBatchValue := Batch;
        SkipTmplValue := SkipTmpl;
    end;

    procedure CurrTmpl(): Code[10]
    begin
        exit(CurrTmplValue);
    end;

    procedure CurrBatch(): Code[10]
    begin
        exit(CurrBatchValue);
    end;

    procedure SkipTmpl(): Boolean
    begin
        exit(SkipTmplValue);
    end;
}

page 93854 "LT Y72 Cap Journal"
{
    PageType = List;
    SourceTable = "LT Y72 Cap Line";
    DataCaptionFields = Batch;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(TmplCtl; Rec.Tmpl) { ApplicationArea = All; }
                field(BatchCtl; Rec.Batch) { ApplicationArea = All; }
                field(LineCtl; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Setup: Codeunit "LT Y72 Cap Setup";
    begin
        Rec.FilterGroup(2);
        if not Setup.SkipTmpl() then
            Rec.SetRange(Tmpl, Setup.CurrTmpl());
        Rec.SetRange(Batch, Setup.CurrBatch());
        Rec.FilterGroup(0);
    end;
}

page 93855 "LT Y72 Cap Journal Plain"
{
    PageType = List;
    SourceTable = "LT Y72 Cap Line";
    DataCaptionFields = Batch;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(TmplCtl; Rec.Tmpl) { ApplicationArea = All; }
                field(BatchCtl; Rec.Batch) { ApplicationArea = All; }
                field(LineCtl; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }
}

page 93856 "LT Y72 Cap Journal Tbl"
{
    PageType = List;
    SourceTable = "LT Y72 Cap Line Tbl";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(TmplCtl; Rec.Tmpl) { ApplicationArea = All; }
                field(BatchCtl; Rec.Batch) { ApplicationArea = All; }
                field(LineCtl; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Setup: Codeunit "LT Y72 Cap Setup";
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Tmpl, Setup.CurrTmpl());
        Rec.SetRange(Batch, Setup.CurrBatch());
        Rec.FilterGroup(0);
    end;
}

page 93857 "LT Y72 Cap Const List"
{
    PageType = List;
    SourceTable = "LT Y72 Cap Line1";
    DataCaptionFields = Ref;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(RefCtl; Rec.Ref) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Setup: Codeunit "LT Y72 Cap Setup";
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Ref, Setup.CurrBatch());
        Rec.FilterGroup(0);
    end;
}

codeunit 93852 "LT Y72 Caption Relation Where"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Tmpl: Record "LT Y72 Cap Tmpl";
        Batch: Record "LT Y72 Cap Batch";
        Line: Record "LT Y72 Cap Line";
        LineTbl: Record "LT Y72 Cap Line Tbl";
        Batch1: Record "LT Y72 Cap Batch1";
        Line1: Record "LT Y72 Cap Line1";
    begin
        ClearLastError();
        Observer.Discard();
        Tmpl.DeleteAll();
        Batch.DeleteAll();
        Line.DeleteAll();
        LineTbl.DeleteAll();
        Batch1.DeleteAll();
        Line1.DeleteAll();
        Tmpl.Code := 'T1';
        Tmpl.Insert();
        Tmpl.Code := 'T2';
        Tmpl.Insert();
        AddBatch('T1', 'BAT', 'Batch one');
        AddBatch('T2', 'BAT', 'Batch two');
        AddBatch('T1', 'OTHER', '');
        AddLine('T1', 'BAT', 1);
        AddLine('T1', 'BAT', 2);
        AddLine('T2', 'BAT', 1);
        AddLine('T1', 'OTHER', 1);
        Batch1.Name := 'X1';
        Batch1.Description := 'x';
        Batch1.Insert();
        Batch1.Name := 'X2';
        Batch1.Description := 'y';
        Batch1.Insert();
        AddLine1(1, 'X1');
        AddLine1(2, 'X2');
        AddLine1(3, 'Z9');
    end;

    local procedure AddBatch(Tmpl: Code[10]; Name: Code[10]; Description: Text[50])
    var
        Batch: Record "LT Y72 Cap Batch";
    begin
        Batch.Tmpl := Tmpl;
        Batch.Name := Name;
        Batch.Description := Description;
        Batch.Insert();
    end;

    local procedure AddLine(Tmpl: Code[10]; Batch: Code[10]; LineNo: Integer)
    var
        Line: Record "LT Y72 Cap Line";
        LineTbl: Record "LT Y72 Cap Line Tbl";
    begin
        Line.Tmpl := Tmpl;
        Line.Batch := Batch;
        Line."Line No." := LineNo;
        Line.Insert();
        LineTbl.Tmpl := Tmpl;
        LineTbl.Batch := Batch;
        LineTbl."Line No." := LineNo;
        LineTbl.Insert();
    end;

    local procedure AddLine1(Id: Integer; Ref: Code[10])
    var
        Line1: Record "LT Y72 Cap Line1";
    begin
        Line1.Id := Id;
        Line1.Ref := Ref;
        Line1.Insert();
    end;

    [Test]
    procedure Caption_WhereField_TwoKey_JournalFilter()
    var
        Setup: Codeunit "LT Y72 Cap Setup";
        P: TestPage "LT Y72 Cap Journal";
    begin
        Seed();
        Setup.Set('T1', 'BAT', false);
        P.OpenEdit();
        Observer.Observe('open caption', P.Caption());
        Observer.Observe('open line', P.LineCtl.Value());
        Observer.Observe('goto', Format(P.GoToKey('T1', 'BAT', 2)));
        Observer.Observe('goto caption', P.Caption());
        P.Close();
        Observer.Expect('open caption', 'LT Y72 Cap Journal - BAT ∙ Batch one');
        Observer.Expect('open line', '1');
        Observer.Expect('goto', 'Yes');
        Observer.Expect('goto caption', 'LT Y72 Cap Journal - BAT ∙ Batch one');
        Observer.Verify();
    end;




    [Test]
    procedure Caption_WhereField_OtherTemplate()
    var
        Setup: Codeunit "LT Y72 Cap Setup";
        P: TestPage "LT Y72 Cap Journal";
    begin
        Seed();
        Setup.Set('T2', 'BAT', false);
        P.OpenEdit();
        Observer.Observe('caption', P.Caption());
        Observer.Observe('line', P.LineCtl.Value());
        P.Close();
        Observer.Expect('caption', 'LT Y72 Cap Journal - BAT ∙ Batch one');
        Observer.Expect('line', '1');
        Observer.Verify();
    end;




    [Test]
    procedure Caption_WhereField_NoDescription()
    var
        Setup: Codeunit "LT Y72 Cap Setup";
        P: TestPage "LT Y72 Cap Journal";
    begin
        Seed();
        Setup.Set('T1', 'OTHER', false);
        P.OpenEdit();
        Observer.Observe('caption', P.Caption());
        P.Close();
        Observer.Expect('caption', 'LT Y72 Cap Journal - OTHER');
        Observer.Verify();
    end;




    [Test]
    procedure Caption_WhereField_BatchNotInTemplate()
    var
        Setup: Codeunit "LT Y72 Cap Setup";
        P: TestPage "LT Y72 Cap Journal";
    begin
        Seed();
        Setup.Set('T2', 'OTHER', false);
        P.OpenEdit();
        Observer.Observe('caption', P.Caption());
        Observer.Observe('line', P.LineCtl.Value());
        P.Close();
        Observer.Expect('caption', 'LT Y72 Cap Journal - OTHER');
        Observer.Expect('line', '');
        Observer.Verify();
    end;




    [Test]
    procedure Caption_WhereConst_OneKey()
    var
        Setup: Codeunit "LT Y72 Cap Setup";
        P: TestPage "LT Y72 Cap Const List";
    begin
        Seed();
        Setup.Set('', 'X1', false);
        P.OpenEdit();
        Observer.Observe('match caption', P.Caption());
        P.Close();
        Setup.Set('', 'X2', false);
        P.OpenEdit();
        Observer.Observe('where mismatch caption', P.Caption());
        P.Close();
        Setup.Set('', 'Z9', false);
        P.OpenEdit();
        Observer.Observe('no batch row caption', P.Caption());
        P.Close();
        Observer.Expect('match caption', 'LT Y72 Cap Const List - X1 ∙ x');
        Observer.Expect('where mismatch caption', 'LT Y72 Cap Const List - X2 ∙ y');
        Observer.Expect('no batch row caption', 'LT Y72 Cap Const List');
        Observer.Verify();
    end;




    [Test]
    procedure Caption_WhereField_FilterOnlyBatch()
    var
        Setup: Codeunit "LT Y72 Cap Setup";
        P: TestPage "LT Y72 Cap Journal";
    begin
        Seed();
        Setup.Set('', 'BAT', true);
        P.OpenEdit();
        Observer.Observe('caption', P.Caption());
        Observer.Observe('line', P.LineCtl.Value());
        Observer.Observe('goto T2', Format(P.GoToKey('T2', 'BAT', 1)));
        Observer.Observe('goto caption', P.Caption());
        P.Close();
        Setup.Set('', 'OTHER', true);
        P.OpenEdit();
        Observer.Observe('other caption', P.Caption());
        P.Close();
        Observer.Expect('caption', 'LT Y72 Cap Journal - BAT ∙ Batch one');
        Observer.Expect('line', '1');
        Observer.Expect('goto T2', 'Yes');
        Observer.Expect('goto caption', 'LT Y72 Cap Journal - BAT ∙ Batch one');
        Observer.Expect('other caption', 'LT Y72 Cap Journal - OTHER');
        Observer.Verify();
    end;




    [Test]
    procedure Caption_WhereField_TableLevelDataCaptionFields()
    var
        Setup: Codeunit "LT Y72 Cap Setup";
        P: TestPage "LT Y72 Cap Journal Tbl";
    begin
        Seed();
        Setup.Set('T1', 'BAT', false);
        P.OpenEdit();
        Observer.Observe('T1 caption', P.Caption());
        P.Close();
        Setup.Set('T2', 'BAT', false);
        P.OpenEdit();
        Observer.Observe('T2 caption', P.Caption());
        P.Close();
        Observer.Expect('T1 caption', 'LT Y72 Cap Journal Tbl');
        Observer.Expect('T2 caption', 'LT Y72 Cap Journal Tbl');
        Observer.Verify();
    end;




    [Test]
    procedure Caption_WhereField_FilterGroupZeroFromCaller()
    var
        Line: Record "LT Y72 Cap Line";
        P: TestPage "LT Y72 Cap Journal Plain";
    begin
        Seed();
        Line.SetRange(Tmpl, 'T2');
        Line.SetRange(Batch, 'BAT');
        P.Trap();
        Page.Run(Page::"LT Y72 Cap Journal Plain", Line);
        Observer.Observe('both filters caption', P.Caption());
        P.Close();
        Line.Reset();
        Line.SetRange(Batch, 'BAT');
        P.Trap();
        Page.Run(Page::"LT Y72 Cap Journal Plain", Line);
        Observer.Observe('batch filter caption', P.Caption());
        P.Close();
        Line.Reset();
        P.Trap();
        Page.Run(Page::"LT Y72 Cap Journal Plain", Line);
        Observer.Observe('unfiltered caption', P.Caption());
        P.Close();
        Observer.Expect('both filters caption', 'LT Y72 Cap Journal Plain - BAT ∙ Batch one');
        Observer.Expect('batch filter caption', 'LT Y72 Cap Journal Plain - BAT ∙ Batch one');
        Observer.Expect('unfiltered caption', 'LT Y72 Cap Journal Plain');
        Observer.Verify();
    end;



}
