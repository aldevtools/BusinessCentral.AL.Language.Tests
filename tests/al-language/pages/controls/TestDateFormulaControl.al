// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: Assert (60021), ALT DateFormula Row (60604), ALT DateFormula Card (60605)
//
// What a TestPage control whose declared type is DateFormula does with the value SetValue
// hands it. AL's TestPage surface is string-typed for every control, so the question the tier
// answers here is whether a DateFormula control EVALUATES that string into a date formula, or
// whether the value has to already be one.
//
// Both ways an AL test can reach a DateFormula control are covered, because they are different
// code paths and a platform can get one right and the other wrong:
//
//   Shape A — the AL hands SetValue a TEXT that spells a formula ('<1D>', '3D').
//   Shape B — the AL hands SetValue a typed DateFormula, via a Variant. BC renders the typed
//             value to text before the control sees it, so this arm pins that the round trip
//             through that rendering still lands on the control's declared type.
//
// Both bindings are covered for the same reason: RecPeriod is bound to a table field,
// VarPeriod to a page variable, and BC's write path reaches them differently.
//
// The two Text arms are the control: they pin that a control whose type is NOT DateFormula
// still takes its string unchanged. An implementation that routed every control through
// DateFormula evaluation would pass every arm above and fail those two, which is what makes
// this suite discriminate rather than merely cover.
//
// The last arm is the negative direction, and it is deliberately NOT "an invalid value is
// refused". That was measured and is false: BC's DateFormula parser reads a leading token and
// stops, so 'not a formula' and '<1X>' are both accepted rather than rejected. What the arm
// pins instead is that two formulas differing ONLY in the quantifier do not land on the same
// stored value -- which is what fails if a platform stores the text verbatim, truncates it,
// or blanks it, and which needs no prediction of the tier's own formatting.

codeunit 60601 "ALT DateFormula Control Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure SeedRow()
    var
        Row: Record "ALT DateFormula Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'DF-1';
        Row.Insert();
    end;

    // ── Shape A: SetValue is handed TEXT spelling a formula ─────────────────────

    [Test]
    procedure SetValue_TextFormula_OnRecBoundDateFormulaControl_Evaluates()
    var
        Card: TestPage "ALT DateFormula Card";
        Row: Record "ALT DateFormula Row";
        Expected: DateFormula;
    begin
        // The invariant spelling, which is what Format() of a DateFormula produces.
        SeedRow();
        Evaluate(Expected, '<1D>');

        Card.OpenEdit();
        Card.RecPeriod.SetValue('<1D>');
        Card.Close();

        // Asserted on the STORED field, not on the control's own read-back: a control that
        // echoed the string it was handed without ever reaching the field would pass a
        // read-back assertion while storing nothing.
        Row.Get('DF-1');
        Assert.AreEqual(Format(Expected), Format(Row."Period Length"),
          'SetValue with text <1D> on a Rec-bound DateFormula control must store the evaluated formula');
    end;

    [Test]
    procedure SetValue_TextFormula_OnPageVariableDateFormulaControl_Evaluates()
    var
        Card: TestPage "ALT DateFormula Card";
        Expected: DateFormula;
    begin
        SeedRow();
        Evaluate(Expected, '<1D>');

        Card.OpenEdit();
        Card.VarPeriod.SetValue('<1D>');

        // A page variable has no table field behind it, so the control's own value IS the
        // stored state and reading it back is the only observation available.
        Assert.AreEqual(Format(Expected), Card.VarPeriod.Value,
          'SetValue with text <1D> on a page-variable DateFormula control must evaluate it');
        Card.Close();
    end;

    [Test]
    procedure SetValue_TextFormulaWithoutAngleBrackets_OnDateFormulaControl_Evaluates()
    var
        Card: TestPage "ALT DateFormula Card";
        Row: Record "ALT DateFormula Row";
        Expected: DateFormula;
    begin
        // The spelling Microsoft's own tests produce: Format(-5) + 'D' gives '-5D', with no
        // angle brackets. A platform that accepted only the bracketed invariant form would
        // pass the arm above and fail this one.
        SeedRow();
        Evaluate(Expected, '<3D>');

        Card.OpenEdit();
        Card.RecPeriod.SetValue('3D');
        Card.Close();

        Row.Get('DF-1');
        Assert.AreEqual(Format(Expected), Format(Row."Period Length"),
          'SetValue with unbracketed text 3D on a DateFormula control must evaluate it');
    end;

    // ── Shape B: SetValue is handed a TYPED DateFormula through a Variant ───────

    [Test]
    procedure SetValue_TypedDateFormulaViaVariant_OnRecBoundControl_Evaluates()
    var
        Card: TestPage "ALT DateFormula Card";
        Row: Record "ALT DateFormula Row";
        Period: DateFormula;
        AsVariant: Variant;
    begin
        // The AL never holds a Text here: Evaluate produces a DateFormula, which travels
        // through a Variant exactly as LibraryVariableStorage.Dequeue hands one to a handler.
        SeedRow();
        Evaluate(Period, '<2D>');
        AsVariant := Period;

        Card.OpenEdit();
        Card.RecPeriod.SetValue(AsVariant);
        Card.Close();

        Row.Get('DF-1');
        Assert.AreEqual(Format(Period), Format(Row."Period Length"),
          'SetValue with a typed DateFormula in a Variant must store that formula');
    end;

    [Test]
    procedure SetValue_TypedDateFormulaViaVariant_OnPageVariableControl_Evaluates()
    var
        Card: TestPage "ALT DateFormula Card";
        Period: DateFormula;
        AsVariant: Variant;
    begin
        SeedRow();
        Evaluate(Period, '<2D>');
        AsVariant := Period;

        Card.OpenEdit();
        Card.VarPeriod.SetValue(AsVariant);

        Assert.AreEqual(Format(Period), Card.VarPeriod.Value,
          'SetValue with a typed DateFormula in a Variant must set a page-variable control');
        Card.Close();
    end;

    // ── The control arm: a non-DateFormula control is unaffected ────────────────

    [Test]
    procedure SetValue_Text_OnRecBoundTextControl_StoresItUnchanged()
    var
        Card: TestPage "ALT DateFormula Card";
        Row: Record "ALT DateFormula Row";
    begin
        // Deliberately a string that WOULD parse as a date formula. A platform that decided
        // how to read a value from the string rather than from the control's declared type
        // would evaluate this one too, and this arm is what catches that.
        SeedRow();

        Card.OpenEdit();
        Card.RecText.SetValue('<1D>');
        Card.Close();

        Row.Get('DF-1');
        Assert.AreEqual('<1D>', Row.Description,
          'SetValue on a Text control must store the string unchanged, even one spelling a formula');
    end;

    [Test]
    procedure SetValue_Text_OnPageVariableTextControl_StoresItUnchanged()
    var
        Card: TestPage "ALT DateFormula Card";
    begin
        SeedRow();

        Card.OpenEdit();
        Card.VarText.SetValue('<1D>');

        Assert.AreEqual('<1D>', Card.VarText.Value,
          'SetValue on a page-variable Text control must keep the string unchanged');
        Card.Close();
    end;

    // ── Negative: the quantifier is read, not merely echoed ─────────────────────

    [Test]
    procedure SetValue_DifferentQuantifiers_OnDateFormulaControl_AreNotInterchangeable()
    var
        Card: TestPage "ALT DateFormula Card";
        Row: Record "ALT DateFormula Row";
        OneDay: DateFormula;
        RoundTrip: DateFormula;
        Stored: Text;
    begin
        // The discriminating negative. '<1D>' and '<1M>' differ only in the quantifier, so a
        // platform that stored the incoming text verbatim, or truncated it, or blanked it,
        // would make these two agree -- and every positive arm above would still pass.
        // Asserting they DIFFER pins that the quantifier reached the stored value, without
        // this suite having to predict the tier's formatting for either one.
        SeedRow();
        Evaluate(OneDay, '<1D>');

        Card.OpenEdit();
        Card.RecPeriod.SetValue('<1M>');
        Card.Close();

        Row.Get('DF-1');
        Stored := Format(Row."Period Length");
        Assert.AreNotEqual(Format(OneDay), Stored,
          'a month formula must not store the same value as a day formula');
        Assert.AreNotEqual('', Stored,
          'a valid month formula must not store a blank DateFormula');
        // AreNotEqual alone is too weak on its own: a truncated '<' differs from a day formula
        // too, so it would satisfy both assertions above. Pinning the round trip is what makes
        // this arm fail for a platform that stores anything other than the evaluated month
        // formula, without predicting the tier's spelling for it.
        Evaluate(RoundTrip, Stored);
        Assert.AreEqual(Stored, Format(RoundTrip),
          'the stored month formula must itself re-evaluate to the same formula');
    end;
}
