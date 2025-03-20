Here we set up the CloudFlared container to allow connectivity to our network.

**TODO**: add config file (use templating)
- based on <https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/configure-tunnels/local-management/configuration-file/>
- example:

```yaml
originRequest:
  originServerName: "external.{{ ansible_nas_domain }}"

ingress:
  - hostname: "{{ ansible_nas_domain }}"
    service: "https://{{ hostvars[inventory_hostname]['ansible_default_ipv4']['address'] }}:{{ traefik_port_https }}" # https://ingress-nginx-external-controller.network.svc.cluster.local:443
  - hostname: "*.{{ ansible_nas_domain }}"
    service: "https://{{ hostvars[inventory_hostname]['ansible_default_ipv4']['address'] }}:{{ traefik_port_https }}" # https://ingress-nginx-external-controller.network.svc.cluster.local:443
  - service: http_status:404
```

This assumes:
- there is a DNS record on your CloudFlare domain
- and this record is set to send `external.` subdomain of your domain (which should match with the value of `ansible_nas_domain`) to your tunnel
- with this, the tunnel client (this container) will be able to forward the traffic to the Traefik reverse proxy running on the same host
- Traefik then should be able to send the traffic to route the traffic to the relevant containers
