// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// local object: the page's OnModifyRecord and the table field's OnValidate (which log xRec) are what is under test
// Fixtures used: Probe Observer (codeunit 69160); own table 99980, log codeunit 99981, page 99982, test codeunit 99983
// Probe (al-runner issue 7428): a page-variable control's OnValidate writes Rec.Formula and then calls CurrPage.Update(true), Update(false), Update(),
//   SaveRecord() or nothing. Readings: whether the page's OnModifyRecord runs, what Rec and xRec hold there, whether the table field's OnValidate
//   (called by Rec.Validate in OnModifyRecord) sees xRec.Formula different from Formula, and what the stored row holds. A table-bound control is the control case.
// BC versions: 27, 28, 29

table 99980 "LT K12 Formula"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Formula; Text[250])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT K12 Formula Log";
            begin
                Log.Add('table OnValidate Formula=' + Formula + ' xrec=' + xRec.Formula);
            end;
        }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 99981 "LT K12 Formula Log"
{
    SingleInstance = true;

    var
        Text1: Text;

    procedure Add(Line: Text)
    begin
        Text1 += Line + '; ';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Text1;
        Text1 := '';
        exit(Result);
    end;
}

page 99982 "LT K12 Formulas"
{
    PageType = ListPlus;
    SourceTable = "LT K12 Formula";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Formula; Rec.Formula) { ApplicationArea = All; }
                field(T0Text; T0Text)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.Formula := CopyStr(T0Text, 1, MaxStrLen(Rec.Formula));
                        
                    end;
                }
                field(T1Text; T1Text)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.Formula := CopyStr(T1Text, 1, MaxStrLen(Rec.Formula));
                        CurrPage.Update(true);
                    end;
                }
                field(T2Text; T2Text)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.Formula := CopyStr(T2Text, 1, MaxStrLen(Rec.Formula));
                        CurrPage.Update(false);
                    end;
                }
                field(T3Text; T3Text)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.Formula := CopyStr(T3Text, 1, MaxStrLen(Rec.Formula));
                        CurrPage.Update();
                    end;
                }
                field(T4Text; T4Text)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.Formula := CopyStr(T4Text, 1, MaxStrLen(Rec.Formula));
                        CurrPage.SaveRecord();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AssignUpdateTrue) { ApplicationArea = All; trigger OnAction() begin Rec.Formula := 'ACT'; CurrPage.Update(true); end; }
            action(AssignUpdateFalse) { ApplicationArea = All; trigger OnAction() begin Rec.Formula := 'ACT'; CurrPage.Update(false); end; }
            action(AssignSave) { ApplicationArea = All; trigger OnAction() begin Rec.Formula := 'ACT'; CurrPage.SaveRecord(); end; }
            action(AssignModify) { ApplicationArea = All; trigger OnAction() begin Rec.Formula := 'ACT'; Rec.Modify(true); end; }
            action(ValidateUpdateTrue) { ApplicationArea = All; trigger OnAction() begin Rec.Validate(Formula, 'ACT'); CurrPage.Update(true); end; }
            action(AssignOnly) { ApplicationArea = All; trigger OnAction() begin Rec.Formula := 'ACT'; end; }
        }
    }

    trigger OnAfterGetRecord()
    begin
        T0Text := Rec.Formula;
        T1Text := Rec.Formula;
        T2Text := Rec.Formula;
        T3Text := Rec.Formula;
        T4Text := Rec.Formula;
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT K12 Formula Log";
        Stored: Record "LT K12 Formula";
    begin
        Stored.Get(Rec."Code");
        Log.Add('page OnModifyRecord rec=' + Rec.Formula + ' xrec=' + xRec.Formula + ' stored=' + Stored.Formula);
        if Rec.Formula <> xRec.Formula then
            Rec.Validate(Formula);
    end;

    var
        T0Text: Text;
        T1Text: Text;
        T2Text: Text;
        T3Text: Text;
        T4Text: Text;
}

codeunit 99983 "LT K12 Formula Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Log: Codeunit "LT K12 Formula Log";

    local procedure Seed()
    var
        Row: Record "LT K12 Formula";
    begin
        Row.DeleteAll();
        Row."Code" := 'A';
        Row.Formula := '1+1';
        Row.Insert();
        Row."Code" := 'B';
        Row.Formula := '2+2';
        Row.Insert();
        Log.Take();
    end;

    [Test]
    procedure Y7428_T0()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
        Row: Record "LT K12 Formula";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.T0Text.SetValue('2+4+1');
        Observer.Observe('no call: log after set', Log.Take());
        P.Last();
        Observer.Observe('no call: log after Last', Log.Take());
        Row.Get('A');
        Observer.Observe('no call: stored A', Row.Formula);
        Observer.Finish();
    end;

    [Test]
    procedure Y7428_T1()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
        Row: Record "LT K12 Formula";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.T1Text.SetValue('2+4+1');
        Observer.Observe('CurrPage.Update(true): log after set', Log.Take());
        P.Last();
        Observer.Observe('CurrPage.Update(true): log after Last', Log.Take());
        Row.Get('A');
        Observer.Observe('CurrPage.Update(true): stored A', Row.Formula);
        Observer.Finish();
    end;

    [Test]
    procedure Y7428_T2()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
        Row: Record "LT K12 Formula";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.T2Text.SetValue('2+4+1');
        Observer.Observe('CurrPage.Update(false): log after set', Log.Take());
        P.Last();
        Observer.Observe('CurrPage.Update(false): log after Last', Log.Take());
        Row.Get('A');
        Observer.Observe('CurrPage.Update(false): stored A', Row.Formula);
        Observer.Finish();
    end;

    [Test]
    procedure Y7428_T3()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
        Row: Record "LT K12 Formula";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.T3Text.SetValue('2+4+1');
        Observer.Observe('CurrPage.Update(): log after set', Log.Take());
        P.Last();
        Observer.Observe('CurrPage.Update(): log after Last', Log.Take());
        Row.Get('A');
        Observer.Observe('CurrPage.Update(): stored A', Row.Formula);
        Observer.Finish();
    end;

    [Test]
    procedure Y7428_T4()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
        Row: Record "LT K12 Formula";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.T4Text.SetValue('2+4+1');
        Observer.Observe('CurrPage.SaveRecord(): log after set', Log.Take());
        P.Last();
        Observer.Observe('CurrPage.SaveRecord(): log after Last', Log.Take());
        Row.Get('A');
        Observer.Observe('CurrPage.SaveRecord(): stored A', Row.Formula);
        Observer.Finish();
    end;

    [Test]
    procedure Y7428_Direct()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
        Row: Record "LT K12 Formula";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.Formula.SetValue('2+4+1');
        Observer.Observe('table-bound control, no CurrPage call: log after set', Log.Take());
        P.Last();
        Observer.Observe('table-bound control, no CurrPage call: log after Last', Log.Take());
        Row.Get('A');
        Observer.Observe('table-bound control, no CurrPage call: stored A', Row.Formula);
        Observer.Finish();
    end;

    // Matrix: the change made by an action instead of a typed value (xRec in OnModifyRecord and in the table field's OnValidate).

    [Test]
    procedure Y7428_Action_AssignUpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
        Row: Record "LT K12 Formula";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.AssignUpdateTrue.Invoke();
        Observer.Observe('AssignUpdateTrue: log after action', Log.Take());
        P.Last();
        Observer.Observe('AssignUpdateTrue: log after Last', Log.Take());
        Row.Get('A');
        Observer.Observe('AssignUpdateTrue: stored A', Row.Formula);
        Observer.Finish();
    end;

    [Test]
    procedure Y7428_Action_AssignUpdateFalse()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
        Row: Record "LT K12 Formula";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.AssignUpdateFalse.Invoke();
        Observer.Observe('AssignUpdateFalse: log after action', Log.Take());
        P.Last();
        Observer.Observe('AssignUpdateFalse: log after Last', Log.Take());
        Row.Get('A');
        Observer.Observe('AssignUpdateFalse: stored A', Row.Formula);
        Observer.Finish();
    end;

    [Test]
    procedure Y7428_Action_AssignSave()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
        Row: Record "LT K12 Formula";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.AssignSave.Invoke();
        Observer.Observe('AssignSave: log after action', Log.Take());
        P.Last();
        Observer.Observe('AssignSave: log after Last', Log.Take());
        Row.Get('A');
        Observer.Observe('AssignSave: stored A', Row.Formula);
        Observer.Finish();
    end;

    [Test]
    procedure Y7428_Action_AssignModify()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
        Row: Record "LT K12 Formula";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.AssignModify.Invoke();
        Observer.Observe('AssignModify: log after action', Log.Take());
        P.Last();
        Observer.Observe('AssignModify: log after Last', Log.Take());
        Row.Get('A');
        Observer.Observe('AssignModify: stored A', Row.Formula);
        Observer.Finish();
    end;

    [Test]
    procedure Y7428_Action_ValidateUpdateTrue()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
        Row: Record "LT K12 Formula";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.ValidateUpdateTrue.Invoke();
        Observer.Observe('ValidateUpdateTrue: log after action', Log.Take());
        P.Last();
        Observer.Observe('ValidateUpdateTrue: log after Last', Log.Take());
        Row.Get('A');
        Observer.Observe('ValidateUpdateTrue: stored A', Row.Formula);
        Observer.Finish();
    end;

    [Test]
    procedure Y7428_Action_AssignOnly()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
        Row: Record "LT K12 Formula";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.AssignOnly.Invoke();
        Observer.Observe('AssignOnly: log after action', Log.Take());
        P.Last();
        Observer.Observe('AssignOnly: log after Last', Log.Take());
        Row.Get('A');
        Observer.Observe('AssignOnly: stored A', Row.Formula);
        Observer.Finish();
    end;

    [Test]
    procedure Y7428_TypedTwice_And_SameValue()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT K12 Formulas";
    begin
        Seed();
        P.OpenEdit();
        P.First();
        P.T1Text.SetValue('2+4+1');
        Observer.Observe('Update(true) field, first set', Log.Take());
        P.T1Text.SetValue('9');
        Observer.Observe('Update(true) field, second set', Log.Take());
        P.T1Text.SetValue('9');
        Observer.Observe('Update(true) field, same value', Log.Take());
        P.Formula.SetValue('7');
        Observer.Observe('table-bound field after that', Log.Take());
        Observer.Finish();
    end;
}
