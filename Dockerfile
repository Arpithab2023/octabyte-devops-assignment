# Static site (HTML/JS) — served via nginx on port 8080.
FROM nginx:alpine

# Run nginx on 8080 instead of 80, and as non-root (security best practice)
RUN sed -i 's/listen\s*80;/listen 8080;/' /etc/nginx/conf.d/default.conf \
    && sed -i 's,/var/run/nginx.pid,/tmp/nginx.pid,' /etc/nginx/nginx.conf \
    && touch /tmp/nginx.pid \
    && chown -R nginx:nginx /var/cache/nginx /tmp/nginx.pid /etc/nginx/conf.d

COPY app/ /usr/share/nginx/html/

USER nginx
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:8080/health.html || exit 1
CMD ["nginx", "-g", "daemon off;"]
