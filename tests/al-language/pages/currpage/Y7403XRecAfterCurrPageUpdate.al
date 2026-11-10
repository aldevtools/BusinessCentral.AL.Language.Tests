// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// local object: the field triggers of the base page (which call CurrPage.Update in a different form per field) are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own table 99920, log codeunit 99921, pages 99922 and 99923, page extensions 99924 and 99925, test codeunit 99926
// Probe (al-runner issue 7403): what xRec holds in a page extension's OnAfterValidate of a field whose base OnValidate trigger calls CurrPage.Update()
//   (none, Update(), Update(true), Update(false), SaveRecord(), SaveRecord then Update(false)). Also what xRec holds inside the base OnValidate before the call.
//   One list page and one card page, same fields; the field is set with TestPage.SetValue from 1 to 5.
// BC versions: 27, 28, 29

table 99920 "LT K12 Upd Row"
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

codeunit 99921 "LT K12 Upd Log"
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
page 99922 "LT K12 Upd List"
{
    PageType = List;
    SourceTable = "LT K12 Upd Row";
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
                        Log.Add('base F0 (no call) rec=' + Format(Rec.F0) + ' xrec=' + Format(xRec.F0));
                    end;
                }
                field(F1; Rec.F1)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F1 (CurrPage.Update()) rec=' + Format(Rec.F1) + ' xrec=' + Format(xRec.F1));
                        CurrPage.Update();
                    end;
                }
                field(F2; Rec.F2)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F2 (CurrPage.Update(true)) rec=' + Format(Rec.F2) + ' xrec=' + Format(xRec.F2));
                        CurrPage.Update(true);
                    end;
                }
                field(F3; Rec.F3)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F3 (CurrPage.Update(false)) rec=' + Format(Rec.F3) + ' xrec=' + Format(xRec.F3));
                        CurrPage.Update(false);
                    end;
                }
                field(F4; Rec.F4)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F4 (CurrPage.SaveRecord()) rec=' + Format(Rec.F4) + ' xrec=' + Format(xRec.F4));
                        CurrPage.SaveRecord();
                    end;
                }
                field(F5; Rec.F5)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F5 (SaveRecord then Update(false)) rec=' + Format(Rec.F5) + ' xrec=' + Format(xRec.F5));
                        CurrPage.SaveRecord(); CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "LT K12 Upd Log";
}

page 99923 "LT K12 Upd Card"
{
    PageType = Card;
    SourceTable = "LT K12 Upd Row";
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
                        Log.Add('base F0 (no call) rec=' + Format(Rec.F0) + ' xrec=' + Format(xRec.F0));
                    end;
                }
                field(F1; Rec.F1)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F1 (CurrPage.Update()) rec=' + Format(Rec.F1) + ' xrec=' + Format(xRec.F1));
                        CurrPage.Update();
                    end;
                }
                field(F2; Rec.F2)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F2 (CurrPage.Update(true)) rec=' + Format(Rec.F2) + ' xrec=' + Format(xRec.F2));
                        CurrPage.Update(true);
                    end;
                }
                field(F3; Rec.F3)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F3 (CurrPage.Update(false)) rec=' + Format(Rec.F3) + ' xrec=' + Format(xRec.F3));
                        CurrPage.Update(false);
                    end;
                }
                field(F4; Rec.F4)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F4 (CurrPage.SaveRecord()) rec=' + Format(Rec.F4) + ' xrec=' + Format(xRec.F4));
                        CurrPage.SaveRecord();
                    end;
                }
                field(F5; Rec.F5)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('base F5 (SaveRecord then Update(false)) rec=' + Format(Rec.F5) + ' xrec=' + Format(xRec.F5));
                        CurrPage.SaveRecord(); CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    var
        Log: Codeunit "LT K12 Upd Log";
}

pageextension 99924 "LT K12 Upd List Ext" extends "LT K12 Upd List"
{
    layout
    {
        modify(F0)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F0 rec=' + Format(Rec.F0) + ' xrec=' + Format(xRec.F0) + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F1)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F1 rec=' + Format(Rec.F1) + ' xrec=' + Format(xRec.F1) + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F2)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F2 rec=' + Format(Rec.F2) + ' xrec=' + Format(xRec.F2) + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F3)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F3 rec=' + Format(Rec.F3) + ' xrec=' + Format(xRec.F3) + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F4)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F4 rec=' + Format(Rec.F4) + ' xrec=' + Format(xRec.F4) + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F5)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F5 rec=' + Format(Rec.F5) + ' xrec=' + Format(xRec.F5) + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
    }

    var
        Log: Codeunit "LT K12 Upd Log";
}

pageextension 99925 "LT K12 Upd Card Ext" extends "LT K12 Upd Card"
{
    layout
    {
        modify(F0)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F0 rec=' + Format(Rec.F0) + ' xrec=' + Format(xRec.F0) + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F1)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F1 rec=' + Format(Rec.F1) + ' xrec=' + Format(xRec.F1) + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F2)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F2 rec=' + Format(Rec.F2) + ' xrec=' + Format(xRec.F2) + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F3)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F3 rec=' + Format(Rec.F3) + ' xrec=' + Format(xRec.F3) + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F4)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F4 rec=' + Format(Rec.F4) + ' xrec=' + Format(xRec.F4) + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
        modify(F5)
        {
            trigger OnAfterValidate()
            begin
                Log.Add('ext F5 rec=' + Format(Rec.F5) + ' xrec=' + Format(xRec.F5) + ' equal=' + Format(Format(Rec) = Format(xRec)));
            end;
        }
    }

    var
        Log: Codeunit "LT K12 Upd Log";
}

codeunit 99926 "LT K12 Upd XRec Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT K12 Upd Log";

    local procedure Seed()
    var
        Row: Record "LT K12 Upd Row";
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

    [Test]
    procedure Y7403_List_F0()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.F0.SetValue(5);
        Observer.Observe('List no call', Log.Take());
        Observer.Expect('List no call', 'base F0 (no call) rec=5 xrec=1; ext F0 rec=5 xrec=1 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_List_F1()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.F1.SetValue(5);
        Observer.Observe('List CurrPage.Update()', Log.Take());
        Observer.Expect('List CurrPage.Update()', 'base F1 (CurrPage.Update()) rec=5 xrec=1; ext F1 rec=5 xrec=1 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_List_F2()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.F2.SetValue(5);
        Observer.Observe('List CurrPage.Update(true)', Log.Take());
        Observer.Expect('List CurrPage.Update(true)', 'base F2 (CurrPage.Update(true)) rec=5 xrec=1; ext F2 rec=5 xrec=1 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_List_F3()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.F3.SetValue(5);
        Observer.Observe('List CurrPage.Update(false)', Log.Take());
        Observer.Expect('List CurrPage.Update(false)', 'base F3 (CurrPage.Update(false)) rec=5 xrec=1; ext F3 rec=5 xrec=1 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_List_F4()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.F4.SetValue(5);
        Observer.Observe('List CurrPage.SaveRecord()', Log.Take());
        Observer.Expect('List CurrPage.SaveRecord()', 'base F4 (CurrPage.SaveRecord()) rec=5 xrec=1; ext F4 rec=5 xrec=1 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_List_F5()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.F5.SetValue(5);
        Observer.Observe('List SaveRecord then Update(false)', Log.Take());
        Observer.Expect('List SaveRecord then Update(false)', 'base F5 (SaveRecord then Update(false)) rec=5 xrec=1; ext F5 rec=5 xrec=1 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_Card_F0()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd Card";
    begin
        Seed();
        P.OpenEdit();
        P.F0.SetValue(5);
        Observer.Observe('Card no call', Log.Take());
        Observer.Expect('Card no call', 'base F0 (no call) rec=5 xrec=1; ext F0 rec=5 xrec=1 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_Card_F1()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd Card";
    begin
        Seed();
        P.OpenEdit();
        P.F1.SetValue(5);
        Observer.Observe('Card CurrPage.Update()', Log.Take());
        Observer.Expect('Card CurrPage.Update()', 'base F1 (CurrPage.Update()) rec=5 xrec=1; ext F1 rec=5 xrec=1 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_Card_F2()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd Card";
    begin
        Seed();
        P.OpenEdit();
        P.F2.SetValue(5);
        Observer.Observe('Card CurrPage.Update(true)', Log.Take());
        Observer.Expect('Card CurrPage.Update(true)', 'base F2 (CurrPage.Update(true)) rec=5 xrec=1; ext F2 rec=5 xrec=1 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_Card_F3()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd Card";
    begin
        Seed();
        P.OpenEdit();
        P.F3.SetValue(5);
        Observer.Observe('Card CurrPage.Update(false)', Log.Take());
        Observer.Expect('Card CurrPage.Update(false)', 'base F3 (CurrPage.Update(false)) rec=5 xrec=1; ext F3 rec=5 xrec=1 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_Card_F4()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd Card";
    begin
        Seed();
        P.OpenEdit();
        P.F4.SetValue(5);
        Observer.Observe('Card CurrPage.SaveRecord()', Log.Take());
        Observer.Expect('Card CurrPage.SaveRecord()', 'base F4 (CurrPage.SaveRecord()) rec=5 xrec=1; ext F4 rec=5 xrec=1 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_Card_F5()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd Card";
    begin
        Seed();
        P.OpenEdit();
        P.F5.SetValue(5);
        Observer.Observe('Card SaveRecord then Update(false)', Log.Take());
        Observer.Expect('Card SaveRecord then Update(false)', 'base F5 (SaveRecord then Update(false)) rec=5 xrec=1; ext F5 rec=5 xrec=1 equal=No; ');
        Observer.Verify();
    end;

    // Matrix cells beyond the first set: a second SetValue (5 -> 6) and a SetValue to the value the field already holds, on the list page.

    [Test]
    procedure Y7403_List_F0_SetTwice_And_SameValue()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.F0.SetValue(5);
        Observer.Observe('first set 1 -> 5', Log.Take());
        P.F0.SetValue(6);
        Observer.Observe('second set 5 -> 6', Log.Take());
        P.F0.SetValue(6);
        Observer.Observe('set to the held value 6', Log.Take());
        P.F0.SetValue(1);
        Observer.Observe('set back to 1', Log.Take());
        Observer.Expect('first set 1 -> 5', 'base F0 (no call) rec=5 xrec=1; ext F0 rec=5 xrec=1 equal=No; ');
        Observer.Expect('second set 5 -> 6', 'base F0 (no call) rec=6 xrec=5; ext F0 rec=6 xrec=5 equal=No; ');
        Observer.Expect('set to the held value 6', 'base F0 (no call) rec=6 xrec=1; ext F0 rec=6 xrec=1 equal=No; ');
        Observer.Expect('set back to 1', 'base F0 (no call) rec=1 xrec=6; ext F0 rec=1 xrec=6 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_List_F1_SetTwice_And_SameValue()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.F1.SetValue(5);
        Observer.Observe('first set 1 -> 5', Log.Take());
        P.F1.SetValue(6);
        Observer.Observe('second set 5 -> 6', Log.Take());
        P.F1.SetValue(6);
        Observer.Observe('set to the held value 6', Log.Take());
        P.F1.SetValue(1);
        Observer.Observe('set back to 1', Log.Take());
        Observer.Expect('first set 1 -> 5', 'base F1 (CurrPage.Update()) rec=5 xrec=1; ext F1 rec=5 xrec=1 equal=No; ');
        Observer.Expect('second set 5 -> 6', 'base F1 (CurrPage.Update()) rec=6 xrec=5; ext F1 rec=6 xrec=5 equal=No; ');
        Observer.Expect('set to the held value 6', 'base F1 (CurrPage.Update()) rec=6 xrec=6; ext F1 rec=6 xrec=6 equal=Yes; ');
        Observer.Expect('set back to 1', 'base F1 (CurrPage.Update()) rec=1 xrec=6; ext F1 rec=1 xrec=6 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_List_F2_SetTwice_And_SameValue()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.F2.SetValue(5);
        Observer.Observe('first set 1 -> 5', Log.Take());
        P.F2.SetValue(6);
        Observer.Observe('second set 5 -> 6', Log.Take());
        P.F2.SetValue(6);
        Observer.Observe('set to the held value 6', Log.Take());
        P.F2.SetValue(1);
        Observer.Observe('set back to 1', Log.Take());
        Observer.Expect('first set 1 -> 5', 'base F2 (CurrPage.Update(true)) rec=5 xrec=1; ext F2 rec=5 xrec=1 equal=No; ');
        Observer.Expect('second set 5 -> 6', 'base F2 (CurrPage.Update(true)) rec=6 xrec=5; ext F2 rec=6 xrec=5 equal=No; ');
        Observer.Expect('set to the held value 6', 'base F2 (CurrPage.Update(true)) rec=6 xrec=6; ext F2 rec=6 xrec=6 equal=Yes; ');
        Observer.Expect('set back to 1', 'base F2 (CurrPage.Update(true)) rec=1 xrec=6; ext F2 rec=1 xrec=6 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_List_F3_SetTwice_And_SameValue()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.F3.SetValue(5);
        Observer.Observe('first set 1 -> 5', Log.Take());
        P.F3.SetValue(6);
        Observer.Observe('second set 5 -> 6', Log.Take());
        P.F3.SetValue(6);
        Observer.Observe('set to the held value 6', Log.Take());
        P.F3.SetValue(1);
        Observer.Observe('set back to 1', Log.Take());
        Observer.Expect('first set 1 -> 5', 'base F3 (CurrPage.Update(false)) rec=5 xrec=1; ext F3 rec=5 xrec=1 equal=No; ');
        Observer.Expect('second set 5 -> 6', 'base F3 (CurrPage.Update(false)) rec=6 xrec=1; ext F3 rec=6 xrec=1 equal=No; ');
        Observer.Expect('set to the held value 6', 'base F3 (CurrPage.Update(false)) rec=6 xrec=1; ext F3 rec=6 xrec=1 equal=No; ');
        Observer.Expect('set back to 1', 'base F3 (CurrPage.Update(false)) rec=1 xrec=1; ext F3 rec=1 xrec=1 equal=Yes; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_List_F4_SetTwice_And_SameValue()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.F4.SetValue(5);
        Observer.Observe('first set 1 -> 5', Log.Take());
        P.F4.SetValue(6);
        Observer.Observe('second set 5 -> 6', Log.Take());
        P.F4.SetValue(6);
        Observer.Observe('set to the held value 6', Log.Take());
        P.F4.SetValue(1);
        Observer.Observe('set back to 1', Log.Take());
        Observer.Expect('first set 1 -> 5', 'base F4 (CurrPage.SaveRecord()) rec=5 xrec=1; ext F4 rec=5 xrec=1 equal=No; ');
        Observer.Expect('second set 5 -> 6', 'base F4 (CurrPage.SaveRecord()) rec=6 xrec=5; ext F4 rec=6 xrec=5 equal=No; ');
        Observer.Expect('set to the held value 6', 'base F4 (CurrPage.SaveRecord()) rec=6 xrec=6; ext F4 rec=6 xrec=6 equal=Yes; ');
        Observer.Expect('set back to 1', 'base F4 (CurrPage.SaveRecord()) rec=1 xrec=6; ext F4 rec=1 xrec=6 equal=No; ');
        Observer.Verify();
    end;

    [Test]
    procedure Y7403_List_F5_SetTwice_And_SameValue()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Upd List";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('R1');
        P.F5.SetValue(5);
        Observer.Observe('first set 1 -> 5', Log.Take());
        P.F5.SetValue(6);
        Observer.Observe('second set 5 -> 6', Log.Take());
        P.F5.SetValue(6);
        Observer.Observe('set to the held value 6', Log.Take());
        P.F5.SetValue(1);
        Observer.Observe('set back to 1', Log.Take());
        Observer.Expect('first set 1 -> 5', 'base F5 (SaveRecord then Update(false)) rec=5 xrec=1; ext F5 rec=5 xrec=1 equal=No; ');
        Observer.Expect('second set 5 -> 6', 'base F5 (SaveRecord then Update(false)) rec=6 xrec=5; ext F5 rec=6 xrec=5 equal=No; ');
        Observer.Expect('set to the held value 6', 'base F5 (SaveRecord then Update(false)) rec=6 xrec=6; ext F5 rec=6 xrec=6 equal=Yes; ');
        Observer.Expect('set back to 1', 'base F5 (SaveRecord then Update(false)) rec=1 xrec=6; ext F5 rec=1 xrec=6 equal=No; ');
        Observer.Verify();
    end;
}
