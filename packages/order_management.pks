create or replace package order_management is
--*************************
    procedure create_customer(p_name  in varchar2, 
    						  p_email in varchar2,
    						  p_phone in varchar2);
--*************************
    procedure create_order_from_xml(p_xml in clob);
--*************************
--*************************
--*************************
--*************************
--*************************
--*************************
end order_management;