create or replace package custom_errors is
    exc_user_exists exception;
    pragma exception_init(exc_user_exists, -20001);

    exc_email_exists exception;
    pragma exception_init(exc_email_exists, -20002);
    
    exc_phone_exists exception;
    pragma exception_init(exc_phone_exists, -20003);

    exc_customer_doesnt_exists exception;
    pragma exception_init(exc_customer_doesnt_exists, -20004);

    exc_invalid_xml_structure exception;
    pragma exception_init(exc_invalid_xml_structure, -20005);
    
end custom_errors;