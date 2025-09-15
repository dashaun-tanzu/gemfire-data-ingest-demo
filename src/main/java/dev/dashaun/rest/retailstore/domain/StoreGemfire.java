package dev.dashaun.rest.retailstore.domain;

import org.springframework.data.annotation.Id;
import lombok.Builder;
import org.springframework.data.gemfire.mapping.annotation.Region;

@Builder
@Region(name = "stores")
public class StoreGemfire {
    @Id
    private String License_Number;
    private String County;
    private String Operation_Type;
    private String Establishment_Type;
    private String Entity_Name;
    private String DBA_Name;
    private String Street_Number;
    private String Street_Name;
    private String Address_Line_2;
    private String Address_Line_3;
    private String City;
    private String State;
    private String Zip_Code;
    private String Square_Footage;
    private String Georeference;
}
