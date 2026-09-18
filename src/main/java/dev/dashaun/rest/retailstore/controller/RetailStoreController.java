package dev.dashaun.rest.retailstore.controller;

import dev.dashaun.rest.retailstore.config.IngestStats;
import dev.dashaun.rest.retailstore.domain.StoreJPA;
import dev.dashaun.rest.retailstore.repository.StoreGemfireRepository;
import dev.dashaun.rest.retailstore.repository.StoreJPARepository;
import dev.dashaun.rest.retailstore.util.CSVLoader;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

@RestController
public class RetailStoreController {
    private final StoreGemfireRepository gemfireRepository;
    private final StoreJPARepository jpaRepository;
    private final CSVLoader csvLoader;
    private final IngestStats ingestStats;

    public RetailStoreController(StoreGemfireRepository gemfireRepository,
                                 StoreJPARepository jpa,
                                 IngestStats ingestStats,
                                 @Value("classpath:/Retail_Food_Stores.csv") Resource csv) {
        this.gemfireRepository = gemfireRepository;
        this.jpaRepository = jpa;
        this.csvLoader = new CSVLoader(csv);
        this.ingestStats = ingestStats;
    }

    @GetMapping("/load-gemfire")
    void loadGemfire() {
        long start = System.nanoTime();
        csvLoader.gemfire(gemfireRepository);
        ingestStats.record("gemfire", secondsSince(start));
    }

    @GetMapping("/load-jpa")
    void loadJpa() {
        long start = System.nanoTime();
        csvLoader.jpa(jpaRepository);
        ingestStats.record("jpa", secondsSince(start));
    }

    @GetMapping("/load-jpa-batch")
    void loadJpaBatch() {
        long start = System.nanoTime();
        csvLoader.jpaBatch(jpaRepository);
        ingestStats.record("jpaBatch", secondsSince(start));
    }

    @GetMapping("/get-jpa-by-id/{id}")
    Optional<StoreJPA> jpaById(@PathVariable String id) {
        return jpaRepository.findById(id);
    }

    @GetMapping("/get-jpa-count")
    Long jpaCount() {
        return jpaRepository.count();
    }

    @GetMapping("/get-gemfire-count")
    Long gemfireCount() {
        return gemfireRepository.count();
    }

    @GetMapping("/stats")
    Map<String, Object> stats() {
        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("jpaCount", jpaRepository.count());
        stats.put("gemfireCount", gemfireRepository.count());
        stats.put("loadSeconds", ingestStats.getLoadSeconds());
        return stats;
    }

    private static double secondsSince(long startNanos) {
        return (System.nanoTime() - startNanos) / 1_000_000_000.0;
    }
}
