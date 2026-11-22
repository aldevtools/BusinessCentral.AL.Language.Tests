// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method
// Scope: in-scope. Sort order of a Text and a Code key, SetRange and SetFilter ranges, equality and '@' filters on texts with Æ, Ø, Å, accents, ß and Œ, on a database table and on a temporary table, and the AL comparison operators on the same texts.
// Fixtures used: Probe Observer (codeunit 69160); own objects 77800-77801 (FC Coll Row, Filter Collation Nordic)
// Probe: from al-runner issues 8195 and 8196 (an outside reporter measured BC 28.4 W1, en-US). The database collation is not readable from AL; the order
//   the database gives is the collation of the database restored from the W1 artifact. Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: the sort order, ranges, equality, '@' filters and AL comparison operators of Text and Code values with Æ, Ø, Å, accents and ß on a database table and a temporary table, all as asserted (the values are the same on both and on every supported major).
// BC versions: 27, 28, 29

table 77800 "FC Coll Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; CName; Code[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(ByName; Name) { }
        key(ByCName; CName) { }
    }
}

codeunit 77801 "Filter Collation Nordic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Add(var Row: Record "FC Coll Row"; RowCode: Code[20]; RowName: Text[50])
    begin
        Row.Init();
        Row."Code" := RowCode;
        Row.Name := RowName;
        Row.CName := CopyStr(RowName, 1, 50);
        Row.Insert();
    end;

    local procedure Seed(var Row: Record "FC Coll Row")
    begin
        Row.Reset();
        Row.DeleteAll();
        Add(Row, 'N01', 'Alpha');
        Add(Row, 'N02', 'alpha two');
        Add(Row, 'N03', 'Bravo');
        Add(Row, 'N04', 'Émile');
        Add(Row, 'N05', 'Ærø');
        Add(Row, 'N06', 'Zebra');
        Add(Row, 'N07', 'a*b?');
        Add(Row, 'N08', '');
        Add(Row, 'N09', 'AEra');
        Add(Row, 'N10', 'Øre');
        Add(Row, 'N11', 'Oslo');
        Add(Row, 'N12', 'Åse');
        Add(Row, 'N13', 'Asa');
        Add(Row, 'N14', 'Zulu');
        Add(Row, 'N15', 'Œuvre');
        Add(Row, 'N16', 'Oeuvre');
        Add(Row, 'N17', 'Straße');
        Add(Row, 'N18', 'Strasse');
        Add(Row, 'N19', 'Ödön');
        Add(Row, 'N20', 'Ozon');
        Add(Row, 'N21', 'Ñandu');
        Add(Row, 'N22', 'Nz');
        Add(Row, 'N23', 'emile');
        Add(Row, 'N24', 'aerø');
        Add(Row, 'N25', 'Ab');
        Row.Reset();
    end;

    local procedure Codes(var Row: Record "FC Coll Row"): Text
    var
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Row."Code";
            until Row.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TrySetFilter(var Row: Record "FC Coll Row"; Filter: Text)
    begin
        Row.SetFilter(Name, Filter);
    end;

    local procedure ByFilter(var Row: Record "FC Coll Row"; Filter: Text): Text
    begin
        Row.Reset();
        if not TrySetFilter(Row, Filter) then
            exit('error: ' + GetLastErrorText());
        exit(Codes(Row));
    end;

    local procedure ByRange(var Row: Record "FC Coll Row"; FromName: Text; ToName: Text): Text
    begin
        Row.Reset();
        Row.SetRange(Name, FromName, ToName);
        exit(Codes(Row));
    end;

    local procedure ByCodeRange(var Row: Record "FC Coll Row"; FromName: Code[50]; ToName: Code[50]): Text
    begin
        Row.Reset();
        Row.SetRange(CName, FromName, ToName);
        exit(Codes(Row));
    end;

    local procedure ObserveOrder(var Observer: Codeunit "Probe Observer"; var Row: Record "FC Coll Row")
    begin
        Row.Reset();
        Row.SetCurrentKey(Name);
        Observer.Observe('nameAsc', Codes(Row));
        Row.Ascending(false);
        Observer.Observe('nameDesc', Codes(Row));
        Row.Reset();
        Row.SetCurrentKey(CName);
        Observer.Observe('codeAsc', Codes(Row));
    end;

    local procedure ObserveRanges(var Observer: Codeunit "Probe Observer"; var Row: Record "FC Coll Row")
    begin
        Observer.Observe('rangeAtoB', ByRange(Row, 'A', 'B'));
        Observer.Observe('rangeOtoP', ByRange(Row, 'O', 'P'));
        Observer.Observe('rangeZtoZZZZ', ByRange(Row, 'Z', 'ZZZZ'));
        Observer.Observe('rangeAEtoAF', ByRange(Row, 'AE', 'AF'));
        Observer.Observe('rangeAeLigToB', ByRange(Row, 'Æ', 'B'));
        Observer.Observe('rangeOStroke', ByRange(Row, 'Ø', 'Øzzz'));
        Observer.Observe('rangeARing', ByRange(Row, 'Å', 'Åzzz'));
        Observer.Observe('rangeNtoO', ByRange(Row, 'N', 'O'));
        Observer.Observe('rangeStoT', ByRange(Row, 'S', 'T'));
        Observer.Observe('codeRangeAtoB', ByCodeRange(Row, 'A', 'B'));
        Observer.Observe('codeRangeOtoP', ByCodeRange(Row, 'O', 'P'));
    end;

    local procedure ObserveEquality(var Observer: Codeunit "Probe Observer"; var Row: Record "FC Coll Row")
    begin
        Observer.Observe('eqAeTwo', ByRange(Row, 'AErø', 'AErø'));
        Observer.Observe('eqAeLig', ByRange(Row, 'Ærø', 'Ærø'));
        Observer.Observe('eqStrasse', ByRange(Row, 'Strasse', 'Strasse'));
        Observer.Observe('eqSharpS', ByRange(Row, 'Straße', 'Straße'));
        Observer.Observe('eqOeuvre', ByRange(Row, 'Oeuvre', 'Oeuvre'));
        Observer.Observe('eqEmileAccent', ByRange(Row, 'Émile', 'Émile'));
        Observer.Observe('filterAeLig', ByFilter(Row, 'Ærø'));
        Observer.Observe('filterAeTwo', ByFilter(Row, 'AErø'));
        Observer.Observe('filterGtZebra', ByFilter(Row, '>Zebra'));
        Observer.Observe('filterLtAlpha', ByFilter(Row, '<Alpha'));
        Observer.Observe('filterDotsAtoB', ByFilter(Row, 'A..B'));
    end;

    local procedure ObserveAt(var Observer: Codeunit "Probe Observer"; var Row: Record "FC Coll Row")
    begin
        Observer.Observe('at_emile', ByFilter(Row, '@emile'));
        Observer.Observe('at_EMILE', ByFilter(Row, '@EMILE'));
        Observer.Observe('at_emileAccent', ByFilter(Row, '@émile'));
        Observer.Observe('at_starMile', ByFilter(Row, '@*mile'));
        Observer.Observe('at_aeLig', ByFilter(Row, '@ærø'));
        Observer.Observe('at_aeTwoLower', ByFilter(Row, '@aerø'));
        Observer.Observe('at_aero', ByFilter(Row, '@aero'));
        Observer.Observe('at_sharpS', ByFilter(Row, '@straße'));
        Observer.Observe('at_strasse', ByFilter(Row, '@strasse'));
        Observer.Observe('at_oslo', ByFilter(Row, '@OSLO'));
        Observer.Observe('at_orestroke', ByFilter(Row, '@ore'));
        Observer.Observe('at_aringStar', ByFilter(Row, '@å*'));
        Observer.Observe('at_nandu', ByFilter(Row, '@nandu'));
        Observer.Observe('at_oeuvre', ByFilter(Row, '@oeuvre'));
        Observer.Observe('plain_emileAccent', ByFilter(Row, 'émile'));
        Observer.Observe('plain_Emile', ByFilter(Row, 'Emile'));
        Observer.Observe('plain_EAccentStar', ByFilter(Row, 'É*'));
        Observer.Observe('plain_EStar', ByFilter(Row, 'E*'));
    end;

    [Test]
    procedure SortOrder_Database_TextAndCodeKey()
    var
        Row: Record "FC Coll Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Row);
        ObserveOrder(Observer, Row);
        Observer.Expect('nameAsc', 'N08,N07,N25,N09,N24,N05,N01,N02,N13,N12,N03,N23,N04,N21,N22,N19,N16,N15,N10,N11,N20,N17,N18,N06,N14');
        Observer.Expect('nameDesc', 'N14,N06,N18,N17,N20,N11,N10,N15,N16,N19,N22,N21,N04,N23,N03,N12,N13,N02,N01,N05,N24,N09,N25,N07,N08');
        Observer.Expect('codeAsc', 'N08,N07,N25,N09,N05,N24,N01,N02,N13,N12,N03,N23,N04,N21,N22,N19,N15,N16,N10,N11,N20,N17,N18,N06,N14');
        Observer.Verify();
    end;

    [Test]
    procedure SortOrder_Temporary_TextAndCodeKey()
    var
        Row: Record "FC Coll Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Row);
        ObserveOrder(Observer, Row);
        Observer.Expect('nameAsc', 'N08,N07,N25,N09,N24,N05,N01,N02,N13,N12,N03,N23,N04,N21,N22,N19,N16,N15,N10,N11,N20,N17,N18,N06,N14');
        Observer.Expect('nameDesc', 'N14,N06,N18,N17,N20,N11,N10,N15,N16,N19,N22,N21,N04,N23,N03,N12,N13,N02,N01,N05,N24,N09,N25,N07,N08');
        Observer.Expect('codeAsc', 'N08,N07,N25,N09,N05,N24,N01,N02,N13,N12,N03,N23,N04,N21,N22,N19,N15,N16,N10,N11,N20,N17,N18,N06,N14');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_Database_Ranges()
    var
        Row: Record "FC Coll Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Row);
        ObserveRanges(Observer, Row);
        Observer.Expect('rangeAtoB', 'N01,N02,N05,N07,N09,N12,N13,N24,N25');
        Observer.Expect('rangeOtoP', 'N10,N11,N15,N16,N19,N20');
        Observer.Expect('rangeZtoZZZZ', 'N06,N14');
        Observer.Expect('rangeAEtoAF', 'N05,N09,N24');
        Observer.Expect('rangeAeLigToB', 'N01,N02,N05,N09,N12,N13,N24');
        Observer.Expect('rangeOStroke', 'N10,N11,N15,N16,N19,N20');
        Observer.Expect('rangeARing', 'N01,N02,N05,N07,N09,N12,N13,N24,N25');
        Observer.Expect('rangeNtoO', 'N21,N22');
        Observer.Expect('rangeStoT', 'N17,N18');
        Observer.Expect('codeRangeAtoB', 'N01,N02,N05,N07,N09,N12,N13,N24,N25');
        Observer.Expect('codeRangeOtoP', 'N10,N11,N15,N16,N19,N20');
        Observer.Verify();
    end;

    [Test]
    procedure SetRange_Temporary_Ranges()
    var
        Row: Record "FC Coll Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Row);
        ObserveRanges(Observer, Row);
        Observer.Expect('rangeAtoB', 'N01,N02,N05,N07,N09,N12,N13,N24,N25');
        Observer.Expect('rangeOtoP', 'N10,N11,N15,N16,N19,N20');
        Observer.Expect('rangeZtoZZZZ', 'N06,N14');
        Observer.Expect('rangeAEtoAF', 'N05,N09,N24');
        Observer.Expect('rangeAeLigToB', 'N01,N02,N05,N09,N12,N13,N24');
        Observer.Expect('rangeOStroke', 'N10,N11,N15,N16,N19,N20');
        Observer.Expect('rangeARing', 'N01,N02,N05,N07,N09,N12,N13,N24,N25');
        Observer.Expect('rangeNtoO', 'N21,N22');
        Observer.Expect('rangeStoT', 'N17,N18');
        Observer.Expect('codeRangeAtoB', 'N01,N02,N05,N07,N09,N12,N13,N24,N25');
        Observer.Expect('codeRangeOtoP', 'N10,N11,N15,N16,N19,N20');
        Observer.Verify();
    end;

    [Test]
    procedure Equality_Database_Expansions()
    var
        Row: Record "FC Coll Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Row);
        ObserveEquality(Observer, Row);
        Observer.Expect('eqAeTwo', 'N05');
        Observer.Expect('eqAeLig', 'N05');
        Observer.Expect('eqStrasse', 'N17,N18');
        Observer.Expect('eqSharpS', 'N17,N18');
        Observer.Expect('eqOeuvre', 'N16');
        Observer.Expect('eqEmileAccent', 'N04');
        Observer.Expect('filterAeLig', 'N05');
        Observer.Expect('filterAeTwo', 'N05');
        Observer.Expect('filterGtZebra', 'N14');
        Observer.Expect('filterLtAlpha', 'N05,N07,N08,N09,N24,N25');
        Observer.Expect('filterDotsAtoB', 'N01,N02,N05,N07,N09,N12,N13,N24,N25');
        Observer.Verify();
    end;

    [Test]
    procedure Equality_Temporary_Expansions()
    var
        Row: Record "FC Coll Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Row);
        ObserveEquality(Observer, Row);
        Observer.Expect('eqAeTwo', 'N05');
        Observer.Expect('eqAeLig', 'N05');
        Observer.Expect('eqStrasse', 'N17,N18');
        Observer.Expect('eqSharpS', 'N17,N18');
        Observer.Expect('eqOeuvre', 'N16');
        Observer.Expect('eqEmileAccent', 'N04');
        Observer.Expect('filterAeLig', 'N05');
        Observer.Expect('filterAeTwo', 'N05');
        Observer.Expect('filterGtZebra', 'N14');
        Observer.Expect('filterLtAlpha', 'N05,N07,N08,N09,N24,N25');
        Observer.Expect('filterDotsAtoB', 'N01,N02,N05,N07,N09,N12,N13,N24,N25');
        Observer.Verify();
    end;

    [Test]
    procedure AtFilter_Database_Accents()
    var
        Row: Record "FC Coll Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Row);
        ObserveAt(Observer, Row);
        Observer.Expect('at_emile', 'N04,N23');
        Observer.Expect('at_EMILE', 'N04,N23');
        Observer.Expect('at_emileAccent', 'N04,N23');
        Observer.Expect('at_starMile', 'N04,N23');
        Observer.Expect('at_aeLig', 'N05,N24');
        Observer.Expect('at_aeTwoLower', 'N05,N24');
        Observer.Expect('at_aero', 'N05,N24');
        Observer.Expect('at_sharpS', 'N17,N18');
        Observer.Expect('at_strasse', 'N17,N18');
        Observer.Expect('at_oslo', 'N11');
        Observer.Expect('at_orestroke', 'N10');
        Observer.Expect('at_aringStar', 'N01,N02,N07,N09,N12,N13,N24,N25');
        Observer.Expect('at_nandu', 'N21');
        Observer.Expect('at_oeuvre', 'N15,N16');
        Observer.Expect('plain_emileAccent', '');
        Observer.Expect('plain_Emile', '');
        Observer.Expect('plain_EAccentStar', 'N04');
        Observer.Expect('plain_EStar', '');
        Observer.Verify();
    end;

    [Test]
    procedure AtFilter_Temporary_Accents()
    var
        Row: Record "FC Coll Row" temporary;
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Row);
        ObserveAt(Observer, Row);
        Observer.Expect('at_emile', 'N04,N23');
        Observer.Expect('at_EMILE', 'N04,N23');
        Observer.Expect('at_emileAccent', 'N04,N23');
        Observer.Expect('at_starMile', 'N04,N23');
        Observer.Expect('at_aeLig', 'N05,N24');
        Observer.Expect('at_aeTwoLower', 'N05,N24');
        Observer.Expect('at_aero', 'N05,N24');
        Observer.Expect('at_sharpS', 'N17,N18');
        Observer.Expect('at_strasse', 'N17,N18');
        Observer.Expect('at_oslo', 'N11');
        Observer.Expect('at_orestroke', 'N10');
        Observer.Expect('at_aringStar', 'N01,N02,N07,N09,N12,N13,N24,N25');
        Observer.Expect('at_nandu', 'N21');
        Observer.Expect('at_oeuvre', 'N15,N16');
        Observer.Expect('plain_emileAccent', '');
        Observer.Expect('plain_Emile', '');
        Observer.Expect('plain_EAccentStar', 'N04');
        Observer.Expect('plain_EStar', '');
        Observer.Verify();
    end;

    [Test]
    procedure Operators_Text_Compare()
    var
        Observer: Codeunit "Probe Observer";
        AeLig: Text;
        AeTwo: Text;
        Sharp: Text;
        DoubleS: Text;
    begin
        AeLig := 'Ærø';
        AeTwo := 'AErø';
        Sharp := 'Straße';
        DoubleS := 'Strasse';
        Observer.Observe('aeLigLtB', Format(AeLig < 'B'));
        Observer.Observe('aeLigGtZ', Format(AeLig > 'Z'));
        Observer.Observe('aeLigEqAeTwo', Format(AeLig = AeTwo));
        Observer.Observe('aeLigLtAlpha', Format(AeLig < 'Alpha'));
        Observer.Observe('emileLtF', Format('Émile' < 'F'));
        Observer.Observe('oStrokeLtP', Format('Øre' < 'P'));
        Observer.Observe('aRingLtB', Format('Åse' < 'B'));
        Observer.Observe('sharpEqDoubleS', Format(Sharp = DoubleS));
        Observer.Observe('sharpLtDoubleS', Format(Sharp < DoubleS));
        Observer.Observe('lowerALtUpperB', Format('a' < 'B'));
        Observer.Observe('upperBLtLowerA', Format('B' < 'a'));
        Observer.Observe('lowerALtUpperA', Format('a' < 'A'));
        Observer.Observe('emileLtEmileAccent', Format('emile' < 'émile'));
        Observer.Expect('aeLigLtB', 'Yes');
        Observer.Expect('aeLigGtZ', 'No');
        Observer.Expect('aeLigEqAeTwo', 'No');
        Observer.Expect('aeLigLtAlpha', 'Yes');
        Observer.Expect('emileLtF', 'Yes');
        Observer.Expect('oStrokeLtP', 'Yes');
        Observer.Expect('aRingLtB', 'Yes');
        Observer.Expect('sharpEqDoubleS', 'No');
        Observer.Expect('sharpLtDoubleS', 'No');
        Observer.Expect('lowerALtUpperB', 'Yes');
        Observer.Expect('upperBLtLowerA', 'No');
        Observer.Expect('lowerALtUpperA', 'Yes');
        Observer.Expect('emileLtEmileAccent', 'Yes');
        Observer.Verify();
    end;
}
