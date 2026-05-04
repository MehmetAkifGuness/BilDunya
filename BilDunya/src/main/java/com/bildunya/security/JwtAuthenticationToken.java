package com.bildunya.security;

import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Locale;

public class JwtAuthenticationToken extends AbstractAuthenticationToken {

    private final UserPrincipal principal;

    public JwtAuthenticationToken(UserPrincipal principal) {
        super(resolveAuthorities(principal));
        this.principal = principal;
        setAuthenticated(true);
    }

    @Override
    public Object getCredentials() {
        return null;
    }

    @Override
    public Object getPrincipal() {
        return principal;
    }

    private static Collection<? extends GrantedAuthority> resolveAuthorities(UserPrincipal principal) {
        if (principal == null || principal.getRole() == null || principal.getRole().isBlank()) {
            return Collections.emptyList();
        }
        String role = principal.getRole().trim().toUpperCase(Locale.ROOT);
        if (role.startsWith("ROLE_")) {
            role = role.substring("ROLE_".length());
        }
        return List.of(new SimpleGrantedAuthority("ROLE_" + role));
    }
}
