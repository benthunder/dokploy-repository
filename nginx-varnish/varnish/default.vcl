vcl 4.1;

# Backend là Nginx service
backend default {
    .host = "nginx-backend";  # Tên container của Nginx
    .port = "80";
    .connect_timeout = 5s;
    .first_byte_timeout = 60s;
    .between_bytes_timeout = 10s;
    .max_connections = 300;

    .probe = {
        .url = "/";
        .timeout = 5s;
        .interval = 10s;
        .window = 5;
        .threshold = 3;
    }
}

# ACL cho phép purge cache
acl purge {
    "localhost";
    "nginx";
    "127.0.0.1";
    "172.16.0.0"/12;  # Docker network range
}

sub vcl_recv {
    # Cho phép purge cache từ ACL
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return (synth(405, "Not allowed"));
        }
        return (purge);
    }

    # Không cache POST, PUT, DELETE
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # Không cache nếu có cookie session
    if (req.http.Cookie ~ "PHPSESSID|wordpress_logged_in") {
        return (pass);
    }

    # Remove cookies cho static files
    if (req.url ~ "\.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$") {
        unset req.http.Cookie;
    }

    return (hash);
}

sub vcl_backend_response {
    # Cache static files lâu hơn
    if (bereq.url ~ "\.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$") {
        set beresp.ttl = 7d;
        unset beresp.http.Set-Cookie;
    }

    # Cache HTML trong 1 giờ
    if (beresp.http.Content-Type ~ "text/html") {
        set beresp.ttl = 1h;
    }

    # Không cache nếu có Set-Cookie
    if (beresp.http.Set-Cookie) {
        set beresp.ttl = 0s;
        set beresp.uncacheable = true;
        return (deliver);
    }

    return (deliver);
}

sub vcl_deliver {
    # Thêm header để debug
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS";
    }

    # Remove internal headers
    unset resp.http.X-Varnish;
    unset resp.http.Via;
    unset resp.http.Age;

    return (deliver);
}
