// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-text-record-joker-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 93950 and 93954, pages 93951 and 93952, test codeunit 93953
// Probe: corpus writer Y74, pages area inventory. The fully qualified name forms of Page.Run and Page.RunModal that no corpus test pins: Run(Name), Run(Name, Record), Run(Name, Record, Field value), RunModal(Name), RunModal(Name, Record), RunModal(Name, Record, Field value), RunModal(Name, Record, FieldRef), and the name spellings and error texts. The forms with a field NUMBER are pinned by report/lt-bj-fqn-page-run/BjFqnPageRun.al.
// BC versions: 28.0 and later (runtime 17.0; BC 27 rejects the fully qualified name overloads, see must-not-compile 0664)

#if BC28PLUS
namespace LT.Y74.Fqn;

table 93950 "LT Y74 Fqn Row"
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

table 93954 "LT Y74 Fqn Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 93951 "LT Y74 Fqn Card"
{
    PageType = Card;
    SourceTable = "LT Y74 Fqn Row";
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

page 93952 "LT Y74 Fqn List"
{
    PageType = List;
    SourceTable = "LT Y74 Fqn Row";
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

codeunit 93953 "LT Y74 Fqn Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Seen: Text;
        Choice: Integer;

    local procedure Seed()
    var
        Row: Record "LT Y74 Fqn Row";
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
    [HandlerFunctions('CardHandler,ListHandler')]
    procedure Run_Name_Only()
    begin
        Seed();
        Seen := '';
        Page.Run('LT.Y74.Fqn.LT Y74 Fqn Card');
        Observer.Observe('card', Seen);
        Seen := '';
        Page.Run('LT.Y74.Fqn.LT Y74 Fqn List');
        Observer.Observe('list', Seen);
        Observer.Expect('card', '1/T1/10;');
        Observer.Expect('list', 'cur=1 rows=12340;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler,ListHandler')]
    procedure Run_Name_Record()
    var
        Row: Record "LT Y74 Fqn Row";
    begin
        Seed();
        Row.Get(3);
        Seen := '';
        Page.Run('LT.Y74.Fqn.LT Y74 Fqn Card', Row);
        Observer.Observe('card', Seen);
        Seen := '';
        Page.Run('LT.Y74.Fqn.LT Y74 Fqn List', Row);
        Observer.Observe('list', Seen);
        Row.SetFilter(Id, '%1|%2', 2, 4);
        Row.FindFirst();
        Seen := '';
        Page.Run('LT.Y74.Fqn.LT Y74 Fqn List', Row);
        Observer.Observe('list filtered', Seen);
        Observer.Observe('filters after', Row.GetFilters());
        Observer.Expect('card', '3/T3/30;');
        Observer.Expect('list', 'cur=3 rows=12340;');
        Observer.Expect('list filtered', 'cur=2 rows=240;');
        Observer.Expect('filters after', 'Id: 2|4');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler,ListHandler')]
    procedure Run_Name_Record_FieldValue()
    var
        Row: Record "LT Y74 Fqn Row";
    begin
        Seed();
        Row.Get(3);
        Seen := '';
        Page.Run('LT.Y74.Fqn.LT Y74 Fqn Card', Row, Row.Qty);
        Observer.Observe('card qty', Seen);
        Seen := '';
        Page.Run('LT.Y74.Fqn.LT Y74 Fqn Card', Row, Row.Id);
        Observer.Observe('card id', Seen);
        Seen := '';
        Page.Run('LT.Y74.Fqn.LT Y74 Fqn List', Row, Row.Txt);
        Observer.Observe('list txt', Seen);
        Seen := '';
        Page.Run(Page::"LT Y74 Fqn List", Row, Row.Txt);
        Observer.Observe('list txt by id', Seen);
        Observer.Expect('card qty', '3/T3/30;');
        Observer.Expect('card id', '3/T3/30;');
        Observer.Expect('list txt', 'cur=3 rows=12340;');
        Observer.Expect('list txt by id', 'cur=3 rows=12340;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalListHandler')]
    procedure RunModal_Name_Only()
    var
        Act: Action;
    begin
        Seed();
        Seen := '';
        Choice := 1;
        Act := Page.RunModal('LT.Y74.Fqn.LT Y74 Fqn List');
        Observer.Observe('ok', Format(Act) + '|' + Seen);
        Seen := '';
        Choice := 2;
        Act := Page.RunModal('LT.Y74.Fqn.LT Y74 Fqn List');
        Observer.Observe('cancel', Format(Act) + '|' + Seen);
        Observer.Expect('ok', 'LookupOK|cur=1 rows=1234;');
        Observer.Expect('cancel', 'LookupCancel|cur=1 rows=1234;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalListHandler')]
    procedure RunModal_Name_Record()
    var
        Row: Record "LT Y74 Fqn Row";
        Act: Action;
    begin
        Seed();
        Row.Get(2);
        Seen := '';
        Choice := 1;
        Act := Page.RunModal('LT.Y74.Fqn.LT Y74 Fqn List', Row);
        Observer.Observe('ok', Format(Act) + '|' + Seen);
        Seen := '';
        Choice := 2;
        Act := Page.RunModal('LT.Y74.Fqn.LT Y74 Fqn List', Row);
        Observer.Observe('cancel', Format(Act) + '|' + Seen);
        Observer.Observe('row after', Format(Row.Id));
        Observer.Expect('ok', 'LookupOK|cur=2 rows=1234;');
        Observer.Expect('cancel', 'LookupCancel|cur=4 rows=1234;');
        Observer.Expect('row after', '4');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalListHandler')]
    procedure RunModal_Name_Record_FieldValue()
    var
        Row: Record "LT Y74 Fqn Row";
        Act: Action;
    begin
        Seed();
        Row.Get(4);
        Seen := '';
        Choice := 1;
        Act := Page.RunModal('LT.Y74.Fqn.LT Y74 Fqn List', Row, Row.Qty);
        Observer.Observe('ok', Format(Act) + '|' + Seen);
        Seen := '';
        Choice := 2;
        Act := Page.RunModal('LT.Y74.Fqn.LT Y74 Fqn List', Row, Row.Txt);
        Observer.Observe('cancel', Format(Act) + '|' + Seen);
        Observer.Expect('ok', 'LookupOK|cur=4 rows=1234;');
        Observer.Expect('cancel', 'LookupCancel|cur=4 rows=1234;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModalListHandler')]
    procedure RunModal_Name_Record_FieldRef()
    var
        Row: Record "LT Y74 Fqn Row";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(2);
        RecRef.GetTable(Row);
        FR := RecRef.Field(Row.FieldNo(Qty));
        Seen := '';
        Choice := 1;
        Act := Page.RunModal('LT.Y74.Fqn.LT Y74 Fqn List', Row, FR);
        Observer.Observe('ok', Format(Act) + '|' + Seen);
        Seen := '';
        Choice := 2;
        Act := Page.RunModal('LT.Y74.Fqn.LT Y74 Fqn List', Row, FR);
        Observer.Observe('cancel', Format(Act) + '|' + Seen);
        Observer.Expect('ok', 'LookupOK|cur=2 rows=1234;');
        Observer.Expect('cancel', 'LookupCancel|cur=4 rows=1234;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler,ListHandler')]
    procedure Run_Name_Spellings()
    begin
        Seed();
        Seen := '';
        Page.Run('lt.y74.fqn.lt y74 fqn card');
        Observer.Observe('lower case', Seen);
        Seen := '';
        Page.Run('LT.Y74.Fqn."LT Y74 Fqn Card"');
        Observer.Observe('quoted', Seen);
        Observer.Expect('lower case', '1/T1/10;');
        Observer.Expect('quoted', '1/T1/10;');
        Observer.Verify();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_Missing()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y74.Fqn.LT Y74 Fqn Missing');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_Empty()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_NoNamespace()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT Y74 Fqn Card');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_TableName()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y74.Fqn.LT Y74 Fqn Row');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_CodeunitName()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y74.Fqn.LT Y74 Fqn Run Tests');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_PageIdAsText()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('93951');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_ModalMissing()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        asserterror Act := Page.RunModal('LT.Y74.Fqn.LT Y74 Fqn Missing');
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_OtherTable()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        Other.Id := 1;
        asserterror Page.Run('LT.Y74.Fqn.LT Y74 Fqn Card', Other);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_FieldOfOtherTable()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        Other.Id := 1;
        asserterror Page.Run('LT.Y74.Fqn.LT Y74 Fqn Card', Row, Other.Id);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_NoHandler()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        asserterror Page.Run('LT.Y74.Fqn.LT Y74 Fqn Card', Row);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_FieldRefUninitialized()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        asserterror Act := Page.RunModal('LT.Y74.Fqn.LT Y74 Fqn List', Row, FR);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_FieldRefOtherTable()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        Other.Id := 1;
        RecRef.GetTable(Other);
        FR := RecRef.Field(Other.FieldNo(Id));
        asserterror Act := Page.RunModal('LT.Y74.Fqn.LT Y74 Fqn List', Row, FR);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    // Own test per case: one of them may end the session in a CLR exception.
    [Test]
    procedure Err_FieldRefMissingPage()
    var
        Row: Record "LT Y74 Fqn Row";
        Other: Record "LT Y74 Fqn Other";
        RecRef: RecordRef;
        FR: FieldRef;
        Act: Action;
    begin
        Seed();
        Row.Get(1);
        Other.Id := 1;
        RecRef.GetTable(Other);
        FR := RecRef.Field(Other.FieldNo(Id));
        asserterror Act := Page.RunModal('LT.Y74.Fqn.LT Y74 Fqn Missing', Row, FR);
        Observer.ObserveError('e');
        Observer.Finish();
    end;

    [PageHandler]
    procedure CardHandler(var P: TestPage "LT Y74 Fqn Card")
    begin
        Seen += P.Id.Value + '/' + P.Txt.Value + '/' + P.Qty.Value + ';';
    end;

    [PageHandler]
    procedure ListHandler(var P: TestPage "LT Y74 Fqn List")
    begin
        Seen += 'cur=' + P.Id.Value + ' rows=';
        if P.First() then
            repeat
                Seen += P.Id.Value;
            until not P.Next();
        Seen += ';';
    end;

    [ModalPageHandler]
    procedure ModalListHandler(var P: TestPage "LT Y74 Fqn List")
    begin
        Seen += 'cur=' + P.Id.Value + ' rows=';
        if P.First() then
            repeat
                Seen += P.Id.Value;
            until not P.Next();
        Seen += ';';
        if Choice = 1 then
            P.OK().Invoke()
        else
            P.Cancel().Invoke();
    end;
}
#endif
