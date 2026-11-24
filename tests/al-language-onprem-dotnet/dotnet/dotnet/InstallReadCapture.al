// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: per-company installation reads of identity/configuration, calendar, Feature Key and task capability.
// local object: captures install-only context; calls that might fail run in a write-free TryFunction.
codeunit 99465 "INST Read Capture"
{
    Subtype = Install;
    trigger OnInstallAppPerCompany()
    var
        Kind: Integer;
    begin
        for Kind := 1 to 7 do
            Capture(Kind);
    end;

    local procedure Capture(Kind: Integer)
    var
        Observation: Record "INST Read Observation";
        Value: Text;
        Failure: Text;
    begin
        ClearLastError();
        if not TryRead(Kind, Value) then
            Failure := GetLastErrorText();
        ClearLastError();
        Observation.Company := CopyStr(CompanyName(), 1, 30);
        Observation.Probe := Format(Kind);
        Observation.Result := CopyStr(Value, 1, 250);
        Observation.Failure := CopyStr(Failure, 1, 250);
        if Observation.Insert(false) then;
    end;

    [TryFunction]
    local procedure TryRead(Kind: Integer; var Value: Text)
    var
        GraphUser: Codeunit "Azure AD Graph User";
        Settings: Codeunit "Server Setting";
        Calendar: Record Date;
        Feature: Record "Feature Key";
        SavedDate: Date;
    begin
        case Kind of
            1: Value := Format(GraphUser.IsUserDelegatedAdmin(), 0, 9) + '|' + Format(GraphUser.IsUserDelegatedHelpdesk(), 0, 9);
            2: Value := Format(Settings.GetEnableEntraGroupsOnPrem(), 0, 9);
            3: begin
                Value := Format(DMY2Date(29, 2, 2024), 0, 9) + '|' + Format(Date2DMY(20240229D, 1)) + '|' + Format(Date2DMY(20240229D, 2)) + '|' + Format(Date2DMY(20240229D, 3));
            end;
            4: begin
                Calendar.SetRange("Period Type", Calendar."Period Type"::Date);
                Calendar.SetRange("Period Start", 20240229D);
                if Calendar.FindFirst() then
                    Value := Format(Calendar.Count()) + '|' + Format(Calendar."Period Start", 0, 9);
            end;
            5: begin
                Feature.SetRange(ID, 'SalesPrices');
                if Feature.FindFirst() then
                    Value := Feature.ID + '|' + Format(Feature.Count()) + '|' + Format(Feature.Description <> '', 0, 9);
            end;
            6: Value := Format(TaskScheduler.CanCreateTask(), 0, 9);
            7: begin
                SavedDate := WorkDate();
                WorkDate(20240228D);
                Value := Format(DMY2Date(29), 0, 9) + '|' + Format(DMY2Date(29, 2), 0, 9);
                WorkDate(SavedDate);
            end;
        end;
    end;
}
