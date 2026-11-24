// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-passing-parameters
// Scope: in-scope
// local object: the view a ListPart's Rec hands by value to a codeunit or table procedure, where its filter group 4 link filter comes
//   from the host's SubPageLink, is what is under test
// Fixtures used: Probe Observer (codeunit 69160); own objects 97070..97076 (LT BVP Head, LT BVP Row, LT BVP Log, LT BVP Callee,
//   LT BVP Head Card, LT BVP Row Part, LT BVP Tests)
// Probe (al-runner issue 8283): the origin of a filter group 4 filter that record/filters/ByValueRecordView.al sets from code
//   (ByValue_Group4Filter): a ListPart's Rec, whose group 4 filter comes from the host's SubPageLink, handed by value during a
//   TestPage SetValue on the part. The shape of Base Application's Sales Line.CheckCreditLimit, which hands Rec of the Sales Order
//   subform to Cust-Check Cr. Limit.SalesLineCheck, where page Check Credit Limit.CalcSalesLineOrderAmountsLCY calls SalesLine.Find().
//   Cells, each with the part on row H1/10000 of three rows (two linked to the host's H1, one to H2):
//   - a table field's OnValidate hands Rec to a codeunit procedure (the issue's shape);
//   - a table field's OnValidate hands Rec to a procedure of the same table (Rec.Proc(Rec));
//   - a page field's OnValidate on the part hands Rec to a codeunit procedure;
//   - the control: a record with the same filter set in group 4 from code, validated from code, through the same table trigger.
//   Readings in the callee: its filters per filter group (-1 to 6), Count, current filter group, key and order, the fields it holds,
//   Find() and the fields it reads then. Readings of the caller's Rec right after the call: its filter group, its filters per group,
//   Count. After Close: the row's stored fields.
// Facts (measured on a local BC 29.1 OnPrem w1 container; 27.5 and 28.5 by the corpus CI):
//   - the part's Rec holds the SubPageLink filter in filter group 4 ('Head No.: H1'), stands in filter group 0 and counts the 2 linked
//     rows, before and after the call;
//   - the callee's by-value copy has no filter in filter groups -1 to 6, stands in filter group 0, has the primary key, ascending, and
//     counts all 3 rows; it holds the caller's fields as validated (the new value, not yet stored), and Find() finds the row and reads
//     its stored fields;
//   - the same for a table field's OnValidate calling a codeunit procedure, a procedure of the same table, and a page field's OnValidate
//     on the part calling a codeunit procedure, and for the control with the group 4 filter set from code.
// BC versions: 27, 28, 29

table 97070 "LT BVP Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 97071 "LT BVP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Head No."; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Amount; Decimal)
        {
            trigger OnValidate()
            var
                Callee: Codeunit "LT BVP Callee";
                Log: Codeunit "LT BVP Log";
            begin
                Log.Add('callee ' + Callee.Describe(Rec));
                Log.Add('caller ' + CallerView());
            end;
        }
        field(4; Qty; Decimal)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT BVP Log";
            begin
                Log.Add('callee ' + OwnByValue(Rec));
                Log.Add('caller ' + CallerView());
            end;
        }
        field(5; Note; Text[30]) { }
    }

    keys
    {
        key(PK; "Head No.", "Line No.") { Clustered = true; }
    }

    procedure OwnByValue(Copy: Record "LT BVP Row"): Text
    var
        Callee: Codeunit "LT BVP Callee";
    begin
        exit(Callee.DescribeCopy(Copy));
    end;

    procedure CallerView(): Text
    var
        Callee: Codeunit "LT BVP Callee";
        Saved: Integer;
        Group: Integer;
        Result: Text;
    begin
        Saved := FilterGroup();
        Result := 'grp=' + Format(Saved);
        foreach Group in Callee.GroupNos() do begin
            FilterGroup(Group);
            Result += ' ' + Format(Group) + '={' + GetFilters() + '}';
        end;
        FilterGroup(Saved);
        exit(Result + ' n=' + Format(Count()));
    end;
}

codeunit 97072 "LT BVP Log"
{
    SingleInstance = true;

    var
        Buffer: Text;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;
}

codeunit 97073 "LT BVP Callee"
{
    procedure Describe(R: Record "LT BVP Row"): Text
    begin
        exit(DescribeCopy(R));
    end;

    // The record is the by-value parameter of Describe or of the table procedure OwnByValue, passed on as var so it is not copied again.
    procedure DescribeCopy(var R: Record "LT BVP Row"): Text
    var
        Group: Integer;
        Result: Text;
    begin
        Result := 'grp=' + Format(R.FilterGroup()) + ' key=' + R.CurrentKey() + ' asc=' + Format(R.Ascending());
        foreach Group in GroupNos() do begin
            R.FilterGroup(Group);
            Result += ' ' + Format(Group) + '={' + R.GetFilters() + '}';
        end;
        R.FilterGroup(0);
        Result += ' n=' + Format(R.Count()) + ' holds=' + Fields(R);
        if R.Find() then
            Result += ' find=Yes reads=' + Fields(R)
        else
            Result += ' find=No';
        exit(Result);
    end;

    procedure Fields(R: Record "LT BVP Row"): Text
    begin
        exit(R."Head No." + '/' + Format(R."Line No.") + ' amount=' + Format(R.Amount, 0, 9) + ' qty=' + Format(R.Qty, 0, 9) + ' note=' + R.Note);
    end;

    procedure GroupNos(): List of [Integer]
    var
        Groups: List of [Integer];
        Group: Integer;
    begin
        for Group := -1 to 6 do
            Groups.Add(Group);
        exit(Groups);
    end;
}

page 97074 "LT BVP Head Card"
{
    PageType = Document;
    SourceTable = "LT BVP Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Rows; "LT BVP Row Part")
            {
                ApplicationArea = All;
                SubPageLink = "Head No." = field("No.");
            }
        }
    }
}

page 97075 "LT BVP Row Part"
{
    PageType = ListPart;
    SourceTable = "LT BVP Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; Editable = false; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
                field(Note; Rec.Note)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Callee: Codeunit "LT BVP Callee";
                        Log: Codeunit "LT BVP Log";
                    begin
                        Log.Add('callee ' + Callee.Describe(Rec));
                        Log.Add('caller ' + Rec.CallerView());
                    end;
                }
            }
        }
    }
}

codeunit 97076 "LT BVP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Callee: Codeunit "LT BVP Callee";
        Log: Codeunit "LT BVP Log";

    local procedure Initialize()
    var
        Head: Record "LT BVP Head";
        Row: Record "LT BVP Row";
    begin
        Head.DeleteAll();
        Row.DeleteAll();
        Head."No." := 'H1';
        Head.Insert();
        Head."No." := 'H2';
        Head.Insert();
        AddRow('H1', 10000, 5);
        AddRow('H1', 20000, 1);
        AddRow('H2', 10000, 3);
        Log.Take();
    end;

    local procedure AddRow(HeadNo: Code[10]; LineNo: Integer; Amount: Decimal)
    var
        Row: Record "LT BVP Row";
    begin
        Row."Head No." := HeadNo;
        Row."Line No." := LineNo;
        Row.Amount := Amount;
        Row.Qty := 1;
        Row.Note := 'old';
        Row.Insert();
    end;

    local procedure OpenOnFirstRow(var HeadCard: TestPage "LT BVP Head Card")
    var
        Head: Record "LT BVP Head";
        Row: Record "LT BVP Row";
    begin
        Head.Get('H1');
        Row.Get('H1', 10000);
        HeadCard.OpenEdit();
        HeadCard.GoToRecord(Head);
        HeadCard.Rows.GoToRecord(Row);
        Log.Take();
    end;

    local procedure StoredRow(): Text
    var
        Row: Record "LT BVP Row";
    begin
        Row.Get('H1', 10000);
        exit(Callee.Fields(Row));
    end;

    [Test]
    procedure ByValue_ListPartLink_TableFieldOnValidate_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
        HeadCard: TestPage "LT BVP Head Card";
    begin
        Initialize();
        OpenOnFirstRow(HeadCard);
        HeadCard.Rows.Amount.SetValue(7);
        Observer.Observe('set value', Log.Take());
        HeadCard.Close();
        Observer.Observe('stored after close', StoredRow());
        Observer.Expect('set value', 'callee grp=0 key=Head No.,Line No. asc=Yes -1={} 0={} 1={} 2={} 3={} 4={} 5={} 6={} n=3 holds=H1/10000 amount=7 qty=1 note=old find=Yes reads=H1/10000 amount=5 qty=1 note=old;caller grp=0 -1={} 0={} 1={} 2={} 3={} 4={Head No.: H1} 5={} 6={} n=2;');
        Observer.Expect('stored after close', 'H1/10000 amount=7 qty=1 note=old');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_ListPartLink_TableFieldOnValidate_TableProcedure()
    var
        Observer: Codeunit "Probe Observer";
        HeadCard: TestPage "LT BVP Head Card";
    begin
        Initialize();
        OpenOnFirstRow(HeadCard);
        HeadCard.Rows.Qty.SetValue(4);
        Observer.Observe('set value', Log.Take());
        HeadCard.Close();
        Observer.Observe('stored after close', StoredRow());
        Observer.Expect('set value', 'callee grp=0 key=Head No.,Line No. asc=Yes -1={} 0={} 1={} 2={} 3={} 4={} 5={} 6={} n=3 holds=H1/10000 amount=5 qty=4 note=old find=Yes reads=H1/10000 amount=5 qty=1 note=old;caller grp=0 -1={} 0={} 1={} 2={} 3={} 4={Head No.: H1} 5={} 6={} n=2;');
        Observer.Expect('stored after close', 'H1/10000 amount=5 qty=4 note=old');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_ListPartLink_PageFieldOnValidate_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
        HeadCard: TestPage "LT BVP Head Card";
    begin
        Initialize();
        OpenOnFirstRow(HeadCard);
        HeadCard.Rows.Note.SetValue('new');
        Observer.Observe('set value', Log.Take());
        HeadCard.Close();
        Observer.Observe('stored after close', StoredRow());
        Observer.Expect('set value', 'callee grp=0 key=Head No.,Line No. asc=Yes -1={} 0={} 1={} 2={} 3={} 4={} 5={} 6={} n=3 holds=H1/10000 amount=5 qty=1 note=new find=Yes reads=H1/10000 amount=5 qty=1 note=old;caller grp=0 -1={} 0={} 1={} 2={} 3={} 4={Head No.: H1} 5={} 6={} n=2;');
        Observer.Expect('stored after close', 'H1/10000 amount=5 qty=1 note=new');
        Observer.Verify();
    end;

    [Test]
    procedure ByValue_CodeGroup4Filter_TableFieldValidate_Codeunit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BVP Row";
    begin
        Initialize();
        Row.FilterGroup(4);
        Row.SetRange("Head No.", 'H1');
        Row.FilterGroup(0);
        Row.Get('H1', 10000);
        Row.Validate(Amount, 7);
        Observer.Observe('validate', Log.Take());
        Observer.Observe('stored', StoredRow());
        Observer.Expect('validate', 'callee grp=0 key=Head No.,Line No. asc=Yes -1={} 0={} 1={} 2={} 3={} 4={} 5={} 6={} n=3 holds=H1/10000 amount=7 qty=1 note=old find=Yes reads=H1/10000 amount=5 qty=1 note=old;caller grp=0 -1={} 0={} 1={} 2={} 3={} 4={Head No.: H1} 5={} 6={} n=2;');
        Observer.Expect('stored', 'H1/10000 amount=5 qty=1 note=old');
        Observer.Verify();
    end;
}
