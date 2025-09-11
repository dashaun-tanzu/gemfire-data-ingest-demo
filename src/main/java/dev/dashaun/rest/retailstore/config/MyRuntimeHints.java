package dev.dashaun.rest.retailstore.config;

import dev.dashaun.rest.retailstore.domain.StoreGemfire;
import org.springframework.aot.hint.RuntimeHints;
import org.springframework.aot.hint.RuntimeHintsRegistrar;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.ImportRuntimeHints;
import org.springframework.data.gemfire.config.annotation.EnableEntityDefinedRegions;
import org.springframework.geode.config.annotation.EnableClusterAware;

@ImportRuntimeHints(MyRuntimeHints.MyRuntimeHintsRegistrar.class)
@Configuration
@EnableClusterAware
@EnableEntityDefinedRegions(basePackageClasses = StoreGemfire.class)
class MyRuntimeHints {

    static class MyRuntimeHintsRegistrar implements RuntimeHintsRegistrar {

        @Override
        public void registerHints(RuntimeHints hints, ClassLoader classLoader) {
            // Register resources
            hints.resources().registerPattern("Retail_Food_Stores.csv");
        }
    }
}
