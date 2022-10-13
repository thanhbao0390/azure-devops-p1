variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "baont1-azure-webapp"
}

variable "location" {
  description = "The Azure region in which all resources in this example should be created"
  default = "east us"
}

variable "tags" {
  description = "A map of the tags to use for the resources that are deployed"
  type        = map(string)
  default = {
    Name = "baont1-azure-webapp"
  }
}

variable "instance_count" {
  description = "Number machines to be created"
  type = number
  default = 2
}

variable "admin_username" {
  description = "Default username for admin"
  default = "adminuser"
}

variable "admin_password" {
  description = "Default password for admin"
  default = "Password@12345"
}

variable "subscription_id" {
  description = "Subscription id of the Packer image"
}

variable "packer_resource_group" {
  description = "Resource group of the Packer image"
}

variable "packer_image_name" {
  description = "Image name of the Packer image"
}