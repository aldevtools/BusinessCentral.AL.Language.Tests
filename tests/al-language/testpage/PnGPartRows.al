// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG Doc Parts (70138), LT PnG Doc (70137), LT PnG Part (70136), LT PnG Head (70131), LT PnG Line (70132), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md rows 72 (Parts: New()/Next() onto the blank line of a part whose control says Editable = false), 74 (Parts: link to a host with no row, a part moves back to its first row when the host lands on a row), 75 (Parts: a part's pending row is saved before the part is pointed at another host row; a refused save raises) and 76 (Parts: a SubPageView where-filter on the field the SubPageLink also filters)
// Facts: New / Next / SetValue / First on an editable and a read-only part control, stored rows after a host move, part position after host moves, rows of parts with SubPageView
// BC versions: 29 (27 and 28 by CI)

codeunit 70181 "LT PnG Part Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Head: Record "LT PnG Head";
        Line: Record "LT PnG Line";
        i: Integer;
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Head."Code" := 'D1';
        Head.Insert();
        Head."Code" := 'D2';
        Head.Insert();
        for i := 1 to 3 do begin
            Line."Head Code" := 'D1';
            Line."Line No." := i * 10000;
            Line.Descr := 'D1 line ' + Format(i * 10000);
            Line.Insert();
        end;
        Line."Head Code" := 'D2';
        Line."Line No." := 10000;
        Line.Descr := 'D2 line 10000';
        Line.Insert();
    end;

    [Test]
    procedure ReadOnlyPartNewAndNext()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT PnG Doc Parts";
        Line: Record "LT PnG Line";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('ro-first', Format(Doc.ReadOnlyLines.First()));
        Observer.Observe('ro-descr', Doc.ReadOnlyLines.DescrCtl.Value());
        Observer.Observe('ro-next-1', Format(Doc.ReadOnlyLines.Next()));
        Observer.Observe('ro-next-2', Format(Doc.ReadOnlyLines.Next()));
        Observer.Observe('ro-next-3-onto-blank', Format(Doc.ReadOnlyLines.Next()));
        Observer.Observe('ro-descr-on-blank', Doc.ReadOnlyLines.DescrCtl.Value());
        Observer.Observe('ro-next-4', Format(Doc.ReadOnlyLines.Next()));
        asserterror begin Doc.ReadOnlyLines.New(); Error('LT-NOERROR'); end;
        Observer.ObserveError('ro-new');
        Observer.Observe('ro-stored-lines', Format(Line.Count()));
        Doc.Close();
        Observer.Expect('ro-first', 'Yes');
        Observer.Expect('ro-descr', 'D1 line 10000');
        Observer.Expect('ro-next-1', 'Yes');
        Observer.Expect('ro-next-2', 'Yes');
        Observer.Expect('ro-next-3-onto-blank', 'No');
        Observer.Expect('ro-descr-on-blank', 'D1 line 30000');
        Observer.Expect('ro-next-4', 'No');
        Observer.Expect('ro-new|text', 'LT-NOERROR');
        Observer.Expect('ro-new|code', 'Dialog');
        Observer.Expect('ro-stored-lines', '0');
        Observer.Verify();
    end;

    [Test]
    procedure EditablePartNewAndNext()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT PnG Doc Parts";
        Line: Record "LT PnG Line";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('pl-first', Format(Doc.PlainLines.First()));
        Observer.Observe('pl-next-1', Format(Doc.PlainLines.Next()));
        Observer.Observe('pl-next-2', Format(Doc.PlainLines.Next()));
        Observer.Observe('pl-next-3-onto-blank', Format(Doc.PlainLines.Next()));
        Observer.Observe('pl-descr-on-blank', Doc.PlainLines.DescrCtl.Value());
        Observer.Observe('pl-next-4', Format(Doc.PlainLines.Next()));
        Doc.PlainLines.New();
        Doc.PlainLines.DescrCtl.SetValue('new via part');
        Observer.Observe('pl-line-no-after-new', Doc.PlainLines.LineNoCtl.Value());
        Observer.Observe('pl-head-after-new', Doc.PlainLines.HeadCtl.Value());
        Doc.Close();
        Observer.Observe('pl-stored-lines', Format(Line.Count()));
        Line.SetRange(Descr, 'new via part');
        Observer.Observe('pl-stored-new', Format(Line.Count()));
        Observer.Expect('pl-first', 'Yes');
        Observer.Expect('pl-next-1', 'Yes');
        Observer.Expect('pl-next-2', 'Yes');
        Observer.Expect('pl-next-3-onto-blank', 'Yes');
        Observer.Expect('pl-descr-on-blank', '');
        Observer.Expect('pl-next-4', 'No');
        Observer.Expect('pl-line-no-after-new', '0');
        Observer.Expect('pl-head-after-new', 'D1');
        Observer.Expect('pl-stored-lines', '5');
        Observer.Expect('pl-stored-new', '1');
        Observer.Verify();
    end;

    [Test]
    procedure ReadOnlyPartSetValue()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT PnG Doc Parts";
        Line: Record "LT PnG Line";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.ReadOnlyLines.First();
        Observer.Observe('ro-descr-editable', Format(Doc.ReadOnlyLines.DescrCtl.Editable()));
        Doc.ReadOnlyLines.DescrCtl.SetValue('through read only part');
        Observer.Observe('ro-descr-after', Doc.ReadOnlyLines.DescrCtl.Value());
        Doc.Close();
        Line.Get('D1', 10000);
        Observer.Observe('ro-stored-descr', Line.Descr);
        Observer.Expect('ro-descr-editable', 'No');
        Observer.Expect('ro-descr-after', 'through read only part');
        Observer.Expect('ro-stored-descr', 'through read only part');
        Observer.Verify();
    end;

    [Test]
    procedure PendingPartRowSavedWhenHostMoves()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT PnG Doc";
        Line: Record "LT PnG Line";
        Log: Codeunit "LT PnG Log";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.Lines.New();
        Doc.Lines.DescrCtl.SetValue('pending row');
        Line.SetRange(Descr, 'pending row');
        Observer.Observe('stored-before-host-move', Format(Line.Count()));
        Log.Reset();
        Observer.Observe('host-next', Format(Doc.Next()));
        Observer.Observe('stored-after-host-move', Format(Line.Count()));
        Observer.Observe('log', Log.Dump());
        Observer.Observe('part-first-after-move', Format(Doc.Lines.First()));
        Observer.Observe('part-descr-after-move', Doc.Lines.DescrCtl.Value());
        Observer.Observe('host-previous', Format(Doc.Previous()));
        Observer.Observe('part-first-back', Format(Doc.Lines.First()));
        Observer.Observe('part-descr-back', Doc.Lines.DescrCtl.Value());
        Doc.Close();
        Observer.Expect('stored-before-host-move', '0');
        Observer.Expect('host-next', 'Yes');
        Observer.Expect('stored-after-host-move', '1');
        Observer.Expect('log', 'Doc.AGR(D2);Part.AGR(D2/10000)');
        Observer.Expect('part-first-after-move', 'Yes');
        Observer.Expect('part-descr-after-move', 'D2 line 10000');
        Observer.Expect('host-previous', 'Yes');
        Observer.Expect('part-first-back', 'Yes');
        Observer.Expect('part-descr-back', 'D1 line 10000');
        Observer.Verify();
    end;

    [Test]
    procedure PendingPartRowSavedOnHostClose()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT PnG Doc";
        Line: Record "LT PnG Line";
    begin
        Seed();
        Doc.OpenEdit();
        Doc.Lines.New();
        Doc.Lines.DescrCtl.SetValue('pending at close');
        Doc.Close();
        Line.SetRange(Descr, 'pending at close');
        Observer.Observe('stored-after-close', Format(Line.Count()));
        Observer.Expect('stored-after-close', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SubPageViewOnTheLinkedField()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT PnG Doc Parts";
    begin
        Seed();
        Doc.OpenEdit();
        Observer.Observe('same-field-first', Format(Doc.SameFieldViewLines.First()));
        Observer.Observe('same-field-head', Doc.SameFieldViewLines.HeadCtl.Value());
        Observer.Observe('same-field-descr', Doc.SameFieldViewLines.DescrCtl.Value());
        Observer.Observe('host-next', Format(Doc.Next()));
        Observer.Observe('same-field-first-d2', Format(Doc.SameFieldViewLines.First()));
        Observer.Observe('same-field-descr-d2', Doc.SameFieldViewLines.DescrCtl.Value());
        Observer.Observe('view-filtered-first-d2', Format(Doc.ViewFilteredLines.First()));
        Observer.Observe('host-previous', Format(Doc.Previous()));
        Observer.Observe('view-filtered-first', Format(Doc.ViewFilteredLines.First()));
        Observer.Observe('view-filtered-descr', Doc.ViewFilteredLines.DescrCtl.Value());
        Observer.Observe('view-filtered-next', Format(Doc.ViewFilteredLines.Next()));
        Observer.Observe('view-filtered-descr-2', Doc.ViewFilteredLines.DescrCtl.Value());
        Doc.Close();
        Observer.Expect('same-field-first', 'Yes');
        Observer.Expect('same-field-head', 'D1');
        Observer.Expect('same-field-descr', 'D1 line 10000');
        Observer.Expect('host-next', 'Yes');
        Observer.Expect('same-field-first-d2', 'Yes');
        Observer.Expect('same-field-descr-d2', 'D2 line 10000');
        Observer.Expect('view-filtered-first-d2', 'Yes');
        Observer.Expect('host-previous', 'Yes');
        Observer.Expect('view-filtered-first', 'Yes');
        Observer.Expect('view-filtered-descr', 'D1 line 10000');
        Observer.Expect('view-filtered-next', 'Yes');
        Observer.Expect('view-filtered-descr-2', 'D1 line 20000');
        Observer.Verify();
    end;

    [Test]
    procedure PartLinkWithHostWithoutRow()
    var
        Observer: Codeunit "Probe Observer";
        Head: Record "LT PnG Head";
        Line: Record "LT PnG Line";
        Doc: TestPage "LT PnG Doc";
    begin
        Head.DeleteAll();
        Line.DeleteAll();
        Line."Head Code" := '';
        Line."Line No." := 10000;
        Line.Descr := 'orphan with blank head';
        Line.Insert();
        Line."Head Code" := 'D9';
        Line."Line No." := 10000;
        Line.Descr := 'line of a head that does not exist';
        Line.Insert();
        Doc.OpenView();
        Observer.Observe('host-first', Format(Doc.First()));
        Observer.Observe('part-first', Format(Doc.Lines.First()));
        Observer.Observe('part-descr', Doc.Lines.DescrCtl.Value());
        Observer.Observe('part-head', Doc.Lines.HeadCtl.Value());
        Observer.Observe('part-next', Format(Doc.Lines.Next()));
        Doc.Close();
        Observer.Expect('host-first', 'No');
        Observer.Expect('part-first', 'No');
        Observer.Expect('part-descr', '');
        Observer.Expect('part-head', '');
        Observer.Expect('part-next', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure PartReturnsToFirstRowWhenHostMoves()
    var
        Observer: Codeunit "Probe Observer";
        Doc: TestPage "LT PnG Doc";
    begin
        Seed();
        Doc.OpenView();
        Doc.Lines.First();
        Doc.Lines.Next();
        Doc.Lines.Next();
        Observer.Observe('part-at', Doc.Lines.DescrCtl.Value());
        Observer.Observe('host-next', Format(Doc.Next()));
        Observer.Observe('part-at-d2', Doc.Lines.DescrCtl.Value());
        Observer.Observe('host-previous', Format(Doc.Previous()));
        Observer.Observe('part-at-d1-again', Doc.Lines.DescrCtl.Value());
        Observer.Observe('host-goto-d1', Format(Doc.GoToKey('D1')));
        Observer.Observe('part-at-after-goto-same', Doc.Lines.DescrCtl.Value());
        Doc.Lines.Last();
        Observer.Observe('part-at-last', Doc.Lines.DescrCtl.Value());
        Observer.Observe('host-goto-d1-while-on-d1', Format(Doc.GoToKey('D1')));
        Observer.Observe('part-at-after-goto-same-while-last', Doc.Lines.DescrCtl.Value());
        Doc.Close();
        Observer.Expect('part-at', 'D1 line 30000');
        Observer.Expect('host-next', 'Yes');
        Observer.Expect('part-at-d2', 'D2 line 10000');
        Observer.Expect('host-previous', 'Yes');
        Observer.Expect('part-at-d1-again', 'D1 line 30000');
        Observer.Expect('host-goto-d1', 'Yes');
        Observer.Expect('part-at-after-goto-same', 'D1 line 30000');
        Observer.Expect('part-at-last', 'D1 line 30000');
        Observer.Expect('host-goto-d1-while-on-d1', 'Yes');
        Observer.Expect('part-at-after-goto-same-while-last', 'D1 line 30000');
        Observer.Verify();
    end;
}
