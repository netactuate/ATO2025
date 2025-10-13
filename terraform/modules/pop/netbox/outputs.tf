output "virtual_machine_ids" {
  value = { for key, vm in netbox_virtual_machine.vm : key => vm.id }
}

output "device_ids" {
  value = { for key, device in netbox_device.vm : key => device.id }
}
