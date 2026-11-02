// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-datacaptionfields-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 93851-93857, pages 93854-93858, codeunit 93851 (setup), 93852 (test)
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: the caption of a list whose DataCaptionFields field has a TableRelation with a where(field()) clause to a table with a
//   two-field primary key (the journal pattern: a batch name related to the batch table of the template). The batch table declares
//   DataCaptionFields = Name, Description. The page sets the template and batch filter in filter group 2 in OnOpenPage (the journal
//   pattern), or the caller hands a filtered record (filter group 0). Also: a const where on a one-field key, only the batch filtered
//   (no template), DataCaptionFields declared on the table instead of the page.
//   Batch rows (Tmpl, Name, Description): (T1, BAT, 'Batch one'), (T2, BAT, 'Batch two'), (T1, OTHER, '').
// Neighbours: pages/lt-y45-list-caption-relation/Y45ListCaptionRelation.al (a one-field key relation without where()).
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
        Observer.Finish();
    end;

    [Test]
    procedure Caption_WhereField_TwoKey_JournalFilter_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_TwoKey_JournalFilter_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_TwoKey_JournalFilter_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure Caption_WhereField_OtherTemplate_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_OtherTemplate_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_OtherTemplate_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure Caption_WhereField_NoDescription_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_NoDescription_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_NoDescription_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure Caption_WhereField_BatchNotInTemplate_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_BatchNotInTemplate_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_BatchNotInTemplate_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure Caption_WhereConst_OneKey_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereConst_OneKey_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereConst_OneKey_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure Caption_WhereField_FilterOnlyBatch_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_FilterOnlyBatch_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_FilterOnlyBatch_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure Caption_WhereField_TableLevelDataCaptionFields_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_TableLevelDataCaptionFields_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_TableLevelDataCaptionFields_More3()
    begin
        Observer.More();
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
        Observer.Finish();
    end;

    [Test]
    procedure Caption_WhereField_FilterGroupZeroFromCaller_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_FilterGroupZeroFromCaller_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Caption_WhereField_FilterGroupZeroFromCaller_More3()
    begin
        Observer.More();
    end;
}
