// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Fixtures used: TestFieldTypedFixture.al (table 70955 "LT TFT Rec", enum 70954 "LT TFT Kind")
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.TestField(Field, Value, ErrorInfo) with Collectible = true under ErrorBehavior::Collect: the collected ErrorInfo Message, Title and DetailedMessage.
// Risky: ErrorBehavior/GetCollectedErrors/Collectible; own file.
// BC versions: 29 (27 and 28 by CI)

codeunit 70975 "LT TFT Rec Collected"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectRec(var Rec: Record "LT TFT Rec"; var Texts: List of [Text])
    var
        Info: ErrorInfo;
        Errs: List of [ErrorInfo];
        E: ErrorInfo;
        IntVal: Integer;
        TxtVal: Text;
    begin
        IntVal := 43;
        TxtVal := 'other';
        Info.Message := 'TFT message';
        Info.Title := 'TFT title';
        Info.DetailedMessage := 'TFT detail';
        Info.Collectible := true;
        Rec.TestField(Int, IntVal, Info);
        Rec.TestField(Txt, TxtVal, Info);
        Errs := GetCollectedErrors();
        foreach E in Errs do begin
            Texts.Add('msg=' + E.Message);
            Texts.Add('title=' + E.Title);
            Texts.Add('detail=' + E.DetailedMessage);
        end;
        ClearCollectedErrors();
    end;

    [Test]
    procedure P189_RecTestFieldInfo_Collected_Texts()
    var
        Rec: Record "LT TFT Rec";
        Texts: List of [Text];
        Observer: Codeunit "Probe Observer";
        T: Text;
        i: Integer;
    begin
        Rec.DeleteAll();
        Rec.Int := 42;
        Rec.Txt := 'text';
        CollectRec(Rec, Texts);
        Observer.Observe('count', Format(Texts.Count()));
        foreach T in Texts do begin
            i += 1;
            Observer.Observe('item' + Format(i), T);
        end;
        Observer.Expect('count', '6');
        Observer.Expect('item1', 'msg=TFT message');
        Observer.Expect('item2', 'title=TFT title');
        Observer.Expect('item3', 'detail=TFT detail');
        Observer.Expect('item4', 'msg=TFT message');
        Observer.Expect('item5', 'title=TFT title');
        Observer.Expect('item6', 'detail=TFT detail');
        Observer.Verify();
    end;
}
