package com.food.ordering.system.payment.service.domain;

import com.food.ordering.system.payment.service.domain.entity.CreditEntity;
import com.food.ordering.system.payment.service.domain.entity.CreditHistory;
import com.food.ordering.system.payment.service.domain.entity.Payment;
import com.food.ordering.system.payment.service.domain.event.PaymentEvent;

import java.util.List;

public interface PaymentDomainService {
    PaymentEvent validateAndInitiatePayment(Payment payment,
                                            CreditEntity creditEntity,
                                            List<CreditHistory> creditHistories,
                                            List<String> failureMessages);

    PaymentEvent validateAndCancelPayment(Payment payment,
                                          CreditEntity creditEntity,
                                          List<CreditHistory> creditHistories,
                                          List<String> failureMessages);
}
