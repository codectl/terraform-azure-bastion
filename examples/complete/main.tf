module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "network" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"

  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.19.0.0/16"]

    subnets = {
      bastion = {
        name             = "AzureBastionSubnet"
        address_prefixes = ["10.19.1.0/27"]
        network_security_group = {
          name  = module.naming.network_security_group.name
          rules = local.rules
        }
      }
    }
  }
}

module "public_ip" {
  source  = "codectl/pip/azure"
  version = "~> 1.0"

  public_ips = {
    bastion = {
      name                = module.naming.public_ip.name
      location            = module.rg.groups.demo.location
      resource_group_name = module.rg.groups.demo.name
      zones               = ["1", "2", "3"]
    }
  }
}

module "bastion" {
  source  = "codectl/bastion/azure"
  version = "~> 1.0"

  host = {
    name                = module.naming.bastion_host.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    copy_paste_enabled     = true
    file_copy_enabled      = true
    tunneling_enabled      = true
    ip_connect_enabled     = true
    shareable_link_enabled = true
    kerberos_enabled       = true

    ip_configuration = {
      subnet_id            = module.network.subnets.bastion.id
      public_ip_address_id = module.public_ip.public_ips.bastion.id
    }
  }
}
