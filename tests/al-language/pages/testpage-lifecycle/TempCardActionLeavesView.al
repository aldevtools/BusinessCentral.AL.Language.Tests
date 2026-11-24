// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 88083, log 88090, pages 88150-88155, test codeunit 88096
// Probe: written against BC on the corpus CI matrix and local BC 27.5, 28.5 and 29.0; every literal asserted below is what that tier produced.
// Facts: a Card over a temporary table with SourceTableView where(RowKind = const(7), Posted = const(false)),
//   InsertAllowed = false, RefreshOnActivate, a part and OnQueryClosePage exit(Rec.Posted), opened with Trap + Page.Run on one temporary row; an action
//   sets Posted (the row leaves the view), optionally closes the page or calls CurrPage.Update(false) (runner issue 7903). After the action: the
//   messages the page showed, the Id the TestPage shows, First(), and whether Close raises. Neighbors: the same actions from a page extension, the
//   page without part and OnQueryClosePage, the page over a database table, the page without SourceTableView.
// BC versions: all (CI)

table 88083 "TPL Tmp Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Posted; Boolean) { }
        field(3; RowKind; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 88151 "TPL Tmp Part"
{
    PageType = ListPart;
    SourceTable = "TPL Tmp Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

page 88150 "TPL Tmp Card"
{
    PageType = Card;
    SourceTable = "TPL Tmp Row";
    SourceTableTemporary = true;
    SourceTableView = where(RowKind = const(7), Posted = const(false));
    InsertAllowed = false;
    RefreshOnActivate = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
            }
            part(Related; "TPL Tmp Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PostRow)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                end;
            }
            action(PostAndClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                    CurrPage.Close();
                end;
            }
            action(PostUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(Rec.Posted);
    end;
}

page 88153 "TPL Tmp Card NoPart"
{
    PageType = Card;
    SourceTable = "TPL Tmp Row";
    SourceTableTemporary = true;
    SourceTableView = where(RowKind = const(7), Posted = const(false));
    InsertAllowed = false;
    RefreshOnActivate = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PostRow)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                end;
            }
            action(PostAndClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                    CurrPage.Close();
                end;
            }
            action(PostUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
        }
    }
}

page 88154 "TPL Tmp Card Db"
{
    PageType = Card;
    SourceTable = "TPL Tmp Row";
    SourceTableView = where(RowKind = const(7), Posted = const(false));
    InsertAllowed = false;
    RefreshOnActivate = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
            }
            part(Related; "TPL Tmp Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PostRow)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                end;
            }
            action(PostAndClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                    CurrPage.Close();
                end;
            }
            action(PostUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(Rec.Posted);
    end;
}

page 88155 "TPL Tmp Card NoView"
{
    PageType = Card;
    SourceTable = "TPL Tmp Row";
    SourceTableTemporary = true;
    InsertAllowed = false;
    RefreshOnActivate = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
            }
            part(Related; "TPL Tmp Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PostRow)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                end;
            }
            action(PostAndClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                    CurrPage.Close();
                end;
            }
            action(PostUpdateFalse)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(Rec.Posted);
    end;
}

pageextension 88152 "TPL Tmp Card Ext" extends "TPL Tmp Card"
{
    actions
    {
        addlast(Processing)
        {
            action(ExtPostRow)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                end;
            }
            action(ExtPostAndClose)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Posted := true;
                    Rec.Modify();
                    CurrPage.Close();
                end;
            }
        }
    }
}

codeunit 88090 "TPL Tmp Log"
{
    SingleInstance = true;

    var
        Buffer: Text;
        CurrentMode: Text;

    procedure Reset()
    begin
        Buffer := '';
        CurrentMode := '';
    end;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;

    procedure SetMode(NewMode: Text)
    begin
        CurrentMode := NewMode;
    end;

    procedure Mode(): Text
    begin
        exit(CurrentMode);
    end;
}

codeunit 88096 "TPL Temp Card Action"
{
    Subtype = Test;

    var
        Log: Codeunit "TPL Tmp Log";

    [Test]
    [HandlerFunctions('MessageLogger')]
    procedure TempCard_PostRow()
    var
        Row: Record "TPL Tmp Row" temporary;
        Stored: Record "TPL Tmp Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Tmp Card";
        Value: Text;
        Found: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Stored.DeleteAll();
        Row.Id := 1;
        Row.RowKind := 7;
        Row.Insert();
        P.Trap();
        Page.Run(Page::"TPL Tmp Card", Row);
        Observer.Observe('idBefore', P.IdF.Value());
        P.PostRow.Invoke();
        Observer.Observe('messages', Log.Take());
        if TryId_Card(P, Value) then
            Observer.Observe('id', Value)
        else
            Observer.ObserveError('id');
        if TryFirst_Card(P, Found) then
            Observer.Observe('first', Format(Found))
        else
            Observer.ObserveError('first');
        Observer.Observe('messagesFirst', Log.Take());
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('messagesClose', Log.Take());
        Message('end');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageLogger')]
    procedure TempCard_PostAndClose()
    var
        Row: Record "TPL Tmp Row" temporary;
        Stored: Record "TPL Tmp Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Tmp Card";
        Value: Text;
        Found: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Stored.DeleteAll();
        Row.Id := 1;
        Row.RowKind := 7;
        Row.Insert();
        P.Trap();
        Page.Run(Page::"TPL Tmp Card", Row);
        Observer.Observe('idBefore', P.IdF.Value());
        P.PostAndClose.Invoke();
        Observer.Observe('messages', Log.Take());
        if TryId_Card(P, Value) then
            Observer.Observe('id', Value)
        else
            Observer.ObserveError('id');
        if TryFirst_Card(P, Found) then
            Observer.Observe('first', Format(Found))
        else
            Observer.ObserveError('first');
        Observer.Observe('messagesFirst', Log.Take());
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('messagesClose', Log.Take());
        Message('end');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageLogger')]
    procedure TempCard_PostUpdateFalse()
    var
        Row: Record "TPL Tmp Row" temporary;
        Stored: Record "TPL Tmp Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Tmp Card";
        Value: Text;
        Found: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Stored.DeleteAll();
        Row.Id := 1;
        Row.RowKind := 7;
        Row.Insert();
        P.Trap();
        Page.Run(Page::"TPL Tmp Card", Row);
        Observer.Observe('idBefore', P.IdF.Value());
        P.PostUpdateFalse.Invoke();
        Observer.Observe('messages', Log.Take());
        if TryId_Card(P, Value) then
            Observer.Observe('id', Value)
        else
            Observer.ObserveError('id');
        if TryFirst_Card(P, Found) then
            Observer.Observe('first', Format(Found))
        else
            Observer.ObserveError('first');
        Observer.Observe('messagesFirst', Log.Take());
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('messagesClose', Log.Take());
        Message('end');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageLogger')]
    procedure TempCard_ExtPostRow()
    var
        Row: Record "TPL Tmp Row" temporary;
        Stored: Record "TPL Tmp Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Tmp Card";
        Value: Text;
        Found: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Stored.DeleteAll();
        Row.Id := 1;
        Row.RowKind := 7;
        Row.Insert();
        P.Trap();
        Page.Run(Page::"TPL Tmp Card", Row);
        Observer.Observe('idBefore', P.IdF.Value());
        P.ExtPostRow.Invoke();
        Observer.Observe('messages', Log.Take());
        if TryId_Card(P, Value) then
            Observer.Observe('id', Value)
        else
            Observer.ObserveError('id');
        if TryFirst_Card(P, Found) then
            Observer.Observe('first', Format(Found))
        else
            Observer.ObserveError('first');
        Observer.Observe('messagesFirst', Log.Take());
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('messagesClose', Log.Take());
        Message('end');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageLogger')]
    procedure TempCard_ExtPostAndClose()
    var
        Row: Record "TPL Tmp Row" temporary;
        Stored: Record "TPL Tmp Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Tmp Card";
        Value: Text;
        Found: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Stored.DeleteAll();
        Row.Id := 1;
        Row.RowKind := 7;
        Row.Insert();
        P.Trap();
        Page.Run(Page::"TPL Tmp Card", Row);
        Observer.Observe('idBefore', P.IdF.Value());
        P.ExtPostAndClose.Invoke();
        Observer.Observe('messages', Log.Take());
        if TryId_Card(P, Value) then
            Observer.Observe('id', Value)
        else
            Observer.ObserveError('id');
        if TryFirst_Card(P, Found) then
            Observer.Observe('first', Format(Found))
        else
            Observer.ObserveError('first');
        Observer.Observe('messagesFirst', Log.Take());
        if TryClose_Card(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('messagesClose', Log.Take());
        Message('end');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageLogger')]
    procedure TempCardNoPart_PostRow()
    var
        Row: Record "TPL Tmp Row" temporary;
        Stored: Record "TPL Tmp Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Tmp Card NoPart";
        Value: Text;
        Found: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Stored.DeleteAll();
        Row.Id := 1;
        Row.RowKind := 7;
        Row.Insert();
        P.Trap();
        Page.Run(Page::"TPL Tmp Card NoPart", Row);
        Observer.Observe('idBefore', P.IdF.Value());
        P.PostRow.Invoke();
        Observer.Observe('messages', Log.Take());
        if TryId_NoPart(P, Value) then
            Observer.Observe('id', Value)
        else
            Observer.ObserveError('id');
        if TryFirst_NoPart(P, Found) then
            Observer.Observe('first', Format(Found))
        else
            Observer.ObserveError('first');
        Observer.Observe('messagesFirst', Log.Take());
        if TryClose_NoPart(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('messagesClose', Log.Take());
        Message('end');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageLogger')]
    procedure DbCard_PostRow()
    var
        Row: Record "TPL Tmp Row";
        Stored: Record "TPL Tmp Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Tmp Card Db";
        Value: Text;
        Found: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Stored.DeleteAll();
        Row.DeleteAll();
        Row.Id := 1;
        Row.RowKind := 7;
        Row.Insert();
        P.Trap();
        Page.Run(Page::"TPL Tmp Card Db", Row);
        Observer.Observe('idBefore', P.IdF.Value());
        P.PostRow.Invoke();
        Observer.Observe('messages', Log.Take());
        if TryId_Db(P, Value) then
            Observer.Observe('id', Value)
        else
            Observer.ObserveError('id');
        if TryFirst_Db(P, Found) then
            Observer.Observe('first', Format(Found))
        else
            Observer.ObserveError('first');
        Observer.Observe('messagesFirst', Log.Take());
        if TryClose_Db(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('messagesClose', Log.Take());
        Message('end');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageLogger')]
    procedure TempCardNoPart_PostAndClose()
    var
        Row: Record "TPL Tmp Row" temporary;
        Stored: Record "TPL Tmp Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Tmp Card NoPart";
        Value: Text;
        Found: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Stored.DeleteAll();
        Row.Id := 1;
        Row.RowKind := 7;
        Row.Insert();
        P.Trap();
        Page.Run(Page::"TPL Tmp Card NoPart", Row);
        Observer.Observe('idBefore', P.IdF.Value());
        P.PostAndClose.Invoke();
        Observer.Observe('messages', Log.Take());
        if TryId_NoPart(P, Value) then
            Observer.Observe('id', Value)
        else
            Observer.ObserveError('id');
        if TryFirst_NoPart(P, Found) then
            Observer.Observe('first', Format(Found))
        else
            Observer.ObserveError('first');
        Observer.Observe('messagesFirst', Log.Take());
        if TryClose_NoPart(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('messagesClose', Log.Take());
        Message('end');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageLogger')]
    procedure DbCard_PostAndClose()
    var
        Row: Record "TPL Tmp Row";
        Stored: Record "TPL Tmp Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Tmp Card Db";
        Value: Text;
        Found: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Stored.DeleteAll();
        Row.DeleteAll();
        Row.Id := 1;
        Row.RowKind := 7;
        Row.Insert();
        P.Trap();
        Page.Run(Page::"TPL Tmp Card Db", Row);
        Observer.Observe('idBefore', P.IdF.Value());
        P.PostAndClose.Invoke();
        Observer.Observe('messages', Log.Take());
        if TryId_Db(P, Value) then
            Observer.Observe('id', Value)
        else
            Observer.ObserveError('id');
        if TryFirst_Db(P, Found) then
            Observer.Observe('first', Format(Found))
        else
            Observer.ObserveError('first');
        Observer.Observe('messagesFirst', Log.Take());
        if TryClose_Db(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('messagesClose', Log.Take());
        Message('end');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('MessageLogger')]
    procedure TempCardNoView_PostRow()
    var
        Row: Record "TPL Tmp Row" temporary;
        Stored: Record "TPL Tmp Row";
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Tmp Card NoView";
        Value: Text;
        Found: Boolean;
    begin
        Log.Reset();
        ClearLastError();
        Stored.DeleteAll();
        Row.Id := 1;
        Row.RowKind := 7;
        Row.Insert();
        P.Trap();
        Page.Run(Page::"TPL Tmp Card NoView", Row);
        Observer.Observe('idBefore', P.IdF.Value());
        P.PostRow.Invoke();
        Observer.Observe('messages', Log.Take());
        if TryId_NoView(P, Value) then
            Observer.Observe('id', Value)
        else
            Observer.ObserveError('id');
        if TryFirst_NoView(P, Found) then
            Observer.Observe('first', Format(Found))
        else
            Observer.ObserveError('first');
        Observer.Observe('messagesFirst', Log.Take());
        if TryClose_NoView(P) then
            Observer.Observe('close', 'ok')
        else
            Observer.ObserveError('close');
        Observer.Observe('messagesClose', Log.Take());
        Message('end');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryId_Card(var P: TestPage "TPL Tmp Card"; var Value: Text)
    begin
        Value := P.IdF.Value();
    end;

    [TryFunction]
    local procedure TryFirst_Card(var P: TestPage "TPL Tmp Card"; var Found: Boolean)
    begin
        Found := P.First();
    end;
    [TryFunction]
    local procedure TryClose_Card(var P: TestPage "TPL Tmp Card")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryId_NoPart(var P: TestPage "TPL Tmp Card NoPart"; var Value: Text)
    begin
        Value := P.IdF.Value();
    end;

    [TryFunction]
    local procedure TryFirst_NoPart(var P: TestPage "TPL Tmp Card NoPart"; var Found: Boolean)
    begin
        Found := P.First();
    end;
    [TryFunction]
    local procedure TryClose_NoPart(var P: TestPage "TPL Tmp Card NoPart")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryId_Db(var P: TestPage "TPL Tmp Card Db"; var Value: Text)
    begin
        Value := P.IdF.Value();
    end;

    [TryFunction]
    local procedure TryFirst_Db(var P: TestPage "TPL Tmp Card Db"; var Found: Boolean)
    begin
        Found := P.First();
    end;
    [TryFunction]
    local procedure TryClose_Db(var P: TestPage "TPL Tmp Card Db")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryId_NoView(var P: TestPage "TPL Tmp Card NoView"; var Value: Text)
    begin
        Value := P.IdF.Value();
    end;

    [TryFunction]
    local procedure TryFirst_NoView(var P: TestPage "TPL Tmp Card NoView"; var Found: Boolean)
    begin
        Found := P.First();
    end;
    [TryFunction]
    local procedure TryClose_NoView(var P: TestPage "TPL Tmp Card NoView")
    begin
        P.Close();
    end;

    [MessageHandler]
    procedure MessageLogger(Msg: Text[1024])
    begin
        Log.Add('message ' + Msg);
    end;
}
