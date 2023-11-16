resource "kubernetes_daemonset" "gpu_init" {
  metadata {
    name      = "gpu-init"
    namespace = "kube-system"
    labels = {
      app = "gpu-init"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "gpu-init"
      }
    }
    strategy {
      type = "RollingUpdate"
    }
    template {
      metadata {
        labels = {
          name = "gpu-init"
          app  = "gpu-init"
        }
      }
      spec {
        priority_class_name = "system-node-critical"
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "cloud.google.com/gke-accelerator"
                  operator = "Exists"
                }
                match_expressions {
                  key      = "cloud.google.com/gke-gpu-driver-version"
                  operator = "DoesNotExist"
                }
              }
            }
          }
        }
        toleration {
          operator = "Exists"
        }
        volume {
          name = "dev"
          host_path {
            path = "/dev"
          }
        }
        volume {
          name = "boot"
          host_path {
            path = "/boot"
          }
        }
        volume {
          name = "root-mount"
          host_path {
            path = "/"
          }
        }
        init_container {
          image = "gke-nvidia-installer:fixed"
          name  = "nvidia-driver-installer"
          resources {
            requests = {
              cpu = "150m"
            }
          }
          security_context {
            privileged = true
          }
          volume_mount {
            name       = "boot"
            mount_path = "/boot"
          }
          volume_mount {
            name       = "dev"
            mount_path = "/dev"
          }
          volume_mount {
            name       = "root-mount"
            mount_path = "/root"
          }
          env {
            name  = "NVIDIA_DRIVER_VERSION"
            value = "525.105.17"
          }
        }
        container {
          image = "gcr.io/google-containers/pause:2.0"
          name  = "pause"
        }
      }
    }
  }
}

resource "kubernetes_config_map" "entrypoint" {
  metadata {
    name = "entrypoint"
    labels = {
      app = "gpu-init"
    }
  }

  data = {
    "entrypoint.sh" = <<-EOT
      #!/usr/bin/env bash

      set -euo pipefail

      DEBIAN_FRONTEND=noninteractive
      ROOT_MOUNT_DIR="$\{ROOT_MOUNT_DIR:-/root\}"

      echo "Installing dependencies"
      apt-get update
      apt-get install -y apt-transport-https curl gnupg lsb-release

      echo "Installing gcloud SDK"
      export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
      echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
      curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
      apt-get update
      apt-get install -y google-cloud-sdk

      echo "Getting node metadata"
      NODE_NAME="$(curl -sS http://metadata.google.internal/computeMetadata/v1/instance/name -H 'Metadata-Flavor: Google')"
      ZONE="$(curl -sS http://metadata.google.internal/computeMetadata/v1/instance/zone -H 'Metadata-Flavor: Google' | awk -F  "/" '{print $4}')"

      echo "Setting up disks"
      DISK_NAME="$NODE_NAME-additional"

      if ! gcloud compute disks list --filter="name:$DISK_NAME" | grep "$DISK_NAME" > /dev/null; then
          echo "Creating $DISK_NAME"
          gcloud compute disks create "$DISK_NAME" --size=1024 --zone="$ZONE"
      else
          echo "$DISK_NAME already exists"
      fi

      if ! gcloud compute instances describe "$NODE_NAME" --zone "$ZONE" --format '(disks[].source)' | grep "$DISK_NAME" > /dev/null; then
          echo "Attaching $DISK_NAME to $NODE_NAME"
          gcloud compute instances attach-disk "$NODE_NAME" --device-name=sdb --disk "$DISK_NAME" --zone "$ZONE"
      else
          echo "$DISK_NAME is already attached to $NODE_NAME"
      fi

      # We use chroot to run the following commands in the host root (mounted as the /root volume in the container)
      echo "Installing nano"
      chroot "${ROOT_MOUNT_DIR}" apt-get update
      chroot "${ROOT_MOUNT_DIR}" apt-get install -y nano

      echo "Loading Kernel modules"
      # Load the bridge kernel module as an example
      chroot "${ROOT_MOUNT_DIR}" modprobe bridge
    EOT
  }
}
