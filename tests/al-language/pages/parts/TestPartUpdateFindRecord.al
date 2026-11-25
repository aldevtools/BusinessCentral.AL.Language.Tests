// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); local objects 70018-70019
// local object: the Document/ListPart shape, the part triggers and Qty OnValidate are the behavior under test
// Probe: from al-runner issue 7820, a Document host and ListPart have no page-level ApplicationArea or UsageCategory.
//   The ListPart logs OnFindRecord(Which), OnAfterGetRecord and OnAfterGetCurrRecord; Qty OnValidate calls
//   CurrPage.Update(true). With the part on its first row, the test opens the host, goes to the header, calls First and
//   sets Qty. The focused cells have exactly one part row and exactly five part rows.
// Result: on BC 29.1.57326.57497, one row reads `F=>;R1;F=;R1;C1;` and five rows read
//   `F=>;R1;R2;R3;R4;R5;R1;F=;R1;C1;`.
// BC versions: 27+

table 70018 "PAG UpdFind Header"
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

table 70019 "PAG UpdFind Line"
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

codeunit 70018 "PAG UpdFind Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Clear()
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

page 70018 "PAG UpdFind Document"
{
    PageType = Document;
    SourceTable = "PAG UpdFind Header";

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
            }
            part(Lines; "PAG UpdFind Part")
            {
                ApplicationArea = All;
                SubPageLink = "Order No." = field("No.");
            }
        }
    }
}

page 70019 "PAG UpdFind Part"
{
    PageType = ListPart;
    SourceTable = "PAG UpdFind Line";
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
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
        ReadLog: Codeunit "PAG UpdFind Log";
    begin
        ReadLog.Add('F' + Which);
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    var
        ReadLog: Codeunit "PAG UpdFind Log";
    begin
        ReadLog.Add('R' + Format(Rec."Line No." div 10000));
    end;

    trigger OnAfterGetCurrRecord()
    var
        ReadLog: Codeunit "PAG UpdFind Log";
    begin
        ReadLog.Add('C' + Format(Rec."Line No." div 10000));
    end;
}

codeunit 70019 "PAG UpdFind Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PartUpdate_FirstRow_OneRow_Log()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize(1);
        ObserveFirstQtySet(Observer);
        Observer.Expect('reads', 'F=>;R1;F=;R1;C1;');
        Observer.Verify();
    end;

    [Test]
    procedure PartUpdate_FirstRow_FiveRows_Log()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize(5);
        ObserveFirstQtySet(Observer);
        Observer.Expect('reads', 'F=>;R1;R2;R3;R4;R5;R1;F=;R1;C1;');
        Observer.Verify();
    end;

    local procedure Initialize(Rows: Integer)
    var
        Header: Record "PAG UpdFind Header";
        Line: Record "PAG UpdFind Line";
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
    end;

    local procedure ObserveFirstQtySet(var Observer: Codeunit "Probe Observer")
    var
        Header: Record "PAG UpdFind Header";
        ReadLog: Codeunit "PAG UpdFind Log";
        Host: TestPage "PAG UpdFind Document";
    begin
        Header.Get('O1');
        Host.OpenEdit();
        Host.GoToRecord(Header);
        Host.Lines.First();
        ReadLog.Clear();
        Host.Lines.Qty.SetValue(100);
        Observer.Observe('reads', ReadLog.Get());
        Host.Close();
    end;
}
