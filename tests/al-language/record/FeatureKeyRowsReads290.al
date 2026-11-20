// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/feature-management
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: reads of the platform table "Feature Key" (2000000211) on BC 29.0, measured for al-runner pull request 8504 (the Feature Key rows of BC 29.1).
// DRAFT
codeunit 99985 "LT FK Rows Reads 29.0"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Applies(): Boolean
    var
        AppConstants: Codeunit "Application System Constants";
        Version: Text;
    begin
        Version := AppConstants.ApplicationVersion();
        // The text starts with the country ('W1 29.1.57326.0' or 'DE 29.1.57326.0'): keep the version.
        if Version.Contains(' ') then
            Version := CopyStr(Version, StrPos(Version, ' ') + 1);
        exit((Version + '.').StartsWith('29.0.'));
    end;

    local procedure Row(var FeatureKey: Record "Feature Key"): Text
    begin
        exit('Enabled=' + Format(FeatureKey.Enabled) +
            ' | Mandatory By=' + FeatureKey."Mandatory By" +
            ' | Mandatory By Version=' + FeatureKey."Mandatory By Version" +
            ' | Can Try=' + Format(FeatureKey."Can Try") +
            ' | Is One Way=' + Format(FeatureKey."Is One Way") +
            ' | Data Update Required=' + Format(FeatureKey."Data Update Required") +
            ' | Learn More Link=' + FeatureKey."Learn More Link" +
            ' | Description In English=' + FeatureKey."Description In English");
    end;

    [Test]
    procedure Rows_ScanColumnsPerId()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        if not Applies() then
            exit;
        if FeatureKey.FindSet() then
            repeat
                N += 1;
                Observer.Observe('row ' + FeatureKey.ID, Row(FeatureKey));
            until FeatureKey.Next() = 0;
        Observer.Observe('rows', Format(N));
        Observer.Finish();
    end;

    [Test]
    procedure Rows_DescriptionPerId()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
    begin
        if not Applies() then
            exit;
        if FeatureKey.FindSet() then
            repeat
                Observer.Observe('desc ' + FeatureKey.ID, FeatureKey.Description);
            until FeatureKey.Next() = 0;
        Observer.Finish();
    end;

    [Test]
    procedure Rows_GetEachId_EqualsScan()
    var
        FeatureKey: Record "Feature Key";
        ByGet: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
    begin
        if not Applies() then
            exit;
        if FeatureKey.FindSet() then
            repeat
                Clear(ByGet);
                Observer.Observe('get ' + FeatureKey.ID, Format(ByGet.Get(FeatureKey.ID)) + ' ' + Format(Row(ByGet) = Row(FeatureKey)) + ' ' + Format(ByGet.Description = FeatureKey.Description));
            until FeatureKey.Next() = 0;
        Observer.Finish();
    end;

    [Test]
    procedure Rows_FindCountFirstLast()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
        Ids: Text;
        Previous: Text;
        Ascending: Boolean;
    begin
        if not Applies() then
            exit;
        Observer.Observe('count', Format(FeatureKey.Count()));
        Observer.Observe('isempty', Format(FeatureKey.IsEmpty()));
        Observer.Observe('findfirst', Format(FeatureKey.FindFirst()) + ' ' + FeatureKey.ID);
        Observer.Observe('findlast', Format(FeatureKey.FindLast()) + ' ' + FeatureKey.ID);
        Clear(FeatureKey);
        Ascending := true;
        FeatureKey.FindSet();
        repeat
            Ids += FeatureKey.ID + ',';
            if (Previous <> '') and (UpperCase(Previous) > UpperCase(FeatureKey.ID)) then
                Ascending := false;
            Previous := FeatureKey.ID;
        until FeatureKey.Next() = 0;
        Observer.Observe('ids in order', Ids);
        Observer.Observe('ascending by upper-cased id', Format(Ascending));
        Observer.Finish();
    end;

    [Test]
    procedure Rows_FiltersOnServedColumns()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
    begin
        if not Applies() then
            exit;
        FeatureKey.SetRange(Enabled, FeatureKey.Enabled::None);
        Observer.Observe('enabled none', Format(FeatureKey.Count()));
        FeatureKey.SetRange(Enabled, FeatureKey.Enabled::"All Users");
        Observer.Observe('enabled all users', Format(FeatureKey.Count()));
        FeatureKey.Reset();
        FeatureKey.SetRange("Can Try", true);
        Observer.Observe('can try', Format(FeatureKey.Count()));
        FeatureKey.Reset();
        FeatureKey.SetRange("Is One Way", true);
        Observer.Observe('is one way', Format(FeatureKey.Count()));
        FeatureKey.Reset();
        FeatureKey.SetRange("Data Update Required", true);
        Observer.Observe('data update required', Format(FeatureKey.Count()));
        FeatureKey.Reset();
        FeatureKey.SetFilter(ID, 'Concurrent*');
        Observer.Observe('id concurrent*', Format(FeatureKey.Count()));
        FeatureKey.Reset();
        FeatureKey.SetRange("Mandatory By Version", '31.0');
        Observer.Observe('mandatory by version 31.0', Format(FeatureKey.Count()));
        FeatureKey.Reset();
        FeatureKey.SetFilter("Mandatory By", '*Wave 1*');
        Observer.Observe('mandatory by wave 1', Format(FeatureKey.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Rows_FiltersOnTextColumns()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
    begin
        if not Applies() then
            exit;
        FeatureKey.SetFilter(Description, '@*sales*');
        Observer.Observe('description sales', Format(FeatureKey.Count()));
        FeatureKey.Reset();
        FeatureKey.SetFilter("Description In English", '@*sales*');
        Observer.Observe('description in english sales', Format(FeatureKey.Count()));
        FeatureKey.Reset();
        FeatureKey.SetFilter("Learn More Link", 'https*');
        Observer.Observe('learn more link https', Format(FeatureKey.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Rows_NoRow_GetAndFind()
    var
        FeatureKey: Record "Feature Key";
        Observer: Codeunit "Probe Observer";
    begin
        if not Applies() then
            exit;
        Observer.Observe('get missing', Format(FeatureKey.Get('NoSuchFeatureKeyZzz')));
        asserterror FeatureKey.Get('NoSuchFeatureKeyZzz');
        Observer.ObserveError('get missing error');
        FeatureKey.SetRange(ID, 'NoSuchFeatureKeyZzz');
        Observer.Observe('find missing', Format(FeatureKey.FindFirst()));
        Observer.Observe('isempty missing', Format(FeatureKey.IsEmpty()));
        Observer.Observe('count missing', Format(FeatureKey.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Rows_RecordRefScan()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Observer: Codeunit "Probe Observer";
        Ids: Text;
        Names: Text;
        i: Integer;
    begin
        if not Applies() then
            exit;
        RecRef.Open(Database::"Feature Key");
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            Names += Format(FldRef.Number()) + '=' + FldRef.Name() + ' ';
        end;
        Observer.Observe('fields', Names);
        Observer.Observe('count', Format(RecRef.Count()));
        Observer.Observe('isempty', Format(RecRef.IsEmpty()));
        if RecRef.FindSet() then
            repeat
                FldRef := RecRef.Field(1);
                Ids += Format(FldRef.Value()) + ',';
            until RecRef.Next() = 0;
        Observer.Observe('ids in order', Ids);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_TemporaryRecordStartsEmpty()
    var
        FeatureKey: Record "Feature Key" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        if not Applies() then
            exit;
        Observer.Observe('count before', Format(FeatureKey.Count()));
        FeatureKey.ID := 'TempOnly';
        FeatureKey.Insert();
        Observer.Observe('count after', Format(FeatureKey.Count()));
        Observer.Observe('get', Format(FeatureKey.Get('TempOnly')));
        Observer.Finish();
    end;
}
