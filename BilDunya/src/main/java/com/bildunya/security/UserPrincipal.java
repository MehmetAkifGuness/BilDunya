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
        String currentRole = normalize(role);
        for (String required : roles) {
            if (required != null && normalize(required).equalsIgnoreCase(currentRole)) {
                return true;
            }
        }
        return false;
    }

    private static String normalize(String value) {
        String normalized = value == null ? "" : value.trim().toUpperCase();
        if (normalized.startsWith("ROLE_")) {
            normalized = normalized.substring("ROLE_".length());
        }
        return normalized;
    }
}
