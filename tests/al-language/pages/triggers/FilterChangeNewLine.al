// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 72424, page 72425, log codeunit 72426 (SingleInstance, used by test codeunit 72427 only)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: an editable list opened with OpenNew and with OpenEdit over an empty (filtered) result: Filter.SetFilter then SetValue of a non-key field: the stored row's key, the page triggers that run, Next and First.
// BC versions: 29 (27 and 28 by CI)

table 72424 "LT FltNew Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Grp; Code[10]) { }
        field(2; LineNo; Integer) { }
        field(3; Descr; Text[30]) { }
        field(4; Qty; Integer) { }
    }
    keys
    {
        key(PK; Grp, LineNo) { Clustered = true; }
    }
}

codeunit 72426 "LT FltNew Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Clear()
    begin
        Entries := '';
    end;

    procedure Add(What: Text)
    begin
        Entries += What + ';';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}

page 72425 "LT FltNew List"
{
    PageType = List;
    SourceTable = "LT FltNew Row";
    ApplicationArea = All;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(LineNo; Rec.LineNo) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
                field(Qty; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Add('OpenPage');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('NewRecord(' + Rec.Grp + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('InsertRecord(' + Rec.Grp + ',' + Format(Rec.LineNo) + ')');
        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('AfterGetRecord(' + Rec.Grp + ',' + Format(Rec.LineNo) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('AfterGetCurrRecord(' + Rec.Grp + ',' + Format(Rec.LineNo) + ')');
    end;

    var
        Log: Codeunit "LT FltNew Log";
}

codeunit 72427 "LT FltNew Lands On New Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(WithOtherGroup: Boolean)
    var
        R: Record "LT FltNew Row";
        Log: Codeunit "LT FltNew Log";
    begin
        R.DeleteAll();
        if WithOtherGroup then begin
            R.Init();
            R.Grp := 'G9';
            R.LineNo := 1;
            R.Descr := 'other';
            R.Insert();
        end;
        Commit();
        Log.Clear();
    end;

    local procedure Stored(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        R: Record "LT FltNew Row";
        i: Integer;
    begin
        Observer.Observe(Prefix + '_count', Format(R.Count()));
        R.SetFilter(Grp, '<>G9');
        Observer.Observe(Prefix + '_count_not_g9', Format(R.Count()));
        if R.FindFirst() then begin
            Observer.Observe(Prefix + '_grp', R.Grp);
            Observer.Observe(Prefix + '_lineno', Format(R.LineNo));
            Observer.Observe(Prefix + '_descr', R.Descr);
            Observer.Observe(Prefix + '_qty', Format(R.Qty));
        end;
        i := 0;
    end;

    [Test]
    procedure OpenNew_FilterSetFilter_ThenSetValueDescr_StoresRowWithFilterKey()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT FltNew Log";
        TP: TestPage "LT FltNew List";
    begin
        Seed(false);
        TP.OpenNew();
        Observer.Observe('log_after_open', Log.Get());
        TP.Filter.SetFilter(Grp, 'G1');
        Observer.Observe('log_after_filter', Log.Get());
        Observer.Observe('grp_on_page', TP.Grp.Value());
        Observer.Observe('lineno_on_page', TP.LineNo.Value());
        TP.Descr.SetValue('typed');
        Observer.Observe('log_after_setvalue', Log.Get());
        Observer.Observe('grp_after_setvalue', TP.Grp.Value());
        TP.Close();
        Stored(Observer, 's');
        Observer.Expect('log_after_open', 'OpenPage;NewRecord();AfterGetCurrRecord(,0);');
        Observer.Expect('log_after_filter', 'OpenPage;NewRecord();AfterGetCurrRecord(,0);NewRecord(G1);AfterGetCurrRecord(G1,0);NewRecord(G1);AfterGetCurrRecord(G1,0);');
        Observer.Expect('grp_on_page', 'G1');
        Observer.Expect('lineno_on_page', '0');
        Observer.Expect('log_after_setvalue', 'OpenPage;NewRecord();AfterGetCurrRecord(,0);NewRecord(G1);AfterGetCurrRecord(G1,0);NewRecord(G1);AfterGetCurrRecord(G1,0);');
        Observer.Expect('grp_after_setvalue', 'G1');
        Observer.Expect('s_count', '1');
        Observer.Expect('s_count_not_g9', '1');
        Observer.Expect('s_grp', 'G1');
        Observer.Expect('s_lineno', '0');
        Observer.Expect('s_descr', 'typed');
        Observer.Expect('s_qty', '0');
        Observer.Verify();
    end;

    [Test]
    procedure OpenNew_FilterSetFilter_ThenNext_AndFirst()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT FltNew Log";
        TP: TestPage "LT FltNew List";
    begin
        Seed(true);
        TP.OpenNew();
        TP.Filter.SetFilter(Grp, 'G1');
        Observer.Observe('log_after_filter', Log.Get());
        Observer.Observe('first', Format(TP.First()));
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('prev', Format(TP.Previous()));
        Observer.Observe('grp_on_page', TP.Grp.Value());
        Observer.Observe('log_total', Log.Get());
        TP.Close();
        Stored(Observer, 's');
        Observer.Expect('log_after_filter', 'OpenPage;NewRecord();AfterGetCurrRecord(,0);NewRecord(G1);AfterGetCurrRecord(G1,0);NewRecord(G1);AfterGetCurrRecord(G1,0);');
        Observer.Expect('first', 'No');
        Observer.Expect('next', 'No');
        Observer.Expect('prev', 'No');
        Observer.Expect('grp_on_page', 'G1');
        Observer.Expect('log_total', 'OpenPage;NewRecord();AfterGetCurrRecord(,0);NewRecord(G1);AfterGetCurrRecord(G1,0);NewRecord(G1);AfterGetCurrRecord(G1,0);');
        Observer.Expect('s_count', '1');
        Observer.Expect('s_count_not_g9', '0');
        Observer.Verify();
    end;

    [Test]
    procedure OpenEdit_EmptyTable_FilterSetFilter_ThenSetValueDescr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT FltNew Log";
        TP: TestPage "LT FltNew List";
    begin
        Seed(false);
        TP.OpenEdit();
        Observer.Observe('log_after_open', Log.Get());
        TP.Filter.SetFilter(Grp, 'G1');
        Observer.Observe('log_after_filter', Log.Get());
        Observer.Observe('grp_on_page', TP.Grp.Value());
        TP.Descr.SetValue('typed');
        Observer.Observe('log_after_setvalue', Log.Get());
        Observer.Observe('grp_after_setvalue', TP.Grp.Value());
        TP.Close();
        Stored(Observer, 's');
        Observer.Expect('log_after_open', 'OpenPage;NewRecord();AfterGetCurrRecord(,0);NewRecord();AfterGetCurrRecord(,0);');
        Observer.Expect('log_after_filter', 'OpenPage;NewRecord();AfterGetCurrRecord(,0);NewRecord();AfterGetCurrRecord(,0);NewRecord(G1);AfterGetCurrRecord(G1,0);NewRecord(G1);AfterGetCurrRecord(G1,0);');
        Observer.Expect('grp_on_page', 'G1');
        Observer.Expect('log_after_setvalue', 'OpenPage;NewRecord();AfterGetCurrRecord(,0);NewRecord();AfterGetCurrRecord(,0);NewRecord(G1);AfterGetCurrRecord(G1,0);NewRecord(G1);AfterGetCurrRecord(G1,0);');
        Observer.Expect('grp_after_setvalue', 'G1');
        Observer.Expect('s_count', '1');
        Observer.Expect('s_count_not_g9', '1');
        Observer.Expect('s_grp', 'G1');
        Observer.Expect('s_lineno', '0');
        Observer.Expect('s_descr', 'typed');
        Observer.Expect('s_qty', '0');
        Observer.Verify();
    end;

    [Test]
    procedure OpenEdit_FilterToEmptyResult_ThenSetValueDescr_RowExistsInOtherGroup()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT FltNew Log";
        TP: TestPage "LT FltNew List";
    begin
        Seed(true);
        TP.OpenEdit();
        Observer.Observe('grp_first_row', TP.Grp.Value());
        TP.Filter.SetFilter(Grp, 'G1');
        Observer.Observe('log_after_filter', Log.Get());
        Observer.Observe('grp_on_page', TP.Grp.Value());
        Observer.Observe('lineno_on_page', TP.LineNo.Value());
        Observer.Observe('descr_on_page', TP.Descr.Value());
        TP.Descr.SetValue('typed');
        Observer.Observe('log_after_setvalue', Log.Get());
        TP.Close();
        Stored(Observer, 's');
        Observer.Expect('grp_first_row', 'G9');
        Observer.Expect('log_after_filter', 'OpenPage;AfterGetRecord(G9,1);AfterGetRecord(G9,1);AfterGetCurrRecord(G9,1);NewRecord(G1);AfterGetCurrRecord(G1,0);NewRecord(G1);AfterGetCurrRecord(G1,0);');
        Observer.Expect('grp_on_page', 'G1');
        Observer.Expect('lineno_on_page', '0');
        Observer.Expect('descr_on_page', '');
        Observer.Expect('log_after_setvalue', 'OpenPage;AfterGetRecord(G9,1);AfterGetRecord(G9,1);AfterGetCurrRecord(G9,1);NewRecord(G1);AfterGetCurrRecord(G1,0);NewRecord(G1);AfterGetCurrRecord(G1,0);');
        Observer.Expect('s_count', '2');
        Observer.Expect('s_count_not_g9', '1');
        Observer.Expect('s_grp', 'G1');
        Observer.Expect('s_lineno', '0');
        Observer.Expect('s_descr', 'typed');
        Observer.Expect('s_qty', '0');
        Observer.Verify();
    end;

    [Test]
    procedure OpenEdit_FilterToEmptyResult_ThenSetKeyAndDescr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT FltNew Log";
        TP: TestPage "LT FltNew List";
    begin
        Seed(true);
        TP.OpenEdit();
        TP.Filter.SetFilter(Grp, 'G1');
        TP.LineNo.SetValue(10);
        Observer.Observe('log_after_lineno', Log.Get());
        Observer.Observe('grp_on_page', TP.Grp.Value());
        TP.Descr.SetValue('typed');
        Observer.Observe('log_after_descr', Log.Get());
        TP.Close();
        Stored(Observer, 's');
        Observer.Expect('log_after_lineno', 'OpenPage;AfterGetRecord(G9,1);AfterGetRecord(G9,1);AfterGetCurrRecord(G9,1);NewRecord(G1);AfterGetCurrRecord(G1,0);NewRecord(G1);AfterGetCurrRecord(G1,0);');
        Observer.Expect('grp_on_page', 'G1');
        Observer.Expect('log_after_descr', 'OpenPage;AfterGetRecord(G9,1);AfterGetRecord(G9,1);AfterGetCurrRecord(G9,1);NewRecord(G1);AfterGetCurrRecord(G1,0);NewRecord(G1);AfterGetCurrRecord(G1,0);InsertRecord(G1,10);');
        Observer.Expect('s_count', '2');
        Observer.Expect('s_count_not_g9', '1');
        Observer.Expect('s_grp', 'G1');
        Observer.Expect('s_lineno', '10');
        Observer.Expect('s_descr', 'typed');
        Observer.Expect('s_qty', '0');
        Observer.Verify();
    end;

    [Test]
    procedure OpenEdit_MultiValuedFilter_ThenSetValueDescr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT FltNew Log";
        TP: TestPage "LT FltNew List";
    begin
        Seed(true);
        TP.OpenEdit();
        TP.Filter.SetFilter(Grp, 'G1|G2');
        Observer.Observe('grp_on_page', TP.Grp.Value());
        TP.Descr.SetValue('typed');
        Observer.Observe('log_after_setvalue', Log.Get());
        TP.Close();
        Stored(Observer, 's');
        Observer.Expect('grp_on_page', '');
        Observer.Expect('log_after_setvalue', 'OpenPage;AfterGetRecord(G9,1);AfterGetRecord(G9,1);AfterGetCurrRecord(G9,1);NewRecord();AfterGetCurrRecord(,0);NewRecord();AfterGetCurrRecord(,0);');
        Observer.Expect('s_count', '2');
        Observer.Expect('s_count_not_g9', '1');
        Observer.Expect('s_grp', '');
        Observer.Expect('s_lineno', '0');
        Observer.Expect('s_descr', 'typed');
        Observer.Expect('s_qty', '0');
        Observer.Verify();
    end;

    [Test]
    procedure OpenEdit_FilterOnNonKeyField_ThenSetValueDescr()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT FltNew Log";
        TP: TestPage "LT FltNew List";
    begin
        Seed(true);
        TP.OpenEdit();
        TP.Filter.SetFilter(Qty, '5');
        Observer.Observe('log_after_filter', Log.Get());
        Observer.Observe('qty_on_page', TP.Qty.Value());
        TP.Descr.SetValue('typed');
        Observer.Observe('log_after_setvalue', Log.Get());
        TP.Close();
        Stored(Observer, 's');
        Observer.Expect('log_after_filter', 'OpenPage;AfterGetRecord(G9,1);AfterGetRecord(G9,1);AfterGetCurrRecord(G9,1);NewRecord();AfterGetCurrRecord(,0);NewRecord();AfterGetCurrRecord(,0);');
        Observer.Expect('qty_on_page', '0');
        Observer.Expect('log_after_setvalue', 'OpenPage;AfterGetRecord(G9,1);AfterGetRecord(G9,1);AfterGetCurrRecord(G9,1);NewRecord();AfterGetCurrRecord(,0);NewRecord();AfterGetCurrRecord(,0);');
        Observer.Expect('s_count', '2');
        Observer.Expect('s_count_not_g9', '1');
        Observer.Expect('s_grp', '');
        Observer.Expect('s_lineno', '0');
        Observer.Expect('s_descr', 'typed');
        Observer.Expect('s_qty', '0');
        Observer.Verify();
    end;
}
