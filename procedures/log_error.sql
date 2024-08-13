create or replace procedure log_error (
    p_error_code    in number,
    p_error_message in varchar2,
    p_procedure_name in varchar2
    ) is
    pragma AUTONOMOUS_TRANSACTION;
begin
    insert into error_logs (
        error_code,
        error_message,
        procedure_name
    ) values (
        p_error_code,
        p_error_message,
        p_procedure_name
    );
        commit;
exception
    when others then
        rollback;
end log_error;