output "vm_public_ipv4_by_pop" {
  value = {
    for pop, mod in module.pop :
    pop => {
      for worker_key, server in mod.servers :
      worker_key => server.public_ipv4
    }
  }
}

output "vm_ids_by_pop" {
  value = {
    for pop, mod in module.pop :
    pop => mod.netactuate_server_ids
  }
}

# Already provided in main.tf: server_data, bgp_sessions_data, ansible_inventory_json
