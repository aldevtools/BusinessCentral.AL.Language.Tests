// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setview-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 95625, test codeunit 95626
// Probe (al-runner issue 6969): SetView of a view whose WHERE conditions are joined by a dot instead of a comma, as stored workflow event
//   conditions hold them (`WHERE(Field1=1(2).Field120=1(0))`). The numeric form (Field<n>, 1(..) for FILTER, 0(..) for CONST) and the named
//   form, a dot inside a value (a range `10..20`, a decimal `1.5`, a text `x.y`), a dot followed by a space, three conditions, a trailing dot,
//   a field named with a dot ("No."), RecordRef.SetView, and GetView(false) of a record filtered on two fields. Each SetView runs in a
//   TryFunction; the result is GetFilters and GetView(false), or the error.
// Result (BC 29.0, corpus CI): SetView refuses every view whose WHERE conditions are joined by a dot, in the numeric and the named form,
//   with or without a space, with a trailing or a double dot: "Invalid expression of type: table view." and the view after a backslash,
//   code DB:Ok (also RecordRef.SetView). The record keeps its filters. A field named with a dot ("No.") joined by a comma is accepted.
//   GetView(false) writes a comma between the conditions.
// BC versions: 27, 28, 29

table 95625 "LT R6969 View Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document Type"; Option) { OptionMembers = Quote,"Order",Invoice; }
        field(3; "No."; Code[20]) { }
        field(120; Status; Option) { OptionMembers = Open,Released; }
        field(130; Amount; Decimal) { }
        field(140; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "Document Type", "No.") { Clustered = true; }
    }
}

codeunit 95626 "LT R6969 SetView Dot"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Apply(View: Text): Text
    var
        Head: Record "LT R6969 View Head";
        Result: Text;
    begin
        ClearLastError();
        if TrySetView(Head, View) then
            exit('filters=[' + Head.GetFilters() + '] count=' + Format(Head.Count()) + ' view=[' + Head.GetView(false) + ']');
        Result := 'error=' + GetLastErrorText() + ' code=' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySetView(var Head: Record "LT R6969 View Head"; View: Text)
    begin
        Head.SetView(View);
    end;

    local procedure Seed()
    var
        Head: Record "LT R6969 View Head";
    begin
        Head.DeleteAll();
        Add(Head."Document Type"::Quote, 'A1', Head.Status::Open, 15, 'x.y');
        Add(Head."Document Type"::Invoice, 'A2', Head.Status::Open, 1.5, 'plain');
        Add(Head."Document Type"::Invoice, 'B3', Head.Status::Released, 12, 'x.y');
        Add(Head."Document Type"::Invoice, 'A4', Head.Status::Released, 30, 'other');
    end;

    local procedure Add(DocType: Option; No: Code[20]; Status: Option; Amount: Decimal; Descr: Text[50])
    var
        Head: Record "LT R6969 View Head";
    begin
        Head.Init();
        Head."Document Type" := DocType;
        Head."No." := No;
        Head.Status := Status;
        Head.Amount := Amount;
        Head.Descr := Descr;
        Head.Insert();
    end;

    [Test]
    procedure SetView_Numeric_CommaAndDot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('comma', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2),Field120=1(0))'));
        Observer.Observe('dot', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2).Field120=1(0))'));
        Observer.Observe('dot const', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field1=0(2).Field120=0(0))'));
        Observer.Observe('dot no version', Apply('SORTING(Field1,Field3) WHERE(Field1=1(2).Field120=1(1))'));
        Observer.Expect('comma', 'filters=[Document Type: Invoice, Status: Open] count=1 view=[VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2),Field120=1(0))]');
        Observer.Expect('dot', 'error=Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2).Field120=1(0)) code=DB:Ok');
        Observer.Expect('dot const', 'error=Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field1=0(2).Field120=0(0)) code=DB:Ok');
        Observer.Expect('dot no version', 'error=Invalid expression of type: table view.\SORTING(Field1,Field3) WHERE(Field1=1(2).Field120=1(1)) code=DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_Numeric_DotInsideAValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('range', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field130=1(10..20).Field120=1(1))'));
        Observer.Observe('decimal', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field130=1(1.5).Field120=1(0))'));
        Observer.Observe('text', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field140=1(x.y).Field120=1(0))'));
        Observer.Observe('range last', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field120=1(1).Field130=1(10..20))'));
        Observer.Expect('range', 'error=Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field130=1(10..20).Field120=1(1)) code=DB:Ok');
        Observer.Expect('decimal', 'error=Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field130=1(1.5).Field120=1(0)) code=DB:Ok');
        Observer.Expect('text', 'error=Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field140=1(x.y).Field120=1(0)) code=DB:Ok');
        Observer.Expect('range last', 'error=Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field120=1(1).Field130=1(10..20)) code=DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_Numeric_DotVariants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('three dots', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2).Field120=1(1).Field3=1(A*))'));
        Observer.Observe('dot and comma', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2).Field120=1(1),Field3=1(A*))'));
        Observer.Observe('dot space', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2). Field120=1(1))'));
        Observer.Observe('space dot', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2) .Field120=1(1))'));
        Observer.Observe('trailing dot', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2).)'));
        Observer.Observe('two dots', Apply('VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2)..Field120=1(1))'));
        Observer.Expect('three dots', 'error=Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2).Field120=1(1).Field3=1(A*)) code=DB:Ok');
        Observer.Expect('dot and comma', 'error=Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2).Field120=1(1),Field3=1(A*)) code=DB:Ok');
        Observer.Expect('dot space', 'error=Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2). Field120=1(1)) code=DB:Ok');
        Observer.Expect('space dot', 'error=Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2) .Field120=1(1)) code=DB:Ok');
        Observer.Expect('trailing dot', 'error=Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2).) code=DB:Ok');
        Observer.Expect('two dots', 'error=Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2)..Field120=1(1)) code=DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_Named_Dot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('named dot', Apply('SORTING(Document Type,No.) WHERE(Document Type=FILTER(Invoice).Status=FILTER(Released))'));
        Observer.Observe('named const dot', Apply('SORTING(Document Type,No.) WHERE(Document Type=CONST(Invoice).Status=CONST(Released))'));
        Observer.Observe('named field with dot first', Apply('SORTING(Document Type,No.) WHERE(No.=FILTER(A*).Status=FILTER(Open))'));
        Observer.Observe('named field with dot second', Apply('SORTING(Document Type,No.) WHERE(Status=FILTER(Open).No.=FILTER(A*))'));
        Observer.Observe('named field with dot comma', Apply('SORTING(Document Type,No.) WHERE(Status=FILTER(Open),No.=FILTER(A*))'));
        Observer.Expect('named dot', 'error=Invalid expression of type: table view.\SORTING(Document Type,No.) WHERE(Document Type=FILTER(Invoice).Status=FILTER(Released)) code=DB:Ok');
        Observer.Expect('named const dot', 'error=Invalid expression of type: table view.\SORTING(Document Type,No.) WHERE(Document Type=CONST(Invoice).Status=CONST(Released)) code=DB:Ok');
        Observer.Expect('named field with dot first', 'error=Invalid expression of type: table view.\SORTING(Document Type,No.) WHERE(No.=FILTER(A*).Status=FILTER(Open)) code=DB:Ok');
        Observer.Expect('named field with dot second', 'error=Invalid expression of type: table view.\SORTING(Document Type,No.) WHERE(Status=FILTER(Open).No.=FILTER(A*)) code=DB:Ok');
        Observer.Expect('named field with dot comma', 'filters=[No.: A*, Status: Open] count=2 view=[VERSION(1) SORTING(Field1,Field3) WHERE(Field3=1(A*),Field120=1(0))]');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_SetView_Numeric_Dot()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Seed();
        RecRef.Open(Database::"LT R6969 View Head");
        asserterror RecRef.SetView('VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2).Field120=1(0))');
        Observer.ObserveError('setview');
        Observer.Observe('filters after', RecRef.GetFilters());
        RecRef.Close();
        Observer.Expect('setview|text', 'Invalid expression of type: table view.\VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2).Field120=1(0))');
        Observer.Expect('setview|code', 'DB:Ok');
        Observer.Expect('filters after', '');
        Observer.Verify();
    end;

    [Test]
    procedure GetView_TwoFilters_Forms()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT R6969 View Head";
        Again: Record "LT R6969 View Head";
    begin
        Seed();
        Head.SetRange("Document Type", Head."Document Type"::Invoice);
        Head.SetRange(Status, Head.Status::Open);
        Observer.Observe('view false', Head.GetView(false));
        Observer.Observe('view true', Head.GetView(true));
        Again.SetView(Head.GetView(false));
        Observer.Observe('round trip filters', Again.GetFilters());
        Observer.Expect('view false', 'VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(2),Field120=1(0))');
        Observer.Expect('view true', 'VERSION(1) SORTING(Document Type,No.) WHERE(Document Type=FILTER(Invoice),Status=FILTER(Open))');
        Observer.Expect('round trip filters', 'Document Type: Invoice, Status: Open');
        Observer.Verify();
    end;
}
