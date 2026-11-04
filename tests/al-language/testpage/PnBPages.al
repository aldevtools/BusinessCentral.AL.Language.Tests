// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-pageext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), PnBObjects.al (table 70527, log 70531), self-contained page 70560, page extensions 70570/70571, codeunits 70555/70556
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
//   70555: "Page extensions | Two extensions declaring one page trigger both run, in application order..." (168);
//          "Page extensions | When extensions modify one control, the later one in application order wins, for every property..." (169);
//          "Page extensions | OnBeforeValidate / OnAfterValidate of a modify block run around the control's own OnValidate..." (170);
//          "CurrFieldNo | CurrFieldNo is a property of the record a TestPage write validates..." (202);
//          "SetValue | A DateFormula control reads a formula with or without angle brackets..." (186);
//          "Page controls | a Date control also takes ISO yyyy-mm-dd text..." (162)
//   70556: "Field | Type stores the member position..." (243); "AllObj, AllObjWithCaption | an object of the platform app has the empty package ids..." (246);
//          "Table Metadata, CodeUnit Metadata | DrillDownPageId, PasteIsValid, ReplicateData..." (247)
// BC versions: 29 (27 and 28 by CI)

page 70560 "LT PnB Card"
{
    PageType = Card;
    SourceTable = "LT PnB Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field(Dur; Rec.Dur) { ApplicationArea = All; }
                field(DF; Rec.DF) { ApplicationArea = All; }
                field(Dt; Rec.Dt) { ApplicationArea = All; }
                field(Opt; Rec.Opt) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        LogCu: Codeunit "LT PnB Log 2";
    begin
        LogCu.Add('Base.OnOpenPage');
    end;
}

pageextension 70570 "LT PnB Card Ext1" extends "LT PnB Card"
{
    layout
    {
        modify(Name)
        {
            Caption = 'Ext1 Name';

            trigger OnBeforeValidate()
            var
                LogCu: Codeunit "LT PnB Log 2";
            begin
                LogCu.Add('E1.Name.Before');
            end;

            trigger OnAfterValidate()
            var
                LogCu: Codeunit "LT PnB Log 2";
            begin
                LogCu.Add('E1.Name.After:' + Rec.Name);
            end;
        }
        modify(Amount)
        {
            Editable = false;
            Visible = true;
        }
    }

    trigger OnOpenPage()
    var
        LogCu: Codeunit "LT PnB Log 2";
    begin
        LogCu.Add('E1.OnOpenPage');
    end;
}

pageextension 70571 "LT PnB Card Ext2" extends "LT PnB Card"
{
    layout
    {
        modify(Name)
        {
            Caption = 'Ext2 Name';
        }
        modify(Amount)
        {
            Editable = true;
            Visible = false;
        }
    }

    trigger OnOpenPage()
    var
        LogCu: Codeunit "LT PnB Log 2";
    begin
        LogCu.Add('E2.OnOpenPage');
    end;
}

codeunit 70555 "LT PnB Page Ext"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT PnB Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Insert();
    end;

    [TryFunction]
    local procedure TrySet(var TP: TestPage "LT PnB Card"; What: Text; Txt: Text)
    begin
        case What of
            'DF':
                TP.DF.SetValue(Txt);
            'Dur':
                TP.Dur.SetValue(Txt);
            'Dt':
                TP.Dt.SetValue(Txt);
        end;
    end;

    local procedure SetAndRead(var TP: TestPage "LT PnB Card"; What: Text; Txt: Text): Text
    var
        Shown: Text;
    begin
        if TrySet(TP, What, Txt) then begin
            case What of
                'DF':
                    Shown := TP.DF.Value();
                'Dur':
                    Shown := TP.Dur.Value();
                'Dt':
                    Shown := TP.Dt.Value();
            end;
            exit('ok:' + Shown);
        end;
        exit('error:' + GetLastErrorText());
    end;

    [Test]
    procedure ExtensionTriggers_RunOrder()
    var
        Obs: Codeunit "Probe Observer";
        LogCu: Codeunit "LT PnB Log 2";
        TP: TestPage "LT PnB Card";
    begin
        Seed();
        LogCu.Reset();
        TP.OpenEdit();
        Obs.Observe('openLog', LogCu.Joined());
        TP.Close();
        Obs.Expect('openLog', 'Base.OnOpenPage,E1.OnOpenPage,E2.OnOpenPage');
        Obs.Verify();
    end;

    [Test]
    procedure ModifyValidateTriggers_AroundTableOnValidate()
    var
        Obs: Codeunit "Probe Observer";
        LogCu: Codeunit "LT PnB Log 2";
        TP: TestPage "LT PnB Card";
    begin
        Seed();
        TP.OpenEdit();
        LogCu.Reset();
        TP.Name.SetValue('Zed');
        Obs.Observe('nameValidateLog', LogCu.Joined());
        LogCu.Reset();
        TP.Name.SetValue('Zed');
        Obs.Observe('sameValueLog', LogCu.Joined());
        LogCu.Reset();
        TP.Close();
        Obs.Expect('nameValidateLog', 'Name.OnValidate:2,E1.Name.Before,E1.Name.After:Zed');
        Obs.Expect('sameValueLog', 'Name.OnValidate:2,E1.Name.Before,E1.Name.After:Zed');
        Obs.Verify();
    end;

    [Test]
    procedure CurrFieldNo_PageWriteVersusCode()
    var
        Obs: Codeunit "Probe Observer";
        LogCu: Codeunit "LT PnB Log 2";
        TP: TestPage "LT PnB Card";
        Row: Record "LT PnB Row";
        Other: Record "LT PnB Row";
    begin
        Seed();
        TP.OpenEdit();
        LogCu.Reset();
        TP.Name.SetValue('PageWrite');
        Obs.Observe('pageName', LogCu.Joined());
        TP.Close();
        LogCu.Reset();
        Row.Get(1);
        Row.Validate(Name, 'FromCode');
        Obs.Observe('codeValidateName', LogCu.Joined());
        LogCu.Reset();
        Row.Validate(Amount, 3);
        Obs.Observe('codeValidateAmount', LogCu.Joined());
        LogCu.Reset();
        Row.Name := 'plain';
        Obs.Observe('plainAssignment', LogCu.Joined());
        LogCu.Reset();
        Other.Id := 2;
        Other.Validate(Name, 'Other');
        Obs.Observe('otherRecordValidate', LogCu.Joined());
        Obs.Observe('currFieldNoInCode', Format(Row.Id));
        Obs.Expect('pageName', 'Name.OnValidate:2,E1.Name.Before,E1.Name.After:PageWrite');
        Obs.Expect('codeValidateName', 'Name.OnValidate:0');
        Obs.Expect('codeValidateAmount', 'Amount.OnValidate:0');
        Obs.Expect('plainAssignment', '');
        Obs.Expect('otherRecordValidate', 'Name.OnValidate:0');
        Obs.Expect('currFieldNoInCode', '1');
        Obs.Verify();
    end;

    [Test]
    procedure DateFormulaControl_Spellings()
    var
        Obs: Codeunit "Probe Observer";
        TP: TestPage "LT PnB Card";
    begin
        Seed();
        TP.OpenEdit();
        Obs.Observe('1D', SetAndRead(TP, 'DF', '1D'));
        Obs.Observe('<1D>', SetAndRead(TP, 'DF', '<1D>'));
        Obs.Observe('<1D+1W>', SetAndRead(TP, 'DF', '<1D+1W>'));
        Obs.Observe('CM', SetAndRead(TP, 'DF', 'CM'));
        Obs.Observe('<-CM>', SetAndRead(TP, 'DF', '<-CM>'));
        Obs.Observe('lower1d', SetAndRead(TP, 'DF', '1d'));
        Obs.Observe('1X', SetAndRead(TP, 'DF', '1X'));
        Obs.Observe('1D trailing garbage', SetAndRead(TP, 'DF', '1D xyz'));
        Obs.Observe('empty', SetAndRead(TP, 'DF', ''));
        Obs.Observe('WD1', SetAndRead(TP, 'DF', '<WD1>'));
        TP.Close();
        Obs.Expect('1D', 'ok:1D');
        Obs.Expect('<1D>', 'ok:1D');
        Obs.Expect('<1D+1W>', 'ok:1D+1W');
        Obs.Expect('CM', 'ok:CM');
        Obs.Expect('<-CM>', 'ok:-CM');
        Obs.Expect('lower1d', 'ok:1D');
        Obs.Expect('1X', 'error:Validation error for Field: DF,  Message = ''Your entry of ''1X'' is not an acceptable value for ''DF''. The date formula ''1X'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit. (Select Refresh to discard errors)''');
        Obs.Expect('1D trailing garbage', 'error:Validation error for Field: DF,  Message = ''Your entry of ''1D xyz'' is not an acceptable value for ''DF''. The date formula ''1D XYZ'' must include plus (+) or minus (-). (Select Refresh to discard errors)''');
        Obs.Expect('empty', 'ok:');
        Obs.Expect('WD1', 'ok:WD1');
        Obs.Verify();
    end;

    [Test]
    procedure DurationControl_Spellings()
    var
        Obs: Codeunit "Probe Observer";
        TP: TestPage "LT PnB Card";
    begin
        Seed();
        TP.OpenEdit();
        Obs.Observe('full', SetAndRead(TP, 'Dur', '1 hour 2 minutes 3 seconds'));
        Obs.Observe('negative', SetAndRead(TP, 'Dur', '-1 hour'));
        Obs.Observe('blank', SetAndRead(TP, 'Dur', ''));
        Obs.Observe('millis', SetAndRead(TP, 'Dur', '3600000'));
        Obs.Observe('short', SetAndRead(TP, 'Dur', '1h'));
        Obs.Observe('fractional', SetAndRead(TP, 'Dur', '1.5 hours'));
        Obs.Observe('days', SetAndRead(TP, 'Dur', '2 days'));
        Obs.Observe('colon', SetAndRead(TP, 'Dur', '1:00:00'));
        Obs.Observe('plural', SetAndRead(TP, 'Dur', '2 minutes'));
        Obs.Observe('singular2', SetAndRead(TP, 'Dur', '1 minutes'));
        Obs.Observe('seconds', SetAndRead(TP, 'Dur', '90 seconds'));
        Obs.Observe('garbage', SetAndRead(TP, 'Dur', 'abc'));
        TP.Close();
        Obs.Expect('full', 'ok:1 hour 2 minutes 3 seconds');
        Obs.Expect('negative', 'ok:-1 hour');
        Obs.Expect('blank', 'ok:');
        Obs.Expect('millis', 'ok:150000 days');
        Obs.Expect('short', 'ok:1 hour');
        Obs.Expect('fractional', 'ok:1 hour 30 minutes');
        Obs.Expect('days', 'ok:2 days');
        Obs.Expect('colon', 'error:Validation error for Field: Dur,  Message = ''Your entry of ''1:00:00'' is not an acceptable value for ''Dur''. The value "1:00:00" can''t be evaluated into type Duration. (Select Refresh to discard errors)''');
        Obs.Expect('plural', 'ok:2 minutes');
        Obs.Expect('singular2', 'ok:1 minute');
        Obs.Expect('seconds', 'ok:1 minute 30 seconds');
        Obs.Expect('garbage', 'error:Validation error for Field: Dur,  Message = ''Your entry of ''abc'' is not an acceptable value for ''Dur''. The value "abc" can''t be evaluated into type Duration. (Select Refresh to discard errors)''');
        Obs.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure DateControl_IsoAndShorthands()
    var
        Obs: Codeunit "Probe Observer";
        TP: TestPage "LT PnB Card";
        Orig: Date;
    begin
        Seed();
        Orig := WorkDate();
        WorkDate(20240131D);
        TP.OpenEdit();
        Obs.Observe('iso', SetAndRead(TP, 'Dt', '2024-02-15'));
        Obs.Observe('isoNoPad', SetAndRead(TP, 'Dt', '2024-2-5'));
        Obs.Observe('w', SetAndRead(TP, 'Dt', 'w'));
        Obs.Observe('W', SetAndRead(TP, 'Dt', 'W'));
        Obs.Observe('t', SetAndRead(TP, 'Dt', 't'));
        Obs.Observe('today', SetAndRead(TP, 'Dt', 'today'));
        Obs.Observe('workdate', SetAndRead(TP, 'Dt', 'workdate'));
        Obs.Observe('twoDigit29', SetAndRead(TP, 'Dt', '15.02.29'));
        Obs.Observe('twoDigit30', SetAndRead(TP, 'Dt', '15.02.30'));
        Obs.Observe('garbage', SetAndRead(TP, 'Dt', 'notadate'));
        Obs.Observe('empty', SetAndRead(TP, 'Dt', ''));
        TP.Close();
        WorkDate(Orig);
        Obs.Expect('iso', 'ok:2/15/2024');
        Obs.Expect('isoNoPad', 'error:Validation error for Field: Dt,  Message = ''Your entry of ''2024-2-5'' is not an acceptable value for ''Dt''. The format of the Date ''2024-2-5'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''. (Select Refresh to discard errors)''');
        Obs.Expect('w', 'ok:1/31/2024');
        Obs.Expect('W', 'ok:1/31/2024');
        // 't' and 'today' enter Today, and the demo license allows only November to February (the filter in the error):
        // the result depends on the month the test runs in.
        if Date2DMY(Today(), 2) in [11, 12, 1, 2] then begin
            Obs.Expect('t', StrSubstNo('ok:%1/%2/%3', Date2DMY(Today(), 2), Date2DMY(Today(), 1), Date2DMY(Today(), 3)));
            Obs.Expect('today', StrSubstNo('ok:%1/%2/%3', Date2DMY(Today(), 2), Date2DMY(Today(), 1), Date2DMY(Today(), 3)));
        end else begin
            Obs.Expect('t', 'error:Validation error for Field: Dt,  Message = ''In the current company the date you''ve entered is outside the allowed interval (this is determined by the filter ''??11*|??12*|??01*|??02*'', which is defined by the license file). (Select Refresh to discard errors)''');
            Obs.Expect('today', 'error:Validation error for Field: Dt,  Message = ''In the current company the date you''ve entered is outside the allowed interval (this is determined by the filter ''??11*|??12*|??01*|??02*'', which is defined by the license file). (Select Refresh to discard errors)''');
        end;
        Obs.Expect('workdate', 'ok:1/31/2024');
        Obs.Expect('twoDigit29', 'error:Validation error for Field: Dt,  Message = ''Your entry of ''15.02.29'' is not an acceptable value for ''Dt''. The format of the Date ''15.02.29'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''. (Select Refresh to discard errors)''');
        Obs.Expect('twoDigit30', 'error:Validation error for Field: Dt,  Message = ''Your entry of ''15.02.30'' is not an acceptable value for ''Dt''. The format of the Date ''15.02.30'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''. (Select Refresh to discard errors)''');
        Obs.Expect('garbage', 'error:Validation error for Field: Dt,  Message = ''Your entry of ''notadate'' is not an acceptable value for ''Dt''. The format of the Date ''notadate'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''. (Select Refresh to discard errors)''');
        Obs.Expect('empty', 'ok:');
        Obs.Verify();
    end;
#endif




}

codeunit 70556 "LT PnB Platform Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryColumn(var F: Record Field; Col: Integer; var R: Text)
    begin
        case Col of
            1:
                R := Format(F.Type);
            2:
                R := Format(F.Len);
            3:
                R := Format(F.Class);
            4:
                R := Format(F.Enabled);
            5:
                R := F."Type Name";
            6:
                R := F."Field Caption";
            7:
                R := F.FieldName;
        end;
    end;

    local procedure Column(var F: Record Field; Col: Integer): Text
    var
        R: Text;
    begin
        if TryColumn(F, Col, R) then
            exit(R);
        exit('error:' + GetLastErrorText());
    end;

    [Test]
    procedure FieldTable_TypeColumn()
    var
        Obs: Codeunit "Probe Observer";
        F: Record Field;
        N: Integer;
    begin
        F.SetRange(TableNo, Database::"LT PnB Row");
        F.SetFilter("No.", '<%1', 2000000000);
        Obs.Observe('count', Format(F.Count()));
        if F.FindSet() then begin
            repeat
                N += 1;
                if N <= 10 then begin
                    Obs.Observe('f' + Format(F."No.") + '.name', F.FieldName);
                    Obs.Observe('f' + Format(F."No.") + '.type', Format(F.Type));
                end;
            until F.Next() = 0;
        end;
        Obs.Observe('typeIsInteger', Format(F.Type = F.Type::Integer));
        Obs.Expect('count', '10');
        Obs.Expect('f1.name', 'Id');
        Obs.Expect('f1.type', 'Integer');
        Obs.Expect('f2.name', 'Name');
        Obs.Expect('f2.type', 'Text');
        Obs.Expect('f3.name', 'Amount');
        Obs.Expect('f3.type', 'Decimal');
        Obs.Expect('f4.name', 'Parent Id');
        Obs.Expect('f4.type', 'Integer');
        Obs.Expect('f5.name', 'Opt');
        Obs.Expect('f5.type', 'Option');
        Obs.Expect('f6.name', 'Flag');
        Obs.Expect('f6.type', 'Boolean');
        Obs.Expect('f7.name', 'Dur');
        Obs.Expect('f7.type', 'Duration');
        Obs.Expect('f8.name', 'DF');
        Obs.Expect('f8.type', 'DateFormula');
        Obs.Expect('f9.name', 'Dt');
        Obs.Expect('f9.type', 'Date');
        Obs.Expect('f10.name', 'Gd');
        Obs.Expect('f10.type', 'GUID');
        Obs.Expect('typeIsInteger', 'No');
        Obs.Verify();
    end;

    [Test]
    procedure FieldTable_OtherColumns()
    var
        Obs: Codeunit "Probe Observer";
        F: Record Field;
        i: Integer;
    begin
        F.Get(Database::"LT PnB Row", 2);
        for i := 1 to 7 do begin
            Obs.Observe('name.col' + Format(i), Column(F, i));
        end;
        F.Get(Database::"LT PnB Row", 3);
        for i := 1 to 7 do begin
            Obs.Observe('amount.col' + Format(i), Column(F, i));
        end;
        Obs.Expect('name.col1', 'Text');
        Obs.Expect('name.col2', '30');
        Obs.Expect('name.col3', 'Normal');
        Obs.Expect('name.col4', 'Yes');
        Obs.Expect('name.col5', 'Text30');
        Obs.Expect('name.col6', 'Name');
        Obs.Expect('name.col7', 'Name');
        Obs.Expect('amount.col1', 'Decimal');
        Obs.Expect('amount.col2', '12');
        Obs.Expect('amount.col3', 'Normal');
        Obs.Expect('amount.col4', 'Yes');
        Obs.Expect('amount.col5', 'Decimal');
        Obs.Expect('amount.col6', 'Amount');
        Obs.Expect('amount.col7', 'Amount');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryAllObj(var A: Record AllObj; Col: Integer; var R: Text)
    begin
        case Col of
            1:
                R := Format(IsNullGuid(A."App Package ID"));
            2:
                R := Format(IsNullGuid(A."App Runtime Package ID"));
            3:
                R := A."Object Name";
            5:
                R := A."AL Namespace";
        end;
    end;

    local procedure AllObjCol(var A: Record AllObj; Col: Integer): Text
    var
        R: Text;
    begin
        if TryAllObj(A, Col, R) then
            exit(R);
        exit('error:' + GetLastErrorText());
    end;

    [Test]
    procedure AllObj_OwnAndPlatformObjects()
    var
        Obs: Codeunit "Probe Observer";
        A: Record AllObj;
        i: Integer;
    begin
        A.Get(A."Object Type"::Table, 70527);
        for i := 1 to 5 do begin
            Obs.Observe('own.col' + Format(i), AllObjCol(A, i));
        end;
        A.Get(A."Object Type"::Table, 2000000041);
        for i := 1 to 5 do begin
            Obs.Observe('platform.col' + Format(i), AllObjCol(A, i));
        end;
        A.Get(A."Object Type"::Page, 70560);
        for i := 1 to 5 do begin
            Obs.Observe('page.col' + Format(i), AllObjCol(A, i));
        end;
        Obs.Expect('own.col1', 'No');
        Obs.Expect('own.col2', 'No');
        Obs.Expect('own.col3', 'LT PnB Row');
        Obs.Expect('own.col4', '');
        Obs.Expect('own.col5', '');
        Obs.Expect('platform.col1', 'No');
        Obs.Expect('platform.col2', 'Yes');
        Obs.Expect('platform.col3', 'Field');
        Obs.Expect('platform.col4', '');
        Obs.Expect('platform.col5', 'System.Reflection');
        Obs.Expect('page.col1', 'No');
        Obs.Expect('page.col2', 'No');
        Obs.Expect('page.col3', 'LT PnB Card');
        Obs.Expect('page.col4', '');
        Obs.Expect('page.col5', '');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryMeta(var M: Record "Table Metadata"; Col: Integer; var R: Text)
    begin
        case Col of
            1:
                R := Format(M.DrillDownPageID);
            2:
                R := Format(M.PasteIsValid);
            3:
                R := Format(M.ReplicateData);
            4:
                R := Format(M.LookupPageID);
            5:
                R := Format(M.DataPerCompany);
            6:
                R := Format(M.TableType);
            7:
                R := Format(M.Name);
        end;
    end;

    local procedure MetaCol(var M: Record "Table Metadata"; Col: Integer): Text
    var
        R: Text;
    begin
        if TryMeta(M, Col, R) then
            exit(R);
        exit('error:' + GetLastErrorText());
    end;

    [Test]
    procedure TableMetadata_Columns()
    var
        Obs: Codeunit "Probe Observer";
        M: Record "Table Metadata";
        i: Integer;
    begin
        M.Get(70527);
        for i := 1 to 7 do begin
            Obs.Observe('col' + Format(i), MetaCol(M, i));
        end;
        M.Get(70529);
        for i := 1 to 7 do begin
            Obs.Observe('auto.col' + Format(i), MetaCol(M, i));
        end;
        Obs.Expect('col1', '0');
        Obs.Expect('col2', 'Yes');
        Obs.Expect('col3', 'Yes');
        Obs.Expect('col4', '0');
        Obs.Expect('col5', 'Yes');
        Obs.Expect('col6', 'Normal');
        Obs.Expect('col7', 'LT PnB Row');
        Obs.Expect('auto.col1', '0');
        Obs.Expect('auto.col2', 'Yes');
        Obs.Expect('auto.col3', 'Yes');
        Obs.Expect('auto.col4', '0');
        Obs.Expect('auto.col5', 'Yes');
        Obs.Expect('auto.col6', 'Normal');
        Obs.Expect('auto.col7', 'LT PnB Auto');
        Obs.Verify();
    end;
}
