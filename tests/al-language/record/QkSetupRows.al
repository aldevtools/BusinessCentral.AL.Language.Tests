// Scope: fixture
// Fixtures used: none; used by test codeunits 78603, 70535, 67755, 84363 and 86504.
// Writer QK (owner decision 2026-10-21: corpus tests must not depend on the demo rows of the corpus database). Writes the setup rows a test
// reads with fixed values, and puts the rows back afterwards (the corpus runner does not promise a rollback between tests or codeunits).
// Not SingleInstance: every test declares its own variable, so the saved rows live in that variable only.
//   - Company Information: Get, or Init and Insert when the row is missing; every field the report dataset header writes gets a fixed value,
//     with an own Country/Region 'LTQK' (Name 'LT QK Land', other fields as Init leaves them) and a 1x1 PNG as Picture.
//   - Accounting Period: own monthly periods 2090-01-01 to 2091-12-01 and the fiscal year start 2092-01-01 (each inserted only when no
//     row has that Starting Date), WorkDate 2091-03-15; Restore deletes only the rows it inserted and puts WorkDate back.
//   - General Ledger Setup: LCY Code 'GBP' and Global Dimension 1 Code 'DEPARTMENT', the values the demo row has. They stay the demo values
//     on purpose: Base Application's codeunits 342 "Currency CaptionClass Mgmt" and 343 "Dimension CaptionClass Mgmt" are SingleInstance
//     and keep the General Ledger Setup row they read first in the session, so another value could show the demo value or the written
//     one depending on which test read a caption first. The Dimension row DEPARTMENT is written with Code Caption 'Department Code' (and
//     the caption of a Dimension Translation row for the session language, when one exists), also the demo value: on BC 29.0 a
//     FieldCaption of '1,1,1' still read 'Department Code' after the Code Caption was changed to another text in the same session
//     (CaptionClassTranslate too), so the session keeps the resolved caption and another value would depend on the run order.

codeunit 86940 "LT QK Setup Rows"
{
    var
        SavedInfo: Record "Company Information";
        SavedPicture: Codeunit "Temp Blob";
        InfoExisted: Boolean;
        CountryInserted: Boolean;
        InfoWritten: Boolean;
        InsertedPeriods: List of [Date];
        SavedWorkDate: Date;
        PeriodsWritten: Boolean;
        SavedGLSetup: Record "General Ledger Setup";
        GLSetupExisted: Boolean;
        SavedDimCaption: Text[80];
        DimExisted: Boolean;
        SavedTransCaption: Text[80];
        TransExisted: Boolean;
        GLSetupWritten: Boolean;

    procedure CountryCode(): Code[10]
    begin
        exit('LTQK');
    end;

    procedure PictureBase64(): Text
    begin
        exit('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
    end;

    procedure WriteCompanyInformation()
    var
        Info: Record "Company Information";
        Country: Record "Country/Region";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
        SavedOutS: OutStream;
        InS: InStream;
    begin
        if not Country.Get(CountryCode()) then begin
            Country.Init();
            Country.Code := CountryCode();
            Country.Name := 'LT QK Land';
            Country.Insert();
            CountryInserted := true;
        end;
        InfoExisted := Info.Get();
        if InfoExisted then begin
            SavedInfo := Info;
            Clear(SavedPicture);
            Info.CalcFields(Picture);
            if Info.Picture.HasValue() then begin
                Info.Picture.CreateInStream(InS);
                SavedPicture.CreateOutStream(SavedOutS);
                CopyStream(SavedOutS, InS);
            end;
        end else begin
            Info.Init();
            Info.Insert();
        end;
        Info.Name := 'LT QK Company';
        Info."Name 2" := '';
        Info.Address := 'QK Street 1';
        Info."Address 2" := 'QK Floor 2';
        Info.City := 'QK Town';
        Info."Post Code" := 'QK-1234';
        Info.County := '';
        Info."Country/Region Code" := CountryCode();
        Info."Phone No." := '0111-222-3333';
        Info."Fax No." := '0111-222-3334';
        Info."E-Mail" := 'qk@example.com';
        Info."Home Page" := 'www.example.com/qk';
        Info."VAT Registration No." := 'QK123456789';
        Info."Registration No." := 'QKREG42';
        Info."Bank Name" := 'LT QK Bank';
        Info."Bank Account No." := '11-22-333';
        Info."Bank Branch No." := 'QKB777';
        Info.IBAN := 'QK 11 BANK 22223333444455';
        Info."SWIFT Code" := 'QKBKXX22';
        Info."Giro No." := '123-4567';
        Clear(Info.Picture);
        Info.Picture.CreateOutStream(OutS);
        Base64.FromBase64(PictureBase64(), OutS);
        Info.Modify();
        InfoWritten := true;
    end;

    procedure RestoreCompanyInformation()
    var
        Info: Record "Company Information";
        Country: Record "Country/Region";
        OutS: OutStream;
        InS: InStream;
    begin
        if not InfoWritten then
            exit;
        InfoWritten := false;
        if Info.Get() then
            if InfoExisted then begin
                Info.TransferFields(SavedInfo, false);
                Clear(Info.Picture);
                if SavedPicture.HasValue() then begin
                    Info.Picture.CreateOutStream(OutS);
                    SavedPicture.CreateInStream(InS);
                    CopyStream(OutS, InS);
                end;
                Info.Modify();
            end else
                Info.Delete();
        if CountryInserted then
            if Country.Get(CountryCode()) then
                Country.Delete();
        CountryInserted := false;
    end;

    procedure PeriodWorkDate(): Date
    begin
        exit(DMY2Date(15, 3, 2091));
    end;

    procedure WriteAccountingPeriods()
    var
        Year: Integer;
        Month: Integer;
    begin
        for Year := 2090 to 2091 do
            for Month := 1 to 12 do
                InsertPeriod(DMY2Date(1, Month, Year), Month = 1);
        InsertPeriod(DMY2Date(1, 1, 2092), true);
        SavedWorkDate := WorkDate();
        WorkDate(PeriodWorkDate());
        PeriodsWritten := true;
    end;

    local procedure InsertPeriod(StartingDate: Date; NewFiscalYear: Boolean)
    var
        Period: Record "Accounting Period";
    begin
        if Period.Get(StartingDate) then
            exit;
        Period.Init();
        Period."Starting Date" := StartingDate;
        Period.Name := CopyStr('QK ' + Format(StartingDate, 0, '<Month,2>-<Year4>'), 1, MaxStrLen(Period.Name));
        Period."New Fiscal Year" := NewFiscalYear;
        Period.Insert();
        InsertedPeriods.Add(StartingDate);
    end;

    procedure RestoreAccountingPeriods()
    var
        Period: Record "Accounting Period";
        StartingDate: Date;
    begin
        if not PeriodsWritten then
            exit;
        PeriodsWritten := false;
        foreach StartingDate in InsertedPeriods do
            if Period.Get(StartingDate) then
                Period.Delete();
        Clear(InsertedPeriods);
        WorkDate(SavedWorkDate);
    end;

    procedure DimCodeCaption(): Text[80]
    begin
        exit('Department Code');
    end;

    procedure WriteGLSetupCaptions()
    var
        GLSetup: Record "General Ledger Setup";
        Dim: Record Dimension;
        DimTrans: Record "Dimension Translation";
    begin
        GLSetupExisted := GLSetup.Get();
        if GLSetupExisted then
            SavedGLSetup := GLSetup
        else begin
            GLSetup.Init();
            GLSetup.Insert();
        end;
        GLSetup."LCY Code" := 'GBP';
        GLSetup."Global Dimension 1 Code" := 'DEPARTMENT';
        GLSetup.Modify();
        DimExisted := Dim.Get('DEPARTMENT');
        if DimExisted then
            SavedDimCaption := Dim."Code Caption"
        else begin
            Dim.Init();
            Dim.Code := 'DEPARTMENT';
            Dim.Name := 'LT QK Department';
            Dim.Insert();
        end;
        Dim."Code Caption" := DimCodeCaption();
        Dim.Modify();
        TransExisted := DimTrans.Get('DEPARTMENT', GlobalLanguage());
        if TransExisted then begin
            SavedTransCaption := DimTrans."Code Caption";
            DimTrans."Code Caption" := DimCodeCaption();
            DimTrans.Modify();
        end;
        GLSetupWritten := true;
    end;

    procedure RestoreGLSetupCaptions()
    var
        GLSetup: Record "General Ledger Setup";
        Dim: Record Dimension;
        DimTrans: Record "Dimension Translation";
    begin
        if not GLSetupWritten then
            exit;
        GLSetupWritten := false;
        if TransExisted then
            if DimTrans.Get('DEPARTMENT', GlobalLanguage()) then begin
                DimTrans."Code Caption" := SavedTransCaption;
                DimTrans.Modify();
            end;
        if Dim.Get('DEPARTMENT') then
            if DimExisted then begin
                Dim."Code Caption" := SavedDimCaption;
                Dim.Modify();
            end else
                Dim.Delete();
        if GLSetup.Get() then
            if GLSetupExisted then begin
                GLSetup."LCY Code" := SavedGLSetup."LCY Code";
                GLSetup."Global Dimension 1 Code" := SavedGLSetup."Global Dimension 1 Code";
                GLSetup.Modify();
            end else
                GLSetup.Delete();
    end;
}
