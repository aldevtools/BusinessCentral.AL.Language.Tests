// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 70432 - 70441
// Probe: written against the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a Worksheet that stands on the new-row line of a batch without lines (nothing stored), whose header controls switch to another
//   batch without lines (the Movement Worksheet shape: global controls for the worksheet name and the location; the name's OnValidate
//   runs CurrPage.SaveRecord(), sets the name and location filters in filter group 2, calls Rec.Find('-') and CurrPage.Update(false)).
//   Pinned elsewhere: a switch from a stored row to an empty batch (Y17JournalBatchSwitch.al UpdWs_BatchSwitch_ToEmptyBatch) and from the
//   new-row line to a batch with rows (pages/triggers/Y50UpdateFromNewLine.al G520_FromNewLine_ToBatchWithRows). Open here: which
//   OnNewRecord and OnAfterGetCurrRecord runs the switch makes, and what Rec holds afterwards for the page's code (an action that
//   passes Rec to a table procedure). Two pages: the Movement shape (DelayedInsert, no AutoSplitKey, OnNewRecord copies the globals into
//   the new row) and the journal shape (AutoSplitKey, OnNewRecord only logs, so the key of the new row comes from the filters).
//   Names: A/L1 and B/L2 (second test: C/L3), template T1, no lines. Log: V:start/V:done around the OnValidate, N: OnNewRecord
//   (name/location of Rec at its start), C: OnAfterGetCurrRecord, R: OnAfterGetRecord, A: the action (name/location of Rec).
// BC versions: 27, 28, 29

table 70432 "LT EE Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Template; Code[10]) { }
        field(2; Name; Code[10]) { }
        field(3; Location; Code[10]) { }
        field(4; "Line No."; Integer) { }
    }
    keys
    {
        key(PK; Template, Name, Location, "Line No.") { Clustered = true; }
    }

    procedure SetUpNewLine(NewTemplate: Code[10]; NewName: Code[10]; NewLocation: Code[10])
    begin
        Template := NewTemplate;
        Name := NewName;
        Location := NewLocation;
        "Line No." := 10000;
    end;

    // The shape of Warehouse Worksheet Line "WBR Calculate ..." in a partner extension: the name record is read with the keys of Rec.
    procedure Describe(var Line: Record "LT EE Line"): Text
    var
        WorksheetName: Record "LT EE Name";
    begin
        Line.TestField(Template);
        WorksheetName.Get(Line.Template, Line.Name, Line.Location);
        exit(Line.Template + '/' + Line.Name + '/' + Line.Location);
    end;
}

table 70433 "LT EE Name"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Template; Code[10]) { }
        field(2; Name; Code[10]) { }
        field(3; Location; Code[10]) { }
    }
    keys
    {
        key(PK; Template, Name, Location) { Clustered = true; }
    }
}

page 70435 "LT EE Movement Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT EE Line";
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(CurrentName; CurrentName)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('V:start');
                        CurrPage.SaveRecord();
                        SetName();
                        CurrPage.Update(false);
                        Log.Add('V:done');
                    end;
                }
                field(CurrentLocation; CurrentLocation)
                {
                    ApplicationArea = All;
                }
            }
            repeater(Lines)
            {
                field(Template; Rec.Template) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Location; Rec.Location) { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('A:' + Rec.Name + '/' + Rec.Location);
                    Log.SetResult(Rec.Describe(Rec));
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        WorksheetName: Record "LT EE Name";
    begin
        CurrentTemplate := 'T1';
        Rec.FilterGroup := 2;
        Rec.SetRange(Template, CurrentTemplate);
        Rec.FilterGroup := 0;
        WorksheetName.SetRange(Template, CurrentTemplate);
        WorksheetName.FindFirst();
        CurrentName := WorksheetName.Name;
        CurrentLocation := WorksheetName.Location;
        SetName();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec.Name + '/' + Rec.Location);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec.Name + '/' + Rec.Location);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Rec.Name + '/' + Rec.Location);
        Rec.SetUpNewLine(CurrentTemplate, CurrentName, CurrentLocation);
    end;

    local procedure SetName()
    begin
        Rec.FilterGroup := 2;
        Rec.SetRange(Name, CurrentName);
        Rec.SetRange(Location, CurrentLocation);
        Rec.FilterGroup := 0;
        if Rec.Find('-') then;
    end;

    var
        Log: Codeunit "LT EE Log";
        CurrentTemplate: Code[10];
        CurrentName: Code[10];
        CurrentLocation: Code[10];
}

page 70436 "LT EE Journal Worksheet"
{
    PageType = Worksheet;
    SourceTable = "LT EE Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(CurrentName; CurrentName)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('V:start');
                        CurrPage.SaveRecord();
                        SetName();
                        CurrPage.Update(false);
                        Log.Add('V:done');
                    end;
                }
                field(CurrentLocation; CurrentLocation)
                {
                    ApplicationArea = All;
                }
            }
            repeater(Lines)
            {
                field(Template; Rec.Template) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Location; Rec.Location) { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ReadRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add('A:' + Rec.Template + '/' + Rec.Name + '/' + Rec.Location);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        WorksheetName: Record "LT EE Name";
    begin
        CurrentTemplate := 'T1';
        Rec.FilterGroup := 2;
        Rec.SetRange(Template, CurrentTemplate);
        Rec.FilterGroup := 0;
        WorksheetName.SetRange(Template, CurrentTemplate);
        WorksheetName.FindFirst();
        CurrentName := WorksheetName.Name;
        CurrentLocation := WorksheetName.Location;
        SetName();
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec.Name + '/' + Rec.Location);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec.Name + '/' + Rec.Location);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('N:' + Rec.Template + '/' + Rec.Name + '/' + Rec.Location);
    end;

    local procedure SetName()
    begin
        Rec.FilterGroup := 2;
        Rec.SetRange(Name, CurrentName);
        Rec.SetRange(Location, CurrentLocation);
        Rec.FilterGroup := 0;
        if Rec.Find('-') then;
    end;

    var
        Log: Codeunit "LT EE Log";
        CurrentTemplate: Code[10];
        CurrentName: Code[10];
        CurrentLocation: Code[10];
}

codeunit 70434 "LT EE Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        Result: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Taken: Text
    begin
        Taken := Entries;
        Entries := '';
    end;

    procedure SetResult(NewResult: Text)
    begin
        Result := NewResult;
    end;

    procedure TakeResult() Taken: Text
    begin
        Taken := Result;
        Result := '';
    end;
}

codeunit 70437 "LT EE Batch Switch Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT EE Log";

    local procedure Seed()
    var
        WorksheetName: Record "LT EE Name";
        Line: Record "LT EE Line";
    begin
        Line.DeleteAll();
        WorksheetName.DeleteAll();
        AddName('A', 'L1');
        AddName('B', 'L2');
        AddName('C', 'L3');
        Log.Take();
        Log.TakeResult();
    end;

    local procedure AddName(Name: Code[10]; Location: Code[10])
    var
        WorksheetName: Record "LT EE Name";
    begin
        WorksheetName.Template := 'T1';
        WorksheetName.Name := Name;
        WorksheetName.Location := Location;
        WorksheetName.Insert();
    end;

    local procedure StoredLines(): Integer
    var
        Line: Record "LT EE Line";
    begin
        exit(Line.Count());
    end;

    [TryFunction]
    local procedure TrySwitch(var W: TestPage "LT EE Movement Worksheet"; NewName: Text; NewLocation: Text)
    begin
        W.CurrentLocation.SetValue(NewLocation);
        W.CurrentName.SetValue(NewName);
    end;

    [TryFunction]
    local procedure TrySwitchJournal(var W: TestPage "LT EE Journal Worksheet"; NewName: Text; NewLocation: Text)
    begin
        W.CurrentLocation.SetValue(NewLocation);
        W.CurrentName.SetValue(NewName);
    end;

    local procedure MovementSwitch(NewName: Text; NewLocation: Text; Invoke: Boolean)
    var
        W: TestPage "LT EE Movement Worksheet";
        Ok: Boolean;
    begin
        Seed();
        W.OpenEdit();
        Observer.Observe('open', W.Name.Value() + '/' + W.Location.Value() + '/' + W."Line No.".Value() + ':' + Log.Take());
        Observer.Observe('header', W.CurrentName.Value() + '/' + W.CurrentLocation.Value());
        Ok := TrySwitch(W, NewName, NewLocation);
        Observer.Observe('setvalue', Format(Ok));
        if not Ok then
            Observer.ObserveError('setvalue error');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', W.Template.Value() + '/' + W.Name.Value() + '/' + W.Location.Value() + '/' + W."Line No.".Value());
        Observer.Observe('read log', Log.Take());
        if Invoke then begin
            Ok := TryInvoke(W);
            Observer.Observe('invoke', Format(Ok));
            if not Ok then
                Observer.ObserveError('invoke error');
            Observer.Observe('action log', Log.Take());
            Observer.Observe('action result', Log.TakeResult());
        end;
        Observer.Observe('first', Format(W.First()) + ':' + Log.Take());
        W.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', Format(StoredLines()));
    end;

    [TryFunction]
    local procedure TryInvoke(var W: TestPage "LT EE Movement Worksheet")
    begin
        W.ReadRec.Invoke();
    end;

    // The partner shape: a switch to a worksheet without lines, then an action that reads Rec and passes it to a table procedure.
    [Test]
    procedure MovementWs_EmptyToEmpty_ThenAction()
    begin
        MovementSwitch('B', 'L2', true);
        Observer.Finish();
    end;

    // The same switch, nothing invoked: what the page shows and which triggers ran.
    [Test]
    procedure MovementWs_EmptyToEmpty_NoAction()
    begin
        MovementSwitch('B', 'L2', false);
        Observer.Finish();
    end;

    // A second switch in the same codeunit, to the third worksheet (the earlier tests left their rows behind).
    [Test]
    procedure MovementWs_EmptyToEmpty_SecondTest()
    begin
        MovementSwitch('C', 'L3', true);
        Observer.Finish();
    end;

    // The name the page already shows: the filters stay as they are.
    [Test]
    procedure MovementWs_SameName_ThenAction()
    begin
        MovementSwitch('A', 'L1', true);
        Observer.Finish();
    end;

    [Test]
    procedure JournalWs_EmptyToEmpty_ThenAction()
    var
        W: TestPage "LT EE Journal Worksheet";
        Ok: Boolean;
    begin
        Seed();
        W.OpenEdit();
        Observer.Observe('open', W.Name.Value() + '/' + W.Location.Value() + '/' + W."Line No.".Value() + ':' + Log.Take());
        Ok := TrySwitchJournal(W, 'B', 'L2');
        Observer.Observe('setvalue', Format(Ok));
        if not Ok then
            Observer.ObserveError('setvalue error');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('current', W.Template.Value() + '/' + W.Name.Value() + '/' + W.Location.Value() + '/' + W."Line No.".Value());
        Observer.Observe('read log', Log.Take());
        W.ReadRec.Invoke();
        Observer.Observe('action log', Log.Take());
        W.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Observe('stored', Format(StoredLines()));
        Observer.Finish();
    end;
}
