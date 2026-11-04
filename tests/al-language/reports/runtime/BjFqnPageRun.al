// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-text-record-integer-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 81650, pages 81651 and 81652, test codeunit 81653
// Probe: corpus issue 596 item 2. Page.Run(FullyQualifiedName, Record, FieldNo): the row the page shows, the rows of a list page, a filtered record, field number 0 and a field number the table does not have. The overload returns nothing and has no FieldRef form:
//   must-not-compile 1340 and 1341.
// BC versions: 28.0 and later (runtime 17.0; BC 27 rejects the fully qualified name overloads, see must-not-compile 0664)

#if BC28PLUS
namespace LT.BJ.Fqn;

table 81650 "LT BJ Fqn Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 81651 "LT BJ Fqn Card"
{
    PageType = Card;
    SourceTable = "LT BJ Fqn Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
            field(Qty; Rec.Qty) { ApplicationArea = All; }
        }
    }
}

page 81652 "LT BJ Fqn List"
{
    PageType = List;
    SourceTable = "LT BJ Fqn Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Txt; Rec.Txt) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 81653 "LT BJ Fqn Page Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Seen: Text;

    local procedure Seed()
    var
        Row: Record "LT BJ Fqn Row";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 4 do begin
            Row.Init();
            Row.Id := Index;
            Row.Txt := 'T' + Format(Index);
            Row.Qty := Index * 10;
            Row.Insert();
        end;
        Commit();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure PageRun_Fqn_Record_FieldNo_Card()
    var
        Row: Record "LT BJ Fqn Row";
    begin
        Seed();
        Row.Get(3);
        Seen := '';
        Page.Run('LT.BJ.Fqn.LT BJ Fqn Card', Row, Row.FieldNo(Qty));
        Observer.Observe('card fieldno', Seen);
        Seen := '';
        Page.Run('LT.BJ.Fqn.LT BJ Fqn Card', Row, 0);
        Observer.Observe('card fieldno 0', Seen);
        Seen := '';
        Page.Run('LT.BJ.Fqn.LT BJ Fqn Card', Row, 2);
        Observer.Observe('card fieldno 2', Seen);
        Observer.Observe('record after', Format(Row.Id) + '/' + Row.Txt);
        Observer.Expect('card fieldno', '3/T3/30;');
        Observer.Expect('card fieldno 0', '3/T3/30;');
        Observer.Expect('card fieldno 2', '3/T3/30;');
        Observer.Expect('record after', '3/T3');
        Observer.Verify();
    end;

    // No handler: the page does not open (a listed handler that never runs fails the test).
    [Test]
    procedure PageRun_Fqn_Record_UnknownFieldNo()
    var
        Row: Record "LT BJ Fqn Row";
    begin
        Seed();
        Row.Get(1);
        Seen := '';
        asserterror begin
            Page.Run('LT.BJ.Fqn.LT BJ Fqn Card', Row, 99);
            Error('NOERROR');
        end;
        Observer.ObserveError('card fieldno 99');
        Observer.Observe('card fieldno 99 seen', Seen);
        Observer.Expect('card fieldno 99|text', 'The supplied field number ''99'' cannot be found in the ''LT BJ Fqn Row'' table.');
        Observer.Expect('card fieldno 99|code', 'FieldNotFound');
        Observer.Expect('card fieldno 99 seen', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure PageRun_Fqn_Record_FieldNo_List()
    var
        Row: Record "LT BJ Fqn Row";
    begin
        Seed();
        Row.Get(2);
        Seen := '';
        Page.Run('LT.BJ.Fqn.LT BJ Fqn List', Row, Row.FieldNo(Txt));
        Observer.Observe('list fieldno', Seen);
        Row.SetFilter(Id, '%1|%2', 3, 4);
        Row.FindLast();
        Seen := '';
        Page.Run('LT.BJ.Fqn.LT BJ Fqn List', Row, Row.FieldNo(Qty));
        Observer.Observe('list filtered', Seen);
        Observer.Observe('filters after', Row.GetFilters());
        Observer.Expect('list fieldno', 'cur=2 rows=12340;');
        Observer.Expect('list filtered', 'cur=4 rows=340;');
        Observer.Expect('filters after', 'Id: 3|4');
        Observer.Verify();
    end;

    [PageHandler]
    procedure CardHandler(var P: TestPage "LT BJ Fqn Card")
    begin
        Seen += P.Id.Value + '/' + P.Txt.Value + '/' + P.Qty.Value + ';';
    end;

    [PageHandler]
    procedure ListHandler(var P: TestPage "LT BJ Fqn List")
    begin
        Seen += 'cur=' + P.Id.Value + ' rows=';
        if P.First() then
            repeat
                Seen += P.Id.Value;
            until not P.Next();
        Seen += ';';
    end;
}
#endif
