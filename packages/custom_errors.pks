create or replace package custom_errors is

    exc_user_exists exception;
	pragma exception_init(exc_user_exists, -20001);

end custom_errors;