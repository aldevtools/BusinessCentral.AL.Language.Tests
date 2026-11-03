// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-importfile-method
// Scope: in-scope (OnPrem only: Media.ImportFile and MediaSet.ImportFile are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained table 61294 and codeunit 61294
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816). Other BC versions were not measured.
//
// Media.ImportFile and MediaSet.ImportFile of a file that does not exist answer false inside a TryFunction with the .NET text "Could not find a part of the path '<path>'." and code InvalidPath;
// an empty file name gives "The specified path is invalid." (InvalidPath). Nothing is imported: HasValue stays false and the MediaSet stays empty.
// BC versions: 29.0
table 61294 "PZ OnPrem Media Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Pic; Media) { }
        field(3; Set; MediaSet) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 61294 "PZ Media ImportFile"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryImport(var Row: Record "PZ OnPrem Media Row"; FileName: Text)
    begin
        Row.Pic.ImportFile(FileName, 'description');
    end;

    [TryFunction]
    local procedure TryImportSet(var Row: Record "PZ OnPrem Media Row"; FileName: Text)
    begin
        Row.Set.ImportFile(FileName, 'description');
    end;

    [Test]
    procedure Media_ImportFile_MissingFile_AndMediaSet()
    var
        Row: Record "PZ OnPrem Media Row";
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Ok := TryImport(Row, '/no/such/dir/missing-picture.png');
        Observer.Observe('media_missing_file', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryImportSet(Row, '/no/such/dir/missing-picture.png');
        Observer.Observe('mediaset_missing_file', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryImport(Row, '');
        Observer.Observe('media_empty_name', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('hasvalue_after_failures', Format(Row.Pic.HasValue()) + '/' + Format(Row.Set.Count()));
        Observer.Expect('media_missing_file', 'No Could not find a part of the path ''/no/such/dir/missing-picture.png''.|InvalidPath');
        Observer.Expect('mediaset_missing_file', 'No Could not find a part of the path ''/no/such/dir/missing-picture.png''.|InvalidPath');
        Observer.Expect('media_empty_name', 'No The specified path is invalid.|InvalidPath');
        Observer.Expect('hasvalue_after_failures', 'No/0');
        Observer.Verify();
    end;
}
