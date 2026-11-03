// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setview-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.SetView / RecordRef.SetView with a WHERE on a field whose Caption differs from its Name (own table LT SetView Caption: Name Report_ID / Caption 'Report ID',
// Line_No / 'Line No.', Doc_Code / 'Doc Code'), the way GetView writes it: does SetView accept the caption form, the name form, a mix; the GetView text afterwards, the Count of matching rows,
// the error text start and code (SetView and Count in TryFunctions, no writes inside them). Other SetView tests: record/lt-setview-sorting-nonkey (SORTING on a non-key field).
// BC versions: 29 (27 and 28 by CI)

table 71710 "LT SetView Caption"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Report_ID; Integer)
        {
            Caption = 'Report ID';
        }
        field(2; Line_No; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Doc_Code; Code[10])
        {
            Caption = 'Doc Code';
        }
    }

    keys
    {
        key(PK; Report_ID, Line_No) { Clustered = true; }
    }
}

codeunit 71704 "LT SetView Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetView(var Rec: Record "LT SetView Caption"; View: Text)
    begin
        Rec.SetView(View);
    end;

    [TryFunction]
    local procedure TryCount(var Rec: Record "LT SetView Caption"; var Cnt: Integer)
    begin
        Cnt := Rec.Count();
    end;

    [TryFunction]
    local procedure TryRefSetView(var RR: RecordRef; View: Text)
    begin
        RR.SetView(View);
    end;

    local procedure Seed()
    var
        Rec: Record "LT SetView Caption";
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Report_ID := 5;
        Rec.Line_No := 1;
        Rec.Doc_Code := 'A';
        Rec.Insert();
        Rec.Line_No := 2;
        Rec.Doc_Code := 'B';
        Rec.Insert();
        Rec.Line_No := 3;
        Rec.Doc_Code := 'A';
        Rec.Insert();
        Rec.Report_ID := 6;
        Rec.Line_No := 1;
        Rec.Insert();
        Rec.Report_ID := 7;
        Rec.Line_No := 1;
        Rec.Insert();
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; View: Text)
    var
        Rec: Record "LT SetView Caption";
        Cnt: Integer;
    begin
        Cnt := -1;
        if not TrySetView(Rec, View) then begin
            Observer.Observe('SetView', 'err|' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode());
            exit;
        end;
        Observer.Observe('SetView', 'ok');
        Observer.Observe('GetView(true)', Rec.GetView(true));
        Observer.Observe('GetView(false)', Rec.GetView(false));
        Observer.Observe('HasFilter', Format(Rec.HasFilter()));
        if TryCount(Rec, Cnt) then
            Observer.Observe('Count', Format(Cnt))
        else
            Observer.Observe('Count', 'err|' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure SetView_CaptionForm_ReportId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'WHERE(Report ID=CONST(5))');
        Observer.Expect('SetView', 'ok');
        Observer.Expect('GetView(true)', 'VERSION(1) SORTING(Report ID,Line No.) WHERE(Report ID=FILTER(5))');
        Observer.Expect('GetView(false)', 'VERSION(1) SORTING(Field1,Field2) WHERE(Field1=1(5))');
        Observer.Expect('HasFilter', 'Yes');
        Observer.Expect('Count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_NameForm_ReportId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'WHERE(Report_ID=CONST(5))');
        Observer.Expect('SetView', 'ok');
        Observer.Expect('GetView(true)', 'VERSION(1) SORTING(Report ID,Line No.) WHERE(Report ID=FILTER(5))');
        Observer.Expect('GetView(false)', 'VERSION(1) SORTING(Field1,Field2) WHERE(Field1=1(5))');
        Observer.Expect('HasFilter', 'Yes');
        Observer.Expect('Count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_CaptionForm_WithDotInCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'WHERE(Line No.=CONST(2))');
        Observer.Expect('SetView', 'ok');
        Observer.Expect('GetView(true)', 'VERSION(1) SORTING(Report ID,Line No.) WHERE(Line No.=FILTER(2))');
        Observer.Expect('GetView(false)', 'VERSION(1) SORTING(Field1,Field2) WHERE(Field2=1(2))');
        Observer.Expect('HasFilter', 'Yes');
        Observer.Expect('Count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_CaptionForm_SortingAndTwoConditions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'SORTING(Report ID,Line No.) ORDER(Descending) WHERE(Report ID=CONST(5),Doc Code=CONST(A))');
        Observer.Expect('SetView', 'ok');
        Observer.Expect('GetView(true)', 'VERSION(1) SORTING(Report ID,Line No.) ORDER(Descending) WHERE(Report ID=FILTER(5),Doc Code=FILTER(A))');
        Observer.Expect('GetView(false)', 'VERSION(1) SORTING(Field1,Field2) ORDER(1) WHERE(Field1=1(5),Field3=1(A))');
        Observer.Expect('HasFilter', 'Yes');
        Observer.Expect('Count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_MixedNameAndCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'WHERE(Report_ID=CONST(5),Doc Code=CONST(A))');
        Observer.Expect('SetView', 'ok');
        Observer.Expect('GetView(true)', 'VERSION(1) SORTING(Report ID,Line No.) WHERE(Report ID=FILTER(5),Doc Code=FILTER(A))');
        Observer.Expect('GetView(false)', 'VERSION(1) SORTING(Field1,Field2) WHERE(Field1=1(5),Field3=1(A))');
        Observer.Expect('HasFilter', 'Yes');
        Observer.Expect('Count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_UnknownField_ErrorText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Probe(Observer, 'WHERE(Nothing Here=CONST(5))');
        Observer.Expect('SetView', 'ok');
        Observer.Expect('GetView(true)', 'VERSION(1) SORTING(Report ID,Line No.)');
        Observer.Expect('GetView(false)', 'VERSION(1) SORTING(Field1,Field2)');
        Observer.Expect('HasFilter', 'No');
        Observer.Expect('Count', '5');
        Observer.Verify();
    end;

    [Test]
    procedure SetView_GetViewRoundTrip_NameFormSetFilter()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT SetView Caption";
        Other: Record "LT SetView Caption";
        Cnt: Integer;
    begin
        Seed();
        Rec.SetRange(Report_ID, 5);
        Rec.SetFilter(Line_No, '>=2');
        Observer.Observe('GetView', Rec.GetView());
        Other.SetView(Rec.GetView());
        Observer.Observe('roundTrip GetView', Other.GetView());
        Observer.Observe('roundTrip Count', Format(Other.Count()));
        Observer.Observe('filter on Report_ID', Other.GetFilter(Report_ID));
        Observer.Observe('filter on Line_No', Other.GetFilter(Line_No));
        Cnt := Rec.Count();
        Observer.Observe('same count', Format(Cnt = Other.Count()));
        Observer.Expect('GetView', 'VERSION(1) SORTING(Report ID,Line No.) WHERE(Report ID=FILTER(5),Line No.=FILTER(>=2))');
        Observer.Expect('roundTrip GetView', 'VERSION(1) SORTING(Report ID,Line No.) WHERE(Report ID=FILTER(5),Line No.=FILTER(>=2))');
        Observer.Expect('roundTrip Count', '2');
        Observer.Expect('filter on Report_ID', '5');
        Observer.Expect('filter on Line_No', '>=2');
        Observer.Expect('same count', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRefSetView_CaptionAndNameForm()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        RR.Open(Database::"LT SetView Caption");
        if TryRefSetView(RR, 'WHERE(Report ID=CONST(5))') then
            Observer.Observe('caption SetView', 'ok;count=' + Format(RR.Count()) + ';view=' + RR.GetView())
        else
            Observer.Observe('caption SetView', 'err|' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode());
        RR.Close();
        RR.Open(Database::"LT SetView Caption");
        if TryRefSetView(RR, 'WHERE(Report_ID=CONST(5))') then
            Observer.Observe('name SetView', 'ok;count=' + Format(RR.Count()) + ';view=' + RR.GetView())
        else
            Observer.Observe('name SetView', 'err|' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode());
        RR.Close();
        Observer.Expect('caption SetView', 'ok;count=3;view=VERSION(1) SORTING(Report ID,Line No.) WHERE(Report ID=FILTER(5))');
        Observer.Expect('name SetView', 'ok;count=3;view=VERSION(1) SORTING(Report ID,Line No.) WHERE(Report ID=FILTER(5))');
        Observer.Verify();
    end;
}
