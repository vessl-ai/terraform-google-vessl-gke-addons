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
        volume {
          name = "entrypoint"
          config_map {
            name         = "entrypoint"
            default_mode = "0744"
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
        init_container {
          name    = "nvidia-containerd-runtime"
          image   = "ubuntu:22.04"
          command = ["/scripts/entrypoint.sh"]
          env {
            name  = "ROOT_MOUNT_DIR"
            value = "/root"
          }
          security_context {
            privileged = true
          }
          volume_mount {
            name       = "root-mount"
            mount_path = "/root"
          }
          volume_mount {
            name       = "entrypoint"
            mount_path = "/scripts"
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
      ROOT_MOUNT_DIR="$${ROOT_MOUNT_DIR:-/root}"

      cat << EOF | chroot "$${ROOT_MOUNT_DIR}"
      apt-get update
      apt-get install -y apt-transport-https curl gnupg lsb-release
      curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
      curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        chroot "$${ROOT_MOUNT_DIR}" sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
      apt-get update
      apt-get install -y nvidia-container-toolkit

      # containerd config 업데이트
      nvidia-ctk runtime configure --runtime=containerd

      # runc -> nvidia 확인
      cat /etc/containerd/config.toml

      systemctl restart containerd
      EOF
    EOT
  }
}
