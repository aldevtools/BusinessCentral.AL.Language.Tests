// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: self-contained helper codeunit 73571 (NOT a test codeunit), uses the Temp Blob codeunit like the corpus tests do
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Shared helper of the P130 report probes: runs Report.SaveAs(Xml) into a stream and returns the column lines of every row as `Name=Value` texts and the labels.
// BC versions: 29 (27 and 28 by CI)

codeunit 73571 "LT P130 Dataset"
{
    // Returns '' when saved, else the reason. Rows: one text per <Columns> block, `Name=Value` joined by a space. Labels: `Name=Value` joined by a space.
    procedure Read(ReportId: Integer; var Rows: List of [Text]; var Labels: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Current: Text;
        Rest: Text;
        ColName: Text;
        ColValue: Text;
        Saved: Boolean;
        InRow: Boolean;
    begin
        Clear(Rows);
        Labels := '';
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        Saved := Report.SaveAs(ReportId, '', ReportFormat::Xml, OutS);
        if not Saved then
            exit('not saved: ' + GetLastErrorText());
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Line := Line.Trim();
            if Line = '<Columns>' then begin
                InRow := true;
                Current := '';
            end;
            if Line = '</Columns>' then begin
                InRow := false;
                Rows.Add(Current);
            end;
            if Line.StartsWith('<Column name="') then begin
                Rest := Line.Substring(15);
                ColName := Rest.Substring(1, Rest.IndexOf('"') - 1);
                ColValue := Rest.Substring(Rest.IndexOf('>') + 1);
                ColValue := ColValue.Replace('</Column>', '');
                if InRow then
                    Current += ColName + '=' + ColValue + ' ';
            end;
            if Line.StartsWith('<Label name="') then begin
                Rest := Line.Substring(14);
                ColName := Rest.Substring(1, Rest.IndexOf('"') - 1);
                ColValue := Rest.Substring(Rest.IndexOf('>') + 1);
                ColValue := ColValue.Replace('</Label>', '');
                Labels += ColName + '=' + ColValue + ' ';
            end;
        end;
        exit('');
    end;

    procedure Seed()
    var
        Item: Record "LT P130 Item";
        Line: Record "LT P130 Line";
    begin
        Item.DeleteAll();
        Line.DeleteAll();
        AddItem('A', 'Alpha', 1, 0);
        AddItem('B', 'Beta', 2, 1);
        AddItem('C', 'Gamma', 3, 2);
        AddItem('D', 'Delta', 4, 0);
        AddItem('E', 'Epsilon', 0, 1);
        Line.Id := 1;
        Line.Name := 'line one';
        Line.Insert();
        Line.Id := 2;
        Line.Name := 'line two';
        Line.Insert();
        Line.Id := 3;
        Line.Name := 'line three';
        Line.Insert();
    end;

    local procedure AddItem(No: Code[20]; Name: Text[50]; Qty: Integer; Opt: Integer)
    var
        Item: Record "LT P130 Item";
    begin
        Item."No." := No;
        Item.Name := Name;
        Item.Qty := Qty;
        Item.Opt := Opt;
        Item.Insert();
    end;
}
