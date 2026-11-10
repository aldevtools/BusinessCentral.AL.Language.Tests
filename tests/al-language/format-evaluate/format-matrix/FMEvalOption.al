// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on the Evaluate texts of Option. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72859 "LT FM Eval Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Nul(): Text
    var
        C: Char;
        T: Text;
    begin
        C := 0;
        T := '';
        T += C;
        exit(T);
    end;

    [TryFunction]
    local procedure TryEv(Txt: Text; var V: Option " ",Draft,Active)
    begin
        Evaluate(V, Txt);
    end;

    local procedure EvB(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text; N: Integer)
    var
        V: Option " ",Draft,Active;
        Ok: Boolean;
    begin
        V := 2;
        if N = 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, N);
        O.Observe(Name, Format(Ok) + '|' + Format(V, 0, 9) + '/' + Format(V));
    end;

    local procedure EvS(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        V: Option " ",Draft,Active;
    begin
        V := 2;
        ClearLastError();
        if TryEv(Txt, V) then
            O.Observe(Name, 'ok|' + Format(V, 0, 9) + '/' + Format(V))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + '|' + Format(V, 0, 9) + '/' + Format(V));
    end;

    [Test]
    procedure Evaluate_Option_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '|b0', '', 0);
        EvB(O, '|b9', '', 9);
        EvS(O, '|st', '');
        EvB(O, ' |b0', ' ', 0);
        EvB(O, ' |b9', ' ', 9);
        EvS(O, ' |st', ' ');
        EvB(O, 'Draft|b0', 'Draft', 0);
        EvB(O, 'Draft|b9', 'Draft', 9);
        EvS(O, 'Draft|st', 'Draft');
        EvB(O, 'draft|b0', 'draft', 0);
        EvB(O, 'draft|b9', 'draft', 9);
        EvS(O, 'draft|st', 'draft');
        EvB(O, 'DRAFT|b0', 'DRAFT', 0);
        EvB(O, 'DRAFT|b9', 'DRAFT', 9);
        EvS(O, 'DRAFT|st', 'DRAFT');
        EvB(O, 'Active|b0', 'Active', 0);
        EvB(O, 'Active|b9', 'Active', 9);
        EvS(O, 'Active|st', 'Active');
        EvB(O, 'Closed|b0', 'Closed', 0);
        EvB(O, 'Closed|b9', 'Closed', 9);
        EvS(O, 'Closed|st', 'Closed');
        EvB(O, '1|b0', '1', 0);
        EvB(O, '1|b9', '1', 9);
        EvS(O, '1|st', '1');
        EvB(O, '2|b0', '2', 0);
        EvB(O, '2|b9', '2', 9);
        EvS(O, '2|st', '2');
        EvB(O, '3|b0', '3', 0);
        EvB(O, '3|b9', '3', 9);
        EvS(O, '3|st', '3');
        GlobalLanguage(Saved);
        O.Expect('|b0', 'Yes|0/ ');
        O.Expect('|b9', 'Yes|0/ ');
        O.Expect('|st', 'ok|0/ ');
        O.Expect(' |b0', 'Yes|0/ ');
        O.Expect(' |b9', 'Yes|0/ ');
        O.Expect(' |st', 'ok|0/ ');
        O.Expect('Draft|b0', 'Yes|1/Draft');
        O.Expect('Draft|b9', 'Yes|1/Draft');
        O.Expect('Draft|st', 'ok|1/Draft');
        O.Expect('draft|b0', 'Yes|1/Draft');
        O.Expect('draft|b9', 'Yes|1/Draft');
        O.Expect('draft|st', 'ok|1/Draft');
        O.Expect('DRAFT|b0', 'Yes|1/Draft');
        O.Expect('DRAFT|b9', 'Yes|1/Draft');
        O.Expect('DRAFT|st', 'ok|1/Draft');
        O.Expect('Active|b0', 'Yes|2/Active');
        O.Expect('Active|b9', 'Yes|2/Active');
        O.Expect('Active|st', 'ok|2/Active');
        O.Expect('Closed|b0', 'No|2/Active');
        O.Expect('Closed|b9', 'No|2/Active');
        O.Expect('Closed|st', 'err:InvalidOptionString|2/Active');
        O.Expect('1|b0', 'Yes|1/Draft');
        O.Expect('1|b9', 'Yes|1/Draft');
        O.Expect('1|st', 'ok|1/Draft');
        O.Expect('2|b0', 'Yes|2/Active');
        O.Expect('2|b9', 'Yes|2/Active');
        O.Expect('2|st', 'ok|2/Active');
        O.Expect('3|b0', 'Yes|3/3');
        O.Expect('3|b9', 'Yes|3/3');
        O.Expect('3|st', 'ok|3/3');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_Option_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '0|b0', '0', 0);
        EvB(O, '0|b9', '0', 9);
        EvS(O, '0|st', '0');
        EvB(O, '4|b0', '4', 0);
        EvB(O, '4|b9', '4', 9);
        EvS(O, '4|st', '4');
        EvB(O, '-1|b0', '-1', 0);
        EvB(O, '-1|b9', '-1', 9);
        EvS(O, '-1|st', '-1');
        EvB(O, 'abc|b0', 'abc', 0);
        EvB(O, 'abc|b9', 'abc', 9);
        EvS(O, 'abc|st', 'abc');
        EvB(O, 'test123|b0', 'test123', 0);
        EvB(O, 'test123|b9', 'test123', 9);
        EvS(O, 'test123|st', 'test123');
        EvB(O, 'Draft |b0', 'Draft ', 0);
        EvB(O, 'Draft |b9', 'Draft ', 9);
        EvS(O, 'Draft |st', 'Draft ');
        EvB(O, ' Draft|b0', ' Draft', 0);
        EvB(O, ' Draft|b9', ' Draft', 9);
        EvS(O, ' Draft|st', ' Draft');
        EvB(O, ',|b0', ',', 0);
        EvB(O, ',|b9', ',', 9);
        EvS(O, ',|st', ',');
        EvB(O, 'Dra|b0', 'Dra', 0);
        EvB(O, 'Dra|b9', 'Dra', 9);
        EvS(O, 'Dra|st', 'Dra');
        EvB(O, 'Draft,Active|b0', 'Draft,Active', 0);
        EvB(O, 'Draft,Active|b9', 'Draft,Active', 9);
        GlobalLanguage(Saved);
        O.Expect('0|b0', 'Yes|0/ ');
        O.Expect('0|b9', 'Yes|0/ ');
        O.Expect('0|st', 'ok|0/ ');
        O.Expect('4|b0', 'Yes|4/4');
        O.Expect('4|b9', 'Yes|4/4');
        O.Expect('4|st', 'ok|4/4');
        O.Expect('-1|b0', 'No|2/Active');
        O.Expect('-1|b9', 'No|2/Active');
        O.Expect('-1|st', 'err:InvalidOptionString|2/Active');
        O.Expect('abc|b0', 'No|2/Active');
        O.Expect('abc|b9', 'No|2/Active');
        O.Expect('abc|st', 'err:InvalidOptionString|2/Active');
        O.Expect('test123|b0', 'No|2/Active');
        O.Expect('test123|b9', 'No|2/Active');
        O.Expect('test123|st', 'err:InvalidOptionString|2/Active');
        O.Expect('Draft |b0', 'Yes|1/Draft');
        O.Expect('Draft |b9', 'Yes|1/Draft');
        O.Expect('Draft |st', 'ok|1/Draft');
        O.Expect(' Draft|b0', 'Yes|1/Draft');
        O.Expect(' Draft|b9', 'Yes|1/Draft');
        O.Expect(' Draft|st', 'ok|1/Draft');
        O.Expect(',|b0', 'No|2/Active');
        O.Expect(',|b9', 'No|2/Active');
        O.Expect(',|st', 'err:InvalidOptionString|2/Active');
        O.Expect('Dra|b0', 'No|2/Active');
        O.Expect('Dra|b9', 'No|2/Active');
        O.Expect('Dra|st', 'err:InvalidOptionString|2/Active');
        O.Expect('Draft,Active|b0', 'No|2/Active');
        O.Expect('Draft,Active|b9', 'No|2/Active');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_Option_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvS(O, 'Draft,Active|st', 'Draft,Active');
        EvB(O, '1D|b0', '1D', 0);
        EvB(O, '1D|b9', '1D', 9);
        EvS(O, '1D|st', '1D');
        EvB(O, '1T|b0', '1T', 0);
        EvB(O, '1T|b9', '1T', 9);
        EvS(O, '1T|st', '1T');
        EvB(O, 'male|b0', 'male', 0);
        EvB(O, 'male|b9', 'male', 9);
        EvS(O, 'male|st', 'male');
        EvB(O, 'non-binary|b0', 'non-binary', 0);
        EvB(O, 'non-binary|b9', 'non-binary', 9);
        EvS(O, 'non-binary|st', 'non-binary');
        EvB(O, 'nonbinary|b0', 'nonbinary', 0);
        EvB(O, 'nonbinary|b9', 'nonbinary', 9);
        EvS(O, 'nonbinary|st', 'nonbinary');
        EvB(O, 'NUL|b0', Nul(), 0);
        EvB(O, 'NUL|b9', Nul(), 9);
        EvS(O, 'NUL|st', Nul());
        EvB(O, '?|b0', '?', 0);
        EvB(O, '?|b9', '?', 9);
        EvS(O, '?|st', '?');
        GlobalLanguage(Saved);
        O.Expect('Draft,Active|st', 'err:InvalidOptionString|2/Active');
        O.Expect('1D|b0', 'No|2/Active');
        O.Expect('1D|b9', 'No|2/Active');
        O.Expect('1D|st', 'err:InvalidOptionString|2/Active');
        O.Expect('1T|b0', 'No|2/Active');
        O.Expect('1T|b9', 'No|2/Active');
        O.Expect('1T|st', 'err:InvalidOptionString|2/Active');
        O.Expect('male|b0', 'No|2/Active');
        O.Expect('male|b9', 'No|2/Active');
        O.Expect('male|st', 'err:InvalidOptionString|2/Active');
        O.Expect('non-binary|b0', 'No|2/Active');
        O.Expect('non-binary|b9', 'No|2/Active');
        O.Expect('non-binary|st', 'err:InvalidOptionString|2/Active');
        O.Expect('nonbinary|b0', 'No|2/Active');
        O.Expect('nonbinary|b9', 'No|2/Active');
        O.Expect('nonbinary|st', 'err:InvalidOptionString|2/Active');
        O.Expect('NUL|b0', 'Yes|0/ ');
        O.Expect('NUL|b9', 'Yes|0/ ');
        O.Expect('NUL|st', 'ok|0/ ');
        O.Expect('?|b0', 'No|2/Active');
        O.Expect('?|b9', 'No|2/Active');
        O.Expect('?|st', 'err:InvalidOptionString|2/Active');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_Option_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        EvB(O, '|b0', '', 0);
        EvB(O, '|b9', '', 9);
        EvS(O, '|st', '');
        EvB(O, ' |b0', ' ', 0);
        EvB(O, ' |b9', ' ', 9);
        EvS(O, ' |st', ' ');
        EvB(O, 'Draft|b0', 'Draft', 0);
        EvB(O, 'Draft|b9', 'Draft', 9);
        EvS(O, 'Draft|st', 'Draft');
        EvB(O, 'draft|b0', 'draft', 0);
        EvB(O, 'draft|b9', 'draft', 9);
        EvS(O, 'draft|st', 'draft');
        EvB(O, 'DRAFT|b0', 'DRAFT', 0);
        EvB(O, 'DRAFT|b9', 'DRAFT', 9);
        EvS(O, 'DRAFT|st', 'DRAFT');
        EvB(O, 'Active|b0', 'Active', 0);
        EvB(O, 'Active|b9', 'Active', 9);
        EvS(O, 'Active|st', 'Active');
        EvB(O, 'Closed|b0', 'Closed', 0);
        EvB(O, 'Closed|b9', 'Closed', 9);
        EvS(O, 'Closed|st', 'Closed');
        EvB(O, '1|b0', '1', 0);
        EvB(O, '1|b9', '1', 9);
        EvS(O, '1|st', '1');
        GlobalLanguage(Saved);
        O.Expect('|b0', 'Ja|0/ ');
        O.Expect('|b9', 'Ja|0/ ');
        O.Expect('|st', 'ok|0/ ');
        O.Expect(' |b0', 'Ja|0/ ');
        O.Expect(' |b9', 'Ja|0/ ');
        O.Expect(' |st', 'ok|0/ ');
        O.Expect('Draft|b0', 'Ja|1/Draft');
        O.Expect('Draft|b9', 'Ja|1/Draft');
        O.Expect('Draft|st', 'ok|1/Draft');
        O.Expect('draft|b0', 'Ja|1/Draft');
        O.Expect('draft|b9', 'Ja|1/Draft');
        O.Expect('draft|st', 'ok|1/Draft');
        O.Expect('DRAFT|b0', 'Ja|1/Draft');
        O.Expect('DRAFT|b9', 'Ja|1/Draft');
        O.Expect('DRAFT|st', 'ok|1/Draft');
        O.Expect('Active|b0', 'Ja|2/Active');
        O.Expect('Active|b9', 'Ja|2/Active');
        O.Expect('Active|st', 'ok|2/Active');
        O.Expect('Closed|b0', 'Nein|2/Active');
        O.Expect('Closed|b9', 'Nein|2/Active');
        O.Expect('Closed|st', 'err:InvalidOptionString|2/Active');
        O.Expect('1|b0', 'Ja|1/Draft');
        O.Expect('1|b9', 'Ja|1/Draft');
        O.Expect('1|st', 'ok|1/Draft');
        O.Verify();
    end;
}
