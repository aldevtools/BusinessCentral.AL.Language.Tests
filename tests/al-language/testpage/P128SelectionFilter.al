// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-setselectionfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73163, log 73164 (SingleInstance, used only by test codeunit 73166), page 73165, test codeunit 73166
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CurrPage.SetSelectionFilter(Record) into a record that ALREADY has filters: a filter on another field, a filter on the key field, a range on the key field, a mark and MarkedOnly, the
// record copied from Rec (the page's own filters), a temporary record with rows. Count, GetFilters, the filter of the key field and HasFilter are logged after the call. (A fresh record is pinned in
// pages/lt-page-runtime/P82CurrPage.al.)
// BC versions: 29 (27 and 28 by CI)

table 73163 "LT P128 Sel Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Qty; Integer) { }
        field(3; Grp; Integer) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 73164 "LT P128 Sel Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Add(Value: Text)
    begin
        Lines += Value + ' || ';
    end;

    procedure Joined(): Text
    begin
        exit(Lines);
    end;
}

page 73165 "LT P128 Sel List"
{
    PageType = List;
    SourceTable = "LT P128 Sel Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Qty; Rec.Qty)
                {
                    ApplicationArea = All;
                }
                field(Grp; Rec.Grp)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelOtherField)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Sel: Record "LT P128 Sel Row";
                begin
                    Sel.SetRange(Grp, 1);
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('other field Grp=1', Sel);
                end;
            }
            action(SelKeyFilter)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Sel: Record "LT P128 Sel Row";
                begin
                    Sel.SetFilter(Code, 'A|C');
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('key filter A|C', Sel);
                end;
            }
            action(SelKeyRange)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Sel: Record "LT P128 Sel Row";
                begin
                    Sel.SetRange(Code, 'B', 'D');
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('key range B..D', Sel);
                end;
            }
            action(SelMarked)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Sel: Record "LT P128 Sel Row";
                begin
                    Sel.Get('A');
                    Sel.Mark(true);
                    Sel.MarkedOnly(true);
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('marked A only', Sel);
                end;
            }
            action(SelCopyOfRec)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Sel: Record "LT P128 Sel Row";
                begin
                    Sel.Copy(Rec);
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('copy of Rec', Sel);
                end;
            }
            action(SelTemporary)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Sel: Record "LT P128 Sel Row" temporary;
                begin
                    Sel.Code := 'Z';
                    Sel.Insert();
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('temporary with row Z', Sel);
                end;
            }
            action(SelTwice)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Sel: Record "LT P128 Sel Row";
                begin
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('first call', Sel);
                    CurrPage.SetSelectionFilter(Sel);
                    LogSel('second call on the same record', Sel);
                end;
            }
        }
    }

    local procedure LogSel(Where: Text; var Sel: Record "LT P128 Sel Row")
    var
        Log: Codeunit "LT P128 Sel Log";
    begin
        Log.Add(Where + ': count=' + Format(Sel.Count()) + ' filters=[' + Sel.GetFilters() + '] codefilter=[' + Sel.GetFilter(Code) + '] hasfilter=' + Format(Sel.HasFilter()) + ' markedonly=' + Format(Sel.MarkedOnly()));
    end;
}

codeunit 73166 "LT P128 Sel Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P128 Sel Row";
        Log: Codeunit "LT P128 Sel Log";
    begin
        Row.DeleteAll();
        AddRow('A', 10, 1);
        AddRow('B', 20, 1);
        AddRow('C', 30, 2);
        AddRow('D', 40, 2);
        Log.Reset();
    end;

    local procedure AddRow(RowCode: Code[10]; Qty: Integer; Grp: Integer)
    var
        Row: Record "LT P128 Sel Row";
    begin
        Row.Code := RowCode;
        Row.Qty := Qty;
        Row.Grp := Grp;
        Row.Insert();
    end;

    [Test]
    procedure P128_SetSelectionFilter_IntoRecordsWithFilters_SecondRow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P128 Sel Log";
        List: TestPage "LT P128 Sel List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey('B');
        List.SelOtherField.Invoke();
        List.SelKeyFilter.Invoke();
        List.SelKeyRange.Invoke();
        Observer.Observe('log', Log.Joined());
        List.Close();
        Observer.Expect('log', 'other field Grp=1: count=1 filters=[Code: B] codefilter=[B] hasfilter=Yes markedonly=No || key filter A|C: count=1 filters=[Code: B] codefilter=[B] hasfilter=Yes markedonly=No || key range B..D: count=1 filters=[Code: B] codefilter=[B] hasfilter=Yes markedonly=No || ');
        Observer.Verify();
    end;

    [Test]
    procedure P128_SetSelectionFilter_IntoRecordsWithFilters_MarkCopyTemporary()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P128 Sel Log";
        List: TestPage "LT P128 Sel List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey('C');
        List.SelMarked.Invoke();
        List.SelCopyOfRec.Invoke();
        List.SelTemporary.Invoke();
        Observer.Observe('log', Log.Joined());
        List.Close();
        Observer.Expect('log', 'marked A only: count=1 filters=[Marked: Yes, Code: C] codefilter=[C] hasfilter=Yes markedonly=Yes || copy of Rec: count=1 filters=[Code: C] codefilter=[C] hasfilter=Yes markedonly=No || temporary with row Z: count=0 filters=[Code: C] codefilter=[C] hasfilter=Yes markedonly=No || ');
        Observer.Verify();
    end;

    [Test]
    procedure P128_SetSelectionFilter_CalledTwiceOnOneRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P128 Sel Log";
        List: TestPage "LT P128 Sel List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey('B');
        List.SelTwice.Invoke();
        List.GoToKey('D');
        List.SelCopyOfRec.Invoke();
        Observer.Observe('log', Log.Joined());
        List.Close();
        Observer.Expect('log', 'first call: count=1 filters=[Code: B] codefilter=[B] hasfilter=Yes markedonly=No || second call on the same record: count=1 filters=[Code: B] codefilter=[B] hasfilter=Yes markedonly=No || copy of Rec: count=1 filters=[Code: D] codefilter=[D] hasfilter=Yes markedonly=No || ');
        Observer.Verify();
    end;

    [Test]
    procedure P128_SetSelectionFilter_PageWithOwnFilter_CopyOfRec()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P128 Sel Log";
        List: TestPage "LT P128 Sel List";
    begin
        Seed();
        List.OpenView();
        List.Filter.SetFilter(Grp, '2');
        List.First();
        List.SelCopyOfRec.Invoke();
        List.SelOtherField.Invoke();
        Observer.Observe('log', Log.Joined());
        List.Close();
        Observer.Expect('log', 'copy of Rec: count=1 filters=[Code: C] codefilter=[C] hasfilter=Yes markedonly=No || other field Grp=1: count=1 filters=[Code: C] codefilter=[C] hasfilter=Yes markedonly=No || ');
        Observer.Verify();
    end;
}
