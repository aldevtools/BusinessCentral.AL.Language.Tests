// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72581, table 72582
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows (NP Retail blockers): "`ReportLayoutType` - the members are RDLC, Word, Excel, Custom",
// "`Format(OptionField, 0, 9)` where `OptionCaption` differs from `OptionMembers`", "`foreach Token in JsonArray`"
// Facts: Format of ReportLayoutType members, Format of option fields with different caption and member names (formats 0, 1, 2, 9, also with GlobalLanguage 1031), foreach over a JsonArray
// BC versions: 29 (27 and 28 by CI)

table 72582 "LT PnE Option Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option)
        {
            OptionMembers = "A-B",C;
            OptionCaption = 'First,Second';
        }
        field(3; OptSame; Option)
        {
            OptionMembers = X,Y;
        }
        field(4; OptCaptionBlank; Option)
        {
            OptionMembers = "M 1","M 2";
            OptionCaption = ' ,Caption Two';
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72581 "LT PnE Format Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure All(var R: Record "LT PnE Option Rec"; FieldNo: Integer): Text
    var
        RR: RecordRef;
        FR: FieldRef;
        S: Text;
        i: Integer;
    begin
        RR.GetTable(R);
        FR := RR.Field(FieldNo);
        for i := 0 to 2 do
            S += Format(FR.Value, 0, i) + '|';
        S += Format(FR.Value, 0, 9);
        exit(S);
    end;

    [Test]
    procedure ReportLayoutType_Members()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('RDLC0', Format(ReportLayoutType::RDLC, 0, 0));
        Observer.Observe('RDLC2', Format(ReportLayoutType::RDLC, 0, 2));
        Observer.Observe('RDLC9', Format(ReportLayoutType::RDLC, 0, 9));
        Observer.Observe('Word0', Format(ReportLayoutType::Word, 0, 0));
        Observer.Observe('Word2', Format(ReportLayoutType::Word, 0, 2));
        Observer.Observe('Word9', Format(ReportLayoutType::Word, 0, 9));
        Observer.Observe('Excel0', Format(ReportLayoutType::Excel, 0, 0));
        Observer.Observe('Excel2', Format(ReportLayoutType::Excel, 0, 2));
        Observer.Observe('Custom0', Format(ReportLayoutType::Custom, 0, 0));
        Observer.Observe('Custom2', Format(ReportLayoutType::Custom, 0, 2));
        Observer.Observe('Custom9', Format(ReportLayoutType::Custom, 0, 9));
        Observer.Expect('RDLC0', 'RDLC');
        Observer.Expect('RDLC2', '0');
        Observer.Expect('RDLC9', '0');
        Observer.Expect('Word0', 'Word');
        Observer.Expect('Word2', '1');
        Observer.Expect('Word9', '1');
        Observer.Expect('Excel0', 'Excel');
        Observer.Expect('Excel2', '2');
        Observer.Expect('Custom0', 'Custom');
        Observer.Expect('Custom2', '3');
        Observer.Expect('Custom9', '3');
        Observer.Verify();
    end;

    [Test]
    procedure OptionField_CaptionDiffersFromMember()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnE Option Rec";
    begin
        R.Opt := R.Opt::"A-B";
        Observer.Observe('firstAllFormats', All(R, 2));
        R.Opt := R.Opt::C;
        Observer.Observe('secondAllFormats', All(R, 2));
        Observer.Observe('firstDirect9', Format(R.Opt::"A-B", 0, 9));
        Observer.Observe('secondDirect9', Format(R.Opt::C, 0, 9));
        R.OptSame := R.OptSame::Y;
        Observer.Observe('sameAllFormats', All(R, 3));
        R.OptCaptionBlank := R.OptCaptionBlank::"M 1";
        Observer.Observe('blankCaptionFirst', All(R, 4));
        R.OptCaptionBlank := R.OptCaptionBlank::"M 2";
        Observer.Observe('blankCaptionSecond', All(R, 4));
        Observer.Expect('firstAllFormats', 'First|First|0|0');
        Observer.Expect('secondAllFormats', 'Second|Second|1|1');
        Observer.Expect('firstDirect9', '0');
        Observer.Expect('secondDirect9', '1');
        Observer.Expect('sameAllFormats', 'Y|Y|1|1');
        Observer.Expect('blankCaptionFirst', ' | |0|0');
        Observer.Expect('blankCaptionSecond', 'Caption Two|Caption Two|1|1');
        Observer.Verify();
    end;

    [Test]
    procedure OptionField_CaptionDiffersFromMember_German()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT PnE Option Rec";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        R.Opt := R.Opt::"A-B";
        Observer.Observe('firstAllFormats', All(R, 2));
        R.Opt := R.Opt::C;
        Observer.Observe('secondAllFormats', All(R, 2));
        Observer.Observe('direct9', Format(R.Opt::C, 0, 9));
        GlobalLanguage(Saved);
        Observer.Expect('firstAllFormats', 'First|First|0|0');
        Observer.Expect('secondAllFormats', 'Second|Second|1|1');
        Observer.Expect('direct9', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_OverJsonArray()
    var
        Observer: Codeunit "Probe Observer";
        Arr: JsonArray;
        Obj: JsonObject;
        Tok: JsonToken;
        Back: JsonToken;
        Val: JsonToken;
        S: Text;
        R: Text;
        N: Integer;
    begin
        Obj.Add('a', 1);
        Arr.Add(Obj);
        Clear(Obj);
        Obj.Add('a', 2);
        Arr.Add(Obj);
        Arr.Add('text');
        Arr.Add(3);
        foreach Tok in Arr do begin
            N += 1;
            Tok.WriteTo(R);
            S += R + ';';
        end;
        Observer.Observe('count', Format(N));
        Observer.Observe('order', S);
        Observer.Observe('afterLoopIsAssigned', Format(Tok.IsValue()));
        Arr.WriteTo(R);
        Observer.Observe('arrayUnchanged', R);
        Observer.Expect('count', '4');
        Observer.Expect('order', '{"a":1};{"a":2};"text";3;');
        Observer.Expect('afterLoopIsAssigned', 'Yes');
        Observer.Expect('arrayUnchanged', '[{"a":1},{"a":2},"text",3]');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_ChangeTokenInBody()
    var
        Observer: Codeunit "Probe Observer";
        Arr: JsonArray;
        Obj: JsonObject;
        Tok: JsonToken;
        Prop: JsonToken;
        R: Text;
    begin
        Obj.Add('a', 1);
        Arr.Add(Obj);
        Clear(Obj);
        Obj.Add('a', 2);
        Arr.Add(Obj);
        foreach Tok in Arr do begin
            Tok.AsObject().Add('b', 'added');
            Tok.AsObject().Replace('a', 100);
        end;
        Arr.WriteTo(R);
        Observer.Observe('arrayAfterChange', R);
        Observer.Observe('objVariableUntouched', Format(Obj.Contains('b')));
        Observer.Expect('arrayAfterChange', '[{"b":"added","a":100},{"b":"added","a":100}]');
        Observer.Expect('objVariableUntouched', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryAddWhileLooping(var Arr: JsonArray; var N: Integer)
    var
        Tok: JsonToken;
    begin
        foreach Tok in Arr do begin
            Arr.Add(9);
            N += 1;
            if N > 10 then
                break;
        end;
    end;

    [Test]
    procedure Foreach_EmptyAndBreak()
    var
        Observer: Codeunit "Probe Observer";
        Arr: JsonArray;
        Tok: JsonToken;
        N: Integer;
        R: Text;
    begin
        foreach Tok in Arr do
            N += 1;
        Observer.Observe('emptyPasses', Format(N));
        Arr.Add(1);
        Arr.Add(2);
        Arr.Add(3);
        foreach Tok in Arr do begin
            N += 1;
            if N = 2 then
                break;
        end;
        Tok.WriteTo(R);
        Observer.Observe('breakPasses', Format(N));
        Observer.Observe('tokenAtBreak', R);
        N := 0;
        Observer.Observe('tryAddWhileLooping', Format(TryAddWhileLooping(Arr, N)));
        Observer.Observe('addedWhileLooping', Format(N));
        Observer.Observe('tryError', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('arrayCount', Format(Arr.Count()));
        Observer.Expect('emptyPasses', '0');
        Observer.Expect('breakPasses', '2');
        Observer.Expect('tokenAtBreak', '2');
        Observer.Expect('tryAddWhileLooping', 'Yes');
        Observer.Expect('addedWhileLooping', '3');
        Observer.Expect('tryError', '|');
        Observer.Expect('arrayCount', '6');
        Observer.Verify();
    end;
}
