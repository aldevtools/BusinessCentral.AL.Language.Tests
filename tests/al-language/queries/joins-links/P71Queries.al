// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: tables 72622-72624
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: query fixtures for the P71 outer join probes (Item parent, Loc child, three-level shape, aggregates)
// BC versions: 29 (27 and 28 by CI)

query 72626 "LT P71 Q Inner"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72627 "LT P71 Q Left"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72628 "LT P71 Q Right"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = RightOuterJoin;
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72629 "LT P71 Q Full"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = FullOuterJoin;
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72630 "LT P71 Q Inner Static"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;
                DataItemTableFilter = Active = const(true);
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72631 "LT P71 Q Left Static"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                DataItemTableFilter = Active = const(true);
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72632 "LT P71 Q Right Static"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = RightOuterJoin;
                DataItemTableFilter = Active = const(true);
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72633 "LT P71 Q Full Static"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = FullOuterJoin;
                DataItemTableFilter = Active = const(true);
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72634 "LT P71 Q Cross"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                SqlJoinType = CrossJoin;
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72635 "LT P71 Q Cross Static"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                SqlJoinType = CrossJoin;
                DataItemTableFilter = Active = const(true);
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72636 "LT P71 Q Left ParFilter"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            DataItemTableFilter = Grp = const('G1');
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72637 "LT P71 Q Right ParFilter"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            DataItemTableFilter = Grp = const('G1');
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = RightOuterJoin;
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72638 "LT P71 Q Full ParFilter"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            DataItemTableFilter = Grp = const('G1');
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = FullOuterJoin;
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72639 "LT P71 Q Left Rank"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                DataItemTableFilter = Rank = filter(>=2);
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72640 "LT P71 Q Full Rank"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = FullOuterJoin;
                DataItemTableFilter = Rank = filter(>=2);
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72641 "LT P71 Q Left Zone"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                DataItemTableFilter = Zone = const('N');
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72642 "LT P71 Q Left ZoneBlank"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                DataItemTableFilter = Zone = const('');
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72643 "LT P71 Q Left Both"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            DataItemTableFilter = Grp = const('G1');
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                DataItemTableFilter = Active = const(true);
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72644 "LT P71 Q Full Both"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            DataItemTableFilter = Grp = const('G1');
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = FullOuterJoin;
                DataItemTableFilter = Active = const(true);
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72645 "LT P71 Q Left Desc"
{
    QueryType = Normal;
    OrderBy = descending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72646 "LT P71 Q Right Asc Rank"
{
    QueryType = Normal;
    OrderBy = ascending(LocRank);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = RightOuterJoin;
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72647 "LT P71 Q Full Desc Rank"
{
    QueryType = Normal;
    OrderBy = descending(LocRank);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = FullOuterJoin;
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72648 "LT P71 Q Full Desc Item"
{
    QueryType = Normal;
    OrderBy = descending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = FullOuterJoin;
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72649 "LT P71 Q Left Stat Desc"
{
    QueryType = Normal;
    OrderBy = descending(ItemNo);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }
            column(ItemName; Name) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                DataItemTableFilter = Active = const(true);
                column(LocCode; "Code") { }
                column(LocName; Name) { }
                column(LocRank; Rank) { }
                column(LocCost; Cost) { }
                column(LocSince; Since) { }
                column(LocActive; Active) { }
                column(LocZone; Zone) { }
                column(LocItem; ItemNo) { }
            }
        }
    }
}

query 72650 "LT P71 S Inner Zone"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LineId);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;
                column(LineId; Id) { }
                column(LineQty; Qty) { }

                dataitem(LocRow; "LT P71 Loc")
                {
                    DataItemLink = "Code" = LineRow.LocCode;
                    SqlJoinType = InnerJoin;
                    DataItemTableFilter = Zone = const('N');
                    column(LocCode; "Code") { }
                    column(LocName; Name) { }
                    column(LocZone; Zone) { }
                    column(LocActive; Active) { }
                }
            }
        }
    }
}

query 72651 "LT P71 S Left Zone"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LineId);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;
                column(LineId; Id) { }
                column(LineQty; Qty) { }

                dataitem(LocRow; "LT P71 Loc")
                {
                    DataItemLink = "Code" = LineRow.LocCode;
                    SqlJoinType = LeftOuterJoin;
                    DataItemTableFilter = Zone = const('N');
                    column(LocCode; "Code") { }
                    column(LocName; Name) { }
                    column(LocZone; Zone) { }
                    column(LocActive; Active) { }
                }
            }
        }
    }
}

query 72652 "LT P71 S Right Zone"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LineId);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;
                column(LineId; Id) { }
                column(LineQty; Qty) { }

                dataitem(LocRow; "LT P71 Loc")
                {
                    DataItemLink = "Code" = LineRow.LocCode;
                    SqlJoinType = RightOuterJoin;
                    DataItemTableFilter = Zone = const('N');
                    column(LocCode; "Code") { }
                    column(LocName; Name) { }
                    column(LocZone; Zone) { }
                    column(LocActive; Active) { }
                }
            }
        }
    }
}

query 72653 "LT P71 S Full Zone"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LineId);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;
                column(LineId; Id) { }
                column(LineQty; Qty) { }

                dataitem(LocRow; "LT P71 Loc")
                {
                    DataItemLink = "Code" = LineRow.LocCode;
                    SqlJoinType = FullOuterJoin;
                    DataItemTableFilter = Zone = const('N');
                    column(LocCode; "Code") { }
                    column(LocName; Name) { }
                    column(LocZone; Zone) { }
                    column(LocActive; Active) { }
                }
            }
        }
    }
}

query 72654 "LT P71 S Left None"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LineId);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;
                column(LineId; Id) { }
                column(LineQty; Qty) { }

                dataitem(LocRow; "LT P71 Loc")
                {
                    DataItemLink = "Code" = LineRow.LocCode;
                    SqlJoinType = LeftOuterJoin;
                    column(LocCode; "Code") { }
                    column(LocName; Name) { }
                    column(LocZone; Zone) { }
                    column(LocActive; Active) { }
                }
            }
        }
    }
}

query 72655 "LT P71 S Left Codes"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LineId);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;
                column(LineId; Id) { }
                column(LineQty; Qty) { }

                dataitem(LocRow; "LT P71 Loc")
                {
                    DataItemLink = "Code" = LineRow.LocCode;
                    SqlJoinType = LeftOuterJoin;
                    DataItemTableFilter = "Code" = filter('L1|L3');
                    column(LocCode; "Code") { }
                    column(LocName; Name) { }
                    column(LocZone; Zone) { }
                    column(LocActive; Active) { }
                }
            }
        }
    }
}

query 72656 "LT P71 S Left NonBlank"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LineId);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;
                column(LineId; Id) { }
                column(LineQty; Qty) { }

                dataitem(LocRow; "LT P71 Loc")
                {
                    DataItemLink = "Code" = LineRow.LocCode;
                    SqlJoinType = LeftOuterJoin;
                    DataItemTableFilter = "Code" = filter(<>'');
                    column(LocCode; "Code") { }
                    column(LocName; Name) { }
                    column(LocZone; Zone) { }
                    column(LocActive; Active) { }
                }
            }
        }
    }
}

query 72657 "LT P71 S Left ParFilter"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LineId);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            DataItemTableFilter = Grp = const('G1');
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;
                column(LineId; Id) { }
                column(LineQty; Qty) { }

                dataitem(LocRow; "LT P71 Loc")
                {
                    DataItemLink = "Code" = LineRow.LocCode;
                    SqlJoinType = LeftOuterJoin;
                    DataItemTableFilter = Zone = const('N');
                    column(LocCode; "Code") { }
                    column(LocName; Name) { }
                    column(LocZone; Zone) { }
                    column(LocActive; Active) { }
                }
            }
        }
    }
}

query 72658 "LT P71 S LineLeft Zone"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LineId);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                column(LineId; Id) { }
                column(LineQty; Qty) { }

                dataitem(LocRow; "LT P71 Loc")
                {
                    DataItemLink = "Code" = LineRow.LocCode;
                    SqlJoinType = InnerJoin;
                    DataItemTableFilter = Zone = const('N');
                    column(LocCode; "Code") { }
                    column(LocName; Name) { }
                    column(LocZone; Zone) { }
                    column(LocActive; Active) { }
                }
            }
        }
    }
}

query 72659 "LT P71 S Group Left"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;

                dataitem(LocRow; "LT P71 Loc")
                {
                    DataItemLink = "Code" = LineRow.LocCode;
                    SqlJoinType = LeftOuterJoin;
                    DataItemTableFilter = Zone = const('N');
                    column(LocCode; "Code") { }
                    column(Cnt) { Method = Count; }
                }
            }
        }
    }
}

query 72660 "LT P71 S Group Inner"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;

                dataitem(LocRow; "LT P71 Loc")
                {
                    DataItemLink = "Code" = LineRow.LocCode;
                    SqlJoinType = InnerJoin;
                    DataItemTableFilter = Zone = const('N');
                    column(LocCode; "Code") { }
                    column(Cnt) { Method = Count; }
                }
            }
        }
    }
}

query 72661 "LT P71 S Group Full"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo), ascending(LocCode);

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;

                dataitem(LocRow; "LT P71 Loc")
                {
                    DataItemLink = "Code" = LineRow.LocCode;
                    SqlJoinType = FullOuterJoin;
                    DataItemTableFilter = Zone = const('N');
                    column(LocCode; "Code") { }
                    column(Cnt) { Method = Count; }
                }
            }
        }
    }
}

query 72662 "LT P71 A Grp Inner"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72663 "LT P71 A Grp Left"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72664 "LT P71 A Grp Right"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = RightOuterJoin;
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72665 "LT P71 A Grp Full"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = FullOuterJoin;
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72666 "LT P71 A Grp Left Static"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                DataItemTableFilter = Active = const(true);
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72667 "LT P71 A Grp Right Static"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = RightOuterJoin;
                DataItemTableFilter = Active = const(true);
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72668 "LT P71 A Grp Full Static"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = FullOuterJoin;
                DataItemTableFilter = Active = const(true);
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72669 "LT P71 A Tot Inner"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = InnerJoin;
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72670 "LT P71 A Tot Left"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72671 "LT P71 A Tot Right"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = RightOuterJoin;
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72672 "LT P71 A Tot Full"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = FullOuterJoin;
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72673 "LT P71 A Tot Left Static"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                DataItemTableFilter = Active = const(true);
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72674 "LT P71 A Tot Right Static"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = RightOuterJoin;
                DataItemTableFilter = Active = const(true);
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72675 "LT P71 A Zone Left"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                column(LocZone; Zone) { }
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72676 "LT P71 A Zone Full"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {

            dataitem(LocRow; "LT P71 Loc")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = FullOuterJoin;
                column(LocZone; Zone) { }
                column(CntAll) { Method = Count; }
                column(SumCost; Cost) { Method = Sum; }
                column(MinRank; Rank) { Method = Min; }
                column(MaxRank; Rank) { Method = Max; }
                column(AvgCost; Cost) { Method = Average; }
            }
        }
    }
}

query 72677 "LT P71 A Line Left"
{
    QueryType = Normal;

    elements
    {
        dataitem(ItemRow; "LT P71 Item")
        {
            column(ItemNo; No) { }

            dataitem(LineRow; "LT P71 Line")
            {
                DataItemLink = ItemNo = ItemRow.No;
                SqlJoinType = LeftOuterJoin;
                column(CntAll) { Method = Count; }
                column(SumQty; Qty) { Method = Sum; }
                column(MinQty; Qty) { Method = Min; }
                column(MaxQty; Qty) { Method = Max; }
                column(AvgQty; Qty) { Method = Average; }
            }
        }
    }
}
