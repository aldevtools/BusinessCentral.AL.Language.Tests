// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-method-overloading
// Scope: in-scope
// Fixtures used: Probe Observer (69160), self-contained codeunits 82353 (overloads) and 82356 (test)
// Corpus issue #664 items 79 and 82 (P69Overloads.al is claimed by another writer, so these live here):
//   79: overloads that differ only in the element type of a List parameter (List of [Integer] and List of [Text[30]]): which one runs.
//   82: two overloads of a local procedure each declare a label with the same name (myLabel): does each return its own text.
// Result (BC 29.0): each call runs the overload of its own type; each overload returns its own label text.

codeunit 82353 "LT BO Overload Host"
{
    procedure Initialize(L: List of [Integer]): Text
    begin
        exit('integer list ' + Format(L.Count()));
    end;

    procedure Initialize(L: List of [Text[30]]): Text
    begin
        exit('text30 list ' + Format(L.Count()));
    end;

    procedure LabelOf(A: Integer): Text
    begin
        exit(P(A));
    end;

    procedure LabelOf(A: Text): Text
    begin
        exit(P(A));
    end;

    local procedure P(A: Integer): Text
    var
        myLabel: Label 'AH int';
    begin
        exit(myLabel + ' ' + Format(A));
    end;

    local procedure P(A: Text): Text
    var
        myLabel: Label 'AH text';
    begin
        exit(myLabel + ' ' + A);
    end;
}

codeunit 82356 "LT BO Overloads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ListElementTypeOverloads_WhichRuns()
    var
        Host: Codeunit "LT BO Overload Host";
        Observer: Codeunit "Probe Observer";
        LI: List of [Integer];
        LT30: List of [Text[30]];
    begin
        LI.Add(1);
        LT30.Add('a');
        LT30.Add('b');
        Observer.Observe('list of integer', Host.Initialize(LI));
        Observer.Observe('list of text30', Host.Initialize(LT30));
        Observer.Expect('list of integer', 'integer list 1');
        Observer.Expect('list of text30', 'text30 list 2');
        Observer.Verify();
    end;

    [Test]
    procedure SameNamedLabelInOverloads_EachKeepsItsText()
    var
        Host: Codeunit "LT BO Overload Host";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('integer overload', Host.LabelOf(7));
        Observer.Observe('text overload', Host.LabelOf('x'));
        Observer.Expect('integer overload', 'AH int 7');
        Observer.Expect('text overload', 'AH text x');
        Observer.Verify();
    end;
}
