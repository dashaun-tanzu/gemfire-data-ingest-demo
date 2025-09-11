package dev.dashaun.rest.retailstore.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;

@Builder
@Entity
@AllArgsConstructor
public class StoreJPA {
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
    private String Location;

    public StoreJPA() {

    }
}
