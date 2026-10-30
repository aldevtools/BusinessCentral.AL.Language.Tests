// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 90821, 90825, 90826 and codeunit 90822
// Probe: Evaluate into an Option where the earlier probes (errors/lt-ms-refusals-131/P131EvalOption.al, errors/lt-ms-refusals-137/P137OptionEvaluate.al,
//   types/lt-wc/WcUnpinnedSingles.al) leave gaps.
// Facts: a caption that is the name of another member (which wins); two members with the same caption; captions with blanks around them; a member name
//   with a space; blanks, a TAB and a line break around the text; a prefix; OptionCaptionML under GlobalLanguage 1033, 1031 (a DEU caption) and 1036 (no
//   caption for it); the format number 9 and 2 (field and variable); a failed Evaluate with the result unused, with number 9 and with a TAB; Evaluate into
//   a RecordId whose Option key field has an OptionCaption, and, without one, a name in another case, blanks, an empty quoted value, ordinals at and past
//   the Integer range.
// BC versions: 27 - 29

table 90821 "LT Option Eval Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Swap; Option)
        {
            OptionMembers = A,B,C;
            OptionCaption = 'B,C,A';
        }
        field(3; Dup; Option)
        {
            OptionMembers = X,Y,Z;
            OptionCaption = 'Same,Same,Other';
        }
        field(4; ML; Option)
        {
            OptionMembers = Red,Green,Blue;
            OptionCaptionML = ENU = 'Red one,Green one,Blue one', DEU = 'Rot,Gruen,Blau';
        }
        field(5; Sp; Option)
        {
            OptionMembers = " ",Open,"Closed Now";
            OptionCaption = ' ,Open cap,Closed Now cap';
        }
        field(6; Lead; Option)
        {
            OptionMembers = P,Q;
            OptionCaption = ' P cap,Q cap ';
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 90825 "LT Option Key Cap"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc Type"; Option)
        {
            OptionMembers = " ",Invoice,"Credit Memo";
            OptionCaption = ' ,Inv cap,Credit Memo cap';
        }
        field(2; "No."; Code[20]) { }
    }

    keys { key(PK; "Doc Type", "No.") { Clustered = true; } }
}

table 90826 "LT Option Key Plain"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc Type"; Option) { OptionMembers = " ",Invoice,"Credit Memo"; }
        field(2; "No."; Code[20]) { }
    }

    keys { key(PK; "Doc Type", "No.") { Clustered = true; } }
}

codeunit 90822 "LT Option Evaluate Captions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Evaluate into one field of a fresh row (every field starts at ordinal 0): result, ordinal, Format of the field.
    local procedure E(Which: Text; Txt: Text): Text
    begin
        exit(EN(Which, Txt, 0));
    end;

    local procedure EN(Which: Text; Txt: Text; Num: Integer): Text
    var
        Row: Record "LT Option Eval Row";
        Ok: Boolean;
        Ord: Integer;
        Shown: Text;
    begin
        case Which of
            'Swap':
                begin
                    Ok := Evaluate(Row.Swap, Txt, Num);
                    Ord := Row.Swap;
                    Shown := Format(Row.Swap);
                end;
            'Dup':
                begin
                    Ok := Evaluate(Row.Dup, Txt, Num);
                    Ord := Row.Dup;
                    Shown := Format(Row.Dup);
                end;
            'ML':
                begin
                    Ok := Evaluate(Row.ML, Txt, Num);
                    Ord := Row.ML;
                    Shown := Format(Row.ML);
                end;
            'Sp':
                begin
                    Ok := Evaluate(Row.Sp, Txt, Num);
                    Ord := Row.Sp;
                    Shown := Format(Row.Sp);
                end;
            'Lead':
                begin
                    Ok := Evaluate(Row.Lead, Txt, Num);
                    Ord := Row.Lead;
                    Shown := Format(Row.Lead);
                end;
        end;
        ClearLastError();
        // Yes/No written out: Format(Boolean) follows the language, and CaptionML_ByLanguage runs under 1031 and 1036.
        if Ok then
            exit('Yes|' + Format(Ord) + '|[' + Shown + ']');
        exit('No|' + Format(Ord) + '|[' + Shown + ']');
    end;

    local procedure Tab(): Text
    var
        C: Char;
        T: Text;
    begin
        C := 9;
        T[1] := C;
        exit(T);
    end;

    local procedure CrLf(): Text
    var
        C: Char;
        L: Char;
        T: Text;
    begin
        C := 13;
        L := 10;
        T[1] := C;
        T[2] := L;
        exit(T);
    end;

    [Test]
    procedure CaptionIsNameOfAnotherMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('A', E('Swap', 'A'));
        Observer.Observe('B', E('Swap', 'B'));
        Observer.Observe('C', E('Swap', 'C'));
        Observer.Observe('b', E('Swap', 'b'));
        Observer.Observe('0', E('Swap', '0'));
        Observer.Expect('A', 'Yes|2|[A]');
        Observer.Expect('B', 'Yes|0|[B]');
        Observer.Expect('C', 'Yes|1|[C]');
        Observer.Expect('b', 'Yes|0|[B]');
        Observer.Expect('0', 'Yes|0|[B]');
        Observer.Verify();
    end;

    [Test]
    procedure SameCaptionTwice()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Same', E('Dup', 'Same'));
        Observer.Observe('Other', E('Dup', 'Other'));
        Observer.Observe('Y', E('Dup', 'Y'));
        Observer.Observe('1', E('Dup', '1'));
        Observer.Expect('Same', 'Yes|0|[Same]');
        Observer.Expect('Other', 'Yes|2|[Other]');
        Observer.Expect('Y', 'Yes|1|[Same]');
        Observer.Expect('1', 'Yes|1|[Same]');
        Observer.Verify();
    end;

    [Test]
    procedure BlanksAndPrefixes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('name with space', E('Sp', 'Closed Now'));
        Observer.Observe('name double space', E('Sp', 'Closed  Now'));
        Observer.Observe('caption upper', E('Sp', 'OPEN CAP'));
        Observer.Observe('caption padded', E('Sp', '  Open cap  '));
        Observer.Observe('tab before', E('Sp', Tab() + 'Open'));
        Observer.Observe('tab after caption', E('Sp', 'Open cap' + Tab()));
        Observer.Observe('crlf after', E('Sp', 'Open' + CrLf()));
        Observer.Observe('tab only', E('Sp', Tab()));
        Observer.Observe('prefix of name', E('Sp', 'Ope'));
        Observer.Observe('prefix of caption', E('Sp', 'Closed Now c'));
        Observer.Observe('lead caption exact', E('Lead', ' P cap'));
        Observer.Observe('lead caption trimmed', E('Lead', 'P cap'));
        Observer.Observe('trail caption exact', E('Lead', 'Q cap '));
        Observer.Observe('trail caption trimmed', E('Lead', 'Q cap'));
        Observer.Observe('format lead', EN('Lead', 'Q', 0));
        Observer.Expect('name with space', 'Yes|2|[Closed Now cap]');
        Observer.Expect('name double space', 'No|0|[ ]');
        Observer.Expect('caption upper', 'Yes|1|[Open cap]');
        Observer.Expect('caption padded', 'Yes|1|[Open cap]');
        Observer.Expect('tab before', 'Yes|1|[Open cap]');
        Observer.Expect('tab after caption', 'Yes|1|[Open cap]');
        Observer.Expect('crlf after', 'Yes|1|[Open cap]');
        Observer.Expect('tab only', 'Yes|0|[ ]');
        Observer.Expect('prefix of name', 'No|0|[ ]');
        Observer.Expect('prefix of caption', 'No|0|[ ]');
        Observer.Expect('lead caption exact', 'Yes|0|[ P cap]');
        Observer.Expect('lead caption trimmed', 'Yes|0|[ P cap]');
        Observer.Expect('trail caption exact', 'Yes|1|[Q cap ]');
        Observer.Expect('trail caption trimmed', 'Yes|1|[Q cap ]');
        Observer.Expect('format lead', 'Yes|1|[Q cap ]');
        Observer.Verify();
    end;

    [Test]
    procedure CaptionML_ByLanguage()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Observer.Observe('1033 Red one', E('ML', 'Red one'));
        Observer.Observe('1033 Green', E('ML', 'Green'));
        Observer.Observe('1033 Gruen', E('ML', 'Gruen'));
        Observer.Observe('1033 2', E('ML', '2'));
        GlobalLanguage(1031);
        Observer.Observe('1031 Gruen', E('ML', 'Gruen'));
        Observer.Observe('1031 gruen', E('ML', 'gruen'));
        Observer.Observe('1031 Green one', E('ML', 'Green one'));
        Observer.Observe('1031 Green', E('ML', 'Green'));
        Observer.Observe('1031 2', E('ML', '2'));
        GlobalLanguage(1036);
        Observer.Observe('1036 Green one', E('ML', 'Green one'));
        Observer.Observe('1036 Gruen', E('ML', 'Gruen'));
        Observer.Observe('1036 Green', E('ML', 'Green'));
        GlobalLanguage(Saved);
        Observer.Expect('1033 Red one', 'Yes|0|[Red one]');
        Observer.Expect('1033 Green', 'Yes|1|[Green one]');
        Observer.Expect('1033 Gruen', 'No|0|[Red one]');
        Observer.Expect('1033 2', 'Yes|2|[Blue one]');
        Observer.Expect('1031 Gruen', 'Yes|1|[Gruen]');
        Observer.Expect('1031 gruen', 'Yes|1|[Gruen]');
        Observer.Expect('1031 Green one', 'No|0|[Rot]');
        Observer.Expect('1031 Green', 'Yes|1|[Gruen]');
        Observer.Expect('1031 2', 'Yes|2|[Blau]');
        Observer.Expect('1036 Green one', 'Yes|1|[Green one]');
        Observer.Expect('1036 Gruen', 'No|0|[Red one]');
        Observer.Expect('1036 Green', 'Yes|1|[Green one]');
        Observer.Verify();
    end;

    [Test]
    procedure FormatNumber()
    var
        Observer: Codeunit "Probe Observer";
        V: Option Alpha,Beta,Gamma;
        Ok: Boolean;
    begin
        Observer.Observe('9 name', EN('Sp', 'Open', 9));
        Observer.Observe('9 caption', EN('Sp', 'Open cap', 9));
        Observer.Observe('9 ordinal', EN('Sp', '2', 9));
        Observer.Observe('9 unknown', EN('Sp', 'Nope', 9));
        Observer.Observe('2 caption', EN('Sp', 'Open cap', 2));
        Observer.Observe('2 ordinal', EN('Sp', '2', 2));
        Ok := Evaluate(V, 'Beta', 9);
        Observer.Observe('var 9 name', Format(Ok) + '|' + Format(V));
        Ok := Evaluate(V, '2', 9);
        Observer.Observe('var 9 ordinal', Format(Ok) + '|' + Format(V));
        Ok := Evaluate(V, 'gamma', 2);
        Observer.Observe('var 2 lower', Format(Ok) + '|' + Format(V));
        Observer.Expect('9 name', 'Yes|1|[Open cap]');
        Observer.Expect('9 caption', 'Yes|1|[Open cap]');
        Observer.Expect('9 ordinal', 'Yes|2|[Closed Now cap]');
        Observer.Expect('9 unknown', 'No|0|[ ]');
        Observer.Expect('2 caption', 'Yes|1|[Open cap]');
        Observer.Expect('2 ordinal', 'Yes|2|[Closed Now cap]');
        Observer.Expect('var 9 name', 'Yes|Beta');
        Observer.Expect('var 9 ordinal', 'Yes|Gamma');
        Observer.Expect('var 2 lower', 'Yes|Gamma');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryUnused(Which: Text; Txt: Text; Num: Integer)
    var
        Row: Record "LT Option Eval Row";
        V: Option Alpha,Beta,Gamma;
    begin
        case Which of
            'Sp':
                Evaluate(Row.Sp, Txt, Num);
            'Swap':
                Evaluate(Row.Swap, Txt, Num);
            'ML':
                Evaluate(Row.ML, Txt, Num);
            'Var':
                Evaluate(V, Txt, Num);
        end;
    end;

    local procedure U(Which: Text; Txt: Text; Num: Integer): Text
    var
        T: Text;
    begin
        if TryUnused(Which, Txt, Num) then
            exit('no error');
        T := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(T);
    end;

    [Test]
    procedure ResultUnused_Errors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('field 9 unknown', U('Sp', 'Nope', 9));
        Observer.Observe('field tab only', U('Sp', Tab(), 0));
        Observer.Observe('field tab name', U('Sp', Tab() + 'Open', 0));
        Observer.Observe('swap unknown', U('Swap', 'D', 0));
        Observer.Observe('ml unknown', U('ML', 'Purple', 0));
        Observer.Observe('var unknown', U('Var', 'Delta', 0));
        Observer.Observe('var tab', U('Var', Tab(), 0));
        Observer.Observe('var 9 unknown', U('Var', 'Delta', 9));
        Observer.Expect('field 9 unknown', 'error:''Nope'' is not an option. The existing options are:  ,Open cap,Closed Now cap|InvalidOptionString');
        Observer.Expect('field tab only', 'no error');
        Observer.Expect('field tab name', 'no error');
        Observer.Expect('swap unknown', 'error:''D'' is not an option. The existing options are: B,C,A|InvalidOptionString');
        Observer.Expect('ml unknown', 'error:''Purple'' is not an option. The existing options are: Red one,Green one,Blue one|InvalidOptionString');
        Observer.Expect('var unknown', 'error:''Delta'' is not an option. The existing options are: Alpha,Beta,Gamma|InvalidOptionString');
        Observer.Expect('var tab', 'error:''\t'' is not an option. The existing options are: Alpha,Beta,Gamma|InvalidOptionString');
        Observer.Expect('var 9 unknown', 'error:''Delta'' is not an option. The existing options are: Alpha,Beta,Gamma|InvalidOptionString');
        Observer.Verify();
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
        Result := 'true|text=' + Format(Id);
        if RecRef.Get(Id) then
            Result += '|row=found'
        else
            Result += '|row=missing';
        RecRef.Close();
        exit(Result);
    end;

    [Test]
    procedure RecordId_OptionKeyWithCaption()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT Option Key Cap";
    begin
        K.DeleteAll();
        K."Doc Type" := K."Doc Type"::"Credit Memo";
        K."No." := 'D-1';
        K.Insert();
        Observer.Observe('format', Format(K.RecordId));
        Observer.Observe('name', EvalRecordId('LT Option Key Cap: Credit Memo,D-1'));
        Observer.Observe('caption', EvalRecordId('LT Option Key Cap: Credit Memo cap,D-1'));
        Observer.Observe('caption other', EvalRecordId('LT Option Key Cap: Inv cap,D-1'));
        Observer.Observe('ordinal', EvalRecordId('LT Option Key Cap: 2,D-1'));
        Observer.Observe('unknown', EvalRecordId('LT Option Key Cap: Quote,D-1'));
        Observer.Expect('format', 'LT Option Key Cap: Credit Memo cap,D-1');
        Observer.Expect('name', 'true|text=LT Option Key Cap: Credit Memo cap,D-1|row=found');
        Observer.Expect('caption', 'true|text=LT Option Key Cap: Credit Memo cap,D-1|row=found');
        Observer.Expect('caption other', 'true|text=LT Option Key Cap: Inv cap,D-1|row=missing');
        Observer.Expect('ordinal', 'true|text=LT Option Key Cap: Credit Memo cap,D-1|row=found');
        Observer.Expect('unknown', 'false|''Quote'' is not an option. The existing options are:  ,Inv cap,Credit Memo cap|InvalidOptionString');
        Observer.Verify();
    end;

    [Test]
    procedure RecordId_OptionKeyShapes()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT Option Key Plain";
    begin
        K.DeleteAll();
        K."Doc Type" := K."Doc Type"::Invoice;
        K."No." := 'D-1';
        K.Insert();
        Observer.Observe('other case', EvalRecordId('LT Option Key Plain: invoice,D-1'));
        Observer.Observe('blank before', EvalRecordId('LT Option Key Plain:  Invoice,D-1'));
        Observer.Observe('blank after', EvalRecordId('LT Option Key Plain: Invoice ,D-1'));
        Observer.Observe('empty quoted', EvalRecordId('LT Option Key Plain: "",D-1'));
        Observer.Observe('blank quoted', EvalRecordId('LT Option Key Plain: " ",D-1'));
        Observer.Observe('quoted name', EvalRecordId('LT Option Key Plain: "Credit Memo",D-1'));
        Observer.Observe('max int', EvalRecordId('LT Option Key Plain: 2147483647,D-1'));
        Observer.Observe('past int', EvalRecordId('LT Option Key Plain: 2147483648,D-1'));
        Observer.Observe('minus', EvalRecordId('LT Option Key Plain: -1,D-1'));
        Observer.Expect('other case', 'true|text=LT Option Key Plain: Invoice,D-1|row=found');
        Observer.Expect('blank before', 'true|text=LT Option Key Plain: Invoice,D-1|row=found');
        Observer.Expect('blank after', 'true|text=LT Option Key Plain: Invoice,D-1|row=found');
        Observer.Expect('empty quoted', 'true|text=LT Option Key Plain: " ",D-1|row=missing');
        Observer.Expect('blank quoted', 'true|text=LT Option Key Plain: " ",D-1|row=missing');
        Observer.Expect('quoted name', 'true|text=LT Option Key Plain: Credit Memo,D-1|row=missing');
        Observer.Expect('max int', 'true|text=LT Option Key Plain: 2147483647,D-1|row=missing');
        Observer.Expect('past int', 'false|''2147483648'' is not an option. The existing options are:  ,Invoice,Credit Memo|InvalidOptionString');
        Observer.Expect('minus', 'false|''-1'' is not an option. The existing options are:  ,Invoice,Credit Memo|InvalidOptionString');
        Observer.Verify();
    end;
}
