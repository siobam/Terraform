

data "azurerm_client_config" "current" {}
data "external" "get_azure_resources" {
  program = ["PowerShell", "${path.module}/Get-AzureRmResourceIds.ps1"]
  query = {
      AADSecret = "${var.AADSecret}"
      AADClientID = "${data.azurerm_client_config.current.client_id}"
      TenantID = "${data.azurerm_client_config.current.tenant_id}"
      ResourceGroup = "${var.resource_group_name}"
      SubscriptionID = "${data.azurerm_client_config.current.subscription_id}"
      ResourceType = "${var.resource_type}"
  }
}

locals {
  resources = "${split(",", lookup(data.external.get_azure_resources.result,"resource"))}"
  resource_count = "${length(local.resources)}"
}

data "external" "calculate_dashboard_coordinates" {
  program = ["PowerShell", "${path.module}/Get-CoordinatesOfDashbaordElements.ps1"]
  query = {
      ElementCount = "${local.resource_count}"
      ElementHeight = "${var.element_height}" 
      ElementWeight = "${var.element_weight}"
  }
}

locals {
   positions = "${split(",", lookup(data.external.calculate_dashboard_coordinates.result,"positions"))}"
}
# select target template
locals {
 database_template = "${var.resource_type == "database" ? "azure_database.json": ""}"
 app_service_template = "${var.resource_type == "app_service" ? "azure_app_service.json": ""}"
 app_service_plan_template = "${var.resource_type == "app_service_plan" ? "azure_app_service.json": ""}"
 virtual_machine_template = "${var.resource_type == "virtual_machine" ? "azure_virtual_machine.json": ""}"
 resource_template = "${local.database_template}${local.app_service_template}${local.app_service_plan_template}${local.virtual_machine_template}"
}
data  "template_file" "dashboard" {
  count    = "${local.resource_count}"

  template = "${file("${path.module}/templates/${local.resource_template}")}"
  vars {
      resourceMetadataId  = "${element(split("|", element(local.resources, count.index)),1)}"
      resourceDisplayName = "${element(split("|", element(local.resources, count.index)),0)}"
      index               = "${count.index}"
      position_x          = "${element(split(";", element(local.positions, count.index) ),0)}"
      position_y          = "${element(split(";", element(local.positions, count.index)),1)}"
      colSpan             = "${var.element_weight}"
      rowSpan             = "${var.element_height}"
  }
}

resource "azurerm_dashboard" "dashboard" {
  
    name                       = "${var.name}"
    resource_group_name        = "${var.resource_group_name}"
    location                   = "${var.location}"

    dashboard_properties       = <<DASH
{
   "lenses": {
        "0": {
            "order": 0,
            "parts": {
                ${join(",",data.template_file.dashboard.*.rendered)}
            }
        }
    },
    "metadata": {
        "model": {
            "timeRange": {
                "value": {
                    "relative": {
                        "duration": 24,
                        "timeUnit": 1
                    }
                },
                "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
            },
            "filterLocale": {
                "value": "en-us"
            },
            "filters": {
                "value": {
                    "MsPortalFx_TimeRange": {
                        "model": {
                            "format": "utc",
                            "granularity": "auto",
                            "relative": "24h"
                        },
                        "displayCache": {
                            "name": "UTC Time",
                            "value": "Past 24 hours"
                        },
                        "filteredPartIds": [
                            "StartboardPart-UnboundPart-ae44fef5-76b8-46b0-86f0-2b3f47bad1c7"
                        ]
                    }
                }
            }
        }
    }
}
DASH
    }
