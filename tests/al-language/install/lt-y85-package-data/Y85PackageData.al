// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Fixtures used: tests/al-language-xapp-a/Y85XaPackageData.al (tables 50100, 94440-94443, table extension 94444, enum 94445, install codeunit 94449) and the
//   data files TAB50100, TAB94440-TAB94443.navxdata in that folder; Probe Observer (69160).
// Probe (writer Y85, al-runner issue 6649): NavApp.LoadPackageData with real package data files. The install codeunit of app A loads the files (per company
//   for the company tables, per database for the DataPerCompany = false table); the tests read what the platform put in the tables, per field type, and call
//   NavApp.LoadPackageData from test code. The file layout is described in Y85XaPackageData.al.
// BC versions: 27 - 29
codeunit 94430 "LT Y85 Package Data"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure DumpCompany(var Row: Record "LT Y85 Pkg Company"): Text
    var
        T: Text;
    begin
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Row.Description + ';';
            until Row.Next() = 0;
        exit(T);
    end;

    local procedure DumpDatabase(): Text
    var
        Row: Record "LT Y85 Pkg Database";
        T: Text;
    begin
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Row.Description + '/' + Format(Row.Amount) + ';';
            until Row.Next() = 0;
        exit(T);
    end;

    local procedure BlobText(var Row: Record "LT Y85 Pkg Types"): Text
    var
        InS: InStream;
        T: Text;
    begin
        Row.CalcFields(Blb);
        if Row.Blb.Length() > 0 then begin
            Row.Blb.CreateInStream(InS);
            InS.Read(T);
        end;
        exit(Format(Row.Blb.Length()) + ':' + T);
    end;

    local procedure TypesRow(No: Code[20]) Row: Record "LT Y85 Pkg Types"
    begin
        Row.Get(No);
    end;

    local procedure Strings(No: Code[20]): Text
    var
        Row: Record "LT Y85 Pkg Types";
    begin
        Row := TypesRow(No);
        exit(Row.Txt + '|' + Row.Cde);
    end;

    local procedure Numbers(No: Code[20]): Text
    var
        Row: Record "LT Y85 Pkg Types";
    begin
        Row := TypesRow(No);
        exit(Format(Row.Int, 0, 9) + '|' + Format(Row.Big, 0, 9) + '|' + Format(Row.Dec, 0, 9) + '|' + Format(Row.Bool, 0, 9));
    end;

    local procedure Dates(No: Code[20]): Text
    var
        Row: Record "LT Y85 Pkg Types";
    begin
        Row := TypesRow(No);
        exit(Format(Row.Dat, 0, 9) + '|' + Format(Row.Tim, 0, 9) + '|' + Format(Row.Dtm, 0, 9));
    end;

    local procedure Others(No: Code[20]): Text
    var
        Row: Record "LT Y85 Pkg Types";
    begin
        Row := TypesRow(No);
        exit(Format(Row.Dur, 0, 9) + '|' + Format(Row.Gid, 0, 9) + '|' + Format(Row.Opt, 0, 9) + '|' + Format(Row.Enm, 0, 9) + '|' + Format(Row.Enm) + '|' + Format(Row.Dfm, 0, 9) + '|' + BlobText(Row));
    end;

    // Company table 50100 (the shape of waldo's example), loaded by OnInstallAppPerCompany.
    [Test]
    procedure Y85_PerCompany_RowsAndNoTrigger()
    var
        Row: Record "LT Y85 Pkg Company";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', DumpCompany(Row));
        Observer.Observe('count', Format(Row.Count()));
        Observer.Expect('rows', '0001=test1;0002=test2;');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Y85_PerCompany_SystemFieldsFromFile()
    var
        Row: Record "LT Y85 Pkg Company";
        Observer: Codeunit "Probe Observer";
        Nothing: Guid;
    begin
        Row.Get('0001');
        Observer.Observe('systemid 0001', Format(Row.SystemId));
        Observer.Observe('created at set', Format(Row.SystemCreatedAt <> 0DT));
        Observer.Observe('created by set', Format(Row.SystemCreatedBy <> Nothing));
        Row.Get('0002');
        Observer.Observe('systemid 0002', Format(Row.SystemId));
        Observer.Expect('systemid 0001', '{00000000-0000-0000-0000-000000008501}');
        Observer.Expect('created at set', 'Yes');
        Observer.Expect('created by set', 'Yes');
        Observer.Expect('systemid 0002', '{00000000-0000-0000-0000-000000008502}');
        Observer.Verify();
    end;

    // The install ran once for every company of the database: every company holds the rows.
    [Test]
    procedure Y85_PerCompany_EveryCompanyHasTheRows()
    var
        Company: Record Company;
        Row: Record "LT Y85 Pkg Company";
        Observer: Codeunit "Probe Observer";
        Wrong: Text;
    begin
        if Company.FindSet() then
            repeat
                Row.ChangeCompany(Company.Name);
                if DumpCompany(Row) <> '0001=test1;0002=test2;' then
                    Wrong += Company.Name + ';';
            until Company.Next() = 0;
        Observer.Observe('companies with other rows', Wrong);
        Observer.Expect('companies with other rows', '');
        Observer.Verify();
    end;

    // Table 94440 has DataPerCompany = false and is loaded by OnInstallAppPerDatabase.
    [Test]
    procedure Y85_PerDatabase_Rows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('rows', DumpDatabase());
        Observer.Expect('rows', 'A=alpha/1;B=beta/-2;C=/0;');
        Observer.Verify();
    end;

    [Test]
    procedure Y85_Types_Strings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('T1', Strings('T1'));
        Observer.Observe('T2', Strings('T2'));
        Observer.Observe('T3', Strings('T3'));
        Observer.Expect('T1', 'Hello, world|ABC DEF');
        Observer.Expect('T2', 'ä ö ü 日本語 xxxxxxxxxxxxxxxxxxxx|');
        Observer.Expect('T3', '|');
        Observer.Verify();
    end;

    [Test]
    procedure Y85_Types_NumbersAndBoolean()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('T1', Numbers('T1'));
        Observer.Observe('T2', Numbers('T2'));
        Observer.Observe('T3', Numbers('T3'));
        Observer.Expect('T1', '42|9223372036854775807|1234567.891|true');
        Observer.Expect('T2', '-2147483648|-9223372036854775808|-999999999999999.99|false');
        Observer.Expect('T3', '0|0|0|false');
        Observer.Verify();
    end;

    [Test]
    procedure Y85_Types_DateTimeValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('T1', Dates('T1'));
        Observer.Observe('T2', Dates('T2'));
        Observer.Observe('T3', Dates('T3'));
        Observer.Expect('T1', '2022-01-01|12:30:00.123|2022-01-01T12:30:00Z');
        Observer.Expect('T2', '9999-12-31|23:59:59|2999-12-31T23:59:59Z');
        Observer.Expect('T3', '||');
        Observer.Verify();
    end;

    [Test]
    procedure Y85_Types_DurationGuidOptionEnumDateFormulaBlob()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('T1', Others('T1'));
        Observer.Observe('T2', Others('T2'));
        Observer.Observe('T3', Others('T3'));
        Observer.Expect('T1', 'P1DT1H0M0.0S|{11223344-5566-7788-99AA-BBCCDDEEFF00}|2|5|Five|<CM+1D>|3:abc');
        Observer.Expect('T2', '-P0DT0H0M5.0S|{00000000-0000-0000-0000-000000000000}|0|7|Seven Up|1D|0:');
        Observer.Expect('T3', 'P0DT0H0M0.0S|{00000000-0000-0000-0000-000000000000}|0|0|Zero||0:');
        Observer.Verify();
    end;

    // Values are in the order B, A (the primary key), C, "No." (declaration order), Ext; FlowField Fl and the disabled field Dis are not in the file.
    [Test]
    procedure Y85_FieldOrder_KeyFieldsFirstThenDeclarationOrder()
    var
        Row: Record "LT Y85 Pkg Order";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Row.FindSet();
        repeat
            Row.CalcFields(Fl);
            T += 'B=' + Row.B + ' A=' + Row.A + ' C=' + Row.C + ' No=' + Row."No." + ' Ext=' + Format(Row.Ext) + ' Fl=' + Format(Row.Fl) + ' Dis=' + Format(Row.Dis) + ';';
        until Row.Next() = 0;
        Observer.Observe('rows', T);
        Observer.Observe('get A,B', Format(Row.Get('A2', 'B2')));
        Observer.Observe('get B,A', Format(Row.Get('B2', 'A2')));
        Observer.Expect('rows', 'B=B1 A=A1 C=C1 No=N1 Ext=77 Fl=3 Dis=0;B=B2 A=A2 C=C2 No=N2 Ext=-1 Fl=3 Dis=0;');
        Observer.Expect('get A,B', 'Yes');
        Observer.Expect('get B,A', 'No');
        Observer.Verify();
    end;

    // The AutoIncrement key keeps the values of the file; the next insert takes the following number.
    [Test]
    procedure Y85_AutoIncrement_ContinuesAfterLoadedRows()
    var
        Row: Record "LT Y85 Pkg Auto";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Row.FindSet();
        repeat
            T += Format(Row.Id) + '=' + Row.Txt + ';';
        until Row.Next() = 0;
        Observer.Observe('rows', T);
        Row.Init();
        Row.Id := 0;
        Row.Txt := 'new';
        Row.Insert();
        Observer.Observe('new id above loaded', Format(Row.Id > 7));
        Row.Delete();
        Observer.Expect('rows', '5=a;7=b;');
        Observer.Expect('new id above loaded', 'Yes');
        Observer.Verify();
    end;

    // Outside install and upgrade code NavApp.LoadPackageData does nothing: no rows are added and no error is raised (tables 94447 and 94448 have a
    // data file that no install code loaded).
    [Test]
    procedure Y85_Outside_CompanyTable_NothingLoaded()
    var
        Row: Record "LT Y85 Pkg Late";
        Observer: Codeunit "Probe Observer";
    begin
        NavApp.LoadPackageData(Database::"LT Y85 Pkg Late");
        Observer.Observe('count', Format(Row.Count()));
        Observer.Observe('get L1', Format(Row.Get('L1')));
        Observer.Expect('count', '0');
        Observer.Expect('get L1', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Y85_Outside_DatabaseTable_NothingLoaded()
    var
        Row: Record "LT Y85 Pkg Late Database";
        Observer: Codeunit "Probe Observer";
    begin
        NavApp.LoadPackageData(Database::"LT Y85 Pkg Late Database");
        Observer.Observe('count', Format(Row.Count()));
        Observer.Observe('get D1', Format(Row.Get('D1')));
        Observer.Expect('count', '0');
        Observer.Expect('get D1', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Y85_Outside_OtherRowsStay()
    var
        Row: Record "LT Y85 Pkg Late";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Row."No." := 'X';
        Row.Description := 'own';
        Row.Insert();
        NavApp.LoadPackageData(Database::"LT Y85 Pkg Late");
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Row.Description + ';';
            until Row.Next() = 0;
        Row.DeleteAll();
        Observer.Observe('rows', T);
        Observer.Expect('rows', 'X=own;');
        Observer.Verify();
    end;

    // The rows are there: no duplicate key error, nothing changes.
    [Test]
    procedure Y85_Outside_WithRowsPresent_NoErrorNoChange()
    var
        Row: Record "LT Y85 Pkg Company";
        Observer: Codeunit "Probe Observer";
    begin
        NavApp.LoadPackageData(Database::"LT Y85 Pkg Company");
        NavApp.LoadPackageData(Database::"LT Y85 Pkg Company");
        Observer.Observe('rows', DumpCompany(Row));
        Observer.Expect('rows', '0001=test1;0002=test2;');
        Observer.Verify();
    end;
}
