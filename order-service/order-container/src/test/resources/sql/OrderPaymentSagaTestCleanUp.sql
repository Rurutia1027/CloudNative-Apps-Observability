delete
from "order".restaurant_approval_outbox
where saga_id = '15a497c1-0f4b-4eff-b9f4-c402c8c07afa';

delete
from "order".payment_outbox
where saga_id = '15a497c1-0f4b-4eff-b9f4-c402c8c07afa';

delete
from "order".orders
where id = 'd215b5f8-0249-4dc5-89a3-51fd148cfb17';