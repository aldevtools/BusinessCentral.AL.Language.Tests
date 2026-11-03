// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpage-drilldown-method
// Scope: in-scope
// Fixtures used: Test Page DrillDown Row (60972), Test Page DrillDown List (60965)
//
// A list page whose repeater has several controls bound to the SAME source field (Descr),
// distinguished only by control name — exactly the shape needed to prove field-level
// dispatch, not just "a trigger somewhere ran". StampCol writes what the page's CURRENT row
// is, mirroring TestPageActionInvoke's row-context check for actions.
//
// PlainCol declares no OnDrillDown trigger at all — the field-with-no-trigger case.
// FailCol's OnDrillDown raises an Error, to prove DrillDown() does not swallow it.

page 60965 "Test Page DrillDown List"
{
    PageType = List;
    SourceTable = "Test Page DrillDown Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }

                field(StampCol; Rec.Descr)
                {
                    ApplicationArea = All;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        Marker: Record "Test Page DrillDown Row";
                    begin
                        if not Marker.Get('DRILL') then begin
                            Marker.Init();
                            Marker."No." := 'DRILL';
                            Marker.Descr := Rec."No.";
                            Marker.Insert();
                        end else begin
                            Marker.Descr := Rec."No.";
                            Marker.Modify();
                        end;
                    end;
                }

                field(OtherCol; Rec.Descr)
                {
                    ApplicationArea = All;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        Marker: Record "Test Page DrillDown Row";
                    begin
                        Marker.Init();
                        Marker."No." := 'OTHER';
                        Marker.Descr := 'other ran';
                        Marker.Insert();
                    end;
                }

                field(PlainCol; Rec.Descr)
                {
                    ApplicationArea = All;
                }

                field(FailCol; Rec.Descr)
                {
                    ApplicationArea = All;
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        Error('Test Page DrillDown control refused deliberately');
                    end;
                }
            }
        }
    }
}
