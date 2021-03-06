provider "vra" {
  url           = var.url
  refresh_token = var.refresh_token
}

data "vra_project" "this" {
  name = var.project_name
}

data "vra_blueprint" "this" {
  name = var.blueprint_name
}

resource "vra_deployment" "this" {
  name        = var.deployment_name
  description = "Deployed from vRA provider for Terraform."

  owner = var.owner

  blueprint_id      = data.vra_blueprint.this.id
  blueprint_version = var.blueprint_version
  project_id        = data.vra_project.this.id

  inputs = {
    flavor = "small"
    image  = "centos"
    count  = 1
    flag   = true
    arrayProp = jsonencode(["foo", "bar", "baz"])
    objectProp = jsonencode({ "key": "value", "key2": [1, 2, 3] })
  }

  timeouts {
    create = "30m"
    delete = "30m"
    update = "30m"
  }
}


output "resources" {
  description = "All the resources from a vRA deployment"
  value       = vra_deployment.this.resources
}

output "resource_properties_by_name" {
  description = "Properties of all resources by its name from a vRA deployment"
  value = {
    for rs in vra_deployment.this.resources :
    rs.name => jsondecode(rs.properties_json)
  }
}

output "resources_properties" {
  description = "Properties of all resources from a vRA deployment"
  value = [
    for rs in vra_deployment.this.resources :
    jsondecode(rs.properties_json)
  ]
}

output "addresses_by_name" {
  description = "Resource name and IP addresses of all machine type resources from a vRA deployment"
  value = {
    for props in sort(vra_deployment.this.resources.*.properties_json) :
    jsondecode(props).resourceName => jsondecode(props).address
    if jsondecode(props).componentType == "Cloud.Machine" || jsondecode(props).componentType == "Cloud.vSphere.Machine" || jsondecode(props).componentType == "Cloud.AWS.EC2.Instance" || jsondecode(props).componentType == "Cloud.GCP.Machine" || jsondecode(props).componentType == "Cloud.Azure.Machine"
  }
}

output "first_resource_address" {
  // Works for simple deployments with only one machine resource with count as 1.
  description = "IP address property of first resource in a vRA deployment"
  value       = jsondecode(sort(vra_deployment.this.resources.*.properties_json)[0]).address
}

output "all_resources_addresses" {
  // Gives address property from all resources of a deployment
  description = "IP address property of all resources from a vRA deployment"
  value = [
    for props in sort(vra_deployment.this.resources.*.properties_json) :
    jsondecode(props).address
  ]
}