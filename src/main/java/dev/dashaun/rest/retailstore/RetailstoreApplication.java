package dev.dashaun.rest.retailstore;

import dev.dashaun.rest.retailstore.domain.StoreGemfire;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.gemfire.config.annotation.EnableEntityDefinedRegions;
import org.springframework.geode.config.annotation.EnableClusterAware;

@EnableClusterAware
@EnableEntityDefinedRegions(basePackageClasses = StoreGemfire.class)
@SpringBootApplication
public class RetailstoreApplication {

	public static void main(String[] args) {
		SpringApplication.run(RetailstoreApplication.class, args);
	}

}
