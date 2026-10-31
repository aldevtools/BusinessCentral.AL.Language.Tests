// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 90648, table 90649
// Probe: written against al-runner issue 6322 (small unpinned shapes); every value asserted below is what the BC service tier produced.
// Facts: GlobalLanguage(0) inside a TryFunction and the language afterwards; Evaluate of a Boolean from a word that is not a Boolean under language 1031 (return value,
//        error text and code); Evaluate into a RecordId whose first key field is an Option, given as caption, name and ordinal; the Windows Language row of language 12297.
// BC versions: 27, 28, 29

table 90649 "LT WC Ledger"
{
    fields
    {
        field(1; "Document Type"; Option) { OptionMembers = " ",Invoice,"Credit Memo"; }
        field(2; "No."; Code[20]) { }
    }
    keys { key(PK; "Document Type", "No.") { Clustered = true; } }
}

codeunit 90648 "LT WC Unpinned Singles"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetGlobalLanguage(LanguageId: Integer)
    begin
        GlobalLanguage(LanguageId);
    end;

    [TryFunction]
    local procedure TryEvaluateBoolean(Txt: Text; var B: Boolean)
    begin
        Evaluate(B, Txt);
    end;

    local procedure EvalRecordId(Txt: Text): Text
    var
        Id: RecordId;
        RecRef: RecordRef;
        Result: Text;
    begin
        if not Evaluate(Id, Txt) then begin
            Result := 'false|' + GetLastErrorText() + '|' + GetLastErrorCode();
            ClearLastError();
            exit(Result);
        end;
        Result := 'true|table=' + Format(Id.TableNo()) + '|text=' + Format(Id);
        if RecRef.Get(Id) then
            Result += '|row=found'
        else
            Result += '|row=missing';
        RecRef.Close();
        exit(Result);
    end;

    [Test]
    procedure WC_GlobalLanguage_Zero_InTryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        Observer.Observe('try zero', Format(TrySetGlobalLanguage(0)));
        Observer.Observe('error', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Observe('language kept', Format(GlobalLanguage() = Saved));
        Observer.Observe('try unknown', Format(TrySetGlobalLanguage(99999)));
        ClearLastError();
        Observer.Observe('language kept after unknown', Format(GlobalLanguage() = Saved));
        GlobalLanguage(Saved);
        Observer.Expect('try zero', 'No');
        Observer.Expect('error', '''0'' is not a valid language code. You must specify a locale identifier (LCID) or code in the format of language-country/region, such as en-US, de-DE, or da-DK.|NotSupportedLanguage');
        Observer.Expect('language kept', 'Yes');
        Observer.Expect('try unknown', 'No');
        Observer.Expect('language kept after unknown', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WC_Evaluate_Boolean_German()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
        B: Boolean;
        Ok: Boolean;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        Ok := TryEvaluateBoolean('vielleicht', B);
        Observer.Observe('vielleicht', Format(Ok));
        Observer.Observe('error code', GetLastErrorCode());
        Observer.Observe('error text', GetLastErrorText());
        ClearLastError();
        asserterror Evaluate(B, 'vielleicht');
        Observer.ObserveError('direct');
        Observer.Observe('Ja', Format(TryEvaluateBoolean('Ja', B)) + '|' + Format(B));
        Observer.Observe('Nein', Format(TryEvaluateBoolean('Nein', B)) + '|' + Format(B));
        Observer.Observe('Yes', Format(TryEvaluateBoolean('Yes', B)) + '|' + Format(B));
        ClearLastError();
        GlobalLanguage(Saved);
        Observer.Expect('vielleicht', 'Nein');
        Observer.Expect('error code', 'Evaluate');
        Observer.Expect('error text', 'Der Wert „vielleicht“ kann nicht in Typ Boolean ausgewertet werden.');
        Observer.Expect('direct|text', 'Der Wert „vielleicht“ kann nicht in Typ Boolean ausgewertet werden.');
        Observer.Expect('direct|code', 'Evaluate');
        Observer.Expect('Ja', 'Ja|Ja');
        Observer.Expect('Nein', 'Ja|Nein');
        Observer.Expect('Yes', 'Nein|Nein');
        Observer.Verify();
    end;

    [Test]
    procedure WC_Evaluate_RecordId_OptionKey()
    var
        Observer: Codeunit "Probe Observer";
        Ledger: Record "LT WC Ledger";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        Ledger.DeleteAll();
        Ledger."Document Type" := Ledger."Document Type"::Invoice;
        Ledger."No." := 'D-001';
        Ledger.Insert();
        Observer.Observe('format', Format(Ledger.RecordId));
        GlobalLanguage(1033);
        Observer.Observe('name', EvalRecordId('LT WC Ledger: Invoice,D-001'));
        Observer.Observe('ordinal', EvalRecordId('LT WC Ledger: 1,D-001'));
        Observer.Observe('caption', EvalRecordId('LT WC Ledger: Credit Memo,D-001'));
        Observer.Observe('blank member', EvalRecordId('LT WC Ledger: ,D-001'));
        Observer.Observe('unknown member', EvalRecordId('LT WC Ledger: Quote,D-001'));
        Observer.Observe('out of range ordinal', EvalRecordId('LT WC Ledger: 9,D-001'));
        GlobalLanguage(1031);
        Observer.Observe('name 1031', EvalRecordId('LT WC Ledger: Invoice,D-001'));
        Observer.Observe('ordinal 1031', EvalRecordId('LT WC Ledger: 1,D-001'));
        GlobalLanguage(Saved);
        Observer.Expect('format', 'LT WC Ledger: Invoice,D-001');
        Observer.Expect('name', 'true|table=90649|text=LT WC Ledger: Invoice,D-001|row=found');
        Observer.Expect('ordinal', 'true|table=90649|text=LT WC Ledger: Invoice,D-001|row=found');
        Observer.Expect('caption', 'true|table=90649|text=LT WC Ledger: Credit Memo,D-001|row=missing');
        Observer.Expect('blank member', 'true|table=90649|text=LT WC Ledger: " ",D-001|row=missing');
        Observer.Expect('unknown member', 'false|''Quote'' is not an option. The existing options are:  ,Invoice,Credit Memo|InvalidOptionString');
        Observer.Expect('out of range ordinal', 'true|table=90649|text=LT WC Ledger: 9,D-001|row=missing');
        Observer.Expect('name 1031', 'true|table=90649|text=LT WC Ledger: Invoice,D-001|row=found');
        Observer.Expect('ordinal 1031', 'true|table=90649|text=LT WC Ledger: Invoice,D-001|row=found');
        Observer.Verify();
    end;

    [Test]
    procedure WC_WindowsLanguage_12297()
    var
        Observer: Codeunit "Probe Observer";
        WindowsLanguage: Record "Windows Language";
    begin
        WindowsLanguage.SetRange("Language ID", 12297);
        Observer.Observe('count', Format(WindowsLanguage.Count()));
        if WindowsLanguage.FindFirst() then begin
            Observer.Observe('name', WindowsLanguage.Name);
            Observer.Observe('abbreviated name', WindowsLanguage."Abbreviated Name");
            Observer.Observe('globally enabled', Format(WindowsLanguage."Globally Enabled"));
            Observer.Observe('stx file exist', Format(WindowsLanguage."STX File Exist"));
        end;
        WindowsLanguage.SetRange("Globally Enabled", true);
        Observer.Observe('count enabled', Format(WindowsLanguage.Count()));
        Observer.Observe('is empty enabled', Format(WindowsLanguage.IsEmpty()));
        Observer.Expect('count', '1');
        Observer.Expect('name', 'English (Zimbabwe)');
        Observer.Expect('abbreviated name', 'ENW');
        Observer.Expect('globally enabled', 'Yes');
        Observer.Expect('stx file exist', 'No');
        Observer.Expect('count enabled', '1');
        Observer.Expect('is empty enabled', 'No');
        Observer.Verify();
    end;
}
