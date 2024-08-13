
create or replace package body order_management is
--*************************
    procedure create_customer(p_name  in varchar2, 
                              p_email in varchar2,
                              p_phone in varchar2) is
        l_email_count number;
        l_phone_count number;
    begin
        select count(*)
        into l_email_count
        from customers
        where email = upper(p_email);

        if l_email_count > 0 then
            raise custom_errors.exc_email_exists;
        end if;

        select count(*)
        into l_phone_count
        from customers
        where phone = p_phone;

        if l_phone_count > 0 then
            raise custom_errors.exc_phone_exists;
        end if;

        insert into customers(customer_id, name, email, phone)
        values(shop_db_main_seq.nextval, p_name, upper(p_email), p_phone);
        log_error(0, 'customer created successfully', 'create_customer');
    
    exception
        when custom_errors.exc_email_exists then
            log_error(-20002, 'email already exists: ' || p_email, 'create_customer');
            raise;
        when custom_errors.exc_phone_exists then
            log_error(-20003, 'phone number already exists: ' || p_phone, 'create_customer');
            raise;
        when others then
            log_error(sqlcode, sqlerrm, 'create_customer');
            raise;
    end create_customer;
--*************************
procedure create_order (p_customer_id  in  number,
                        p_order_date   in  date,
                        p_items        in  sys_refcursor) as
    v_order_id      orders.order_id%type;
    v_total_amount  orders.total_amount%type := 0;
    v_product_name  order_items.product_name%type;
    v_quantity      order_items.quantity%type;
    v_price         order_items.price%type;
begin
    declare
        v_exists number;
    begin
        select count(*) into v_exists
        from customers
        where customer_id = p_customer_id;

        if v_exists = 0 then
            raise custom_errors.exc_customer_doesnt_exists;
        end if;
    end;

    insert into orders (order_id, customer_id, order_date, total_amount)
    values (shop_db_main_seq.nextval, p_customer_id, p_order_date, 0)
    returning order_id into v_order_id;

    loop
        fetch p_items into v_product_name, v_quantity, v_price;
        exit when p_items%notfound;

        insert into order_items (order_item_id, order_id, product_name, quantity, price)
        values (shop_db_main_seq.nextval, v_order_id, v_product_name, v_quantity, v_price);
        v_total_amount := v_total_amount + (v_quantity * v_price);
    end loop;
    close p_items;

    update orders
    set total_amount = v_total_amount
    where order_id = v_order_id;

    commit;
exception
    when custom_errors.exc_customer_doesnt_exists then
        log_error(
            p_error_code    => -20004,
            p_error_message => 'customer does not exist',
            p_procedure_name => 'create_order'
        );
        raise;
    when others then
        log_error(
            p_error_code    => sqlcode,
            p_error_message => sqlerrm,
            p_procedure_name => 'create_order'
        );
        rollback;
        raise;
end create_order;
--*************************
procedure parse_order_data(
    xml_data        in  clob,
    p_customer_id   out number,
    p_order_date    out date,
    p_items         out sys_refcursor
) as
begin
    if xmlcast(xmlquery('Order/Customer_ID/text()' passing xmltype(xml_data)) as number) is null
        or xmlcast(xmlquery('Order/Order_Date/text()' passing xmltype(xml_data)) as date) is null then
        raise custom_errors.exc_invalid_xml_structure;
    end if;

    select 
        xmlcast(xmlquery('Order/Customer_ID/text()' passing xmltype(xml_data)) as number),
        xmlcast(xmlquery('Order/Order_Date/text()' passing xmltype(xml_data)) as date)
    into p_customer_id, p_order_date
    from dual;

    open p_items for
        select 
            xmlcast(xmlquery('Product_Name/text()' passing x) as varchar2(100)) as product_name,
            xmlcast(xmlquery('Quantity/text()' passing x) as number) as quantity,
            xmlcast(xmlquery('Price/text()' passing x) as number) as price
        from xmltable('/Order/Items/Item' passing xmltype(xml_data) columns x xmltype path '.');
exception
    when custom_errors.exc_invalid_xml_structure then
        log_error(
            p_error_code    => -20005,
            p_error_message => 'invalid xml structure',
            p_procedure_name => 'parse_order_data'
        );
        raise;
    when others then
        log_error(
            p_error_code    => sqlcode,
            p_error_message => sqlerrm,
            p_procedure_name => 'parse_order_data'
        );
        raise;
end parse_order_data;
--*************************
procedure create_order_from_xml(p_xml in clob) as 
 v_customer_id  number;
 v_order_date   date;
 v_items        sys_refcursor;
begin
    parse_order_data(p_xml, v_customer_id, v_order_date, v_items);

    insert_order_data(v_customer_id, v_order_date, v_items);
  
end create_order_from_xml;
--*************************
function get_customer_orders ( p_customer_id in number) return sys_refcursor is
v_exists number;
  l_cursor sys_refcursor;
begin
    select count(*) into v_exists
    from customers
    where customer_id = p_customer_id;
  
    if v_exists = 0 then
        raise custom_errors.exc_customer_doesnt_exists;
    end if;
 
  open l_cursor for
    select order_id, order_date, total_amount
    from orders
    where customer_id = p_customer_id;
  return l_cursor;
exception
    when custom_errors.exc_customer_doesnt_exists then
        log_error(
            p_error_code    => -20004,
            p_error_message => 'customer does not exist',
            p_procedure_name => 'get_customer_orders'
        );
        raise;
    when others then
        log_error(
            p_error_code    => sqlcode,
            p_error_message => sqlerrm,
            p_procedure_name => 'get_customer_orders'
        );
        raise;
end;
--*************************
function get_customer_orders_xml (p_customer_id in number) 
return clob 
is
  l_cursor sys_refcursor;
  l_xml clob;
begin
  l_cursor := get_customer_orders(p_customer_id);

  if l_cursor is not null then
    select xmlelement(
             "orders",
             xmlagg(
               xmlelement(
                 "order",
                 xmlforest(
                   order_id as "id",
                   order_date as "date",
                   total_amount as "total_amount"
                 )
               )
             )
           ).getclobval()
    into l_xml
    from table(
             xmltable(
               '/orders/order'
               passing xmltype(l_cursor)
             )
           );

    return l_xml;
  else
    return null;
  end if;
exception
  when others then
    log_error(
      p_error_code    => sqlcode,
      p_error_message => sqlerrm,
      p_procedure_name => 'get_customer_orders_as_xml'
    );
    return null;
end;
--*************************
--*************************

end order_management;