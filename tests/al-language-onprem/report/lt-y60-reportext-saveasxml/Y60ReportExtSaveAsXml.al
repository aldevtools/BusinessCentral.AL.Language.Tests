// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testrequestpage/testrequestpage-saveasxml-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath)
// Fixtures used: Probe Observer (codeunit 69160); own table 98708, enum 98707, reports 98709-98710, report extensions 98706-98707,
//                codeunits 98708-98709 (writer Y60, gap cycle 6 spec G6-10)
// Probe: TestRequestPage.SaveAsXml on the request page of a report (SaveValues = true) that a report extension in the same app extends:
//        the extension adds a column, modifies a data item (OnBeforePreDataItem, OnAfterAfterGetRecord), adds a data item and adds a
//        request page field bound to an Enum global of the extension (addlast(Options)). Observed: the parameters file, the data file,
//        the extension's trigger log, and what the request page shows on the next run (are values closed by SaveAsXml saved?);
//        the same with SaveValues = false. Not repeated: the Report.Run + OK paths of report/lt-y42-* (corpus PR 968).
// BC versions: 27, 28, 29

table 98708 "LT Y60 OP Ext Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

enum 98707 "LT Y60 OP Basis"
{
    Extensible = false;

    value(0; Average) { }
    value(1; Details) { }
}

codeunit 98708 "LT Y60 OP Ext Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 98709 "LT Y60 OP Ext Saved"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Header; "LT Y60 OP Ext Row")
        {
            column(HName; Name) { }
            dataitem(Line; "LT Y60 OP Ext Row")
            {
                DataItemLink = Id = field(Id);
                column(LName; Name) { }
            }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(ShowAll; ShowAll) { ApplicationArea = All; }
                }
            }
        }
    }

    var
        ShowAll: Boolean;
}

report 98710 "LT Y60 OP Ext Unsaved"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Header; "LT Y60 OP Ext Row")
        {
            column(HName; Name) { }
            dataitem(Line; "LT Y60 OP Ext Row")
            {
                DataItemLink = Id = field(Id);
                column(LName; Name) { }
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(ShowAll; ShowAll) { ApplicationArea = All; }
                }
            }
        }
    }

    var
        ShowAll: Boolean;
}

reportextension 98706 "LT Y60 OP Ext Saved X" extends "LT Y60 OP Ext Saved"
{
    dataset
    {
        add(Header)
        {
            column(BasisTxt; Format(Basis)) { }
        }
        modify(Line)
        {
            trigger OnBeforePreDataItem()
            begin
                Log.Add('ext pre basis=' + Format(Basis));
            end;

            trigger OnAfterAfterGetRecord()
            begin
                Log.Add('ext line ' + Format(Line.Id));
            end;
        }
        addlast(Line)
        {
            dataitem(Extra; "LT Y60 OP Ext Row")
            {
                DataItemLink = Id = field(Id);
                column(EName; Name) { }
            }
        }
    }

    requestpage
    {
        layout
        {
            addlast(Options)
            {
                field(BasisCtl; Basis) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "LT Y60 OP Ext Log";
        Basis: Enum "LT Y60 OP Basis";
}

reportextension 98707 "LT Y60 OP Ext Unsaved X" extends "LT Y60 OP Ext Unsaved"
{
    dataset
    {
        add(Header)
        {
            column(BasisTxt; Format(Basis)) { }
        }
        modify(Line)
        {
            trigger OnBeforePreDataItem()
            begin
                Log.Add('ext pre basis=' + Format(Basis));
            end;
        }
    }

    requestpage
    {
        layout
        {
            addlast(Options)
            {
                field(BasisCtl; Basis) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "LT Y60 OP Ext Log";
        Basis: Enum "LT Y60 OP Basis";
}

codeunit 98709 "LT Y60 OP Ext SaveAsXml"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y60 OP Ext Log";
        ParametersFile: Text;
        DataFile: Text;
        Step: Integer;
        Seen: Text;

    local procedure Prepare()
    begin
        Commit();
        ParametersFile := TemporaryPath() + 'lt-y60-ext-params.xml';
        DataFile := TemporaryPath() + 'lt-y60-ext-data.xml';
        if Exists(ParametersFile) then
            Erase(ParametersFile);
        if Exists(DataFile) then
            Erase(DataFile);
    end;

    local procedure Seed()
    var
        Row: Record "LT Y60 OP Ext Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Log.Take();
    end;

    // The file as text, lines joined by |, without the byte order mark.
    local procedure FileText(Name: Text): Text
    var
        SaveFile: File;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        if not Exists(Name) then
            exit('<no file>');
        SaveFile.Open(Name);
        SaveFile.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        SaveFile.Close();
        exit(CopyStr(Result, 4));
    end;

    // The parameter names of the parameters file, without their 32-digit suffix (the values are the user and the run time).
    local procedure ParameterNames(Content: Text): Text
    var
        Line: Text;
        Result: Text;
    begin
        if Content = '<no file>' then
            exit(Content);
        foreach Line in Content.Split('|') do
            if Line.Trim().StartsWith('<Name>') then
                Result += CopyStr(Line.Trim(), 7, StrLen(Line.Trim()) - 6 - 7 - 32) + '|';
        exit(Result);
    end;

    local procedure Columns(Content: Text): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Content.Split('|') do
            if Line.Contains(' type="') then
                Result += Line.Trim().Replace(' minOccurs="0" />', '') + '|';
        exit(Result);
    end;

    local procedure Rows(Content: Text): Text
    var
        Line: Text;
        Result: Text;
        After: Boolean;
    begin
        foreach Line in Content.Split('|') do begin
            if After then
                Result += Line.Trim() + '|';
            if Line.Contains('</xs:schema>') then
                After := true;
        end;
        exit(Result);
    end;

    local procedure RunSaved(var Observer: Codeunit "Probe Observer"; Name: Text; NewStep: Integer)
    var
        Content: Text;
    begin
        Prepare();
        Step := NewStep;
        Seen := '';
        Report.Run(Report::"LT Y60 OP Ext Saved");
        Observer.Observe(Name + ' seen', Seen);
        Observer.Observe(Name + ' parameters', ParameterNames(FileText(ParametersFile)));
        Content := FileText(DataFile);
        Observer.Observe(Name + ' schema', Columns(Content));
        Observer.Observe(Name + ' rows', Rows(Content));
        Observer.Observe(Name + ' log', Log.Take());
    end;

    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure ReportExt_SaveValues_SaveAsXml_ParametersAndData()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RunSaved(Observer, 'set details', 2);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('SavedHandler')]
    procedure ReportExt_SaveValues_SaveAsXml_NextRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RunSaved(Observer, 'first', 2);
        RunSaved(Observer, 'second', 3);
        RunSaved(Observer, 'third', 1);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('UnsavedHandler')]
    procedure ReportExt_NoSaveValues_SaveAsXml_Parameters()
    var
        Observer: Codeunit "Probe Observer";
        Content: Text;
    begin
        Seed();
        Prepare();
        Step := 2;
        Seen := '';
        Report.Run(Report::"LT Y60 OP Ext Unsaved");
        Observer.Observe('first parameters', ParameterNames(FileText(ParametersFile)));
        Content := FileText(DataFile);
        Observer.Observe('first rows', Rows(Content));
        Observer.Observe('first log', Log.Take());
        Prepare();
        Step := 3;
        Report.Run(Report::"LT Y60 OP Ext Unsaved");
        Observer.Observe('second seen', Seen);
        Observer.Finish();
    end;

    // Step 1: SaveAsXml only. Step 2: BasisCtl := Details and ShowAll := true, then SaveAsXml. Step 3: read the controls, then Cancel.
    [RequestPageHandler]
    procedure SavedHandler(var RP: TestRequestPage "LT Y60 OP Ext Saved")
    begin
        case Step of
            1:
                RP.SaveAsXml(ParametersFile, DataFile);
            2:
                begin
                    RP.BasisCtl.SetValue("LT Y60 OP Basis"::Details);
                    RP.ShowAll.SetValue(true);
                    RP.SaveAsXml(ParametersFile, DataFile);
                end;
            3:
                begin
                    Seen := 'basis=' + RP.BasisCtl.Value() + ' showall=' + RP.ShowAll.Value();
                    RP.Cancel().Invoke();
                end;
        end;
    end;

    [RequestPageHandler]
    procedure UnsavedHandler(var RP: TestRequestPage "LT Y60 OP Ext Unsaved")
    begin
        case Step of
            2:
                begin
                    RP.BasisCtl.SetValue("LT Y60 OP Basis"::Details);
                    RP.ShowAll.SetValue(true);
                    RP.SaveAsXml(ParametersFile, DataFile);
                end;
            3:
                begin
                    Seen := 'basis=' + RP.BasisCtl.Value() + ' showall=' + RP.ShowAll.Value();
                    RP.Cancel().Invoke();
                end;
        end;
    end;
}
