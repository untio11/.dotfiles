{
  config,
  lib,
  ...
}:
let
  cfg = config.gathering-hub;
in
{
  options.gathering-hub.ports.paperless = lib.mkOption {
    type = lib.types.port;
    default = 28981;
    description = lib.mdDoc ''
      Paperless-ngx Web UI port
    '';
  };

  options.gathering-hub.ports.paperless-gpt = lib.mkOption {
    type = lib.types.port;
    default = 8081;
    description = lib.mdDoc ''
      Paperless-GPT Web UI port
    '';
  };

  config = {
    services.paperless = {
      enable = true;
      address = "127.0.0.1";
      port = cfg.ports.paperless;
      consumptionDir = "/data/paperless/consume";
      consumptionDirIsPublic = true;
      settings = {
        PAPERLESS_URL = "https://paperless.furahiya.nexus";
        # Languages for Optical Character Recognition (OCR).
        PAPERLESS_OCR_LANGUAGE = "eng+nld";
        PAPERLESS_TIME_ZONE = "Europe/Amsterdam";
        # Database Config
        PAPERLESS_DBENGINE = "postgresql";
        PAPERLESS_DBHOST = "/run/postgresql";
        PAPERLESS_DBNAME = "paperless";
        PAPERLESS_DBUSER = "paperless";
        # Document consumption config
        PAPERLESS_CONSUMER_DELETE_DUPLICATES = true; # Simply delete documents from the consumer dir in case of duplicate detection.
        PAPERLESS_CONSUMER_RECURSIVE = true; # Allow paperless to consume documents from subdirectories of the consumer dir.
        PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true; # Subdirectories leading to the consumed document will be added as tags.
      };
      exporter = {
        enable = true;
        directory = "/data/backups/paperless";
        onCalendar = "*-*-* 01:30:00"; # Daily at 01:30
      };
    };

    # So paperless can interact with files in /data/paperless/consume.
    users.users.paperless.extraGroups = [ "users" ];

    sops = {
      secrets."gcp_paperless_docai_credentials_json" = {
        # paperless-gpt drops privileges to UID/GID 10001 inside the container
        mode = "0444";
      };
      secrets."paperless_api_token" = { };
      templates."paperless-gpt.env".content = ''
        PAPERLESS_API_TOKEN=${config.sops.placeholder.paperless_api_token}
      '';
    };

    virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.paperless-gpt = {
        image = "docker.io/icereed/paperless-gpt:latest";
        autoStart = true;
        extraOptions = [ "--network=host" ];
        environment = {
          LISTEN_INTERFACE = "127.0.0.1:${toString cfg.ports.paperless-gpt}";
          PAPERLESS_BASE_URL = "http://127.0.0.1:${toString cfg.ports.paperless}";
          PAPERLESS_PUBLIC_URL = "https://paperless.furahiya.nexus";

          # Dummy LLM config required by paperless-gpt's startup validation even when only using OCR
          LLM_PROVIDER = "ollama";
          LLM_MODEL = "unused";

          # Google Document AI OCR configuration (Astera Cloud)
          OCR_PROVIDER = "google_docai";
          GOOGLE_PROJECT_ID = "robotic-circle-456517-e7";
          GOOGLE_LOCATION = "europe-west2";
          GOOGLE_PROCESSOR_ID = "16da0c76b368e7ec";
          GOOGLE_APPLICATION_CREDENTIALS = "/etc/gcp-credentials.json"; # Created by sops (mounted outside /app so entrypoint chown -R /app succeeds)

          # Send the entire PDF as images to Google Document AI and upload the resulting searchable PDF back to Paperless
          OCR_PROCESS_MODE = "image";
          OCR_LIMIT_PAGES = "0"; # 0 = no artificial 5-page limit in paperless-gpt (Google DocAI sync limit is 15 pages / 20MB)
          PDF_UPLOAD = "true";
          PDF_UPLOAD_MODE = "version"; # Uploaded doc becomes a new version of the original doc (Paperless-ngx 3.0+).
          PDF_OCR_TAGGING = "true";
          PDF_OCR_COMPLETE_TAG = "ai-ocr-done";

          MANUAL_TAG = "ai-request";
          AUTO_TAG = "ai-auto-request";
          AUTO_OCR_TAG = "ai-ocr-request";
        };
        environmentFiles = [
          config.sops.templates."paperless-gpt.env".path
        ];
        volumes = [
          "${config.sops.secrets."gcp_paperless_docai_credentials_json".path}:/etc/gcp-credentials.json:ro"
          "/var/lib/paperless-gpt/config:/app/config"
          "/var/lib/paperless-gpt/prompts:/app/prompts"
          "/var/lib/paperless-gpt/db:/app/db"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      # Ensure the base consume folder exists with full access
      "d /data/paperless/consume 0777 paperless paperless -"

      # Force DEFAULT ACLs so any subfolder/file created by Syncthing or you
      # automatically inherits read, write, and delete permissions for the paperless user
      "A+ /data/paperless/consume - - - - default:user:paperless:rwx,default:group:users:rwx,default:other::rwx"
      "A+ /data/paperless/consume - - - - user:paperless:rwx,group:users:rwx,other::rwx"

      # State directories for paperless-gpt
      "d /var/lib/paperless-gpt/config 0755 root root -"
      "d /var/lib/paperless-gpt/prompts 0755 root root -"
      "d /var/lib/paperless-gpt/db 0755 root root -"
    ];
  };
}
