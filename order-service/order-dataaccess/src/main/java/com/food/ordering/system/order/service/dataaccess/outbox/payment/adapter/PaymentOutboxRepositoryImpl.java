package com.food.ordering.system.order.service.dataaccess.outbox.payment.adapter;

import com.food.ordering.system.order.service.dataaccess.outbox.payment.exception.PaymentOutboxNotFoundException;
import com.food.ordering.system.order.service.dataaccess.outbox.payment.mapper.PaymentOutboxDataAccessMapper;
import com.food.ordering.system.order.service.dataaccess.outbox.payment.repository.PaymentOutboxJpaRepository;
import com.food.ordering.system.order.service.domain.outbox.model.payment.OrderPaymentOutboxMessage;
import com.food.ordering.system.order.service.domain.ports.outputs.repository.PaymentOutboxRepository;
import com.food.ordering.system.outbox.OutboxStatus;
import com.food.ordering.system.saga.SagaStatus;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
public class PaymentOutboxRepositoryImpl implements PaymentOutboxRepository {
    private final PaymentOutboxRepository paymentOutboxRepository;
    private final PaymentOutboxDataAccessMapper paymentOutboxDataAccessMapper;
    private final PaymentOutboxJpaRepository paymentOutboxJpaRepository;

    public PaymentOutboxRepositoryImpl(PaymentOutboxRepository paymentOutboxRepository,
                                       PaymentOutboxDataAccessMapper paymentOutboxDataAccessMapper, PaymentOutboxJpaRepository paymentOutboxJpaRepository) {
        this.paymentOutboxRepository = paymentOutboxRepository;
        this.paymentOutboxDataAccessMapper = paymentOutboxDataAccessMapper;
        this.paymentOutboxJpaRepository = paymentOutboxJpaRepository;
    }

    @Override
    public OrderPaymentOutboxMessage save(OrderPaymentOutboxMessage orderPaymentOutboxMessage) {
        return paymentOutboxDataAccessMapper
                .paymentOutboxMessageToOrderPaymentOutboxMessage(paymentOutboxJpaRepository
                        .save(paymentOutboxDataAccessMapper
                                .orderPaymentOutboxMessageToOutboxEntity(orderPaymentOutboxMessage)));
    }

    @Override
    public Optional<List<OrderPaymentOutboxMessage>>
    findByTypeAndOutboxStatusAndSagaStatus(String sagaType,
                                           OutboxStatus outboxStatus,
                                           SagaStatus... sagaStatus) {
        return Optional.of(paymentOutboxJpaRepository.findByTypeAndOutboxStatusAndSagaStatusIn(
                        sagaType,
                        outboxStatus,
                        Arrays.asList(sagaStatus))
                .orElseThrow(() -> new PaymentOutboxNotFoundException("Payment outbox object" +
                        " could not be found for saga type " + sagaType))
                .stream().map(paymentOutboxDataAccessMapper::paymentOutboxMessageToOrderPaymentOutboxMessage)
                .collect(Collectors.toList()));

    }

    @Override
    public Optional<OrderPaymentOutboxMessage>
    findByTypeAndSagaIdAndSagaStatus(String sagaType,
                                     UUID sagaId,
                                     SagaStatus... sagaStatuses) {
        return paymentOutboxJpaRepository
                .findByTypeAndSagaIdAndSagaStatusIn(sagaType, sagaId, Arrays.asList(sagaStatuses))
                .map(paymentOutboxDataAccessMapper::paymentOutboxEntityToOrderPaymentOutboxMessage);
    }

    @Override
    public void deleteByTypeAndOutboxStatusAndSagaStatus(String type,
                                                         OutboxStatus outboxStatus,
                                                         SagaStatus... sagaStatuses) {
        paymentOutboxJpaRepository.deleteByTypeAndOutboxStatusAndSagaStatusIn(type,
                outboxStatus,
                Arrays.asList(sagaStatuses));
    }
}
