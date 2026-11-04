// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-length-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); tables 78101 - 78103
// Probe: (1) FieldRef.Length of a Media field and of a MediaSet field (and of a Blob and a Guid field for comparison); (2) Record.Find (default, '=', '-', '+')
// on an empty table when the record's primary key holds a value other than the default, for a Code key and an Integer key: the result or the error
// text and code. Object ids 78101 - 78104.

table 78101 "LT AD Media Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Pic; Media) { }
        field(3; Pics; MediaSet) { }
        field(4; Data; Blob) { }
        field(5; G; Guid) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 78102 "LT AD Code Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Note; Text[20]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 78103 "LT AD Int Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 78104 "LT AD Media Find Empty"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FieldRef_Length_Media()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        FR: FieldRef;
    begin
        RR.Open(Database::"LT AD Media Row");
        FR := RR.Field(2);
        Observer.Observe('media_length', Format(FR.Length()));
        FR := RR.Field(3);
        Observer.Observe('mediaset_length', Format(FR.Length()));
        FR := RR.Field(4);
        Observer.Observe('blob_length', Format(FR.Length()));
        FR := RR.Field(5);
        Observer.Observe('guid_length', Format(FR.Length()));
        Observer.Expect('media_length', '16');
        Observer.Expect('mediaset_length', '16');
        Observer.Expect('blob_length', '8');
        Observer.Expect('guid_length', '16');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryFindCode(var Rec: Record "LT AD Code Key"; Mode: Text; var Found: Boolean)
    begin
        if Mode = '' then Found := Rec.Find() else Found := Rec.Find(Mode);
    end;

    [TryFunction]
    local procedure TryFindInt(var Rec: Record "LT AD Int Key"; Mode: Text; var Found: Boolean)
    begin
        if Mode = '' then Found := Rec.Find() else Found := Rec.Find(Mode);
    end;

    local procedure CodeCase(var Observer: Codeunit "Probe Observer"; Mode: Text; KeyValue: Code[10])
    var
        Rec: Record "LT AD Code Key";
        Found: Boolean;
    begin
        Rec.DeleteAll();
        Rec.Code := KeyValue;
        ClearLastError();
        if TryFindCode(Rec, Mode, Found) then
            Observer.Observe('code ' + KeyValue + ' find(' + Mode + ')', 'ok:' + Format(Found) + '|key=' + Rec.Code)
        else
            Observer.Observe('code ' + KeyValue + ' find(' + Mode + ')', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure IntCase(var Observer: Codeunit "Probe Observer"; Mode: Text; KeyValue: Integer)
    var
        Rec: Record "LT AD Int Key";
        Found: Boolean;
    begin
        Rec.DeleteAll();
        Rec.Id := KeyValue;
        ClearLastError();
        if TryFindInt(Rec, Mode, Found) then
            Observer.Observe('int ' + Format(KeyValue) + ' find(' + Mode + ')', 'ok:' + Format(Found) + '|key=' + Format(Rec.Id))
        else
            Observer.Observe('int ' + Format(KeyValue) + ' find(' + Mode + ')', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Find_EmptyTable_CodeKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CodeCase(Observer, '', 'ABC');
        CodeCase(Observer, '=', 'ABC');
        CodeCase(Observer, '-', 'ABC');
        CodeCase(Observer, '+', 'ABC');
        CodeCase(Observer, '', '');
        Observer.Expect('code ABC find()', 'ok:No|key=ABC');
        Observer.Expect('code ABC find(=)', 'ok:No|key=ABC');
        Observer.Expect('code ABC find(-)', 'ok:No|key=ABC');
        Observer.Expect('code ABC find(+)', 'ok:No|key=ABC');
        Observer.Expect('code  find()', 'ok:No|key=');
        Observer.Verify();
    end;

    [Test]
    procedure Find_EmptyTable_IntegerKey()
    var
        Observer: Codeunit "Probe Observer";
    begin
        IntCase(Observer, '', 5);
        IntCase(Observer, '=', 5);
        IntCase(Observer, '-', 5);
        IntCase(Observer, '+', 5);
        IntCase(Observer, '', 0);
        Observer.Expect('int 5 find()', 'ok:No|key=5');
        Observer.Expect('int 5 find(=)', 'ok:No|key=5');
        Observer.Expect('int 5 find(-)', 'ok:No|key=5');
        Observer.Expect('int 5 find(+)', 'ok:No|key=5');
        Observer.Expect('int 0 find()', 'ok:No|key=0');
        Observer.Verify();
    end;
}
