// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 67132-67137 (PG R7820 *)
// local object: the part's OnFindRecord trigger is what the test checks
// Probe: from al-runner issue 7820: a Document page with a ListPart (AutoSplitKey, default UpdatePropagation) whose OnFindRecord logs
//   Which and returns Rec.Find(Which), with OnAfterGetRecord and OnAfterGetCurrRecord, and whose Qty OnValidate runs
//   CurrPage.Update(true). The test opens the document, goes to the part's first row (or a later row), sets Qty and reads the part's
//   trigger log, the row it stands on and its Qty. The reporter saw on BC 29.1 with the part on its first row
//   `F=>;R1;F=;R1;C1;` (one row) and `F=>;R1;R2;R3;R4;R5;R1;F=;R1;C1;` (five rows).
// Result: awaiting the corpus CI run (BC 27.5, 28.5 and 29.0).
// BC versions: 27+ (tested by the corpus CI matrix)

table 67132 "PG R7820 Header"
{
    fields
    {
        field(1; "No."; Code[20]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 67133 "PG R7820 Line"
{
    fields
    {
        field(1; "Order No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Qty; Integer) { }
    }
    keys
    {
        key(PK; "Order No.", "Line No.") { Clustered = true; }
    }
}

codeunit 67134 "PG R7820 Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Reset()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}

page 67135 "PG R7820 Doc"
{
    PageType = Document;
    SourceTable = "PG R7820 Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PG R7820 Part")
            {
                ApplicationArea = All;
                SubPageLink = "Order No." = field("No.");
            }
        }
    }
}

page 67136 "PG R7820 Part"
{
    PageType = ListPart;
    SourceTable = "PG R7820 Line";
    ApplicationArea = All;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; Editable = false; }
                field(Qty; Rec.Qty)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "PG R7820 Log";
    begin
        Log.Add('F' + Which);
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R7820 Log";
    begin
        Log.Add('R' + Format(Rec."Line No." div 10000));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R7820 Log";
    begin
        Log.Add('C' + Format(Rec."Line No." div 10000));
    end;
}

codeunit 67137 "PG R7820 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Rows: Integer; Moves: Integer)
    var
        Header: Record "PG R7820 Header";
        Line: Record "PG R7820 Line";
        Log: Codeunit "PG R7820 Log";
        P: TestPage "PG R7820 Doc";
        i: Integer;
    begin
        Header.DeleteAll();
        Line.DeleteAll();
        Header."No." := 'O1';
        Header.Insert();
        for i := 1 to Rows do begin
            Line."Order No." := 'O1';
            Line."Line No." := i * 10000;
            Line.Qty := i;
            Line.Insert();
        end;
        P.OpenEdit();
        P.GoToRecord(Header);
        P.Lines.First();
        for i := 1 to Moves do
            P.Lines.Next();
        Log.Reset();
        P.Lines.Qty.SetValue(100);
        Observer.Observe('log', Log.Get());
        Observer.Observe('line after', P.Lines."Line No.".Value());
        Observer.Observe('qty after', P.Lines.Qty.Value());
        P.Close();
    end;

    [Test]
    procedure PG7820_OneRow_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1, 0);
        Observer.Expect('log', 'F=>;R1;F=;R1;C1;');
        Observer.Expect('line after', '10000');
        Observer.Expect('qty after', '100');
        Observer.Verify();
    end;

    [Test]
    procedure PG7820_TwoRows_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2, 0);
        Observer.Expect('log', 'F=>;R1;R2;R1;F=;R1;C1;');
        Observer.Expect('line after', '10000');
        Observer.Expect('qty after', '100');
        Observer.Verify();
    end;

    [Test]
    procedure PG7820_FiveRows_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 5, 0);
        Observer.Expect('log', 'F=>;R1;R2;R3;R4;R5;R1;F=;R1;C1;');
        Observer.Expect('line after', '10000');
        Observer.Expect('qty after', '100');
        Observer.Verify();
    end;

    [Test]
    procedure PG7820_ThreeRows_Second()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3, 1);
        Observer.Expect('log', 'F=>;R2;R3;R2;R1;R2;F=;R2;C2;');
        Observer.Expect('line after', '20000');
        Observer.Expect('qty after', '100');
        Observer.Verify();
    end;
}
