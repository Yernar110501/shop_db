
create or replace package body order_management is
    procedure create_customer(p_name  in varchar2, 
                              p_email in varchar2,
                              p_phone in varchar2) is
        l_email_count number;
        l_phone_count number;
    begin
        select count(*)
        into l_email_count
        from customers
        where email = p_email;

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
        values(shop_db_main_seq.nextval, p_name, p_email, p_phone);
        log_error(0, 'Customer created successfully', 'create_customer');
    
    exception
        when custom_errors.exc_email_exists then
            log_error(-20002, 'Email already exists: ' || p_email, 'create_customer');
            raise;
        when custom_errors.exc_phone_exists then
            log_error(-20003, 'Phone number already exists: ' || p_phone, 'create_customer');
            raise;
        when others then
            log_error(sqlcode, sqlerrm, 'create_customer');
            raise;
    end create_customer;
end order_management;