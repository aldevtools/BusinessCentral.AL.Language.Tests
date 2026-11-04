// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: tables 73000, 73001 in RfTObjects.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 73010 "LT RfT Helper"
{
    procedure Reset()
    var
        D: Record "LT RfT Data";
        P: Record "LT RfT Parent";
    begin
        D.DeleteAll();
        P.DeleteAll();
    end;

    procedure Seed()
    var
        D: Record "LT RfT Data";
        P: Record "LT RfT Parent";
        i: Integer;
    begin
        Reset();
        for i := 1 to 5 do begin
            P.Init();
            P."No." := 'P' + Format(i);
            P.Description := 'Parent ' + Format(i);
            P.Qty := i;
            P.Amount := i * 10.5;
            P.Insert();
        end;
        for i := 1 to 5 do begin
            D.Init();
            D.Code := 'D' + Format(i);
            D.Txt := 'Text ' + Format(i);
            D.Int := i * 10;
            D.Dec := i * 1.25;
            D.Bool := (i mod 2) = 1;
            D.Dt := DMY2Date(i, 1, 2020);
            D.Opt := (i - 1) mod 3;
            D.Rel := 'P' + Format(i);
            D.Insert();
        end;
    end;
}
