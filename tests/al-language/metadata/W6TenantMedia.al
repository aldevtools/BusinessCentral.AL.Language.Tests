// Batch 6, md:365 [Tenant Media, API Webhook Entity]. API Webhook Entity is Scope = OnPrem (AL0296 in a Cloud app, see MANIFEST): not probed.
// Tenant Media: what reading it shows with no write at all, and the row that Media.ImportStream on an own table leaves (the platform writes the row, the test only reads it).
// Observe-only. Media ids are GUIDs and are never printed.

table 67332 "W6 TMed Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Image; Media) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67333 "W6 Tenant Media Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ColumnList(TableId: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Result: Text;
        i: Integer;
    begin
        RecRef.Open(TableId);
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            Result += Format(FldRef.Number()) + '=' + FldRef.Name() + ';';
        end;
        exit(Result);
    end;

    [Test]
    procedure TenantMedia_ReadsWithoutAnyWrite()
    var
        TenantMedia: Record "Tenant Media";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get_unknown_id', Format(TenantMedia.Get(CreateGuid())));
        TenantMedia.Reset();
        Observer.Observe('count_is_number', Format(TenantMedia.Count() >= 0));
        Observer.Observe('is_empty_matches_count', Format(TenantMedia.IsEmpty() = (TenantMedia.Count() = 0)));
        Observer.Expect('get_unknown_id', 'No');
        Observer.Expect('count_is_number', 'Yes');
        Observer.Expect('is_empty_matches_count', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TenantMedia_ColumnNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tenant_media_columns', ColumnList(Database::"Tenant Media"));
        Observer.Expect('tenant_media_columns', '1=ID;2=Description;3=Content;4=Mime Type;5=Height;6=Width;7=Company Name;8=Expiration Date;10=Prohibit Cache;11=File Name;12=Security Token;13=Creating User;');
        Observer.Verify();
    end;

    [Test]
    procedure TenantMedia_RowAfterImportStream()
    var
        Row: Record "W6 TMed Row";
        TenantMedia: Record "Tenant Media";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Before: Integer;
        MediaId: Guid;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Before := TenantMedia.Count();
        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', OutStr);
        TempBlob.CreateInStream(InStr);
        Row.Id := 1;
        Row.Image.ImportStream(InStr, 'w6 description', 'image/png');
        Row.Insert();
        Row.Get(1);
        MediaId := Row.Image.MediaId;
        Observer.Observe('has_value', Format(Row.Image.HasValue()));
        Observer.Observe('media_id_null', Format(IsNullGuid(MediaId)));
        Observer.Observe('tenant_media_count_delta', Format(TenantMedia.Count() - Before));
        Observer.Observe('tenant_media_row_found', Format(TenantMedia.Get(MediaId)));
        TenantMedia.CalcFields(Content);
        Observer.Observe('content_has_value', Format(TenantMedia.Content.HasValue()));
        Observer.Observe('mime_type', TenantMedia."Mime Type");
        Observer.Observe('width', Format(TenantMedia.Width));
        Observer.Observe('height', Format(TenantMedia.Height));
        Observer.Observe('company_name_is_session_company', Format(TenantMedia."Company Name" = CompanyName()));
        Observer.Expect('has_value', 'Yes');
        Observer.Expect('media_id_null', 'No');
        Observer.Expect('tenant_media_count_delta', '1');
        Observer.Expect('tenant_media_row_found', 'Yes');
        Observer.Expect('content_has_value', 'Yes');
        Observer.Expect('mime_type', 'image/png');
        Observer.Expect('width', '1');
        Observer.Expect('height', '1');
        Observer.Expect('company_name_is_session_company', 'Yes');
        Observer.Verify();
    end;
}
