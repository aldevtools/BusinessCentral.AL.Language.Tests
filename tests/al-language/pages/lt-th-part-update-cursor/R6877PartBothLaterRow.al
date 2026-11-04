// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT TH Doc/Line fixtures of ThPartUpdateCursor.al (same folder); own objects 95000-95019 (LT R6877 *)
// Probe: from al-runner issue 6877 (follow-up of 6038): a ListPart (SubPageLink, UpdatePropagation = Both) over three lines on a Document,
//   a Card and a ListPlus host. A part control's OnValidate calls CurrPage.Update(false). Part on line 2 (Next), on line 3 (Next and a part
//   action that runs Rec.Next()) and on line 2 by the action from line 1; with a control that only updates (Note) and with one that first
//   changes the host's stored row (Qty. to Ship). After the SetValue: the part's Line No., the trigger log of host and part, where a following
//   SetValue of another field (Bin Code) is stored, and the stored rows.
// Facts: on all three host types the part stays on its row (line 2 after Next, line 3 after Next and the action, line 2 after the action from
//   line 1). Update(false) in Note or Qty. to Ship drops the typed value (stored empty and 0); the Qty. to Ship trigger's change of the host's
//   stored row is shown on the host (Info). The log is the trigger order of the host and the part; the next SetValue (Bin Code) is stored on the
//   same line, and no trigger runs for it.
// BC versions: 27+ (tested by the corpus CI matrix)

table 95000 "LT R6877 Doc"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Info; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 95001 "LT R6877 Lines"
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
                field(Note; Rec.Note)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Log: Codeunit "LT R6877 Log";
                    begin
                        Log.Add('N.V');
                        CurrPage.Update(false);
                        Log.Add('N.V.end');
                    end;
                }
                field("Qty. to Ship"; Rec."Qty. to Ship")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        Head: Record "LT R6877 Doc";
                        Log: Codeunit "LT R6877 Log";
                    begin
                        Log.Add('Q.V');
                        Head.Get(Rec."Document No.");
                        Head.Info := 'changed';
                        Head.Modify();
                        CurrPage.Update(false);
                        Log.Add('Q.V.end');
                    end;
                }
                field("Bin Code"; Rec."Bin Code") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NextLine)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT R6877 Log";
                begin
                    Log.Add('ACT');
                    Rec.Next();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT R6877 Log";
    begin
        Log.Add('R' + Format(Rec."Line No." div 10000));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT R6877 Log";
    begin
        Log.Add('C' + Format(Rec."Line No." div 10000));
    end;
}

page 95002 "LT R6877 Doc"
{
    PageType = Document;
    SourceTable = "LT R6877 Doc";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Info; Rec.Info) { ApplicationArea = All; }
            part(Lines; "LT R6877 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT R6877 Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT R6877 Log";
    begin
        Log.Add('HC');
    end;
}

page 95003 "LT R6877 Card"
{
    PageType = Card;
    SourceTable = "LT R6877 Doc";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Info; Rec.Info) { ApplicationArea = All; }
            part(Lines; "LT R6877 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT R6877 Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT R6877 Log";
    begin
        Log.Add('HC');
    end;
}

page 95004 "LT R6877 Plus"
{
    PageType = ListPlus;
    SourceTable = "LT R6877 Doc";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Info; Rec.Info) { ApplicationArea = All; }
            part(Lines; "LT R6877 Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT R6877 Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT R6877 Log";
    begin
        Log.Add('HC');
    end;
}

codeunit 95005 "LT R6877 Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Head: Record "LT R6877 Doc";
        Line: Record "LT TH Line";
        Log: Codeunit "LT R6877 Log";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head."No." := 'D1';
        Head.Insert();
        InsertLine(10000);
        InsertLine(20000);
        InsertLine(30000);
        Log.Reset();
    end;

    local procedure InsertLine(LineNo: Integer)
    var
        Line: Record "LT TH Line";
    begin
        Line."Document No." := 'D1';
        Line."Line No." := LineNo;
        Line.Insert();
    end;

    local procedure ObserveStored(var Observer: Codeunit "Probe Observer")
    var
        Head: Record "LT R6877 Doc";
        Line: Record "LT TH Line";
        Rows: Text;
    begin
        Head.Get('D1');
        if Line.FindSet() then
            repeat
                Rows += Format(Line."Line No." div 10000) + ':' + Line.Note + '/' + Format(Line."Qty. to Ship") + '/' + Line."Bin Code" + ' ';
            until Line.Next() = 0;
        Observer.Observe('stored', Head.Info + ' ' + Rows);
    end;

    // Nav: 1 = Lines.First(); Lines.Next() (line 2); 2 = First, Next, action NextLine (line 3); 3 = First, action NextLine (line 2).
    // Ctl: 1 = Note (Update(false)); 2 = Qty. to Ship (changes the host's stored row, then Update(false)).

    local procedure RunDoc(var Observer: Codeunit "Probe Observer"; Nav: Integer; Ctl: Integer)
    var
        P: TestPage "LT R6877 Doc";
        Log: Codeunit "LT R6877 Log";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('D1');
        P.Lines.First();
        if Nav <= 2 then
            if Nav = 1 then
                P.Lines.Next()
            else begin
                P.Lines.Next();
                P.Lines.NextLine.Invoke();
            end
        else
            P.Lines.NextLine.Invoke();
        Observer.Observe('line before', P.Lines."Line No.".Value());
        Log.Reset();
        if Ctl = 1 then
            P.Lines.Note.SetValue('A')
        else
            P.Lines."Qty. to Ship".SetValue('5');
        Observer.Observe('line after', P.Lines."Line No.".Value());
        Observer.Observe('log', Log.Get());
        Observer.Observe('info shown', P.Info.Value());
        Log.Reset();
        P.Lines."Bin Code".SetValue('Z');
        Observer.Observe('line after bin', P.Lines."Line No.".Value());
        Observer.Observe('log bin', Log.Get());
        P.Close();
        ObserveStored(Observer);
    end;

    local procedure RunCard(var Observer: Codeunit "Probe Observer"; Nav: Integer; Ctl: Integer)
    var
        P: TestPage "LT R6877 Card";
        Log: Codeunit "LT R6877 Log";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('D1');
        P.Lines.First();
        if Nav <= 2 then
            if Nav = 1 then
                P.Lines.Next()
            else begin
                P.Lines.Next();
                P.Lines.NextLine.Invoke();
            end
        else
            P.Lines.NextLine.Invoke();
        Observer.Observe('line before', P.Lines."Line No.".Value());
        Log.Reset();
        if Ctl = 1 then
            P.Lines.Note.SetValue('A')
        else
            P.Lines."Qty. to Ship".SetValue('5');
        Observer.Observe('line after', P.Lines."Line No.".Value());
        Observer.Observe('log', Log.Get());
        Observer.Observe('info shown', P.Info.Value());
        Log.Reset();
        P.Lines."Bin Code".SetValue('Z');
        Observer.Observe('line after bin', P.Lines."Line No.".Value());
        Observer.Observe('log bin', Log.Get());
        P.Close();
        ObserveStored(Observer);
    end;

    local procedure RunPlus(var Observer: Codeunit "Probe Observer"; Nav: Integer; Ctl: Integer)
    var
        P: TestPage "LT R6877 Plus";
        Log: Codeunit "LT R6877 Log";
    begin
        Seed();
        P.OpenEdit();
        P.GoToKey('D1');
        P.Lines.First();
        if Nav <= 2 then
            if Nav = 1 then
                P.Lines.Next()
            else begin
                P.Lines.Next();
                P.Lines.NextLine.Invoke();
            end
        else
            P.Lines.NextLine.Invoke();
        Observer.Observe('line before', P.Lines."Line No.".Value());
        Log.Reset();
        if Ctl = 1 then
            P.Lines.Note.SetValue('A')
        else
            P.Lines."Qty. to Ship".SetValue('5');
        Observer.Observe('line after', P.Lines."Line No.".Value());
        Observer.Observe('log', Log.Get());
        Observer.Observe('info shown', P.Info.Value());
        Log.Reset();
        P.Lines."Bin Code".SetValue('Z');
        Observer.Observe('line after bin', P.Lines."Line No.".Value());
        Observer.Observe('log bin', Log.Get());
        P.Close();
        ObserveStored(Observer);
    end;

    [Test]
    procedure R_Doc_Nav1_Ctl1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDoc(Observer, 1, 1);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'N.V N.V.end HR HC R2 R3 R2 R1 R2 R2 C2 ');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Doc_Nav1_Ctl2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDoc(Observer, 1, 2);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'Q.V Q.V.end HR HC R2 R3 R2 R1 R2 R2 C2 ');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Doc_Nav2_Ctl1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDoc(Observer, 2, 1);
        Observer.Expect('line before', '30000');
        Observer.Expect('line after', '30000');
        Observer.Expect('log', 'N.V N.V.end HR HC R3 R2 R1 R3 R3 C3 ');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '30000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/ 3:/0/Z ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Doc_Nav2_Ctl2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDoc(Observer, 2, 2);
        Observer.Expect('line before', '30000');
        Observer.Expect('line after', '30000');
        Observer.Expect('log', 'Q.V Q.V.end HR HC R3 R2 R1 R3 R3 C3 ');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '30000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/ 3:/0/Z ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Doc_Nav3_Ctl1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDoc(Observer, 3, 1);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'N.V N.V.end HR HC R2 R3 R2 R1 R2 R2 C2 ');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Doc_Nav3_Ctl2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDoc(Observer, 3, 2);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'Q.V Q.V.end HR HC R2 R3 R2 R1 R2 R2 C2 ');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Card_Nav1_Ctl1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCard(Observer, 1, 1);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'N.V N.V.end HR HC R2 R3 R2 R1 R2 R2 C2 ');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Card_Nav1_Ctl2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCard(Observer, 1, 2);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'Q.V Q.V.end HR HC R2 R3 R2 R1 R2 R2 C2 ');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Card_Nav2_Ctl1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCard(Observer, 2, 1);
        Observer.Expect('line before', '30000');
        Observer.Expect('line after', '30000');
        Observer.Expect('log', 'N.V N.V.end HR HC R3 R2 R1 R3 R3 C3 ');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '30000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/ 3:/0/Z ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Card_Nav2_Ctl2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCard(Observer, 2, 2);
        Observer.Expect('line before', '30000');
        Observer.Expect('line after', '30000');
        Observer.Expect('log', 'Q.V Q.V.end HR HC R3 R2 R1 R3 R3 C3 ');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '30000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/ 3:/0/Z ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Card_Nav3_Ctl1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCard(Observer, 3, 1);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'N.V N.V.end HR HC R2 R3 R2 R1 R2 R2 C2 ');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Card_Nav3_Ctl2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCard(Observer, 3, 2);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'Q.V Q.V.end HR HC R2 R3 R2 R1 R2 R2 C2 ');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Plus_Nav1_Ctl1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunPlus(Observer, 1, 1);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'N.V N.V.end HR HC R2 R3 R2 R1 R2 R2 C2 ');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Plus_Nav1_Ctl2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunPlus(Observer, 1, 2);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'Q.V Q.V.end HR HC R2 R3 R2 R1 R2 R2 C2 ');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Plus_Nav2_Ctl1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunPlus(Observer, 2, 1);
        Observer.Expect('line before', '30000');
        Observer.Expect('line after', '30000');
        Observer.Expect('log', 'N.V N.V.end HR HC R3 R2 R1 R3 R3 C3 ');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '30000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/ 3:/0/Z ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Plus_Nav2_Ctl2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunPlus(Observer, 2, 2);
        Observer.Expect('line before', '30000');
        Observer.Expect('line after', '30000');
        Observer.Expect('log', 'Q.V Q.V.end HR HC R3 R2 R1 R3 R3 C3 ');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '30000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/ 3:/0/Z ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Plus_Nav3_Ctl1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunPlus(Observer, 3, 1);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'N.V N.V.end HR HC R2 R3 R2 R1 R2 R2 C2 ');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure R_Plus_Nav3_Ctl2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunPlus(Observer, 3, 2);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'Q.V Q.V.end HR HC R2 R3 R2 R1 R2 R2 C2 ');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;
}

codeunit 95006 "LT R6877 Log"
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
