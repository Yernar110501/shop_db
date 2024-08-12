# shop_db

Цель данного репозитория - создать фунциональные составляющие магазина на языке - PL/SQL. По инструкции ниже:

## Создайте следующие таблицы:
	•	Customers (Клиенты):
	•	Customer_ID (NUMBER) - первичный ключ
	•	Name (VARCHAR2(100))
	•	Email (VARCHAR2(100))
	•	Phone (VARCHAR2(20))
	•	Created_At (DATE)
	•	Orders (Заказы):
	•	Order_ID (NUMBER) - первичный ключ
	•	Customer_ID (NUMBER) - внешний ключ, ссылающийся на Customers.Customer_ID
	•	Order_Date (DATE)
	•	Total_Amount (NUMBER)
	•	Order_Items (Товары в заказе):
	•	Order_Item_ID (NUMBER) - первичный ключ
	•	Order_ID (NUMBER) - внешний ключ, ссылающийся на Orders.Order_ID
	•	Product_Name (VARCHAR2(100))
	•	Quantity (NUMBER)
	•	Price (NUMBER)
 ![Пустой диаграммой](https://github.com/user-attachments/assets/f413c676-215b-46ae-9259-f1105db63c3f)

