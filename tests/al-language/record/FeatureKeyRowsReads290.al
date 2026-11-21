// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/feature-management
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: reads of the platform table "Feature Key" (2000000211) on BC 29.0, written for al-runner issue 8192 and pull request 8504 (the Feature Key rows of BC 29.1).
// The tests only run on platform 29.0.55782 (the platform of the 29.0.54011.55816 build the corpus CI pins); on every other build they do nothing.
// Measured on BC 29.0.54011.55816 (platform 29.0.55782.0), country W1, local container (the control for the 29.1 file FeatureKeyRowsReads291.al): 13 rows. CI runs this file on its 29.0 leg.
// A Windows sandbox container of application 29.0 (symbols 29.0.54011.56609, platform 29.0.56480) answered 14 rows with the 29.1 values: the row set follows the platform build, not the application minor.
// The row set is the one PFFeatureKeyColumns.al pins (without the text columns); this file adds Description, Learn More Link, Description In English, Get, filters and RecordRef.
// Cells (one test each): every row with all columns but Description (Rows_ScanColumnsPerId), Description per row (Rows_DescriptionPerId), Get of each id equals the scan
// (Rows_GetEachId_EqualsScan), Count, IsEmpty, FindFirst, FindLast and the order of the ids (Rows_FindCountFirstLast), filters on Enabled, Can Try, Is One Way, Data Update
// Required, ID and Mandatory By (Rows_FiltersOnServedColumns), filters on Description, Description In English and Learn More Link (Rows_FiltersOnTextColumns), a Get and a
// filter that find no row (Rows_NoRow_GetAndFind), the same through a RecordRef (Rows_RecordRefScan) and a temporary record (Rows_TemporaryRecordStartsEmpty).
// Not covered: writes (Modify, Insert, Delete) on the platform table, other builds, countries other than W1.
// BC versions: 29.0 (platform 29.0.55782)
codeunit 99985 "LT FK Rows Reads 29.0"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Applies(): Boolean
    var
        AppConstants: Codeunit "Application System Constants";
    begin
        // The rows follow the platform build, not the application minor: a 29.0 application on a later platform has 14 rows (see the header).
        exit((AppConstants.PlatformFileVersion() + '.').StartsWith('29.0.55782.'));
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
        Observer.Expect('row AcceleratedDepreciation', 'Enabled=None | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes | Learn More Link=TODO | Description In English=Feature Update: Accelerated Depreciation');
        Observer.Expect('row AdvancedTellMe', 'Enabled=All Users | Mandatory By=2027 Wave 1 (from April to September 2027) | Mandatory By Version=30.0 | Can Try=No | Is One Way=No | Data Update Required=No | Learn More Link=https://go.microsoft.com/fwlink/?linkid=2331650 | Description In English=Feature: Advanced Tell Me');
        Observer.Expect('row ConcurrentInventoryPosting', 'Enabled=All Users | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=No | Data Update Required=No | Learn More Link=https://go.microsoft.com/fwlink/?linkid=2299833 | Description In English=Feature Update: Enable multiple users to post item ledger entries and value entries at the same time');
        Observer.Expect('row ConcurrentJobPosting', 'Enabled=All Users | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=No | Data Update Required=No | Learn More Link=https://go.microsoft.com/fwlink/?linkid=2299833 | Description In English=Feature Update: Enable multiple users to post job ledger entries at the same time');
        Observer.Expect('row ConcurrentResourcePosting', 'Enabled=All Users | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=No | Data Update Required=No | Learn More Link=https://go.microsoft.com/fwlink/?linkid=2299833 | Description In English=Feature Update: Enable multiple users to post resource ledger entries at the same time');
        Observer.Expect('row DisableSoapWebServicesOnMicrosoftUIPages', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=No | Is One Way=No | Data Update Required=No | Learn More Link=https://go.microsoft.com/fwlink/?linkid=2312202 | Description In English=Feature: Disable SOAP web services on Microsoft UI pages');
        Observer.Expect('row DocumentReportExperience', 'Enabled=All Users | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=No | Data Update Required=No | Learn More Link=https://learn.microsoft.com/en-us/dynamics365/business-central/ui-manage-report-layouts | Description In English=Feature: New Document Report Experience');
        Observer.Expect('row EXRPerformantTrialBalance', 'Enabled=All Users | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=Yes | Is One Way=No | Data Update Required=No | Learn More Link=https://learn.microsoft.com/dynamics365/business-central/reports/report-4405 | Description In English=Feature Update: Improved performance in Trial Balance-related Excel reports');
        Observer.Expect('row FinancialReportDefaults', 'Enabled=All Users | Mandatory By=2026 Wave 2 (from October 2026 to March 2027) | Mandatory By Version=29.0 | Can Try=Yes | Is One Way=No | Data Update Required=No | Learn More Link=https://learn.microsoft.com/en-us/dynamics365/release-plan/2025wave2/smb/dynamics365-business-central/use-enhanced-financial-reporting | Description In English=Feature Update: Provides functionality for having default values for financial reports');
        Observer.Expect('row FullTextSearch', 'Enabled=None | Mandatory By=2027 Wave 1 (from April to September 2027) | Mandatory By Version=30.0 | Can Try=Yes | Is One Way=No | Data Update Required=No | Learn More Link=https://go.microsoft.com/fwlink/?linkid=2280603 | Description In English=Feature: Use optimized text search in lists');
        Observer.Expect('row SalesPrices', 'Enabled=None | Mandatory By=2027 Wave 2 (from October 2027 to March 2028) | Mandatory By Version=31.0 | Can Try=No | Is One Way=Yes | Data Update Required=Yes | Learn More Link=https://go.microsoft.com/fwlink/?linkid=2136722 | Description In English=Feature Update: New sales pricing experience');
        Observer.Expect('row SaveValueToDatabasePromptly', 'Enabled=All Users | Mandatory By=2027 Wave 1 (from April to September 2027) | Mandatory By Version=30.0 | Can Try=Yes | Is One Way=No | Data Update Required=No | Learn More Link=https://go.microsoft.com/fwlink/?linkid=2212032 | Description In English=Feature Update: Auto-save with every field change');
        Observer.Expect('row SemanticMetadataSearch', 'Enabled=All Users | Mandatory By=2027 Wave 1 (from April to September 2027) | Mandatory By Version=30.0 | Can Try=No | Is One Way=No | Data Update Required=No | Learn More Link=https://go.microsoft.com/fwlink/?linkid=2312404 | Description In English=Feature: Preview semantic similarity search on application metadata.');
        Observer.Expect('rows', '13');
        Observer.Verify();
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
        Observer.Expect('desc AcceleratedDepreciation', 'Feature Update: Accelerated Depreciation');
        Observer.Expect('desc AdvancedTellMe', 'Feature: Advanced Tell Me');
        Observer.Expect('desc ConcurrentInventoryPosting', 'Feature Update: Enable multiple users to post item ledger entries and value entries at the same time');
        Observer.Expect('desc ConcurrentJobPosting', 'Feature Update: Enable multiple users to post job ledger entries at the same time');
        Observer.Expect('desc ConcurrentResourcePosting', 'Feature Update: Enable multiple users to post resource ledger entries at the same time');
        Observer.Expect('desc DisableSoapWebServicesOnMicrosoftUIPages', 'Feature: Disable SOAP web services on Microsoft UI pages');
        Observer.Expect('desc DocumentReportExperience', 'Feature: New Document Report Experience');
        Observer.Expect('desc EXRPerformantTrialBalance', 'Feature Update: Improved performance in Trial Balance-related Excel reports');
        Observer.Expect('desc FinancialReportDefaults', 'Feature Update: Provides functionality for having default values for financial reports');
        Observer.Expect('desc FullTextSearch', 'Feature: Use optimized text search in lists');
        Observer.Expect('desc SalesPrices', 'Feature Update: New sales pricing experience');
        Observer.Expect('desc SaveValueToDatabasePromptly', 'Feature Update: Auto-save with every field change');
        Observer.Expect('desc SemanticMetadataSearch', 'Feature: Preview semantic similarity search on application metadata.');
        Observer.Verify();
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
        Observer.Expect('get AcceleratedDepreciation', 'Yes Yes Yes');
        Observer.Expect('get AdvancedTellMe', 'Yes Yes Yes');
        Observer.Expect('get ConcurrentInventoryPosting', 'Yes Yes Yes');
        Observer.Expect('get ConcurrentJobPosting', 'Yes Yes Yes');
        Observer.Expect('get ConcurrentResourcePosting', 'Yes Yes Yes');
        Observer.Expect('get DisableSoapWebServicesOnMicrosoftUIPages', 'Yes Yes Yes');
        Observer.Expect('get DocumentReportExperience', 'Yes Yes Yes');
        Observer.Expect('get EXRPerformantTrialBalance', 'Yes Yes Yes');
        Observer.Expect('get FinancialReportDefaults', 'Yes Yes Yes');
        Observer.Expect('get FullTextSearch', 'Yes Yes Yes');
        Observer.Expect('get SalesPrices', 'Yes Yes Yes');
        Observer.Expect('get SaveValueToDatabasePromptly', 'Yes Yes Yes');
        Observer.Expect('get SemanticMetadataSearch', 'Yes Yes Yes');
        Observer.Verify();
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
        Observer.Expect('count', '13');
        Observer.Expect('isempty', 'No');
        Observer.Expect('findfirst', 'Yes AcceleratedDepreciation');
        Observer.Expect('findlast', 'Yes SemanticMetadataSearch');
        Observer.Expect('ids in order', 'AcceleratedDepreciation,AdvancedTellMe,ConcurrentInventoryPosting,ConcurrentJobPosting,ConcurrentResourcePosting,DisableSoapWebServicesOnMicrosoftUIPages,DocumentReportExperience,EXRPerformantTrialBalance,FinancialReportDefaults,FullTextSearch,SalesPrices,SaveValueToDatabasePromptly,SemanticMetadataSearch,');
        Observer.Expect('ascending by upper-cased id', 'Yes');
        Observer.Verify();
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
        Observer.Expect('enabled none', '3');
        Observer.Expect('enabled all users', '10');
        Observer.Expect('can try', '4');
        Observer.Expect('is one way', '2');
        Observer.Expect('data update required', '2');
        Observer.Expect('id concurrent*', '3');
        Observer.Expect('mandatory by version 31.0', '7');
        Observer.Expect('mandatory by wave 1', '4');
        Observer.Verify();
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
        Observer.Expect('description sales', '1');
        Observer.Expect('description in english sales', '1');
        Observer.Expect('learn more link https', '12');
        Observer.Verify();
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
        Observer.Expect('get missing', 'No');
        Observer.Expect('get missing error|text', 'The Feature Key does not exist. Identification fields and values: ID=''NoSuchFeatureKeyZzz''');
        Observer.Expect('get missing error|code', 'DB:RecordNotFound');
        Observer.Expect('find missing', 'No');
        Observer.Expect('isempty missing', 'Yes');
        Observer.Expect('count missing', '0');
        Observer.Verify();
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
        Observer.Expect('fields', '1=ID 2=Enabled 3=Description 4=Learn More Link 5=Mandatory By 6=Can Try 7=Is One Way 8=Data Update Required 9=Mandatory By Version 10=Description In English ');
        Observer.Expect('count', '13');
        Observer.Expect('isempty', 'No');
        Observer.Expect('ids in order', 'AcceleratedDepreciation,AdvancedTellMe,ConcurrentInventoryPosting,ConcurrentJobPosting,ConcurrentResourcePosting,DisableSoapWebServicesOnMicrosoftUIPages,DocumentReportExperience,EXRPerformantTrialBalance,FinancialReportDefaults,FullTextSearch,SalesPrices,SaveValueToDatabasePromptly,SemanticMetadataSearch,');
        Observer.Verify();
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
        Observer.Expect('count before', '0');
        Observer.Expect('count after', '1');
        Observer.Expect('get', 'Yes');
        Observer.Verify();
    end;
}
