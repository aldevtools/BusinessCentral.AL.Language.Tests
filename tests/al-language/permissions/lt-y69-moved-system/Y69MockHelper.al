// Helper of the Y69 mock tests (writer Y69; needs Permissions Mock, so it is not part of the SaaS slices). No state.
codeunit 93736 "LT Y69 Mock Helper"
{
    var
        Helper: Codeunit "LT Y69 Helper";
        Mock: Codeunit "Permissions Mock";

    // The four operations (read, insert, modify, delete of the seeded row 'LTY69') on a table under one set as four characters:
    // o = worked, D = a permission error, ! = another error. Every operation starts from a fresh seed (the asserterror of the one before rolled it back).
    procedure FourOps(SetName: Code[20]; TableId: Integer): Text
    var
        Kind: Integer;
        Result: Text;
    begin
        for Kind := 1 to 4 do begin
            Prepare(SetName);
            asserterror Helper.Op(Kind, TableId);
            if GetLastErrorText() = 'LT Y69 ok' then
                Result += 'o'
            else
                if GetLastErrorText().StartsWith('Sorry, the current permissions prevented the action.') then
                    Result += 'D'
                else
                    Result += '!';
            ClearLastError();
        end;
        Mock.ClearAssignments();
        exit(Result);
    end;

    // The error text and code of one operation under one set.
    procedure ErrorOf(SetName: Code[20]; Kind: Integer; TableId: Integer): Text
    begin
        Prepare(SetName);
        asserterror Helper.Op(Kind, TableId);
        exit(GetLastErrorText() + ' | ' + GetLastErrorCode());
    end;

    local procedure Prepare(SetName: Code[20])
    begin
        Mock.ClearAssignments();
        Helper.SeedMoved();
        ClearLastError();
        Mock.Set(SetName);
    end;
}
