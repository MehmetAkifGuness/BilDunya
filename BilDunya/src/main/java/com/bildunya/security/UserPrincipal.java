package com.bildunya.security;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserPrincipal {

    private String username;
    private String role;

    public boolean hasAnyRole(String... roles) {
        if (role == null || roles == null) {
            return false;
        }
        for (String required : roles) {
            if (required != null && required.equalsIgnoreCase(role)) {
                return true;
            }
        }
        return false;
    }
}
