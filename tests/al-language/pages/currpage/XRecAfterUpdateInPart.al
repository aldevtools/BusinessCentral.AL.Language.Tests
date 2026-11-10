// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// local object: the field triggers of the part page (each calls CurrPage.Update in another form) and of its table are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own tables 61810 and 61811, log codeunit 61812, pages 61813 and 61814, page extension 61816, test codeunit 61817
// Probe (al-runner issue 7403, the reporter's page shape): what xRec holds in a page extension's OnBeforeValidate and OnAfterValidate, in the
//   table field's OnValidate and in the page field's OnValidate, when the field is on a ListPart of a document page (AutoSplitKey and
//   DelayedInsert, as on the Base Application document subforms) and the page field's OnValidate calls CurrPage.Update.
//   Area: the call (none, Update(), Update(true) from a procedure, Update(false), SaveRecord()) crossed with the row (a stored line, a new line
//   below the stored lines with the field typed first, a new line on which another field ran Update() before, the first line of a document
//   with no lines) and the part opened alone as its own TestPage.
//   A log entry is '<where> <field> rec=<Rec.field> xrec=<xRec.field> xline=<xRec."Line No.">'; where is 'before' and 'after' (the page
//   extension), 'table' (the table field's OnValidate) and 'base' (the page field's OnValidate, before its call).
// Next to: pages/currpage/Y7403XRecAfterCurrPageUpdate.al (the same calls on a List and a Card that are opened alone, stored row),
//   pages/currpage/XRecAfterUpdateNewRow.al (the same, new rows),
//   pages/currpage/Y7428OnModifyRecordAfterUpdate.al (what OnModifyRecord sees after the call).
// Observation form: every test ends in Finish(), so the run fails on purpose and the failure message carries what BC produced.
// BC versions: 27, 28, 29

table 61810 "PAG XRec Part Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 61811 "PAG XRec Part Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; F0; Integer)
        {
            trigger OnValidate()
            begin
                Log.Add('table F0 rec=' + Format(Rec.F0) + ' xrec=' + Format(xRec.F0) + ' xline=' + Format(xRec."Line No."));
            end;
        }
        field(4; F1; Integer)
        {
            trigger OnValidate()
            begin
                Log.Add('table F1 rec=' + Format(Rec.F1) + ' xrec=' + Format(xRec.F1) + ' xline=' + Format(xRec."Line No."));
            end;
        }
        field(5; F2; Integer)
        {
            trigger OnValidate()
            begin
                Log.Add('table F2 rec=' + Format(Rec.F2) + ' xrec=' + Format(xRec.F2) + ' xline=' + Format(xRec."Line No."));
            end;
        }
        field(6; F3; Integer)
        {
            trigger OnValidate()
            begin
                Log.Add('table F3 rec=' + Format(Rec.F3) + ' xrec=' + Format(xRec.F3) + ' xline=' + Format(xRec."Line No."));
            end;
        }
        field(7; F4; Integer)
        {
            trigger OnValidate()
            begin
                Log.Add('table F4 rec=' + Format(Rec.F4) + ' xrec=' + Format(xRec.F4) + ' xline=' + Format(xRec."Line No."));
            end;
        }
    }

    keys { key(PK; "Doc No.", "Line No.") { Clustered = true; } }

    var
        Log: Codeunit "PAG XRec Part Log";
}

codeunit 61812 "PAG XRec Part Log"
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

page 61813 "PAG XRec Part Lines"
{
    PageType = ListPart;
    SourceTable = "PAG XRec Part Line";
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
                field(F0; Rec.F0)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F0 rec=' + Format(Rec.F0) + ' xrec=' + Format(xRec.F0) + ' xline=' + Format(xRec."Line No."));
                    end;
                }
                field(F1; Rec.F1)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F1 rec=' + Format(Rec.F1) + ' xrec=' + Format(xRec.F1) + ' xline=' + Format(xRec."Line No."));
                        CurrPage.Update();
                    end;
                }
                field(F2; Rec.F2)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F2 rec=' + Format(Rec.F2) + ' xrec=' + Format(xRec.F2) + ' xline=' + Format(xRec."Line No."));
                        F2OnAfterValidate();
                    end;
                }
                field(F3; Rec.F3)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F3 rec=' + Format(Rec.F3) + ' xrec=' + Format(xRec.F3) + ' xline=' + Format(xRec."Line No."));
                        CurrPage.Update(false);
                    end;
                }
                field(F4; Rec.F4)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F4 rec=' + Format(Rec.F4) + ' xrec=' + Format(xRec.F4) + ' xline=' + Format(xRec."Line No."));
                        CurrPage.SaveRecord();
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "PAG XRec Part Log";

    local procedure F2OnAfterValidate()
    begin
        CurrPage.Update(true);
    end;
}

page 61814 "PAG XRec Part Doc"
{
    PageType = Document;
    SourceTable = "PAG XRec Part Head";
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
            part(Lines; "PAG XRec Part Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

pageextension 61816 "PAG XRec Part Lines Ext" extends "PAG XRec Part Lines"
{
    layout
    {
        modify(F0)
        {
            trigger OnBeforeValidate()
            begin
                Log.Add('before F0 rec=' + Format(Rec.F0) + ' xrec=' + Format(xRec.F0) + ' xline=' + Format(xRec."Line No."));
            end;

            trigger OnAfterValidate()
            begin
                Log.Add('after F0 rec=' + Format(Rec.F0) + ' xrec=' + Format(xRec.F0) + ' xline=' + Format(xRec."Line No.") + ' line=' + Format(Rec."Line No."));
            end;
        }
        modify(F1)
        {
            trigger OnBeforeValidate()
            begin
                Log.Add('before F1 rec=' + Format(Rec.F1) + ' xrec=' + Format(xRec.F1) + ' xline=' + Format(xRec."Line No."));
            end;

            trigger OnAfterValidate()
            begin
                Log.Add('after F1 rec=' + Format(Rec.F1) + ' xrec=' + Format(xRec.F1) + ' xline=' + Format(xRec."Line No.") + ' line=' + Format(Rec."Line No."));
            end;
        }
        modify(F2)
        {
            trigger OnBeforeValidate()
            begin
                Log.Add('before F2 rec=' + Format(Rec.F2) + ' xrec=' + Format(xRec.F2) + ' xline=' + Format(xRec."Line No."));
            end;

            trigger OnAfterValidate()
            begin
                Log.Add('after F2 rec=' + Format(Rec.F2) + ' xrec=' + Format(xRec.F2) + ' xline=' + Format(xRec."Line No.") + ' line=' + Format(Rec."Line No."));
            end;
        }
        modify(F3)
        {
            trigger OnBeforeValidate()
            begin
                Log.Add('before F3 rec=' + Format(Rec.F3) + ' xrec=' + Format(xRec.F3) + ' xline=' + Format(xRec."Line No."));
            end;

            trigger OnAfterValidate()
            begin
                Log.Add('after F3 rec=' + Format(Rec.F3) + ' xrec=' + Format(xRec.F3) + ' xline=' + Format(xRec."Line No.") + ' line=' + Format(Rec."Line No."));
            end;
        }
        modify(F4)
        {
            trigger OnBeforeValidate()
            begin
                Log.Add('before F4 rec=' + Format(Rec.F4) + ' xrec=' + Format(xRec.F4) + ' xline=' + Format(xRec."Line No."));
            end;

            trigger OnAfterValidate()
            begin
                Log.Add('after F4 rec=' + Format(Rec.F4) + ' xrec=' + Format(xRec.F4) + ' xline=' + Format(xRec."Line No.") + ' line=' + Format(Rec."Line No."));
            end;
        }
    }

    var
        Log: Codeunit "PAG XRec Part Log";
}

codeunit 61817 "PAG XRec Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "PAG XRec Part Log";

    // Document H1 has the lines 10000 (every field 1) and 20000 (every field 2); document H2 has no lines.
    local procedure Seed()
    var
        Head: Record "PAG XRec Part Head";
        Line: Record "PAG XRec Part Line";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."No." := 'H1';
        Head.Insert();
        Head."No." := 'H2';
        Head.Insert();
        AddLine('H1', 10000, 1);
        AddLine('H1', 20000, 2);
        Log.Take();
    end;

    local procedure AddLine(DocNo: Code[20]; LineNo: Integer; Value: Integer)
    var
        Line: Record "PAG XRec Part Line";
    begin
        Line."Doc No." := DocNo;
        Line."Line No." := LineNo;
        Line.F0 := Value;
        Line.F1 := Value;
        Line.F2 := Value;
        Line.F3 := Value;
        Line.F4 := Value;
        Line.Insert();
    end;

    // The stored lines of a document: '<line no>: F0 F1 F2 F3 F4; ' for each.
    local procedure Stored(DocNo: Code[20]): Text
    var
        Line: Record "PAG XRec Part Line";
        Result: Text;
    begin
        Line.SetRange("Doc No.", DocNo);
        if Line.FindSet() then
            repeat
                Result += Format(Line."Line No.") + ': ' + Format(Line.F0) + ' ' + Format(Line.F1) + ' ' + Format(Line.F2) + ' ' + Format(Line.F3) + ' ' + Format(Line.F4) + '; ';
            until Line.Next() = 0;
        if Result = '' then
            exit('no lines');
        exit(Result);
    end;

    local procedure SetPartField(var Doc: TestPage "PAG XRec Part Doc"; FieldIndex: Integer; NewValue: Integer)
    begin
        case FieldIndex of
            0:
                Doc.Lines.F0.SetValue(NewValue);
            1:
                Doc.Lines.F1.SetValue(NewValue);
            2:
                Doc.Lines.F2.SetValue(NewValue);
            3:
                Doc.Lines.F3.SetValue(NewValue);
            4:
                Doc.Lines.F4.SetValue(NewValue);
        end;
    end;

    local procedure StoredLine(FieldIndex: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "PAG XRec Part Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.First();
        Log.Take();
        SetPartField(Doc, FieldIndex, 5);
        Observer.Observe('stored line 10000, set 1 -> 5', Log.Take());
        Observer.Observe('lines after the first set', Stored('H1'));
        SetPartField(Doc, FieldIndex, 6);
        Observer.Observe('stored line 10000, set 5 -> 6', Log.Take());
        Observer.Observe('lines after the second set', Stored('H1'));
        Observer.Finish();
    end;

    local procedure NewLineFieldFirst(FieldIndex: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "PAG XRec Part Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Doc.Lines.New();
        Log.Take();
        SetPartField(Doc, FieldIndex, 5);
        Observer.Observe('new line, set 0 -> 5', Log.Take());
        Observer.Observe('lines after the first set', Stored('H1'));
        SetPartField(Doc, FieldIndex, 6);
        Observer.Observe('new line, set 5 -> 6', Log.Take());
        Observer.Observe('lines after the second set', Stored('H1'));
        Observer.Finish();
    end;

    // The reporter's order: one field of the new line runs CurrPage.Update() (as "No." does on a purchase invoice line), then another field is set.
    local procedure NewLineAfterUpdateField(FieldIndex: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "PAG XRec Part Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H1');
        Doc.Lines.Last();
        Doc.Lines.New();
        Doc.Lines.F1.SetValue(7);
        Observer.Observe('new line, F1 set first', Log.Take());
        Observer.Observe('lines after F1', Stored('H1'));
        SetPartField(Doc, FieldIndex, 5);
        Observer.Observe('same line, set 0 -> 5', Log.Take());
        Observer.Observe('lines after the set', Stored('H1'));
        Observer.Finish();
    end;

    local procedure FirstLineOfEmptyDocument(FirstIndex: Integer; SecondIndex: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "PAG XRec Part Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.GoToKey('H2');
        Log.Take();
        SetPartField(Doc, FirstIndex, 7);
        Observer.Observe('first line, first field set 0 -> 7', Log.Take());
        Observer.Observe('lines after the first field', Stored('H2'));
        SetPartField(Doc, SecondIndex, 5);
        Observer.Observe('first line, second field set 0 -> 5', Log.Take());
        Observer.Observe('lines after the second field', Stored('H2'));
        Observer.Finish();
    end;

    [Test]
    procedure Part_StoredLine_F0()
    begin
        StoredLine(0);
    end;

    [Test]
    procedure Part_StoredLine_F1()
    begin
        StoredLine(1);
    end;

    [Test]
    procedure Part_StoredLine_F2()
    begin
        StoredLine(2);
    end;

    [Test]
    procedure Part_StoredLine_F3()
    begin
        StoredLine(3);
    end;

    [Test]
    procedure Part_StoredLine_F4()
    begin
        StoredLine(4);
    end;

    [Test]
    procedure Part_NewLine_FieldFirst_F0()
    begin
        NewLineFieldFirst(0);
    end;

    [Test]
    procedure Part_NewLine_FieldFirst_F1()
    begin
        NewLineFieldFirst(1);
    end;

    [Test]
    procedure Part_NewLine_FieldFirst_F2()
    begin
        NewLineFieldFirst(2);
    end;

    [Test]
    procedure Part_NewLine_FieldFirst_F3()
    begin
        NewLineFieldFirst(3);
    end;

    [Test]
    procedure Part_NewLine_FieldFirst_F4()
    begin
        NewLineFieldFirst(4);
    end;

    [Test]
    procedure Part_NewLine_AfterF1Update_F0()
    begin
        NewLineAfterUpdateField(0);
    end;

    [Test]
    procedure Part_NewLine_AfterF1Update_F2()
    begin
        NewLineAfterUpdateField(2);
    end;

    [Test]
    procedure Part_NewLine_AfterF1Update_F3()
    begin
        NewLineAfterUpdateField(3);
    end;

    [Test]
    procedure Part_NewLine_AfterF1Update_F4()
    begin
        NewLineAfterUpdateField(4);
    end;

    [Test]
    procedure Part_EmptyDocument_F1_Then_F2()
    begin
        FirstLineOfEmptyDocument(1, 2);
    end;

    [Test]
    procedure Part_EmptyDocument_F2_Then_F1()
    begin
        FirstLineOfEmptyDocument(2, 1);
    end;

    [Test]
    procedure Part_EmptyDocument_F0_Then_F2()
    begin
        FirstLineOfEmptyDocument(0, 2);
    end;

    [Test]
    procedure Part_EmptyDocument_F3_Then_F2()
    begin
        FirstLineOfEmptyDocument(3, 2);
    end;

    [Test]
    procedure Part_EmptyDocument_F4_Then_F2()
    begin
        FirstLineOfEmptyDocument(4, 2);
    end;

    // The part page opened alone as its own TestPage (no document page, no SubPageLink).

    [Test]
    procedure PartAlone_StoredLine_F1_And_F2()
    var
        Observer: Codeunit "Probe Observer";
        Lines: TestPage "PAG XRec Part Lines";
    begin
        Seed();
        Lines.OpenEdit();
        Lines.First();
        Log.Take();
        Lines.F1.SetValue(5);
        Observer.Observe('line 10000, F1 set 1 -> 5', Log.Take());
        Lines.F2.SetValue(5);
        Observer.Observe('line 10000, F2 set 1 -> 5', Log.Take());
        Lines.F2.SetValue(6);
        Observer.Observe('line 10000, F2 set 5 -> 6', Log.Take());
        Observer.Observe('lines', Stored('H1'));
        Observer.Expect('line 10000, F1 set 1 -> 5', 'table F1 rec=5 xrec=1 xline=10000; before F1 rec=5 xrec=1 xline=10000; base F1 rec=5 xrec=1 xline=10000; after F1 rec=5 xrec=1 xline=10000 line=10000; ');
        Observer.Expect('line 10000, F2 set 1 -> 5', 'table F2 rec=5 xrec=1 xline=10000; before F2 rec=5 xrec=1 xline=10000; base F2 rec=5 xrec=1 xline=10000; after F2 rec=5 xrec=1 xline=10000 line=10000; ');
        Observer.Expect('line 10000, F2 set 5 -> 6', 'table F2 rec=6 xrec=5 xline=10000; before F2 rec=6 xrec=5 xline=10000; base F2 rec=6 xrec=5 xline=10000; after F2 rec=6 xrec=5 xline=10000 line=10000; ');
        Observer.Expect('lines', '10000: 1 5 6 1 1; 20000: 2 2 2 2 2; ');
        Observer.Verify();
    end;
}
