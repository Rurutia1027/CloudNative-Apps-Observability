package com.food.ordering.system.order.service.domain;

import com.food.ordering.system.order.service.dataaccess.outbox.payment.entity.PaymentOutboxEntity;
import com.food.ordering.system.order.service.dataaccess.outbox.payment.repository.PaymentOutboxJpaRepository;
import com.food.ordering.system.order.service.domain.dto.message.PaymentResponse;
import com.food.ordering.system.saga.SagaStatus;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.context.jdbc.SqlConfig;
import org.springframework.test.context.jdbc.SqlGroup;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;

import static com.food.ordering.system.saga.order.SagaConstants.ORDER_SAGA_NAME;
import static org.junit.jupiter.api.Assertions.assertTrue;

@Slf4j
@SpringBootTest(classes = OrderServiceApplication.class)
@SqlGroup({
        @Sql(scripts = "classpath:sql/OrderPaymentSagaTestSchema.sql",
                config = @SqlConfig(separator = ";;"),
                executionPhase = Sql.ExecutionPhase.BEFORE_TEST_METHOD),
        @Sql(scripts = "classpath:sql/OrderPaymentSagaTestSetUp.sql", executionPhase = Sql.ExecutionPhase.BEFORE_TEST_METHOD),
        @Sql(scripts = "classpath:sql/OrderPaymentSagaTestCleanUp.sql", executionPhase = Sql.ExecutionPhase.AFTER_TEST_METHOD)
})
public class OrderPaymentSagaTest {
    @Autowired
    private OrderPaymentSaga orderPaymentSaga;


    @Autowired
    private PaymentOutboxJpaRepository paymentOutboxJpaRepository;

    private final UUID SAGA_ID = UUID.fromString("15a497c1-0f4b-4eff-b9f4-c402c8c07afa");
    private final UUID ORDER_ID = UUID.fromString("d215b5f8-0249-4dc5-89a3-51fd148cfb17");
    private final UUID CUSTOMER_ID = UUID.fromString("d215b5f8-0249-4dc5-89a3-51fd148cfb41");
    private final UUID PAYMENT_ID = UUID.randomUUID();
    private final BigDecimal PRICE = new BigDecimal("100");

    @Test
    void testDoublePayment() {
        orderPaymentSaga.process(getPaymentResponse());
        orderPaymentSaga.process(getPaymentResponse());
    }

    @Test
    void testDoublePaymentWithThreads() throws InterruptedException {
        Thread t1 = new Thread(() -> {
            orderPaymentSaga.process(getPaymentResponse());
        });
        Thread t2 = new Thread(() -> {
            orderPaymentSaga.process(getPaymentResponse());
        });
        t1.start();
        t2.start();

        t1.join();
        t2.join();


        assPaymentOutbox();
    }

    @Test
    void testDoublePaymentWithLatch() throws InterruptedException {
        CountDownLatch latch = new CountDownLatch(2);
         Thread t1 = new Thread(() -> {
             try {
                 orderPaymentSaga.process(getPaymentResponse());
             } catch (OptimisticLockingFailureException e) {
                 log.error("OptimisticLockingFailureException occurred for thread1");
             } finally {
                 latch.countDown();
             }
         });

         Thread t2 = new Thread(() -> {
             try {
                 orderPaymentSaga.process(getPaymentResponse());
             } catch (OptimisticLockingFailureException e) {
                 log.error("OptimisticLockingFailureException occurred for thread2");
             } finally {
                 latch.countDown();
             }
         });

         t1.start();
         t2.start();

        latch.await();

        assPaymentOutbox();
    }

    private void assPaymentOutbox() {
        Optional<PaymentOutboxEntity> paymentOutboxEntity =
                paymentOutboxJpaRepository.findByTypeAndSagaIdAndSagaStatusIn(ORDER_SAGA_NAME,
                        SAGA_ID, List.of(SagaStatus.PROCESSING));

        assertTrue(paymentOutboxEntity.isEmpty());
    }

    private PaymentResponse getPaymentResponse() {
        return PaymentResponse.builder()
                .id(UUID.randomUUID().toString())
                .sagaId(SAGA_ID.toString())
                .paymentStatus(com.food.ordering.system.domain.valueobject.PaymentStatus.COMPLETED)
                .paymentId(PAYMENT_ID.toString())
                .orderId(ORDER_ID.toString())
                .customerId(CUSTOMER_ID.toString())
                .price(PRICE)
                .createdAt(Instant.now())
                .failureMessages(new ArrayList<>())
                .build();
    }
}
