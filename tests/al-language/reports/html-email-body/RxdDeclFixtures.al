// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-layouts
// Scope: in-scope
// Fixtures used: none; used by test codeunits 80043 and 80044 (RxdDeclLayoutTests.al, RxdDeclEmailBodyTests.al)
// Facts: the report, table and helper of the declaration-shape layout probes (al-runner issue 6924).
//   RXD Decl Word: the reporter's report declaration: WordLayout and RDLCLayout with DefaultLayout = Word, no rendering section, no
//   ExcelLayout, no DefaultRenderingLayout, one data item on an own table, no report triggers, no request page.
//   Its Word layout (RxdDeclWord.docx, hand-built) has the static texts 'MARK RXDWORD END', 'RGBA1 rgba(1,2,3,1) END' and
//   'RGB4 rgb(1, 2, 3) END' and a table row bound to RowTxt. RxdDeclRdlc.rdl is hand-built from the compiler's generated file with one
//   text box 'RXDRDLC' in its body.
//   The helper inserts a user-defined Tenant Report Layout row named by a GUID whose docx is the same layout with the static texts
//   'MARK RXDTENANT END' and 'RGBA1 rgba(1,2,3,1) END' (the docx bytes are kept here as Base64), so the output says which layout ran.
// local object: the report's own marked layouts and the dataset table are what the tests check.
// BC versions: 27 - 29

table 80041 "RXD Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 80040 "RXD Decl Word"
{
    WordLayout = './reports/html-email-body/RxdDeclWord.docx';
    RDLCLayout = './reports/html-email-body/RxdDeclRdlc.rdl';
    DefaultLayout = Word;

    dataset
    {
        dataitem(Row; "RXD Row")
        {
            column(RowId; Id) { }
            column(RowTxt; Txt) { }
        }
    }
}

codeunit 80042 "RXD Decl Helper"
{
    procedure TenantGuidName(): Text[250]
    begin
        exit('{5B2E8C41-9D7A-4F36-B1C0-2A6E4D8F9C17}');
    end;

    procedure Rows(N: Integer)
    var
        Row: Record "RXD Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to N do begin
            Row.Init();
            Row.Id := I;
            Row.Txt := 'RXDROW' + Format(I);
            Row.Insert();
        end;
    end;

    procedure Cleanup()
    var
        Selection: Record "Report Layout Selection";
        TenantSelection: Record "Tenant Report Layout Selection";
        TenantLayout: Record "Tenant Report Layout";
    begin
        Selection.SetRange("Report ID", Report::"RXD Decl Word");
        Selection.DeleteAll();
        TenantSelection.SetRange("Report ID", Report::"RXD Decl Word");
        TenantSelection.DeleteAll();
        TenantLayout.SetRange("Report ID", Report::"RXD Decl Word");
        TenantLayout.DeleteAll();
        Selection.ClearTempLayoutSelected();
    end;

    // State: 0 no Report Layout Selection row; 1 RDLC (built-in) of the company; 2 RDLC (built-in) with an empty Company Name;
    // 3 both rows of 1 and 2; 4 Word (built-in) of the company. Custom Report Layout Code stays empty.
    procedure StoreState(State: Integer)
    var
        Selection: Record "Report Layout Selection";
    begin
        case State of
            1:
                StoreRow(CopyStr(CompanyName(), 1, 30), Selection.Type::"RDLC (built-in)");
            2:
                StoreRow('', Selection.Type::"RDLC (built-in)");
            3:
                begin
                    StoreRow(CopyStr(CompanyName(), 1, 30), Selection.Type::"RDLC (built-in)");
                    StoreRow('', Selection.Type::"RDLC (built-in)");
                end;
            4:
                StoreRow(CopyStr(CompanyName(), 1, 30), Selection.Type::"Word (built-in)");
        end;
    end;

    local procedure StoreRow(Company: Text[30]; TypeValue: Integer)
    var
        Selection: Record "Report Layout Selection";
    begin
        Selection.Init();
        Selection."Report ID" := Report::"RXD Decl Word";
        Selection."Company Name" := Company;
        Selection.Type := TypeValue;
        Selection."Custom Report Layout Code" := '';
        Selection.Insert();
    end;

    // A user-defined Word layout of the report in Tenant Report Layout, named by a GUID as the Report Layouts page names a copy.
    procedure InsertTenantLayout()
    var
        TenantLayout: Record "Tenant Report Layout";
        Base64: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64(TenantDocx(), OutS);
        TempBlob.CreateInStream(InS);
        TenantLayout.Init();
        TenantLayout."Report ID" := Report::"RXD Decl Word";
        TenantLayout.Name := TenantGuidName();
        TenantLayout."Layout Format" := TenantLayout."Layout Format"::Word;
        TenantLayout.Description := 'RXD user-defined word layout';
        TenantLayout.Layout.ImportStream(InS, 'RXD user-defined word layout');
        TenantLayout.Insert();
    end;

    // Mode: 0 no temporary selection; 1 SetTempLayoutSelectedName(<GUID name of the tenant layout>, empty App ID);
    // 2 SetTempLayoutSelected('') (the Report Selections call form).
    procedure SetTemp(Mode: Integer)
    var
        Selection: Record "Report Layout Selection";
        NullGuid: Guid;
    begin
        case Mode of
            1:
                Selection.SetTempLayoutSelectedName(TenantGuidName(), NullGuid);
            2:
                Selection.SetTempLayoutSelected('');
        end;
    end;

    procedure TempNameAfter(): Text
    var
        Selection: Record "Report Layout Selection";
    begin
        exit(Selection.GetTempSelectedLayoutName().Replace(TenantGuidName(), '<tenant guid>'));
    end;

    [TryFunction]
    procedure TrySave(Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob"; var Ok: Boolean)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Ok := Report.SaveAs(Report::"RXD Decl Word", '', Fmt, OutS);
    end;

    [TryFunction]
    procedure TrySaveStatement(Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Report.SaveAs(Report::"RXD Decl Word", '', Fmt, OutS);
    end;

    procedure BodyText(var TempBlob: Codeunit "Temp Blob") Body: Text
    var
        InS: InStream;
    begin
        if TempBlob.Length() = 0 then
            exit('');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        InS.Read(Body);
    end;

    // The text of word/document.xml of a saved Word document ('' when the output is empty or has no such part).
    procedure WordDocumentText(var TempBlob: Codeunit "Temp Blob") Content: Text
    var
        DataCompression: Codeunit "Data Compression";
        EntryBlob: Codeunit "Temp Blob";
        Names: List of [Text];
        InS: InStream;
        EntryOut: OutStream;
        EntryIn: InStream;
        Length: Integer;
    begin
        if TempBlob.Length() = 0 then
            exit('');
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(Names);
        if not Names.Contains('word/document.xml') then
            exit('');
        EntryBlob.CreateOutStream(EntryOut);
        DataCompression.ExtractEntry('word/document.xml', EntryOut, Length);
        EntryBlob.CreateInStream(EntryIn, TextEncoding::UTF8);
        EntryIn.Read(Content);
    end;

    procedure Markers(Content: Text) Result: Text
    begin
        if StrPos(Content, 'RXDWORD') > 0 then
            Result += 'word;';
        if StrPos(Content, 'RXDTENANT') > 0 then
            Result += 'tenant;';
        if StrPos(Content, 'RXDRDLC') > 0 then
            Result += 'rdlc;';
        if Result = '' then
            Result := 'none';
    end;

    // The first four bytes of the saved document as numbers ('37 80 68 70' is %PDF, '80 75 3 4' a zip package).
    procedure FirstBytes(var TempBlob: Codeunit "Temp Blob") Result: Text
    var
        InS: InStream;
        B: Byte;
        I: Integer;
    begin
        if TempBlob.Length() = 0 then
            exit('');
        TempBlob.CreateInStream(InS);
        for I := 1 to 4 do
            if not InS.EOS() then begin
                InS.Read(B);
                if Result <> '' then
                    Result += ' ';
                Result += Format(B);
            end;
    end;

    procedure CountOf(Value: Text; Part: Text) N: Integer
    var
        P: Integer;
    begin
        P := StrPos(Value, Part);
        while P > 0 do begin
            N += 1;
            Value := CopyStr(Value, P + StrLen(Part));
            P := StrPos(Value, Part);
        end;
    end;

    local procedure TenantDocx(): Text
    var
        B64: TextBuilder;
    begin
        B64.Append('UEsDBBQAAAAIAGQPbV0/UOPknAMAACoMAAARAAAAd29yZC9kb2N1bWVudC54bWzVVutP3DgQ/1eifGlPAuzsgy4RuxXdBYRaENoigVSdKm/iTaw6tmV7H9xff+PEedCydClf7hQp9nhmfp7xPOzTj9uCB2uqDZNiHEZHOAyoSGTKRDYOV3Z5OAo/Tk43cSqTVUGFDUBemHijknGYW6tihEyS04KYo4IlWhq5tEeJLJBcLllC0UbqFPVwhMuZ0jKhxgD4lIg1MaGHK35Fk4oKYC6lLogFUmeoIPrHSh0CuiKWLRhn9hGw8XENI8FkLWIPcdgY5FTiyiA/1Bp6n30rlZk/gXJHpCkHG6QwOVOtG3+KBsy8Blm/5MS64GETgmjwthjMNNnA0ALuY35aKRW8svxlxAjvEREH0WjsY8LTPWtLCsJEu/EfHU3ncKPh6wB6PwOo7G3BudRypVo09ja0K/GjwRL0VVg+yF3XzNuM+ZoTBRVYJPFVJqQmCw4WQcgCOPXApXXoOs5Cpo9uVO6n3a9sPrFRJAF5pamhek3DyfXZ/HMwf5jdnd+c3dwF5zezUwTCE/fX5V/thTO//HQWBTpbkPfRQe+gfxD9tRPMLrgfbrWf3Acbl77QQIF8VABNVlaGAXJ8k6ewvCZ8HCacEu2EEsmlrqU28ZJx4F703Fdqoaf4l5qlbprBOJW82m2AMe4I1zImtX6o1AlnxNQGzOXGW2VJ9usiayzt4b5fS4kln5hwtwIw4ciWbHtNlAIacqFKC2Hw+J0r9rbI00dBgDKHgqyhYyqprUEQqe8zmvDv9y49RhgPMHrnDmALXT0fhwiA4huydux5qfNQ8Fui7bfo75LXmBoNYwCl0Ichp2ji2rE/isZxmEylsNBonzuWrquDnZhXlhYv49oqRkn19xFL7rshqnMi3ZLXpsTsxH1NlD1+m866Wih1a8QpxnVmQGHFlm7tBYBVlJGcpR0SUn7KQRXmXeWKS7jKScvr');
        B64.Append('DduMa3VrqgVGT7dFjZm7iu9hev7lS/Ck2H6fx3db+2wqt+vdEPf+o9ncmYLhQNU+wfG9nHj/x/hPKjd/bqtdx5CPfNVtUVVaqKqz3aI7ln2r/n37f4BmHz3b7Q00glt3tvBMTufQ4/FwODjBF+U9pbKv/1SVHkUn7i26iSHu0fGoP/JxVNk1cdpWwgsr+oAjJ6NZllun0x84ciGtlUXL5nTZ4eaUpBQawwc8KvuClLZDZitbkj7eLhNckXgPSyHk3/DugnDoTNBbZhMwtH/cXCCVm+W0unxR++6f/AtQSwMEFAAAAAgAZA9tXfyeaJd4AAAAjAAAABAAAABkb2NQcm9wcy9hcHAueG1sPYwxDsMgEAS/gujtIymiCBm7yQPyBQSHjRTuEJwjPz9UKVczs8t2lY/6YuuZyenbbLRCChwz7U6fkqan3tbFV/tuXLFJxq5GQt366vQhUi1ADwcW3+dh0ICJW/EyZtuBU8oBXxzOgiRwN+YBeAlSxDjV/6dWsP4AUEsDBBQAAAAIAGQPbV0vL4einAEAADEFAAARAAAAd29yZC9zZXR0aW5ncy54bWy1VN1umzAUfhXEfQKptmlCTatKW7ROzXaRvoBjDsnRbB90fAhjT78DCU23SRFr1SsM9vdnPvv69qd3yQE4IoVlupjnaQLBUolht0wbqWYf09ub67aIIKLfYqLrQyy8XaZ7kbrIsmj34E2cUw1BJytib0RfeZd5wz+aembJ10Zwiw6ly67y/EN6oiHV4FCcKGYeLVOkSnpIQVWFFk6PEcFTdI+QT2QbD0EGxYzBqQcKcY91HNn8S9l0cj+SHC6FOHg3rmsX+YS4LXH5hJhirwfUTBZi1B/k3WgQw1n43T9ET9pz1T5FHKgUvsiH0XPn7/+P4OovguimJDlOPeCWDXfPY3hb3O8Csdk6WKYaJ1FHaV/LY7X6URNh9fnBdNRIkp2nNsfeJm0RjFfwH11cU6nFUizj9Hw94GA0kFq4');
        B64.Append('pER6qhhLeOxdb6RzsKIgG/wFd6H82kRBpRwq+QoLFx1A6KW/60Y/djWswEjDEN9KraRvJCuH9RqZie9Dqafl7dSwqoBVAY3AunGCTO2w1V/AlHqfvVY4O5crO19/N78BUEsDBBQAAAAIAGQPbV1uiSdSrAQAABQhAAASAAAAY3VzdG9tWG1sL2l0ZW0ueG1s5VrZbhNJFL3P8xWleQdDdqEQlMSEIIUoAhNmnkYe4hiLpB1sh+XngVO3ulz70ul5G0WOu+uee86pW0unu/Pr5z69oO90Szck6CtNaEFLmtGcGnpOf9JTekxP8C0Qaegj2q8QbWjK0Xta0TU9AmoHZy/ogP6gfTqnMZg+ALsA+i0y7/h4RX+xzgXi8ky0ug0UFdsCx8/QNoPSAjlLfK6BfASeH4iN29gSLQ2rDIAz/Eucv4XKkP7BZwLkDY60kwHtoS9PaAufAfSkW4GffTqiY8fna7Bf8/EtVFZtPTRe5dj4NzheAXnF6LGDVOiX6OuKa6ir+xrog0i7QGSIjEEyp8x9zpWaJPh1NK5hcss6Fxizf1HjGVo+8dyJK4a4uHaMr+zi0pm1cQcuJq7u8/jK7gyRI2G3mHELcTkmU2+XzR6lOD7HegzUnTVzXW436iv4ub7OIcZozmt/hFGSY2Vnj9CywhhKhwYp1ljheTF46aOeu6urCY93rSeFrnGkeXOjcYrjG5yd8d75ORgPHRdrhD8mIYO9Fw2qdyPXlzz+gr5N0KtYH0a8Psb4rLBe5O8FztSctmPCigqOS0+57HBVN9jNZ7zrNzy/G2eux+P+XpbnqNMc4Upzl9XUiLSm4fA1j4G7RUxW5YflzW13+5XKyXMPea7eYdaMs0ouLqecYsz7UOPtq+q9Mob1+d5DVe7MRlG3uG5DnM805BUxwZpuoCR3E4XT7YJ9XLW7kuZNZfnsZ5w9xXoa47dE+C2SLUT5PCfWXx5yhU7XO7EdEU5MMqfzUnXQfbnE+U27D/ho');
        B64.Append('lfE3YmO+HusjqWhaYzlvWH2FXfMc3LfYR9UV3bQLJyIZUzkx/mE7D23ccD2LXd4YNsZ5ynu9jOojmW1a4/2Ue/I9V/TAOVM9sqP+SAyqx8Lf5dN7t78Cy3+d/v92pUNU44rvHZb4UVfV9OyvyX0a6YWLFGusADrsSZr3oZ42OnnaqPa00cPTZidPm9WeNnt42urkaava01YPT9udPG1Xe9ru4Wmnk6edak87PTztdvK0W+1pt4envU6e9qo97UWvIA/b2fyeXOCaO2ds6N3EQj07r1bBv8NM68XuVWtZ825O8P0d14t5RF/FBEcfRzTt3FqVUp9dzXK/08x5Ry/5L8QZrpehBxML9ey8WoVSnw2y3N80a97NKZ9N+KnjNDq7NUKsMaF6yNJNtVSJ0EO5IiWNvMMznE2js19HQkWTk+e+xC40Wt+DLNs7f+0svuZUjkhmpVdjjVpfv6Xxq3VfHtXuXvJ96zYK3avfp+59Kt6/0v9djY/4+3PmfkYjcncyIUs31VLFQg/lGpU06hwe0kd+d3RP6olcbOYZdy46PfNy7A/1VV/DuMv6ipa16/pwxHNXvpv7VKysjS3XNWR+mKP6msb81Ve0pFt6TnmEMTmPPqtUkdjzSp1Tx12qhMaV+5xirBuhd/QBDCe4zuRGw6DSNbeZumrXzwuTUz8b0jp5n6/ap/nxtaSj6dXj5tdrlarhK5crkWN3nyvWPS+UyG5vyuXbpjl9C95AyTb9BlUfq+ebJhJmjNo3bfaZyRo57+FMu/qfhEH1fyUc0G9QSwMEFAAAAAgAZA9tXcvT6o86BQAAvCIAABMAAABjdXN0b21YbWwvaXRlbTIueG1s5VpdUxs3FL3P+RWavCcGY4zToWQAQ/EMYRjqkvYp48TG8QR/1DZp8ufbHl1Zu5JWX8vmLcMY7+qee8/Rlfaupd3//j2mt/SN5vRIgr7ShNa0oRktaUG/0kvap9e0h28By4I+oX0M64KmbH2iLT3Q');
        B64.Append('K6C6OHtLJ/SCjumGRoj0Htg10HfwXPHxlv5knlvY5ZnY8S7AqKKtcfwL2mZgWsNng88DkK8Q5ztso51tg5aPwG9YywTfG7RKhVv4jRCzxZYt92exa5mAb8uoMf6P0bI2tG1wfgeFffqAzwTxHnGke9GiHvKwRx18WtAqeyrwd0xndG71cYD4D3w8B+92l0uNVz4m/h2Ot0COGT2ykAp9UejWIzMA+sTTLmDpw6MV9EnHvuEsTwLxtdXPUfqmeW4xfh+R4xlaPvM4+RmrOD+3L15axb014/0KbIyf3Y3jMtszRI6E2VKOWxUXi1Tm245mjpIfH4t6DtTKmLl2bNvqMri+Ls8pxmjJdWOIUZJjZXoP0bLFGEqFJVIUWOFoKfFSR37suqpU5cjVpNA5inTc2Ghc4fgRZ9dc0b5UxkPbRYFwx6QawaxFrexqZOuSx3+jb7L6+vow5OtjxFX4oqjMak6bNmFYBdulpph39ape4H4z4zvGguf3wprrfrtby+Ix8jiHuEutopwaEeYsY7ic58DNYZNZ+W5os9vtfoV84rH7PFdXmDWjKJONizGHIsZ1qPF2WXWt9GHdeH+AVVbmklG32GqrODdSn6+ICa5p+ftBVhOF0+2CdYx3VUnHDXm50a/Ze4rraYT/EuG2yGhVlBvn0vjlIa/QaVGJTYuwbDJy2C+UB92Xe/51peqAi1Yef8E24vuxPpKMZavP5x2zb1E1bxB7jjqq7uhlu7AsMmLIxxe/v5uHJq5fzGI7rg/ri3nFtV5a9ZH0Llv9/ZQ1+YkzemKdqR6ZVnckWtlj4Vb5cO12r8D0r9OfryqdIhtjXjvIdcd1sQbxj3CO776nFzZSFFgBdLUn4bjP1dSupamdrandQNNBLU0H2ZoOGmjq1NLUydbUaaDpsJamw2xNhw00dWtp6mZr6jbQdFRL01G2pqMGmnq1NPWyNfW8d5DnVTa3J7e45y4ZW9Ve2qp8pl8ug7vCDPP51qq5UeNq');
        B64.Append('LvH9DfeLpYdf2QRbX3s4Td9cllSfbc50v8OR44ou+BfiDPfLqobSVuUz/XIZUn0uken+hqPG1Vzx2YR3LKfe2a0RosBU2atR6rGmMlHVkM5IiiOu8BpnU+/s15YqY+kTj32PKjQs1iCb3cpfK/Nfc8pHBL3CV2MOW1O9qfHLVZ8e1fpa4n2rNwr1s98k700y3jzTPy7HZ/z9JbKe0YjYSqYapR5rKmNVDekcpTjyFJ7SJ37u9ERqR84380p1Njo882LRn6srP4d+lfkZTXPn9eGM5658rvc5mVkTm85rNfLzFOXn1KcvP6Mp3tQ+5RnG5Ma7V6ksvv1K7ZMXO5UJjUv3ORQxb4R+p/eIcIn7TGw0SlQ452akutz586L0yZ8NYZ64zt92u/n+a0lbw1eP7Z/PlcqGy5zORCy6va+Yt18okfWelMsnSEv8PbJlxevelmG9g+0fkusA+UzPfXoi3yfo7zQMeI90zm8x2Gj5zEAi29TF+rhNe1i5v6FD2jee8JtsA97fDzOes165T7yIsO2D6w0zdphtj9+eEIVeM+KA1FsMU953fslP/7QStaurz3x6h/x8sbniA+Slh78jKO2y+pBe/UyzVDosnoaa5+a8UO3q3ZFW9tsjJ/Q/UEsDBBQAAAAAAGQPbV1b5XUDywEAAMsBAAALAAAAX3JlbHMvLnJlbHPvu788P3htbCB2ZXJzaW9uPSIxLjAiIGVuY29kaW5nPSJ1dGYtOCI/PjxSZWxhdGlvbnNoaXBzIHhtbG5zPSJodHRwOi8vc2NoZW1hcy5vcGVueG1sZm9ybWF0cy5vcmcvcGFja2FnZS8yMDA2L3JlbGF0aW9uc2hpcHMiPjxSZWxhdGlvbnNoaXAgVHlwZT0iaHR0cDovL3NjaGVtYXMub3BlbnhtbGZvcm1hdHMub3JnL29mZmljZURvY3VtZW50LzIwMDYvcmVsYXRpb25zaGlwcy9vZmZpY2VEb2N1bWVudCIgVGFy');
        B64.Append('Z2V0PSIvd29yZC9kb2N1bWVudC54bWwiIElkPSJSNTMzZDUyMWY5ZTNlNGEyYiIgLz48UmVsYXRpb25zaGlwIFR5cGU9Imh0dHA6Ly9zY2hlbWFzLm9wZW54bWxmb3JtYXRzLm9yZy9vZmZpY2VEb2N1bWVudC8yMDA2L3JlbGF0aW9uc2hpcHMvZXh0ZW5kZWQtcHJvcGVydGllcyIgVGFyZ2V0PSIvZG9jUHJvcHMvYXBwLnhtbCIgSWQ9IlI1YWYyMmJkZTYwZGI0NDRlIiAvPjwvUmVsYXRpb25zaGlwcz5QSwMEFAAAAAgAZA9tXQqrccXtAAAAVwIAABwAAAB3b3JkL19yZWxzL2RvY3VtZW50LnhtbC5yZWxzxZK/TsMwEIdfxfJOnKRWHFDTLiysVQdW/zknUWs7si/QPhsDj8QrYBiiVGJgQYz3u7vvvuE+3t63+4s7kxeIaQy+o1VRUgJeBzP6vqMz2ruW7nfbA5wl5ok0jFMiecWnjg6I0wNjSQ/gZCrCBD53bIhOYi5jzyapT7IHVpdlw+KaQW+Z5Hid4DfEYO2o4THo2YHHH8AsAWKWT5QcZewBO8peQzRLXmQiJU+mo4e24q3SQhlhG14ZSQn7My09Jwzu+ev24rVkbERwK7Gm1WZTb5SSyvBaif8Vq1dmSt1zIaQtZSm4bPm3Gbt5j90nUEsDBBQAAAAIAGQPbV06WgTEGAEAAO4CAAATAAAAW0NvbnRlbnRfVHlwZXNdLnhtbKWSv07DMBDGXyXyihKHDgihpB2AFTowsFr2JbHwP/kupTwbA4/EK3BJoQOgUtTRvrvv992ne399a1Zb74oNZLQxtOK8qkUBQUdjQ9+KkbryUqyWzcNLAiy4NWArBqJ0JSXqAbzCKiYIXOli9or4mXuZlH5SPchFXV9IHQNBoJImDbFsbqBTo6PidsvfOyyPi+J61zehWqFSclYr4rLcBPMNUsausxpM1KPnkeo5ZpNy1IDI');
        B64.Append('vr2r9hWvbDib5eWv5AwO/4f+3K3iybkHB5twj7jnKLM1UKxVpjvlWU+ymXWOCSUrV6euCpN3A6bkfRNksnAYPkUjEYg4GDyZ/iPoL+WDHvSIFP2jd9IS+D9MHC+0OFJJzte7/ABQSwECFAMUAAAACABkD21dP1Dj5JwDAAAqDAAAEQAAAAAAAAAAAAAApIEAAAAAd29yZC9kb2N1bWVudC54bWxQSwECFAMUAAAACABkD21d/J5ol3gAAACMAAAAEAAAAAAAAAAAAAAApIHLAwAAZG9jUHJvcHMvYXBwLnhtbFBLAQIUAxQAAAAIAGQPbV0vL4einAEAADEFAAARAAAAAAAAAAAAAACkgXEEAAB3b3JkL3NldHRpbmdzLnhtbFBLAQIUAxQAAAAIAGQPbV1uiSdSrAQAABQhAAASAAAAAAAAAAAAAACkgTwGAABjdXN0b21YbWwvaXRlbS54bWxQSwECFAMUAAAACABkD21dy9PqjzoFAAC8IgAAEwAAAAAAAAAAAAAApIEYCwAAY3VzdG9tWG1sL2l0ZW0yLnhtbFBLAQIUAxQAAAAAAGQPbV1b5XUDywEAAMsBAAALAAAAAAAAAAAAAACkgYMQAABfcmVscy8ucmVsc1BLAQIUAxQAAAAIAGQPbV0Kq3HF7QAAAFcCAAAcAAAAAAAAAAAAAACkgXcSAAB3b3JkL19yZWxzL2RvY3VtZW50LnhtbC5yZWxzUEsBAhQDFAAAAAgAZA9tXTpaBMQYAQAA7gIAABMAAAAAAAAAAAAAAKSBnhMAAFtDb250ZW50X1R5cGVzXS54bWxQSwUGAAAAAAgACAABAgAA5xQAAAAA');
        exit(B64.ToText());
    end;
}
