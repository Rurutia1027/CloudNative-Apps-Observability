package com.food.ordering.system.payment.service.domain.ports.ouputs.repository;

import com.food.ordering.system.domain.valueobject.CustomerId;
import com.food.ordering.system.payment.service.domain.entity.CreditEntity;

import java.util.Optional;

public interface CreditEntryRepository {
    CreditEntity save(CreditEntity creditEntity);

      Optional<CreditEntity> findByCustomerId(CustomerId customerId);
}
