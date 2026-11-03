// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-pagehandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); declares table 74032, pages 74033-74035
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: [PageHandler] and [ModalPageHandler] procedures whose first parameter is a Page (not a TestPage): what the handler is handed (GetRecord, Close, members), and which of several such handlers BC binds when a test names two of them for different pages (Page.Run / Page.RunModal in either order, list order of HandlerFunctions)
// BC versions: 29 (27 and 28 by CI)

table 74032 "LT P133 Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Grp; Code[10]) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 74033 "LT P133 List A"
{
    PageType = List;
    SourceTable = "LT P133 Row";
    ApplicationArea = All;
    Caption = 'LT P133 List A Caption';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
            }
        }
    }
}

page 74034 "LT P133 Card B"
{
    PageType = Card;
    SourceTable = "LT P133 Row";
    ApplicationArea = All;
    Caption = 'LT P133 Card B Caption';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
            }
        }
    }
}

page 74035 "LT P133 List C"
{
    PageType = List;
    SourceTable = "LT P133 Row";
    ApplicationArea = All;
    Caption = 'LT P133 List C Caption';

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
}

codeunit 74036 "LT P133 Page Handlers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Seen: Text;
        ResponseToGive: Action;

    local procedure Seed()
    var
        Row: Record "LT P133 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Grp := 'G1';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Grp := 'G2';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'three';
        Row.Grp := 'G1';
        Row.Insert();
        Seen := '';
        ResponseToGive := Action::LookupOK;
    end;

    // ---- handlers: non-modal, Page typed ----

    [PageHandler]
    procedure PhCard(var P: Page "LT P133 Card B")
    var
        Row: Record "LT P133 Row";
    begin
        P.GetRecord(Row);
        Seen += 'PhCard:' + Format(Row.Id) + '/' + Row.Name + ';';
    end;

    [PageHandler]
    procedure PhList(var P: Page "LT P133 List A")
    var
        Row: Record "LT P133 Row";
    begin
        P.GetRecord(Row);
        Seen += 'PhList:' + Format(Row.Id) + '/' + Row.Name + ';';
    end;

    [PageHandler]
    procedure PhCardClose(var P: Page "LT P133 Card B")
    begin
        Seen += 'PhCardClose:before;';
        P.Close();
        Seen += 'PhCardClose:after;';
    end;

    [TryFunction]
    local procedure TryCaption(var P: Page "LT P133 Card B"; var Res: Text)
    begin
        Res := P.Caption;
    end;

    [TryFunction]
    local procedure TryEditable(var P: Page "LT P133 Card B"; var Res: Text)
    begin
        Res := Format(P.Editable());
    end;

    [TryFunction]
    local procedure TryLookupMode(var P: Page "LT P133 Card B"; var Res: Text)
    begin
        Res := Format(P.LookupMode());
    end;

    [TryFunction]
    local procedure TryObjectId(var P: Page "LT P133 Card B"; var Res: Text)
    begin
        Res := P.ObjectId(false);
    end;

    [TryFunction]
    local procedure TryObjectIdTrue(var P: Page "LT P133 Card B"; var Res: Text)
    begin
        Res := P.ObjectId(true);
    end;

    [PageHandler]
    procedure PhCardMembers(var P: Page "LT P133 Card B")
    var
        Res: Text;
    begin
        if TryCaption(P, Res) then
            Seen += 'caption=' + Res + ';'
        else
            Seen += 'caption err=' + GetLastErrorText() + ';';
        if TryEditable(P, Res) then
            Seen += 'editable=' + Res + ';'
        else
            Seen += 'editable err=' + GetLastErrorText() + ';';
        if TryLookupMode(P, Res) then
            Seen += 'lookupmode=' + Res + ';'
        else
            Seen += 'lookupmode err=' + GetLastErrorText() + ';';
        if TryObjectId(P, Res) then
            Seen += 'objectid=' + Res + ';'
        else
            Seen += 'objectid err=' + GetLastErrorText() + ';';
        if TryObjectIdTrue(P, Res) then
            Seen += 'objectidtrue=' + Res + ';'
        else
            Seen += 'objectidtrue err=' + GetLastErrorText() + ';';
    end;

    [PageHandler]
    procedure PhCardSetRecord(var P: Page "LT P133 Card B")
    var
        Row: Record "LT P133 Row";
        Other: Record "LT P133 Row";
    begin
        P.GetRecord(Row);
        Seen += 'before=' + Format(Row.Id) + ';';
        Other.Get(3);
        P.SetRecord(Other);
        Clear(Row);
        P.GetRecord(Row);
        Seen += 'after=' + Format(Row.Id) + ';';
    end;

    [PageHandler]
    procedure PhListFilteredRow(var P: Page "LT P133 List A")
    var
        Row: Record "LT P133 Row";
    begin
        Row.SetRange(Id, 99);
        P.GetRecord(Row);
        Seen += 'row=' + Format(Row.Id) + '/' + Row.Name + ';filters=[' + Row.GetFilters() + '];';
    end;

    // ---- handlers: modal, Page typed ----

    [ModalPageHandler]
    procedure MhList(var P: Page "LT P133 List A"; var Response: Action)
    var
        Row: Record "LT P133 Row";
    begin
        P.GetRecord(Row);
        Seen += 'MhList:' + Format(Row.Id) + '/' + Row.Name + ';';
        Response := ResponseToGive;
    end;

    [ModalPageHandler]
    procedure MhCard(var P: Page "LT P133 Card B"; var Response: Action)
    var
        Row: Record "LT P133 Row";
    begin
        P.GetRecord(Row);
        Seen += 'MhCard:' + Format(Row.Id) + '/' + Row.Name + ';';
        Response := ResponseToGive;
    end;

    [ModalPageHandler]
    procedure MhListC(var P: Page "LT P133 List C"; var Response: Action)
    var
        Row: Record "LT P133 Row";
    begin
        P.GetRecord(Row);
        Seen += 'MhListC:' + Format(Row.Id) + '/' + Row.Name + ';';
        Response := ResponseToGive;
    end;

    [ModalPageHandler]
    procedure MhListTestPage(var P: TestPage "LT P133 List C")
    begin
        Seen += 'MhListTestPage;';
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure MhCardNoRead(var P: Page "LT P133 Card B"; var Response: Action)
    begin
        Seen += 'MhCardNoRead;';
        Response := ResponseToGive;
    end;

    // ---- tests: one Page typed [PageHandler] ----

    [Test]
    [HandlerFunctions('PhCard')]
    procedure P133_PageHandler_PageTyped_GetRecord_WithRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(2);
        Page.Run(Page::"LT P133 Card B", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'PhCard:2/two;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhCard')]
    procedure P133_PageHandler_PageTyped_GetRecord_NoRecordGiven()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Page.Run(Page::"LT P133 Card B");
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'PhCard:0/;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhList')]
    procedure P133_PageHandler_PageTyped_List_WithAndWithoutRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(3);
        Page.Run(Page::"LT P133 List A", Row);
        Observer.Observe('with record', Seen);
        Seen := '';
        Page.Run(Page::"LT P133 List A");
        Observer.Observe('without record', Seen);
        Seen := '';
        Row.Reset();
        Row.SetRange(Grp, 'G2');
        Page.Run(Page::"LT P133 List A", Row);
        Observer.Observe('filtered record', Seen);
        Observer.Expect('with record', 'PhList:3/three;');
        Observer.Expect('without record', 'PhList:0/;');
        Observer.Expect('filtered record', 'PhList:3/three;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhCardClose')]
    procedure P133_PageHandler_PageTyped_Close()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        Page.Run(Page::"LT P133 Card B", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'PhCardClose:before;PhCardClose:after;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhCardMembers')]
    procedure P133_PageHandler_PageTyped_Members()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        Page.Run(Page::"LT P133 Card B", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'caption=LT P133 Card B Caption;editable=Yes;lookupmode=No;objectid=Page 74034;objectidtrue=Page LT P133 Card B Caption;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhCardSetRecord')]
    procedure P133_PageHandler_PageTyped_SetRecordThenGetRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        Page.Run(Page::"LT P133 Card B", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'before=1;after=3;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhListFilteredRow')]
    procedure P133_PageHandler_PageTyped_GetRecordIntoFilteredRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(2);
        Page.Run(Page::"LT P133 List A", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'row=2/two;filters=[Id: 99];');
        Observer.Verify();
    end;

    // ---- tests: two Page typed [PageHandler]s for different pages ----

    [Test]
    [HandlerFunctions('PhCard,PhList')]
    procedure P133_TwoPageHandlers_CardThenList()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        Page.Run(Page::"LT P133 Card B", Row);
        Row.Get(2);
        Page.Run(Page::"LT P133 List A", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'PhCard:1/one;PhList:2/two;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhList,PhCard')]
    procedure P133_TwoPageHandlers_ListThenCard_ListedInOtherOrder()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        Page.Run(Page::"LT P133 Card B", Row);
        Row.Get(2);
        Page.Run(Page::"LT P133 List A", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'PhCard:1/one;PhList:2/two;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhCard,PhList')]
    procedure P133_TwoPageHandlers_PageRunTwice_SamePageTwice()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        Page.Run(Page::"LT P133 Card B", Row);
        Row.Get(3);
        Page.Run(Page::"LT P133 Card B", Row);
        Page.Run(Page::"LT P133 List A", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'PhCard:1/one;PhCard:3/three;PhList:3/three;');
        Observer.Verify();
    end;

    // ---- tests: one Page typed [ModalPageHandler] ----

    [Test]
    [HandlerFunctions('MhCard')]
    procedure P133_ModalHandler_PageTyped_ResponsesOfCard()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(2);
        ResponseToGive := Action::LookupOK;
        Result := Page.RunModal(Page::"LT P133 Card B", Row);
        Observer.Observe('lookupok', Format(Result));
        ResponseToGive := Action::Cancel;
        Result := Page.RunModal(Page::"LT P133 Card B", Row);
        Observer.Observe('cancel', Format(Result));
        ResponseToGive := Action::OK;
        Result := Page.RunModal(Page::"LT P133 Card B", Row);
        Observer.Observe('ok', Format(Result));
        ResponseToGive := Action::LookupCancel;
        Result := Page.RunModal(Page::"LT P133 Card B", Row);
        Observer.Observe('lookupcancel', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('lookupok', 'LookupOK');
        Observer.Expect('cancel', 'Cancel');
        Observer.Expect('ok', 'OK');
        Observer.Expect('lookupcancel', 'LookupCancel');
        Observer.Expect('seen', 'MhCard:2/two;MhCard:2/two;MhCard:2/two;MhCard:2/two;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MhCardNoRead')]
    procedure P133_ModalHandler_PageTyped_NeverTouchesThePage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(2);
        ResponseToGive := Action::LookupOK;
        Result := Page.RunModal(Page::"LT P133 Card B", Row);
        Observer.Observe('result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('seen', 'MhCardNoRead;');
        Observer.Verify();
    end;

    // ---- tests: two Page typed [ModalPageHandler]s for different pages ----

    [Test]
    [HandlerFunctions('MhList,MhCard')]
    procedure P133_TwoModalHandlers_ListThenCard()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(1);
        Result := Page.RunModal(Page::"LT P133 List A", Row);
        Observer.Observe('list result', Format(Result));
        Row.Get(2);
        Result := Page.RunModal(Page::"LT P133 Card B", Row);
        Observer.Observe('card result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('list result', 'LookupOK');
        Observer.Expect('card result', 'LookupOK');
        Observer.Expect('seen', 'MhList:1/one;MhCard:2/two;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MhList,MhCard')]
    procedure P133_TwoModalHandlers_CardThenList()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(2);
        Result := Page.RunModal(Page::"LT P133 Card B", Row);
        Observer.Observe('card result', Format(Result));
        Row.Get(3);
        Result := Page.RunModal(Page::"LT P133 List A", Row);
        Observer.Observe('list result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('card result', 'LookupOK');
        Observer.Expect('list result', 'LookupOK');
        Observer.Expect('seen', 'MhCard:2/two;MhList:3/three;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MhCard,MhList')]
    procedure P133_TwoModalHandlers_ListedInOtherOrder_Cancel()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        ResponseToGive := Action::Cancel;
        Row.Get(1);
        Result := Page.RunModal(Page::"LT P133 List A", Row);
        Observer.Observe('list result', Format(Result));
        Result := Page.RunModal(Page::"LT P133 Card B", Row);
        Observer.Observe('card result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('list result', 'Cancel');
        Observer.Expect('card result', 'Cancel');
        Observer.Expect('seen', 'MhList:1/one;MhCard:1/one;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MhList,MhCard,MhListC')]
    procedure P133_ThreeModalHandlers_ThreePages()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(1);
        Result := Page.RunModal(Page::"LT P133 List C", Row);
        Observer.Observe('c result', Format(Result));
        Result := Page.RunModal(Page::"LT P133 Card B", Row);
        Observer.Observe('card result', Format(Result));
        Result := Page.RunModal(Page::"LT P133 List A", Row);
        Observer.Observe('a result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('c result', 'LookupOK');
        Observer.Expect('card result', 'LookupOK');
        Observer.Expect('a result', 'LookupOK');
        Observer.Expect('seen', 'MhListC:1/one;MhCard:1/one;MhList:1/one;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MhList,MhCard')]
    procedure P133_TwoModalHandlers_SamePageTwiceThenOther()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
    begin
        Seed();
        Row.Get(1);
        Page.RunModal(Page::"LT P133 List A", Row);
        Row.Get(2);
        Page.RunModal(Page::"LT P133 List A", Row);
        Page.RunModal(Page::"LT P133 Card B", Row);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'MhList:1/one;MhList:2/two;MhCard:2/two;');
        Observer.Verify();
    end;

    // ---- tests: a Page typed and a TestPage typed handler, and a Page and a modal handler ----

    [Test]
    [HandlerFunctions('MhListTestPage,MhCard')]
    procedure P133_MixedModalHandlers_TestPageList_PageCard()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(1);
        Result := Page.RunModal(Page::"LT P133 List C", Row);
        Observer.Observe('list result', Format(Result));
        Result := Page.RunModal(Page::"LT P133 Card B", Row);
        Observer.Observe('card result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('list result', 'LookupOK');
        Observer.Expect('card result', 'LookupOK');
        Observer.Expect('seen', 'MhListTestPage;MhCard:1/one;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhCard,MhList')]
    procedure P133_MixedKinds_PageHandlerAndModalHandler_BothPageTyped()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(2);
        Page.Run(Page::"LT P133 Card B", Row);
        Result := Page.RunModal(Page::"LT P133 List A", Row);
        Observer.Observe('modal result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('modal result', 'LookupOK');
        Observer.Expect('seen', 'PhCard:2/two;MhList:2/two;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PhCard,MhCard')]
    procedure P133_MixedKinds_SamePageUnderPageAndModalHandler()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P133 Row";
        Result: Action;
    begin
        Seed();
        Row.Get(2);
        Page.Run(Page::"LT P133 Card B", Row);
        Result := Page.RunModal(Page::"LT P133 Card B", Row);
        Observer.Observe('modal result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('modal result', 'LookupOK');
        Observer.Expect('seen', 'PhCard:2/two;MhCard:2/two;');
        Observer.Verify();
    end;
}
