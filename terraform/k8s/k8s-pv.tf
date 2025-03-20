# resource "kubernetes_persistent_volume_v1" "pv_azurefile" {
#   metadata {
#     name = "pv-azurefile"
#     annotations = {
#       "pv.kubernetes.io/provisioned-by" = "file.csi.azure.com"
#     }
#   }
#
#   spec {
#     capacity = {
#       storage = "10Gi"
#     }
#
#     access_modes = ["ReadWriteMany"]
#     persistent_volume_reclaim_policy = "Retain"
#     storage_class_name = "azurefile-csi"
#
#     mount_options = [
#       "dir_mode=0777",
#       "file_mode=0777",
#       "uid=0",
#       "gid=0",
#       "mfsymlinks",
#       "cache=strict",
#       "nosharesock",
#       "actimeo=30",
#       "nobrl"
#     ]
#
#     persistent_volume_source {
#       csi {
#         driver = "file.csi.azure.com"
#         volume_handle = "{resource-group-name}#{account-name}#{file-share-name}"
#
#         volume_attributes = {
#           shareName = "EXISTING_FILE_SHARE_NAME"
#         }
#
#         node_stage_secret_ref {
#           name = "azure-secret"
#           namespace = "default"
#         }
#       }
#     }
#   }
# }