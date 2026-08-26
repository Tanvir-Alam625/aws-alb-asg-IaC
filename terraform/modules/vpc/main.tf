resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnet_cidrs : idx => {
    cidr = cidr
    az   = var.availability_zones[idx % length(var.availability_zones)]
  } }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-${each.key + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private_app" {
  for_each = { for idx, cidr in var.private_app_subnet_cidrs : idx => {
    cidr = cidr
    az   = var.availability_zones[idx % length(var.availability_zones)]
  } }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-app-${each.key + 1}"
    Tier = "private-app"
  })
}

resource "aws_subnet" "private_database" {
  for_each = { for idx, cidr in var.private_database_subnet_cidrs : idx => {
    cidr = cidr
    az   = var.availability_zones[idx % length(var.availability_zones)]
  } }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-db-${each.key + 1}"
    Tier = "private-db"
  })
}

resource "aws_eip" "nat" {
  count  = var.enable_multi_nat_gateway ? length(var.public_subnet_cidrs) : 1
  domain = "vpc"

  depends_on = [aws_internet_gateway.this]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "this" {
  count = var.enable_multi_nat_gateway ? length(var.public_subnet_cidrs) : 1

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count  = length(var.private_app_subnet_cidrs)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index % length(aws_nat_gateway.this)].id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table" "database" {
  count  = length(var.private_database_subnet_cidrs)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index % length(aws_nat_gateway.this)].id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app" {
  for_each       = aws_subnet.private_app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key % length(aws_route_table.private)].id
}

resource "aws_route_table_association" "private_database" {
  for_each       = aws_subnet.private_database
  subnet_id      = each.value.id
  route_table_id = aws_route_table.database[each.key % length(aws_route_table.database)].id
}
