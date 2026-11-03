// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 91690-91691 and 91695, page 91696, xmlports 91693-91694, codeunits 91692 and 91697
// Probe: observe probe (writer Y14, 2026-10-31, runtime asks from partner-app triage); every literal asserted below is what the BC service tier produced.
// Facts: (1) Evaluate(RecordId, 'Table: key') with a Text[50] primary key holding blanks, commas, quotes and the empty string; Format(RecordId) of the same keys.
//   (2) TestPage SetValue with a Decimal (1.11) on a Text control. (3) SetFilter with a '%1' text that contains '>' and '@', with and without a leading '@':
//   GetFilters and the rows that match. (4) JsonObject.Get with a missing name whose result is not used. (5) XmlPort import into a temporary table element
//   whose table has OnInsert and OnModify triggers, against the same port on the real table.
// BC versions: 27, 28, 29

table 91690 "LT Y14 SM Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Key50; Text[50]) { }
        field(2; Data; Text[30]) { }
    }
    keys { key(PK; Key50) { Clustered = true; } }
}

table 91691 "LT Y14 SM Mail"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Email; Text[50]) { }
        field(3; Label; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 91696 "LT Y14 SM Card"
{
    PageType = Card;
    SourceTable = "LT Y14 SM Mail";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Label; Rec.Label) { ApplicationArea = All; }
        }
    }
}

table 91695 "LT Y14 SM Trig"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    var
        Log: Codeunit "LT Y14 SM Log";
    begin
        Log.Add('insert(' + Format(Id) + ')');
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT Y14 SM Log";
    begin
        Log.Add('modify(' + Format(Id) + ')');
    end;
}

codeunit 91692 "LT Y14 SM Log"
{
    SingleInstance = true;

    var
        Text: Text;

    procedure Add(Entry: Text)
    begin
        Text += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Text;
        Text := '';
        exit(Result);
    end;
}

xmlport 91693 "LT Y14 SM Import Temp"
{
    Direction = Import;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y14 SM Trig")
            {
                UseTemporary = true;
                XmlName = 'Row';
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }

                trigger OnAfterInsertRecord()
                begin
                    Rows.Copy(Row);
                    Rows.Insert();
                end;
            }
        }
    }

    var
        Rows: Record "LT Y14 SM Trig" temporary;

    procedure Seen(): Integer
    begin
        exit(Rows.Count());
    end;
}

xmlport 91694 "LT Y14 SM Import Real"
{
    Direction = Import;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y14 SM Trig")
            {
                XmlName = 'Row';
                fieldelement(Id; Row.Id) { }
                fieldelement(Name; Row.Name) { }
            }
        }
    }
}

codeunit 91697 "LT Y14 SM Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure KeyText(Value: Text): Text
    var
        Rid: RecordId;
        Ok: Boolean;
        Back: Text;
    begin
        Ok := Evaluate(Rid, Value);
        Back := '';
        if Ok then
            Back := Format(Rid);
        exit('eval=' + Format(Ok) + '|back=' + Back);
    end;

    [Test]
    procedure Evaluate_RecordId_TextKey()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT Y14 SM Key";
    begin
        K.DeleteAll();
        K.Key50 := 'a b';
        K.Insert();
        K.Key50 := 'a,b';
        K.Insert();
        K.Key50 := 'a"b';
        K.Insert();
        K.Key50 := 'it''s';
        K.Insert();
        K.Key50 := '';
        K.Insert();
        K.Key50 := ' lead';
        K.Insert();
        K.FindSet();
        repeat
            Observer.Observe('format [' + K.Key50 + ']', Format(K.RecordId));
        until K.Next() = 0;
        Observer.Expect('format []', 'LT Y14 SM Key: ""');
        Observer.Expect('format [ lead]', 'LT Y14 SM Key: " lead"');
        Observer.Expect('format [a b]', 'LT Y14 SM Key: a b');
        Observer.Expect('format [a"b]', 'LT Y14 SM Key: a"b');
        Observer.Expect('format [a,b]', 'LT Y14 SM Key: "a,b"');
        Observer.Expect('format [it''s]', 'LT Y14 SM Key: it''s');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_RecordId_TextKey_Forms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('eval blank', KeyText('LT Y14 SM Key: a b'));
        Observer.Observe('eval comma quoted', KeyText('LT Y14 SM Key: "a,b"'));
        Observer.Observe('eval comma bare', KeyText('LT Y14 SM Key: a,b'));
        Observer.Observe('eval quote inside', KeyText('LT Y14 SM Key: a"b'));
        Observer.Observe('eval quoted quote', KeyText('LT Y14 SM Key: "a""b"'));
        Observer.Observe('eval apostrophe', KeyText('LT Y14 SM Key: it''s'));
        Observer.Observe('eval empty key', KeyText('LT Y14 SM Key: '));
        Observer.Observe('eval empty quoted', KeyText('LT Y14 SM Key: ""'));
        Observer.Observe('eval no colon', KeyText('LT Y14 SM Key'));
        Observer.Observe('eval table id', KeyText('Table 91690: a b'));
        Observer.Observe('eval leading blank', KeyText('LT Y14 SM Key:  lead'));
        Observer.Observe('eval trailing blank', KeyText('LT Y14 SM Key: a b '));
        Observer.Expect('eval blank', 'eval=Yes|back=LT Y14 SM Key: a b');
        Observer.Expect('eval comma quoted', 'eval=Yes|back=LT Y14 SM Key: "a,b"');
        Observer.Expect('eval comma bare', 'eval=No|back=');
        Observer.Expect('eval quote inside', 'eval=Yes|back=LT Y14 SM Key: a"b');
        Observer.Expect('eval quoted quote', 'eval=Yes|back=LT Y14 SM Key: a"b');
        Observer.Expect('eval apostrophe', 'eval=Yes|back=LT Y14 SM Key: it''s');
        Observer.Expect('eval empty key', 'eval=Yes|back=LT Y14 SM Key');
        Observer.Expect('eval empty quoted', 'eval=Yes|back=LT Y14 SM Key: ""');
        Observer.Expect('eval no colon', 'eval=Yes|back=LT Y14 SM Key');
        Observer.Expect('eval table id', 'eval=Yes|back=LT Y14 SM Key: a b');
        Observer.Expect('eval leading blank', 'eval=Yes|back=LT Y14 SM Key: lead');
        Observer.Expect('eval trailing blank', 'eval=Yes|back=LT Y14 SM Key: a b');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_SetValue_DecimalOnTextControl()
    var
        Observer: Codeunit "Probe Observer";
        M: Record "LT Y14 SM Mail";
        P: TestPage "LT Y14 SM Card";
    begin
        M.DeleteAll();
        M.Id := 1;
        M.Insert();
        Commit();
        P.OpenEdit();
        P.Label.SetValue(1.11);
        Observer.Observe('control', P.Label.Value());
        P.Close();
        M.Get(1);
        Observer.Observe('stored', M.Label);
        P.OpenEdit();
        P.Label.SetValue(1234567.5);
        Observer.Observe('control big', P.Label.Value());
        P.Label.SetValue(0.0);
        Observer.Observe('control zero', P.Label.Value());
        P.Label.SetValue(-3.50);
        Observer.Observe('control negative', P.Label.Value());
        P.Close();
        Observer.Expect('control', '1.11');
        Observer.Expect('stored', '1.11');
        Observer.Expect('control big', '1,234,567.5');
        Observer.Expect('control zero', '0');
        Observer.Expect('control negative', '-3.5');
        Observer.Verify();
    end;

    local procedure MailRows()
    var
        M: Record "LT Y14 SM Mail";
    begin
        M.DeleteAll();
        M.Id := 1;
        M.Email := 'a>b@x.com';
        M.Insert();
        M.Id := 2;
        M.Email := 'A>B@X.COM';
        M.Insert();
        M.Id := 3;
        M.Email := 'a>b@x.comm';
        M.Insert();
        M.Id := 4;
        M.Email := 'b';
        M.Insert();
        M.Id := 5;
        M.Email := 'a';
        M.Insert();
    end;

    local procedure Matches(var M: Record "LT Y14 SM Mail"): Text
    var
        Result: Text;
    begin
        if M.FindSet() then
            repeat
                Result += Format(M.Id) + ',';
            until M.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySetFilter(var M: Record "LT Y14 SM Mail"; Value: Text)
    begin
        M.SetFilter(Email, '%1', Value);
    end;

    [Test]
    procedure SetFilter_Percent_GreaterAndAt()
    var
        Observer: Codeunit "Probe Observer";
        M: Record "LT Y14 SM Mail";
        Values: List of [Text];
        Value: Text;
        Name: Text;
    begin
        MailRows();
        ClearLastError();
        Values := 'a>b@x.com|@a>b@x.com|@A>B@X.COM|a>b|>b|@x.com|a@|@'.Split('|');
        foreach Value in Values do begin
            M.Reset();
            Name := Value;
            Observer.Observe('set [' + Name + ']', Format(TrySetFilter(M, Value)));
            Observer.ObserveError('err [' + Name + ']');
            Observer.Observe('filters [' + Name + ']', M.GetFilters());
            Observer.Observe('view [' + Name + ']', M.GetView());
            Observer.Observe('rows [' + Name + ']', Matches(M));
        end;
        Observer.Expect('set [a>b@x.com]', 'Yes');
        Observer.Expect('err [a>b@x.com]|text', '');
        Observer.Expect('err [a>b@x.com]|code', '');
        Observer.Expect('filters [a>b@x.com]', 'Email: ''a>b@x.com''');
        Observer.Expect('view [a>b@x.com]', 'VERSION(1) SORTING(Id) WHERE(Email=FILTER(''a>b@x.com''))');
        Observer.Expect('rows [a>b@x.com]', '1,');
        Observer.Expect('set [@a>b@x.com]', 'Yes');
        Observer.Expect('err [@a>b@x.com]|text', '');
        Observer.Expect('err [@a>b@x.com]|code', '');
        Observer.Expect('filters [@a>b@x.com]', 'Email: ''@a>b@x.com''');
        Observer.Expect('view [@a>b@x.com]', 'VERSION(1) SORTING(Id) WHERE(Email=FILTER(''@a>b@x.com''))');
        Observer.Expect('rows [@a>b@x.com]', '1,2,');
        Observer.Expect('set [@A>B@X.COM]', 'Yes');
        Observer.Expect('err [@A>B@X.COM]|text', '');
        Observer.Expect('err [@A>B@X.COM]|code', '');
        Observer.Expect('filters [@A>B@X.COM]', 'Email: ''@A>B@X.COM''');
        Observer.Expect('view [@A>B@X.COM]', 'VERSION(1) SORTING(Id) WHERE(Email=FILTER(''@A>B@X.COM''))');
        Observer.Expect('rows [@A>B@X.COM]', '1,2,');
        Observer.Expect('set [a>b]', 'Yes');
        Observer.Expect('err [a>b]|text', '');
        Observer.Expect('err [a>b]|code', '');
        Observer.Expect('filters [a>b]', 'Email: ''a>b''');
        Observer.Expect('view [a>b]', 'VERSION(1) SORTING(Id) WHERE(Email=FILTER(''a>b''))');
        Observer.Expect('rows [a>b]', '');
        Observer.Expect('set [>b]', 'Yes');
        Observer.Expect('err [>b]|text', '');
        Observer.Expect('err [>b]|code', '');
        Observer.Expect('filters [>b]', 'Email: ''>b''');
        Observer.Expect('view [>b]', 'VERSION(1) SORTING(Id) WHERE(Email=FILTER(''>b''))');
        Observer.Expect('rows [>b]', '');
        Observer.Expect('set [@x.com]', 'Yes');
        Observer.Expect('err [@x.com]|text', '');
        Observer.Expect('err [@x.com]|code', '');
        Observer.Expect('filters [@x.com]', 'Email: @x.com');
        Observer.Expect('view [@x.com]', 'VERSION(1) SORTING(Id) WHERE(Email=FILTER(@x.com))');
        Observer.Expect('rows [@x.com]', '');
        Observer.Expect('set [a@]', 'Yes');
        Observer.Expect('err [a@]|text', '');
        Observer.Expect('err [a@]|code', '');
        Observer.Expect('filters [a@]', 'Email: a@');
        Observer.Expect('view [a@]', 'VERSION(1) SORTING(Id) WHERE(Email=FILTER(a@))');
        Observer.Expect('rows [a@]', '');
        Observer.Expect('set [@]', 'Yes');
        Observer.Expect('err [@]|text', '');
        Observer.Expect('err [@]|code', '');
        Observer.Expect('filters [@]', 'Email: ''@''');
        Observer.Expect('view [@]', 'VERSION(1) SORTING(Id) WHERE(Email=FILTER(''@''))');
        Observer.Expect('rows [@]', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryGetMissing(J: JsonObject)
    var
        Token: JsonToken;
    begin
        J.Get('missing', Token);
    end;

    [Test]
    procedure JsonObject_Get_MissingNameResultNotUsed()
    var
        Observer: Codeunit "Probe Observer";
        J: JsonObject;
        Token: JsonToken;
        Found: Boolean;
    begin
        J.Add('present', 1);
        ClearLastError();
        Observer.Observe('try ok', Format(TryGetMissing(J)));
        Observer.ObserveError('try');
        Found := J.Get('missing', Token);
        Observer.Observe('assigned', Format(Found));
        Observer.Observe('token after', Format(Token.IsValue()) + '|' + Format(Token.IsObject()));
        Observer.Observe('contains', Format(J.Contains('missing')));
        Observer.Expect('try ok', 'No');
        Observer.Expect('try|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('try|code', 'JsonPropertyNotFound');
        Observer.Expect('assigned', 'No');
        Observer.Expect('token after', 'Yes|No');
        Observer.Expect('contains', 'No');
        Observer.Verify();
    end;

    local procedure ImportXml(): Text
    begin
        exit('<Root><Row><Id>1</Id><Name>one</Name></Row><Row><Id>2</Id><Name>two</Name></Row></Root>');
    end;

    [Test]
    procedure XmlPortImport_TemporaryTableElement_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y14 SM Log";
        T: Record "LT Y14 SM Trig";
        TempBlob: Codeunit "Temp Blob";
        PortTemp: XmlPort "LT Y14 SM Import Temp";
        PortReal: XmlPort "LT Y14 SM Import Real";
        OutS: OutStream;
        InS: InStream;
    begin
        T.DeleteAll();
        Commit();
        ClearLastError();
        Log.Take();
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(ImportXml());
        TempBlob.CreateInStream(InS);
        PortTemp.SetSource(InS);
        Observer.Observe('temp import', Format(PortTemp.Import()));
        Observer.Observe('temp log', Log.Take());
        Observer.Observe('temp table rows', Format(T.Count()));
        Observer.Observe('temp seen', Format(PortTemp.Seen()));
        TempBlob.CreateInStream(InS);
        PortReal.SetSource(InS);
        Observer.Observe('real import', Format(PortReal.Import()));
        Observer.Observe('real log', Log.Take());
        Observer.Observe('real table rows', Format(T.Count()));
        Observer.Expect('temp import', 'Yes');
        Observer.Expect('temp log', '');
        Observer.Expect('temp table rows', '0');
        Observer.Expect('temp seen', '2');
        Observer.Expect('real import', 'Yes');
        Observer.Expect('real log', 'insert(1);insert(2);');
        Observer.Expect('real table rows', '2');
        Observer.Verify();
    end;
}
