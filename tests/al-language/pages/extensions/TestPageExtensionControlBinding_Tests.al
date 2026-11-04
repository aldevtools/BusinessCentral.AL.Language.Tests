// Tests for the fixture in TestPageExtensionControlBinding_Page.al.
//
// CLAIM: a control declared by a PAGEEXTENSION is reachable through a TestPage and carries its
// value, whether it is bound to a variable the pageextension declares or to a field of the
// extended page's SourceTable.
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4145, which reports
// NavTestFieldNotFoundException on the global-bound case. Nothing here predicts the runner's
// answer -- these arms record what BC does, which is the thing that was missing.

codeunit 60978 "PXC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "PXC Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row."Rec Text" := 'RECTEXT';
        Row.Insert();
    end;

    [Test]
    procedure PageExtControl_BoundToExtensionGlobal_IsFoundAndReadsItsValue()
    // The half AL Runner #4145 reports failing. OnOpenPage assigns the global, so a found
    // control must read the assigned value rather than a blank.
    var
        Card: TestPage "PXC Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.GoToKey(1);
        Assert.AreEqual(
            'EXTGLOBAL', Card.ExtGlobalField.Value(),
            'A pageextension control bound to an extension global must read the value its OnOpenPage assigned.');
        Card.Close();
    end;

    [Test]
    procedure PageExtControl_BoundToRecField_IsFoundAndReadsItsValue()
    // The discriminating half. Same pageextension, same layout block, different binding.
    //
    // Read together with the arm above: both passing means extension controls reach the page
    // metadata and any global-bound failure is about source expressions; both failing means
    // the metadata does not carry extension controls at all. Neither arm alone says which.
    var
        Card: TestPage "PXC Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.GoToKey(1);
        Assert.AreEqual(
            'RECTEXT', Card.ExtRecField.Value(),
            'A pageextension control bound to a SourceTable field must read that field''s value.');
        Card.Close();
    end;

    [Test]
    procedure PageExtControl_BaseControl_StillReadable()
    // The control. If the base page's own control stopped being readable, the two arms above
    // would fail for a reason that has nothing to do with pageextensions.
    var
        Card: TestPage "PXC Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.GoToKey(1);
        Assert.AreEqual(
            '1', Card."Entry No.".Value(),
            'The base page''s own control must still be readable alongside the extension''s.');
        Card.Close();
    end;
}

// Tests for the SUBPAGE fixtures in TestPageExtensionControlBinding_Page.al.
//
// CLAIM: a control declared by a PAGEEXTENSION on a page used as a SUBPAGE PART is reachable
// through the host TestPage's part and carries its value -- the same claim the codeunit above
// makes for a top-level page.
//
// A SEPARATE CODEUNIT ON PURPOSE. AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4181
// reports the part shape still failing with the top-level fix in place, so the two claims have
// different runner answers and an expectations entry must be able to name one without the other.
// Codeunit 60978's arms are green on the runner; these may not be, and a shared codeunit would
// force a Method wildcard to claim arms that pass.
//
// Nothing here predicts the runner's answer. These arms record what BC does, which for the part
// shape had never been measured -- #4181 says so explicitly, calling its own expectation
// "an expectation from the top-level result, not a verdict".

codeunit 60980 "PXC Sub Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "PXC Row";
        SubRow: Record "PXC Sub Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row."Rec Text" := 'RECTEXT';
        Row.Insert();

        SubRow.DeleteAll();
        SubRow.Init();
        SubRow."Entry No." := 1;
        SubRow."Sub Text" := 'SUBRECTEXT';
        SubRow.Insert();
    end;

    [Test]
    procedure SubPageExtControl_BoundToExtensionGlobal_IsFoundAndReadsItsValue()
    // The shape AL Runner #4181 reports failing. The part's own OnOpenPage assigns the global,
    // so a found control must read the assigned value rather than a blank.
    var
        Host: TestPage "PXC Host Card";
    begin
        Initialize();

        Host.OpenEdit();
        Host.GoToKey(1);
        Assert.AreEqual(
            'SUBEXTGLOBAL', Host.SubPart.SubExtGlobalField.Value(),
            'A pageextension control on a subpage part, bound to an extension global, must read the value its OnOpenPage assigned.');
        Host.Close();
    end;

    [Test]
    procedure SubPageExtControl_BoundToRecField_IsFoundAndReadsItsValue()
    // The discriminating half, one level down. Same pageextension, same layout block, different
    // binding: read with the arm above, a failure separates "the part's metadata does not carry
    // extension controls" from "it does, and the source expression never registered".
    var
        Host: TestPage "PXC Host Card";
    begin
        Initialize();

        Host.OpenEdit();
        Host.GoToKey(1);
        Assert.AreEqual(
            'SUBRECTEXT', Host.SubPart.SubExtRecField.Value(),
            'A pageextension control on a subpage part, bound to a SourceTable field, must read that field''s value.');
        Host.Close();
    end;

    [Test]
    procedure SubPageBaseControl_StillReadable()
    // The control. If the part's OWN control stopped being readable, the two arms above would
    // fail for a reason that has nothing to do with pageextensions -- the part not being
    // reachable at all, rather than its extension's controls being absent from it.
    var
        Host: TestPage "PXC Host Card";
    begin
        Initialize();

        Host.OpenEdit();
        Host.GoToKey(1);
        Assert.AreEqual(
            '1', Host.SubPart."Entry No.".Value(),
            'The subpage part''s own control must be readable, so a failure above is about the extension rather than the part.');
        Host.Close();
    end;
}
