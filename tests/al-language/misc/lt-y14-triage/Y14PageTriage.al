// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-class
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 91660-91661 and 91666, pages 91662, 91664 and 91667, codeunits 91663 and 91670
// Probe: observe probe (writer Y14, 2026-10-31, runtime asks from partner-app triage); every literal asserted below is what the BC service tier produced.
// Facts: (1) FindFirstField and Next on a list page taken with TestPage.Trap() after Page.Run, with a control whose value comes from a function that reads
//   a second table through the RecordId of a page-level record that is never inserted; the same page opened with OpenView is the reference.
//   (2) A Page-typed ModalPageHandler (and PageHandler) on a list page with a temporary source table that is filled by a procedure of the page:
//   the Action, which page triggers ran, and what GetRecord hands back. (3) Error('') in a table field OnValidate after a Confirm during
//   TestPage SetValue on a Card page (the lookup case is in Y14LookupNoRow.al).
// BC versions: 27, 28, 29

table 91660 "LT Y14 PG T"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Store; Text[20]) { }
        field(3; Note; Text[30]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

table 91661 "LT Y14 PG U"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Info; Text[30]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 91663 "LT Y14 PG Log"
{
    SingleInstance = true;

    var
        Text: Text;

    procedure Add(Entry: Text)
    begin
        Text += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Text;
        Text := '';
        exit(Result);
    end;
}

page 91662 "LT Y14 PG Expr"
{
    PageType = List;
    SourceTable = "LT Y14 PG T";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Store; Rec.Store) { ApplicationArea = All; }
                field(Info; Describe()) { ApplicationArea = All; }
            }
        }
    }

    var
        Link: Record "LT Y14 PG U";
        Log: Codeunit "LT Y14 PG Log";

    local procedure Describe(): Text
    var
        Other: Record "LT Y14 PG U";
    begin
        Log.Add('describe(' + Rec.Code + ')');
        if Other.Get(Link.RecordId) then
            exit(Other.Info);
        exit('none');
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('agr(' + Rec.Code + ')');
        Clear(Link);
        Link.Code := Rec.Code;
    end;
}

// A list over a temporary source table that a procedure of the page fills.
page 91664 "LT Y14 PG Temp"
{
    PageType = List;
    SourceTable = "LT Y14 PG T";
    SourceTableTemporary = true;
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Store; Rec.Store) { ApplicationArea = All; }
            }
        }
    }

    var
        CopyA: Record "LT Y14 PG T" temporary;
        CopyB: Record "LT Y14 PG T" temporary;
        CopyOnOpen: Boolean;
        Log: Codeunit "LT Y14 PG Log";

    procedure SetSourceTables(var TempA: Record "LT Y14 PG T" temporary; var TempB: Record "LT Y14 PG T" temporary; OnOpen: Boolean)
    begin
        CopyOnOpen := OnOpen;
        if OnOpen then begin
            CopyA.Copy(TempA, true);
            CopyB.Copy(TempB, true);
        end else begin
            Fill(TempA);
            Fill(TempB);
        end;
        Log.Add('set(' + Format(OnOpen) + ')');
    end;

    local procedure Fill(var Source: Record "LT Y14 PG T" temporary)
    begin
        if Source.FindSet() then
            repeat
                Rec := Source;
                Rec.Insert();
            until Source.Next() = 0;
    end;

    trigger OnOpenPage()
    begin
        Log.Add('open');
        if CopyOnOpen then begin
            Fill(CopyA);
            Fill(CopyB);
        end;
    end;
}

table 91666 "LT Y14 PG C"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT Y14 PG Log";
            begin
                Log.Add('validate(' + Name + ')');
                if Name = 'bad' then begin
                    if Confirm('Really change?') then
                        Log.Add('confirmed')
                    else
                        Log.Add('declined');
                    Error('');
                end;
            end;
        }
    }
    keys { key(PK; Code) { Clustered = true; } }
}

page 91667 "LT Y14 PG Card"
{
    PageType = Card;
    SourceTable = "LT Y14 PG C";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }
}

codeunit 91670 "LT Y14 PG Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y14 PG Log";

    local procedure SeedExpr()
    var
        T: Record "LT Y14 PG T";
        U: Record "LT Y14 PG U";
    begin
        T.DeleteAll();
        U.DeleteAll();
        T.Code := 'A';
        T.Store := 'X1';
        T.Insert();
        T.Code := 'B';
        T.Store := 'X2';
        T.Insert();
        U.Code := 'A';
        U.Info := 'info-A';
        U.Insert();
        U.Code := 'B';
        U.Info := 'info-B';
        U.Insert();
        Commit();
        Log.Take();
    end;

    local procedure ExprShown(var P: TestPage "LT Y14 PG Expr"): Text
    begin
        exit(P.Code.Value() + '/' + P.Store.Value() + '/' + P.Info.Value());
    end;

    [Test]
    procedure Trapped_FindFirstField_FunctionControl()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT Y14 PG T";
        P: TestPage "LT Y14 PG Expr";
    begin
        SeedExpr();
        T.SetFilter(Code, 'A|B');
        P.Trap();
        Page.Run(Page::"LT Y14 PG Expr", T);
        Observer.Observe('open log', Log.Take());
        Observer.Observe('first', ExprShown(P));
        Observer.Observe('find X2', Format(P.FindFirstField(P.Store, 'X2')));
        Observer.Observe('after find', ExprShown(P));
        Observer.Observe('find by info', Format(P.FindFirstField(P.Info, 'info-A')));
        Observer.Observe('after find by info', ExprShown(P));
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('after next', ExprShown(P));
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Expect('open log', 'agr(A);describe(A);agr(B);describe(B);agr(A);');
        Observer.Expect('first', 'A/X1/info-A');
        Observer.Expect('find X2', 'Yes');
        Observer.Expect('after find', 'B/X2/info-B');
        Observer.Expect('find by info', 'Yes');
        Observer.Expect('after find by info', 'A/X1/info-A');
        Observer.Expect('next', 'Yes');
        Observer.Expect('after next', 'B/X2/info-B');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure OpenView_FindFirstField_FunctionControl()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y14 PG Expr";
    begin
        SeedExpr();
        P.OpenView();
        Observer.Observe('open log', Log.Take());
        Observer.Observe('first', ExprShown(P));
        Observer.Observe('find X2', Format(P.FindFirstField(P.Store, 'X2')));
        Observer.Observe('after find', ExprShown(P));
        Observer.Observe('find by info', Format(P.FindFirstField(P.Info, 'info-A')));
        Observer.Observe('after find by info', ExprShown(P));
        Observer.Observe('next', Format(P.Next()));
        Observer.Observe('after next', ExprShown(P));
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Expect('open log', 'agr(A);describe(A);agr(B);describe(B);agr(A);');
        Observer.Expect('first', 'A/X1/info-A');
        Observer.Expect('find X2', 'Yes');
        Observer.Expect('after find', 'B/X2/info-B');
        Observer.Expect('find by info', 'Yes');
        Observer.Expect('after find by info', 'A/X1/info-A');
        Observer.Expect('next', 'Yes');
        Observer.Expect('after next', 'B/X2/info-B');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    local procedure TempRows(var A: Record "LT Y14 PG T" temporary; var B: Record "LT Y14 PG T" temporary)
    begin
        A.Code := 'A1';
        A.Store := 'sa1';
        A.Insert();
        A.Code := 'A2';
        A.Store := 'sa2';
        A.Insert();
        B.Code := 'B1';
        B.Store := 'sb1';
        B.Insert();
    end;

    [ModalPageHandler]
    procedure PageTypedLookupOk(var P: Page "LT Y14 PG Temp"; var Response: Action)
    var
        Cur: Record "LT Y14 PG T" temporary;
    begin
        Log.Add('handler');
        P.GetRecord(Cur);
        Log.Add('cur=' + Cur.Code + '/' + Cur.Store + '/find=' + Format(Cur.Find()) + '/count=' + Format(Cur.Count()));
        Response := Action::LookupOK;
    end;

    [PageHandler]
    procedure PageTypedRun(var P: Page "LT Y14 PG Temp")
    var
        Cur: Record "LT Y14 PG T" temporary;
    begin
        Log.Add('handler');
        P.GetRecord(Cur);
        Log.Add('cur=' + Cur.Code + '/' + Cur.Store + '/find=' + Format(Cur.Find()) + '/count=' + Format(Cur.Count()));
    end;

    [Test]
    [HandlerFunctions('PageTypedLookupOk')]
    procedure PageTypedModalHandler_TempSource_CopyOnOpen()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT Y14 PG T" temporary;
        B: Record "LT Y14 PG T" temporary;
        P: Page "LT Y14 PG Temp";
        Result: Action;
    begin
        Log.Take();
        TempRows(A, B);
        P.SetSourceTables(A, B, true);
        P.LookupMode(true);
        Result := P.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'set(Yes);handler;cur=//find=No/count=0;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageTypedLookupOk')]
    procedure PageTypedModalHandler_TempSource_FilledBeforeOpen()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "LT Y14 PG T" temporary;
        B: Record "LT Y14 PG T" temporary;
        P: Page "LT Y14 PG Temp";
        Result: Action;
    begin
        Log.Take();
        TempRows(A, B);
        P.SetSourceTables(A, B, false);
        P.LookupMode(true);
        Result := P.RunModal();
        Observer.Observe('result', Format(Result));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'set(No);handler;cur=B1/sb1/find=No/count=0;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PageTypedRun')]
    procedure PageTypedPageHandler_PageRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Page.Run(Page::"LT Y14 PG Temp");
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'handler;cur=//find=No/count=0;');
        Observer.Verify();
    end;

    [ConfirmHandler]
    procedure DeclineConfirm(Question: Text; var Reply: Boolean)
    begin
        Log.Add('confirm(' + Question + ')');
        Reply := false;
    end;

    local procedure SeedCard()
    var
        C: Record "LT Y14 PG C";
    begin
        C.DeleteAll();
        C.Code := 'C1';
        C.Name := 'seed';
        C.Insert();
        Commit();
        Log.Take();
    end;

    local procedure StoredName(): Text
    var
        C: Record "LT Y14 PG C";
    begin
        C.Get('C1');
        exit(C.Name);
    end;

    [TryFunction]
    local procedure TrySetValue(var P: TestPage "LT Y14 PG Card"; Value: Text)
    begin
        P.Name.SetValue(Value);
    end;

    [Test]
    [HandlerFunctions('DeclineConfirm')]
    procedure CardSetValue_ConfirmThenEmptyError_TryFunction()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y14 PG Card";
    begin
        SeedCard();
        P.OpenEdit();
        Observer.Observe('try', Format(TrySetValue(P, 'bad')));
        Observer.ObserveError('setvalue');
        Observer.Observe('page value', P.Name.Value());
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Observe('stored', StoredName());
        Observer.Expect('try', 'Yes');
        Observer.Expect('setvalue|text', '');
        Observer.Expect('setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('page value', 'seed');
        Observer.Expect('log', 'validate(bad);confirm(Really change?);declined;');
        Observer.Expect('stored', 'seed');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DeclineConfirm')]
    procedure CardSetValue_ConfirmThenEmptyError_Plain()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT Y14 PG Card";
    begin
        SeedCard();
        P.OpenEdit();
        P.Name.SetValue('bad');
        Observer.Observe('went on', 'yes');
        Observer.ObserveError('setvalue');
        Observer.Observe('page value', P.Name.Value());
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Observe('stored', StoredName());
        P.OpenEdit();
        Observer.Observe('reopened value', P.Name.Value());
        P.Name.SetValue('fine');
        Observer.Observe('after fine', P.Name.Value());
        P.Close();
        Observer.Observe('stored after fine', StoredName());
        Observer.Observe('log2', Log.Take());
        Observer.Expect('went on', 'yes');
        Observer.Expect('setvalue|text', '');
        Observer.Expect('setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('page value', 'seed');
        Observer.Expect('log', 'validate(bad);confirm(Really change?);declined;');
        Observer.Expect('stored', 'seed');
        Observer.Expect('reopened value', 'seed');
        Observer.Expect('after fine', 'fine');
        Observer.Expect('stored after fine', 'fine');
        Observer.Expect('log2', 'validate(fine);');
        Observer.Verify();
    end;
}
