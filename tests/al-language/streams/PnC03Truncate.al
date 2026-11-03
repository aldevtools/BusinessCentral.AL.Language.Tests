// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-truncate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Rec (71080), LT PnC Child (71081), LT PnC Media (71082)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Truncate "Truncate on a table with Media or MediaSet fields and on a temporary record raise the pinned texts"
// BC versions: 29 (27 and 28 by CI)

codeunit 71103 "LT PnC Truncate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Truncate_Plain_ThenCount()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "LT PnC Child";
    begin
        C.DeleteAll();
        C."Entry No." := 1;
        C.Insert();
        C."Entry No." := 2;
        C.Insert();
        Observer.Observe('before', Format(C.Count()));
        C.Truncate();
        Observer.Observe('after', Format(C.Count()));
        Observer.Observe('isEmpty', Format(C.IsEmpty()));
        Observer.Expect('before', '2');
        Observer.Expect('after', '0');
        Observer.Expect('isEmpty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Truncate_WithFilter()
    var
        Observer: Codeunit "Probe Observer";
        C: Record "LT PnC Child";
    begin
        C.DeleteAll();
        C."Entry No." := 1;
        C.Insert();
        C."Entry No." := 2;
        C.Insert();
        C.SetRange("Entry No.", 1);
        C.Truncate();
        C.Reset();
        Observer.Observe('afterFilteredTruncate', Format(C.Count()));
        Observer.Expect('afterFilteredTruncate', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Truncate_MediaTable()
    var
        Observer: Codeunit "Probe Observer";
        M: Record "LT PnC Media";
    begin
        M.DeleteAll();
        M."No." := 1;
        M.Insert();
        asserterror M.Truncate();
        Observer.ObserveError('media');
        Observer.Observe('rowsLeft', Format(M.Count()));
        M.DeleteAll();
        Observer.Expect('media|text', 'Truncate is not supported when the field has Media and/or MediaSet fields.');
        Observer.Expect('media|code', 'DB:Ok');
        Observer.Expect('rowsLeft', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Truncate_MediaTable_Empty()
    var
        Observer: Codeunit "Probe Observer";
        M: Record "LT PnC Media";
    begin
        M.DeleteAll();
        asserterror M.Truncate();
        Observer.ObserveError('mediaEmpty');
        Observer.Expect('mediaEmpty|text', 'Truncate is not supported when the field has Media and/or MediaSet fields.');
        Observer.Expect('mediaEmpty|code', 'DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure Truncate_TemporaryRecord()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PnC Rec" temporary;
    begin
        T."No." := 1;
        T.Insert();
        asserterror T.Truncate();
        Observer.ObserveError('temporary');
        Observer.Observe('rowsLeft', Format(T.Count()));
        T.DeleteAll();
        asserterror T.Truncate();
        Observer.ObserveError('temporaryEmpty');
        Observer.Expect('temporary|text', 'Temporary tables does not support truncation.');
        Observer.Expect('temporary|code', 'DB:Ok');
        Observer.Expect('rowsLeft', '1');
        Observer.Expect('temporaryEmpty|text', 'Temporary tables does not support truncation.');
        Observer.Expect('temporaryEmpty|code', 'DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure Truncate_TableWithBlobAndFlowField()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnC Rec";
    begin
        R.DeleteAll();
        R."No." := 1;
        R.Insert();
        R.Truncate();
        Observer.Observe('count', Format(R.Count()));
        Observer.Expect('count', '0');
        Observer.Verify();
    end;
}
