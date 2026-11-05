// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT TH Line (pages/parts/ThPartUpdateCursor.al) and LT R6877 Doc
//   (pages/lt-th-part-update-cursor/R6877PartBothLaterRow.al); own objects 95966-95973 (PG R7099 *)
// local object: the part's OnFindRecord trigger and the hosts' UpdatePropagation are what the test checks
// Probe: from al-runner issue 7099 (follow-up of 6877): R6877PartBothLaterRow.al's shape with the ListPart declaring
//   OnFindRecord(Which) that logs Which and returns Rec.Find(Which) (Sales Order Subform's shape); a second part also changes a page
//   global in it. Document, ListPlus and Card hosts with UpdatePropagation = Both. The part on line 2 (Next) or line 3 (Next, Next); a control
//   that only runs CurrPage.Update(false) (Note) and one that first changes the host's stored row (Qty. to Ship). Observed: the part's
//   Line No. after the SetValue, the trigger log (F(Which), R/C of the part, HR/HC of the host), where the next SetValue (Bin Code) lands,
//   and the stored rows.
// Result (BC 27.5, 28.5 and 29.0 alike): the part stays on its row on every host, as without OnFindRecord (R6877PartBothLaterRow.al),
//   and the next SetValue lands there. The reads are those of the part without OnFindRecord, with OnFindRecord('=>') before the first
//   read of the part and OnFindRecord('=') before its last OnAfterGetRecord: `HR;HC;F(=>);R2;R3;R2;R1;R2;F(=);R2;C2` on line 2,
//   `HR;HC;F(=>);R3;R2;R1;R3;F(=);R3;C3` on line 3. A change of a page global in the trigger changes nothing.
// BC versions: 27+ (tested by the corpus CI matrix)

page 95966 "PG R7099 Find Part"
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
                        Log: Codeunit "PG R7099 Log";
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
                        Log: Codeunit "PG R7099 Log";
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

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('F(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('R' + Format(Rec."Line No." div 10000));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('C' + Format(Rec."Line No." div 10000));
    end;
}

page 95967 "PG R7099 Find Global Part"
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
                        Log: Codeunit "PG R7099 Log";
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
                        Log: Codeunit "PG R7099 Log";
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

    var
        Total: Decimal;
        Finds: Integer;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Clear(Total);
        Finds += 1;
        Log.Add('F(' + Which + ')');
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('R' + Format(Rec."Line No." div 10000));
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('C' + Format(Rec."Line No." div 10000));
    end;
}

page 95968 "PG R7099 Doc"
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
            part(Lines; "PG R7099 Find Part")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('HC');
    end;
}

page 95969 "PG R7099 Plus"
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
            part(Lines; "PG R7099 Find Part")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('HC');
    end;
}

page 95970 "PG R7099 Card"
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
            part(Lines; "PG R7099 Find Part")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('HC');
    end;
}

page 95971 "PG R7099 DocG"
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
            part(Lines; "PG R7099 Find Global Part")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('HR');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "PG R7099 Log";
    begin
        Log.Add('HC');
    end;
}

codeunit 95972 "PG R7099 Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Head: Record "LT R6877 Doc";
        Line: Record "LT TH Line";
        Log: Codeunit "PG R7099 Log";
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

    // Nav: 1 = Lines.First(); Lines.Next() (line 2); 2 = First, Next, Next (line 3).
    // Ctl: 1 = Note (Update(false)); 2 = Qty. to Ship (changes the host's stored row, then Update(false)).

    local procedure RunDoc(var Observer: Codeunit "Probe Observer"; Nav: Integer; Ctl: Integer)
    var
        P: TestPage "PG R7099 Doc";
        Log: Codeunit "PG R7099 Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        P.Lines.First();
        P.Lines.Next();
        if Nav = 2 then
            P.Lines.Next();
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
        P: TestPage "PG R7099 Plus";
        Log: Codeunit "PG R7099 Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        P.Lines.First();
        P.Lines.Next();
        if Nav = 2 then
            P.Lines.Next();
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
        P: TestPage "PG R7099 Card";
        Log: Codeunit "PG R7099 Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        P.Lines.First();
        P.Lines.Next();
        if Nav = 2 then
            P.Lines.Next();
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

    local procedure RunDocG(var Observer: Codeunit "Probe Observer"; Nav: Integer; Ctl: Integer)
    var
        P: TestPage "PG R7099 DocG";
        Log: Codeunit "PG R7099 Log";
    begin
        P.OpenEdit();
        P.GoToKey('D1');
        P.Lines.First();
        P.Lines.Next();
        if Nav = 2 then
            P.Lines.Next();
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
    procedure PG7099_Doc_Line2_Note()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunDoc(Observer, 1, 1);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'N.V;N.V.end;HR;HC;F(=>);R2;R3;R2;R1;R2;F(=);R2;C2');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure PG7099_Doc_Line2_QtyChangesHost()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunDoc(Observer, 1, 2);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'Q.V;Q.V.end;HR;HC;F(=>);R2;R3;R2;R1;R2;F(=);R2;C2');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure PG7099_Doc_Line3_Note()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunDoc(Observer, 2, 1);
        Observer.Expect('line before', '30000');
        Observer.Expect('line after', '30000');
        Observer.Expect('log', 'N.V;N.V.end;HR;HC;F(=>);R3;R2;R1;R3;F(=);R3;C3');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '30000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/ 3:/0/Z ');
        Observer.Verify();
    end;

    [Test]
    procedure PG7099_Doc_Line3_QtyChangesHost()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunDoc(Observer, 2, 2);
        Observer.Expect('line before', '30000');
        Observer.Expect('line after', '30000');
        Observer.Expect('log', 'Q.V;Q.V.end;HR;HC;F(=>);R3;R2;R1;R3;F(=);R3;C3');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '30000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/ 3:/0/Z ');
        Observer.Verify();
    end;

    [Test]
    procedure PG7099_Plus_Line2_Note()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlus(Observer, 1, 1);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'N.V;N.V.end;HR;HC;F(=>);R2;R3;R2;R1;R2;F(=);R2;C2');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure PG7099_Plus_Line3_QtyChangesHost()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunPlus(Observer, 2, 2);
        Observer.Expect('line before', '30000');
        Observer.Expect('line after', '30000');
        Observer.Expect('log', 'Q.V;Q.V.end;HR;HC;F(=>);R3;R2;R1;R3;F(=);R3;C3');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '30000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/ 3:/0/Z ');
        Observer.Verify();
    end;

    [Test]
    procedure PG7099_Card_Line2_Note()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 1, 1);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'N.V;N.V.end;HR;HC;F(=>);R2;R3;R2;R1;R2;F(=);R2;C2');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure PG7099_Card_Line3_QtyChangesHost()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunCard(Observer, 2, 2);
        Observer.Expect('line before', '30000');
        Observer.Expect('line after', '30000');
        Observer.Expect('log', 'Q.V;Q.V.end;HR;HC;F(=>);R3;R2;R1;R3;F(=);R3;C3');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '30000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/ 3:/0/Z ');
        Observer.Verify();
    end;

    [Test]
    procedure PG7099_DocG_Line2_Note()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunDocG(Observer, 1, 1);
        Observer.Expect('line before', '20000');
        Observer.Expect('line after', '20000');
        Observer.Expect('log', 'N.V;N.V.end;HR;HC;F(=>);R2;R3;R2;R1;R2;F(=);R2;C2');
        Observer.Expect('info shown', '');
        Observer.Expect('line after bin', '20000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', ' 1:/0/ 2:/0/Z 3:/0/ ');
        Observer.Verify();
    end;

    [Test]
    procedure PG7099_DocG_Line3_QtyChangesHost()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        RunDocG(Observer, 2, 2);
        Observer.Expect('line before', '30000');
        Observer.Expect('line after', '30000');
        Observer.Expect('log', 'Q.V;Q.V.end;HR;HC;F(=>);R3;R2;R1;R3;F(=);R3;C3');
        Observer.Expect('info shown', 'changed');
        Observer.Expect('line after bin', '30000');
        Observer.Expect('log bin', '');
        Observer.Expect('stored', 'changed 1:/0/ 2:/0/ 3:/0/Z ');
        Observer.Verify();
    end;
}

codeunit 95973 "PG R7099 Log"
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
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}
