// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-findfirst-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 94251, test codeunit 94252
// Probe (writer Y81): FindFirst, FindLast, FindSet, FindSet(true), Find with each search string, Next (steps 1, -1, 0, 2) and Get on an empty set, on a set filtered
// to no row and on a set with rows, for a RecordRef (permanent and temporary), and for a temporary Record variable; the result unused (error text and code)
// and used. Also a Record found past the last row by Next.
// Pinned elsewhere: Record on a permanent table: record/lt-filters-keys-finds/P68C_EmptyFinds.al, record/lt-find-empty-table/*.al,
// error-handling/lt-last-error-text-forms/FindEmptyTableExcludeFlag.al.
// BC versions: 27, 28, 29

table 94251 "LT Y81 ES Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 94252 "LT Y81 Empty Set Finds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryRef(var RecRef: RecordRef; Op: Text)
    begin
        case Op of
            'FindFirst':
                RecRef.FindFirst();
            'FindLast':
                RecRef.FindLast();
            'FindSet':
                RecRef.FindSet();
            'FindSetTrue':
                RecRef.FindSet(true);
            'Find':
                RecRef.Find();
            'Find-':
                RecRef.Find('-');
            'Find+':
                RecRef.Find('+');
            'Find=':
                RecRef.Find('=');
            'Find>':
                RecRef.Find('>');
            'Find<':
                RecRef.Find('<');
            'Next':
                RecRef.Next();
            'Next-1':
                RecRef.Next(-1);
            'Next0':
                RecRef.Next(0);
            'Next2':
                RecRef.Next(2);
        end;
    end;

    [TryFunction]
    local procedure TryRec(var Row: Record "LT Y81 ES Row"; Op: Text)
    begin
        case Op of
            'FindFirst':
                Row.FindFirst();
            'FindLast':
                Row.FindLast();
            'FindSet':
                Row.FindSet();
            'FindSetTrue':
                Row.FindSet(true);
            'Find':
                Row.Find();
            'Find-':
                Row.Find('-');
            'Find+':
                Row.Find('+');
            'Find=':
                Row.Find('=');
            'Find>':
                Row.Find('>');
            'Find<':
                Row.Find('<');
            'Next':
                Row.Next();
            'Next-1':
                Row.Next(-1);
            'Next0':
                Row.Next(0);
            'Next2':
                Row.Next(2);
        end;
    end;

    local procedure Unused(var RecRef: RecordRef; Op: Text): Text
    begin
        ClearLastError();
        if TryRef(RecRef, Op) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure UnusedRec(var Row: Record "LT Y81 ES Row"; Op: Text): Text
    begin
        ClearLastError();
        if TryRec(Row, Op) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Used(var RecRef: RecordRef; Op: Text): Text
    begin
        case Op of
            'FindFirst':
                exit(Format(RecRef.FindFirst()));
            'FindLast':
                exit(Format(RecRef.FindLast()));
            'FindSet':
                exit(Format(RecRef.FindSet()));
            'FindSetTrue':
                exit(Format(RecRef.FindSet(true)));
            'Find':
                exit(Format(RecRef.Find()));
            'Find-':
                exit(Format(RecRef.Find('-')));
            'Find+':
                exit(Format(RecRef.Find('+')));
            'Find=':
                exit(Format(RecRef.Find('=')));
            'Find>':
                exit(Format(RecRef.Find('>')));
            'Find<':
                exit(Format(RecRef.Find('<')));
            'Next':
                exit(Format(RecRef.Next()));
            'Next-1':
                exit(Format(RecRef.Next(-1)));
            'Next0':
                exit(Format(RecRef.Next(0)));
            'Next2':
                exit(Format(RecRef.Next(2)));
        end;
    end;

    local procedure UsedRec(var Row: Record "LT Y81 ES Row"; Op: Text): Text
    begin
        case Op of
            'FindFirst':
                exit(Format(Row.FindFirst()));
            'FindLast':
                exit(Format(Row.FindLast()));
            'FindSet':
                exit(Format(Row.FindSet()));
            'FindSetTrue':
                exit(Format(Row.FindSet(true)));
            'Find':
                exit(Format(Row.Find()));
            'Find-':
                exit(Format(Row.Find('-')));
            'Find+':
                exit(Format(Row.Find('+')));
            'Find=':
                exit(Format(Row.Find('=')));
            'Find>':
                exit(Format(Row.Find('>')));
            'Find<':
                exit(Format(Row.Find('<')));
            'Next':
                exit(Format(Row.Next()));
            'Next-1':
                exit(Format(Row.Next(-1)));
            'Next0':
                exit(Format(Row.Next(0)));
            'Next2':
                exit(Format(Row.Next(2)));
        end;
    end;

    local procedure Ops(): List of [Text]
    var
        L: List of [Text];
    begin
        L.Add('FindFirst');
        L.Add('FindLast');
        L.Add('FindSet');
        L.Add('FindSetTrue');
        L.Add('Find');
        L.Add('Find-');
        L.Add('Find+');
        L.Add('Find=');
        L.Add('Find>');
        L.Add('Find<');
        L.Add('Next');
        L.Add('Next-1');
        L.Add('Next0');
        L.Add('Next2');
        exit(L);
    end;

    local procedure Seed()
    var
        Row: Record "LT Y81 ES Row";
    begin
        Row.DeleteAll();
        Row.Id := 10;
        Row.Name := 'ten';
        Row.Insert();
        Row.Id := 20;
        Row.Name := 'twenty';
        Row.Insert();
    end;

    [Test]
    procedure Y81_RecRef_Empty_Unused()
    var
        Row: Record "LT Y81 ES Row";
        RecRef: RecordRef;
        Op: Text;
    begin
        Row.DeleteAll();
        RecRef.Open(Database::"LT Y81 ES Row");
        foreach Op in Ops() do
            Observer.Observe('unused ' + Op, Unused(RecRef, Op));
        Observer.Expect('unused FindFirst', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused FindLast', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused FindSet', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused FindSetTrue', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused Find', 'The LT Y81 ES Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Find-', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused Find+', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused Find=', 'The LT Y81 ES Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Find>', 'The LT Y81 ES Row does not exist. >\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Find<', 'The LT Y81 ES Row does not exist. <\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Next', 'ok');
        Observer.Expect('unused Next-1', 'ok');
        Observer.Expect('unused Next0', 'ok');
        Observer.Expect('unused Next2', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_RecRef_Empty_Used()
    var
        Row: Record "LT Y81 ES Row";
        RecRef: RecordRef;
        Op: Text;
    begin
        Row.DeleteAll();
        RecRef.Open(Database::"LT Y81 ES Row");
        foreach Op in Ops() do
            Observer.Observe('used ' + Op, Used(RecRef, Op));
        Observer.Expect('used FindFirst', 'No');
        Observer.Expect('used FindLast', 'No');
        Observer.Expect('used FindSet', 'No');
        Observer.Expect('used FindSetTrue', 'No');
        Observer.Expect('used Find', 'No');
        Observer.Expect('used Find-', 'No');
        Observer.Expect('used Find+', 'No');
        Observer.Expect('used Find=', 'No');
        Observer.Expect('used Find>', 'No');
        Observer.Expect('used Find<', 'No');
        Observer.Expect('used Next', '0');
        Observer.Expect('used Next-1', '0');
        Observer.Expect('used Next0', '0');
        Observer.Expect('used Next2', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_RecRef_FilteredOut_Unused()
    var
        RecRef: RecordRef;
        Op: Text;
    begin
        Seed();
        RecRef.Open(Database::"LT Y81 ES Row");
        RecRef.Field(1).SetRange(99);
        foreach Op in Ops() do
            Observer.Observe('unused ' + Op, Unused(RecRef, Op));
        Observer.Expect('unused FindFirst', 'There is no LT Y81 ES Row within the filter.\\Filters: Id: 99|DB:NothingInsideFilter');
        Observer.Expect('unused FindLast', 'There is no LT Y81 ES Row within the filter.\\Filters: Id: 99|DB:NothingInsideFilter');
        Observer.Expect('unused FindSet', 'There is no LT Y81 ES Row within the filter.\\Filters: Id: 99|DB:NothingInsideFilter');
        Observer.Expect('unused FindSetTrue', 'There is no LT Y81 ES Row within the filter.\\Filters: Id: 99|DB:NothingInsideFilter');
        Observer.Expect('unused Find', 'The LT Y81 ES Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Find-', 'There is no LT Y81 ES Row within the filter.\\Filters: Id: 99|DB:NothingInsideFilter');
        Observer.Expect('unused Find+', 'There is no LT Y81 ES Row within the filter.\\Filters: Id: 99|DB:NothingInsideFilter');
        Observer.Expect('unused Find=', 'The LT Y81 ES Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Find>', 'The LT Y81 ES Row does not exist. >\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Find<', 'The LT Y81 ES Row does not exist. <\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Next', 'ok');
        Observer.Expect('unused Next-1', 'ok');
        Observer.Expect('unused Next0', 'ok');
        Observer.Expect('unused Next2', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_RecRef_FilteredOut_Used()
    var
        RecRef: RecordRef;
        Op: Text;
    begin
        Seed();
        RecRef.Open(Database::"LT Y81 ES Row");
        RecRef.Field(1).SetRange(99);
        foreach Op in Ops() do
            Observer.Observe('used ' + Op, Used(RecRef, Op));
        Observer.Expect('used FindFirst', 'No');
        Observer.Expect('used FindLast', 'No');
        Observer.Expect('used FindSet', 'No');
        Observer.Expect('used FindSetTrue', 'No');
        Observer.Expect('used Find', 'No');
        Observer.Expect('used Find-', 'No');
        Observer.Expect('used Find+', 'No');
        Observer.Expect('used Find=', 'No');
        Observer.Expect('used Find>', 'No');
        Observer.Expect('used Find<', 'No');
        Observer.Expect('used Next', '0');
        Observer.Expect('used Next-1', '0');
        Observer.Expect('used Next0', '0');
        Observer.Expect('used Next2', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_RecRef_Temporary_Empty()
    var
        RecRef: RecordRef;
        Op: Text;
    begin
        Seed();
        RecRef.Open(Database::"LT Y81 ES Row", true);
        foreach Op in Ops() do
            Observer.Observe('unused ' + Op, Unused(RecRef, Op));
        foreach Op in Ops() do
            Observer.Observe('used ' + Op, Used(RecRef, Op));
        Observer.Expect('unused FindFirst', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused FindLast', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused FindSet', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused FindSetTrue', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused Find', 'The LT Y81 ES Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Find-', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused Find+', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused Find=', 'The LT Y81 ES Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Find>', 'The LT Y81 ES Row does not exist. >\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Find<', 'The LT Y81 ES Row does not exist. <\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Next', 'ok');
        Observer.Expect('unused Next-1', 'ok');
        Observer.Expect('unused Next0', 'ok');
        Observer.Expect('unused Next2', 'ok');
        Observer.Expect('used FindFirst', 'No');
        Observer.Expect('used FindLast', 'No');
        Observer.Expect('used FindSet', 'No');
        Observer.Expect('used FindSetTrue', 'No');
        Observer.Expect('used Find', 'No');
        Observer.Expect('used Find-', 'No');
        Observer.Expect('used Find+', 'No');
        Observer.Expect('used Find=', 'No');
        Observer.Expect('used Find>', 'No');
        Observer.Expect('used Find<', 'No');
        Observer.Expect('used Next', '0');
        Observer.Expect('used Next-1', '0');
        Observer.Expect('used Next0', '0');
        Observer.Expect('used Next2', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_Rec_Temporary_Empty()
    var
        Row: Record "LT Y81 ES Row" temporary;
        Op: Text;
    begin
        Seed();
        foreach Op in Ops() do
            Observer.Observe('unused ' + Op, UnusedRec(Row, Op));
        foreach Op in Ops() do
            Observer.Observe('used ' + Op, UsedRec(Row, Op));
        Observer.Expect('unused FindFirst', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused FindLast', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused FindSet', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused FindSetTrue', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused Find', 'The LT Y81 ES Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Find-', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused Find+', 'The LT Y81 ES Row table is empty.|DB:TableIsEmpty');
        Observer.Expect('unused Find=', 'The LT Y81 ES Row does not exist. Identification fields and values: Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Find>', 'The LT Y81 ES Row does not exist. >\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Find<', 'The LT Y81 ES Row does not exist. <\\Identification fields and values:\\Id=''0''|DB:RecordNotFound');
        Observer.Expect('unused Next', 'ok');
        Observer.Expect('unused Next-1', 'ok');
        Observer.Expect('unused Next0', 'ok');
        Observer.Expect('unused Next2', 'ok');
        Observer.Expect('used FindFirst', 'No');
        Observer.Expect('used FindLast', 'No');
        Observer.Expect('used FindSet', 'No');
        Observer.Expect('used FindSetTrue', 'No');
        Observer.Expect('used Find', 'No');
        Observer.Expect('used Find-', 'No');
        Observer.Expect('used Find+', 'No');
        Observer.Expect('used Find=', 'No');
        Observer.Expect('used Find>', 'No');
        Observer.Expect('used Find<', 'No');
        Observer.Expect('used Next', '0');
        Observer.Expect('used Next-1', '0');
        Observer.Expect('used Next0', '0');
        Observer.Expect('used Next2', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_Rec_Temporary_FilteredOut()
    var
        Row: Record "LT Y81 ES Row" temporary;
        Op: Text;
    begin
        Row.Id := 10;
        Row.Insert();
        Row.SetRange(Id, 99);
        foreach Op in Ops() do
            Observer.Observe('unused ' + Op, UnusedRec(Row, Op));
        foreach Op in Ops() do
            Observer.Observe('used ' + Op, UsedRec(Row, Op));
        Observer.Expect('unused FindFirst', 'There is no LT Y81 ES Row within the filter.\\Filters: Id: 99|DB:NothingInsideFilter');
        Observer.Expect('unused FindLast', 'There is no LT Y81 ES Row within the filter.\\Filters: Id: 99|DB:NothingInsideFilter');
        Observer.Expect('unused FindSet', 'There is no LT Y81 ES Row within the filter.\\Filters: Id: 99|DB:NothingInsideFilter');
        Observer.Expect('unused FindSetTrue', 'There is no LT Y81 ES Row within the filter.\\Filters: Id: 99|DB:NothingInsideFilter');
        Observer.Expect('unused Find', 'The LT Y81 ES Row does not exist. Identification fields and values: Id=''10''|DB:RecordNotFound');
        Observer.Expect('unused Find-', 'There is no LT Y81 ES Row within the filter.\\Filters: Id: 99|DB:NothingInsideFilter');
        Observer.Expect('unused Find+', 'There is no LT Y81 ES Row within the filter.\\Filters: Id: 99|DB:NothingInsideFilter');
        Observer.Expect('unused Find=', 'The LT Y81 ES Row does not exist. Identification fields and values: Id=''10''|DB:RecordNotFound');
        Observer.Expect('unused Find>', 'The LT Y81 ES Row does not exist. >\\Identification fields and values:\\Id=''10''|DB:RecordNotFound');
        Observer.Expect('unused Find<', 'The LT Y81 ES Row does not exist. <\\Identification fields and values:\\Id=''10''|DB:RecordNotFound');
        Observer.Expect('unused Next', 'ok');
        Observer.Expect('unused Next-1', 'ok');
        Observer.Expect('unused Next0', 'ok');
        Observer.Expect('unused Next2', 'ok');
        Observer.Expect('used FindFirst', 'No');
        Observer.Expect('used FindLast', 'No');
        Observer.Expect('used FindSet', 'No');
        Observer.Expect('used FindSetTrue', 'No');
        Observer.Expect('used Find', 'No');
        Observer.Expect('used Find-', 'No');
        Observer.Expect('used Find+', 'No');
        Observer.Expect('used Find=', 'No');
        Observer.Expect('used Find>', 'No');
        Observer.Expect('used Find<', 'No');
        Observer.Expect('used Next', '0');
        Observer.Expect('used Next-1', '0');
        Observer.Expect('used Next0', '0');
        Observer.Expect('used Next2', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_Next_PastLastRow()
    var
        Row: Record "LT Y81 ES Row";
        RecRef: RecordRef;
    begin
        Seed();
        Row.FindLast();
        Observer.Observe('rec next past last', Format(Row.Next()) + '|' + Format(Row.Id));
        Observer.Observe('rec next unused', UnusedRec(Row, 'Next'));
        Row.FindFirst();
        Observer.Observe('rec next-1 before first', Format(Row.Next(-1)) + '|' + Format(Row.Id));
        RecRef.Open(Database::"LT Y81 ES Row");
        RecRef.FindLast();
        Observer.Observe('ref next past last', Format(RecRef.Next()) + '|' + Format(RecRef.Field(1).Value));
        Observer.Observe('ref next unused', Unused(RecRef, 'Next'));
        RecRef.FindFirst();
        Observer.Observe('ref next-1 before first', Format(RecRef.Next(-1)) + '|' + Format(RecRef.Field(1).Value));
        Observer.Expect('rec next past last', '0|20');
        Observer.Expect('rec next unused', 'ok');
        Observer.Expect('rec next-1 before first', '0|10');
        Observer.Expect('ref next past last', '0|20');
        Observer.Expect('ref next unused', 'ok');
        Observer.Expect('ref next-1 before first', '0|10');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_Get_Missing()
    var
        Row: Record "LT Y81 ES Row";
        RecRef: RecordRef;
    begin
        Seed();
        RecRef.Open(Database::"LT Y81 ES Row");
        ClearLastError();
        Observer.Observe('rec get used', Format(Row.Get(55)));
        Observer.Observe('ref get used', Format(RecRef.Get(Row.RecordId)));
        Row.Id := 55;
        RecRef.GetTable(Row);
        Observer.Observe('ref get unused', GetUnusedRef(RecRef));
        Observer.Expect('rec get used', 'No');
        Observer.Expect('ref get used', 'No');
        Observer.Expect('ref get unused', 'The LT Y81 ES Row does not exist. Identification fields and values: Id=''55''|DB:RecordNotFound');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryGetRef(var RecRef: RecordRef)
    var
        Check: RecordRef;
    begin
        Check.Open(RecRef.Number);
        Check.Get(RecRef.RecordId);
    end;

    local procedure GetUnusedRef(var RecRef: RecordRef): Text
    begin
        ClearLastError();
        if TryGetRef(RecRef) then
            exit('ok');
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;
}
