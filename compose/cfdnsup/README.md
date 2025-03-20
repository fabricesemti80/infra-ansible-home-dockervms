
## Folder structure and how to run

```sh
Project Folder:
├── docker-compose.yml   # Docker Compose file to run the script in a container
├── update_dns.sh        # The Cloudflare DNS update script
├── .env                 # (Optional) Store environment variables here
```

## Steps to Run:
1. Clone or create the project folder
2. Make sure 'update_dns.sh' is executable:
   `chmod +x update_dns.sh`
3. Modify 'docker-compose.yml' and '.env' (copy `.env_example` to `.env`) with your Cloudflare API details
4. Start the container:
   `docker-compose up -d`
5. Check logs:
   `docker logs cloudflare-dns-updater`
6. (Optional) Stop the container:
   `docker-compose down`
