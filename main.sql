--главный сиквенс. можно было через генератор дефолт или олвейс, но сиквенс гибче)
CREATE SEQUENCE shop_db_main_seq 
    START WITH 1 
    INCREMENT BY 1 
    NOMAXVALUE 
    MINVALUE 1 
    NOCYCLE 
    nocache;

create table customers(
    customer_id number primary key,
    name varchar2(100) not null,
    email varchar2(100) not null,
    phone varchar2(20) not null,
    created_at date default sysdate not null
);

COMMENT ON TABLE customers IS 'таблицы для хранения данных клиента';
COMMENT ON COLUMN customers.customer_id IS 'идентификатор клиента, pk';
COMMENT ON COLUMN customers.name IS 'имя клиента';
COMMENT ON COLUMN customers.email IS 'адрес почты';
COMMENT ON COLUMN customers.phone IS 'номер телефона';
COMMENT ON COLUMN customers.created_at IS 'дата создания записи';


create table orders(
    order_id number primary key,
    customer_id number not null,
    order_date date default sysdate not null,
    total_amount number not null,
    constraint fk_customers foreign key (customer_id) references customers(customer_id)
);

COMMENT ON TABLE orders IS 'таблица для хранения данных о заказах';
COMMENT ON COLUMN orders.order_id IS 'идентификатор заказа, pk';
COMMENT ON COLUMN orders.customer_id IS 'идентификатор клиента или же заказчика customers.customer_id';
COMMENT ON COLUMN orders.order_date IS 'дата заказа';
COMMENT ON COLUMN orders.total_amount IS 'общая сумма заказа';

create table order_items(
    order_item_id number primary key,
    order_id number not null,
    product_name varchar2(100) not null,
    quantity number not null,
    price number not null,
    constraint fk_orders foreign key (order_id) references orders(order_id)
);

COMMENT ON TABLE order_items IS 'таблица для хранения данных товаров в заказе';
COMMENT ON COLUMN order_items.order_item_id IS 'идентификатор товра в заказе, pk';
COMMENT ON COLUMN order_items.order_id IS 'идентификатор заказа orders.order_id';
COMMENT ON COLUMN order_items.product_name IS 'название продукта';
COMMENT ON COLUMN order_items.quantity IS 'количество данного продукта';
COMMENT ON COLUMN order_items.price IS 'цена товара';