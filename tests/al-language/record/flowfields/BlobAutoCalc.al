// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setautocalcfields-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 67501, codeunit 67502
// Probe: SetAutoCalcFields on a Blob field of a temporary record and of a persistent record: after Get, Find, FindFirst, FindLast, FindSet and Next the Blob's HasValue, Length and content, with and without SetAutoCalcFields (issue 580 item 1).
// BC versions: 27+

table 67501 "LT BAC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
        field(3; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67502 "LT BAC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(var Row: Record "LT BAC Row")
    begin
        Row.DeleteAll();
        Put(Row, 1, 'alpha');
        Put(Row, 2, 'bravo-longer');
        Put(Row, 3, '');
    end;

    local procedure Put(var Row: Record "LT BAC Row"; Id: Integer; Content: Text)
    var
        OutS: OutStream;
    begin
        Row.Init();
        Row.Id := Id;
        Row.Name := 'n' + Format(Id);
        if Content <> '' then begin
            Row.Data.CreateOutStream(OutS);
            OutS.WriteText(Content);
        end;
        Row.Insert();
    end;

    local procedure Show(var Row: Record "LT BAC Row"): Text
    var
        InS: InStream;
        Content: Text;
    begin
        Row.Data.CreateInStream(InS);
        if InS.EOS() then
            Content := '<eos>'
        else
            InS.ReadText(Content);
        exit(Format(Row.Id) + ':' + Format(Row.Data.HasValue) + ':' + Format(Row.Data.Length) + ':' + Content);
    end;

    local procedure Walk(var Row: Record "LT BAC Row"; var Observer: Codeunit "Probe Observer")
    begin
        Row.Init();
        Observer.Observe('after_init', Show(Row));
        Row.Get(1);
        Observer.Observe('get_1', Show(Row));
        Row.Get(2);
        Observer.Observe('get_2', Show(Row));
        Row.Get(3);
        Observer.Observe('get_3_no_content', Show(Row));
        Row.Init();
        Row.Id := 1;
        Row.Find('=');
        Observer.Observe('find_equal', Show(Row));
        Row.Reset();
        Row.FindFirst();
        Observer.Observe('find_first', Show(Row));
        Row.FindLast();
        Observer.Observe('find_last', Show(Row));
        Row.Find('-');
        Observer.Observe('find_minus', Show(Row));
        Row.Find('+');
        Observer.Observe('find_plus', Show(Row));
        Row.FindSet();
        Observer.Observe('find_set_1', Show(Row));
        Row.Next();
        Observer.Observe('next_2', Show(Row));
        Row.Next();
        Observer.Observe('next_3', Show(Row));
        Observer.Observe('next_end', Format(Row.Next()));
        Row.FindLast();
        Row.Next(-1);
        Observer.Observe('next_back', Show(Row));
        Row.Init();
        Row.Id := 2;
        Row.Find();
        Observer.Observe('find_default', Show(Row));
    end;

    local procedure InsertOne(var Row: Record "LT BAC Row"; var Observer: Codeunit "Probe Observer")
    var
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 7;
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('inserted');
        Observer.Observe('before_insert', Show(Row));
        Row.Insert();
        Observer.Observe('after_insert', Show(Row));
        Row.Find();
        Observer.Observe('after_find', Show(Row));
        Row.CalcFields(Data);
        Observer.Observe('after_calcfields', Show(Row));
    end;

    [Test]
    procedure Temporary_InsertedRecord_Blob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BAC Row" temporary;
    begin
        InsertOne(Row, Observer);
        Observer.Expect('before_insert', '7:Yes:8:inserted');
        Observer.Expect('after_insert', '7:Yes:8:inserted');
        Observer.Expect('after_find', '7:Yes:8:<eos>');
        Observer.Expect('after_calcfields', '7:Yes:8:inserted');
        Observer.Verify();
    end;

    [Test]
    procedure Persistent_InsertedRecord_Blob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BAC Row";
    begin
        InsertOne(Row, Observer);
        Observer.Expect('before_insert', '7:Yes:8:inserted');
        Observer.Expect('after_insert', '7:Yes:8:inserted');
        Observer.Expect('after_find', '7:Yes:14:<eos>');
        Observer.Expect('after_calcfields', '7:Yes:8:inserted');
        Observer.Verify();
    end;

    [Test]
    procedure Temporary_InsertedRecord_WithSetAutoCalcFields_Blob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BAC Row" temporary;
    begin
        Row.SetAutoCalcFields(Data);
        InsertOne(Row, Observer);
        Observer.Expect('before_insert', '7:Yes:8:inserted');
        Observer.Expect('after_insert', '7:Yes:8:inserted');
        Observer.Expect('after_find', '7:Yes:8:inserted');
        Observer.Expect('after_calcfields', '7:Yes:8:inserted');
        Observer.Verify();
    end;

    [Test]
    procedure Persistent_InsertedRecord_WithSetAutoCalcFields_Blob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BAC Row";
    begin
        Row.SetAutoCalcFields(Data);
        InsertOne(Row, Observer);
        Observer.Expect('before_insert', '7:Yes:8:inserted');
        Observer.Expect('after_insert', '7:Yes:8:inserted');
        Observer.Expect('after_find', '7:Yes:8:inserted');
        Observer.Expect('after_calcfields', '7:Yes:8:inserted');
        Observer.Verify();
    end;

    [Test]
    procedure Temporary_SetAutoCalcFields_Blob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BAC Row" temporary;
    begin
        Seed(Row);
        Observer.Observe('after_insert_last_row', Show(Row));
        Row.SetAutoCalcFields(Data);
        Walk(Row, Observer);
        Observer.Expect('after_insert_last_row', '3:No:0:<eos>');
        Observer.Expect('after_init', '3:No:0:<eos>');
        Observer.Expect('get_1', '1:Yes:5:alpha');
        Observer.Expect('get_2', '2:Yes:12:bravo-longer');
        Observer.Expect('get_3_no_content', '3:No:0:<eos>');
        Observer.Expect('find_equal', '1:Yes:5:alpha');
        Observer.Expect('find_first', '1:Yes:5:alpha');
        Observer.Expect('find_last', '3:No:0:<eos>');
        Observer.Expect('find_minus', '1:Yes:5:alpha');
        Observer.Expect('find_plus', '3:No:0:<eos>');
        Observer.Expect('find_set_1', '1:Yes:5:alpha');
        Observer.Expect('next_2', '2:Yes:12:bravo-longer');
        Observer.Expect('next_3', '3:No:0:<eos>');
        Observer.Expect('next_end', '0');
        Observer.Expect('next_back', '2:Yes:12:bravo-longer');
        Observer.Expect('find_default', '2:Yes:12:bravo-longer');
        Observer.Verify();
    end;


    [Test]
    procedure Persistent_SetAutoCalcFields_Blob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BAC Row";
    begin
        Seed(Row);
        Observer.Observe('after_insert_last_row', Show(Row));
        Row.SetAutoCalcFields(Data);
        Walk(Row, Observer);
        Observer.Expect('after_insert_last_row', '3:No:0:<eos>');
        Observer.Expect('after_init', '3:No:0:<eos>');
        Observer.Expect('get_1', '1:Yes:5:alpha');
        Observer.Expect('get_2', '2:Yes:12:bravo-longer');
        Observer.Expect('get_3_no_content', '3:No:0:<eos>');
        Observer.Expect('find_equal', '1:Yes:5:alpha');
        Observer.Expect('find_first', '1:Yes:5:alpha');
        Observer.Expect('find_last', '3:No:0:<eos>');
        Observer.Expect('find_minus', '1:Yes:5:alpha');
        Observer.Expect('find_plus', '3:No:0:<eos>');
        Observer.Expect('find_set_1', '1:Yes:5:alpha');
        Observer.Expect('next_2', '2:Yes:12:bravo-longer');
        Observer.Expect('next_3', '3:No:0:<eos>');
        Observer.Expect('next_end', '0');
        Observer.Expect('next_back', '2:Yes:12:bravo-longer');
        Observer.Expect('find_default', '2:Yes:12:bravo-longer');
        Observer.Verify();
    end;


    [Test]
    procedure Temporary_WithoutSetAutoCalcFields_Blob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BAC Row" temporary;
    begin
        Seed(Row);
        Walk(Row, Observer);
        Observer.Expect('after_init', '3:No:0:<eos>');
        Observer.Expect('get_1', '1:Yes:5:<eos>');
        Observer.Expect('get_2', '2:Yes:12:<eos>');
        Observer.Expect('get_3_no_content', '3:No:0:<eos>');
        Observer.Expect('find_equal', '1:Yes:5:<eos>');
        Observer.Expect('find_first', '1:Yes:5:<eos>');
        Observer.Expect('find_last', '3:No:0:<eos>');
        Observer.Expect('find_minus', '1:Yes:5:<eos>');
        Observer.Expect('find_plus', '3:No:0:<eos>');
        Observer.Expect('find_set_1', '1:Yes:5:<eos>');
        Observer.Expect('next_2', '2:Yes:12:<eos>');
        Observer.Expect('next_3', '3:No:0:<eos>');
        Observer.Expect('next_end', '0');
        Observer.Expect('next_back', '2:Yes:12:<eos>');
        Observer.Expect('find_default', '2:Yes:12:<eos>');
        Observer.Verify();
    end;


    [Test]
    procedure Persistent_WithoutSetAutoCalcFields_Blob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BAC Row";
    begin
        Seed(Row);
        Walk(Row, Observer);
        Observer.Expect('after_init', '3:No:0:<eos>');
        Observer.Expect('get_1', '1:Yes:11:<eos>');
        Observer.Expect('get_2', '2:Yes:18:<eos>');
        Observer.Expect('get_3_no_content', '3:No:0:<eos>');
        Observer.Expect('find_equal', '1:Yes:11:<eos>');
        Observer.Expect('find_first', '1:Yes:11:<eos>');
        Observer.Expect('find_last', '3:No:0:<eos>');
        Observer.Expect('find_minus', '1:Yes:11:<eos>');
        Observer.Expect('find_plus', '3:No:0:<eos>');
        Observer.Expect('find_set_1', '1:Yes:11:<eos>');
        Observer.Expect('next_2', '2:Yes:18:<eos>');
        Observer.Expect('next_3', '3:No:0:<eos>');
        Observer.Expect('next_end', '0');
        Observer.Expect('next_back', '2:Yes:18:<eos>');
        Observer.Expect('find_default', '2:Yes:18:<eos>');
        Observer.Verify();
    end;


    [Test]
    procedure Temporary_CalcFields_Blob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BAC Row" temporary;
    begin
        Seed(Row);
        Row.Get(2);
        Observer.Observe('get', Show(Row));
        Row.CalcFields(Data);
        Observer.Observe('after_calcfields', Show(Row));
        Observer.Expect('get', '2:Yes:12:<eos>');
        Observer.Expect('after_calcfields', '2:Yes:12:bravo-longer');
        Observer.Verify();
    end;

    [Test]
    procedure Persistent_CalcFields_Blob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BAC Row";
    begin
        Seed(Row);
        Row.Get(2);
        Observer.Observe('get', Show(Row));
        Row.CalcFields(Data);
        Observer.Observe('after_calcfields', Show(Row));
        Observer.Expect('get', '2:Yes:18:<eos>');
        Observer.Expect('after_calcfields', '2:Yes:12:bravo-longer');
        Observer.Verify();
    end;

    [Test]
    procedure Temporary_SetAutoCalcFields_ThenModifyAndGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BAC Row" temporary;
        OutS: OutStream;
    begin
        Seed(Row);
        Row.SetAutoCalcFields(Data);
        Row.Get(1);
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('changed');
        Row.Modify();
        Row.Init();
        Row.Get(1);
        Observer.Observe('after_modify_get', Show(Row));
        Row.Delete();
        Observer.Observe('get_deleted', Format(Row.Get(1)));
        Observer.Expect('after_modify_get', '1:Yes:7:changed');
        Observer.Expect('get_deleted', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Persistent_SetAutoCalcFields_ThenModifyAndGet()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BAC Row";
        OutS: OutStream;
    begin
        Seed(Row);
        Row.SetAutoCalcFields(Data);
        Row.Get(1);
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('changed');
        Row.Modify();
        Row.Init();
        Row.Get(1);
        Observer.Observe('after_modify_get', Show(Row));
        Row.Delete();
        Observer.Observe('get_deleted', Format(Row.Get(1)));
        Observer.Expect('after_modify_get', '1:Yes:7:changed');
        Observer.Expect('get_deleted', 'No');
        Observer.Verify();
    end;
}
