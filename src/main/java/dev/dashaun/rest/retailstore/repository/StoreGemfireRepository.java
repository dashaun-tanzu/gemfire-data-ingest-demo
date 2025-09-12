package dev.dashaun.rest.retailstore.repository;

import dev.dashaun.rest.retailstore.domain.StoreGemfire;
import org.springframework.data.gemfire.repository.GemfireRepository;

@ClientRegion("Stores")
public interface StoreGemfireRepository extends GemfireRepository<StoreGemfire, String> {
}
