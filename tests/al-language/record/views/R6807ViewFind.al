// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-find-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 94520 - 94522 (writer R6807)
// Pins al-runner issue 6807 (values measured on BC 28.5; 27.5 and 29.0 by the CI matrix): Find, Find('='), Find('>'), Find('<'), Next, Count, IsEmpty and FindFirst honour a filter set after the row was read with Get, in every shape (SetView, SetRange, SetFilter, CopyFilters, field-form CopyFilter, Copy, FilterGroup, view round trip), on a stored field and on a FlowField, on a Record and on a RecordRef; SetRecFilter keeps the row.
// Probe: al-runner issue 6807. A row read with Get and then narrowed by SetView / SetRange / SetFilter / CopyFilters / FilterGroup, on a stored
//   field and on a FlowField (Cnt, count of child rows), on a Record and on a RecordRef: what Find(), Find('='), Count, IsEmpty,
//   FindFirst, Next, Find('>') and Find('<') answer. Rows: A (one child), B (none), C (one child). Cases that fail A: svStored (No. = B),
//   FlowZero (Cnt = 0, A has 1); passing controls: svFlowSome, sfFlowSome, ffFlowSome. viewThenGet reads A under the failing filter.

table 94520 "LT R6807 Parent"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT R6807 Child" where(Par = field("No.")));
            Editable = false;
        }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

table 94521 "LT R6807 Child"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Par; Code[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 94522 "LT R6807 View Find"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        P: Record "LT R6807 Parent";
        C: Record "LT R6807 Child";
    begin
        P.DeleteAll();
        C.DeleteAll();
        P."No." := 'A'; P.Insert();
        P."No." := 'B'; P.Insert();
        P."No." := 'C'; P.Insert();
        C.Id := 1; C.Par := 'A'; C.Insert();
        C.Id := 2; C.Par := 'C'; C.Insert();
    end;

    local procedure ViewNo(): Text
    var
        Q: Record "LT R6807 Parent";
    begin
        Q.SetRange("No.", 'B');
        exit(Q.GetView(false));
    end;

    local procedure ViewZero(): Text
    var
        Q: Record "LT R6807 Parent";
    begin
        Q.SetRange(Cnt, 0);
        exit(Q.GetView(false));
    end;

    local procedure ViewSome(): Text
    var
        Q: Record "LT R6807 Parent";
    begin
        Q.SetFilter(Cnt, '>%1', 0);
        exit(Q.GetView(false));
    end;

    local procedure RecApply(var P: Record "LT R6807 Parent"; CaseName: Text)
    var
        Q: Record "LT R6807 Parent";
    begin
        case CaseName of
            'svStored':
                begin
                    P.SetView(ViewNo());
                end;
            'svFlowZero':
                begin
                    P.SetView(ViewZero());
                end;
            'svFlowSome':
                begin
                    P.SetView(ViewSome());
                end;
            'svFlowZeroCalc':
                begin
                    P.CalcFields(Cnt); P.SetView(ViewZero());
                end;
            'srFlowZero':
                begin
                    P.SetRange(Cnt, 0);
                end;
            'sfFlowZero':
                begin
                    P.SetFilter(Cnt, '0');
                end;
            'sfFlowSome':
                begin
                    P.SetFilter(Cnt, '>%1', 0);
                end;
            'srStored':
                begin
                    P.SetRange("No.", 'B');
                end;
            'fgFlowZero':
                begin
                    P.FilterGroup(2); P.SetView(ViewZero()); P.FilterGroup(0);
                end;
            'fgSetRangeFlowZero':
                begin
                    P.FilterGroup(2); P.SetRange(Cnt, 0); P.FilterGroup(0);
                end;
            'copyFlowZero':
                begin
                    Q.SetRange(Cnt, 0); P.CopyFilters(Q);
                end;
            'copyStored':
                begin
                    Q.SetRange("No.", 'B'); P.CopyFilters(Q);
                end;
            'viewThenGet':
                begin
                    P.SetView(ViewZero()); P.Get('A');
                end;
            'viewThenReset':
                begin
                    P.SetView(ViewZero()); P.Reset();
                end;
            'copyFilterFieldFlowZero':
                begin
                    Q.SetRange(Cnt, 0); Q.CopyFilter(Cnt, P.Cnt);
                end;
            'copyFilterFieldStored':
                begin
                    Q.SetRange("No.", 'B'); Q.CopyFilter("No.", P."No.");
                end;
            'setRecFilterOwn':
                begin
                    P.SetRecFilter();
                end;
            'setRecFilterOther':
                begin
                    P."No." := 'B'; P.SetRecFilter();
                end;
            'copyAfterGet':
                begin
                    Q := P; Q.SetRange(Cnt, 0); P.Copy(Q);
                end;
        end;
    end;

    local procedure RecProbe(CaseName: Text; var Observer: Codeunit "Probe Observer")
    var
        P: Record "LT R6807 Parent";
    begin
        Seed();
        P.Get('A');
        RecApply(P, CaseName);
        Observer.Observe('find', Format(P.Find()));
        Observer.Observe('findEq', Format(P.Find('=')));
        Observer.Observe('count', Format(P.Count()));
        Observer.Observe('isEmpty', Format(P.IsEmpty()));
        Observer.Observe('findFirst', Format(P.FindFirst()) + '/' + P."No.");
        Clear(P);
        P.Get('A');
        RecApply(P, CaseName);
        Observer.Observe('next', Format(P.Next()) + '/' + P."No.");
        Clear(P);
        P.Get('A');
        RecApply(P, CaseName);
        Observer.Observe('findGt', Format(P.Find('>')) + '/' + P."No.");
        Clear(P);
        P.Get('C');
        RecApply(P, CaseName);
        Observer.Observe('findLtFromC', Format(P.Find('<')) + '/' + P."No.");
    end;

    local procedure RefApply(var R: RecordRef; CaseName: Text; Id: RecordId)
    var
        Q: Record "LT R6807 Parent";
        R2: RecordRef;
        F: FieldRef;
    begin
        case CaseName of
            'svStored':
                begin
                    R.SetView(ViewNo());
                end;
            'svFlowZero':
                begin
                    R.SetView(ViewZero());
                end;
            'svFlowSome':
                begin
                    R.SetView(ViewSome());
                end;
            'svFlowZeroCalc':
                begin
                    F := R.Field(3); F.CalcField(); R.SetView(ViewZero());
                end;
            'frFlowZero':
                begin
                    F := R.Field(3); F.SetRange(0);
                end;
            'ffFlowZero':
                begin
                    F := R.Field(3); F.SetFilter('0');
                end;
            'ffFlowSome':
                begin
                    F := R.Field(3); F.SetFilter('>%1', 0);
                end;
            'frStored':
                begin
                    F := R.Field(1); F.SetRange('B');
                end;
            'fgFlowZero':
                begin
                    R.FilterGroup(2); R.SetView(ViewZero()); R.FilterGroup(0);
                end;
            'fgFieldRangeFlowZero':
                begin
                    R.FilterGroup(2); F := R.Field(3); F.SetRange(0); R.FilterGroup(0);
                end;
            'viewRoundTripFlowZero':
                begin
                    Q.SetRange(Cnt, 0); R2.GetTable(Q); R.SetView(R2.GetView(false));
                end;
            'viewRoundTripStored':
                begin
                    Q.SetRange("No.", 'B'); R2.GetTable(Q); R.SetView(R2.GetView(false));
                end;
            'viewThenGet':
                begin
                    R.SetView(ViewZero()); R.Get(Id);
                end;
            'viewThenReset':
                begin
                    R.SetView(ViewZero()); R.Reset();
                end;
            'setRecFilterOwn':
                begin
                    R.SetRecFilter();
                end;
            'setRecFilterOther':
                begin
                    F := R.Field(1); F.Value := 'B'; R.SetRecFilter();
                end;
        end;
    end;

    local procedure RefProbe(CaseName: Text; var Observer: Codeunit "Probe Observer")
    var
        P: Record "LT R6807 Parent";
        R: RecordRef;
    begin
        Seed();
        P.Get('A');
        R.Open(Database::"LT R6807 Parent");
        R.Get(P.RecordId());
        RefApply(R, CaseName, P.RecordId());
        Observer.Observe('find', Format(R.Find()));
        Observer.Observe('findEq', Format(R.Find('=')));
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('isEmpty', Format(R.IsEmpty()));
        Observer.Observe('findFirst', Format(R.FindFirst()) + '/' + Format(R.Field(1).Value));
        R.Close();
        R.Open(Database::"LT R6807 Parent");
        R.Get(P.RecordId());
        RefApply(R, CaseName, P.RecordId());
        Observer.Observe('next', Format(R.Next()) + '/' + Format(R.Field(1).Value));
        R.Close();
        R.Open(Database::"LT R6807 Parent");
        R.Get(P.RecordId());
        RefApply(R, CaseName, P.RecordId());
        Observer.Observe('findGt', Format(R.Find('>')) + '/' + Format(R.Field(1).Value));
        R.Close();
        P.Get('C');
        R.Open(Database::"LT R6807 Parent");
        R.Get(P.RecordId());
        RefApply(R, CaseName, P.RecordId());
        Observer.Observe('findLtFromC', Format(R.Find('<')) + '/' + Format(R.Field(1).Value));
    end;

    [Test]
    procedure Rec_svStored()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('svStored', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_svFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('svFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_svFlowSome()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'Yes');
        Observer.Expect('findEq', 'Yes');
        Observer.Expect('count', '2');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/A');
        Observer.Expect('next', '1/C');
        Observer.Expect('findGt', 'Yes/C');
        Observer.Expect('findLtFromC', 'Yes/A');
        RecProbe('svFlowSome', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_svFlowZeroCalc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('svFlowZeroCalc', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_srFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('srFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_sfFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('sfFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_sfFlowSome()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'Yes');
        Observer.Expect('findEq', 'Yes');
        Observer.Expect('count', '2');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/A');
        Observer.Expect('next', '1/C');
        Observer.Expect('findGt', 'Yes/C');
        Observer.Expect('findLtFromC', 'Yes/A');
        RecProbe('sfFlowSome', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_srStored()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('srStored', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_fgFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('fgFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_fgSetRangeFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('fgSetRangeFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_copyFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('copyFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_copyStored()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('copyStored', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_viewThenGet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'No/A');
        RecProbe('viewThenGet', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_viewThenReset()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'Yes');
        Observer.Expect('findEq', 'Yes');
        Observer.Expect('count', '3');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/A');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('viewThenReset', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_copyFilterFieldFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('copyFilterFieldFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_copyFilterFieldStored()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('copyFilterFieldStored', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_setRecFilterOwn()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'Yes');
        Observer.Expect('findEq', 'Yes');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/A');
        Observer.Expect('next', '0/A');
        Observer.Expect('findGt', 'No/A');
        Observer.Expect('findLtFromC', 'No/C');
        RecProbe('setRecFilterOwn', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_setRecFilterOther()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'Yes');
        Observer.Expect('findEq', 'Yes');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '0/B');
        Observer.Expect('findGt', 'No/B');
        Observer.Expect('findLtFromC', 'No/B');
        RecProbe('setRecFilterOther', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Rec_copyAfterGet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RecProbe('copyAfterGet', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_svStored()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RefProbe('svStored', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_svFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RefProbe('svFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_svFlowSome()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'Yes');
        Observer.Expect('findEq', 'Yes');
        Observer.Expect('count', '2');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/A');
        Observer.Expect('next', '1/C');
        Observer.Expect('findGt', 'Yes/C');
        Observer.Expect('findLtFromC', 'Yes/A');
        RefProbe('svFlowSome', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_svFlowZeroCalc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RefProbe('svFlowZeroCalc', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_frFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RefProbe('frFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_ffFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RefProbe('ffFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_ffFlowSome()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'Yes');
        Observer.Expect('findEq', 'Yes');
        Observer.Expect('count', '2');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/A');
        Observer.Expect('next', '1/C');
        Observer.Expect('findGt', 'Yes/C');
        Observer.Expect('findLtFromC', 'Yes/A');
        RefProbe('ffFlowSome', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_frStored()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RefProbe('frStored', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_fgFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RefProbe('fgFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_fgFieldRangeFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RefProbe('fgFieldRangeFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_viewRoundTripFlowZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RefProbe('viewRoundTripFlowZero', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_viewRoundTripStored()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RefProbe('viewRoundTripStored', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_viewThenGet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('findEq', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RefProbe('viewThenGet', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_viewThenReset()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'Yes');
        Observer.Expect('findEq', 'Yes');
        Observer.Expect('count', '3');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/A');
        Observer.Expect('next', '1/B');
        Observer.Expect('findGt', 'Yes/B');
        Observer.Expect('findLtFromC', 'Yes/B');
        RefProbe('viewThenReset', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_setRecFilterOwn()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'Yes');
        Observer.Expect('findEq', 'Yes');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/A');
        Observer.Expect('next', '0/A');
        Observer.Expect('findGt', 'No/A');
        Observer.Expect('findLtFromC', 'No/C');
        RefProbe('setRecFilterOwn', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_setRecFilterOther()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Expect('find', 'Yes');
        Observer.Expect('findEq', 'Yes');
        Observer.Expect('count', '1');
        Observer.Expect('isEmpty', 'No');
        Observer.Expect('findFirst', 'Yes/B');
        Observer.Expect('next', '0/B');
        Observer.Expect('findGt', 'No/B');
        Observer.Expect('findLtFromC', 'No/B');
        RefProbe('setRecFilterOther', Observer);
        Observer.Verify();
    end;

    [Test]
    procedure Ref_GetTableAfterRecordView()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "LT R6807 Parent";
        R: RecordRef;
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('getView', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(0))');
        Seed();
        P.Get('A');
        P.SetView(ViewZero());
        R.GetTable(P);
        Observer.Observe('find', Format(R.Find()));
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('getView', R.GetView(false));
        Observer.Verify();
    end;

    [Test]
    procedure Ref_ViewSetAfterGetTable()
    var
        Observer: Codeunit "Probe Observer";
        P: Record "LT R6807 Parent";
        R: RecordRef;
    begin
        Observer.Expect('find', 'No');
        Observer.Expect('count', '1');
        Observer.Expect('getView', 'VERSION(1) SORTING(Field1) WHERE(Field3=1(0))');
        Seed();
        P.Get('A');
        R.GetTable(P);
        R.SetView(ViewZero());
        Observer.Observe('find', Format(R.Find()));
        Observer.Observe('count', Format(R.Count()));
        Observer.Observe('getView', R.GetView(false));
        Observer.Verify();
    end;
}
