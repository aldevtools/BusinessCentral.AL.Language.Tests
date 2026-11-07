// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 96981, 96985, 96986; own pages 96980, 96982 to 96984; own pageextensions 96987 to 96990; log 96991; subscribers 96992
// Probe: a pageextension publishes an event with IncludeSender = true from its OnAfterGetRecord trigger and a subscriber takes `Sender: Page "..."`.
// Facts pinned (identical on BC 27.5, 28.5 and 29.0): the subscriber gets the page instance that runs the trigger. Through it the
//   subscriber and later code can call a base page procedure and an extension procedure; both read the live Rec of that page instance
//   (after the page moves to another row the held sender shows the new row) and the variables of that instance (marks set through the
//   held sender are seen at the next raise of the same page, a second open page has its own instance). Card, List, Document header and
//   Document lines part behave the same. A held sender still answers after the TestPage is closed (state of the last row).

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
        Observer.Expect('open', 'card|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;');
        Observer.Expect('goto K2', 'card|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;card|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;card|key=K2|rec=Second|ext=Second/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;');
        Observer.Verify();
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
        Observer.Expect('base', 'Second||LT PES Card Caption');
        Observer.Expect('ext', 'Second/ext|');
        Observer.Expect('base after marks', 'Second|B1|LT PES Card Caption');
        Observer.Expect('ext after marks', 'Second/ext|E1');
        Observer.Expect('base after goto K3', 'Third|B1|LT PES Card Caption');
        Observer.Expect('ext after goto K3', 'Third/ext|E1');
        Observer.Expect('log', 'card|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;card|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;card|key=K2|rec=Second|ext=Second/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;card|key=K1|rec=First|ext=First/ext|base_mark=B1|ext_mark=E1|caption=LT PES Card Caption;card|key=K2|rec=Second|ext=Second/ext|base_mark=B1|ext_mark=E1|caption=LT PES Card Caption;card|key=K3|rec=Third|ext=Third/ext|base_mark=B1|ext_mark=E1|caption=LT PES Card Caption;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCardBase(var Result: Text)
    var
        Log: Codeunit "LT PES Log";
    begin
        Result := Log.CardBase();
    end;

    [TryFunction]
    local procedure TryCardExt(var Result: Text)
    var
        Log: Codeunit "LT PES Log";
    begin
        Result := Log.CardExt();
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
        if TryCardBase(Result) then
            Observer.Observe('base after close', Result)
        else
            Observer.ObserveError('base after close');
        if TryCardExt(Result) then
            Observer.Observe('ext after close', Result)
        else
            Observer.ObserveError('ext after close');
        Observer.Expect('base after close', 'Second||LT PES Card Caption');
        Observer.Expect('ext after close', 'Second/ext|');
        Observer.Verify();
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
        Observer.Expect('log', 'card|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;card|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;card|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;card|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;card|key=K2|rec=Second|ext=Second/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;card|key=K3|rec=Third|ext=Third/ext|base_mark=|ext_mark=|caption=LT PES Card Caption;');
        Observer.Expect('held is second', 'Third||LT PES Card Caption#Third/ext|');
        Observer.Expect('held after first moves', 'Second|FIRST|LT PES Card Caption#Second/ext|FIRST-EXT');
        Observer.Verify();
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
        Observer.Expect('open', 'list|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=;list|key=K2|rec=Second|ext=Second/ext|base_mark=|ext_mark=;list|key=K3|rec=Third|ext=Third/ext|base_mark=|ext_mark=;list|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=;');
        Observer.Expect('first', 'list|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=;list|key=K2|rec=Second|ext=Second/ext|base_mark=|ext_mark=;list|key=K3|rec=Third|ext=Third/ext|base_mark=|ext_mark=;list|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=;');
        Observer.Expect('held base', 'First|');
        Observer.Expect('held ext', 'First/ext|');
        Observer.Expect('next', 'list|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=;list|key=K2|rec=Second|ext=Second/ext|base_mark=|ext_mark=;list|key=K3|rec=Third|ext=Third/ext|base_mark=|ext_mark=;list|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=;');
        Observer.Expect('held base after next', 'First|LB');
        Observer.Expect('held ext after next', 'First/ext|LE');
        Observer.Expect('next 2', 'list|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=;list|key=K2|rec=Second|ext=Second/ext|base_mark=|ext_mark=;list|key=K3|rec=Third|ext=Third/ext|base_mark=|ext_mark=;list|key=K1|rec=First|ext=First/ext|base_mark=|ext_mark=;');
        Observer.Expect('held base after next 2', 'First|LB');
        Observer.Verify();
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
        Observer.Expect('open and goto D1', 'head|no=D1|rec=Doc One|ext=Doc One/ext|base_mark=;line|doc=D1|line=10000|rec=Line A|ext=Line A/ext|base_mark=;line|doc=D1|line=20000|rec=Line B|ext=Line B/ext|base_mark=;line|doc=D1|line=10000|rec=Line A|ext=Line A/ext|base_mark=;head|no=D1|rec=Doc One|ext=Doc One/ext|base_mark=;');
        Observer.Expect('held head', 'Doc One||Doc One/ext');
        Observer.Expect('held lines', 'Line A||Line A/ext');
        Observer.Expect('lines next', '');
        Observer.Expect('held lines after next', 'Line A||Line A/ext');
        Observer.Expect('head next', 'head|no=D2|rec=Doc Two|ext=Doc Two/ext|base_mark=;line|doc=D2|line=10000|rec=Line C|ext=Line C/ext|base_mark=;');
        Observer.Expect('held head after next', 'Doc Two||Doc Two/ext');
        Observer.Expect('held lines after head next', 'Line C||Line C/ext');
        Observer.Verify();
    end;
}
