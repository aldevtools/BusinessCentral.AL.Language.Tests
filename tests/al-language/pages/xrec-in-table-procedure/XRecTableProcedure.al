// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xrec
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 72451, log 72452, page 72453, tests 72454
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a table procedure called on the page's Rec from OnNewRecord reads the page's xRec (the row the cursor left); the same procedure on a plain record variable.
// BC versions: 29 (27 and 28 by CI)

table 72451 "LT XRP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Integer) { }
        field(3; Note; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure InitKind()
    begin
        LTXRPLog.Add('proc xRec=' + Format(xRec.Id) + '/' + Format(xRec.Kind) + '/' + xRec.Note + ' Rec=' + Format(Rec.Id) + '/' + Format(Rec.Kind));
        Kind := xRec.Kind;
    end;

    var
        LTXRPLog: Codeunit "LT XRP Log";
}

codeunit 72452 "LT XRP Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Wipe()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure Get(Index: Integer): Text
    begin
        if (Index < 1) or (Index > Lines.Count()) then
            exit('<none>');
        exit(Lines.Get(Index));
    end;
}

page 72453 "LT XRP List"
{
    PageType = List;
    SourceTable = "LT XRP Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Note; Rec.Note) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        LTXRPLog.Add('OnNewRecord xRec=' + Format(xRec.Id) + '/' + Format(xRec.Kind) + '/' + xRec.Note);
        Rec.InitKind();
        LTXRPLog.Add('after Rec=' + Format(Rec.Id) + '/' + Format(Rec.Kind));
    end;

    var
        LTXRPLog: Codeunit "LT XRP Log";
}

codeunit 72454 "LT XRP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT XRP Row";
        Log: Codeunit "LT XRP Log";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.Kind := 11;
        R.Note := 'one';
        R.Insert();
        R.Init();
        R.Id := 2;
        R.Kind := 22;
        R.Note := 'two';
        R.Insert();
        Log.Wipe();
    end;

    local procedure DumpLog(var Observer: Codeunit "Probe Observer")
    var
        Log: Codeunit "LT XRP Log";
        i: Integer;
    begin
        Observer.Observe('log-count', Format(Log.Count()));
        for i := 1 to Log.Count() do
            Observer.Observe('log-' + Format(i), Log.Get(i));
    end;

    [Test]
    procedure Page_NewAfterFirstRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT XRP List";
    begin
        Seed();
        TP.OpenEdit();
        TP.First();
        TP.New();
        Observer.Observe('kind-on-new-line', TP.Kind.Value());
        Observer.Observe('id-on-new-line', TP.Id.Value());
        DumpLog(Observer);
        TP.Close();
        Observer.Expect('kind-on-new-line', '22');
        Observer.Expect('id-on-new-line', '0');
        Observer.Expect('log-count', '3');
        Observer.Expect('log-1', 'OnNewRecord xRec=2/22/two');
        Observer.Expect('log-2', 'proc xRec=2/22/two Rec=0/0');
        Observer.Expect('log-3', 'after Rec=0/22');
        Observer.Verify();
    end;

    [Test]
    procedure Page_NewAfterSecondRow()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT XRP List";
    begin
        Seed();
        TP.OpenEdit();
        TP.First();
        TP.Next();
        TP.New();
        Observer.Observe('kind-on-new-line', TP.Kind.Value());
        DumpLog(Observer);
        TP.Close();
        Observer.Expect('kind-on-new-line', '22');
        Observer.Expect('log-count', '3');
        Observer.Expect('log-1', 'OnNewRecord xRec=2/22/two');
        Observer.Expect('log-2', 'proc xRec=2/22/two Rec=0/0');
        Observer.Expect('log-3', 'after Rec=0/22');
        Observer.Verify();
    end;

    [Test]
    procedure Page_NewOnEmptyTable()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT XRP Row";
        Log: Codeunit "LT XRP Log";
        TP: TestPage "LT XRP List";
    begin
        R.DeleteAll();
        Log.Wipe();
        TP.OpenNew();
        Observer.Observe('kind-on-new-line', TP.Kind.Value());
        DumpLog(Observer);
        TP.Close();
        Observer.Expect('kind-on-new-line', '0');
        Observer.Expect('log-count', '3');
        Observer.Expect('log-1', 'OnNewRecord xRec=0/0/');
        Observer.Expect('log-2', 'proc xRec=0/0/ Rec=0/0');
        Observer.Expect('log-3', 'after Rec=0/0');
        Observer.Verify();
    end;

    [Test]
    procedure Record_Procedure_PlainVariable()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT XRP Row";
        Log: Codeunit "LT XRP Log";
    begin
        Seed();
        R.Get(2);
        R.InitKind();
        Observer.Observe('kind-after-get', Format(R.Kind));
        R.Init();
        R.InitKind();
        Observer.Observe('kind-after-init', Format(R.Kind));
        R.Get(1);
        R.Note := 'changed';
        R.Modify();
        R.Init();
        R.InitKind();
        Observer.Observe('kind-after-modify-init', Format(R.Kind));
        DumpLog(Observer);
        Observer.Expect('kind-after-get', '0');
        Observer.Expect('kind-after-init', '0');
        Observer.Expect('kind-after-modify-init', '0');
        Observer.Expect('log-count', '3');
        Observer.Expect('log-1', 'proc xRec=0/0/ Rec=2/22');
        Observer.Expect('log-2', 'proc xRec=0/0/ Rec=2/0');
        Observer.Expect('log-3', 'proc xRec=0/0/ Rec=1/0');
        Observer.Verify();
    end;
}
