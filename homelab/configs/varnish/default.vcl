vcl 4.1;

import std;

# Backend definition - Nginx
backend default {
    .host = "nginx";
    .port = "8080";
    .connect_timeout = 5s;
    .first_byte_timeout = 60s;
    .between_bytes_timeout = 10s;
    .max_connections = 300;

    .probe = {
        .url = "/health";
        .timeout = 2s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}

# ACL for purge requests
acl purge {
    "localhost";
    "172.20.0.0"/16;
}

sub vcl_recv {
    # Remove empty query string parameters
    if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=") {
        set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
        set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
        set req.url = regsub(req.url, "\?&", "?");
        set req.url = regsub(req.url, "\?$", "");
    }

    # Strip hash, server doesn't need it
    if (req.url ~ "\#") {
        set req.url = regsub(req.url, "\#.*$", "");
    }

    # Strip trailing ? if it exists
    if (req.url ~ "\?$") {
        set req.url = regsub(req.url, "\?$", "");
    }

    # Handle PURGE requests
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return (synth(405, "Not allowed"));
        }
        return (purge);
    }

    # Only cache GET and HEAD requests
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # Don't cache admin areas
    if (req.url ~ "^/wp-admin" ||
        req.url ~ "^/wp-login" ||
        req.url ~ "^/admin" ||
        req.url ~ "^/administrator") {
        return (pass);
    }

    # Don't cache if logged in (WordPress)
    if (req.http.Cookie ~ "wordpress_logged_in_" ||
        req.http.Cookie ~ "wp-postpass_" ||
        req.http.Cookie ~ "comment_author_") {
        return (pass);
    }

    # Don't cache if session cookie exists
    if (req.http.Cookie ~ "PHPSESSID" ||
        req.http.Cookie ~ "laravel_session") {
        return (pass);
    }

    # Remove cookies for static files
    if (req.url ~ "\.(jpg|jpeg|gif|png|ico|css|zip|tgz|gz|rar|bz2|pdf|txt|tar|wav|bmp|rtf|js|flv|swf|html|htm|woff|woff2|ttf|svg|eot)$") {
        unset req.http.Cookie;
        return (hash);
    }

    # Remove Google Analytics cookies
    if (req.http.Cookie) {
        set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(_ga|_gat|_gid|__utm[a-z])=[^;]*", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "^;\s*", "");
        if (req.http.Cookie == "") {
            unset req.http.Cookie;
        }
    }

    return (hash);
}

sub vcl_backend_response {
    # Set ban-lurker friendly custom headers
    set beresp.http.X-Url = bereq.url;
    set beresp.http.X-Host = bereq.http.host;

    # Cache static files for 1 day
    if (bereq.url ~ "\.(jpg|jpeg|gif|png|ico|css|zip|tgz|gz|rar|bz2|pdf|txt|tar|wav|bmp|rtf|js|flv|swf|html|htm|woff|woff2|ttf|svg|eot)$") {
        unset beresp.http.Set-Cookie;
        set beresp.ttl = 1d;
        set beresp.http.Cache-Control = "public, max-age=86400";
    }

    # Don't cache if Set-Cookie is present
    if (beresp.http.Set-Cookie) {
        set beresp.ttl = 0s;
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Don't cache 5xx errors
    if (beresp.status >= 500 && beresp.status < 600) {
        set beresp.ttl = 0s;
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Cache 404 for 1 minute
    if (beresp.status == 404) {
        set beresp.ttl = 1m;
    }

    # Enable ESI
    if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
        unset beresp.http.Surrogate-Control;
        set beresp.do_esi = true;
    }

    # Default TTL
    if (beresp.ttl <= 0s) {
        set beresp.ttl = 5m;
    }

    # Allow stale content
    set beresp.grace = 6h;

    return (deliver);
}

sub vcl_deliver {
    # Add cache hit/miss header
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS";
    }

    # Remove backend headers
    unset resp.http.X-Url;
    unset resp.http.X-Host;
    unset resp.http.X-Powered-By;
    unset resp.http.Server;
    unset resp.http.Via;

    return (deliver);
}

sub vcl_hit {
    if (req.method == "PURGE") {
        return (synth(200, "Purged"));
    }
    return (deliver);
}

sub vcl_miss {
    if (req.method == "PURGE") {
        return (synth(404, "Not in cache"));
    }
    return (fetch);
}

sub vcl_purge {
    return (synth(200, "Purged"));
}
