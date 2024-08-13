
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

    -- update orders
    -- set total_amount = v_total_amount
    -- where order_id = v_order_id;
    update_order_total(v_order_id);

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
procedure update_order_total (
    p_order_id in number
) as
    v_total_amount orders.total_amount%type := 0;
begin
    select sum(quantity * price)
    into v_total_amount
    from order_items
    where order_id = p_order_id;

    update orders
    set total_amount = v_total_amount
    where order_id = p_order_id;

    commit;
exception
    when others then
        log_error(
            p_error_code    => sqlcode,
            p_error_message => sqlerrm,
            p_procedure_name => 'update_order_total'
        );
        rollback;
        raise;
end update_order_total;
--*************************
procedure build_request_body (
    p_order_id      in number,
    p_customer_id   in number,
    p_response_body out clob
) is
begin
    select json_object(
               'order_id'      value p_order_id,
               'customer_id'   value p_customer_id,
               'order_date'    value (select o.order_date
                                      from orders o
                                      where o.order_id = p_order_id
                                        and o.customer_id = p_customer_id),
               'total_amount'  value (select o.total_amount
                                      from orders o
                                      where o.order_id = p_order_id
                                        and o.customer_id = p_customer_id),
               'items'         value (
                   select json_arrayagg(
                              json_object(
                                  'product_name' value oi.product_name,
                                  'quantity'     value oi.quantity,
                                  'price'        value oi.price
                              )
                   )
                   from order_items oi
                   where oi.order_id = p_order_id
               )
           ) into p_response_body
    from dual;
end build_request_body;
--*************************
procedure sync_order_with_api (
    p_order_id        in number,
    p_customer_id     in number
) is
    l_url             varchar2(4000) := 'http://example.com/api/orders';
    l_http_req        utl_http.req;
    l_http_resp       utl_http.resp;
    l_request_body    clob;
    l_response_body   clob;
    l_status_code     number;
    l_start_time      timestamp := systimestamp;
    l_end_time        timestamp;
    l_error_message   varchar2(4000);
begin
    build_request_body(
        p_order_id      => p_order_id,
        p_customer_id   => p_customer_id,
        p_order_date    => p_order_date,
        p_total_amount  => p_total_amount,
        p_response_body => l_request_body
    );

    begin
        l_http_req := utl_http.begin_request(
            p_url          => l_url,
            p_http_method   => 'POST',
            p_http_version  => 'HTTP/1.1'
        );

        utl_http.set_header(l_http_req, 'Content-Type', 'application/json');
        -- UTL_HTTP.set_header(l_http_req, 'Authorization', 'Basic ' || UTL_ENCODE.base64_encode('your_username:your_password'));--если будут данные для авторизации, хотя это только для базовой авторизаци

        utl_http.write_text(l_http_req, l_request_body);

        l_http_resp := utl_http.get_response(l_http_req);
        l_status_code := l_http_resp.status_code;

        utl_http.read_text(l_http_resp, l_response_body);
        utl_http.end_response(l_http_resp);

        l_end_time := systimestamp;

        log_network(
            p_request_body    => l_request_body,
            p_response_body   => l_response_body,
            p_response_time   => l_end_time,
            p_status_code     => l_status_code,
            p_error_message   => null,
            p_procedure_name  => 'sync_order_with_api'
        );

        if l_status_code != 200 then
            l_error_message := 'api returned error status code ' || l_status_code;
            raise custom_errors.exc_api_error;
        end if;

    exception
        when utl_http.end_of_body then
            l_response_body := 'end of body reached prematurely.';
            l_status_code := -1;
            l_error_message := 'end of body reached prematurely.';

            log_error(
                p_error_code    => l_status_code,
                p_error_message => l_error_message,
                p_procedure_name => 'sync_order_with_api'
            );
            
            log_network(
                p_request_body    => l_request_body,
                p_response_body   => l_response_body,
                p_response_time   => systimestamp,
                p_status_code     => l_status_code,
                p_error_message   => l_error_message,
                p_procedure_name  => 'sync_order_with_api'
            );

        when custom_errors.exc_api_error then
            log_error(
                p_error_code    => l_status_code,
                p_error_message => l_error_message,
                p_procedure_name => 'sync_order_with_api'
            );

            log_network(
                p_request_body    => l_request_body,
                p_response_body   => l_response_body,
                p_response_time   => systimestamp,
                p_status_code     => l_status_code,
                p_error_message   => l_error_message,
                p_procedure_name  => 'sync_order_with_api'
            );
            
        when others then
            l_response_body := sqlerrm;
            l_status_code := sqlcode;
            l_error_message := sqlerrm;

            log_error(
                p_error_code    => l_status_code,
                p_error_message => l_error_message,
                p_procedure_name => 'sync_order_with_api'
            );

            log_network(
                p_request_body    => l_request_body,
                p_response_body   => l_response_body,
                p_response_time   => systimestamp,
                p_status_code     => l_status_code,
                p_error_message   => l_error_message,
                p_procedure_name  => 'sync_order_with_api'
            );
            
            raise;
    end;
end;

end order_management;