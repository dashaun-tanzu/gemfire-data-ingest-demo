package dev.dashaun.rest.retailstore.controller;

import dev.dashaun.rest.retailstore.domain.StoreJPA;
import dev.dashaun.rest.retailstore.repository.StoreGemfireRepository;
import dev.dashaun.rest.retailstore.repository.StoreJPARepository;
import dev.dashaun.rest.retailstore.util.CSVLoader;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

@RestController
public class RetailStoreController {
    private final StoreGemfireRepository gemfireRepository;
    private final StoreJPARepository jpaRepository;
    private final CSVLoader csvLoader;
    
    public RetailStoreController(StoreGemfireRepository gemfireRepository,
                                 StoreJPARepository jpa,
    @Value("classpath:/Retail_Food_Stores.csv") Resource csv){
        this.gemfireRepository = gemfireRepository;
        this.jpaRepository = jpa;
        csvLoader = new CSVLoader(csv);
    }

    @GetMapping("/load-gemfire")
    public void loadGemfire(){
        csvLoader.gemfire(gemfireRepository);
    }

    @GetMapping("/load-jpa")
    public void loadJpa(){
        csvLoader.jpa(jpaRepository);
    }

    @GetMapping("/get-jpa-by-id/{id}")
    public Optional<StoreJPA> jpaById(@PathVariable String id){
        return jpaRepository.findById(id);
    }
}