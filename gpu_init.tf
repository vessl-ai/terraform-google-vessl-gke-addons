resource "kubernetes_daemonset" "gpu_init" {
  metadata {
    name      = "vessl-gpu-init"
    namespace = "kube-system"
    labels = {
      app = "vessl-gpu-init"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "vessl-gpu-init"
      }
    }
    strategy {
      type = "RollingUpdate"
    }
    template {
      metadata {
        labels = {
          name = "vessl-gpu-init"
          app  = "vessl-gpu-init"
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
            name         = "vessl-gpu-init-entrypoint"
            default_mode = "0744"
          }
        }
        volume {
          name = "systemd"
          host_path {
            path = "/run/systemd/system"
          }
        }
        volume {
          name = "systemctl"
          host_path {
            path = "/bin/systemctl"
          }
        }
        volume {
          name = "system-bus-socket"
          host_path {
            path = "/var/run/dbus/system_bus_socket"
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
          volume_mount {
            name       = "systemd"
            mount_path = "/run/systemd/system"
          }
          volume_mount {
            name       = "systemctl"
            mount_path = "/bin/systemctl"
          }
          volume_mount {
            name       = "system-bus-socket"
            mount_path = "/var/run/dbus/system_bus_socket"
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
    name      = "vessl-gpu-init-entrypoint"
    namespace = "kube-system"
    labels = {
      app = "vessl-gpu-init"
    }
  }

  data = {
    "entrypoint.sh" = <<-EOT
      #!/bin/bash

      set -euo pipefail

      DEBIAN_FRONTEND=noninteractive

      cat << EOF | chroot /root
      curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
      curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
      tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
      apt-get update
      apt-get install -y nvidia-container-toolkit

      # containerd config 업데이트 후 확인
      nvidia-ctk runtime configure --runtime=containerd
      cat /etc/containerd/config.toml
      EOF
      systemctl restart containerd
      systemctl status --no-pager containerd
      echo Done
    EOT
  }
}
