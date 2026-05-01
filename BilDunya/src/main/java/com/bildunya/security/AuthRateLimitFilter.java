package com.bildunya.security;

import com.bildunya.exception.ErrorResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
@RequiredArgsConstructor
public class AuthRateLimitFilter extends OncePerRequestFilter {

    private static final int LOGIN_LIMIT = 20;
    private static final long LOGIN_WINDOW_MS = 5 * 60 * 1000L;

    private static final int REGISTER_LIMIT = 10;
    private static final long REGISTER_WINDOW_MS = 10 * 60 * 1000L;

    private static final int MAX_BUCKETS_BEFORE_CLEANUP = 20_000;

    private final ObjectMapper objectMapper;

    private final ConcurrentHashMap<String, Bucket> buckets = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String path = normalizePath(request);
        String method = request.getMethod();

        if (!"POST".equalsIgnoreCase(method)) {
            filterChain.doFilter(request, response);
            return;
        }

        if ("/auth/login".equals(path)) {
            if (!allow(request, "login", LOGIN_LIMIT, LOGIN_WINDOW_MS)) {
                writeTooManyRequests(response, request);
                return;
            }
        } else if ("/auth/register".equals(path)) {
            if (!allow(request, "register", REGISTER_LIMIT, REGISTER_WINDOW_MS)) {
                writeTooManyRequests(response, request);
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    private boolean allow(HttpServletRequest request, String action, int limit, long windowMs) {
        String ip = extractClientIp(request);
        String key = action + ":" + ip;

        long now = System.currentTimeMillis();
        Bucket bucket = buckets.computeIfAbsent(key, k -> new Bucket(now, 0));

        boolean allowed;
        synchronized (bucket) {
            if (now - bucket.windowStartMs >= windowMs) {
                bucket.windowStartMs = now;
                bucket.count = 0;
            }
            bucket.count++;
            allowed = bucket.count <= limit;
        }

        if (buckets.size() > MAX_BUCKETS_BEFORE_CLEANUP) {
            cleanup(now);
        }

        return allowed;
    }

    private void cleanup(long now) {
        for (Map.Entry<String, Bucket> entry : buckets.entrySet()) {
            Bucket bucket = entry.getValue();
            boolean expired;
            synchronized (bucket) {
                expired = now - bucket.windowStartMs > Math.max(LOGIN_WINDOW_MS, REGISTER_WINDOW_MS);
            }
            if (expired) {
                buckets.remove(entry.getKey(), bucket);
            }
        }
    }

    private static String extractClientIp(HttpServletRequest request) {
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) {
            String first = xff.split(",", 2)[0].trim();
            if (!first.isBlank()) {
                return first;
            }
        }
        String remote = request.getRemoteAddr();
        return remote == null ? "unknown" : remote;
    }

    private static String normalizePath(HttpServletRequest request) {
        String uri = request.getRequestURI();
        if (uri == null) {
            return "";
        }
        String contextPath = request.getContextPath();
        if (contextPath != null && !contextPath.isBlank() && uri.startsWith(contextPath)) {
            return uri.substring(contextPath.length());
        }
        return uri;
    }

    private void writeTooManyRequests(HttpServletResponse response, HttpServletRequest request) throws IOException {
        response.setStatus(429);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);

        ErrorResponse payload = ErrorResponse.builder()
                .status(429)
                .message("Too many requests")
                .error("Too Many Requests")
                .timestamp(LocalDateTime.now())
                .path(normalizePath(request))
                .build();

        response.getWriter().write(objectMapper.writeValueAsString(payload));
    }

    private static final class Bucket {
        private long windowStartMs;
        private int count;

        private Bucket(long windowStartMs, int count) {
            this.windowStartMs = windowStartMs;
            this.count = count;
        }
    }
}

