CREATE OR REPLACE PACKAGE custom_errors IS
    exc_user_exists               EXCEPTION;
    PRAGMA EXCEPTION_INIT(exc_user_exists, -20001);

    exc_email_exists              EXCEPTION;
    PRAGMA EXCEPTION_INIT(exc_email_exists, -20002);

    exc_phone_exists              EXCEPTION;
    PRAGMA EXCEPTION_INIT(exc_phone_exists, -20003);

    exc_customer_doesnt_exists    EXCEPTION;
    PRAGMA EXCEPTION_INIT(exc_customer_doesnt_exists, -20004);

    exc_invalid_xml_structure     EXCEPTION;
    PRAGMA EXCEPTION_INIT(exc_invalid_xml_structure, -20005);
END custom_errors;