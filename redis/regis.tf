
resource "aws_elasticache_replication_group" "this" {
  description          = var.name
  replication_group_id = var.name
  node_type            = "cache.t3.micro"
  parameter_group_name = "default.redis6.x.cluster.on"
  engine               = "redis"
  engine_version       = "6.2"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = var.security_group_ids

  multi_az_enabled           = true
  automatic_failover_enabled = true
  num_node_groups            = 2
  replicas_per_node_group    = 1

  apply_immediately = true
}

resource "aws_elasticache_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids
}

locals {
  cmd =<<EOS
    jq -n --arg a "$(
      aws elasticache describe-cache-clusters \
        --show-cache-node-info \
        --query='CacheClusters[?ReplicationGroupId==`${aws_elasticache_replication_group.this.id}`].CacheNodes[].Endpoint.join(`:`, [Address,to_string(Port)]) | sort(@)'
    )" '{"a":$a}'
  EOS
}

data "external" "node_endpoints" {
  program = ["sh", "-c", local.cmd]
}

# output "node_endpoints" {
#   value = jsondecode(data.external.node_endpoints.result.a)
# }

data "aws_elasticache_cluster" "this" {
  for_each = toset(aws_elasticache_replication_group.this.member_clusters)
  cluster_id = each.value
}

output "node_endpoints" {
  #value = jsondecode(data.external.node_endpoints.result.a)
  value = sort(flatten([for c in data.aws_elasticache_cluster.this : [for n in c.cache_nodes : "${n.address}:${n.port}"]]))
}
