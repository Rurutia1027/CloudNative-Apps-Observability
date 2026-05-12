package com.food.ordering.system.order.service.application.exception.handler;

import com.food.ordering.system.order.service.domain.exception.OrderDomainException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.ControllerAdvice;

@Slf4j
@ControllerAdvice
public class OrderGlobalExceptionHandler {
    public ErrorDTO handleException(OrderDomainException orderDomainException) {

    }
}
