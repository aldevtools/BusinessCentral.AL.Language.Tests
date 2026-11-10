// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tabletype-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 75116 (TableType = Temporary), test codeunit 75117; Base Application tables 18, 33 and 5341
// local object: the TableType of the table is what is under test
// Probe (observe only): al-runner issue 7465. types/AjMisc.al (QT_FieldTable_*) pins the Field table row of the rowversion (No. 0, timestamp) for
//   normal tables: found by a FieldName filter only, not by Get(table, 0), a No. filter or a Type filter. Base Application codeunit 408
//   DimensionManagement reads the Field table over every table with filters on Class, ObsoleteState, FieldName (a wildcard), Type, Len and
//   RelationTableNo, so the same questions need an answer for the other kinds of tables:
//     an own table with TableType = Temporary, Base Application table 33 "Intercompany Setup Diagnostic" (TableType = Temporary),
//     Base Application table 5341 "CRM Account" (TableType = CDS), the system tables User (2000000120) and Field (2000000041),
//     the virtual tables Integer (2000000026) and Date (2000000007), and Customer (18) as the normal control.
//   Per table: the TableType of Table Metadata, Get(table, 0), the rows named timestamp, the count for No. = 0, for wildcard and case-insensitive
//   name filters, for the filters of DimensionManagement, the first row of the table, and what a RecordRef says (FieldCount, FieldExist(0)).
// BC versions: 27, 28, 29

table 75116 "LT FTS Temporary Type"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Global Dimension 1 Code"; Code[20]) { }
        field(3; "Dimension Set ID"; Integer) { TableRelation = "Dimension Set Entry"; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 75117 "LT FTS Timestamp Row Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RowText(var Fld: Record Field): Text
    begin
        exit(Format(Fld."No.") + ':' + Fld.FieldName + ':' + Format(Fld.Type) + ':' + Format(Fld.Class) + ':' + Format(Fld.Len) + ':' + Format(Fld.Enabled) + ':' + Format(Fld.ObsoleteState));
    end;

    local procedure Rows(var Fld: Record Field): Text
    var
        Result: Text;
        Guard: Integer;
    begin
        if Fld.FindSet() then
            repeat
                Guard += 1;
                Result += RowText(Fld) + ';';
            until (Fld.Next() = 0) or (Guard >= 5);
        exit('[' + Result + ']');
    end;

    [TryFunction]
    local procedure TryRecordRef(TableNumber: Integer; var Answer: Text)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Index: Integer;
        Found: Text;
    begin
        RecRef.Open(TableNumber, true);
        for Index := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(Index);
            if (FldRef.Name() = 'timestamp') or (FldRef.Number() = 0) then
                Found += Format(Index) + ':' + FldRef.Name() + '#' + Format(FldRef.Number()) + ';';
        end;
        Answer := 'FieldExist(0)=' + Format(RecRef.FieldExist(0)) + ' walk=[' + Found + ']';
        RecRef.Close();
    end;

    [TryFunction]
    local procedure TryTableType(TableNumber: Integer; var Answer: Text)
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableNumber) then
            Answer := Format(TableMetadata.TableType)
        else
            Answer := 'no Table Metadata row';
    end;

    local procedure ObserveTable(var Observer: Codeunit "Probe Observer"; TableNumber: Integer)
    var
        Fld: Record Field;
        Answer: Text;
    begin
        if TryTableType(TableNumber, Answer) then
            Observer.Observe('table type', Answer)
        else
            Observer.ObserveError('table type');
        Observer.Observe('Get(table, 0)', Format(Fld.Get(TableNumber, 0)));
        Fld.SetRange(TableNo, TableNumber);
        Fld.SetRange(FieldName, 'timestamp');
        Observer.Observe('by name timestamp', Rows(Fld));
        Fld.SetFilter(FieldName, '@TIMESTAMP');
        Observer.Observe('by name @TIMESTAMP count', Format(Fld.Count()));
        Fld.SetFilter(FieldName, '*stamp*');
        Observer.Observe('by name *stamp* count', Format(Fld.Count()));
        Fld.SetFilter(FieldName, 'timestamp|Id');
        Observer.Observe('by name timestamp|Id', Rows(Fld));
        Fld.SetRange(FieldName);
        Fld.SetRange("No.", 0);
        Observer.Observe('No. = 0 count', Format(Fld.Count()));
        Fld.SetRange("No.");
        Fld.SetRange(Type, Fld.Type::BigInteger);
        Fld.SetRange(Len, 8);
        Observer.Observe('BigInteger of length 8 named timestamp count', CountNamed(Fld, 'timestamp'));
        Fld.SetRange(Type);
        Fld.SetRange(Len);
        Observer.Observe('first row', FirstRow(Fld));
        // The filters of DimensionManagement.FillNormalFieldBuffer (Base Application codeunit 408).
        Fld.SetRange(Class, Fld.Class::Normal);
        Fld.SetFilter(ObsoleteState, '<>%1', Fld.ObsoleteState::Removed);
        Fld.SetFilter(FieldName, '*Global Dimension*');
        Fld.SetRange(Type, Fld.Type::Code);
        Fld.SetRange(Len, 20);
        Observer.Observe('dimension field filters', Rows(Fld));
        Fld.SetRange(FieldName);
        Fld.SetRange(Type);
        Fld.SetRange(Len);
        Fld.SetRange(RelationTableNo, Database::"Dimension Set Entry");
        Observer.Observe('dimension set relation filters', Rows(Fld));
        Fld.SetRange(RelationTableNo);
        Observer.Observe('normal and not removed, named timestamp count', CountNamed(Fld, 'timestamp'));
        Answer := '';
        ClearLastError();
        if TryRecordRef(TableNumber, Answer) then
            Observer.Observe('RecordRef', Answer)
        else
            Observer.ObserveError('RecordRef');
    end;

    local procedure CountNamed(var Fld: Record Field; Name: Text): Text
    var
        Copy: Record Field;
    begin
        Copy.CopyFilters(Fld);
        Copy.SetRange(FieldName, Name);
        exit(Format(Copy.Count()));
    end;

    local procedure FirstRow(var Fld: Record Field): Text
    begin
        if Fld.FindFirst() then
            exit(RowText(Fld));
        exit('no row');
    end;

    [Test]
    procedure FieldTable_TimestampRow_OwnTemporaryTypeTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveTable(Observer, Database::"LT FTS Temporary Type");
        Observer.Expect('table type', 'Temporary');
        Observer.Expect('Get(table, 0)', 'No');
        Observer.Expect('by name timestamp', '[0:timestamp:BigInteger:Normal:8:Yes:No;]');
        Observer.Expect('by name @TIMESTAMP count', '0');
        Observer.Expect('by name *stamp* count', '0');
        Observer.Expect('by name timestamp|Id', '[1:Id:Integer:Normal:4:Yes:No;]');
        Observer.Expect('No. = 0 count', '0');
        Observer.Expect('BigInteger of length 8 named timestamp count', '1');
        Observer.Expect('first row', '1:Id:Integer:Normal:4:Yes:No');
        Observer.Expect('dimension field filters', '[2:Global Dimension 1 Code:Code:Normal:20:Yes:No;]');
        Observer.Expect('dimension set relation filters', '[3:Dimension Set ID:Integer:Normal:4:Yes:No;]');
        Observer.Expect('normal and not removed, named timestamp count', '1');
        Observer.Expect('RecordRef', 'FieldExist(0)=No walk=[]');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_TimestampRow_BaseAppTemporaryTypeTable33()
    var
        Observer: Codeunit "Probe Observer";
        AllObj: Record AllObj;
    begin
        if AllObj.Get(AllObj."Object Type"::Table, 33) then
            Observer.Observe('table 33 name', AllObj."Object Name")
        else
            Observer.Observe('table 33 name', 'no such table');
        ObserveTable(Observer, 33);
        Observer.Expect('table 33 name', 'Intercompany Setup Diagnostic');
        Observer.Expect('table type', 'Temporary');
        Observer.Expect('Get(table, 0)', 'No');
        Observer.Expect('by name timestamp', '[0:timestamp:BigInteger:Normal:8:Yes:No;]');
        Observer.Expect('by name @TIMESTAMP count', '0');
        Observer.Expect('by name *stamp* count', '0');
        Observer.Expect('by name timestamp|Id', '[1:Id:Code:Normal:20:Yes:No;]');
        Observer.Expect('No. = 0 count', '0');
        Observer.Expect('BigInteger of length 8 named timestamp count', '1');
        Observer.Expect('first row', '1:Id:Code:Normal:20:Yes:No');
        Observer.Expect('dimension field filters', '[]');
        Observer.Expect('dimension set relation filters', '[]');
        Observer.Expect('normal and not removed, named timestamp count', '1');
        Observer.Expect('RecordRef', 'FieldExist(0)=No walk=[]');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_TimestampRow_CdsTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveTable(Observer, Database::"CRM Account");
        Observer.Expect('table type', 'CRM');
        Observer.Expect('Get(table, 0)', 'No');
        Observer.Expect('by name timestamp', '[0:timestamp:BigInteger:Normal:8:Yes:No;]');
        Observer.Expect('by name @TIMESTAMP count', '0');
        Observer.Expect('by name *stamp* count', '0');
        Observer.Expect('by name timestamp|Id', '[]');
        Observer.Expect('No. = 0 count', '0');
        Observer.Expect('BigInteger of length 8 named timestamp count', '1');
        Observer.Expect('first row', '1:AccountId:GUID:Normal:16:Yes:No');
        Observer.Expect('dimension field filters', '[]');
        Observer.Expect('dimension set relation filters', '[]');
        Observer.Expect('normal and not removed, named timestamp count', '1');
        Observer.Expect('RecordRef', 'FieldExist(0)=No walk=[]');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_TimestampRow_SystemTableUser()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveTable(Observer, Database::User);
        Observer.Expect('table type', 'Normal');
        Observer.Expect('Get(table, 0)', 'No');
        Observer.Expect('by name timestamp', '[0:timestamp:BigInteger:Normal:8:Yes:No;]');
        Observer.Expect('by name @TIMESTAMP count', '0');
        Observer.Expect('by name *stamp* count', '0');
        Observer.Expect('by name timestamp|Id', '[]');
        Observer.Expect('No. = 0 count', '0');
        Observer.Expect('BigInteger of length 8 named timestamp count', '1');
        Observer.Expect('first row', '1:User Security ID:GUID:Normal:16:Yes:No');
        Observer.Expect('dimension field filters', '[]');
        Observer.Expect('dimension set relation filters', '[]');
        Observer.Expect('normal and not removed, named timestamp count', '1');
        Observer.Expect('RecordRef', 'FieldExist(0)=No walk=[]');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_TimestampRow_SystemTableField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveTable(Observer, Database::Field);
        Observer.Expect('table type', 'Normal');
        Observer.Expect('Get(table, 0)', 'No');
        Observer.Expect('by name timestamp', '[0:timestamp:BigInteger:Normal:8:Yes:No;]');
        Observer.Expect('by name @TIMESTAMP count', '0');
        Observer.Expect('by name *stamp* count', '0');
        Observer.Expect('by name timestamp|Id', '[]');
        Observer.Expect('No. = 0 count', '0');
        Observer.Expect('BigInteger of length 8 named timestamp count', '1');
        Observer.Expect('first row', '1:TableNo:Integer:Normal:4:Yes:No');
        Observer.Expect('dimension field filters', '[]');
        Observer.Expect('dimension set relation filters', '[]');
        Observer.Expect('normal and not removed, named timestamp count', '1');
        Observer.Expect('RecordRef', 'FieldExist(0)=No walk=[]');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_TimestampRow_VirtualTableInteger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveTable(Observer, Database::Integer);
        Observer.Expect('table type', 'Normal');
        Observer.Expect('Get(table, 0)', 'No');
        Observer.Expect('by name timestamp', '[0:timestamp:BigInteger:Normal:8:Yes:No;]');
        Observer.Expect('by name @TIMESTAMP count', '0');
        Observer.Expect('by name *stamp* count', '0');
        Observer.Expect('by name timestamp|Id', '[]');
        Observer.Expect('No. = 0 count', '0');
        Observer.Expect('BigInteger of length 8 named timestamp count', '1');
        Observer.Expect('first row', '1:Number:Integer:Normal:4:Yes:No');
        Observer.Expect('dimension field filters', '[]');
        Observer.Expect('dimension set relation filters', '[]');
        Observer.Expect('normal and not removed, named timestamp count', '1');
        Observer.Expect('RecordRef', 'FieldExist(0)=No walk=[]');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_TimestampRow_VirtualTableDate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveTable(Observer, Database::Date);
        Observer.Expect('table type', 'Normal');
        Observer.Expect('Get(table, 0)', 'No');
        Observer.Expect('by name timestamp', '[0:timestamp:BigInteger:Normal:8:Yes:No;]');
        Observer.Expect('by name @TIMESTAMP count', '0');
        Observer.Expect('by name *stamp* count', '0');
        Observer.Expect('by name timestamp|Id', '[]');
        Observer.Expect('No. = 0 count', '0');
        Observer.Expect('BigInteger of length 8 named timestamp count', '1');
        Observer.Expect('first row', '1:Period Type:Option:Normal:4:Yes:No');
        Observer.Expect('dimension field filters', '[]');
        Observer.Expect('dimension set relation filters', '[]');
        Observer.Expect('normal and not removed, named timestamp count', '1');
        Observer.Expect('RecordRef', 'FieldExist(0)=No walk=[]');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_TimestampRow_NormalTable_Control()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveTable(Observer, Database::Customer);
        Observer.Expect('table type', 'Normal');
        Observer.Expect('Get(table, 0)', 'No');
        Observer.Expect('by name timestamp', '[0:timestamp:BigInteger:Normal:8:Yes:No;]');
        Observer.Expect('by name @TIMESTAMP count', '0');
        Observer.Expect('by name *stamp* count', '0');
        Observer.Expect('by name timestamp|Id', '[]');
        Observer.Expect('No. = 0 count', '0');
        Observer.Expect('BigInteger of length 8 named timestamp count', '1');
        Observer.Expect('first row', '1:No.:Code:Normal:20:Yes:No');
        Observer.Expect('dimension field filters', '[16:Global Dimension 1 Code:Code:Normal:20:Yes:No;17:Global Dimension 2 Code:Code:Normal:20:Yes:No;]');
        Observer.Expect('dimension set relation filters', '[]');
        Observer.Expect('normal and not removed, named timestamp count', '1');
        Observer.Expect('RecordRef', 'FieldExist(0)=No walk=[]');
        Observer.Verify();
    end;

    [Test]
    procedure FieldTable_TimestampRows_AcrossTables()
    var
        Observer: Codeunit "Probe Observer";
        Fld: Record Field;
        Result: Text;
    begin
        // Which of the probed tables answer a timestamp row when TableNo is a filter over several tables, as in DimensionManagement.
        Fld.SetFilter(TableNo, '%1|%2|%3|%4|%5|%6', 18, 33, Database::"CRM Account", Database::"LT FTS Temporary Type", Database::User, Database::Integer);
        Fld.SetRange(FieldName, 'timestamp');
        if Fld.FindSet() then
            repeat
                Result += Format(Fld.TableNo) + ';';
            until Fld.Next() = 0;
        Observer.Observe('tables with a timestamp row by name', '[' + Result + ']');
        Fld.SetRange(FieldName);
        Fld.SetRange("No.", 0);
        Observer.Observe('No. = 0 count over these tables', Format(Fld.Count()));
        Fld.SetRange("No.");
        Fld.SetRange(Class, Fld.Class::Normal);
        Fld.SetFilter(ObsoleteState, '<>%1', Fld.ObsoleteState::Removed);
        Fld.SetFilter(FieldName, '*Global Dimension*');
        Fld.SetRange(Type, Fld.Type::Code);
        Fld.SetRange(Len, 20);
        Result := '';
        if Fld.FindSet() then
            repeat
                Result += Format(Fld.TableNo) + ':' + Fld.FieldName + ';';
            until Fld.Next() = 0;
        Observer.Observe('dimension field filters over these tables', '[' + Result + ']');
        Observer.Expect('tables with a timestamp row by name', '[18;33;5341;75116;2000000026;2000000120;]');
        Observer.Expect('No. = 0 count over these tables', '0');
        Observer.Expect('dimension field filters over these tables', '[18:Global Dimension 1 Code;18:Global Dimension 2 Code;75116:Global Dimension 1 Code;]');
        Observer.Verify();
    end;
}
