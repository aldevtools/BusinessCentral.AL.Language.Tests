// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-saverecord-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT QI SP *)
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a host card with a linked ListPart (SubPageLink, AutoSplitKey, DelayedInsert, as a document subform) and an unlinked ListPart:
//   (1) SetValue on a host control whose OnValidate calls CurrPage.SaveRecord() (the value changes, and the same value again), then the
//       same with Rec.Modify() instead and with neither: which host and part triggers run, in which order, with which Rec and xRec;
//   (2) a part row typed (New + SetValue) or an existing part row edited, then SetValue on a host control whose OnValidate counts and reads
//       the part table: is the part row saved before the host validates, after it, or not at all.
// Settles al-runtime-rs docs/probes-needed.md assumptions host-save-record-refreshes-linked-parts (Tests-ERM 134394, 134344) and
//   part-row-saved-before-host-set-value (Tests-ERM 134087).
// BC versions: 29 (27 and 28 by CI)

table 86830 "LT QI SP Head"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; SaveFld; Text[30]) { }
        field(3; ModFld; Text[30]) { }
        field(4; PlainFld; Text[30]) { }
        field(5; CountFld; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "LT QI SP Log";
    begin
        Log.Add('T.HeadModify(' + Rec."No." + ')');
    end;
}

table 86831 "LT QI SP Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Doc No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; "Doc No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT QI SP Log";
    begin
        Log.Add('T.LineInsert(' + Rec."Doc No." + '/' + Format(Rec."Line No.") + '|' + Rec.Descr + ')');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT QI SP Log";
    begin
        Log.Add('T.LineModify(' + Rec."Doc No." + '/' + Format(Rec."Line No.") + '|' + Rec.Descr + ')');
    end;
}

codeunit 86832 "LT QI SP Log"
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
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 86833 "LT QI SP Linked Part"
{
    PageType = ListPart;
    SourceTable = "LT QI SP Line";
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
                field(LineNoCtl; Rec."Line No.") { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('L.AGR(' + Rec."Doc No." + '/' + Format(Rec."Line No.") + '|' + Rec.Descr + ' x=' + xRec."Doc No." + '/' + Format(xRec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('L.AGCR(' + Rec."Doc No." + '/' + Format(Rec."Line No.") + '|' + Rec.Descr + ' x=' + xRec."Doc No." + '/' + Format(xRec."Line No.") + ')');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('L.NEW(' + Rec."Doc No." + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('L.INS(' + Rec."Doc No." + '/' + Format(Rec."Line No.") + '|' + Rec.Descr + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('L.MOD(' + Rec."Doc No." + '/' + Format(Rec."Line No.") + '|' + Rec.Descr + ' x=' + xRec.Descr + ')');
    end;

    var
        Log: Codeunit "LT QI SP Log";
}

page 86834 "LT QI SP Free Part"
{
    PageType = ListPart;
    SourceTable = "LT QI SP Line";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('U.AGR(' + Rec."Doc No." + '/' + Format(Rec."Line No.") + ' x=' + xRec."Doc No." + '/' + Format(xRec."Line No.") + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('U.AGCR(' + Rec."Doc No." + '/' + Format(Rec."Line No.") + ' x=' + xRec."Doc No." + '/' + Format(xRec."Line No.") + ')');
    end;

    var
        Log: Codeunit "LT QI SP Log";
}

page 86835 "LT QI SP Doc"
{
    PageType = Document;
    SourceTable = "LT QI SP Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(SaveCtl; Rec.SaveFld)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('H.V(save ' + Rec.SaveFld + ' x=' + xRec.SaveFld + ')');
                        CurrPage.SaveRecord();
                        Log.Add('H.V(save done)');
                    end;
                }
                field(ModCtl; Rec.ModFld)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('H.V(mod ' + Rec.ModFld + ' x=' + xRec.ModFld + ')');
                        Rec.Modify();
                        Log.Add('H.V(mod done)');
                    end;
                }
                field(PlainCtl; Rec.PlainFld)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('H.V(plain ' + Rec.PlainFld + ' x=' + xRec.PlainFld + ')');
                    end;
                }
                field(CountCtl; Rec.CountFld)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('H.V(count ' + LinesOf(Rec."No.") + ')');
                    end;
                }
            }
            part(Lines; "LT QI SP Linked Part")
            {
                ApplicationArea = All;
                SubPageLink = "Doc No." = field("No.");
            }
            part(Free; "LT QI SP Free Part")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Log.Add('H.AGR(' + Rec."No." + ' x=' + xRec."No." + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('H.AGCR(' + Rec."No." + ' x=' + xRec."No." + ')');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('H.MOD(' + Rec."No." + ')');
    end;

    local procedure LinesOf(DocNo: Code[20]): Text
    var
        Line: Record "LT QI SP Line";
        Result: Text;
    begin
        Line.SetRange("Doc No.", DocNo);
        Result := Format(Line.Count());
        if Line.FindSet() then
            repeat
                Result += ' ' + Format(Line."Line No.") + '=' + Line.Descr;
            until Line.Next() = 0;
        exit(Result);
    end;

    var
        Log: Codeunit "LT QI SP Log";
}

codeunit 86836 "LT QI SP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Head: Record "LT QI SP Head";
        Line: Record "LT QI SP Line";
        Log: Codeunit "LT QI SP Log";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
        Head.Init();
        Head."No." := 'D1';
        Head.SaveFld := 'a';
        Head.ModFld := 'a';
        Head.PlainFld := 'a';
        Head.Insert();
        Head."No." := 'D2';
        Head.Insert();
        AddLine('D1', 10000, 'd1 l1');
        AddLine('D1', 20000, 'd1 l2');
        AddLine('D2', 10000, 'd2 l1');
        Log.Reset();
    end;

    local procedure AddLine(DocNo: Code[20]; LineNo: Integer; Descr: Text[30])
    var
        Line: Record "LT QI SP Line";
    begin
        Line.Init();
        Line."Doc No." := DocNo;
        Line."Line No." := LineNo;
        Line.Descr := Descr;
        Line.Insert();
    end;

    local procedure Stored(DocNo: Code[20]): Text
    var
        Line: Record "LT QI SP Line";
        Result: Text;
    begin
        Line.SetRange("Doc No.", DocNo);
        Result := Format(Line.Count());
        if Line.FindSet() then
            repeat
                Result += ' ' + Format(Line."Line No.") + '=' + Line.Descr;
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure HeadValues(): Text
    var
        Head: Record "LT QI SP Head";
    begin
        Head.Get('D1');
        exit(Head.SaveFld + '|' + Head.ModFld + '|' + Head.PlainFld + '|' + Head.CountFld);
    end;

    // ---- (1) host OnValidate with CurrPage.SaveRecord / Rec.Modify / neither: which part triggers run ----

    [Test]
    procedure QI_HostSaveRecord_ChangedValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI SP Log";
        Doc: TestPage "LT QI SP Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('open', Log.Take());
        Doc.SaveCtl.SetValue('b');
        Observer.Observe('setvalue', Log.Take());
        Observer.Observe('stored', HeadValues());
        Observer.Observe('part-descr', Doc.Lines.DescrCtl.Value());
        Observer.Observe('after-part-read', Log.Take());
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('stored-after-close', HeadValues());
        Observer.Expect('open', 'H.AGR(D1 x=);H.AGCR(D1 x=);L.AGR(D1/10000|d1 l1 x=/0);L.AGR(D1/20000|d1 l2 x=D1/10000);L.AGR(D1/10000|d1 l1 x=D1/20000);L.AGR(D1/10000|d1 l1 x=D1/10000);L.AGCR(D1/10000|d1 l1 x=D1/0);U.AGR(D1/10000 x=/0);U.AGR(D1/20000 x=D1/10000);U.AGR(D2/10000 x=D1/20000);U.AGR(D1/10000 x=D2/10000);U.AGR(D1/10000 x=D1/10000);U.AGCR(D1/10000 x=/0);');
        Observer.Expect('setvalue', 'H.V(save b x=a);H.MOD(D1);T.HeadModify(D1);H.V(save done);L.AGR(D1/10000|d1 l1 x=D1/10000);L.AGR(D1/20000|d1 l2 x=D1/10000);L.AGR(D1/10000|d1 l1 x=D1/20000);L.AGR(D1/10000|d1 l1 x=D1/10000);L.AGCR(D1/10000|d1 l1 x=D1/10000);U.AGR(D1/10000 x=D1/10000);U.AGR(D1/20000 x=D1/10000);U.AGR(D2/10000 x=D1/20000);U.AGR(D1/10000 x=D2/10000);U.AGR(D1/10000 x=D1/10000);U.AGCR(D1/10000 x=D1/10000);');
        Observer.Expect('stored', 'b|a|a|');
        Observer.Expect('part-descr', 'd1 l1');
        Observer.Expect('after-part-read', '');
        Observer.Expect('close', '');
        Observer.Expect('stored-after-close', 'b|a|a|');
        Observer.Verify();
    end;

    [Test]
    procedure QI_HostSaveRecord_SameValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI SP Log";
        Doc: TestPage "LT QI SP Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('open', Log.Take());
        Doc.SaveCtl.SetValue('a');
        Observer.Observe('setvalue', Log.Take());
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('open', 'H.AGR(D1 x=);H.AGCR(D1 x=);L.AGR(D1/10000|d1 l1 x=/0);L.AGR(D1/20000|d1 l2 x=D1/10000);L.AGR(D1/10000|d1 l1 x=D1/20000);L.AGR(D1/10000|d1 l1 x=D1/10000);L.AGCR(D1/10000|d1 l1 x=D1/0);U.AGR(D1/10000 x=/0);U.AGR(D1/20000 x=D1/10000);U.AGR(D2/10000 x=D1/20000);U.AGR(D1/10000 x=D2/10000);U.AGR(D1/10000 x=D1/10000);U.AGCR(D1/10000 x=/0);');
        Observer.Expect('setvalue', 'H.V(save a x=a);H.V(save done);L.AGR(D1/10000|d1 l1 x=D1/10000);L.AGR(D1/20000|d1 l2 x=D1/10000);L.AGR(D1/10000|d1 l1 x=D1/20000);L.AGR(D1/10000|d1 l1 x=D1/10000);L.AGCR(D1/10000|d1 l1 x=D1/10000);U.AGR(D1/10000 x=D1/10000);U.AGR(D1/20000 x=D1/10000);U.AGR(D2/10000 x=D1/20000);U.AGR(D1/10000 x=D2/10000);U.AGR(D1/10000 x=D1/10000);U.AGCR(D1/10000 x=D1/10000);');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QI_HostSaveRecord_PartMovedToSecondRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI SP Log";
        Doc: TestPage "LT QI SP Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('part-next', Format(Doc.Lines.Next()));
        Observer.Observe('part-row', Doc.Lines.LineNoCtl.Value());
        Observer.Observe('open-and-next', Log.Take());
        Doc.SaveCtl.SetValue('b');
        Observer.Observe('setvalue', Log.Take());
        Observer.Observe('part-row-after', Doc.Lines.LineNoCtl.Value());
        Observer.Observe('after-part-read', Log.Take());
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Expect('part-next', 'Yes');
        Observer.Expect('part-row', '20000');
        Observer.Expect('open-and-next', 'H.AGR(D1 x=);H.AGCR(D1 x=);L.AGR(D1/10000|d1 l1 x=/0);L.AGR(D1/20000|d1 l2 x=D1/10000);L.AGR(D1/10000|d1 l1 x=D1/20000);L.AGR(D1/10000|d1 l1 x=D1/10000);L.AGCR(D1/10000|d1 l1 x=D1/0);U.AGR(D1/10000 x=/0);U.AGR(D1/20000 x=D1/10000);U.AGR(D2/10000 x=D1/20000);U.AGR(D1/10000 x=D2/10000);U.AGR(D1/10000 x=D1/10000);U.AGCR(D1/10000 x=/0);L.AGR(D1/20000|d1 l2 x=D1/10000);L.AGR(D1/20000|d1 l2 x=D1/20000);L.AGCR(D1/20000|d1 l2 x=D1/10000);');
        Observer.Expect('setvalue', 'H.V(save b x=a);H.MOD(D1);T.HeadModify(D1);H.V(save done);L.AGR(D1/20000|d1 l2 x=D1/20000);L.AGR(D1/10000|d1 l1 x=D1/20000);L.AGR(D1/20000|d1 l2 x=D1/10000);L.AGR(D1/20000|d1 l2 x=D1/20000);L.AGCR(D1/20000|d1 l2 x=D1/20000);U.AGR(D1/10000 x=D1/10000);U.AGR(D1/20000 x=D1/10000);U.AGR(D2/10000 x=D1/20000);U.AGR(D1/10000 x=D2/10000);U.AGR(D1/10000 x=D1/10000);U.AGCR(D1/10000 x=D1/10000);');
        Observer.Expect('part-row-after', '20000');
        Observer.Expect('after-part-read', '');
        Observer.Expect('close', '');
        Observer.Verify();
    end;

    [Test]
    procedure QI_HostModify_ChangedValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI SP Log";
        Doc: TestPage "LT QI SP Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('open', Log.Take());
        Doc.ModCtl.SetValue('b');
        Observer.Observe('setvalue', Log.Take());
        Observer.Observe('stored', HeadValues());
        Observer.Observe('part-descr', Doc.Lines.DescrCtl.Value());
        Observer.Observe('after-part-read', Log.Take());
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('stored-after-close', HeadValues());
        Observer.Expect('open', 'H.AGR(D1 x=);H.AGCR(D1 x=);L.AGR(D1/10000|d1 l1 x=/0);L.AGR(D1/20000|d1 l2 x=D1/10000);L.AGR(D1/10000|d1 l1 x=D1/20000);L.AGR(D1/10000|d1 l1 x=D1/10000);L.AGCR(D1/10000|d1 l1 x=D1/0);U.AGR(D1/10000 x=/0);U.AGR(D1/20000 x=D1/10000);U.AGR(D2/10000 x=D1/20000);U.AGR(D1/10000 x=D2/10000);U.AGR(D1/10000 x=D1/10000);U.AGCR(D1/10000 x=/0);');
        Observer.Expect('setvalue', 'H.V(mod b x=a);H.V(mod done);');
        Observer.Expect('stored', 'a|b|a|');
        Observer.Expect('part-descr', 'd1 l1');
        Observer.Expect('after-part-read', 'H.MOD(D1);T.HeadModify(D1);');
        Observer.Expect('close', '');
        Observer.Expect('stored-after-close', 'a|b|a|');
        Observer.Verify();
    end;

    [Test]
    procedure QI_HostPlain_ChangedValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI SP Log";
        Doc: TestPage "LT QI SP Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('open', Log.Take());
        Doc.PlainCtl.SetValue('b');
        Observer.Observe('setvalue', Log.Take());
        Observer.Observe('stored', HeadValues());
        Observer.Observe('part-descr', Doc.Lines.DescrCtl.Value());
        Observer.Observe('after-part-read', Log.Take());
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('stored-after-close', HeadValues());
        Observer.Expect('open', 'H.AGR(D1 x=);H.AGCR(D1 x=);L.AGR(D1/10000|d1 l1 x=/0);L.AGR(D1/20000|d1 l2 x=D1/10000);L.AGR(D1/10000|d1 l1 x=D1/20000);L.AGR(D1/10000|d1 l1 x=D1/10000);L.AGCR(D1/10000|d1 l1 x=D1/0);U.AGR(D1/10000 x=/0);U.AGR(D1/20000 x=D1/10000);U.AGR(D2/10000 x=D1/20000);U.AGR(D1/10000 x=D2/10000);U.AGR(D1/10000 x=D1/10000);U.AGCR(D1/10000 x=/0);');
        Observer.Expect('setvalue', 'H.V(plain b x=a);');
        Observer.Expect('stored', 'a|a|a|');
        Observer.Expect('part-descr', 'd1 l1');
        Observer.Expect('after-part-read', 'H.MOD(D1);T.HeadModify(D1);');
        Observer.Expect('close', '');
        Observer.Expect('stored-after-close', 'a|a|b|');
        Observer.Verify();
    end;

    // ---- (2) a pending part row, then SetValue on a host control ----

    [Test]
    procedure QI_PartNewRow_ThenHostSetValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI SP Log";
        Doc: TestPage "LT QI SP Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.Lines.Last();
        Doc.Lines.New();
        Doc.Lines.DescrCtl.SetValue('typed');
        Observer.Observe('stored-before', Stored('D1'));
        Log.Take();
        Doc.CountCtl.SetValue('x');
        Observer.Observe('setvalue', Log.Take());
        Observer.Observe('stored-after', Stored('D1'));
        Observer.Observe('part-descr', Doc.Lines.DescrCtl.Value());
        Observer.Observe('after-part-read', Log.Take());
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('stored-after-close', Stored('D1'));
        Observer.Expect('stored-before', '2 10000=d1 l1 20000=d1 l2');
        Observer.Expect('setvalue', 'L.INS(D1/30000|typed);T.LineInsert(D1/30000|typed);U.AGR(D1/30000 x=D1/10000);U.AGR(D1/30000 x=D1/30000);U.AGCR(D1/30000 x=/0);H.V(count 3 10000=d1 l1 20000=d1 l2 30000=typed);');
        Observer.Expect('stored-after', '3 10000=d1 l1 20000=d1 l2 30000=typed');
        Observer.Expect('part-descr', 'typed');
        Observer.Expect('after-part-read', '');
        Observer.Expect('close', 'H.MOD(D1);T.HeadModify(D1);U.AGR(D1/10000 x=D1/30000);');
        Observer.Expect('stored-after-close', '3 10000=d1 l1 20000=d1 l2 30000=typed');
        Observer.Verify();
    end;

    [Test]
    procedure QI_PartNewRowUntouched_ThenHostSetValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI SP Log";
        Doc: TestPage "LT QI SP Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.Lines.Last();
        Doc.Lines.New();
        Log.Take();
        Doc.CountCtl.SetValue('x');
        Observer.Observe('setvalue', Log.Take());
        Observer.Observe('stored-after', Stored('D1'));
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('stored-after-close', Stored('D1'));
        Observer.Expect('setvalue', 'H.V(count 2 10000=d1 l1 20000=d1 l2);');
        Observer.Expect('stored-after', '2 10000=d1 l1 20000=d1 l2');
        Observer.Expect('close', 'H.MOD(D1);T.HeadModify(D1);');
        Observer.Expect('stored-after-close', '2 10000=d1 l1 20000=d1 l2');
        Observer.Verify();
    end;

    [Test]
    procedure QI_PartEditedRow_ThenHostSetValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI SP Log";
        Doc: TestPage "LT QI SP Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.Lines.First();
        Doc.Lines.DescrCtl.SetValue('edited');
        Observer.Observe('stored-before', Stored('D1'));
        Log.Take();
        Doc.CountCtl.SetValue('x');
        Observer.Observe('setvalue', Log.Take());
        Observer.Observe('stored-after', Stored('D1'));
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('stored-after-close', Stored('D1'));
        Observer.Expect('stored-before', '2 10000=d1 l1 20000=d1 l2');
        Observer.Expect('setvalue', 'L.MOD(D1/10000|edited x=d1 l1);T.LineModify(D1/10000|edited);U.AGR(D1/10000 x=D1/10000);U.AGCR(D1/10000 x=/0);H.V(count 2 10000=edited 20000=d1 l2);');
        Observer.Expect('stored-after', '2 10000=edited 20000=d1 l2');
        Observer.Expect('close', 'H.MOD(D1);T.HeadModify(D1);');
        Observer.Expect('stored-after-close', '2 10000=edited 20000=d1 l2');
        Observer.Verify();
    end;

    [Test]
    procedure QI_PartNewRow_ThenHostSaveRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QI SP Log";
        Doc: TestPage "LT QI SP Doc";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.Lines.Last();
        Doc.Lines.New();
        Doc.Lines.DescrCtl.SetValue('typed');
        Log.Take();
        Doc.SaveCtl.SetValue('b');
        Observer.Observe('setvalue', Log.Take());
        Observer.Observe('stored-after', Stored('D1'));
        Doc.Close();
        Observer.Observe('close', Log.Take());
        Observer.Observe('stored-after-close', Stored('D1'));
        Observer.Expect('setvalue', 'L.INS(D1/30000|typed);T.LineInsert(D1/30000|typed);U.AGR(D1/30000 x=D1/10000);U.AGR(D1/30000 x=D1/30000);U.AGCR(D1/30000 x=/0);H.V(save b x=a);H.MOD(D1);T.HeadModify(D1);H.V(save done);L.AGR(D1/30000|typed x=D1/20000);L.AGR(D1/20000|d1 l2 x=D1/30000);L.AGR(D1/10000|d1 l1 x=D1/20000);L.AGR(D1/30000|typed x=D1/10000);L.AGR(D1/30000|typed x=D1/30000);L.AGCR(D1/30000|typed x=D1/30000);U.AGR(D1/10000 x=D1/30000);U.AGR(D1/10000 x=D1/10000);U.AGR(D1/20000 x=D1/10000);U.AGR(D1/30000 x=D1/20000);U.AGR(D2/10000 x=D1/30000);U.AGR(D1/10000 x=D2/10000);U.AGR(D1/10000 x=D1/10000);U.AGCR(D1/10000 x=D1/10000);');
        Observer.Expect('stored-after', '3 10000=d1 l1 20000=d1 l2 30000=typed');
        Observer.Expect('close', '');
        Observer.Expect('stored-after-close', '3 10000=d1 l1 20000=d1 l2 30000=typed');
        Observer.Verify();
    end;
}
