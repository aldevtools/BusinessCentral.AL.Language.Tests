// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: none (self-contained ListPart, per the ListPart/TestPage conventions
//   already used by TestPageModalPart_PartList.al)
//
// A page (or ListPart) declared SourceTable = Integer; SourceTableTemporary = true; must
// bind to its OWN empty temporary rowset -- exactly like a temporary source table over any
// other table -- never to the platform's shared/virtual Integer rows. Number starts
// unpositioned (First() = false on an empty page) and the only rows present after the page
// inserts them are the ones it inserted itself, starting at Number = 1.

// Never populated -- proves a temporary-Integer part starts with zero rows.
page 60622 "Test TmpInt Empty Part"
{
    PageType = ListPart;
    SourceTable = Integer;
    SourceTableTemporary = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Number; Rec.Number) { ApplicationArea = All; }
            }
        }
    }
}

// Self-populating: inserts its own rows in OnOpenPage, no host involvement at all.
page 60623 "Test TmpInt SelfLoad Part"
{
    PageType = ListPart;
    SourceTable = Integer;
    SourceTableTemporary = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Number; Rec.Number) { ApplicationArea = All; }
                field(ValueAtNumber; Values[Rec.Number]) { ApplicationArea = All; Caption = 'Value'; }
            }
        }
    }

    var
        Values: array[20] of Decimal;

    trigger OnOpenPage()
    var
        i: Integer;
    begin
        for i := 1 to 3 do begin
            Values[i] := i * 10;
            Rec.Init();
            Rec.Number := i;
            Rec.Insert();
        end;
    end;
}

codeunit 60624 "Test TmpInt ListPart"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure TempIntegerPart_DirectOpen_StartsEmpty()
    // CLAIM: a TestPage over a page declaring SourceTable = Integer;
    // SourceTableTemporary = true; opens on an empty rowset -- never the platform's
    // materialised/virtual Integer rows (which would answer Number = -1000 first).
    var
        Part: TestPage "Test TmpInt Empty Part";
    begin
        Initialize();

        Part.OpenView();
        Assert.IsFalse(Part.First(), 'a never-populated temporary-Integer part must start empty');
        Part.Close();
    end;

    [Test]
    procedure TempIntegerPart_SelfLoaded_FirstRowIsNumberOne()
    // CLAIM: rows the temporary-Integer page inserts itself (in its own OnOpenPage) are
    // the ONLY rows visible, and Number/array-indexed columns read back exactly what was
    // inserted -- Number starts at 1, not the platform's virtual-table Number = -1000.
    var
        Part: TestPage "Test TmpInt SelfLoad Part";
    begin
        Initialize();

        Part.OpenView();
        Assert.IsTrue(Part.First(), 'part must have rows after its own OnOpenPage runs');
        Assert.AreEqual('1', Part.Number.Value(), 'first row Number');
        Assert.AreEqual('10.00', Part.ValueAtNumber.Value(), 'first row Values[Number]');
        Part.Close();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
