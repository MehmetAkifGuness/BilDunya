package com.bildunya.security;

import com.bildunya.entity.User;
import com.bildunya.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.Locale;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider tokenProvider;
    private final UserRepository userRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                   FilterChain filterChain) throws ServletException, IOException {

        try {
            String jwt = getJwtFromRequest(request);

            if (jwt != null && tokenProvider.validateToken(jwt)) {
                String username = tokenProvider.getUsernameFromToken(jwt);
                long tokenVersion = tokenProvider.getTokenVersionFromToken(jwt);

                User user = userRepository.findByUsernameIgnoreCase(username).orElse(null);
                if (user != null
                        && !Boolean.TRUE.equals(user.getIsDeleted())
                        && Boolean.TRUE.equals(user.getIsActive())) {

                    long userVersion = user.getTokenVersion() == null ? 0L : user.getTokenVersion();
                    if (tokenVersion == userVersion) {
                        String userRole = normalizeRole(user.getRole());
                        UserPrincipal userPrincipal = new UserPrincipal(user.getUsername(), userRole);
                        Authentication authentication = new JwtAuthenticationToken(userPrincipal);
                        SecurityContextHolder.getContext().setAuthentication(authentication);
                    }
                }
            }
        } catch (Exception ex) {
            logger.error("Could not set user authentication", ex);
        }

        filterChain.doFilter(request, response);
    }

    private static String normalizeRole(String role) {
        if (role == null || role.isBlank()) {
            return "USER";
        }
        String normalized = role.trim().toUpperCase(Locale.ROOT);
        if (normalized.startsWith("ROLE_")) {
            normalized = normalized.substring("ROLE_".length());
        }
        return switch (normalized) {
            case "ADMIN", "MODERATOR", "USER" -> normalized;
            default -> "USER";
        };
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");

        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }

        return null;
    }
}
