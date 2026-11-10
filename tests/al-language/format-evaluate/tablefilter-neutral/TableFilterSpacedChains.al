// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 66310 and 66312, test codeunit 66311; Base Application page "Table Filter"
//   and table "Table Filter"
// local object: the Evaluate text names the table and its fields by caption, and the rows hold values with spaces.
// Probe (al-runner issue 7497: Evaluate into a TableFilter of `<>BIN EAST&<>BIN WEST`, Code values with a space inside): observation form,
//   the values are read from the corpus CI matrix.
// Area: Evaluate of a text into a TableFilter field whose condition chains values that hold a space, on a Code[20] and a Text[30] field:
//   <>A&<>B, three chained <>, A|B, three alternatives, A..B, open ranges, >A&<B, a single value, <>A, wildcards (A*, <>A*, *A),
//   the same with the values in single quotes, mixed quoted and unquoted, and two fields in one text. Each cell records whether Evaluate
//   raises (error text and code), Format of the TableFilter field, the lines the Base Application page "Table Filter" lists for it
//   (field number = filter text) and the row numbers the listed filters keep when they are set through FieldRef.SetFilter.
// Existing pins: TableFilterEnumForms.al TableFilter_Evaluate_CodeExclusions_LeavesOtherRow (<>A&<>B without spaces) and
//   TableFilter_Evaluate_CodeAlternatives_SelectsBothMatchingRows (A|B without spaces).
// BC versions: 27, 28, 29 by CI

table 66310 "FE TfChain Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Code Field"; Code[20]) { }
        field(3; "Text Field"; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 66312 "FE TfChain Holder"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Filter Value"; TableFilter) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 66311 "FE TfChain Tests"
{
    Subtype = Test;

    local procedure Initialize()
    var
        R: Record "FE TfChain Row";
        H: Record "FE TfChain Holder";
    begin
        R.DeleteAll();
        H.DeleteAll();
        Add(1, 'BIN EAST');
        Add(2, 'BIN WEST');
        Add(3, 'BIN NORTH');
        Add(4, 'BIN');
        Add(5, 'EAST');
        Add(6, '');
        Add(7, 'BIN EAST WEST');
    end;

    local procedure Add(Id: Integer; Value: Text[20])
    var
        R: Record "FE TfChain Row";
    begin
        R.Init();
        R.Id := Id;
        R."Code Field" := Value;
        R."Text Field" := Value;
        R.Insert();
    end;

    [TryFunction]
    local procedure TryEval(var H: Record "FE TfChain Holder"; Value: Text)
    begin
        Evaluate(H."Filter Value", Value);
    end;

    [TryFunction]
    local procedure TryLines(H: Record "FE TfChain Holder"; var Lines: Text; var Rows: Text)
    var
        R: Record "FE TfChain Row";
        Fields: Record "Table Filter" temporary;
        FilterPage: Page "Table Filter";
        Ref: RecordRef;
        Fld: FieldRef;
    begin
        FilterPage.SetSourceTable(Format(H."Filter Value"), Database::"FE TfChain Row", R.TableCaption());
        FilterPage.GetFilterFieldsList(Fields);
        Ref.Open(Database::"FE TfChain Row");
        if Fields.FindSet() then
            repeat
                Lines += Format(Fields."Field Number") + '=' + Fields."Field Filter" + ';';
                Fld := Ref.Field(Fields."Field Number");
                Fld.SetFilter(Fields."Field Filter");
            until Fields.Next() = 0;
        if Ref.FindSet() then
            repeat
                Rows += Format(Ref.Field(1).Value()) + ' ';
            until Ref.Next() = 0;
        Ref.Close();
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; Name: Text; Conditions: Text)
    var
        H: Record "FE TfChain Holder";
        Lines: Text;
        Rows: Text;
    begin
        if not TryEval(H, 'FE TfChain Row: ' + Conditions) then begin
            Observer.Observe(Name, 'E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
            ClearLastError();
            exit;
        end;
        if not TryLines(H, Lines, Rows) then begin
            Observer.Observe(Name, Format(H."Filter Value") + ' | lines so far: ' + Lines + ' | E: ' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
            ClearLastError();
            exit;
        end;
        Observer.Observe(Name, Format(H."Filter Value") + ' | ' + Lines + ' | ' + Rows);
    end;

    local procedure Chains(var Observer: Codeunit "Probe Observer"; FieldCaption: Text)
    begin
        Cell(Observer, 'ne and ne', FieldCaption + '=<>BIN EAST&<>BIN WEST');
        Cell(Observer, 'three ne', FieldCaption + '=<>BIN EAST&<>BIN WEST&<>BIN NORTH');
        Cell(Observer, 'or', FieldCaption + '=BIN EAST|BIN WEST');
        Cell(Observer, 'three or', FieldCaption + '=BIN EAST|BIN WEST|BIN');
        Cell(Observer, 'gt and lt', FieldCaption + '=>BIN EAST&<BIN WEST');
        Cell(Observer, 'or with ne', FieldCaption + '=BIN EAST|<>BIN WEST');
    end;

    local procedure RangesAndSingles(var Observer: Codeunit "Probe Observer"; FieldCaption: Text)
    begin
        Cell(Observer, 'single', FieldCaption + '=BIN EAST');
        Cell(Observer, 'ne', FieldCaption + '=<>BIN EAST');
        Cell(Observer, 'range', FieldCaption + '=BIN EAST..BIN NORTH');
        Cell(Observer, 'up to', FieldCaption + '=..BIN NORTH');
        Cell(Observer, 'from', FieldCaption + '=BIN NORTH..');
        Cell(Observer, 'range or single', FieldCaption + '=BIN EAST..BIN NORTH|EAST');
        Cell(Observer, 'three words', FieldCaption + '=BIN EAST WEST');
    end;

    local procedure Wildcards(var Observer: Codeunit "Probe Observer"; FieldCaption: Text)
    begin
        Cell(Observer, 'prefix', FieldCaption + '=BIN E*');
        Cell(Observer, 'ne prefix', FieldCaption + '=<>BIN E*');
        Cell(Observer, 'suffix', FieldCaption + '=* EAST');
        Cell(Observer, 'inner', FieldCaption + '=BIN*WEST');
        Cell(Observer, 'ne prefix and ne', FieldCaption + '=<>BIN E*&<>BIN WEST');
        Cell(Observer, 'at sign', FieldCaption + '=@bin east');
        Cell(Observer, 'question mark', FieldCaption + '=BIN ?AST');
    end;

    local procedure Quoted(var Observer: Codeunit "Probe Observer"; FieldCaption: Text)
    begin
        Cell(Observer, 'quoted single', FieldCaption + '=''BIN EAST''');
        Cell(Observer, 'quoted ne and ne', FieldCaption + '=<>''BIN EAST''&<>''BIN WEST''');
        Cell(Observer, 'quoted or', FieldCaption + '=''BIN EAST''|''BIN WEST''');
        Cell(Observer, 'quoted range', FieldCaption + '=''BIN EAST''..''BIN NORTH''');
        Cell(Observer, 'quoted and plain', FieldCaption + '=<>''BIN EAST''&<>BIN WEST');
        Cell(Observer, 'plain and quoted', FieldCaption + '=BIN EAST|''BIN WEST''');
        Cell(Observer, 'quoted blank or value', FieldCaption + '=''''|BIN EAST');
    end;

    [Test]
    procedure TableFilter_Evaluate_CodeSpaced_Chains()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Chains(Observer, 'Code Field');
        Observer.Expect('ne and ne', 'FE TfChain Row: Code Field=<>BIN EAST&<>BIN WEST | 2=<>BIN EAST&<>BIN WEST; | 3 4 5 6 7 ');
        Observer.Expect('three ne', 'FE TfChain Row: Code Field=<>BIN EAST&<>BIN WEST&<>BIN NORTH | 2=<>BIN EAST&<>BIN WEST&<>BIN NORTH; | 4 5 6 7 ');
        Observer.Expect('or', 'FE TfChain Row: Code Field=BIN EAST|BIN WEST | 2=BIN EAST|BIN WEST; | 1 2 ');
        Observer.Expect('three or', 'FE TfChain Row: Code Field=BIN EAST|BIN WEST|BIN | 2=BIN EAST|BIN WEST|BIN; | 1 2 4 ');
        Observer.Expect('gt and lt', 'FE TfChain Row: Code Field=>BIN EAST&<BIN WEST | 2=>BIN EAST&<BIN WEST; | 3 7 ');
        Observer.Expect('or with ne', 'FE TfChain Row: Code Field=BIN EAST|<>BIN WEST | 2=BIN EAST|<>BIN WEST; | 1 3 4 5 6 7 ');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Evaluate_CodeSpaced_RangesAndSingles()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RangesAndSingles(Observer, 'Code Field');
        Observer.Expect('single', 'FE TfChain Row: Code Field=BIN EAST | 2=BIN EAST; | 1 ');
        Observer.Expect('ne', 'FE TfChain Row: Code Field=<>BIN EAST | 2=<>BIN EAST; | 2 3 4 5 6 7 ');
        Observer.Expect('range', 'FE TfChain Row: Code Field=BIN EAST..BIN NORTH | 2=BIN EAST..BIN NORTH; | 1 3 7 ');
        Observer.Expect('up to', 'FE TfChain Row: Code Field=..BIN NORTH | 2=..BIN NORTH; | 1 3 4 6 7 ');
        Observer.Expect('from', 'FE TfChain Row: Code Field=BIN NORTH.. | 2=BIN NORTH..; | 2 3 5 ');
        Observer.Expect('range or single', 'FE TfChain Row: Code Field=BIN EAST..BIN NORTH|EAST | 2=BIN EAST..BIN NORTH|EAST; | 1 3 5 7 ');
        Observer.Expect('three words', 'FE TfChain Row: Code Field=BIN EAST WEST | 2=BIN EAST WEST; | 7 ');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Evaluate_CodeSpaced_Wildcards()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Wildcards(Observer, 'Code Field');
        Observer.Expect('prefix', 'FE TfChain Row: Code Field=BIN E* | 2=BIN E*; | 1 7 ');
        Observer.Expect('ne prefix', 'FE TfChain Row: Code Field=<>BIN E* | 2=<>BIN E*; | 2 3 4 5 6 ');
        Observer.Expect('suffix', 'FE TfChain Row: Code Field=* EAST | 2=* EAST; | 1 ');
        Observer.Expect('inner', 'FE TfChain Row: Code Field=BIN*WEST | 2=BIN*WEST; | 2 7 ');
        Observer.Expect('ne prefix and ne', 'FE TfChain Row: Code Field=<>BIN E*&<>BIN WEST | 2=<>BIN E*&<>BIN WEST; | 3 4 5 6 ');
        Observer.Expect('at sign', 'FE TfChain Row: Code Field=@BIN EAST | 2=@BIN EAST; | 1 ');
        Observer.Expect('question mark', 'FE TfChain Row: Code Field=BIN ?AST | 2=BIN ?AST; | 1 ');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Evaluate_CodeSpaced_QuotedValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Quoted(Observer, 'Code Field');
        Observer.Expect('quoted single', 'FE TfChain Row: Code Field=BIN EAST | 2=BIN EAST; | 1 ');
        Observer.Expect('quoted ne and ne', 'FE TfChain Row: Code Field=<>BIN EAST&<>BIN WEST | 2=<>BIN EAST&<>BIN WEST; | 3 4 5 6 7 ');
        Observer.Expect('quoted or', 'FE TfChain Row: Code Field=BIN EAST|BIN WEST | 2=BIN EAST|BIN WEST; | 1 2 ');
        Observer.Expect('quoted range', 'FE TfChain Row: Code Field=BIN EAST..BIN NORTH | 2=BIN EAST..BIN NORTH; | 1 3 7 ');
        Observer.Expect('quoted and plain', 'FE TfChain Row: Code Field=<>BIN EAST&<>BIN WEST | 2=<>BIN EAST&<>BIN WEST; | 3 4 5 6 7 ');
        Observer.Expect('plain and quoted', 'FE TfChain Row: Code Field=BIN EAST|BIN WEST | 2=BIN EAST|BIN WEST; | 1 2 ');
        Observer.Expect('quoted blank or value', 'FE TfChain Row: Code Field=''''|BIN EAST | 2=''''|BIN EAST; | 1 6 ');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Evaluate_TextSpaced_Chains()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Chains(Observer, 'Text Field');
        Observer.Expect('ne and ne', 'FE TfChain Row: Text Field=<>BIN EAST&<>BIN WEST | 3=<>BIN EAST&<>BIN WEST; | 3 4 5 6 7 ');
        Observer.Expect('three ne', 'FE TfChain Row: Text Field=<>BIN EAST&<>BIN WEST&<>BIN NORTH | 3=<>BIN EAST&<>BIN WEST&<>BIN NORTH; | 4 5 6 7 ');
        Observer.Expect('or', 'FE TfChain Row: Text Field=BIN EAST|BIN WEST | 3=BIN EAST|BIN WEST; | 1 2 ');
        Observer.Expect('three or', 'FE TfChain Row: Text Field=BIN EAST|BIN WEST|BIN | 3=BIN EAST|BIN WEST|BIN; | 1 2 4 ');
        Observer.Expect('gt and lt', 'FE TfChain Row: Text Field=>BIN EAST&<BIN WEST | 3=>BIN EAST&<BIN WEST; | 3 7 ');
        Observer.Expect('or with ne', 'FE TfChain Row: Text Field=BIN EAST|<>BIN WEST | 3=BIN EAST|<>BIN WEST; | 1 3 4 5 6 7 ');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Evaluate_TextSpaced_RangesAndSingles()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RangesAndSingles(Observer, 'Text Field');
        Observer.Expect('single', 'FE TfChain Row: Text Field=BIN EAST | 3=BIN EAST; | 1 ');
        Observer.Expect('ne', 'FE TfChain Row: Text Field=<>BIN EAST | 3=<>BIN EAST; | 2 3 4 5 6 7 ');
        Observer.Expect('range', 'FE TfChain Row: Text Field=BIN EAST..BIN NORTH | 3=BIN EAST..BIN NORTH; | 1 3 7 ');
        Observer.Expect('up to', 'FE TfChain Row: Text Field=..BIN NORTH | 3=..BIN NORTH; | 1 3 4 6 7 ');
        Observer.Expect('from', 'FE TfChain Row: Text Field=BIN NORTH.. | 3=BIN NORTH..; | 2 3 5 ');
        Observer.Expect('range or single', 'FE TfChain Row: Text Field=BIN EAST..BIN NORTH|EAST | 3=BIN EAST..BIN NORTH|EAST; | 1 3 5 7 ');
        Observer.Expect('three words', 'FE TfChain Row: Text Field=BIN EAST WEST | 3=BIN EAST WEST; | 7 ');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Evaluate_TextSpaced_Wildcards()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Wildcards(Observer, 'Text Field');
        Observer.Expect('prefix', 'FE TfChain Row: Text Field=BIN E* | 3=BIN E*; | 1 7 ');
        Observer.Expect('ne prefix', 'FE TfChain Row: Text Field=<>BIN E* | 3=<>BIN E*; | 2 3 4 5 6 ');
        Observer.Expect('suffix', 'FE TfChain Row: Text Field=* EAST | 3=* EAST; | 1 ');
        Observer.Expect('inner', 'FE TfChain Row: Text Field=BIN*WEST | 3=BIN*WEST; | 2 7 ');
        Observer.Expect('ne prefix and ne', 'FE TfChain Row: Text Field=<>BIN E*&<>BIN WEST | 3=<>BIN E*&<>BIN WEST; | 3 4 5 6 ');
        Observer.Expect('at sign', 'FE TfChain Row: Text Field=@bin east | 3=@bin east; | 1 ');
        Observer.Expect('question mark', 'FE TfChain Row: Text Field=BIN ?AST | 3=BIN ?AST; | 1 ');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Evaluate_TextSpaced_QuotedValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Quoted(Observer, 'Text Field');
        Observer.Expect('quoted single', 'FE TfChain Row: Text Field=BIN EAST | 3=BIN EAST; | 1 ');
        Observer.Expect('quoted ne and ne', 'FE TfChain Row: Text Field=<>BIN EAST&<>BIN WEST | 3=<>BIN EAST&<>BIN WEST; | 3 4 5 6 7 ');
        Observer.Expect('quoted or', 'FE TfChain Row: Text Field=BIN EAST|BIN WEST | 3=BIN EAST|BIN WEST; | 1 2 ');
        Observer.Expect('quoted range', 'FE TfChain Row: Text Field=BIN EAST..BIN NORTH | 3=BIN EAST..BIN NORTH; | 1 3 7 ');
        Observer.Expect('quoted and plain', 'FE TfChain Row: Text Field=<>BIN EAST&<>BIN WEST | 3=<>BIN EAST&<>BIN WEST; | 3 4 5 6 7 ');
        Observer.Expect('plain and quoted', 'FE TfChain Row: Text Field=BIN EAST|BIN WEST | 3=BIN EAST|BIN WEST; | 1 2 ');
        Observer.Expect('quoted blank or value', 'FE TfChain Row: Text Field=''''|BIN EAST | 3=''''|BIN EAST; | 1 6 ');
        Observer.Verify();
    end;

    [Test]
    procedure TableFilter_Evaluate_TwoFieldsSpaced_Chains()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        Cell(Observer, 'two chains', 'Code Field=<>BIN EAST&<>BIN WEST,Text Field=BIN NORTH|BIN');
        Cell(Observer, 'chain then single', 'Code Field=BIN EAST|BIN WEST,Text Field=BIN EAST');
        Cell(Observer, 'single then chain', 'Code Field=BIN EAST,Text Field=<>BIN WEST&<>BIN');
        Cell(Observer, 'text first', 'Text Field=BIN EAST|BIN WEST,Code Field=<>BIN WEST');
        Observer.Expect('two chains', 'FE TfChain Row: Code Field=<>BIN EAST&<>BIN WEST,Text Field=BIN NORTH|BIN | 2=<>BIN EAST&<>BIN WEST;3=BIN NORTH|BIN; | 3 4 ');
        Observer.Expect('chain then single', 'FE TfChain Row: Code Field=BIN EAST|BIN WEST,Text Field=BIN EAST | 2=BIN EAST|BIN WEST;3=BIN EAST; | 1 ');
        Observer.Expect('single then chain', 'FE TfChain Row: Code Field=BIN EAST,Text Field=<>BIN WEST&<>BIN | 2=BIN EAST;3=<>BIN WEST&<>BIN; | 1 ');
        Observer.Expect('text first', 'FE TfChain Row: Code Field=<>BIN WEST,Text Field=BIN EAST|BIN WEST | 2=<>BIN WEST;3=BIN EAST|BIN WEST; | 1 ');
        Observer.Verify();
    end;
}
