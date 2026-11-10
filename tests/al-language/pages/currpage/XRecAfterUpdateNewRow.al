// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// local object: the field triggers of the base pages (each calls CurrPage.Update in another form) are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own table 61830, log codeunit 61831, pages 61832 and 61833, page extensions 61834 and 61835, test codeunit 61836
// Probe (al-runner issue 7403, new rows): what xRec holds in a page extension's OnAfterValidate of a field whose base OnValidate calls
//   CurrPage.Update, when the row is new. Area: the call (none, Update(), Update(true), Update(false), SaveRecord(), SaveRecord then
//   Update(false)) crossed with the new row: on a list after New() from the stored row R1 with the key typed first (the row is inserted
//   before the field is set), on a list with the field typed first (the row has a blank key), and on a card after OpenNew().
//   The field is set to 5 and then to 6. R1 holds 1 in every field, so xrec=1 means xRec is R1 and xrec=0 means xRec is blank.
//   'stored' is the field of the stored row, or 'no row'.
// Next to: pages/currpage/Y7403XRecAfterCurrPageUpdate.al (codeunit 99926: the same pages and calls on the stored row R1; these pages
//   repeat its shape because that log codeunit is SingleInstance and belongs to that test codeunit),
//   pages/currpage/XRecAfterUpdateInPart.al (the same calls on a ListPart of a document page).
// Observation form: every test ends in Finish(), so the run fails on purpose and the failure message carries what BC produced.
// BC versions: 27, 28, 29

table 61830 "PAG XRec New Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; F0; Integer) { }
        field(3; F1; Integer) { }
        field(4; F2; Integer) { }
        field(5; F3; Integer) { }
        field(6; F4; Integer) { }
        field(7; F5; Integer) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 61831 "PAG XRec New Log"
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
}

page 61832 "PAG XRec New List"
{
    PageType = List;
    SourceTable = "PAG XRec New Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(F0; Rec.F0)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F0 (no call) rec=' + Format(Rec.F0) + ' xrec=' + Format(xRec.F0) + ' xno=' + xRec."No.");
                    end;
                }
                field(F1; Rec.F1)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F1 (CurrPage.Update()) rec=' + Format(Rec.F1) + ' xrec=' + Format(xRec.F1) + ' xno=' + xRec."No.");
                        CurrPage.Update();
                    end;
                }
                field(F2; Rec.F2)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F2 (CurrPage.Update(true)) rec=' + Format(Rec.F2) + ' xrec=' + Format(xRec.F2) + ' xno=' + xRec."No.");
                        CurrPage.Update(true);
                    end;
                }
                field(F3; Rec.F3)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F3 (CurrPage.Update(false)) rec=' + Format(Rec.F3) + ' xrec=' + Format(xRec.F3) + ' xno=' + xRec."No.");
                        CurrPage.Update(false);
                    end;
                }
                field(F4; Rec.F4)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F4 (CurrPage.SaveRecord()) rec=' + Format(Rec.F4) + ' xrec=' + Format(xRec.F4) + ' xno=' + xRec."No.");
                        CurrPage.SaveRecord();
                    end;
                }
                field(F5; Rec.F5)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F5 (SaveRecord then Update(false)) rec=' + Format(Rec.F5) + ' xrec=' + Format(xRec.F5) + ' xno=' + xRec."No.");
                        CurrPage.SaveRecord(); CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "PAG XRec New Log";
}

page 61833 "PAG XRec New Card"
{
    PageType = Card;
    SourceTable = "PAG XRec New Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(F0; Rec.F0)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F0 (no call) rec=' + Format(Rec.F0) + ' xrec=' + Format(xRec.F0) + ' xno=' + xRec."No.");
                    end;
                }
                field(F1; Rec.F1)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F1 (CurrPage.Update()) rec=' + Format(Rec.F1) + ' xrec=' + Format(xRec.F1) + ' xno=' + xRec."No.");
                        CurrPage.Update();
                    end;
                }
                field(F2; Rec.F2)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F2 (CurrPage.Update(true)) rec=' + Format(Rec.F2) + ' xrec=' + Format(xRec.F2) + ' xno=' + xRec."No.");
                        CurrPage.Update(true);
                    end;
                }
                field(F3; Rec.F3)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F3 (CurrPage.Update(false)) rec=' + Format(Rec.F3) + ' xrec=' + Format(xRec.F3) + ' xno=' + xRec."No.");
                        CurrPage.Update(false);
                    end;
                }
                field(F4; Rec.F4)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F4 (CurrPage.SaveRecord()) rec=' + Format(Rec.F4) + ' xrec=' + Format(xRec.F4) + ' xno=' + xRec."No.");
                        CurrPage.SaveRecord();
                    end;
                }
                field(F5; Rec.F5)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F5 (SaveRecord then Update(false)) rec=' + Format(Rec.F5) + ' xrec=' + Format(xRec.F5) + ' xno=' + xRec."No.");
                        CurrPage.SaveRecord(); CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "PAG XRec New Log";
}

pageextension 61834 "PAG XRec New List Ext" extends "PAG XRec New List"
{
    layout
    {
        modify(F0)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F0 rec=' + Format(Rec.F0) + ' xrec=' + Format(xRec.F0) + ' xno=' + xRec."No." + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F1)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F1 rec=' + Format(Rec.F1) + ' xrec=' + Format(xRec.F1) + ' xno=' + xRec."No." + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F2)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F2 rec=' + Format(Rec.F2) + ' xrec=' + Format(xRec.F2) + ' xno=' + xRec."No." + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F3)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F3 rec=' + Format(Rec.F3) + ' xrec=' + Format(xRec.F3) + ' xno=' + xRec."No." + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F4)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F4 rec=' + Format(Rec.F4) + ' xrec=' + Format(xRec.F4) + ' xno=' + xRec."No." + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F5)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F5 rec=' + Format(Rec.F5) + ' xrec=' + Format(xRec.F5) + ' xno=' + xRec."No." + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
    }

    var
        Log: Codeunit "PAG XRec New Log";
}

pageextension 61835 "PAG XRec New Card Ext" extends "PAG XRec New Card"
{
    layout
    {
        modify(F0)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F0 rec=' + Format(Rec.F0) + ' xrec=' + Format(xRec.F0) + ' xno=' + xRec."No." + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F1)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F1 rec=' + Format(Rec.F1) + ' xrec=' + Format(xRec.F1) + ' xno=' + xRec."No." + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F2)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F2 rec=' + Format(Rec.F2) + ' xrec=' + Format(xRec.F2) + ' xno=' + xRec."No." + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F3)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F3 rec=' + Format(Rec.F3) + ' xrec=' + Format(xRec.F3) + ' xno=' + xRec."No." + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F4)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F4 rec=' + Format(Rec.F4) + ' xrec=' + Format(xRec.F4) + ' xno=' + xRec."No." + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F5)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F5 rec=' + Format(Rec.F5) + ' xrec=' + Format(xRec.F5) + ' xno=' + xRec."No." + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
    }

    var
        Log: Codeunit "PAG XRec New Log";
}

codeunit 61836 "PAG XRec New Row Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "PAG XRec New Log";

    local procedure Seed()
    var
        Row: Record "PAG XRec New Row";
    begin
        Row.DeleteAll();
        Row."No." := 'R1';
        Row.F0 := 1;
        Row.F1 := 1;
        Row.F2 := 1;
        Row.F3 := 1;
        Row.F4 := 1;
        Row.F5 := 1;
        Row.Insert();
        Log.Take();
    end;

    local procedure SetListField(var P: TestPage "PAG XRec New List"; FieldIndex: Integer; NewValue: Integer)
    begin
        case FieldIndex of
            0:
                P.F0.SetValue(NewValue);
            1:
                P.F1.SetValue(NewValue);
            2:
                P.F2.SetValue(NewValue);
            3:
                P.F3.SetValue(NewValue);
            4:
                P.F4.SetValue(NewValue);
            5:
                P.F5.SetValue(NewValue);
        end;
    end;

    local procedure SetCardField(var P: TestPage "PAG XRec New Card"; FieldIndex: Integer; NewValue: Integer)
    begin
        case FieldIndex of
            0:
                P.F0.SetValue(NewValue);
            1:
                P.F1.SetValue(NewValue);
            2:
                P.F2.SetValue(NewValue);
            3:
                P.F3.SetValue(NewValue);
            4:
                P.F4.SetValue(NewValue);
            5:
                P.F5.SetValue(NewValue);
        end;
    end;

    local procedure StoredField(RowNo: Code[20]; FieldIndex: Integer): Text
    var
        Row: Record "PAG XRec New Row";
    begin
        if not Row.Get(RowNo) then
            exit('no row');
        case FieldIndex of
            0:
                exit(Format(Row.F0));
            1:
                exit(Format(Row.F1));
            2:
                exit(Format(Row.F2));
            3:
                exit(Format(Row.F3));
            4:
                exit(Format(Row.F4));
            5:
                exit(Format(Row.F5));
        end;
    end;

    local procedure ListNewRowKeyTyped(FieldIndex: Integer; var Observer: Codeunit "Probe Observer")
    var
        P: TestPage "PAG XRec New List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.New();
        P."No.".SetValue('N1');
        SetListField(P, FieldIndex, 5);
        Observer.Observe('new row, first set 0 -> 5', Log.Take());
        Observer.Observe('stored after the first set', StoredField('N1', FieldIndex));
        SetListField(P, FieldIndex, 6);
        Observer.Observe('new row, second set 5 -> 6', Log.Take());
        Observer.Observe('stored after the second set', StoredField('N1', FieldIndex));
    end;

    local procedure ListNewRowFieldFirst(FieldIndex: Integer; var Observer: Codeunit "Probe Observer")
    var
        P: TestPage "PAG XRec New List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.New();
        SetListField(P, FieldIndex, 5);
        Observer.Observe('new row with a blank key, first set 0 -> 5', Log.Take());
        Observer.Observe('stored after the first set', StoredField('', FieldIndex));
        SetListField(P, FieldIndex, 6);
        Observer.Observe('new row with a blank key, second set 5 -> 6', Log.Take());
        Observer.Observe('stored after the second set', StoredField('', FieldIndex));
    end;

    local procedure CardOpenNewKeyTyped(FieldIndex: Integer; var Observer: Codeunit "Probe Observer")
    var
        P: TestPage "PAG XRec New Card";
    begin
        Seed();
        P.OpenNew();
        P."No.".SetValue('N1');
        SetCardField(P, FieldIndex, 5);
        Observer.Observe('new card, first set 0 -> 5', Log.Take());
        Observer.Observe('stored after the first set', StoredField('N1', FieldIndex));
        SetCardField(P, FieldIndex, 6);
        Observer.Observe('new card, second set 5 -> 6', Log.Take());
        Observer.Observe('stored after the second set', StoredField('N1', FieldIndex));
    end;

    [Test]
    procedure List_NewRow_KeyTyped_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListNewRowKeyTyped(0, Observer);
        Observer.Expect('new row, first set 0 -> 5', 'base F0 (no call) rec=5 xrec=0 xno=N1; ext F0 rec=5 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the first set', '0');
        Observer.Expect('new row, second set 5 -> 6', 'base F0 (no call) rec=6 xrec=5 xno=N1; ext F0 rec=6 xrec=5 xno=N1 equal=No; ');
        Observer.Expect('stored after the second set', '0');
        Observer.Verify();
    end;

    [Test]
    procedure List_NewRow_KeyTyped_F1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListNewRowKeyTyped(1, Observer);
        Observer.Expect('new row, first set 0 -> 5', 'base F1 (CurrPage.Update()) rec=5 xrec=0 xno=N1; ext F1 rec=5 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the first set', '5');
        Observer.Expect('new row, second set 5 -> 6', 'base F1 (CurrPage.Update()) rec=6 xrec=5 xno=N1; ext F1 rec=6 xrec=5 xno=N1 equal=No; ');
        Observer.Expect('stored after the second set', '6');
        Observer.Verify();
    end;

    [Test]
    procedure List_NewRow_KeyTyped_F2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListNewRowKeyTyped(2, Observer);
        Observer.Expect('new row, first set 0 -> 5', 'base F2 (CurrPage.Update(true)) rec=5 xrec=0 xno=N1; ext F2 rec=5 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the first set', '5');
        Observer.Expect('new row, second set 5 -> 6', 'base F2 (CurrPage.Update(true)) rec=6 xrec=5 xno=N1; ext F2 rec=6 xrec=5 xno=N1 equal=No; ');
        Observer.Expect('stored after the second set', '6');
        Observer.Verify();
    end;

    [Test]
    procedure List_NewRow_KeyTyped_F3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListNewRowKeyTyped(3, Observer);
        Observer.Expect('new row, first set 0 -> 5', 'base F3 (CurrPage.Update(false)) rec=5 xrec=0 xno=N1; ext F3 rec=5 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the first set', '0');
        Observer.Expect('new row, second set 5 -> 6', 'base F3 (CurrPage.Update(false)) rec=6 xrec=0 xno=N1; ext F3 rec=6 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the second set', '0');
        Observer.Verify();
    end;

    [Test]
    procedure List_NewRow_KeyTyped_F4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListNewRowKeyTyped(4, Observer);
        Observer.Expect('new row, first set 0 -> 5', 'base F4 (CurrPage.SaveRecord()) rec=5 xrec=0 xno=N1; ext F4 rec=5 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the first set', '5');
        Observer.Expect('new row, second set 5 -> 6', 'base F4 (CurrPage.SaveRecord()) rec=6 xrec=5 xno=N1; ext F4 rec=6 xrec=5 xno=N1 equal=No; ');
        Observer.Expect('stored after the second set', '6');
        Observer.Verify();
    end;

    [Test]
    procedure List_NewRow_KeyTyped_F5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListNewRowKeyTyped(5, Observer);
        Observer.Expect('new row, first set 0 -> 5', 'base F5 (SaveRecord then Update(false)) rec=5 xrec=0 xno=N1; ext F5 rec=5 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the first set', '5');
        Observer.Expect('new row, second set 5 -> 6', 'base F5 (SaveRecord then Update(false)) rec=6 xrec=5 xno=N1; ext F5 rec=6 xrec=5 xno=N1 equal=No; ');
        Observer.Expect('stored after the second set', '6');
        Observer.Verify();
    end;

    [Test]
    procedure List_NewRow_FieldFirst_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListNewRowFieldFirst(0, Observer);
        Observer.Expect('new row with a blank key, first set 0 -> 5', 'base F0 (no call) rec=5 xrec=0 xno=; ext F0 rec=5 xrec=0 xno= equal=No; ');
        Observer.Expect('stored after the first set', 'no row');
        Observer.Expect('new row with a blank key, second set 5 -> 6', 'base F0 (no call) rec=6 xrec=5 xno=; ext F0 rec=6 xrec=5 xno= equal=No; ');
        Observer.Expect('stored after the second set', 'no row');
        Observer.Verify();
    end;

    [Test]
    procedure List_NewRow_FieldFirst_F1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListNewRowFieldFirst(1, Observer);
        Observer.Expect('new row with a blank key, first set 0 -> 5', 'base F1 (CurrPage.Update()) rec=5 xrec=0 xno=; ext F1 rec=5 xrec=0 xno= equal=No; ');
        Observer.Expect('stored after the first set', '5');
        Observer.Expect('new row with a blank key, second set 5 -> 6', 'base F1 (CurrPage.Update()) rec=6 xrec=5 xno=; ext F1 rec=6 xrec=5 xno= equal=No; ');
        Observer.Expect('stored after the second set', '6');
        Observer.Verify();
    end;

    [Test]
    procedure List_NewRow_FieldFirst_F2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListNewRowFieldFirst(2, Observer);
        Observer.Expect('new row with a blank key, first set 0 -> 5', 'base F2 (CurrPage.Update(true)) rec=5 xrec=0 xno=; ext F2 rec=5 xrec=0 xno= equal=No; ');
        Observer.Expect('stored after the first set', '5');
        Observer.Expect('new row with a blank key, second set 5 -> 6', 'base F2 (CurrPage.Update(true)) rec=6 xrec=5 xno=; ext F2 rec=6 xrec=5 xno= equal=No; ');
        Observer.Expect('stored after the second set', '6');
        Observer.Verify();
    end;

    [Test]
    procedure List_NewRow_FieldFirst_F3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListNewRowFieldFirst(3, Observer);
        Observer.Expect('new row with a blank key, first set 0 -> 5', 'base F3 (CurrPage.Update(false)) rec=5 xrec=0 xno=; ext F3 rec=5 xrec=0 xno= equal=No; ');
        Observer.Expect('stored after the first set', 'no row');
        Observer.Expect('new row with a blank key, second set 5 -> 6', 'base F3 (CurrPage.Update(false)) rec=6 xrec=0 xno=; ext F3 rec=6 xrec=0 xno= equal=No; ');
        Observer.Expect('stored after the second set', 'no row');
        Observer.Verify();
    end;

    [Test]
    procedure List_NewRow_FieldFirst_F4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListNewRowFieldFirst(4, Observer);
        Observer.Expect('new row with a blank key, first set 0 -> 5', 'base F4 (CurrPage.SaveRecord()) rec=5 xrec=0 xno=; ext F4 rec=5 xrec=0 xno= equal=No; ');
        Observer.Expect('stored after the first set', '5');
        Observer.Expect('new row with a blank key, second set 5 -> 6', 'base F4 (CurrPage.SaveRecord()) rec=6 xrec=5 xno=; ext F4 rec=6 xrec=5 xno= equal=No; ');
        Observer.Expect('stored after the second set', '6');
        Observer.Verify();
    end;

    [Test]
    procedure List_NewRow_FieldFirst_F5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ListNewRowFieldFirst(5, Observer);
        Observer.Expect('new row with a blank key, first set 0 -> 5', 'base F5 (SaveRecord then Update(false)) rec=5 xrec=0 xno=; ext F5 rec=5 xrec=0 xno= equal=No; ');
        Observer.Expect('stored after the first set', '5');
        Observer.Expect('new row with a blank key, second set 5 -> 6', 'base F5 (SaveRecord then Update(false)) rec=6 xrec=5 xno=; ext F5 rec=6 xrec=5 xno= equal=No; ');
        Observer.Expect('stored after the second set', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenNew_KeyTyped_F0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardOpenNewKeyTyped(0, Observer);
        Observer.Expect('new card, first set 0 -> 5', 'base F0 (no call) rec=5 xrec=0 xno=N1; ext F0 rec=5 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the first set', '0');
        Observer.Expect('new card, second set 5 -> 6', 'base F0 (no call) rec=6 xrec=5 xno=N1; ext F0 rec=6 xrec=5 xno=N1 equal=No; ');
        Observer.Expect('stored after the second set', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenNew_KeyTyped_F1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardOpenNewKeyTyped(1, Observer);
        Observer.Expect('new card, first set 0 -> 5', 'base F1 (CurrPage.Update()) rec=5 xrec=0 xno=N1; ext F1 rec=5 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the first set', '5');
        Observer.Expect('new card, second set 5 -> 6', 'base F1 (CurrPage.Update()) rec=6 xrec=5 xno=N1; ext F1 rec=6 xrec=5 xno=N1 equal=No; ');
        Observer.Expect('stored after the second set', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenNew_KeyTyped_F2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardOpenNewKeyTyped(2, Observer);
        Observer.Expect('new card, first set 0 -> 5', 'base F2 (CurrPage.Update(true)) rec=5 xrec=0 xno=N1; ext F2 rec=5 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the first set', '5');
        Observer.Expect('new card, second set 5 -> 6', 'base F2 (CurrPage.Update(true)) rec=6 xrec=5 xno=N1; ext F2 rec=6 xrec=5 xno=N1 equal=No; ');
        Observer.Expect('stored after the second set', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenNew_KeyTyped_F3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardOpenNewKeyTyped(3, Observer);
        Observer.Expect('new card, first set 0 -> 5', 'base F3 (CurrPage.Update(false)) rec=5 xrec=0 xno=N1; ext F3 rec=5 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the first set', '0');
        Observer.Expect('new card, second set 5 -> 6', 'base F3 (CurrPage.Update(false)) rec=6 xrec=0 xno=N1; ext F3 rec=6 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the second set', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenNew_KeyTyped_F4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardOpenNewKeyTyped(4, Observer);
        Observer.Expect('new card, first set 0 -> 5', 'base F4 (CurrPage.SaveRecord()) rec=5 xrec=0 xno=N1; ext F4 rec=5 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the first set', '5');
        Observer.Expect('new card, second set 5 -> 6', 'base F4 (CurrPage.SaveRecord()) rec=6 xrec=5 xno=N1; ext F4 rec=6 xrec=5 xno=N1 equal=No; ');
        Observer.Expect('stored after the second set', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Card_OpenNew_KeyTyped_F5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CardOpenNewKeyTyped(5, Observer);
        Observer.Expect('new card, first set 0 -> 5', 'base F5 (SaveRecord then Update(false)) rec=5 xrec=0 xno=N1; ext F5 rec=5 xrec=0 xno=N1 equal=No; ');
        Observer.Expect('stored after the first set', '5');
        Observer.Expect('new card, second set 5 -> 6', 'base F5 (SaveRecord then Update(false)) rec=6 xrec=5 xno=N1; ext F5 rec=6 xrec=5 xno=N1 equal=No; ');
        Observer.Expect('stored after the second set', '6');
        Observer.Verify();
    end;
}
