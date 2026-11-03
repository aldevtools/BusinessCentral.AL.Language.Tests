// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-copy-method
// Scope: in-scope
// Fixtures used: self-contained table 72012, test codeunit 72006
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.Copy (with and without ShareTable), CopyFilters, CopyFilter(Field, Other), Reset, SetRange/SetFilter state after copy, temporary versus normal record, sort order, SetCurrentKey copied, xRec.
// BC versions: 29 (27 and 28 by CI)

table 72012 "LT RcB Copy"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Txt; Text[30]) { }
        field(4; Amt; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp, Id) { }
    }
}

codeunit 72006 "LT RcB Copy Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Rec: Record "LT RcB Copy";
        i: Integer;
    begin
        Rec.DeleteAll();
        for i := 1 to 6 do begin
            Rec.Init();
            Rec.Id := i;
            Rec.Grp := CopyStr('G' + Format(i mod 2), 1, 10);
            Rec.Txt := 'row' + Format(i);
            Rec.Amt := i;
            Rec.Insert();
        end;
    end;

    [Test]
    procedure Copy_CopiesFiltersAndValues()
    var
        A: Record "LT RcB Copy";
        B: Record "LT RcB Copy";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        A.SetRange(Grp, 'G1');
        A.SetFilter(Id, '>1');
        A.FindFirst();
        B.Copy(A);
        Observer.Observe('values', Format(B.Id) + '/' + B.Txt);
        Observer.Observe('filter Grp', B.GetFilter(Grp));
        Observer.Observe('filter Id', B.GetFilter(Id));
        Observer.Observe('count', Format(B.Count()));
        Observer.Observe('filters text', B.GetFilters());
        Observer.Expect('values', '3/row3');
        Observer.Expect('filter Grp', 'G1');
        Observer.Expect('filter Id', '>1');
        Observer.Expect('count', '2');
        Observer.Expect('filters text', 'Id: >1, Grp: G1');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_ReplacesTargetFilters()
    var
        A: Record "LT RcB Copy";
        B: Record "LT RcB Copy";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        B.SetRange(Txt, 'row1');
        B.SetRange(Amt, 5);
        A.SetRange(Grp, 'G0');
        B.Copy(A);
        Observer.Observe('Txt filter', B.GetFilter(Txt));
        Observer.Observe('Amt filter', B.GetFilter(Amt));
        Observer.Observe('Grp filter', B.GetFilter(Grp));
        Observer.Expect('Txt filter', '');
        Observer.Expect('Amt filter', '');
        Observer.Expect('Grp filter', 'G0');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_IsIndependentAfter()
    var
        A: Record "LT RcB Copy";
        B: Record "LT RcB Copy";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        A.SetRange(Grp, 'G1');
        B.Copy(A);
        B.SetRange(Grp, 'G0');
        Observer.Observe('A filter', A.GetFilter(Grp));
        Observer.Observe('B filter', B.GetFilter(Grp));
        A.Reset();
        Observer.Observe('B after A reset', B.GetFilter(Grp));
        B.FindFirst();
        A.Id := 123;
        Observer.Observe('B id', Format(B.Id));
        Observer.Expect('A filter', 'G1');
        Observer.Expect('B filter', 'G0');
        Observer.Expect('B after A reset', 'G0');
        Observer.Expect('B id', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_CurrentKeyAndOrder()
    var
        A: Record "LT RcB Copy";
        B: Record "LT RcB Copy";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        A.SetCurrentKey(Grp, Id);
        A.Ascending(false);
        A.FindFirst();
        Observer.Observe('A first', Format(A.Id));
        B.Copy(A);
        B.FindFirst();
        Observer.Observe('B first', Format(B.Id));
        Observer.Observe('B ascending', Format(B.Ascending()));
        Observer.Observe('B key', B.CurrentKey());
        Observer.Expect('A first', '5');
        Observer.Expect('B first', '5');
        Observer.Expect('B ascending', 'No');
        Observer.Expect('B key', 'Grp,Id');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_TemporaryShareTable()
    var
        A: Record "LT RcB Copy" temporary;
        B: Record "LT RcB Copy" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        A.Id := 1;
        A.Insert();
        B.Copy(A, true);
        Observer.Observe('shared count', Format(B.Count()));
        B.Id := 2;
        B.Insert();
        Observer.Observe('A sees insert', Format(A.Count()));
        Observer.Observe('temporary', Format(B.IsTemporary()));
        Observer.Expect('shared count', '1');
        Observer.Expect('A sees insert', '2');
        Observer.Expect('temporary', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_TemporaryNoShare()
    var
        A: Record "LT RcB Copy" temporary;
        B: Record "LT RcB Copy" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        A.Id := 1;
        A.Insert();
        B.Copy(A);
        Observer.Observe('B count', Format(B.Count()));
        B.Id := 2;
        B.Insert();
        Observer.Observe('A count', Format(A.Count()));
        Observer.Observe('B count after', Format(B.Count()));
        Observer.Expect('B count', '0');
        Observer.Expect('A count', '1');
        Observer.Expect('B count after', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_NormalIntoTemporary_ShareTable()
    var
        Normal: Record "LT RcB Copy";
        Tmp: Record "LT RcB Copy" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Tmp.Id := 100;
        Tmp.Insert();
        Normal.SetRange(Id, 1, 3);
        Tmp.Copy(Normal);
        Observer.Observe('temp stays temp', Format(Tmp.IsTemporary()));
        Observer.Observe('temp count', Format(Tmp.Count()));
        Observer.Observe('filter', Tmp.GetFilter(Id));
        Observer.Expect('temp stays temp', 'Yes');
        Observer.Expect('temp count', '0');
        Observer.Expect('filter', '1..3');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilters_Basic()
    var
        A: Record "LT RcB Copy";
        B: Record "LT RcB Copy";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        A.SetRange(Grp, 'G0');
        A.SetFilter(Amt, '>2');
        A.Id := 55;
        B.Id := 7;
        B.SetRange(Txt, 'x');
        B.CopyFilters(A);
        Observer.Observe('Grp', B.GetFilter(Grp));
        Observer.Observe('Amt', B.GetFilter(Amt));
        Observer.Observe('Txt replaced', '[' + B.GetFilter(Txt) + ']');
        Observer.Observe('B id untouched', Format(B.Id));
        Observer.Observe('count', Format(B.Count()));
        Observer.Expect('Grp', 'G0');
        Observer.Expect('Amt', '>2');
        Observer.Expect('Txt replaced', '[]');
        Observer.Expect('B id untouched', '7');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilters_FromUnfiltered()
    var
        A: Record "LT RcB Copy";
        B: Record "LT RcB Copy";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        B.SetRange(Grp, 'G0');
        B.CopyFilters(A);
        Observer.Observe('cleared', '[' + B.GetFilter(Grp) + ']');
        Observer.Observe('has filter', Format(B.HasFilter()));
        Observer.Expect('cleared', '[]');
        Observer.Expect('has filter', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilters_DoesNotCopySortOrder()
    var
        A: Record "LT RcB Copy";
        B: Record "LT RcB Copy";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        A.SetCurrentKey(Grp, Id);
        A.Ascending(false);
        A.SetRange(Grp, 'G1');
        B.CopyFilters(A);
        B.FindFirst();
        Observer.Observe('B first', Format(B.Id));
        Observer.Observe('B key', B.CurrentKey());
        Observer.Observe('B asc', Format(B.Ascending()));
        Observer.Expect('B first', '1');
        Observer.Expect('B key', 'Id');
        Observer.Expect('B asc', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilter_Field()
    var
        A: Record "LT RcB Copy";
        B: Record "LT RcB Copy";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        A.SetFilter(Id, '2..4');
        A.SetRange(Grp, 'G1');
        B.CopyFilter(Id, B.Id);
        Observer.Observe('self copy', '[' + B.GetFilter(Id) + ']');
        A.CopyFilter(Id, B.Id);
        Observer.Observe('Id', B.GetFilter(Id));
        Observer.Observe('Grp not copied', '[' + B.GetFilter(Grp) + ']');
        asserterror A.CopyFilter(Grp, B.Txt);
        Observer.ObserveError('af252');
        Observer.Observe('other field', B.GetFilter(Txt));
        A.CopyFilter(Amt, B.Amt);
        Observer.Observe('unfiltered source clears', '[' + B.GetFilter(Amt) + ']');
        Observer.Expect('self copy', '[]');
        Observer.Expect('Id', '2..4');
        Observer.Expect('Grp not copied', '[]');
        Observer.Expect('af252|text', 'The type of the constant must be compatible with that of the Txt field, and the length of the constant must not exceed the length of the field.\\Type: Text <-- Code\Field: Txt <-- Grp\Table: LT RcB Copy');
        Observer.Expect('af252|code', 'NCLCSRTS:TableEqualValue');
        Observer.Expect('other field', '');
        Observer.Expect('unfiltered source clears', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure CopyFilter_OverwritesTarget()
    var
        A: Record "LT RcB Copy";
        B: Record "LT RcB Copy";
        Observer: Codeunit "Probe Observer";
    begin
        A.SetRange(Id, 3);
        B.SetRange(Id, 1, 2);
        B.CopyFilter(Id, B.Id);
        Observer.Observe('self', B.GetFilter(Id));
        A.CopyFilter(Id, B.Id);
        Observer.Observe('overwritten', B.GetFilter(Id));
        Observer.Expect('self', '1..2');
        Observer.Expect('overwritten', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_TransfersPosition()
    var
        A: Record "LT RcB Copy";
        B: Record "LT RcB Copy";
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        A.FindSet();
        A.Next();
        B.Copy(A);
        Observer.Observe('B id', Format(B.Id));
        Observer.Observe('next from B', Format(B.Next()));
        Observer.Observe('B id after next', Format(B.Id));
        Observer.Expect('B id', '2');
        Observer.Expect('next from B', '1');
        Observer.Expect('B id after next', '3');
        Observer.Verify();
    end;
}
