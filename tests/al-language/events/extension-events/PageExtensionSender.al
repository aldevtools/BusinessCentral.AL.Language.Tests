// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 96981, 96985, 96986; own pages 96980, 96982 to 96984; own pageextensions 96987 to 96990; log 96991; subscribers 96992
// Probe: a pageextension publishes an event with IncludeSender = true from its OnAfterGetRecord trigger and a subscriber takes `Sender: Page "..."`.
// Draft: observation form (Finish), values are filled in from the CI run.

table 96981 "LT PES Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(Pri; PK) { Clustered = true; }
    }
}

table 96985 "LT PES DocHead"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; No; Code[10]) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(Pri; No) { Clustered = true; }
    }
}

table 96986 "LT PES DocLine"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; DocNo; Code[10]) { }
        field(2; LineNo; Integer) { }
        field(3; Descr; Text[30]) { }
    }
    keys
    {
        key(Pri; DocNo, LineNo) { Clustered = true; }
    }
}

page 96980 "LT PES Card"
{
    PageType = Card;
    SourceTable = "LT PES Row";
    UsageCategory = None;
    Caption = 'LT PES Card Caption';

    layout
    {
        area(Content)
        {
            field(PK; Rec.PK) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    var
        BaseMark: Text;

    procedure SetBaseMark(NewMark: Text)
    begin
        BaseMark := NewMark;
    end;

    procedure GetBaseMark(): Text
    begin
        exit(BaseMark);
    end;

    procedure GetRecName(): Text
    begin
        exit(Rec.Name);
    end;

    procedure GetCurrPageCaption(): Text
    begin
        exit(CurrPage.Caption);
    end;
}

pageextension 96987 "LT PES Card Ext" extends "LT PES Card"
{
    var
        ExtMark: Text;

    procedure SetExtMark(NewMark: Text)
    begin
        ExtMark := NewMark;
    end;

    procedure GetExtMark(): Text
    begin
        exit(ExtMark);
    end;

    procedure GetExtRecName(): Text
    begin
        exit(Rec.Name + '/ext');
    end;

    trigger OnAfterGetRecord()
    begin
        OnRowRead(Rec.PK);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRowRead(RowKey: Code[10])
    begin
    end;
}

page 96982 "LT PES List"
{
    PageType = List;
    SourceTable = "LT PES Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(PK; Rec.PK) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        BaseMark: Text;

    procedure SetBaseMark(NewMark: Text)
    begin
        BaseMark := NewMark;
    end;

    procedure GetBaseMark(): Text
    begin
        exit(BaseMark);
    end;

    procedure GetRecName(): Text
    begin
        exit(Rec.Name);
    end;
}

pageextension 96988 "LT PES List Ext" extends "LT PES List"
{
    var
        ExtMark: Text;

    procedure SetExtMark(NewMark: Text)
    begin
        ExtMark := NewMark;
    end;

    procedure GetExtMark(): Text
    begin
        exit(ExtMark);
    end;

    procedure GetExtRecName(): Text
    begin
        exit(Rec.Name + '/ext');
    end;

    trigger OnAfterGetRecord()
    begin
        OnRowRead(Rec.PK);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRowRead(RowKey: Code[10])
    begin
    end;
}

page 96984 "LT PES Doc Lines"
{
    PageType = ListPart;
    SourceTable = "LT PES DocLine";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(LineNo; Rec.LineNo) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    var
        BaseMark: Text;

    procedure SetBaseMark(NewMark: Text)
    begin
        BaseMark := NewMark;
    end;

    procedure GetBaseMark(): Text
    begin
        exit(BaseMark);
    end;

    procedure GetRecDescr(): Text
    begin
        exit(Rec.Descr);
    end;
}

pageextension 96990 "LT PES Doc Lines Ext" extends "LT PES Doc Lines"
{
    procedure GetExtRecDescr(): Text
    begin
        exit(Rec.Descr + '/ext');
    end;

    trigger OnAfterGetRecord()
    begin
        OnLineRead(Rec.DocNo, Rec.LineNo);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnLineRead(LineDocNo: Code[10]; LineNumber: Integer)
    begin
    end;
}

page 96983 "LT PES Doc"
{
    PageType = Document;
    SourceTable = "LT PES DocHead";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(No; Rec.No) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
            part(Lines; "LT PES Doc Lines")
            {
                ApplicationArea = All;
                SubPageLink = DocNo = field(No);
            }
        }
    }

    var
        BaseMark: Text;

    procedure SetBaseMark(NewMark: Text)
    begin
        BaseMark := NewMark;
    end;

    procedure GetBaseMark(): Text
    begin
        exit(BaseMark);
    end;

    procedure GetRecName(): Text
    begin
        exit(Rec.Name);
    end;
}

pageextension 96989 "LT PES Doc Ext" extends "LT PES Doc"
{
    procedure GetExtRecName(): Text
    begin
        exit(Rec.Name + '/ext');
    end;

    trigger OnAfterGetRecord()
    begin
        OnHeadRead(Rec.No);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnHeadRead(HeadNo: Code[10])
    begin
    end;
}

codeunit 96991 "LT PES Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];
        HeldCard: Page "LT PES Card";
        HeldList: Page "LT PES List";
        HeldDoc: Page "LT PES Doc";
        HeldLines: Page "LT PES Doc Lines";

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Text(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do
            Result += Line + ';';
        exit(Result);
    end;

    procedure HoldCard(Sender: Page "LT PES Card")
    begin
        HeldCard := Sender;
    end;

    procedure HoldList(Sender: Page "LT PES List")
    begin
        HeldList := Sender;
    end;

    procedure HoldDoc(Sender: Page "LT PES Doc")
    begin
        HeldDoc := Sender;
    end;

    procedure HoldLines(Sender: Page "LT PES Doc Lines")
    begin
        HeldLines := Sender;
    end;

    procedure CardBase(): Text
    begin
        exit(HeldCard.GetRecName() + '|' + HeldCard.GetBaseMark() + '|' + HeldCard.GetCurrPageCaption());
    end;

    procedure CardExt(): Text
    begin
        exit(HeldCard.GetExtRecName() + '|' + HeldCard.GetExtMark());
    end;

    procedure CardSetMarks(Base: Text; Ext: Text)
    begin
        HeldCard.SetBaseMark(Base);
        HeldCard.SetExtMark(Ext);
    end;

    procedure ListBase(): Text
    begin
        exit(HeldList.GetRecName() + '|' + HeldList.GetBaseMark());
    end;

    procedure ListExt(): Text
    begin
        exit(HeldList.GetExtRecName() + '|' + HeldList.GetExtMark());
    end;

    procedure ListSetMarks(Base: Text; Ext: Text)
    begin
        HeldList.SetBaseMark(Base);
        HeldList.SetExtMark(Ext);
    end;

    procedure DocBase(): Text
    begin
        exit(HeldDoc.GetRecName() + '|' + HeldDoc.GetBaseMark() + '|' + HeldDoc.GetExtRecName());
    end;

    procedure LinesBase(): Text
    begin
        exit(HeldLines.GetRecDescr() + '|' + HeldLines.GetBaseMark() + '|' + HeldLines.GetExtRecDescr());
    end;
}

codeunit 96992 "LT PES Subscribers"
{
    [EventSubscriber(ObjectType::Page, Page::"LT PES Card", 'OnRowRead', '', false, false)]
    local procedure OnCardRow(Sender: Page "LT PES Card"; RowKey: Code[10])
    var
        Log: Codeunit "LT PES Log";
    begin
        Log.HoldCard(Sender);
        Log.Add('card|key=' + RowKey + '|rec=' + Sender.GetRecName() + '|ext=' + Sender.GetExtRecName() + '|base_mark=' + Sender.GetBaseMark() + '|ext_mark=' + Sender.GetExtMark() + '|caption=' + Sender.GetCurrPageCaption());
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PES List", 'OnRowRead', '', false, false)]
    local procedure OnListRow(Sender: Page "LT PES List"; RowKey: Code[10])
    var
        Log: Codeunit "LT PES Log";
    begin
        Log.HoldList(Sender);
        Log.Add('list|key=' + RowKey + '|rec=' + Sender.GetRecName() + '|ext=' + Sender.GetExtRecName() + '|base_mark=' + Sender.GetBaseMark() + '|ext_mark=' + Sender.GetExtMark());
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PES Doc", 'OnHeadRead', '', false, false)]
    local procedure OnHeadRow(Sender: Page "LT PES Doc"; HeadNo: Code[10])
    var
        Log: Codeunit "LT PES Log";
    begin
        Log.HoldDoc(Sender);
        Log.Add('head|no=' + HeadNo + '|rec=' + Sender.GetRecName() + '|ext=' + Sender.GetExtRecName() + '|base_mark=' + Sender.GetBaseMark());
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT PES Doc Lines", 'OnLineRead', '', false, false)]
    local procedure OnLineRow(Sender: Page "LT PES Doc Lines"; LineDocNo: Code[10]; LineNumber: Integer)
    var
        Log: Codeunit "LT PES Log";
    begin
        Log.HoldLines(Sender);
        Log.Add('line|doc=' + LineDocNo + '|line=' + Format(LineNumber) + '|rec=' + Sender.GetRecDescr() + '|ext=' + Sender.GetExtRecDescr() + '|base_mark=' + Sender.GetBaseMark());
    end;
}

codeunit 96993 "LT PES Page Extension Sender"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure SeedRows()
    var
        Row: Record "LT PES Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'K1';
        Row.Name := 'First';
        Row.Insert();
        Row.PK := 'K2';
        Row.Name := 'Second';
        Row.Insert();
        Row.PK := 'K3';
        Row.Name := 'Third';
        Row.Insert();
    end;

    local procedure SeedDoc()
    var
        Head: Record "LT PES DocHead";
        Line: Record "LT PES DocLine";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head.Init();
        Head.No := 'D1';
        Head.Name := 'Doc One';
        Head.Insert();
        Head.No := 'D2';
        Head.Name := 'Doc Two';
        Head.Insert();
        Line.Init();
        Line.DocNo := 'D1';
        Line.LineNo := 10000;
        Line.Descr := 'Line A';
        Line.Insert();
        Line.LineNo := 20000;
        Line.Descr := 'Line B';
        Line.Insert();
        Line.DocNo := 'D2';
        Line.LineNo := 10000;
        Line.Descr := 'Line C';
        Line.Insert();
    end;

    [Test]
    procedure Card_SubscriberSeesSender()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PES Log";
        Card: TestPage "LT PES Card";
    begin
        SeedRows();
        Log.Reset();
        Card.OpenView();
        Observer.Observe('open', Log.Text());
        Card.GoToKey('K2');
        Observer.Observe('goto K2', Log.Text());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_HeldSender_CallsWhileOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PES Log";
        Card: TestPage "LT PES Card";
    begin
        SeedRows();
        Log.Reset();
        Card.OpenView();
        Card.GoToKey('K2');
        Observer.Observe('base', Log.CardBase());
        Observer.Observe('ext', Log.CardExt());
        Log.CardSetMarks('B1', 'E1');
        Observer.Observe('base after marks', Log.CardBase());
        Observer.Observe('ext after marks', Log.CardExt());
        Card.GoToKey('K3');
        Observer.Observe('base after goto K3', Log.CardBase());
        Observer.Observe('ext after goto K3', Log.CardExt());
        Observer.Observe('log', Log.Text());
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Card_HeldSender_AfterClose()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PES Log";
        Card: TestPage "LT PES Card";
        Result: Text;
    begin
        SeedRows();
        Log.Reset();
        Card.OpenView();
        Card.GoToKey('K2');
        Card.Close();
        asserterror Result := Log.CardBase();
        Observer.ObserveError('base after close');
        asserterror Result := Log.CardExt();
        Observer.ObserveError('ext after close');
        Observer.Finish();
    end;

    [Test]
    procedure Card_TwoPagesTwoSenders()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PES Log";
        First: TestPage "LT PES Card";
        Second: TestPage "LT PES Card";
    begin
        SeedRows();
        Log.Reset();
        First.OpenView();
        First.GoToKey('K1');
        Log.CardSetMarks('FIRST', 'FIRST-EXT');
        Second.OpenView();
        Second.GoToKey('K3');
        Observer.Observe('log', Log.Text());
        Observer.Observe('held is second', Log.CardBase() + '#' + Log.CardExt());
        First.GoToKey('K2');
        Observer.Observe('held after first moves', Log.CardBase() + '#' + Log.CardExt());
        Second.Close();
        First.Close();
        Observer.Finish();
    end;

    [Test]
    procedure List_SenderPerRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PES Log";
        ListPage: TestPage "LT PES List";
    begin
        SeedRows();
        Log.Reset();
        ListPage.OpenView();
        Observer.Observe('open', Log.Text());
        ListPage.First();
        Observer.Observe('first', Log.Text());
        Observer.Observe('held base', Log.ListBase());
        Observer.Observe('held ext', Log.ListExt());
        Log.ListSetMarks('LB', 'LE');
        ListPage.Next();
        Observer.Observe('next', Log.Text());
        Observer.Observe('held base after next', Log.ListBase());
        Observer.Observe('held ext after next', Log.ListExt());
        ListPage.Next();
        Observer.Observe('next 2', Log.Text());
        Observer.Observe('held base after next 2', Log.ListBase());
        ListPage.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Document_HeaderAndLinesSenders()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PES Log";
        Doc: TestPage "LT PES Doc";
    begin
        SeedDoc();
        Log.Reset();
        Doc.OpenView();
        Doc.GoToKey('D1');
        Observer.Observe('open and goto D1', Log.Text());
        Observer.Observe('held head', Log.DocBase());
        Observer.Observe('held lines', Log.LinesBase());
        Log.Reset();
        Doc.Lines.Next();
        Observer.Observe('lines next', Log.Text());
        Observer.Observe('held lines after next', Log.LinesBase());
        Log.Reset();
        Doc.Next();
        Observer.Observe('head next', Log.Text());
        Observer.Observe('held head after next', Log.DocBase());
        Observer.Observe('held lines after head next', Log.LinesBase());
        Doc.Close();
        Observer.Finish();
    end;
}
