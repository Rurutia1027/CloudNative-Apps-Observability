package com.food.ordering.system.order.service.dataaccess.restaurant.repository;

import com.food.ordering.system.order.service.dataaccess.restaurant.entity.RestaurantEntity;
import com.food.ordering.system.order.service.dataaccess.restaurant.entity.RestaurantEntityId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface RestaurantJpaRepository extends JpaRepository<RestaurantEntity, RestaurantEntityId> {
    /**
     * Spring Data keyword {@code In} maps to SQL {@code IN (...)}; {@code findByRestaurantIdAndProductId}
     * would treat the second argument as a scalar productId and fails for {@link List}.
     */
    List<RestaurantEntity> findByRestaurantIdAndProductIdIn(UUID restaurantId, List<UUID> productIds);
}
