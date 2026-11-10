// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-delayedinsert-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own tables 62630 62631, log codeunit 62632, part pages 62633..62637, host pages
//   62638..62642, test codeunit 62643
// Probe: observe-only. Area: SetValue on a control over a page variable on a new row of a ListPart, crossed with DelayedInsert,
//   AutoSplitKey and PopulateAllFields. QiRowPageVar.al pins what such a control shows on stored rows and on a new row of a plain
//   part; TpmDelayedInsertAutoSplitKey.al pins when a list inserts its new row for record fields. Not pinned (al-runner issue 7481):
//   whether the new row is inserted before the OnValidate of the variable control runs, with which line number, and what a
//   CurrPage.Update() in that OnValidate does then; the same when the variable control is typed first, when its OnValidate does not
//   update, when it has no OnValidate, and on a stored row whose record field was set to the value it already holds.
// Controls of the part: Type and Code (record fields), ActUpd (variable; OnValidate validates it into "Actual Value" and runs
//   CurrPage.Update()), ActKeep (variable; OnValidate validates only), PlainVar (variable, no trigger), Stored ("Actual Value").
// Observed per step: the stored lines (Line No.:Type:Code:Actual Value) and the page and table triggers that ran (log), then the
//   values the row shows.
// local object: the part properties and the triggers of the variable controls are what the test checks
// BC versions: 27, 28, 29

table 62630 "PG NV Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 62631 "PG NV Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc No."; Code[10]) { DataClassification = SystemMetadata; }
        field(2; "Line No."; Integer) { DataClassification = SystemMetadata; }
        field(3; Type; Option)
        {
            DataClassification = SystemMetadata;
            OptionMembers = A,B;
        }
        field(4; Code; Code[20]) { DataClassification = SystemMetadata; }
        field(5; "Actual Value"; Text[50])
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Log: Codeunit "PG NV Log";
            begin
                Log.Add('T-V ' + Format("Line No.") + ' ' + "Actual Value");
            end;
        }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('T-I ' + Format("Line No.") + ' ' + "Actual Value");
    end;

    trigger OnModify()
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('T-M ' + Format("Line No.") + ' ' + "Actual Value");
    end;
}

codeunit 62632 "PG NV Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Line: Text)
    begin
        if Entries <> '' then
            Entries += ' | ';
        Entries += Line;
    end;

    procedure Take() Result: Text
    begin
        Result := '[' + Entries + ']';
        Entries := '';
    end;
}

page 62633 "PG NV Lines Plain"
{
    PageType = ListPart;
    SourceTable = "PG NV Line";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type) { ApplicationArea = All; }
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(ActUpd; ActValueTxt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG NV Log";
                    begin
                        Log.Add('V-UPD ' + Format(Rec."Line No."));
                        Rec.Validate("Actual Value", ActValueTxt);
                        CurrPage.Update();
                    end;
                }
                field(ActKeep; KeepTxt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG NV Log";
                    begin
                        Log.Add('V-KEEP ' + Format(Rec."Line No."));
                        Rec.Validate("Actual Value", KeepTxt);
                    end;
                }
                field(PlainVar; PlainTxt) { ApplicationArea = All; }
                field(Stored; Rec."Actual Value")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    var
        ActValueTxt: Text;
        KeepTxt: Text;
        PlainTxt: Text;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG NV Log";
    begin
        ActValueTxt := Rec."Actual Value";
        KeepTxt := Rec."Actual Value";
        Log.Add('AGR ' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('NEW ' + Format(Rec."Line No."));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('INS ' + Format(Rec."Line No.") + ' ' + Rec."Actual Value");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('MOD ' + Format(Rec."Line No.") + ' ' + Rec."Actual Value");
        exit(true);
    end;
}

page 62638 "PG NV Doc Plain"
{
    PageType = Document;
    SourceTable = "PG NV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "PG NV Lines Plain")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 62634 "PG NV Lines Delayed"
{
    PageType = ListPart;
    SourceTable = "PG NV Line";
    ApplicationArea = All;
    UsageCategory = None;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type) { ApplicationArea = All; }
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(ActUpd; ActValueTxt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG NV Log";
                    begin
                        Log.Add('V-UPD ' + Format(Rec."Line No."));
                        Rec.Validate("Actual Value", ActValueTxt);
                        CurrPage.Update();
                    end;
                }
                field(ActKeep; KeepTxt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG NV Log";
                    begin
                        Log.Add('V-KEEP ' + Format(Rec."Line No."));
                        Rec.Validate("Actual Value", KeepTxt);
                    end;
                }
                field(PlainVar; PlainTxt) { ApplicationArea = All; }
                field(Stored; Rec."Actual Value")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    var
        ActValueTxt: Text;
        KeepTxt: Text;
        PlainTxt: Text;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG NV Log";
    begin
        ActValueTxt := Rec."Actual Value";
        KeepTxt := Rec."Actual Value";
        Log.Add('AGR ' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('NEW ' + Format(Rec."Line No."));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('INS ' + Format(Rec."Line No.") + ' ' + Rec."Actual Value");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('MOD ' + Format(Rec."Line No.") + ' ' + Rec."Actual Value");
        exit(true);
    end;
}

page 62639 "PG NV Doc Delayed"
{
    PageType = Document;
    SourceTable = "PG NV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "PG NV Lines Delayed")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 62635 "PG NV Lines Split"
{
    PageType = ListPart;
    SourceTable = "PG NV Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type) { ApplicationArea = All; }
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(ActUpd; ActValueTxt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG NV Log";
                    begin
                        Log.Add('V-UPD ' + Format(Rec."Line No."));
                        Rec.Validate("Actual Value", ActValueTxt);
                        CurrPage.Update();
                    end;
                }
                field(ActKeep; KeepTxt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG NV Log";
                    begin
                        Log.Add('V-KEEP ' + Format(Rec."Line No."));
                        Rec.Validate("Actual Value", KeepTxt);
                    end;
                }
                field(PlainVar; PlainTxt) { ApplicationArea = All; }
                field(Stored; Rec."Actual Value")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    var
        ActValueTxt: Text;
        KeepTxt: Text;
        PlainTxt: Text;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG NV Log";
    begin
        ActValueTxt := Rec."Actual Value";
        KeepTxt := Rec."Actual Value";
        Log.Add('AGR ' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('NEW ' + Format(Rec."Line No."));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('INS ' + Format(Rec."Line No.") + ' ' + Rec."Actual Value");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('MOD ' + Format(Rec."Line No.") + ' ' + Rec."Actual Value");
        exit(true);
    end;
}

page 62640 "PG NV Doc Split"
{
    PageType = Document;
    SourceTable = "PG NV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "PG NV Lines Split")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 62636 "PG NV Lines DelayedSplit"
{
    PageType = ListPart;
    SourceTable = "PG NV Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type) { ApplicationArea = All; }
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(ActUpd; ActValueTxt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG NV Log";
                    begin
                        Log.Add('V-UPD ' + Format(Rec."Line No."));
                        Rec.Validate("Actual Value", ActValueTxt);
                        CurrPage.Update();
                    end;
                }
                field(ActKeep; KeepTxt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG NV Log";
                    begin
                        Log.Add('V-KEEP ' + Format(Rec."Line No."));
                        Rec.Validate("Actual Value", KeepTxt);
                    end;
                }
                field(PlainVar; PlainTxt) { ApplicationArea = All; }
                field(Stored; Rec."Actual Value")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    var
        ActValueTxt: Text;
        KeepTxt: Text;
        PlainTxt: Text;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG NV Log";
    begin
        ActValueTxt := Rec."Actual Value";
        KeepTxt := Rec."Actual Value";
        Log.Add('AGR ' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('NEW ' + Format(Rec."Line No."));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('INS ' + Format(Rec."Line No.") + ' ' + Rec."Actual Value");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('MOD ' + Format(Rec."Line No.") + ' ' + Rec."Actual Value");
        exit(true);
    end;
}

page 62641 "PG NV Doc DelayedSplit"
{
    PageType = Document;
    SourceTable = "PG NV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "PG NV Lines DelayedSplit")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

page 62637 "PG NV Lines DelayedSplitPop"
{
    PageType = ListPart;
    SourceTable = "PG NV Line";
    ApplicationArea = All;
    UsageCategory = None;
    AutoSplitKey = true;
    DelayedInsert = true;
    PopulateAllFields = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Type; Rec.Type) { ApplicationArea = All; }
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(ActUpd; ActValueTxt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG NV Log";
                    begin
                        Log.Add('V-UPD ' + Format(Rec."Line No."));
                        Rec.Validate("Actual Value", ActValueTxt);
                        CurrPage.Update();
                    end;
                }
                field(ActKeep; KeepTxt)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "PG NV Log";
                    begin
                        Log.Add('V-KEEP ' + Format(Rec."Line No."));
                        Rec.Validate("Actual Value", KeepTxt);
                    end;
                }
                field(PlainVar; PlainTxt) { ApplicationArea = All; }
                field(Stored; Rec."Actual Value")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    var
        ActValueTxt: Text;
        KeepTxt: Text;
        PlainTxt: Text;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG NV Log";
    begin
        ActValueTxt := Rec."Actual Value";
        KeepTxt := Rec."Actual Value";
        Log.Add('AGR ' + Format(Rec."Line No."));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('NEW ' + Format(Rec."Line No."));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('INS ' + Format(Rec."Line No.") + ' ' + Rec."Actual Value");
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "PG NV Log";
    begin
        Log.Add('MOD ' + Format(Rec."Line No.") + ' ' + Rec."Actual Value");
        exit(true);
    end;
}

page 62642 "PG NV Doc DelayedSplitPop"
{
    PageType = Document;
    SourceTable = "PG NV Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
            part(Lines; "PG NV Lines DelayedSplitPop")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
        }
    }
}

codeunit 62643 "PG NV New Row Page Variable"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PG NV Log";

    local procedure Seed()
    var
        Head: Record "PG NV Head";
        Line: Record "PG NV Line";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head."No." := 'D1';
        Head.Insert();
        Line.Init();
        Line."Doc No." := 'D1';
        Line."Line No." := 10000;
        Line.Code := 'C0';
        Line."Actual Value" := 'old';
        Line.Insert();
        Log.Take();
    end;

    local procedure Say(Name: Text)
    var
        Line: Record "PG NV Line";
        Lines: Text;
    begin
        if Line.FindSet() then
            repeat
                Lines += Line."Doc No." + '/' + Format(Line."Line No.") + ':' + Format(Line.Type) + ':' + Line.Code + ':' + Line."Actual Value" + ' ';
            until Line.Next() = 0;
        Observer.Observe(Name, 'lines=[' + Lines + '] log=' + Log.Take());
    end;

    [Test]
    procedure Plain_NewRow_RecordFieldsThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc Plain";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_NewRow_VariableWithUpdateFirst()
    var
        Card: TestPage "PG NV Doc Plain";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_NewRow_RecordFieldThenVariableNoUpdate()
    var
        Card: TestPage "PG NV Doc Plain";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.ActKeep.SetValue('1');
        Say('ActKeep');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_NewRow_VariableNoUpdateFirst()
    var
        Card: TestPage "PG NV Doc Plain";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.ActKeep.SetValue('1');
        Say('ActKeep');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_NewRow_RecordFieldThenPlainVariable()
    var
        Card: TestPage "PG NV Doc Plain";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.PlainVar.SetValue('p');
        Say('PlainVar');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_NewRow_PlainVariableFirst()
    var
        Card: TestPage "PG NV Doc Plain";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.PlainVar.SetValue('p');
        Say('PlainVar');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_StoredRow_SameValueThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc Plain";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.First();
        Say('First');
        Card.Lines.Code.SetValue('C0');
        Say('Code same');
        Card.Lines.ActUpd.SetValue('2');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_StoredRow_VariableWithUpdate()
    var
        Card: TestPage "PG NV Doc Plain";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.First();
        Say('First');
        Card.Lines.ActUpd.SetValue('2');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Plain_NewDocument_RecordFieldsThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc Plain";
    begin
        Seed();
        Card.OpenNew();
        Card."No.".SetValue('D2');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Delayed_NewRow_RecordFieldsThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc Delayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Delayed_NewRow_VariableWithUpdateFirst()
    var
        Card: TestPage "PG NV Doc Delayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Delayed_NewRow_RecordFieldThenVariableNoUpdate()
    var
        Card: TestPage "PG NV Doc Delayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.ActKeep.SetValue('1');
        Say('ActKeep');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Delayed_NewRow_VariableNoUpdateFirst()
    var
        Card: TestPage "PG NV Doc Delayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.ActKeep.SetValue('1');
        Say('ActKeep');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Delayed_NewRow_RecordFieldThenPlainVariable()
    var
        Card: TestPage "PG NV Doc Delayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.PlainVar.SetValue('p');
        Say('PlainVar');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Delayed_NewRow_PlainVariableFirst()
    var
        Card: TestPage "PG NV Doc Delayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.PlainVar.SetValue('p');
        Say('PlainVar');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Delayed_StoredRow_SameValueThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc Delayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.First();
        Say('First');
        Card.Lines.Code.SetValue('C0');
        Say('Code same');
        Card.Lines.ActUpd.SetValue('2');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Delayed_StoredRow_VariableWithUpdate()
    var
        Card: TestPage "PG NV Doc Delayed";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.First();
        Say('First');
        Card.Lines.ActUpd.SetValue('2');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Delayed_NewDocument_RecordFieldsThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc Delayed";
    begin
        Seed();
        Card.OpenNew();
        Card."No.".SetValue('D2');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Split_NewRow_RecordFieldsThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc Split";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Split_NewRow_VariableWithUpdateFirst()
    var
        Card: TestPage "PG NV Doc Split";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Split_NewRow_RecordFieldThenVariableNoUpdate()
    var
        Card: TestPage "PG NV Doc Split";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.ActKeep.SetValue('1');
        Say('ActKeep');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Split_NewRow_VariableNoUpdateFirst()
    var
        Card: TestPage "PG NV Doc Split";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.ActKeep.SetValue('1');
        Say('ActKeep');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Split_NewRow_RecordFieldThenPlainVariable()
    var
        Card: TestPage "PG NV Doc Split";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.PlainVar.SetValue('p');
        Say('PlainVar');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Split_NewRow_PlainVariableFirst()
    var
        Card: TestPage "PG NV Doc Split";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.PlainVar.SetValue('p');
        Say('PlainVar');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Split_StoredRow_SameValueThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc Split";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.First();
        Say('First');
        Card.Lines.Code.SetValue('C0');
        Say('Code same');
        Card.Lines.ActUpd.SetValue('2');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Split_StoredRow_VariableWithUpdate()
    var
        Card: TestPage "PG NV Doc Split";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.First();
        Say('First');
        Card.Lines.ActUpd.SetValue('2');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure Split_NewDocument_RecordFieldsThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc Split";
    begin
        Seed();
        Card.OpenNew();
        Card."No.".SetValue('D2');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplit_NewRow_RecordFieldsThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc DelayedSplit";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplit_NewRow_VariableWithUpdateFirst()
    var
        Card: TestPage "PG NV Doc DelayedSplit";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplit_NewRow_RecordFieldThenVariableNoUpdate()
    var
        Card: TestPage "PG NV Doc DelayedSplit";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.ActKeep.SetValue('1');
        Say('ActKeep');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplit_NewRow_VariableNoUpdateFirst()
    var
        Card: TestPage "PG NV Doc DelayedSplit";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.ActKeep.SetValue('1');
        Say('ActKeep');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplit_NewRow_RecordFieldThenPlainVariable()
    var
        Card: TestPage "PG NV Doc DelayedSplit";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.PlainVar.SetValue('p');
        Say('PlainVar');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplit_NewRow_PlainVariableFirst()
    var
        Card: TestPage "PG NV Doc DelayedSplit";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.PlainVar.SetValue('p');
        Say('PlainVar');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplit_StoredRow_SameValueThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc DelayedSplit";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.First();
        Say('First');
        Card.Lines.Code.SetValue('C0');
        Say('Code same');
        Card.Lines.ActUpd.SetValue('2');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplit_StoredRow_VariableWithUpdate()
    var
        Card: TestPage "PG NV Doc DelayedSplit";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.First();
        Say('First');
        Card.Lines.ActUpd.SetValue('2');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplit_NewDocument_RecordFieldsThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc DelayedSplit";
    begin
        Seed();
        Card.OpenNew();
        Card."No.".SetValue('D2');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplitPop_NewRow_RecordFieldsThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc DelayedSplitPop";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplitPop_NewRow_VariableWithUpdateFirst()
    var
        Card: TestPage "PG NV Doc DelayedSplitPop";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplitPop_NewRow_RecordFieldThenVariableNoUpdate()
    var
        Card: TestPage "PG NV Doc DelayedSplitPop";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.ActKeep.SetValue('1');
        Say('ActKeep');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplitPop_NewRow_VariableNoUpdateFirst()
    var
        Card: TestPage "PG NV Doc DelayedSplitPop";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.ActKeep.SetValue('1');
        Say('ActKeep');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplitPop_NewRow_RecordFieldThenPlainVariable()
    var
        Card: TestPage "PG NV Doc DelayedSplitPop";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.PlainVar.SetValue('p');
        Say('PlainVar');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplitPop_NewRow_PlainVariableFirst()
    var
        Card: TestPage "PG NV Doc DelayedSplitPop";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.PlainVar.SetValue('p');
        Say('PlainVar');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplitPop_StoredRow_SameValueThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc DelayedSplitPop";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.First();
        Say('First');
        Card.Lines.Code.SetValue('C0');
        Say('Code same');
        Card.Lines.ActUpd.SetValue('2');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplitPop_StoredRow_VariableWithUpdate()
    var
        Card: TestPage "PG NV Doc DelayedSplitPop";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('D1');
        Log.Take();
        Card.Lines.First();
        Say('First');
        Card.Lines.ActUpd.SetValue('2');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

    [Test]
    procedure DelayedSplitPop_NewDocument_RecordFieldsThenVariableWithUpdate()
    var
        Card: TestPage "PG NV Doc DelayedSplitPop";
    begin
        Seed();
        Card.OpenNew();
        Card."No.".SetValue('D2');
        Log.Take();
        Card.Lines.New();
        Say('New');
        Card.Lines.Type.SetValue('B');
        Say('Type');
        Card.Lines.Code.SetValue('C1');
        Say('Code');
        Card.Lines.ActUpd.SetValue('1');
        Say('ActUpd');
        Observer.Observe('shown', Card.Lines."Line No.".Value + ':' + Card.Lines.Code.Value + ':upd=' + Card.Lines.ActUpd.Value + ':keep=' + Card.Lines.ActKeep.Value + ':plain=' + Card.Lines.PlainVar.Value + ':stored=' + Card.Lines.Stored.Value);
        Log.Take();
        Card.Close();
        Say('closed');
        Observer.Finish();
    end;

}
