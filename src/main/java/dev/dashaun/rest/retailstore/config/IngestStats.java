package dev.dashaun.rest.retailstore.config;

import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class IngestStats {

    private final Map<String, Double> loadSeconds = new ConcurrentHashMap<>();

    public void record(String loadType, double seconds) {
        loadSeconds.put(loadType, seconds);
    }

    public Map<String, Double> getLoadSeconds() {
        return new LinkedHashMap<>(loadSeconds);
    }
}
