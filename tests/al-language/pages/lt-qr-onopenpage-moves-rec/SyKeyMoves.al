// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-class
// Scope: in-scope
// Fixtures used: own objects 89690 - 89694 (writer SY); Probe Observer (69160); tests in this file (codeunit 89694)
// Probe: al-runner issue 5871 (reporter's measurements on real BC 29.0, repeated here with own objects). A Worksheet over a table with the key
//   ByName (Name) next to its primary key (Id); "LT SY Name List" calls Rec.SetCurrentKey(Name) in OnOpenPage, "LT SY Id List" is the same page in
//   the primary key (control). Log: R<Id> = OnAfterGetRecord, C<Id> = OnAfterGetCurrRecord. Rows are seeded with Name = 'N' + (1000 - Id), so the
//   key ByName runs in descending Id order.
// Facts: in the key ByName every row made current reads three times before OnAfterGetCurrRecord (R4;R4;R4;C4), also with First, Last, each step
//   of GoToKey and GoToRecord over a view of 30 rows (longer than a window), a refill by TestPage.Filter.SetFilter and by an action that calls
//   CurrPage.Update(false), and at the open of a view of one row and of 30 rows. In the primary key the same steps read twice.
// BC versions: 27, 28, 29

table 89690 "LT SY Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Code[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }
}

codeunit 89691 "LT SY Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 89692 "LT SY Name List"
{
    PageType = Worksheet;
    SourceTable = "LT SY Row";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshRows)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Name);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT SY Log";
}

page 89693 "LT SY Id List"
{
    PageType = Worksheet;
    SourceTable = "LT SY Row";
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshRows)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "LT SY Log";
}

codeunit 89694 "LT SY Key Moves Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT SY Log";

    local procedure Seed(Count: Integer)
    var
        Row: Record "LT SY Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Count do begin
            Row.Init();
            Row.Id := i;
            Row.Name := 'N' + Format(1000 - i);
            Row.Insert();
        end;
        Log.Take();
    end;

    [Test]
    procedure Name_OneRow()
    var
        Row: Record "LT SY Row";
        P: TestPage "LT SY Name List";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '1:R1;R1;R1;C1;');
        Observer.Verify();
    end;

    [Test]
    procedure Id_OneRow()
    var
        Row: Record "LT SY Row";
        P: TestPage "LT SY Id List";
    begin
        Seed(1);
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '1:R1;R1;C1;');
        Observer.Verify();
    end;

    [Test]
    procedure Name_FilterMoves()
    var
        Row: Record "LT SY Row";
        P: TestPage "LT SY Name List";
    begin
        Seed(4);
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.Filter.SetFilter(Id, '1|2|4');
        Observer.Observe('filter', P.Id.Value() + ':' + Log.Take());
        P.Next();
        Observer.Observe('next', P.Id.Value() + ':' + Log.Take());
        P.First();
        Observer.Observe('first', P.Id.Value() + ':' + Log.Take());
        P.Last();
        Observer.Observe('last', P.Id.Value() + ':' + Log.Take());
        P.Previous();
        Observer.Observe('previous', P.Id.Value() + ':' + Log.Take());
        P.GoToKey(4);
        Observer.Observe('gotokey', P.Id.Value() + ':' + Log.Take());
        Row.Get(1);
        P.GoToRecord(Row);
        Observer.Observe('gotorecord', P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '4:R4;R3;R2;R1;R4;R4;R4;C4;');
        Observer.Expect('filter', '4:R4;R2;R1;R4;R4;R4;C4;');
        Observer.Expect('next', '2:R2;R2;R2;C2;');
        Observer.Expect('first', '4:R4;R4;R4;C4;');
        Observer.Expect('last', '1:R1;R1;R1;C1;');
        Observer.Expect('previous', '2:R2;R2;R2;C2;');
        Observer.Expect('gotokey', '4:R4;R4;R4;C4;');
        Observer.Expect('gotorecord', '1:R2;R2;R2;C2;R1;R1;R1;C1;');
        Observer.Verify();
    end;

    [Test]
    procedure Id_FilterMoves()
    var
        Row: Record "LT SY Row";
        P: TestPage "LT SY Id List";
    begin
        Seed(4);
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.Filter.SetFilter(Id, '1|2|4');
        Observer.Observe('filter', P.Id.Value() + ':' + Log.Take());
        P.Next();
        Observer.Observe('next', P.Id.Value() + ':' + Log.Take());
        P.First();
        Observer.Observe('first', P.Id.Value() + ':' + Log.Take());
        P.Last();
        Observer.Observe('last', P.Id.Value() + ':' + Log.Take());
        P.Previous();
        Observer.Observe('previous', P.Id.Value() + ':' + Log.Take());
        P.GoToKey(4);
        Observer.Observe('gotokey', P.Id.Value() + ':' + Log.Take());
        Row.Get(1);
        P.GoToRecord(Row);
        Observer.Observe('gotorecord', P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '1:R1;R2;R3;R4;R1;R1;C1;');
        Observer.Expect('filter', '1:R1;R2;R4;R1;R1;C1;');
        Observer.Expect('next', '2:R2;R2;C2;');
        Observer.Expect('first', '1:R1;R1;C1;');
        Observer.Expect('last', '4:R4;R4;C4;');
        Observer.Expect('previous', '2:R2;R2;C2;');
        Observer.Expect('gotokey', '4:R1;R1;C1;R2;R2;C2;R4;R4;C4;');
        Observer.Expect('gotorecord', '1:R1;R1;C1;');
        Observer.Verify();
    end;

    [Test]
    procedure Name_LongView()
    var
        Row: Record "LT SY Row";
        P: TestPage "LT SY Name List";
    begin
        Seed(30);
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.Last();
        Observer.Observe('last', P.Id.Value() + ':' + Log.Take());
        P.First();
        Observer.Observe('first', P.Id.Value() + ':' + Log.Take());
        P.GoToKey(25);
        Observer.Observe('gotokey', P.Id.Value() + ':' + Log.Take());
        Row.Get(10);
        P.GoToRecord(Row);
        Observer.Observe('gotorecord', P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '30:R30;R29;R28;R27;R26;R25;R24;R23;R22;R21;R20;R19;R18;R17;R16;R15;R14;R13;R12;R11;R30;R30;R30;C30;');
        Observer.Expect('last', '1:R11;R10;R9;R8;R7;R6;R5;R4;R3;R2;R1;R1;R1;C1;');
        Observer.Expect('first', '30:R30;R30;R30;C30;');
        Observer.Expect('gotokey', '25:R29;R29;R29;C29;R28;R28;R28;C28;R27;R27;R27;C27;R26;R26;R26;C26;R25;R25;R25;C25;');
        Observer.Expect('gotorecord', '10:R30;R30;R30;C30;R29;R29;R29;C29;R28;R28;R28;C28;R27;R27;R27;C27;R26;R26;R26;C26;R25;R25;R25;C25;R24;R24;R24;C24;R23;R23;R23;C23;R22;R22;R22;C22;R21;R21;R21;C21;R20;R20;R20;C20;R19;R19;R19;C19;R18;R18;R18;C18;R17;R17;R17;C17;R16;R16;R16;C16;R15;R15;R15;C15;R14;R14;R14;C14;R13;R13;R13;C13;R12;R12;R12;C12;R11;R11;R11;C11;R10;R10;R10;C10;');
        Observer.Verify();
    end;

    [Test]
    procedure Id_LongView()
    var
        Row: Record "LT SY Row";
        P: TestPage "LT SY Id List";
    begin
        Seed(30);
        P.OpenView();
        Observer.Observe('open', P.Id.Value() + ':' + Log.Take());
        P.Last();
        Observer.Observe('last', P.Id.Value() + ':' + Log.Take());
        P.First();
        Observer.Observe('first', P.Id.Value() + ':' + Log.Take());
        P.GoToKey(25);
        Observer.Observe('gotokey', P.Id.Value() + ':' + Log.Take());
        Row.Get(10);
        P.GoToRecord(Row);
        Observer.Observe('gotorecord', P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('open', '1:R1;R2;R3;R4;R5;R6;R7;R8;R9;R10;R11;R12;R13;R14;R15;R16;R17;R18;R19;R20;R1;R1;C1;');
        Observer.Expect('last', '30:R20;R21;R22;R23;R24;R25;R26;R27;R28;R29;R30;R30;C30;');
        Observer.Expect('first', '1:R1;R1;C1;');
        Observer.Expect('gotokey', '25:R2;R2;C2;R3;R3;C3;R4;R4;C4;R5;R5;C5;R6;R6;C6;R7;R7;C7;R8;R8;C8;R9;R9;C9;R10;R10;C10;R11;R11;C11;R12;R12;C12;R13;R13;C13;R14;R14;C14;R15;R15;C15;R16;R16;C16;R17;R17;C17;R18;R18;C18;R19;R19;C19;R20;R20;C20;R21;R21;C21;R22;R22;C22;R23;R23;C23;R24;R24;C24;R25;R25;C25;');
        Observer.Expect('gotorecord', '10:R1;R1;C1;R2;R2;C2;R3;R3;C3;R4;R4;C4;R5;R5;C5;R6;R6;C6;R7;R7;C7;R8;R8;C8;R9;R9;C9;R10;R10;C10;');
        Observer.Verify();
    end;

    [Test]
    procedure Name_UpdateAction()
    var
        Row: Record "LT SY Row";
        P: TestPage "LT SY Name List";
    begin
        Seed(3);
        P.OpenView();
        P.Next();
        Observer.Observe('moved', P.Id.Value() + ':' + Log.Take());
        P.RefreshRows.Invoke();
        Observer.Observe('update', P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('moved', '2:R3;R2;R1;R3;R3;R3;C3;R2;R2;R2;C2;');
        Observer.Expect('update', '2:R2;R2;R2;R2;R1;R2;R3;R2;R2;R2;C2;');
        Observer.Verify();
    end;

    [Test]
    procedure Id_UpdateAction()
    var
        Row: Record "LT SY Row";
        P: TestPage "LT SY Id List";
    begin
        Seed(3);
        P.OpenView();
        P.Next();
        Observer.Observe('moved', P.Id.Value() + ':' + Log.Take());
        P.RefreshRows.Invoke();
        Observer.Observe('update', P.Id.Value() + ':' + Log.Take());
        P.Close();
        Observer.Expect('moved', '2:R1;R2;R3;R1;R1;C1;R2;R2;C2;');
        Observer.Expect('update', '2:R2;R2;R2;R3;R2;R1;R2;R2;C2;');
        Observer.Verify();
    end;
}
