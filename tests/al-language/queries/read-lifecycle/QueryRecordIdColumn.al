// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 74445 and query 74446 below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a query column bound to a RecordId field (issue #184 item 20): what Read gives, Format of the column (default, format 9), the type of the column value in a Variant, a blank RecordId, equality with the RecordId of the source row, Q.Read after the last row.
// BC versions: 29 (27 and 28 by CI)

table 74445 "LT QRid Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; RecordId) { }
        field(3; Tag; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 74446 "LT QRid Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Rows; "LT QRid Row")
        {
            column(RowId; Id) { }
            column(RefCol; Ref) { }
            column(TagCol; Tag) { }
        }
    }
}

codeunit 74447 "LT QRid Column"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT QRid Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Ref := Row.RecordId();
        Row.Tag := 'SELF';
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Tag := 'BLANK';
        Row.Insert();
    end;

    [Test]
    procedure QueryRecordId_ReadAndFormat_Result()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QRid Query";
        Row: Record "LT QRid Row";
        Rid: RecordId;
    begin
        Seed();
        Row.Get(1);
        Q.SetRange(RowId, 1);
        Q.Open();
        Observer.Observe('read_1', Format(Q.Read()));
        Rid := Q.RefCol;
        Observer.Observe('format_default', Format(Q.RefCol));
        Observer.Observe('format_9', Format(Q.RefCol, 0, 9));
        Observer.Observe('equals_row_recordid', Format(Rid = Row.RecordId()));
        Observer.Observe('tag', Q.TagCol);
        Observer.Observe('read_2', Format(Q.Read()));
        Q.Close();
        Observer.Expect('read_1', 'Yes');
        Observer.Expect('format_default', 'LT QRid Row: 1');
        Observer.Expect('format_9', 'LT QRid Row: 1');
        Observer.Expect('equals_row_recordid', 'Yes');
        Observer.Expect('tag', 'SELF');
        Observer.Expect('read_2', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QueryRecordId_BlankValue_Result()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QRid Query";
        Blank: RecordId;
        Rid: RecordId;
    begin
        Seed();
        Q.SetRange(RowId, 2);
        Q.Open();
        Observer.Observe('read_1', Format(Q.Read()));
        Rid := Q.RefCol;
        Observer.Observe('format_default', '[' + Format(Q.RefCol) + ']');
        Observer.Observe('equals_blank', Format(Rid = Blank));
        Observer.Observe('tag', Q.TagCol);
        Q.Close();
        Observer.Expect('read_1', 'Yes');
        Observer.Expect('format_default', '[]');
        Observer.Expect('equals_blank', 'Yes');
        Observer.Expect('tag', 'BLANK');
        Observer.Verify();
    end;

    [Test]
    procedure QueryRecordId_Variant_Result()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QRid Query";
        V: Variant;
    begin
        Seed();
        Q.SetRange(RowId, 1);
        Q.Open();
        Observer.Observe('read', Format(Q.Read()));
        V := Q.RefCol;
        Observer.Observe('is_recordid', Format(V.IsRecordId()));
        Observer.Observe('is_text', Format(V.IsText()));
        Observer.Observe('is_integer', Format(V.IsInteger()));
        Q.Close();
        Observer.Expect('read', 'Yes');
        Observer.Expect('is_recordid', 'Yes');
        Observer.Expect('is_text', 'No');
        Observer.Expect('is_integer', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure QueryRecordId_AllRows_Result()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT QRid Query";
        N: Integer;
        Seen: Text;
    begin
        Seed();
        Q.Open();
        while Q.Read() do begin
            N += 1;
            Seen += Format(Q.RowId) + '=' + Format(Q.RefCol) + ';';
        end;
        Q.Close();
        Observer.Observe('rows', Format(N));
        Observer.Observe('seen', Seen);
        Observer.Expect('rows', '2');
        Observer.Expect('seen', '1=LT QRid Row: 1;2=;');
        Observer.Verify();
    end;
}
