output "server_ids" {
  value = { for key, srv in netactuate_server.vm : key => tostring(srv.id) }
}

output "servers" {
  value = local.server_metadata
}
