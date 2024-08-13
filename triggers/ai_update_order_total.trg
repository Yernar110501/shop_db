CREATE OR REPLACE TRIGGER ai_update_order_total_trg
AFTER INSERT ON order_items
FOR EACH ROW
DECLARE
    v_total_amount orders.total_amount%TYPE;
BEGIN
    SELECT SUM(quantity * price)
    INTO v_total_amount
    FROM order_items
    WHERE order_id = :NEW.order_id;

    UPDATE orders
    SET total_amount = v_total_amount
    WHERE order_id = :NEW.order_id;
EXCEPTION
    WHEN OTHERS THEN
        log_error(
            p_error_code    => SQLCODE,
            p_error_message => SQLERRM,
            p_procedure_name => 'trg_update_order_total'
        );
        RAISE;
END;