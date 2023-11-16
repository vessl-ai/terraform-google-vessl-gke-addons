resource "kubernetes_daemonset" "gpu_init" {
  metadata {
    name      = "gpu-init"
    namespace = "kube-system"
    labels = {
      k8s-app = "gpu-init"
    }
  }
  spec {
    selector {
      match_labels = {
        k8s-app = "gpu-init"
      }
    }
    strategy {
      type = "RollingUpdate"
    }
    template {
      metadata {
        labels = {
          name    = "gpu-init"
          k8s-app = "gpu-init"
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
