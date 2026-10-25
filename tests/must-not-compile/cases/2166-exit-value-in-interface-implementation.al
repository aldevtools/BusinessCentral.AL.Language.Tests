// @expect AL0139 | Since 'DoIt' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in a codeunit procedure that implements an interface method without a return type.
interface "MNC SH Iface"
{
    procedure DoIt();
}

codeunit 50001 "MNC SH Impl" implements "MNC SH Iface"
{
    procedure DoIt()
    begin
        exit(1);
    end;
}
