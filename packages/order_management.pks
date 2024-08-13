create or replace package order_management is
--*************************
    procedure create_customer(p_name  in varchar2, 
    						  p_email in varchar2,
    						  p_phone in varchar2);
--*************************
    procedure create_order_from_xml(p_xml in clob);
--*************************
    function get_customer_orders ( p_customer_id in number) return sys_refcursor;
--*************************
    function get_customer_orders_xml (p_customer_id in number) return clob;
--*************************
procedure update_order_total (p_order_id in number);
--*************************
--*************************
--*************************
end order_management;