create or replace package custom_errors is
    exc_user_exists exception;
    pragma exception_init(exc_user_exists, -20001);

    exc_email_exists exception;
    pragma exception_init(exc_email_exists, -20002);
    
    exc_phone_exists exception;
    pragma exception_init(exc_phone_exists, -20003);
end custom_errors;