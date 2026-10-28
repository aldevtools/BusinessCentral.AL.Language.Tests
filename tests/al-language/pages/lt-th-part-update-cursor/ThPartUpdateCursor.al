// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT TH *)
// Probe: from al-runner issue 6038 (reporter's real-BC run on 29.0.54011.56119); every literal asserted below is what BC produced.
//   Other BC versions are checked by the corpus CI matrix.
// Facts: a Document page with a ListPart (SubPageLink) over a line table. A part field's OnValidate calls CurrPage.Update(true),
//   CurrPage.Update(false) or CurrPage.SaveRecord(), or has no trigger. After the SetValue on one line: the line the part stands on,
//   the value it shows, the host's current record, the trigger log, and the stored row. Then the usual test walk
//   Lines.First(); repeat Lines.<Field>.SetValue(...) until not Lines.Next() (the walk stops itself after 6 rows so that a part
//   that does not move on cannot loop for ever), on the part in its primary key and with a SubPageView sorting.
// BC versions: 27+ (tested by the corpus CI matrix)

table 89880 "LT TH Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 89881 "LT TH Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Quantity; Decimal) { }
        field(4; "Qty. to Handle"; Decimal) { }
        field(5; "Qty. to Ship"; Decimal) { }
        field(6; Note; Text[30]) { }
        field(7; "Bin Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Document No.", "Line No.") { Clustered = true; }
        key(Qty; "Document No.", Quantity) { }
    }
}

codeunit 89884 "LT TH Log"
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
        Entries += Entry + ' ';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}

page 89882 "LT TH Doc"
{
    PageType = Document;
    SourceTable = "LT TH Doc";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT TH Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT TH Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT TH Log";
    begin
        Log.Add('HC');
    end;
}

page 89886 "LT TH Doc Sorted"
{
    PageType = Document;
    SourceTable = "LT TH Doc";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "LT TH Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                SubPageView = sorting(Quantity);
            }
        }
    }
}

page 89883 "LT TH Lines"
{
    PageType = ListPart;
    SourceTable = "LT TH Line";
    InsertAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field("Qty. to Handle"; Rec."Qty. to Handle")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "LT TH Log";
                    begin
                        Log.Add('QH.V');
                        CurrPage.Update(true);
                        Log.Add('QH.V.end');
                    end;
                }
                field("Qty. to Ship"; Rec."Qty. to Ship")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "LT TH Log";
                    begin
                        Log.Add('QS.V');
                        CurrPage.Update(false);
                        Log.Add('QS.V.end');
                    end;
                }
                field(Note; Rec.Note) { ApplicationArea = All; }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "LT TH Log";
                    begin
                        Log.Add('BC.V');
                        CurrPage.SaveRecord();
                        Log.Add('BC.V.end');
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT TH Log";
    begin
        Log.Add('R' + Format(Rec."Line No." div 10000));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT TH Log";
    begin
        Log.Add('C' + Format(Rec."Line No." div 10000));
    end;
}

codeunit 89885 "LT TH Part Update Cursor"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Doc: Record "LT TH Doc";
        Line: Record "LT TH Line";
        Log: Codeunit "LT TH Log";
    begin
        Line.DeleteAll();
        Doc.DeleteAll();
        Doc."No." := 'D1';
        Doc.Insert();
        InsertLine(10000, 300, 'FIRST');
        InsertLine(20000, 300, 'SECOND');
        InsertLine(30000, 100, 'THIRD');
        Log.Reset();
    end;

    local procedure InsertLine(LineNo: Integer; Qty: Decimal; Bin: Code[20])
    var
        Line: Record "LT TH Line";
    begin
        Line."Document No." := 'D1';
        Line."Line No." := LineNo;
        Line.Quantity := Qty;
        Line."Bin Code" := Bin;
        Line.Insert();
    end;

    // Field 1 = Qty. to Handle (Update(true)), 2 = Qty. to Ship (Update(false)), 3 = Note (no trigger), 4 = Bin Code (SaveRecord)
    local procedure SetField(var Doc: TestPage "LT TH Doc"; FieldNo: Integer; NewValue: Text)
    begin
        case FieldNo of
            1:
                Doc.Lines."Qty. to Handle".SetValue(NewValue);
            2:
                Doc.Lines."Qty. to Ship".SetValue(NewValue);
            3:
                Doc.Lines.Note.SetValue(NewValue);
            4:
                Doc.Lines."Bin Code".SetValue(NewValue);
        end;
    end;

    local procedure SetFieldSorted(var Doc: TestPage "LT TH Doc Sorted"; FieldNo: Integer; NewValue: Text)
    begin
        case FieldNo of
            1:
                Doc.Lines."Qty. to Handle".SetValue(NewValue);
            2:
                Doc.Lines."Qty. to Ship".SetValue(NewValue);
            3:
                Doc.Lines.Note.SetValue(NewValue);
            4:
                Doc.Lines."Bin Code".SetValue(NewValue);
        end;
    end;

    local procedure ObserveStored(var Observer: Codeunit "Probe Observer"; LineNo: Integer)
    var
        Line: Record "LT TH Line";
    begin
        Line.Get('D1', LineNo);
        Observer.Observe('stored ' + Format(LineNo), Format(Line."Qty. to Handle") + '|' + Format(Line."Qty. to Ship") + '|' + Line.Note + '|' + Line."Bin Code");
    end;

    local procedure OneLine(var Observer: Codeunit "Probe Observer"; FieldNo: Integer; LineNo: Integer)
    var
        Doc: TestPage "LT TH Doc";
        Log: Codeunit "LT TH Log";
        Value: Text;
    begin
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('D1');
        Doc.Lines.GoToKey('D1', LineNo);
        Log.Reset();
        if FieldNo = 4 then
            Value := 'NEW'
        else
            Value := '7';
        SetField(Doc, FieldNo, Value);
        Observer.Observe('line after', Doc.Lines."Line No.".Value());
        Observer.Observe('Qty. to Handle shown', Doc.Lines."Qty. to Handle".Value());
        Observer.Observe('Note shown', Doc.Lines.Note.Value());
        Observer.Observe('Bin Code shown', Doc.Lines."Bin Code".Value());
        Observer.Observe('host', Doc."No.".Value());
        Observer.Observe('log', Log.Get());
        Doc.Close();
        ObserveStored(Observer, LineNo);
    end;

    local procedure Walk(var Observer: Codeunit "Probe Observer"; FieldNo: Integer)
    var
        Doc: TestPage "LT TH Doc";
        Log: Codeunit "LT TH Log";
        Rows: Integer;
        Trail: Text;
        Value: Text;
    begin
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('D1');
        Doc.Lines.First();
        Log.Reset();
        repeat
            Rows += 1;
            Trail += Doc.Lines."Line No.".Value() + '->';
            if FieldNo = 4 then
                Value := 'W' + Format(Rows)
            else
                Value := Format(Rows);
            SetField(Doc, FieldNo, Value);
            Trail += Doc.Lines."Line No.".Value() + ';';
        until (not Doc.Lines.Next()) or (Rows = 6);
        Observer.Observe('rows', Format(Rows));
        Observer.Observe('trail', Trail);
        Observer.Observe('line at end', Doc.Lines."Line No.".Value());
        Observer.Observe('log', Log.Get());
        Doc.Close();
        ObserveStored(Observer, 10000);
        ObserveStored(Observer, 20000);
        ObserveStored(Observer, 30000);
    end;

    local procedure WalkSorted(var Observer: Codeunit "Probe Observer"; FieldNo: Integer)
    var
        Doc: TestPage "LT TH Doc Sorted";
        Rows: Integer;
        Trail: Text;
        Value: Text;
    begin
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('D1');
        Doc.Lines.First();
        repeat
            Rows += 1;
            Trail += Doc.Lines."Line No.".Value() + '->';
            if FieldNo = 4 then
                Value := 'W' + Format(Rows)
            else
                Value := Format(Rows);
            SetFieldSorted(Doc, FieldNo, Value);
            Trail += Doc.Lines."Line No.".Value() + ';';
        until (not Doc.Lines.Next()) or (Rows = 6);
        Observer.Observe('rows', Format(Rows));
        Observer.Observe('trail', Trail);
        Doc.Close();
    end;

    [Test]
    procedure TH_Line2_UpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine(Observer, 1, 20000);
        Observer.Finish();
    end;

    [Test]
    procedure TH_Line2_UpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine(Observer, 2, 20000);
        Observer.Finish();
    end;

    [Test]
    procedure TH_Line2_NoTrigger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine(Observer, 3, 20000);
        Observer.Finish();
    end;

    [Test]
    procedure TH_Line2_SaveRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine(Observer, 4, 20000);
        Observer.Finish();
    end;

    [Test]
    procedure TH_Line1_UpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine(Observer, 1, 10000);
        Observer.Finish();
    end;

    [Test]
    procedure TH_Line3_UpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OneLine(Observer, 2, 30000);
        Observer.Finish();
    end;

    [Test]
    procedure TH_Walk_UpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Walk(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure TH_Walk_UpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Walk(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure TH_Walk_NoTrigger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Walk(Observer, 3);
        Observer.Finish();
    end;

    [Test]
    procedure TH_Walk_SaveRecord()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Walk(Observer, 4);
        Observer.Finish();
    end;

    [Test]
    procedure TH_WalkSorted_UpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WalkSorted(Observer, 1);
        Observer.Finish();
    end;

    [Test]
    procedure TH_WalkSorted_UpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WalkSorted(Observer, 2);
        Observer.Finish();
    end;

    [Test]
    procedure TH_WalkSorted_NoTrigger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WalkSorted(Observer, 3);
        Observer.Finish();
    end;
}
