
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
