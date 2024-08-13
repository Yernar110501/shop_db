create or replace procedure log_network (
    p_request_body    in clob,
    p_response_body   in clob,
    p_response_time   in timestamp,
    p_status_code     in number,
    p_error_message   in varchar2,
    p_procedure_name  in varchar2
) is
    pragma autonomous_transaction;
begin
    insert into network_log (
        request_body,
        response_body,
        response_time,
        status_code,
        error_message,
        procedure_name
    ) values (
        p_request_body,
        p_response_body,
        p_response_time,
        p_status_code,
        p_error_message,
        p_procedure_name
    );

    commit;
exception
    when others then
        rollback;
        raise;
end;