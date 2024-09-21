module "proxy-node" {
    source = "../terraform"

    env_name = "proxy-node"
    // ssh username
    username = "azureadmin"

    x_ui_port = 5320
    x_ui_path = "x-ui"
    x_ui_username = "labber"
    x_ui_password = "labberasdfghjkl"

    resource_group_location = "eastus"
    resource_group_name_prefix = "rg"

    cloudflare_api_token = "m8QvOVoIUxxxxxxxxxxxxxxxxxx1KGyKEIV8D"
    cloudflare_zone_name = "qxxxxxxxn.tk"

    az_subscription_id = "xxxxxxxxx-f46d-4f2b-8777-c70d02xxxxxxx"

    public_key_file = "~/.ssh/id_rsa.pub"


}

output "enpoint" {
    value = "${module.proxy-node.node_enpoint}"
}

output "public_ip" {
    value = "${module.proxy-node.public_ip_address}"
}