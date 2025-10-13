locals {
  pop_workers = {
    for pop_code, pop_module in module.pop :
    lower(pop_code) => [
      for worker_key in sort(keys(pop_module.servers)) : {
        worker_key  = worker_key
        id          = pop_module.servers[worker_key].id
        hostname    = pop_module.servers[worker_key].hostname
        plan        = pop_module.servers[worker_key].plan
        public_ipv4 = pop_module.servers[worker_key].public_ipv4 != "" ? pop_module.servers[worker_key].public_ipv4 : pop_module.servers[worker_key].public_ipv6
      }
    ]
  }

  pop_keys = sort(keys(local.pop_workers))
}

resource "local_file" "ansible_hosts" {
  content = templatefile("${path.module}/hosts.tftpl", {
    pops     = local.pop_workers
    pop_keys = local.pop_keys
  })
  # adjust the path below if your repo layout differs
  filename = "${path.module}/../anycast/base-ansible-template/hosts"
}
