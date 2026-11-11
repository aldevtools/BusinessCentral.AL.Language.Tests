// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-saverecord-method
// Scope: in-scope
// local object: the page triggers of the part, its field triggers and two page extensions are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own tables 76730 and 76731, log codeunit 76732, pages 76733 and 76734, page extensions
//   76735 and 76736, test codeunit 76737
// Probe (al-runner issues 7403 and 6924): what xRec a page extension's OnAfterValidate reads after a row is stored inside a control
//   validation, on a ListPart (AutoSplitKey, DelayedInsert) of a Document page when the PART HAS PAGE TRIGGERS (OnAfterGetRecord,
//   OnNewRecord, OnAfterGetCurrRecord). XRecAfterUpdateInPart.al measures the same part without page triggers.
//   One page extension has OnBeforeValidate and OnAfterValidate on the quantity fields; another has an OnAfterValidate on "No." that
//   calls CurrPage.SaveRecord() (to insert the line before the delayed insert would). The quantity control's own OnValidate calls
//   CurrPage.SaveRecord() (Qty), CurrPage.Update() (Qty2) or nothing (Qty3).
//   Cells: a new line of a host opened with OpenNew; a new line below stored lines of a host opened with OpenEdit; a stored line;
//   "No." (with the SaveRecord) or Ref (without) set before the quantity.
//   A log entry is '<where> <field> rec=<Rec.field> xrec=<xRec.field> xline=<xRec."Line No."> line=<Rec."Line No.">'.
// Observation form: every test ends in Finish(), so the run fails on purpose and the failure message carries what BC produced.
// BC versions: 27, 28, 29

table 76730 "PXT Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 76731 "PXT Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; "No."; Code[20]) { }
        field(4; Ref; Code[20]) { }
        field(5; Qty; Integer) { }
        field(6; Qty2; Integer) { }
        field(7; Qty3; Integer) { }
    }

    keys { key(PK; "Doc No.", "Line No.") { Clustered = true; } }
}

codeunit 76732 "PXT Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Line: Text)
    begin
        Log += Line + '; ';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    procedure Entry(Where: Text; FieldName: Text; RecValue: Integer; XRecValue: Integer; Line: Record "PXT Line"; XLine: Record "PXT Line")
    begin
        Add(Where + ' ' + FieldName + ' rec=' + Format(RecValue) + ' xrec=' + Format(XRecValue) + ' xline=' + Format(XLine."Line No.") + ' line=' + Format(Line."Line No."));
    end;
}

page 76733 "PXT Lines"
{
    PageType = ListPart;
    SourceTable = "PXT Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; Editable = false; }
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Ref; Rec.Ref) { ApplicationArea = All; }
                field(Qty; Rec.Qty)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Entry('base', 'Qty', Rec.Qty, xRec.Qty, Rec, xRec);
                        CurrPage.SaveRecord();
                    end;
                }
                field(Qty2; Rec.Qty2)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Entry('base', 'Qty2', Rec.Qty2, xRec.Qty2, Rec, xRec);
                        CurrPage.Update();
                    end;
                }
                field(Qty3; Rec.Qty3)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Entry('base', 'Qty3', Rec.Qty3, xRec.Qty3, Rec, xRec);
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "PXT Log";

    trigger OnAfterGetRecord()
    begin
        Log.Add('agr line=' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('new xline=' + Format(xRec."Line No."));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('agcr line=' + Format(Rec."Line No.") + ' xline=' + Format(xRec."Line No."));
    end;
}

page 76734 "PXT Doc"
{
    PageType = Document;
    SourceTable = "PXT Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
            part(Lines; "PXT Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

pageextension 76735 "PXT Lines Qty Ext" extends "PXT Lines"
{
    layout
    {
        modify(Qty)
        {
            trigger OnBeforeValidate()
            begin
                Log.Entry('before', 'Qty', Rec.Qty, xRec.Qty, Rec, xRec);
            end;

            trigger OnAfterValidate()
            begin
                Log.Entry('after', 'Qty', Rec.Qty, xRec.Qty, Rec, xRec);
            end;
        }
        modify(Qty2)
        {
            trigger OnBeforeValidate()
            begin
                Log.Entry('before', 'Qty2', Rec.Qty2, xRec.Qty2, Rec, xRec);
            end;

            trigger OnAfterValidate()
            begin
                Log.Entry('after', 'Qty2', Rec.Qty2, xRec.Qty2, Rec, xRec);
            end;
        }
        modify(Qty3)
        {
            trigger OnBeforeValidate()
            begin
                Log.Entry('before', 'Qty3', Rec.Qty3, xRec.Qty3, Rec, xRec);
            end;

            trigger OnAfterValidate()
            begin
                Log.Entry('after', 'Qty3', Rec.Qty3, xRec.Qty3, Rec, xRec);
            end;
        }
    }

    var
        Log: Codeunit "PXT Log";
}

pageextension 76736 "PXT Lines Save Ext" extends "PXT Lines"
{
    layout
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            begin
                Log.Add('after No. line=' + Format(Rec."Line No.") + ' save');
                CurrPage.SaveRecord();
            end;
        }
    }

    var
        Log: Codeunit "PXT Log";
}

codeunit 76737 "PXT Part Triggers Save Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "PXT Log";

    // Document H1 has the lines 10000 and 20000 (quantities 1 and 2).
    local procedure Seed()
    var
        Head: Record "PXT Head";
        Line: Record "PXT Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."No." := 'H1';
        Head.Insert();
        AddLine(10000, 1);
        AddLine(20000, 2);
        Log.Take();
    end;

    local procedure AddLine(LineNo: Integer; Value: Integer)
    var
        Line: Record "PXT Line";
    begin
        Line."Doc No." := 'H1';
        Line."Line No." := LineNo;
        Line.Qty := Value;
        Line.Qty2 := Value;
        Line.Qty3 := Value;
        Line.Insert();
    end;

    local procedure Stored(): Text
    var
        Line: Record "PXT Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line."Doc No." + '/' + Format(Line."Line No.") + ': ' + Line."No." + ' ' + Line.Ref + ' ' + Format(Line.Qty) + ' ' + Format(Line.Qty2) + ' ' + Format(Line.Qty3) + '; ';
            until Line.Next() = 0;
        if Result = '' then
            exit('no lines');
        exit(Result);
    end;

    local procedure SetFirst(var Doc: TestPage "PXT Doc"; WithSave: Boolean)
    begin
        if WithSave then
            Doc.Lines."No.".SetValue('ITEM1')
        else
            Doc.Lines.Ref.SetValue('REF1');
    end;

    local procedure SetQty(var Doc: TestPage "PXT Doc"; QtyIndex: Integer; NewValue: Integer)
    begin
        case QtyIndex of
            1:
                Doc.Lines.Qty.SetValue(NewValue);
            2:
                Doc.Lines.Qty2.SetValue(NewValue);
            3:
                Doc.Lines.Qty3.SetValue(NewValue);
        end;
    end;

    // The report's shape: the host opened with OpenNew, a header typed, then on the part's new line "No." (or Ref) and a quantity.
    local procedure HostOpenNew(var Observer: Codeunit "Probe Observer"; WithSave: Boolean; QtyIndex: Integer)
    var
        Doc: TestPage "PXT Doc";
    begin
        Seed();
        Doc.OpenNew();
        Doc."No.".SetValue('N1');
        Observer.Observe('header typed', Log.Take());
        SetFirst(Doc, WithSave);
        Observer.Observe('first field', Log.Take());
        Observer.Observe('lines after the first field', Stored());
        SetQty(Doc, QtyIndex, 5);
        Observer.Observe('quantity 0 -> 5', Log.Take());
        Observer.Observe('lines after the quantity', Stored());
        SetQty(Doc, QtyIndex, 6);
        Observer.Observe('quantity 5 -> 6', Log.Take());
        Doc.Close();
        Observer.Observe('lines after close', Stored());
        Observer.Finish();
    end;

    local procedure NewLineBelowStored(var Observer: Codeunit "Probe Observer"; WithSave: Boolean; QtyIndex: Integer)
    var
        Doc: TestPage "PXT Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Doc.Lines.New();
        Log.Take();
        SetFirst(Doc, WithSave);
        Observer.Observe('first field', Log.Take());
        SetQty(Doc, QtyIndex, 5);
        Observer.Observe('quantity 0 -> 5', Log.Take());
        Observer.Observe('lines after the quantity', Stored());
        Doc.Close();
        Observer.Observe('lines after close', Stored());
        Observer.Finish();
    end;

    local procedure StoredLine(var Observer: Codeunit "Probe Observer"; WithSave: Boolean; QtyIndex: Integer)
    var
        Doc: TestPage "PXT Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.First();
        Log.Take();
        SetFirst(Doc, WithSave);
        Observer.Observe('first field', Log.Take());
        SetQty(Doc, QtyIndex, 5);
        Observer.Observe('quantity 1 -> 5', Log.Take());
        Observer.Observe('lines after the quantity', Stored());
        Doc.Close();
        Observer.Observe('lines after close', Stored());
        Observer.Finish();
    end;

    [Test]
    procedure OpenNew_ItemNoSaves_Qty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostOpenNew(Observer, true, 1);
    end;

    [Test]
    procedure OpenNew_ItemNoSaves_Qty2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostOpenNew(Observer, true, 2);
    end;

    [Test]
    procedure OpenNew_ItemNoSaves_Qty3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostOpenNew(Observer, true, 3);
    end;

    [Test]
    procedure OpenNew_Ref_Qty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostOpenNew(Observer, false, 1);
    end;

    [Test]
    procedure OpenNew_Ref_Qty3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HostOpenNew(Observer, false, 3);
    end;

    [Test]
    procedure OpenEdit_NewLine_ItemNoSaves_Qty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NewLineBelowStored(Observer, true, 1);
    end;

    [Test]
    procedure OpenEdit_NewLine_Ref_Qty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NewLineBelowStored(Observer, false, 1);
    end;

    [Test]
    procedure OpenEdit_NewLine_ItemNoSaves_Qty3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NewLineBelowStored(Observer, true, 3);
    end;

    [Test]
    procedure OpenEdit_StoredLine_ItemNoSaves_Qty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StoredLine(Observer, true, 1);
    end;

    [Test]
    procedure OpenEdit_StoredLine_Ref_Qty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StoredLine(Observer, false, 1);
    end;
}
